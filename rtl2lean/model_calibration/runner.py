"""Execute the frozen 10A task/model/trial matrix and kernel-check every proof."""
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
from rtl2lean.model_calibration.tasks import REPAIR_TEMPLATE


OPERATIONAL_FAILURES = {"MISSING_API_KEY", "API_FAILURE", "RATE_LIMIT"}
FORBIDDEN = ("sorry", "admit", "native_decide", "axiom ", "unsafe")


def _read(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def _hash_text(value: str) -> str:
    return hashlib.sha256(value.encode()).hexdigest()


def _kernel_check(
    task: dict[str, Any], proof: str, benchmark: Benchmark, model_root: Path,
    source_path: Path, timeout_s: int = 1200,
) -> dict[str, Any]:
    source_path.parent.mkdir(parents=True, exist_ok=True)
    source = "\n".join([
        f"import {task['context_import']}", "",
        "set_option maxRecDepth 100000", "set_option maxHeartbeats 8000000", "",
        f"namespace {task['module']}Verification", f"open {task['module']}", "",
        f"theorem {task['task_id']} : {task['statement']} := {proof}", "",
        f"end {task['module']}Verification", "",
    ])
    source_path.write_text(source, encoding="utf-8")
    env = os.environ.copy()
    env["LEAN_PATH"] = str(model_root) + (":" + env["LEAN_PATH"] if env.get("LEAN_PATH") else "")
    started = time.perf_counter()
    try:
        completed = subprocess.run(
            [find_lean(), "-s", "65536", str(source_path)], cwd=source_path.parent,
            env=env, capture_output=True, text=True, check=False, timeout=timeout_s,
        )
        return {
            "success": completed.returncode == 0, "returncode": completed.returncode,
            "stdout": completed.stdout[-16000:], "stderr": completed.stderr[-16000:],
            "elapsed_s": time.perf_counter() - started, "source": str(source_path),
            "source_sha256": sha256(source_path),
        }
    except subprocess.TimeoutExpired as error:
        return {
            "success": False, "returncode": 124,
            "stdout": str(error.stdout or "")[-16000:],
            "stderr": f"Lean kernel check timed out after {timeout_s}s",
            "elapsed_s": time.perf_counter() - started, "source": str(source_path),
            "source_sha256": sha256(source_path),
        }


def classify_failure(error: str, proof: str | None, exhausted: bool = False) -> str:
    text = error.lower()
    if exhausted:
        return "TOKEN_BUDGET_EXHAUSTED"
    if proof is None or "unsolved goals" in text or "declaration uses 'sorry'" in text:
        return "INCOMPLETE_PROOF"
    if "unknown identifier" in text:
        return "UNKNOWN_IDENTIFIER"
    if "unexpected token" in text or "parser" in text or "syntax" in text:
        return "SYNTAX_ERROR"
    if "application type mismatch" in text or "type mismatch" in text or "failed to synthesize" in text:
        return "TYPE_ERROR"
    if "induction" in proof and ("motive" in text or "tactic 'induction' failed" in text):
        return "FAILED_INDUCTION"
    if "constructor" in proof or "and.intro" in proof.lower():
        return "FAILED_COMPOSITION"
    if re.search(r"\b(exact|apply|rw|simpa|simp)\b", proof):
        return "THEOREM_SELECTION_FAILURE"
    if re.search(r"\b(have|show|suffices)\b", proof):
        return "FAILED_INTERMEDIATE_REASONING"
    return "OTHER"


def normalize_result_classification(row: dict[str, Any]) -> dict[str, Any]:
    """Derive a stable terminal category from retained provider evidence."""
    row.setdefault("transport", "responses_api")
    row.setdefault("credential_source", "environment_api_key")
    row.setdefault("transport_amendment_sha256", None)
    if row.get("final_pass") or row.get("status") in OPERATIONAL_FAILURES:
        return row
    attempts = row.get("attempts", [])
    last = attempts[-1] if attempts else {}
    incomplete = (last.get("response_metadata") or {}).get("incomplete_details") or {}
    if incomplete.get("reason") == "max_output_tokens":
        row["failure_category"] = "TOKEN_BUDGET_EXHAUSTED"
        row["lean_error_category"] = "TOKEN_BUDGET_EXHAUSTED"
    return row


def _run_one(
    task: dict[str, Any], prompt_row: dict[str, Any], model: dict[str, Any],
    budget: dict[str, Any], benchmark: Benchmark, output_root: Path,
    requirement_root: Path, manifest_sha: str, theorem_base_hash: str, resume: bool,
) -> dict[str, Any]:
    trial = prompt_row["trial_id"]
    root = requirement_root / "runs" / model["model_key"] / f"trial_{trial:02d}" / task["task_id"]
    saved = root / "result.json"
    previous_operational: list[dict[str, Any]] = []
    if resume and saved.is_file():
        prior = _read(saved)
        if prior.get("calibration_manifest_sha256") == manifest_sha:
            if prior.get("status") in {"SOLVED", "UNSOLVED"}:
                normalized = normalize_result_classification(prior)
                write_json(saved, normalized)
                return normalized
            previous_operational = [
                *prior.get("operational_retry_history", []),
                {key: prior.get(key) for key in (
                    "status", "failure_category", "wall_time_s", "api_statuses",
                )},
            ]
    started = time.perf_counter()
    backend = CodexCLIBackend() if model.get("runtime_transport") == "codex_cli" else LLMBackend()
    attempts: list[dict[str, Any]] = []
    total_usage = {name: 0 for name in (
        "input_tokens", "output_tokens", "total_tokens", "reasoning_tokens",
    )}
    api_statuses: list[str] = []
    operational_failure: str | None = None
    final_proof: str | None = None
    final_check: dict[str, Any] | None = None
    initial_pass = False
    exhausted = False
    current_prompt = prompt_row["prompt"]
    previous_proof = ""
    last_error = ""
    for call_index in range(1, budget["max_llm_calls"] + 1):
        estimated_input = (len(current_prompt) + 3) // 4
        if estimated_input > budget["max_input_tokens"] or total_usage["total_tokens"] >= budget["max_total_tokens"]:
            exhausted = True
            break
        generated = backend.generate(current_prompt, model, budget)
        api_statuses.append(generated.status)
        for name in total_usage:
            total_usage[name] += generated.usage.get(name, 0)
        attempt: dict[str, Any] = {
            "call_index": call_index, "mode": "INITIAL" if call_index == 1 else "REPAIR",
            "prompt_sha256": _hash_text(current_prompt), "estimated_input_tokens": estimated_input,
            "api_status": generated.status, "api_elapsed_s": generated.elapsed_s,
            "usage": generated.usage, "response_metadata": generated.response_metadata,
            "response_error": generated.error, "generated_proof": generated.proof_body,
            "rationale": generated.rationale,
        }
        if generated.status in OPERATIONAL_FAILURES:
            operational_failure = generated.status
            attempts.append(attempt)
            break
        proof = generated.proof_body
        if proof and any(token in proof.lower() for token in FORBIDDEN):
            check = {
                "success": False, "returncode": None, "stdout": "",
                "stderr": "candidate contains a forbidden unchecked construct",
                "elapsed_s": 0.0, "source": None, "source_sha256": None,
            }
        elif proof:
            check = _kernel_check(
                task, proof, benchmark, output_root / benchmark.slug / "model",
                root / "lean_checks" / f"attempt_{call_index:02d}.lean",
            )
        else:
            check = {
                "success": False, "returncode": None, "stdout": "",
                "stderr": generated.error or "model response did not contain a valid proof_body",
                "elapsed_s": 0.0, "source": None, "source_sha256": None,
            }
        attempt["kernel_check"] = check
        attempts.append(attempt)
        final_proof, final_check = proof, check
        if check["success"] and total_usage["total_tokens"] <= budget["max_total_tokens"]:
            initial_pass = call_index == 1
            break
        last_error = check["stdout"] + check["stderr"]
        previous_proof = proof or ""
        if call_index <= budget["max_repair_rounds"]:
            current_prompt = REPAIR_TEMPLATE.format(
                task_id=task["task_id"], statement=task["statement"],
                previous_proof=previous_proof, lean_error=last_error[-16000:],
                context=task["context"],
            )
    final_pass = bool(final_check and final_check["success"] and not operational_failure and not exhausted)
    if final_pass:
        status, failure, lean_category = "SOLVED", None, None
    elif operational_failure:
        status, failure, lean_category = operational_failure, operational_failure, None
    else:
        status = "UNSOLVED"
        lean_category = classify_failure(last_error, final_proof, exhausted)
        failure = lean_category
        if len(attempts) >= budget["max_llm_calls"] and failure not in {"TOKEN_BUDGET_EXHAUSTED"}:
            failure = "REPAIR_BUDGET_EXHAUSTED"
    result = {
        "schema": "rtl2lean-model_calibration-run-v1",
        "calibration_manifest_sha256": manifest_sha,
        "task_id": task["task_id"], "difficulty": task["difficulty"],
        "dut": task["dut"], "provider": model["provider"],
        "model_key": model["model_key"], "model_id": model["model_id"],
        "transport": model.get("runtime_transport", "responses_api"),
        "credential_source": model.get("credential_source", "environment_api_key"),
        "transport_amendment_sha256": model.get("transport_amendment_sha256"),
        "trial_id": trial, "prompt_hash": prompt_row["prompt_hash"],
        "context_hash": task["context_hash"],
        "theorem_base_hash": theorem_base_hash,
        "theorem_statement_sha256": _hash_text(task["statement"]),
        "initial_pass": initial_pass, "final_pass": final_pass,
        "status": status, "valid_proof_run": status not in OPERATIONAL_FAILURES,
        "proof_failure": status == "UNSOLVED", "failure_category": failure,
        "lean_error_category": lean_category,
        "llm_calls": len(attempts),
        "repair_rounds": max(0, len(attempts) - 1),
        **total_usage,
        "wall_time_s": time.perf_counter() - started,
        "lean_time_s": sum((row.get("kernel_check") or {}).get("elapsed_s", 0.0) for row in attempts),
        "api_statuses": api_statuses, "lean_kernel_result": "PASS" if final_pass else "FAIL",
        "generated_proof": final_proof,
        "proof_ast_size": _proof_ast_size(final_proof or "") if final_proof else None,
        "attempts": attempts, "operational_retry_history": previous_operational,
    }
    result = normalize_result_classification(result)
    write_json(saved, result)
    return result


def run_matrix(
    benchmarks: list[Benchmark], output_root: Path, requirement_root: Path,
    resume: bool = True, workers: int = 3,
) -> dict[str, Any]:
    frozen = _read(requirement_root / "calibration_manifest.json")
    models = _read(requirement_root / "manifests" / "models.json")["models"]
    amendment_path = requirement_root / "manifests" / "transport_amendment_codex_fallback.json"
    if amendment_path.is_file():
        amendment = _read(amendment_path)
        if not amendment.get("user_authorized") or amendment.get("affected_model_key") != "gpt":
            raise RuntimeError("invalid Codex fallback transport amendment")
        amendment_sha = sha256(amendment_path)
        models = [
            {
                **model,
                "runtime_transport": "codex_cli",
                "credential_source": "codex_account_login",
                "transport_amendment_sha256": amendment_sha,
            } if model["model_key"] == "gpt" else model
            for model in models
        ]
    tasks = _read(requirement_root / "manifests" / "tasks.json")["tasks"]
    prompt_rows = _read(requirement_root / "manifests" / "prompts.json")["rows"]
    budget = _read(requirement_root / "manifests" / "budgets.json")
    theorem_rows = _read(requirement_root / "manifests" / "theorem_base.json")["duts"]
    theorem_hashes = {row["dut"]: row["theorem_base_hash"] for row in theorem_rows}
    benchmark_map = {row.design_id: row for row in benchmarks}
    task_map = {row["task_id"]: row for row in tasks}
    prompt_map = {(row["task_id"], row["trial_id"]): row for row in prompt_rows}
    manifest_sha = sha256(requirement_root / "calibration_manifest.json")
    for benchmark in benchmarks:
        actual = tree_digest(output_root / benchmark.slug / "model")
        if actual != theorem_hashes[benchmark.design_id]:
            raise RuntimeError(f"frozen theorem base changed for {benchmark.design_id}")
    jobs = [
        (task, prompt_map[(task["task_id"], trial)], model,
         budget, benchmark_map[task["dut"]], output_root, requirement_root, manifest_sha,
         theorem_hashes[task["dut"]], resume)
        for model in models for task in tasks
        for trial in range(1, frozen["trials_per_task"] + 1)
    ]
    results: list[dict[str, Any]] = []
    with ThreadPoolExecutor(max_workers=max(1, workers)) as executor:
        futures = {executor.submit(_run_one, *job): job for job in jobs}
        for future in as_completed(futures):
            results.append(future.result())
            write_json(requirement_root / "run_progress.json", {
                "schema": "rtl2lean-model_calibration-progress-v1",
                "expected_runs": len(jobs), "completed_runs": len(results),
                "status_counts": {
                    status: sum(row["status"] == status for row in results)
                    for status in sorted({row["status"] for row in results})
                },
            })
    results.sort(key=lambda row: (row["model_key"], row["difficulty"], row["task_id"], row["trial_id"]))
    payload = {
        "schema": "rtl2lean-model_calibration-all-runs-v1",
        "calibration_manifest_sha256": manifest_sha, "rows": results,
    }
    write_json(requirement_root / "runs" / "all_results.json", payload)
    return payload
