"""Direct and diagnosis-guided adaptive Lemma-First trial runners."""
from __future__ import annotations

import json
import re
import time
from pathlib import Path
from typing import Any

from .corpus import theorem_base_for
from .io import atomic_json, atomic_text, read_json, safe_name, sha256_text
from .lean import (
    FORBIDDEN_RE, check_source, synthetic_failure, target_with_lemma_source, theorem_source,
)
from .lemma_diagnosis import diagnose_lemma
from .prompts import (
    LEMMA_SCHEMA, TARGET_SCHEMA, direct_prompt, lemma_prompt, target_after_lemma_prompt,
)
from .proof_model import ProofModel


SUCCESS_API = "API_SUCCESS"
TERMINAL_CREDENTIAL_ERRORS = {"MISSING_API_KEY"}


def _normalized(value: str) -> str:
    return re.sub(r"\s+", "", value)


def _history_attempt(attempt: dict[str, Any]) -> dict[str, Any]:
    check = attempt.get("lean_result") or {}
    response = attempt.get("model_response") or {}
    candidate = response.get("candidate")
    return {
        "call_index": attempt["call_index"],
        "stage": attempt["stage"],
        "operation": attempt["operation"],
        "candidate": candidate,
        "api_status": response.get("status"),
        "lean_success": check.get("success"),
        "lean_error": (str(check.get("stdout") or "") + str(check.get("stderr") or ""))[-12000:],
        "proof_state": check.get("proof_state", ""),
        "diagnosis": attempt.get("diagnosis"),
    }


def _valid_proof(candidate: dict[str, Any] | None) -> str | None:
    if not isinstance(candidate, dict):
        return "structured response is not a JSON object"
    proof = candidate.get("proof_body")
    if not isinstance(proof, str) or not proof.lstrip().startswith("by"):
        return "proof_body must be a non-empty Lean proof beginning with `by`"
    if FORBIDDEN_RE.search(proof):
        return "proof_body contains a forbidden unchecked construct"
    if not isinstance(candidate.get("rationale"), str):
        return "rationale must be a string"
    if not isinstance(candidate.get("used_lemmas"), list):
        return "used_lemmas must be a list"
    return None


def _valid_lemma(
    candidate: dict[str, Any] | None, task: dict[str, Any], prefix: str,
    fixed: dict[str, str] | None, rejected: dict[str, str] | None, operation: str,
) -> str | None:
    error = _valid_proof(candidate)
    if error:
        return error
    assert candidate is not None
    name, statement = candidate.get("lemma_name"), candidate.get("lemma_statement")
    if not isinstance(name, str) or not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_']*", name):
        return "lemma_name must be a safe Lean identifier"
    if not name.startswith(prefix):
        return f"lemma_name must begin with frozen prefix {prefix}"
    if not isinstance(statement, str) or not statement.strip():
        return "lemma_statement must be a non-empty string"
    if FORBIDDEN_RE.search(statement):
        return "lemma_statement contains a forbidden unchecked construct"
    if _normalized(statement) == _normalized(task["statement"]):
        return "candidate lemma duplicates the complete target statement"
    if fixed and (
        name != fixed["lemma_name"]
        or _normalized(statement) != _normalized(fixed["lemma_statement"])
    ):
        return "LEMMA_PROOF_REPAIR changed the frozen lemma name or statement"
    if operation == "REDESIGN" and rejected and _normalized(statement) == _normalized(
        rejected["lemma_statement"]
    ):
        return "lemma redesign reproduced the rejected statement"
    return None


def _classify_lemma(candidate: dict[str, Any], theorem_base: list[dict[str, Any]]) -> str:
    statement = _normalized(candidate["lemma_statement"])
    for theorem in theorem_base:
        if statement == _normalized(str(theorem.get("statement") or "")):
            return "EXISTING_THEOREM_REUSE"
    proof = str(candidate.get("proof_body") or "")
    for theorem in theorem_base:
        name = str(theorem.get("name") or "")
        if name and re.search(rf"(?<![A-Za-z0-9_']){re.escape(name)}(?![A-Za-z0-9_'])", proof):
            theorem_tokens = set(re.findall(r"[A-Za-z_][A-Za-z0-9_']*", str(theorem.get("statement") or "")))
            lemma_tokens = set(re.findall(r"[A-Za-z_][A-Za-z0-9_']*", candidate["lemma_statement"]))
            overlap = len(theorem_tokens & lemma_tokens) / max(1, len(lemma_tokens))
            if overlap >= 0.55:
                return "DERIVED_SPECIALIZATION"
    return "NOVEL_INTERMEDIATE_LEMMA"


