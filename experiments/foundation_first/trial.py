"""One resumable foundation-first lemma-discovery trial."""
from __future__ import annotations

import json
import re
import time
from pathlib import Path
from typing import Any

from experiments.adaptive_proving.lean import FORBIDDEN_RE, synthetic_failure
from experiments.adaptive_proving.lemma_diagnosis import diagnose_lemma
from experiments.adaptive_proving.proof_model import ProofModel
from experiments.adaptive_proving.io import atomic_json, atomic_text, read_json, sha256_text

from .corpus import theorem_base_for
from .proof_gap import extract_proof_gap, retrieve_lemmas
from .prompts import LEMMA_SCHEMA, candidate_prompt
from .prover import kernel_gate, run_property_prover


def _normal(value: str) -> str:
    return re.sub(r"\s+", "", value)


def _prefix(task: dict[str, Any], trial_id: int) -> str:
    return f"r11_{task['challenge_id'].lower()}_t{trial_id}_"


def _candidate_error(
    candidate: Any, task: dict[str, Any], prefix: str, operation: str,
    fixed: dict[str, str] | None, rejected: dict[str, str] | None,
) -> str | None:
    if not isinstance(candidate, dict):
        return "structured response is not a JSON object"
    name, statement, proof = candidate.get("lemma_name"), candidate.get("lemma_statement"), candidate.get("proof_body")
    if not isinstance(name, str) or not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_']*", name):
        return "lemma_name must be a safe Lean identifier"
    if not name.startswith(prefix):
        return f"lemma_name must begin with {prefix}"
    if not isinstance(statement, str) or not statement.strip():
        return "lemma_statement must be non-empty"
    if re.match(r"^\s*(?:theorem|lemma)\b", statement) or ":=" in statement:
        return "lemma_statement contains a declaration header; expected proposition only"
    if not isinstance(proof, str) or not proof.lstrip().startswith("by"):
        return "proof_body must begin with by"
    if FORBIDDEN_RE.search(statement + "\n" + proof):
        return "candidate contains a forbidden unchecked construct"
    if _normal(statement) == _normal(task["statement"]):
        return "candidate duplicates the complete target"
    if fixed and operation == "REPAIR" and (
        name != fixed["lemma_name"] or _normal(statement) != _normal(fixed["lemma_statement"])
    ):
        return "REPAIR changed the frozen lemma name or statement"
    if rejected and operation == "REDESIGN" and _normal(statement) == _normal(rejected["lemma_statement"]):
        return "REDESIGN repeated the rejected statement"
    return None


def _classification(candidate: dict[str, Any], theorems: list[dict[str, Any]]) -> str:
    statement = _normal(candidate["lemma_statement"])
    if any(statement == _normal(str(row.get("statement") or "")) for row in theorems):
        return "EXISTING_THEOREM_DUPLICATE"
    return "NOVEL_CANDIDATE_LEMMA"


def _save_model_call(
    root: Path, state: dict[str, Any], model: ProofModel, prompt: str, operation: str,
) -> dict[str, Any]:
    index = len(state["candidate_attempts"]) + 1
    call_root = root / "calls" / f"call_{index:02d}"
    atomic_text(call_root / "prompt.txt", prompt)
    marker = {
        "schema": "rtl2lean-foundation_first-request-marker-v1", "call_index": index,
        "operation": operation, "prompt_sha256": sha256_text(prompt), "seed": state["seed"],
        "response_persisted": False,
    }
    atomic_json(call_root / "request_started.json", marker)
    response = model.generate(prompt, LEMMA_SCHEMA, state["seed"]).serializable()
    atomic_json(call_root / "response.json", response)
    marker["response_persisted"] = True
    atomic_json(call_root / "request_started.json", marker)
    attempt = {"call_index": index, "operation": operation, "prompt_sha256": sha256_text(prompt),
               "model_response": response, "processing_status": "MODEL_RESPONSE_SAVED"}
    state["candidate_attempts"].append(attempt)
    atomic_json(root / "state.json", state)
    return attempt


