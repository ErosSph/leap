"""Run the frozen Lemma-First matrix and kernel-check both proof stages."""
from __future__ import annotations

import hashlib
import json
import os
import re
import subprocess
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
from typing import Any

from rtl2lean.pipeline.compiler import find_lean
from rtl2lean.pipeline.io import sha256, write_json
from rtl2lean.pipeline.manifest import Benchmark
from rtl2lean.temporal_challenges.experiment import _proof_ast_size
from rtl2lean.compositional_proofs.report import tree_digest
from rtl2lean.model_calibration.backend import CodexCLIBackend, LLMBackend
from rtl2lean.model_calibration.runner import OPERATIONAL_FAILURES, classify_failure


FORBIDDEN = ("sorry", "admit", "native_decide", "axiom ", "unsafe")
LEMMA_SCHEMA = {
    "type": "object",
    "properties": {
        "lemma_name": {"type": "string"},
        "lemma_statement": {"type": "string"},
        "proof_body": {"type": "string"},
        "rationale": {"type": "string"},
    },
    "required": ["lemma_name", "lemma_statement", "proof_body", "rationale"],
    "additionalProperties": False,
}

TARGET_TEMPLATE = """Stage 1 of the frozen Lemma-First run succeeded: the intermediate theorem below
was checked by the Lean kernel. Now prove the exact frozen target and explicitly use the verified
intermediate theorem by name in proof_body.

Return only JSON with fields proof_body and rationale. proof_body must begin with `by`.
Never use sorry, admit, native_decide, axiom, unsafe, or unchecked code. Do not change the target.

Paired trial nonce (no proof information): {trial_nonce}
Import: {context_import}
Namespace: {namespace}
Open namespace: {open_namespace}
Target name: {task_id}
Target statement:
{statement}

Kernel-verified intermediate theorem available in this namespace:
theorem {lemma_name} : {lemma_statement} := {lemma_proof}

Frozen retrieved Lean context:
{context}
"""

LEMMA_REPAIR_TEMPLATE = """The stage-1 intermediate lemma candidate failed Lean checking.
Return only JSON with lemma_name, lemma_statement, proof_body, and rationale. If a valid previous
candidate exists, preserve its exact name and statement and repair only proof_body. Otherwise
produce a valid fresh intermediate lemma. It must remain strictly different from the frozen target.
All original safety and context restrictions remain in force.

Required lemma-name prefix: {lemma_prefix}
Frozen target name: {task_id}
Frozen target statement:
{statement}
Previous candidate:
{previous_candidate}
Lean/provider validation error:
{lean_error}
Frozen retrieved Lean context:
{context}
"""

