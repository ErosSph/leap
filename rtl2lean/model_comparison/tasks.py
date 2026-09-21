"""Freeze a Lemma-First arm over the exact model_calibration tasks."""
from __future__ import annotations

import hashlib
import json
import os
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from rtl2lean.pipeline.io import sha256, write_json


LEMMA_TEMPLATE = """You are proving one frozen Lean 4 theorem in an audited Lemma-First calibration.
Return only one JSON object with fields lemma_name, lemma_statement, proof_body, and rationale.
proof_body must be a complete Lean term beginning with `by` and must prove lemma_statement.

This is stage 1 of Lemma-First. Propose one genuinely useful intermediate theorem that is
strictly different from the complete target, then prove it. The intermediate theorem must expose
a reusable fact that will materially help prove the target in stage 2. Do not merely rename,
restate, or wrap the complete target or an existing theorem.

Hard constraints:
- Never change, weaken, or restate the frozen target.
- Never use sorry, admit, native_decide, axiom, unsafe, or unchecked code.
- Use only the imported definitions and theorem context below.
- lemma_name must be a fresh Lean identifier prefixed with `{lemma_prefix}`.
- Prefer robust induction patterns and use the supplied Lean names exactly.

Paired trial nonce (no proof information): {trial_nonce}
Import: {context_import}
Namespace: {namespace}
Open namespace: {open_namespace}
Frozen target name: {task_id}
Frozen target statement:
{statement}

Identical retrieved Lean context for every model:
{context}
"""


