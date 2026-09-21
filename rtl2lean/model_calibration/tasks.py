"""Build, validate, and immutably freeze the 15-task calibration corpus."""
from __future__ import annotations

import hashlib
import json
import os
import re
from dataclasses import asdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from rtl2lean.evaluation.experiment import _lean_check
from rtl2lean.pipeline.io import sha256, write_json
from rtl2lean.pipeline.manifest import Benchmark
from rtl2lean.compositional_proofs.report import tree_digest
from rtl2lean.proof_gaps.experiment import _proof_source, _task


MODELS = [
    {
        "model_key": "gpt", "display_name": "GPT 5.6 Sol", "provider": "openai",
        "model_id": "gpt-5.6-sol", "api_key_env": "OPENAI_API_KEY",
        "endpoint": "https://api.openai.com/v1/responses", "reasoning_profile": "high",
    },
    {
        "model_key": "deepseek_pro", "display_name": "DeepSeek Pro",
        "provider": "deepseek", "model_id": "deepseek-v4-pro",
        "api_key_env": "DEEPSEEK_API_KEY", "endpoint": "https://api.deepseek.com/responses",
        "reasoning_profile": "high",
    },
    {
        "model_key": "deepseek_flash", "display_name": "DeepSeek Flash",
        "provider": "deepseek", "model_id": "deepseek-v4-flash",
        "api_key_env": "DEEPSEEK_API_KEY", "endpoint": "https://api.deepseek.com/responses",
        "reasoning_profile": "high",
    },
]

BUDGET = {
    "max_input_tokens": 60_000,
    "max_output_tokens": 8_000,
    "max_total_tokens": 120_000,
    "initial_generation_calls": 1,
    "max_repair_rounds": 2,
    "max_llm_calls": 3,
    "provider_timeout_s": 300,
    "temperature": None,
    "trials_per_task": 3,
    "sampling_policy": "paired_semantically_inert_nonce",
}

INITIAL_TEMPLATE = """You are proving one frozen Lean 4 theorem in an audited model calibration.
Return only a JSON object with fields proof_body and rationale. proof_body must be a complete
Lean term beginning with `by`; do not include the theorem declaration.

Hard constraints:
- Prove the exact target. Never change, weaken, or restate it.
- Never use sorry, admit, native_decide, axiom, unsafe, or unchecked code.
- Use only the imported definitions and theorem context below.
- This is Direct proving: do not propose a separate new top-level intermediate theorem.
- Local `have` declarations inside proof_body are allowed.
- Prefer robust induction patterns and use the supplied Lean names exactly.

Paired trial nonce (no proof information): {trial_nonce}
Import: {context_import}
Namespace: {namespace}
Open namespace: {open_namespace}
Target name: {task_id}
Target statement:
{statement}

Identical retrieved Lean context for every model:
{context}
"""

REPAIR_TEMPLATE = """The preceding candidate for this same frozen theorem failed Lean checking.
Return only JSON with proof_body and rationale. Repair the proof without changing the target,
the frozen context, or any budget. The same safety constraints remain in force.

Target name: {task_id}
Target statement:
{statement}

Previous proof_body:
{previous_proof}

Lean error:
{lean_error}

Frozen retrieved Lean context:
{context}
"""