def _trial_root(run_dir: Path, phase: str, strategy: str, task: dict[str, Any], trial_id: int) -> Path:
    arm = "direct" if strategy == "direct" else "adaptive_lemma_first"
    return run_dir / phase / arm / task["challenge_id"] / f"trial_{trial_id:02d}"


def result_path(run_dir: Path, phase: str, strategy: str, task: dict[str, Any], trial_id: int) -> Path:
    return _trial_root(run_dir, phase, strategy, task, trial_id) / "result.json"


def _initial_state(
    strategy: str, task: dict[str, Any], trial_id: int, seed: int, run_manifest_sha256: str,
) -> dict[str, Any]:
    return {
        "schema": "rtl2lean-adaptive_proving-in-progress-v1",
        "status": "IN_PROGRESS",
        "strategy": strategy,
        "challenge_id": task["challenge_id"],
        "task_id": task["task_id"],
        "dut": task["dut"],
        "trial_id": trial_id,
        "seed": seed,
        "run_manifest_sha256": run_manifest_sha256,
        "stage": "TARGET" if strategy == "direct" else "LEMMA",
        "lemma_operation": "GENERATE",
        "attempts": [],
        "diagnoses": [],
        "verified_lemma": None,
        "current_lemma": None,
        "rejected_lemma": None,
        "lemma_redesign_count": 0,
        "abort_reason": None,
    }


def _load_state(
    root: Path, strategy: str, task: dict[str, Any], trial_id: int, seed: int,
    run_manifest_sha256: str,
) -> dict[str, Any]:
    saved = root / "result.json"
    if saved.is_file():
        result = read_json(saved)
        if result.get("run_manifest_sha256") != run_manifest_sha256:
            raise RuntimeError(f"completed trial is bound to another manifest: {saved}")
        return {"completed_result": result}
    state_path = root / "state.json"
    if state_path.is_file():
        state = read_json(state_path)
        expected = (strategy, task["challenge_id"], task["task_id"], trial_id, seed, run_manifest_sha256)
        observed = tuple(state[key] for key in (
            "strategy", "challenge_id", "task_id", "trial_id", "seed", "run_manifest_sha256",
        ))
        if observed != expected:
            raise RuntimeError(f"in-progress trial identity mismatch: {state_path}")
        _recover_orphaned_requests(root, state)
        return state
    state = _initial_state(strategy, task, trial_id, seed, run_manifest_sha256)
    atomic_json(state_path, state)
    return state


def _recover_orphaned_requests(root: Path, state: dict[str, Any]) -> None:
    """Count requests whose delivery was uncertain when the process was interrupted.

    This fails closed: an HTTP request marker consumes one call even if no response was
    persisted, so resume can never silently exceed the frozen proof-model call budget.
    """
    known = {row["call_index"] for row in state["attempts"]}
    changed = False
    for marker_path in sorted((root / "calls").glob("call_*/request_started.json")):
        marker = read_json(marker_path)
        index = int(marker["call_index"])
        if index in known:
            continue
        response_path = marker_path.with_name("response.json")
        if response_path.is_file():
            response = read_json(response_path)
        else:
            response = {
                "status": "INTERRUPTED_OR_UNKNOWN", "candidate": None, "raw_text": "",
                "usage": {}, "elapsed_s": 0.0,
                "metadata": {"request_delivery": "uncertain", "seed": state["seed"]},
                "error": "process interrupted after request marker; call conservatively counted",
            }
        state["attempts"].append({
            "call_index": index, "stage": marker["stage"], "operation": marker["operation"],
            "prompt_path": marker["prompt_path"], "prompt_sha256": marker["prompt_sha256"],
            "model_response": response, "processing_status": "MODEL_RESPONSE_SAVED",
        })
        known.add(index)
        changed = True
    if changed:
        state["attempts"].sort(key=lambda row: row["call_index"])
        atomic_json(root / "state.json", state)