def _recover(root: Path, state: dict[str, Any]) -> None:
    known = {row["call_index"] for row in state["candidate_attempts"]}
    changed = False
    for path in sorted((root / "calls").glob("call_*/request_started.json")):
        marker = read_json(path); index = int(marker["call_index"])
        if index in known:
            continue
        response_path = path.with_name("response.json")
        response = read_json(response_path) if response_path.is_file() else {
            "status": "INTERRUPTED_OR_UNKNOWN", "candidate": None, "raw_text": "", "usage": {},
            "elapsed_s": 0.0, "metadata": {"request_delivery": "uncertain"},
            "error": "interrupted request conservatively consumes one candidate call",
        }
        state["candidate_attempts"].append({
            "call_index": index, "operation": marker["operation"],
            "prompt_sha256": marker["prompt_sha256"], "model_response": response,
            "processing_status": "MODEL_RESPONSE_SAVED",
        })
        changed = True
    if changed:
        state["candidate_attempts"].sort(key=lambda row: row["call_index"])
        atomic_json(root / "state.json", state)


def _diagnose(
    state: dict[str, Any], task: dict[str, Any], base: dict[str, Any], attempt: dict[str, Any],
    candidate: dict[str, Any], selected_but_ineffective: bool = False,
    validation_error: str | None = None,
) -> dict[str, Any]:
    if validation_error and "repeated the rejected statement" in validation_error:
        report = {
            "failure_level": "SELECTION", "primary_cause": "LEMMA_SELECTION_FAILURE",
            "secondary_causes": [], "statement_plausibility": "UNKNOWN", "target_relevance": "UNKNOWN",
            "proof_progress": "STALLED", "recommended_action": "REDESIGN",
            "evidence": ["REDESIGN repeated the exact rejected proposition"], "repair_guidance": [],
            "redesign_guidance": ["Change the proposition structurally; do not only rename or re-prove it."],
            "core_unsolved_goal": validation_error, "goal_similarity_to_previous": 1.0,
            "avoided_invalid_repair": True, "diagnosis_time_s": 0.0,
        }
    elif selected_but_ineffective:
        report = {
            "failure_level": "SELECTION", "primary_cause": "LOW_TARGET_UTILITY",
            "secondary_causes": [], "statement_plausibility": "HIGH", "target_relevance": "LOW",
            "proof_progress": "STALLED", "recommended_action": "REDESIGN",
            "evidence": ["candidate passed kernel gate", "deterministic property retry still failed"],
            "repair_guidance": [],
            "redesign_guidance": ["Choose a bridge matching the residual temporal endpoint relation."],
            "core_unsolved_goal": "", "goal_similarity_to_previous": None,
            "avoided_invalid_repair": True, "diagnosis_time_s": 0.0,
        }
    else:
        lemma_attempts = [row for row in state["candidate_attempts"] if row.get("kernel_result")]
        checks = [row["kernel_result"] for row in lemma_attempts]
        history = [{"proof_state": row.get("kernel_result", {}).get("proof_state", ""),
                    "candidate": row.get("model_response", {}).get("candidate") or {},
                    "diagnosis": row.get("diagnosis")} for row in lemma_attempts]
        report = diagnose_lemma(
            task["statement"], candidate, history,
            [str(row.get("stdout") or "") + str(row.get("stderr") or "") for row in checks],
            [str(row.get("proof_state") or "") for row in checks],
            "\n".join(row["statement"] for row in state["retrieved_lemmas"]),
            base["theorems"], state["verified_lemmas"],
        ).serializable()
    report["avoid_in_next_candidate"] = list(dict.fromkeys([
        *report.get("redesign_guidance", []),
        "Do not repeat a previously rejected statement.",
        "Do not restate the complete target.",
    ]))
    attempt["diagnosis"] = report
    state["diagnoses"].append(report)
    return report


def _usage(attempts: list[dict[str, Any]]) -> dict[str, int]:
    keys = ("input_tokens", "output_tokens", "total_tokens", "reasoning_tokens", "cached_tokens")
    return {key: sum(int(row.get("model_response", {}).get("usage", {}).get(key) or 0)
                     for row in attempts) for key in keys}