def _read(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def _hash_text(value: str) -> str:
    return hashlib.sha256(value.encode()).hexdigest()


def _replace_vars(text: str, replacements: dict[str, str]) -> str:
    return re.sub(
        r"(?<![A-Za-z0-9_'])(s|pre|item)(?![A-Za-z0-9_'])",
        lambda match: replacements[match.group(1)], text,
    )


def _hard_from_symbolic(prop: dict[str, Any], slug: str) -> dict[str, Any]:
    statement = prop["theorem_statement"]
    match = re.match(
        r"∀ \(s : ([^)]+)\) \(pre : List ([^)]+)\) \(item : ([^)]+)\), (.+)",
        statement,
    )
    if not match:
        raise ValueError(f"cannot derive calibration hard task from {prop['property_id']}")
    state_type, list_input, item_input, body = match.groups()
    if list_input != item_input or " → " not in body:
        raise ValueError(f"unexpected symbolic endpoint shape: {prop['property_id']}")
    assumption, conclusion = body.split(" → ", 1)
    state_a = "s"
    state_b = "(r3Run s (preA ++ [itemA]))"
    a = {"s": state_a, "pre": "preA", "item": "itemA"}
    b = {"s": state_b, "pre": "preB", "item": "itemB"}
    hard_statement = (
        f"∀ (s : {state_type}) (preA : List {item_input}) (itemA : {item_input}) "
        f"(preB : List {item_input}) (itemB : {item_input}), "
        f"{_replace_vars(assumption, a)} → {_replace_vars(assumption, b)} → "
        f"({_replace_vars(conclusion, a)}) ∧ ({_replace_vars(conclusion, b)})"
    )
    reference = "\n".join([
        "by",
        f"  have endpoint : {statement} := by",
        *("    " + line if line else "" for line in prop["reference_proof"].splitlines()[1:]),
        "  intro s preA itemA preB itemB hA hB",
        "  exact ⟨endpoint s preA itemA hA,",
        "    endpoint (r3Run s (preA ++ [itemA])) preB itemB hB⟩",
    ])
    return {
        **prop,
        "property_id": f"r10a_hard_{slug}_two_phase_same_endpoint",
        "theorem_statement": hard_statement,
        "reference_proof": reference,
        "property_family": "CALIBRATION_MULTI_STAGE_COMPOSITION",
        "calibration_origin": "NEW_DERIVED_NON_R8_CHALLENGE",
    }


def _task_context(
    benchmark: Benchmark, prop: dict[str, Any], output_root: Path,
) -> tuple[str, list[str]]:
    autonomous = _task(benchmark, prop, {"attempts": []}, output_root)
    return "\n\n".join(autonomous.context_snippets), autonomous.relevant_foundational_lemmas


def _make_tasks(benchmarks: list[Benchmark], output_root: Path) -> list[dict[str, Any]]:
    r8 = _read(output_root / "multi_phase_proofs" / "corpus" / "final_properties.json")
    challenges = _read(output_root / "multi_phase_proofs" / "corpus" / "bottleneck_challenges.json")
    challenge_ids = {row["property_id"] for row in challenges["properties"]}
    challenge_statements = {_hash_text(row["theorem_statement"]) for row in challenges["properties"]}
    benchmark_map = {row.design_id: row for row in benchmarks}
    covered = sorted(
        (row for row in r8["properties"] if row["r8_experiment_class"] == "FOUNDATION_COVERED"),
        key=lambda row: row["dut"],
    )
    symbolic = sorted(
        (row for row in r8["properties"] if row["r8_experiment_class"] == "WEAK_GAP"),
        key=lambda row: row["dut"],
    )
    if len(covered) != 5 or len(symbolic) != 5:
        raise ValueError("model_calibration requires five covered and five symbolic non-challenge seeds")
    rows: list[dict[str, Any]] = []
    for difficulty, source_rows in (("EASY", covered), ("MEDIUM", symbolic)):
        for prop in source_rows:
            benchmark = benchmark_map[prop["dut"]]
            slug = benchmark.slug
            clone = {
                **prop,
                "property_id": f"r10a_{difficulty.lower()}_{slug}_{prop['property_id'].split(slug, 1)[-1].strip('_')}",
                "calibration_origin": "R8_NON_BOTTLENECK_CONTROL",
            }
            context, retrieved = _task_context(benchmark, clone, output_root)
            rows.append({
                "task_id": clone["property_id"], "difficulty": difficulty,
                "dut": clone["dut"], "module": benchmark.top_module,
                "statement": clone["theorem_statement"], "reference_proof": clone["reference_proof"],
                "context_import": "R5Foundation", "context": context,
                "context_hash": _hash_text(context), "retrieved_theorems": retrieved,
                "retrieval_hash": _hash_text(json.dumps(retrieved, sort_keys=True)),
                "foundation_lemmas": clone.get("foundation_lemmas", []),
                "property_family": clone["property_family"],
                "source_property_id": prop["property_id"],
                "calibration_origin": clone["calibration_origin"],
            })
    for prop in symbolic:
        benchmark = benchmark_map[prop["dut"]]
        clone = _hard_from_symbolic(prop, benchmark.slug)
        context, retrieved = _task_context(benchmark, clone, output_root)
        rows.append({
            "task_id": clone["property_id"], "difficulty": "HARD",
            "dut": clone["dut"], "module": benchmark.top_module,
            "statement": clone["theorem_statement"], "reference_proof": clone["reference_proof"],
            "context_import": "R5Foundation", "context": context,
            "context_hash": _hash_text(context), "retrieved_theorems": retrieved,
            "retrieval_hash": _hash_text(json.dumps(retrieved, sort_keys=True)),
            "foundation_lemmas": clone.get("foundation_lemmas", []),
            "property_family": clone["property_family"],
            "source_property_id": prop["property_id"],
            "calibration_origin": clone["calibration_origin"],
        })
    if len(rows) != 15 or any(row["task_id"] in challenge_ids for row in rows):
        raise ValueError("calibration task count or ID separation failed")
    if any(_hash_text(row["statement"]) in challenge_statements for row in rows):
        raise ValueError("calibration set overlaps a multi_phase_proofs bottleneck statement")
    return sorted(rows, key=lambda row: ({"EASY": 0, "MEDIUM": 1, "HARD": 2}[row["difficulty"]], row["dut"]))


def _api_config() -> dict[str, Any]:
    envs = sorted({row["api_key_env"] for row in MODELS})
    return {
        "schema": "rtl2lean-model_calibration-api-config-v1",
        "keys": [{"api_key_env": name, "api_key_present": bool(os.environ.get(name))} for name in envs],
        "actual_keys_recorded": False,
    }


def freeze_calibration(
    benchmarks: list[Benchmark], output_root: Path, requirement_root: Path,
) -> dict[str, Any]:
    manifests = requirement_root / "manifests"
    frozen_path = requirement_root / "calibration_manifest.json"
    write_json(manifests / "api_config.json", _api_config())
    if frozen_path.is_file():
        frozen = _read(frozen_path)
        for rel, expected in frozen["frozen_artifact_hashes"].items():
            path = requirement_root / rel
            if not path.is_file() or sha256(path) != expected:
                raise RuntimeError(f"frozen model_calibration artifact changed: {rel}")
        return frozen

    tasks = _make_tasks(benchmarks, output_root)
    validation_rows = []
    benchmark_map = {row.design_id: row for row in benchmarks}
    for task in tasks:
        benchmark = benchmark_map[task["dut"]]
        source = _proof_source(benchmark, {
            "property_id": task["task_id"], "theorem_statement": task["statement"],
        }, task["reference_proof"])
        path = manifests / "validation" / task["difficulty"].lower() / f"{task['task_id']}.lean"
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(source, encoding="utf-8")
        check = _lean_check(path, output_root / benchmark.slug / "model", 1200)
        validation_rows.append({
            "task_id": task["task_id"], "difficulty": task["difficulty"],
            "kernel_validated": check["success"], "check": check,
            "reference_proof_sha256": _hash_text(task["reference_proof"]),
        })
    if not all(row["kernel_validated"] for row in validation_rows):
        write_json(manifests / "validation.json", {"rows": validation_rows})
        raise RuntimeError("one or more calibration reference proofs failed Lean")

    models_payload = {
        "schema": "rtl2lean-model_calibration-models-v1", "frozen_before_api_calls": True,
        "models": MODELS,
        "provider_api": "Responses API", "model_selection_basis": "official provider model catalogs",
    }
    budgets_payload = {
        "schema": "rtl2lean-model_calibration-budgets-v1", "frozen_before_api_calls": True,
        **BUDGET,
    }
    seeds = [{
        "task_id": task["task_id"], "trial_id": trial,
        "paired_seed": int(_hash_text(f"r10a-v1:{task['task_id']}:{trial}")[:8], 16),
    } for task in tasks for trial in range(1, BUDGET["trials_per_task"] + 1)]
    seed_map = {(row["task_id"], row["trial_id"]): row["paired_seed"] for row in seeds}
    prompts = []
    for task in tasks:
        for trial in range(1, BUDGET["trials_per_task"] + 1):
            prompt = INITIAL_TEMPLATE.format(
                trial_nonce=seed_map[(task["task_id"], trial)],
                context_import=task["context_import"], namespace=f"{task['module']}Verification",
                open_namespace=task["module"], task_id=task["task_id"],
                statement=task["statement"], context=task["context"],
            )
            estimated = (len(prompt) + 3) // 4
            if estimated > BUDGET["max_input_tokens"]:
                raise RuntimeError(f"frozen prompt exceeds input budget: {task['task_id']}")
            prompts.append({
                "task_id": task["task_id"], "trial_id": trial, "prompt": prompt,
                "prompt_hash": _hash_text(prompt), "context_hash": task["context_hash"],
                "estimated_input_tokens": estimated,
            })
    theorem_base = {
        "schema": "rtl2lean-model_calibration-theorem-base-v1",
        "frozen_before_api_calls": True,
        "duts": [{
            "dut": benchmark.design_id, "slug": benchmark.slug,
            "theorem_base_hash": tree_digest(output_root / benchmark.slug / "model"),
            "files": [{"name": path.name, "sha256": sha256(path)}
                      for path in sorted((output_root / benchmark.slug / "model").glob("*.lean"))],
        } for benchmark in benchmarks],
    }
    tasks_payload = {
        "schema": "rtl2lean-model_calibration-tasks-v1", "frozen_before_api_calls": True,
        "task_count": len(tasks), "difficulty_counts": {
            level: sum(row["difficulty"] == level for row in tasks)
            for level in ("EASY", "MEDIUM", "HARD")
        },
        "excluded_multi_phase_proofs_bottleneck_challenges": True, "tasks": tasks,
    }
    payloads = {
        "manifests/models.json": models_payload,
        "manifests/tasks.json": tasks_payload,
        "manifests/prompts.json": {
            "schema": "rtl2lean-model_calibration-prompts-v1",
            "frozen_before_api_calls": True, "provider_specific_prompt_tuning": False,
            "initial_template": INITIAL_TEMPLATE, "repair_template": REPAIR_TEMPLATE,
            "rows": prompts,
        },
        "manifests/theorem_base.json": theorem_base,
        "manifests/budgets.json": budgets_payload,
        "manifests/seeds.json": {
            "schema": "rtl2lean-model_calibration-seeds-v1", "frozen_before_api_calls": True,
            "provider_rng_seed_exposed": False, "rows": seeds,
        },
        "manifests/validation.json": {"rows": validation_rows},
    }
    for rel, payload in payloads.items():
        write_json(requirement_root / rel, payload)
    hashes = {rel: sha256(requirement_root / rel) for rel in payloads}
    frozen = {
        "schema": "rtl2lean-model_calibration-calibration-manifest-v1",
        "freeze_time": datetime.now(timezone.utc).isoformat(), "frozen_before_api_calls": True,
        "task_count": 15, "model_count": 3, "trials_per_task": BUDGET["trials_per_task"],
        "expected_runs": 15 * 3 * BUDGET["trials_per_task"],
        "frozen_artifact_hashes": hashes,
    }
    write_json(frozen_path, frozen)
    return frozen