def _persist_model_response(
    root: Path, state: dict[str, Any], stage: str, operation: str, prompt: str,
    schema: dict[str, Any], model: ProofModel,
) -> dict[str, Any]:
    call_index = len(state["attempts"]) + 1
    call_root = root / "calls" / f"call_{call_index:02d}"
    prompt_path = call_root / "prompt.txt"
    atomic_text(prompt_path, prompt)
    atomic_json(call_root / "request_started.json", {
        "schema": "rtl2lean-adaptive_proving-request-marker-v1",
        "call_index": call_index, "stage": stage, "operation": operation,
        "prompt_path": str(prompt_path.relative_to(root)), "prompt_sha256": sha256_text(prompt),
        "seed": state["seed"], "response_persisted": False,
    })
    generated = model.generate(prompt, schema, state["seed"])
    response = generated.serializable()
    atomic_json(call_root / "response.json", response)
    marker = read_json(call_root / "request_started.json")
    marker["response_persisted"] = True
    atomic_json(call_root / "request_started.json", marker)
    attempt = {
        "call_index": call_index,
        "stage": stage,
        "operation": operation,
        "prompt_path": str(prompt_path.relative_to(root)),
        "prompt_sha256": sha256_text(prompt),
        "model_response": response,
        "processing_status": "MODEL_RESPONSE_SAVED",
    }
    state["attempts"].append(attempt)
    atomic_json(root / "state.json", state)
    return attempt


def _check_direct_attempt(
    project: Path, root: Path, state: dict[str, Any], task: dict[str, Any], config: dict[str, Any],
    attempt: dict[str, Any],
) -> None:
    response = attempt["model_response"]
    candidate = response.get("candidate")
    validation_error = _valid_proof(candidate)
    if response.get("status") != SUCCESS_API:
        check = synthetic_failure(response.get("error") or response.get("status") or "model failure")
    elif validation_error:
        check = synthetic_failure(validation_error)
    else:
        proof = candidate["proof_body"]
        source = theorem_source(task, task["task_id"], task["statement"], proof)
        check = check_source(
            source, project / task["model_dir"],
            root / "lean_checks" / f"call_{attempt['call_index']:02d}_target.lean",
            int(config["lean_timeout_seconds"]),
        )
    attempt["lean_result"] = check
    attempt["processing_status"] = "CHECKED"
    atomic_json(root / "state.json", state)


def _diagnosis_report_path(run_dir: Path, task: dict[str, Any], trial_id: int, index: int) -> Path:
    return run_dir / "diagnosis" / "reports" / (
        f"challenge_{task['challenge_id']}_trial{trial_id}_diag{index:02d}.json"
    )


def _diagnose_attempt(
    run_dir: Path, state: dict[str, Any], task: dict[str, Any], trial_id: int,
    theorem_base: dict[str, Any], attempt: dict[str, Any], candidate: dict[str, Any],
) -> dict[str, Any]:
    lemma_attempts = [row for row in state["attempts"] if row["stage"] == "LEMMA"]
    compact = [_history_attempt(row) for row in lemma_attempts]
    check = attempt["lean_result"]
    report = diagnose_lemma(
        target=task["statement"],
        candidate_lemma=candidate,
        proof_attempts=compact,
        lean_errors=[str(row["lean_result"].get("stdout") or "")
                     + str(row["lean_result"].get("stderr") or "") for row in lemma_attempts],
        proof_states=[str(row["lean_result"].get("proof_state") or "") for row in lemma_attempts],
        local_context="\n".join([task["context"], *task["relevant_foundational_lemmas"]]),
        theorem_base=theorem_base["theorems"],
        verified_context=[state["verified_lemma"]] if state.get("verified_lemma") else [],
    ).serializable()
    attempt["diagnosis"] = report
    diagnosis_index = len(state["diagnoses"]) + 1
    diagnosis_row = {
        "schema": "rtl2lean-adaptive_proving-diagnosis-v1",
        "challenge_id": task["challenge_id"],
        "task_id": task["task_id"],
        "trial_id": trial_id,
        "lemma_id": "L2" if state["lemma_redesign_count"] else "L1",
        "candidate_statement": candidate.get("lemma_statement", ""),
        "candidate_name": candidate.get("lemma_name", ""),
        "candidate_proof": candidate.get("proof_body", ""),
        "proof_attempt_number": len(lemma_attempts),
        "lean_result": "FAIL",
        "lean_error": (str(check.get("stdout") or "") + str(check.get("stderr") or ""))[-16000:],
        "proof_state": check.get("proof_state", ""),
        "local_hypotheses": check.get("local_hypotheses", []),
        **report,
        "next_candidate": None,
        "eventual_result": "PENDING",
    }
    state["diagnoses"].append(diagnosis_row)
    atomic_json(_diagnosis_report_path(run_dir, task, trial_id, diagnosis_index), diagnosis_row)
    return report