TARGET_REPAIR_TEMPLATE = """The stage-2 target proof failed Lean checking. Repair the exact target.
Return only JSON with proof_body and rationale. proof_body must explicitly reference the
kernel-verified intermediate theorem `{lemma_name}`. Do not change the target or lemma and retain
all original safety constraints.

Target name: {task_id}
Target statement:
{statement}
Verified intermediate theorem:
theorem {lemma_name} : {lemma_statement} := {lemma_proof}
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


def _normalized(value: str) -> str:
    return re.sub(r"\s+", "", value)


def _check_source(source: str, model_root: Path, path: Path, timeout_s: int = 1200) -> dict[str, Any]:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(source, encoding="utf-8")
    env = os.environ.copy()
    env["LEAN_PATH"] = str(model_root) + (":" + env["LEAN_PATH"] if env.get("LEAN_PATH") else "")
    started = time.perf_counter()
    try:
        completed = subprocess.run(
            [find_lean(), "-s", "65536", str(path)], cwd=path.parent, env=env,
            capture_output=True, text=True, check=False, timeout=timeout_s,
        )
        return {
            "success": completed.returncode == 0, "returncode": completed.returncode,
            "stdout": completed.stdout[-16000:], "stderr": completed.stderr[-16000:],
            "elapsed_s": time.perf_counter() - started, "source": str(path),
            "source_sha256": sha256(path),
        }
    except subprocess.TimeoutExpired as error:
        return {
            "success": False, "returncode": 124, "stdout": str(error.stdout or "")[-16000:],
            "stderr": f"Lean kernel check timed out after {timeout_s}s",
            "elapsed_s": time.perf_counter() - started, "source": str(path),
            "source_sha256": sha256(path),
        }


def _declaration(task: dict[str, Any], name: str, statement: str, proof: str) -> str:
    return "\n".join([
        f"import {task['context_import']}", "", "set_option maxRecDepth 100000",
        "set_option maxHeartbeats 8000000", "", f"namespace {task['module']}Verification",
        f"open {task['module']}", "", f"theorem {name} : {statement} := {proof}", "",
        f"end {task['module']}Verification", "",
    ])


def _target_source(task: dict[str, Any], lemma: dict[str, str], proof: str) -> str:
    return "\n".join([
        f"import {task['context_import']}", "", "set_option maxRecDepth 100000",
        "set_option maxHeartbeats 8000000", "", f"namespace {task['module']}Verification",
        f"open {task['module']}", "",
        f"theorem {lemma['lemma_name']} : {lemma['lemma_statement']} := {lemma['proof_body']}", "",
        f"theorem {task['task_id']} : {task['statement']} := {proof}", "",
        f"end {task['module']}Verification", "",
    ])


def _synthetic_failure(message: str) -> dict[str, Any]:
    return {
        "success": False, "returncode": None, "stdout": "", "stderr": message,
        "elapsed_s": 0.0, "source": None, "source_sha256": None,
    }


def _validate_lemma_candidate(
    candidate: dict[str, Any] | None, task: dict[str, Any], prefix: str,
    fixed: dict[str, str] | None,
) -> str | None:
    if not candidate:
        return "provider did not return a structured intermediate lemma"
    name, statement, proof = (
        candidate.get("lemma_name"), candidate.get("lemma_statement"), candidate.get("proof_body")
    )
    if not all(isinstance(value, str) and value.strip() for value in (name, statement, proof)):
        return "intermediate lemma fields must be non-empty strings"
    if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_']*", name) or not name.startswith(prefix):
        return f"intermediate lemma name must be a safe identifier prefixed with {prefix}"
    if _normalized(statement) == _normalized(task["statement"]):
        return "intermediate lemma duplicates the complete target statement"
    if fixed and (name != fixed["lemma_name"] or _normalized(statement) != _normalized(fixed["lemma_statement"])):
        return "lemma repair changed the frozen intermediate name or statement"
    if any(token in f"{statement}\n{proof}".lower() for token in FORBIDDEN):
        return "intermediate lemma contains a forbidden unchecked construct"
    return None


def _runtime_models(requirement_root: Path) -> list[dict[str, Any]]:
    models = _read(requirement_root / "manifests" / "models.json")["models"]
    amendment_path = requirement_root / "manifests" / "transport_amendment_codex_fallback.json"
    amendment = _read(amendment_path)
    amendment_sha = sha256(amendment_path)
    return [{
        **model,
        **({
            "runtime_transport": "codex_cli", "credential_source": "codex_account_login",
            "transport_amendment_sha256": amendment_sha,
        } if model["model_key"] == amendment["affected_model_key"] else {}),
    } for model in models]


def _run_one(
    task: dict[str, Any], prompt_row: dict[str, Any], model: dict[str, Any],
    budget: dict[str, Any], benchmark: Benchmark, output_root: Path, requirement_root: Path,
    manifest_sha: str, theorem_base_hash: str, resume: bool,
) -> dict[str, Any]:
    trial = prompt_row["trial_id"]
    root = requirement_root / "runs" / model["model_key"] / f"trial_{trial:02d}" / task["task_id"]
    saved = root / "result.json"
    prior_history: list[dict[str, Any]] = []
    if resume and saved.is_file():
        prior = _read(saved)
        if prior.get("calibration_manifest_sha256") == manifest_sha:
            if prior.get("status") in {"SOLVED", "UNSOLVED"}:
                return prior
            prior_history = [
                *prior.get("operational_retry_history", []),
                {key: prior.get(key) for key in ("status", "failure_category", "wall_time_s", "api_statuses")},
            ]

    backend = CodexCLIBackend() if model.get("runtime_transport") == "codex_cli" else LLMBackend()
    started = time.perf_counter()
    attempts: list[dict[str, Any]] = []
    usage = {key: 0 for key in ("input_tokens", "output_tokens", "total_tokens", "reasoning_tokens")}
    api_statuses: list[str] = []
    stage = "INTERMEDIATE_LEMMA"
    prompt = prompt_row["prompt"]
    lemma: dict[str, str] | None = None
    fixed_failed_lemma: dict[str, str] | None = None
    final_proof: str | None = None
    final_check: dict[str, Any] | None = None
    operational_failure: str | None = None
    exhausted = False
    target_attempts = 0
    lemma_attempts = 0

    for call_index in range(1, budget["max_llm_calls"] + 1):
        estimated_input = (len(prompt) + 3) // 4
        if estimated_input > budget["max_input_tokens"] or usage["total_tokens"] >= budget["max_total_tokens"]:
            exhausted = True
            break
        schema = LEMMA_SCHEMA if stage == "INTERMEDIATE_LEMMA" else None
        generated = backend.generate(prompt, model, budget, schema)
        api_statuses.append(generated.status)
        for key in usage:
            usage[key] += generated.usage.get(key, 0)
        attempt: dict[str, Any] = {
            "call_index": call_index, "stage": stage,
            "stage_attempt": (lemma_attempts + 1) if stage == "INTERMEDIATE_LEMMA" else (target_attempts + 1),
            "prompt_sha256": _hash_text(prompt), "estimated_input_tokens": estimated_input,
            "api_status": generated.status, "api_elapsed_s": generated.elapsed_s,
            "usage": generated.usage, "response_metadata": generated.response_metadata,
            "response_error": generated.error, "candidate": generated.candidate,
            "generated_proof": generated.proof_body, "rationale": generated.rationale,
        }
        if stage == "INTERMEDIATE_LEMMA":
            lemma_attempts += 1
        else:
            target_attempts += 1
        if generated.status in OPERATIONAL_FAILURES:
            operational_failure = generated.status
            attempts.append(attempt)
            break

        if stage == "INTERMEDIATE_LEMMA":
            validation_error = _validate_lemma_candidate(
                generated.candidate, task, prompt_row["lemma_name_prefix"], fixed_failed_lemma,
            )
            if validation_error:
                check = _synthetic_failure(validation_error)
            else:
                candidate = generated.candidate or {}
                candidate_lemma = {
                    "lemma_name": candidate["lemma_name"],
                    "lemma_statement": candidate["lemma_statement"],
                    "proof_body": candidate["proof_body"],
                }
                check = _check_source(
                    _declaration(task, **{
                        "name": candidate_lemma["lemma_name"],
                        "statement": candidate_lemma["lemma_statement"],
                        "proof": candidate_lemma["proof_body"],
                    }),
                    output_root / benchmark.slug / "model",
                    root / "lean_checks" / f"attempt_{call_index:02d}_lemma.lean",
                )
                if fixed_failed_lemma is None:
                    fixed_failed_lemma = candidate_lemma
            attempt["kernel_check"] = check
            attempts.append(attempt)
            if check["success"]:
                lemma = candidate_lemma
                stage = "TARGET"
                prompt = TARGET_TEMPLATE.format(
                    trial_nonce=prompt_row["paired_seed"], context_import=task["context_import"],
                    namespace=f"{task['module']}Verification", open_namespace=task["module"],
                    task_id=task["task_id"], statement=task["statement"], context=task["context"],
                    lemma_name=lemma["lemma_name"], lemma_statement=lemma["lemma_statement"],
                    lemma_proof=lemma["proof_body"],
                )
            else:
                prompt = LEMMA_REPAIR_TEMPLATE.format(
                    lemma_prefix=prompt_row["lemma_name_prefix"], task_id=task["task_id"],
                    statement=task["statement"],
                    previous_candidate=json.dumps(generated.candidate, ensure_ascii=False, indent=2),
                    lean_error=(check["stdout"] + check["stderr"])[-16000:], context=task["context"],
                )
            continue

        proof = generated.proof_body
        if not lemma:
            check = _synthetic_failure("internal error: target stage lacks verified lemma")
        elif not proof:
            check = _synthetic_failure(generated.error or "target response lacks proof_body")
        elif any(token in proof.lower() for token in FORBIDDEN):
            check = _synthetic_failure("target proof contains a forbidden unchecked construct")
        elif not re.search(rf"(?<![A-Za-z0-9_']){re.escape(lemma['lemma_name'])}(?![A-Za-z0-9_'])", proof):
            check = _synthetic_failure("target proof does not explicitly use the verified intermediate lemma")
        else:
            check = _check_source(
                _target_source(task, lemma, proof), output_root / benchmark.slug / "model",
                root / "lean_checks" / f"attempt_{call_index:02d}_target.lean",
            )
        attempt["kernel_check"] = check
        attempts.append(attempt)
        final_proof, final_check = proof, check
        if check["success"] and usage["total_tokens"] <= budget["max_total_tokens"]:
            break
        prompt = TARGET_REPAIR_TEMPLATE.format(
            lemma_name=lemma["lemma_name"], lemma_statement=lemma["lemma_statement"],
            lemma_proof=lemma["proof_body"], task_id=task["task_id"], statement=task["statement"],
            previous_proof=proof or "", lean_error=(check["stdout"] + check["stderr"])[-16000:],
            context=task["context"],
        )

    final_pass = bool(
        lemma and final_check and final_check["success"] and not operational_failure
        and not exhausted and usage["total_tokens"] <= budget["max_total_tokens"]
    )
    if final_pass:
        status, failure, lean_category = "SOLVED", None, None
    elif operational_failure:
        status, failure, lean_category = operational_failure, operational_failure, None
    else:
        status = "UNSOLVED"
        last = attempts[-1] if attempts else {}
        metadata = last.get("response_metadata") or {}
        incomplete = metadata.get("incomplete_details") or {}
        error = ((last.get("kernel_check") or {}).get("stdout", "")
                 + (last.get("kernel_check") or {}).get("stderr", ""))
        proof = last.get("generated_proof")
        lean_category = classify_failure(
            error, proof, exhausted or incomplete.get("reason") == "max_output_tokens"
        )
        failure = (
            "TOKEN_BUDGET_EXHAUSTED" if lean_category == "TOKEN_BUDGET_EXHAUSTED"
            else f"{last.get('stage', stage)}_{lean_category}"
        )
        if len(attempts) >= budget["max_llm_calls"] and lean_category != "TOKEN_BUDGET_EXHAUSTED":
            failure = "REPAIR_BUDGET_EXHAUSTED"

    result = {
        "schema": "rtl2lean-model_comparison-run-v1",
        "calibration_manifest_sha256": manifest_sha,
        "task_id": task["task_id"], "difficulty": task["difficulty"], "dut": task["dut"],
        "provider": model["provider"], "model_key": model["model_key"], "model_id": model["model_id"],
        "transport": model.get("runtime_transport", "responses_api"),
        "credential_source": model.get("credential_source", "environment_api_key"),
        "transport_amendment_sha256": model.get("transport_amendment_sha256"),
        "strategy": "LEMMA_FIRST", "trial_id": trial,
        "prompt_hash": prompt_row["prompt_hash"], "context_hash": task["context_hash"],
        "theorem_base_hash": theorem_base_hash,
        "theorem_statement_sha256": _hash_text(task["statement"]),
        "initial_pass": final_pass and lemma_attempts == 1 and target_attempts == 1,
        "target_first_attempt_pass": final_pass and target_attempts == 1,
        "final_pass": final_pass, "status": status,
        "valid_proof_run": status not in OPERATIONAL_FAILURES,
        "proof_failure": status == "UNSOLVED", "failure_category": failure,
        "lean_error_category": lean_category,
        "intermediate_lemma_pass": lemma is not None,
        "intermediate_lemma": lemma, "intermediate_lemma_actual_reuse": bool(
            final_proof and lemma and lemma["lemma_name"] in final_proof
        ),
        "llm_calls": len(attempts), "lemma_attempts": lemma_attempts,
        "target_attempts": target_attempts,
        "repair_rounds": max(0, lemma_attempts - 1) + max(0, target_attempts - 1),
        **usage,
        "wall_time_s": time.perf_counter() - started,
        "lean_time_s": sum((row.get("kernel_check") or {}).get("elapsed_s", 0) for row in attempts),
        "api_statuses": api_statuses, "lean_kernel_result": "PASS" if final_pass else "FAIL",
        "generated_proof": final_proof,
        "proof_ast_size": _proof_ast_size(final_proof or "") if final_proof else None,
        "attempts": attempts, "operational_retry_history": prior_history,
    }
    write_json(saved, result)
    return result


def run_matrix(
    benchmarks: list[Benchmark], output_root: Path, requirement_root: Path,
    resume: bool = True, workers: int = 3,
) -> dict[str, Any]:
    frozen = _read(requirement_root / "calibration_manifest.json")
    models = _runtime_models(requirement_root)
    tasks = _read(requirement_root / "manifests" / "tasks.json")["tasks"]
    prompts = _read(requirement_root / "manifests" / "prompts.json")["rows"]
    budget = _read(requirement_root / "manifests" / "budgets.json")
    theorem_rows = _read(requirement_root / "manifests" / "theorem_base.json")["duts"]
    theorem_hashes = {row["dut"]: row["theorem_base_hash"] for row in theorem_rows}
    benchmark_map = {row.design_id: row for row in benchmarks}
    prompt_map = {(row["task_id"], row["trial_id"]): row for row in prompts}
    manifest_sha = sha256(requirement_root / "calibration_manifest.json")
    for benchmark in benchmarks:
        if tree_digest(output_root / benchmark.slug / "model") != theorem_hashes[benchmark.design_id]:
            raise RuntimeError(f"frozen theorem base changed for {benchmark.design_id}")
    jobs = [
        (task, prompt_map[(task["task_id"], trial)], model, budget,
         benchmark_map[task["dut"]], output_root, requirement_root, manifest_sha,
         theorem_hashes[task["dut"]], resume)
        for model in models for task in tasks
        for trial in range(1, frozen["trials_per_task"] + 1)
    ]
    results: list[dict[str, Any]] = []
    with ThreadPoolExecutor(max_workers=max(1, workers)) as executor:
        futures = [executor.submit(_run_one, *job) for job in jobs]
        for future in as_completed(futures):
            results.append(future.result())
            write_json(requirement_root / "run_progress.json", {
                "schema": "rtl2lean-model_comparison-progress-v1",
                "expected_runs": len(jobs), "completed_runs": len(results),
                "status_counts": {
                    status: sum(row["status"] == status for row in results)
                    for status in sorted({row["status"] for row in results})
                },
            })
    results.sort(key=lambda row: (row["model_key"], row["difficulty"], row["task_id"], row["trial_id"]))
    payload = {
        "schema": "rtl2lean-model_comparison-all-runs-v1",
        "calibration_manifest_sha256": manifest_sha, "rows": results,
    }
    write_json(requirement_root / "runs" / "all_results.json", payload)
    return payload