def run_trial(
    project: Path, run_dir: Path, task: dict[str, Any], trial_id: int, seed: int,
    config: dict[str, Any], source: dict[str, Any], manifest_hash: str, model: ProofModel,
) -> dict[str, Any]:
    root = run_dir / "trials" / task["challenge_id"] / f"trial_{trial_id:02d}"
    result_path = root / "result.json"
    if result_path.is_file():
        result = read_json(result_path)
        if result["run_manifest_sha256"] != manifest_hash:
            raise RuntimeError("completed trial belongs to another run manifest")
        return result
    state_path = root / "state.json"
    if state_path.is_file():
        state = read_json(state_path)
        _recover(root, state)
    else:
        state = {
            "schema": "rtl2lean-foundation_first-state-v1", "status": "IN_PROGRESS",
            "challenge_id": task["challenge_id"], "task_id": task["task_id"], "trial_id": trial_id,
            "seed": seed, "run_manifest_sha256": manifest_hash, "foundation_result": None,
            "proof_gap": None, "retrieved_lemmas": [], "candidate_attempts": [], "diagnoses": [],
            "verified_lemmas": [], "operation": "DISCOVER", "current_candidate": None,
            "rejected_candidate": None, "redesign_count": 0, "property_rescue": None,
        }
        atomic_json(state_path, state)
    base = theorem_base_for(source, task["dut"])
    if state["foundation_result"] is None:
        state["retrieved_lemmas"] = retrieve_lemmas(
            task["statement"], base["theorems"], int(config["retrieval_limit"])
        )
        state["foundation_result"] = run_property_prover(
            project, root / "foundation_only", task, int(config["lean_timeout_seconds"])
        )
        if not state["foundation_result"]["success"]:
            state["proof_gap"] = extract_proof_gap(
                task, base["theorems"], state["retrieved_lemmas"], state["foundation_result"],
                config["proof_gap_policy"]["version"],
            )
            atomic_json(root / "proof_gap_observation.json", state["proof_gap"])
        atomic_json(state_path, state)

    rescue = state.get("property_rescue")
    if not state["foundation_result"]["success"] and rescue is None:
        while len(state["candidate_attempts"]) < int(config["max_candidate_calls"]):
            pending = next((row for row in state["candidate_attempts"]
                            if row["processing_status"] == "MODEL_RESPONSE_SAVED"), None)
            if pending is None:
                prompt = candidate_prompt(
                    task, state["proof_gap"], state["retrieved_lemmas"], seed, _prefix(task, trial_id),
                    state["operation"], state.get("current_candidate") or state.get("rejected_candidate"),
                    state["diagnoses"][-1] if state["diagnoses"] else None, state["verified_lemmas"],
                )
                pending = _save_model_call(root, state, model, prompt, state["operation"])
            response = pending["model_response"]
            candidate = response.get("candidate") if isinstance(response.get("candidate"), dict) else {}
            fixed = state.get("current_candidate") if pending["operation"] == "REPAIR" else None
            error = _candidate_error(candidate, task, _prefix(task, trial_id), pending["operation"],
                                     fixed, state.get("rejected_candidate"))
            if response.get("status") != "API_SUCCESS":
                check = synthetic_failure(response.get("error") or response.get("status") or "model failure")
            elif error:
                check = synthetic_failure(error)
            else:
                check = kernel_gate(
                    project, root / "kernel_checks" / f"call_{pending['call_index']:02d}_lemma.lean",
                    task, candidate, int(config["lean_timeout_seconds"]),
                )
            pending["kernel_result"] = check
            pending["processing_status"] = "CHECKED"
            if check["success"]:
                verified = {**candidate, "kernel_result": "PASS", "verified_at_call": pending["call_index"],
                            "verified_after_action": pending["operation"],
                            "classification": _classification(candidate, base["theorems"])}
                state["verified_lemmas"].append(verified)
                property_result = run_property_prover(
                    project, root / "property_retry" / f"call_{pending['call_index']:02d}", task,
                    int(config["lean_timeout_seconds"]), verified,
                )
                pending["property_retry"] = property_result
                if property_result["success"]:
                    proof = property_result["successful_proof_body"]
                    used = bool(re.search(rf"(?<![A-Za-z0-9_']){re.escape(candidate['lemma_name'])}(?![A-Za-z0-9_'])", proof))
                    ablation = run_property_prover(
                        project, root / "ablation_without_candidate", task,
                        int(config["lean_timeout_seconds"]), None,
                    )
                    rescue = {
                        "status": "PROPERTY_RESCUED_BY_LLM_LEMMA" if used and not ablation["success"] else "PROPERTY_PASS_NOT_ATTRIBUTABLE",
                        "candidate": verified, "final_property_result": property_result,
                        "candidate_name_occurs_in_final_proof": used,
                        "ablation_without_candidate_pass": ablation["success"],
                        "verified_lemma_used_by_final": used and not ablation["success"],
                    }
                    state["property_rescue"] = rescue
                    atomic_json(state_path, state)
                    break
                report = _diagnose(state, task, base, pending, candidate, selected_but_ineffective=True)
            elif response.get("status") == "API_SUCCESS":
                report = _diagnose(state, task, base, pending, candidate, validation_error=error)
            else:
                report = None
            if report:
                action = report["recommended_action"]
                if action == "REPAIR" and candidate.get("lemma_name") and candidate.get("lemma_statement"):
                    state["current_candidate"] = candidate; state["operation"] = "REPAIR"
                elif action == "REDESIGN" and state["redesign_count"] < int(config["max_lemma_redesign"]):
                    state["rejected_candidate"] = candidate; state["current_candidate"] = None
                    state["redesign_count"] += 1; state["operation"] = "REDESIGN"
                else:
                    state["operation"] = "REDESIGN" if state["redesign_count"] < int(config["max_lemma_redesign"]) else "EXHAUSTED"
            if state["operation"] == "EXHAUSTED" or response.get("status") == "MISSING_API_KEY":
                atomic_json(state_path, state); break
            atomic_json(state_path, state)

    attempts = state["candidate_attempts"]
    first_pass = bool(attempts and attempts[0].get("kernel_result", {}).get("success"))
    later_pass = any(row.get("kernel_result", {}).get("success") for row in attempts[1:])
    repair_success = any(row["operation"] == "REPAIR" and row.get("kernel_result", {}).get("success") for row in attempts)
    redesign_success = any(row["operation"] == "REDESIGN" and row.get("kernel_result", {}).get("success") for row in attempts)
    result = {
        "schema": "rtl2lean-foundation_first-trial-v1", "completed": True,
        "run_manifest_sha256": manifest_hash, "challenge_id": task["challenge_id"],
        "task_id": task["task_id"], "dut": task["dut"], "trial_id": trial_id, "seed": seed,
        "foundation_only_pass": state["foundation_result"]["success"],
        "llm_assisted_property_pass": state["foundation_result"]["success"] or bool(rescue and rescue["final_property_result"]["success"]),
        "result_status": "FOUNDATION_ONLY_PASS" if state["foundation_result"]["success"] else
                         rescue["status"] if rescue else "NOT_RESCUED",
        "first_candidate_kernel_pass": first_pass,
        "feedback_candidate_kernel_pass": later_pass,
        "repair_success": repair_success, "redesign_success": redesign_success,
        "candidate_count": sum(row["operation"] in {"DISCOVER", "REDESIGN"} for row in attempts),
        "model_calls": len(attempts), "usage": _usage(attempts),
        "api_wall_time_s": sum(float(row["model_response"].get("elapsed_s") or 0) for row in attempts),
        "proof_gap": state["proof_gap"], "foundation_result": state["foundation_result"],
        "candidate_attempts": attempts, "diagnoses": state["diagnoses"],
        "verified_lemmas": state["verified_lemmas"], "property_rescue": rescue,
        "candidate_existing_theorem_duplicate": any(
            row.get("classification") == "EXISTING_THEOREM_DUPLICATE" for row in state["verified_lemmas"]
        ),
    }
    atomic_json(result_path, result, overwrite=False)
    state["status"] = "COMPLETED"; state["result_sha256"] = sha256_text(json.dumps(result, sort_keys=True))
    atomic_json(state_path, state)
    return result