def _check_adaptive_lemma_attempt(
    project: Path, run_dir: Path, root: Path, state: dict[str, Any], task: dict[str, Any],
    trial_id: int, config: dict[str, Any], theorem_base: dict[str, Any], attempt: dict[str, Any],
) -> None:
    response = attempt["model_response"]
    candidate = response.get("candidate") if isinstance(response.get("candidate"), dict) else {}
    fixed = state.get("current_lemma") if attempt["operation"] == "REPAIR" else None
    error = _valid_lemma(
        candidate, task, _lemma_prefix(task, trial_id), fixed, state.get("rejected_lemma"),
        attempt["operation"],
    )
    if response.get("status") != SUCCESS_API:
        check = synthetic_failure(response.get("error") or response.get("status") or "model failure")
    elif error:
        check = synthetic_failure(error)
    else:
        check = check_source(
            theorem_source(
                task, candidate["lemma_name"], candidate["lemma_statement"], candidate["proof_body"]
            ),
            project / task["model_dir"],
            root / "lean_checks" / f"call_{attempt['call_index']:02d}_lemma.lean",
            int(config["lean_timeout_seconds"]),
        )
    attempt["lean_result"] = check
    attempt["processing_status"] = "CHECKED"
    if check["success"]:
        lemma = {
            "lemma_name": candidate["lemma_name"],
            "lemma_statement": candidate["lemma_statement"],
            "proof_body": candidate["proof_body"],
            "used_lemmas": candidate.get("used_lemmas", []),
            "classification": _classify_lemma(candidate, theorem_base["theorems"]),
            "kernel_result": "PASS",
            "verified_at_call": attempt["call_index"],
            "verified_after_action": attempt["operation"],
        }
        state["verified_lemma"] = lemma
        state["stage"] = "TARGET"
        state["lemma_operation"] = None
    elif response.get("status") == SUCCESS_API:
        # Diagnosis is local and deliberately follows every candidate-lemma failure.
        report = _diagnose_attempt(run_dir, state, task, trial_id, theorem_base, attempt, candidate)
        action = report["recommended_action"]
        if action == "REPAIR":
            if candidate.get("lemma_name") and candidate.get("lemma_statement"):
                state["current_lemma"] = {
                    "lemma_name": candidate["lemma_name"],
                    "lemma_statement": candidate["lemma_statement"],
                    "proof_body": candidate.get("proof_body", ""),
                }
                state["lemma_operation"] = "REPAIR"
            else:
                state["abort_reason"] = "diagnosis requested repair without a fixable lemma identity"
        elif action == "REDESIGN" and state["lemma_redesign_count"] < int(config["max_lemma_redesign"]):
            state["rejected_lemma"] = {
                "lemma_name": candidate.get("lemma_name", ""),
                "lemma_statement": candidate.get("lemma_statement", ""),
                "proof_body": candidate.get("proof_body", ""),
            }
            state["lemma_redesign_count"] += 1
            state["current_lemma"] = None
            state["lemma_operation"] = "REDESIGN"
        else:
            state["abort_reason"] = (
                f"diagnosis action {action} cannot continue with redesign budget "
                f"{state['lemma_redesign_count']}/{config['max_lemma_redesign']}"
            )
        state["diagnoses"][-1]["next_candidate"] = (
            "L2" if state["lemma_operation"] == "REDESIGN" else
            state["diagnoses"][-1]["lemma_id"] if state["lemma_operation"] == "REPAIR" else None
        )
        atomic_json(
            _diagnosis_report_path(run_dir, task, trial_id, len(state["diagnoses"])),
            state["diagnoses"][-1],
        )
    elif response.get("status") in TERMINAL_CREDENTIAL_ERRORS:
        state["abort_reason"] = response.get("status")
    atomic_json(root / "state.json", state)


def _check_adaptive_target_attempt(
    project: Path, root: Path, state: dict[str, Any], task: dict[str, Any], config: dict[str, Any],
    attempt: dict[str, Any],
) -> None:
    response = attempt["model_response"]
    candidate = response.get("candidate")
    error = _valid_proof(candidate)
    lemma = state["verified_lemma"]
    if response.get("status") != SUCCESS_API:
        check = synthetic_failure(response.get("error") or response.get("status") or "model failure")
    elif error:
        check = synthetic_failure(error)
    elif not re.search(
        rf"(?<![A-Za-z0-9_']){re.escape(lemma['lemma_name'])}(?![A-Za-z0-9_'])",
        candidate["proof_body"],
    ):
        check = synthetic_failure("final target proof does not explicitly use the verified intermediate lemma")
    else:
        check = check_source(
            target_with_lemma_source(task, lemma, candidate["proof_body"]),
            project / task["model_dir"],
            root / "lean_checks" / f"call_{attempt['call_index']:02d}_target.lean",
            int(config["lean_timeout_seconds"]),
        )
    attempt["lean_result"] = check
    attempt["processing_status"] = "CHECKED"
    atomic_json(root / "state.json", state)