def _read(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def _hash_text(value: str) -> str:
    return hashlib.sha256(value.encode()).hexdigest()


def freeze_lemma_first(output_root: Path, requirement_root: Path) -> dict[str, Any]:
    source = output_root / "model_calibration"
    source_report = _read(source / "final_report.json")
    if source_report["status"] != "PASS":
        raise RuntimeError("model_calibration must be complete before Lemma-First calibration")
    manifests = requirement_root / "manifests"
    write_json(manifests / "api_config.json", {
        "schema": "rtl2lean-model_comparison-api-config-v1",
        "keys": [
            {"api_key_env": name, "api_key_present": bool(os.environ.get(name))}
            for name in ("DEEPSEEK_API_KEY", "OPENAI_API_KEY")
        ],
        "gpt_effective_credential_source": "codex_account_login",
        "actual_keys_recorded": False,
    })
    frozen_path = requirement_root / "calibration_manifest.json"
    if frozen_path.is_file():
        frozen = _read(frozen_path)
        for rel, digest in frozen["frozen_artifact_hashes"].items():
            if sha256(requirement_root / rel) != digest:
                raise RuntimeError(f"frozen Lemma-First artifact changed: {rel}")
        return frozen

    source_tasks = _read(source / "manifests" / "tasks.json")
    source_models = _read(source / "manifests" / "models.json")
    source_budget = _read(source / "manifests" / "budgets.json")
    source_seeds = _read(source / "manifests" / "seeds.json")
    source_theorem = _read(source / "manifests" / "theorem_base.json")
    source_validation = _read(source / "manifests" / "validation.json")
    source_prompts = _read(source / "manifests" / "prompts.json")
    tasks = source_tasks["tasks"]
    if len(tasks) != 15 or source_tasks["difficulty_counts"] != {"EASY": 5, "MEDIUM": 5, "HARD": 5}:
        raise RuntimeError("source model_calibration task set is not the frozen balanced set")

    seed_map = {
        (row["task_id"], row["trial_id"]): row["paired_seed"]
        for row in source_seeds["rows"]
    }
    prompt_rows = []
    for task in tasks:
        for trial in range(1, source_budget["trials_per_task"] + 1):
            prefix = f"r10lf_{_hash_text(task['task_id'] + ':' + str(trial))[:10]}_"
            prompt = LEMMA_TEMPLATE.format(
                lemma_prefix=prefix,
                trial_nonce=seed_map[(task["task_id"], trial)],
                context_import=task["context_import"],
                namespace=f"{task['module']}Verification", open_namespace=task["module"],
                task_id=task["task_id"], statement=task["statement"], context=task["context"],
            )
            estimate = (len(prompt) + 3) // 4
            if estimate > source_budget["max_input_tokens"]:
                raise RuntimeError(f"Lemma-First prompt exceeds input budget: {task['task_id']}")
            prompt_rows.append({
                "task_id": task["task_id"], "trial_id": trial,
                "paired_seed": seed_map[(task["task_id"], trial)],
                "lemma_name_prefix": prefix, "prompt": prompt,
                "prompt_hash": _hash_text(prompt), "context_hash": task["context_hash"],
                "estimated_input_tokens": estimate,
            })

    budget = {
        **source_budget,
        "schema": "rtl2lean-model_comparison-budgets-v1",
        "strategy": "LEMMA_FIRST",
        "call_allocation": (
            "At most three calls total per run: obtain one kernel-verified intermediate lemma, "
            "then obtain a target proof that explicitly uses it; remaining calls repair the current stage."
        ),
        "minimum_successful_stage_calls": 2,
        "source_direct_budget_sha256": sha256(source / "manifests" / "budgets.json"),
    }
    direct = _read(source / "runs" / "all_results.json")
    direct_snapshot = {
        "schema": "rtl2lean-model_comparison-direct-snapshot-v1",
        "source_path": "outputs/model_calibration/runs/all_results.json",
        "source_sha256": sha256(source / "runs" / "all_results.json"),
        "rows": [{
            key: row[key] for key in (
                "model_key", "task_id", "trial_id", "difficulty", "final_pass",
                "initial_pass", "status", "valid_proof_run", "total_tokens", "wall_time_s",
            )
        } for row in direct["rows"]],
    }
    amendment = {
        "schema": "rtl2lean-model_comparison-transport-amendment-v1",
        "amendment_time": datetime.now(timezone.utc).isoformat(),
        "user_authorized": True, "affected_model_key": "gpt",
        "reason": "OPENAI_RESPONSES_AUTH_401_INVALID_API_KEY",
        "old_transport": {"kind": "responses_api", "credential_source": "OPENAI_API_KEY"},
        "new_transport": {
            "kind": "codex_cli", "credential_source": "codex_account_login",
            "model_id": "gpt-5.6-sol", "reasoning_profile": "high",
        },
        "same_limitations_as_direct_arm": True,
        "source_amendment_sha256": sha256(
            source / "manifests" / "transport_amendment_codex_fallback.json"
        ),
    }
    payloads = {
        "manifests/models.json": {**source_models, "schema": "rtl2lean-model_comparison-models-v1"},
        "manifests/tasks.json": {**source_tasks, "schema": "rtl2lean-model_comparison-tasks-v1"},
        "manifests/prompts.json": {
            "schema": "rtl2lean-model_comparison-prompts-v1",
            "frozen_before_model_calls": True, "provider_specific_prompt_tuning": False,
            "initial_lemma_template": LEMMA_TEMPLATE, "rows": prompt_rows,
        },
        "manifests/theorem_base.json": {
            **source_theorem, "schema": "rtl2lean-model_comparison-theorem-base-v1",
        },
        "manifests/budgets.json": budget,
        "manifests/seeds.json": {
            **source_seeds, "schema": "rtl2lean-model_comparison-seeds-v1",
        },
        "manifests/validation.json": {
            "schema": "rtl2lean-model_comparison-validation-v1",
            "source_validation_sha256": sha256(source / "manifests" / "validation.json"),
            **source_validation,
        },
        "manifests/direct_baseline_snapshot.json": direct_snapshot,
        "manifests/transport_amendment_codex_fallback.json": amendment,
        "manifests/source_bindings.json": {
            "schema": "rtl2lean-model_comparison-source-bindings-v1",
            "direct_calibration_manifest_sha256": sha256(source / "calibration_manifest.json"),
            "direct_tasks_sha256": sha256(source / "manifests" / "tasks.json"),
            "direct_models_sha256": sha256(source / "manifests" / "models.json"),
            "direct_theorem_base_sha256": sha256(source / "manifests" / "theorem_base.json"),
            "direct_seeds_sha256": sha256(source / "manifests" / "seeds.json"),
            "direct_runs_sha256": sha256(source / "runs" / "all_results.json"),
        },
    }
    for rel, payload in payloads.items():
        write_json(requirement_root / rel, payload)
    frozen = {
        "schema": "rtl2lean-model_comparison-calibration-manifest-v1",
        "freeze_time": datetime.now(timezone.utc).isoformat(),
        "frozen_before_model_calls": True, "strategy": "LEMMA_FIRST",
        "task_count": 15, "model_count": 3,
        "trials_per_task": source_budget["trials_per_task"], "expected_runs": 135,
        "frozen_artifact_hashes": {
            rel: sha256(requirement_root / rel) for rel in payloads
        },
    }
    write_json(frozen_path, frozen)
    return frozen