def _lemma_prefix(task: dict[str, Any], trial_id: int) -> str:
    return f"r10c_{task['challenge_id'].lower()}_t{trial_id}_"


def _usage(attempts: list[dict[str, Any]]) -> dict[str, int]:
    keys = ("input_tokens", "output_tokens", "total_tokens", "reasoning_tokens", "cached_tokens")
    return {
        key: sum(int((row.get("model_response") or {}).get("usage", {}).get(key) or 0) for row in attempts)
        for key in keys
    }


def _finalize(
    run_dir: Path, root: Path, state: dict[str, Any], task: dict[str, Any], phase: str,
    strategy: str, theorem_base: dict[str, Any], config: dict[str, Any],
) -> dict[str, Any]:
    attempts = state["attempts"]
    successful = next((row for row in attempts if row.get("lean_result", {}).get("success")
                       and row["stage"] == "TARGET"), None)
    final_pass = successful is not None
    first_success = successful["call_index"] if successful else None
    diagnoses = state.get("diagnoses", [])
    for index, report in enumerate(diagnoses, 1):
        report["eventual_result"] = "PASS" if final_pass else "FAIL"
        atomic_json(_diagnosis_report_path(run_dir, task, state["trial_id"], index), report)
    usage = _usage(attempts)
    status = "PASS" if final_pass else "FAIL"
    if not final_pass and state.get("abort_reason") == "MISSING_API_KEY":
        status = "OPERATIONAL_FAILURE"
    wall_time = sum(float((row.get("model_response") or {}).get("elapsed_s") or 0)
                    + float((row.get("lean_result") or {}).get("elapsed_s") or 0)
                    + float((row.get("diagnosis") or {}).get("diagnosis_time_s") or 0)
                    for row in attempts)
    verified = state.get("verified_lemma")
    direct_like = strategy == "direct"
    repair_count = sum(row["operation"] == "REPAIR" and row["stage"] == "LEMMA" for row in attempts)
    decision_counts = {
        action: sum(row["recommended_action"] == action for row in diagnoses)
        for action in ("REPAIR", "REDESIGN", "ABORT", "UNKNOWN")
    }
    result = {
        "schema": "rtl2lean-adaptive_proving-trial-v1",
        "completed": True,
        "run_manifest_sha256": state["run_manifest_sha256"],
        "phase": phase,
        "challenge_id": task["challenge_id"],
        "task_id": task["task_id"],
        "dut": task["dut"],
        "strategy": strategy,
        "trial_id": state["trial_id"],
        "seed": state["seed"],
        "status": status,
        "final_pass": final_pass,
        "final_target_lean_result": "PASS" if final_pass else "FAIL",
        "first_success_call": first_success,
        "calls_to_success": first_success,
        "tokens_to_success": sum(
            int((row.get("model_response") or {}).get("usage", {}).get("total_tokens") or 0)
            for row in attempts[:first_success]
        ) if first_success else None,
        "wall_time_to_success": wall_time if first_success else None,
        "success_by_checkpoint": {
            str(checkpoint): bool(first_success and first_success <= checkpoint)
            for checkpoint in config["checkpoints"]
        },
        "model_calls": len(attempts),
        "usage": usage,
        "wall_time_s": wall_time,
        "theorem_statement_sha256": task["statement_sha256"],
        "retrieved_context_sha256": task["context_sha256"],
        "theorem_base_sha256": theorem_base["tree_sha256"],
        "candidate_lemma_count": 0 if direct_like else sum(
            row["stage"] == "LEMMA" and row["operation"] in {"GENERATE", "REDESIGN"}
            for row in attempts
        ),
        "diagnosis_count": 0 if direct_like else len(diagnoses),
        "proof_repair_count": 0 if direct_like else repair_count,
        "lemma_redesign_count": 0 if direct_like else state["lemma_redesign_count"],
        "diagnosis_decision_counts": decision_counts if not direct_like else {},
        "repair_then_lemma_pass_count": int(bool(verified and verified["verified_after_action"] == "REPAIR")),
        "redesign_then_lemma_pass_count": int(bool(verified and verified["verified_after_action"] == "REDESIGN")),
        "diagnosis1_repair_diagnosis2_redesign": bool(
            len(diagnoses) >= 2
            and diagnoses[0]["recommended_action"] == "REPAIR"
            and diagnoses[1]["recommended_action"] == "REDESIGN"
        ),
        "avoided_invalid_repairs": sum(bool(row.get("avoided_invalid_repair")) for row in diagnoses),
        "verified_intermediate_lemma": verified,
        "intermediate_lemma_kernel_pass": bool(verified),
        "intermediate_lemma_used_by_final": bool(
            verified and successful and re.search(
                rf"(?<![A-Za-z0-9_']){re.escape(verified['lemma_name'])}(?![A-Za-z0-9_'])",
                str((successful.get("model_response") or {}).get("candidate", {}).get("proof_body") or ""),
            )
        ),
        "diagnosis_guided_rescue": bool(final_pass and diagnoses),
        "strict_decomposition_rescue": None,
        "strict_decomposition_rescue_scope": "computed only after paired Direct/Adaptive analysis",
        "abort_reason": state.get("abort_reason"),
        "attempts": attempts,
        "diagnoses": diagnoses,
    }
    atomic_json(root / "result.json", result, overwrite=False)
    state["status"] = "COMPLETED"
    state["result_sha256"] = sha256_text(json.dumps(result, ensure_ascii=False, sort_keys=True))
    atomic_json(root / "state.json", state)
    return result


def run_trial(
    project: Path, run_dir: Path, phase: str, strategy: str, task: dict[str, Any],
    trial_id: int, seed: int, config: dict[str, Any], source: dict[str, Any],
    run_manifest_sha256: str, model: ProofModel,
) -> dict[str, Any]:
    """Run or resume one independent trial without replacing a completed result."""
    root = _trial_root(run_dir, phase, strategy, task, trial_id)
    state = _load_state(root, strategy, task, trial_id, seed, run_manifest_sha256)
    if "completed_result" in state:
        return state["completed_result"]
    theorem_base = theorem_base_for(source, task["dut"])
    max_calls = int(config["max_total_calls"])
    while len(state["attempts"]) < max_calls and not state.get("abort_reason"):
        pending = next((row for row in state["attempts"]
                        if row.get("processing_status") == "MODEL_RESPONSE_SAVED"), None)
        if pending is None:
            if strategy == "direct":
                history = [_history_attempt(row) for row in state["attempts"]]
                prompt = direct_prompt(task, seed, history)
                pending = _persist_model_response(root, state, "TARGET", "GENERATE" if not history else "REPAIR",
                                                  prompt, TARGET_SCHEMA, model)
            elif state["stage"] == "LEMMA":
                operation = state["lemma_operation"]
                history = [_history_attempt(row) for row in state["attempts"] if row["stage"] == "LEMMA"]
                prompt = lemma_prompt(
                    task, seed, _lemma_prefix(task, trial_id), operation,
                    candidate=state.get("current_lemma") or state.get("rejected_lemma"),
                    diagnosis=state["diagnoses"][-1] if state["diagnoses"] else None,
                    history=history,
                )
                pending = _persist_model_response(root, state, "LEMMA", operation, prompt, LEMMA_SCHEMA, model)
            else:
                target_history = [_history_attempt(row) for row in state["attempts"] if row["stage"] == "TARGET"]
                prompt = target_after_lemma_prompt(task, seed, state["verified_lemma"], target_history)
                pending = _persist_model_response(
                    root, state, "TARGET", "GENERATE" if not target_history else "REPAIR",
                    prompt, TARGET_SCHEMA, model,
                )

        if strategy == "direct":
            _check_direct_attempt(project, root, state, task, config, pending)
        elif pending["stage"] == "LEMMA":
            _check_adaptive_lemma_attempt(
                project, run_dir, root, state, task, trial_id, config, theorem_base, pending,
            )
        else:
            _check_adaptive_target_attempt(project, root, state, task, config, pending)

        if pending["stage"] == "TARGET" and pending["lean_result"]["success"]:
            break
        if pending["model_response"]["status"] in TERMINAL_CREDENTIAL_ERRORS:
            state["abort_reason"] = pending["model_response"]["status"]
            atomic_json(root / "state.json", state)
            break
        if pending["model_response"]["status"] == "RATE_LIMIT":
            time.sleep(min(10, 2 ** min(3, pending["call_index"])))

    return _finalize(run_dir, root, state, task, phase, strategy, theorem_base, config)
