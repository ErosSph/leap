"""Resumable bridge-guided statement selection, proof, repair, and redesign."""
from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any

from experiments.adaptive_proving.io import atomic_json, atomic_text, read_json, sha256_text
from experiments.adaptive_proving.lean import FORBIDDEN_RE, synthetic_failure
from experiments.adaptive_proving.lemma_diagnosis import diagnose_lemma
from experiments.adaptive_proving.proof_model import ProofModel
from experiments.foundation_first.proof_gap import extract_proof_gap, retrieve_lemmas

from .bridge import build_bridge_specification, build_global_bridge_view
from .corpus import theorem_base_for
from .prompts import PROOF_SCHEMA, STATEMENT_SCHEMA, proof_prompt, statement_prompt
from .prover import formal_kernel_gate, run_delete_lemma_replay, run_foundation_prover, run_property_retry
from .repair_templates import lookup
from .utility import evaluate_candidate


def _normal(value: str) -> str:
    return re.sub(r"\s+", "", value)


def _prefix(task: dict[str, Any], trial_id: int) -> str:
    return f"r12_{task['challenge_id'].lower()}_t{trial_id}_"


def _statement_error(candidate: Any, task: dict[str, Any], prefix: str,
                     prior: list[dict[str, Any]]) -> str | None:
    if not isinstance(candidate, dict):
        return "candidate is not an object"
    name, statement = candidate.get("lemma_name"), candidate.get("lemma_statement")
    if not isinstance(name, str) or not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_']*", name):
        return "lemma_name must be a safe Lean identifier"
    if not name.startswith(prefix):
        return f"lemma_name must begin with {prefix}"
    if not isinstance(statement, str) or not statement.strip():
        return "lemma_statement must be non-empty"
    if re.match(r"^\s*(?:theorem|lemma)\b", statement) or ":=" in statement:
        return "lemma_statement must be a proposition only"
    if FORBIDDEN_RE.search(statement):
        return "lemma_statement contains a forbidden unchecked construct"
    if _normal(statement) == _normal(task["statement"]):
        return "candidate duplicates the complete target"
    if any(_normal(statement) == _normal(row.get("lemma_statement", "")) for row in prior):
        return "candidate repeats a previously rejected statement"
    required = ("new_candidate_source", "new_candidate_target", "how_it_bridges_gap",
                "which_previous_failure_is_avoided")
    if any(not isinstance(candidate.get(key), str) or not candidate[key].strip() for key in required):
        return "candidate is missing required bridge explanation fields"
    return None


def _proof_error(proof: Any) -> str | None:
    if not isinstance(proof, dict):
        return "proof response is not an object"
    body = proof.get("proof_body")
    if not isinstance(body, str) or not body.lstrip().startswith("by"):
        return "proof_body must begin with by"
    if FORBIDDEN_RE.search(body):
        return "proof contains a forbidden unchecked construct"
    return None


def _usage(calls: list[dict[str, Any]]) -> dict[str, int]:
    keys = ("input_tokens", "output_tokens", "total_tokens", "reasoning_tokens", "cached_tokens")
    return {key: sum(int(row.get("model_response", {}).get("usage", {}).get(key) or 0)
                     for row in calls) for key in keys}


def _call(root: Path, state: dict[str, Any], model: ProofModel, prompt: str,
          schema: dict[str, Any], operation: str) -> dict[str, Any]:
    index = len(state["model_calls"]) + 1
    call_root = root / "calls" / f"call_{index:02d}"
    atomic_text(call_root / "prompt.txt", prompt)
    marker = {"schema": "rtl2lean-bridge_discovery-request-marker-v1", "call_index": index,
              "operation": operation, "prompt_sha256": sha256_text(prompt),
              "seed": state["seed"] + index - 1, "response_persisted": False}
    atomic_json(call_root / "request_started.json", marker)
    response = model.generate(prompt, schema, marker["seed"]).serializable()
    atomic_json(call_root / "response.json", response)
    marker["response_persisted"] = True
    atomic_json(call_root / "request_started.json", marker)
    row = {"call_index": index, "operation": operation, "prompt_sha256": sha256_text(prompt),
           "model_response": response, "processing_status": "MODEL_RESPONSE_SAVED"}
    state["model_calls"].append(row); atomic_json(root / "state.json", state)
    return row


def _recover(root: Path, state: dict[str, Any]) -> None:
    known = {row["call_index"] for row in state["model_calls"]}
    changed = False
    for path in sorted((root / "calls").glob("call_*/request_started.json")):
        marker = read_json(path); index = int(marker["call_index"])
        if index in known:
            continue
        response_path = path.with_name("response.json")
        response = read_json(response_path) if response_path.is_file() else {
            "status": "INTERRUPTED_OR_UNKNOWN", "candidate": None, "raw_text": "", "usage": {},
            "elapsed_s": 0.0, "metadata": {"request_delivery": "uncertain"},
            "error": "interrupted request conservatively consumes one call"}
        state["model_calls"].append({"call_index": index, "operation": marker["operation"],
            "prompt_sha256": marker["prompt_sha256"], "model_response": response,
            "processing_status": "MODEL_RESPONSE_SAVED"}); changed = True
    if changed:
        state["model_calls"].sort(key=lambda row: row["call_index"]); atomic_json(root / "state.json", state)


def _diagnose(task: dict[str, Any], base: dict[str, Any], state: dict[str, Any],
              candidate: dict[str, Any], check: dict[str, Any]) -> dict[str, Any]:
    history = [{"proof_state": row.get("kernel_result", {}).get("proof_state", ""),
                "candidate": row.get("formal_candidate", {}), "diagnosis": row.get("diagnosis")}
               for row in state["proof_attempts"]]
    result = diagnose_lemma(task["statement"], candidate, history,
        [str(check.get("stdout") or "") + str(check.get("stderr") or "")],
        [str(check.get("proof_state") or "")],
        "\n".join(row["statement"] for row in state["retrieved_lemmas"]),
        base["theorems"], state["verified_lemmas"]).serializable()
    result["repair_template"] = lookup(result["primary_cause"])
    result["avoid_in_next_candidate"] = list(dict.fromkeys([
        *result.get("redesign_guidance", []), "Do not repeat a rejected statement.",
        "Connect an available source premise to the named target frontier."]))
    state["diagnoses"].append(result)
    return result


def run_trial(project: Path, run_dir: Path, task: dict[str, Any], trial_id: int, seed: int,
              config: dict[str, Any], source: dict[str, Any], manifest_hash: str,
              model: ProofModel) -> dict[str, Any]:
    root = run_dir / "trials" / task["challenge_id"] / f"trial_{trial_id:02d}"
    result_path = root / "result.json"
    if result_path.is_file():
        result = read_json(result_path)
        if result["run_manifest_sha256"] != manifest_hash:
            raise RuntimeError("completed trial belongs to another run manifest")
        return result
    state_path = root / "state.json"
    if state_path.is_file():
        state = read_json(state_path); _recover(root, state)
    else:
        state = {"schema": "rtl2lean-bridge_discovery-state-v1", "status": "IN_PROGRESS",
            "challenge_id": task["challenge_id"], "task_id": task["task_id"], "trial_id": trial_id,
            "seed": seed, "run_manifest_sha256": manifest_hash, "foundation_result": None,
            "proof_gap": None, "bridge_specification": None, "global_bridge_view": None,
            "retrieved_lemmas": [], "model_calls": [], "statement_rounds": [], "proof_attempts": [],
            "diagnoses": [], "verified_lemmas": [], "rejected_candidates": [],
            "current_candidate": None, "current_utility": None, "repair_context": None,
            "next_stage": "STATEMENT_DISCOVER", "redesign_count": 0, "property_rescue": None}
        atomic_json(state_path, state)
    base = theorem_base_for(source, task["dut"])
    timeout = int(config["lean_timeout_seconds"])
    if state["foundation_result"] is None:
        state["retrieved_lemmas"] = retrieve_lemmas(task["statement"], base["theorems"],
                                                    int(config["retrieval_limit"]))
        state["foundation_result"] = run_foundation_prover(project, root / "foundation_only", task, timeout)
        if not state["foundation_result"]["success"]:
            state["proof_gap"] = extract_proof_gap(task, base["theorems"], state["retrieved_lemmas"],
                state["foundation_result"], "bridge_discovery-gap-v1")
            state["bridge_specification"] = build_bridge_specification(task, state["proof_gap"])
            state["global_bridge_view"] = build_global_bridge_view(task, state["proof_gap"],
                                                                   state["bridge_specification"])
            atomic_json(root / "proof_gap_observation.json", state["proof_gap"])
            atomic_json(root / "bridge_specification.json", state["bridge_specification"])
            atomic_json(root / "global_bridge_view.json", state["global_bridge_view"])
        atomic_json(state_path, state)

    while (not state["foundation_result"]["success"] and not state["property_rescue"]
           and len(state["model_calls"]) < int(config["max_total_calls"])):
        stage = state["next_stage"]
        if stage in {"STATEMENT_DISCOVER", "STATEMENT_REDESIGN"}:
            previous = None
            if state["rejected_candidates"]:
                previous = {"previous_candidate": state["rejected_candidates"][-1],
                    "failure_diagnosis": state["diagnoses"][-1] if state["diagnoses"] else None,
                    "lean_evidence": state["proof_attempts"][-1].get("kernel_result") if state["proof_attempts"] else None,
                    "requirements_still_open": state["bridge_specification"]["target_frontier"],
                    "available_source_facts": state["bridge_specification"]["source_frontier"],
                    "avoid_in_next_candidate": (state["diagnoses"][-1].get("avoid_in_next_candidate", [])
                                                 if state["diagnoses"] else state["bridge_specification"]["candidate_avoid"])}
            operation = "REDESIGN" if stage == "STATEMENT_REDESIGN" else "DISCOVER"
            prompt = statement_prompt(task, state["proof_gap"], state["bridge_specification"],
                state["global_bridge_view"], state["retrieved_lemmas"], seed,
                _prefix(task, trial_id), operation, previous)
            call = _call(root, state, model, prompt, STATEMENT_SCHEMA, f"{operation}_STATEMENTS")
            response = call["model_response"]
            slate = response.get("candidate") if response.get("status") == "API_SUCCESS" else {}
            candidates = slate.get("candidates", []) if isinstance(slate, dict) else []
            round_row = {"operation": operation, "call_index": call["call_index"], "candidates": []}
            for position, candidate in enumerate(candidates, 1):
                error = _statement_error(candidate, task, _prefix(task, trial_id), state["rejected_candidates"])
                utility = (evaluate_candidate(project,
                    root / "utility_checks" / f"call_{call['call_index']:02d}_candidate_{position:02d}",
                    task, candidate, state["bridge_specification"], base["theorems"], timeout,
                    float(config["utility_policy"]["medium_structural_score"]))
                    if error is None else {"classification": "LOW_TARGET_UTILITY", "accepted": False,
                        "reason": error, "proof_attempt_avoided": True, "temporary_assumption_only": True})
                round_row["candidates"].append({"position": position, "candidate_statement": candidate,
                    "validation_error": error, "utility_result": utility,
                    "proof_gap_observation": state["proof_gap"],
                    "bridge_specification": state["bridge_specification"],
                    "global_bridge_view": state["global_bridge_view"]})
            accepted = [row for row in round_row["candidates"] if row["utility_result"].get("accepted")]
            accepted.sort(key=lambda row: (row["utility_result"]["classification"] == "HIGH_TARGET_UTILITY",
                                            row["utility_result"].get("structural_score", 0)), reverse=True)
            if accepted:
                selected = accepted[0]; selected["selected_for_proof"] = True
                state["current_candidate"] = selected["candidate_statement"]
                state["current_utility"] = selected["utility_result"]
                state["repair_context"] = None; state["next_stage"] = "PROOF"
            else:
                state["rejected_candidates"].extend(row["candidate_statement"] for row in round_row["candidates"]
                                                     if isinstance(row["candidate_statement"], dict))
                round_row["round_status"] = ("REDESIGN_BRIDGE_FAILURE" if operation == "REDESIGN"
                                              else "ALL_INITIAL_CANDIDATES_LOW")
                if state["redesign_count"] < int(config["max_statement_redesign"]):
                    state["redesign_count"] += 1; state["next_stage"] = "STATEMENT_REDESIGN"
                else:
                    state["next_stage"] = "EXHAUSTED"
            state["statement_rounds"].append(round_row); call["processing_status"] = "CHECKED"
        elif stage in {"PROOF", "REPAIR_PROOF"}:
            operation = "REPAIR" if stage == "REPAIR_PROOF" else "PROVE"
            candidate = state["current_candidate"]
            prompt = proof_prompt(task, state["proof_gap"], state["retrieved_lemmas"], seed,
                                  candidate, state["current_utility"], state["repair_context"])
            call = _call(root, state, model, prompt, PROOF_SCHEMA, operation)
            response = call["model_response"]
            proof = response.get("candidate") if response.get("status") == "API_SUCCESS" else {}
            error = _proof_error(proof)
            formal = {**candidate, "proof_body": proof.get("proof_body", "")}
            check = (formal_kernel_gate(project, root / "kernel_checks" / f"call_{call['call_index']:02d}.lean",
                                        task, formal, timeout) if error is None
                     else synthetic_failure(error or response.get("error") or response.get("status", "model failure")))
            attempt = {"call_index": call["call_index"], "operation": operation,
                "candidate_statement": candidate, "utility_result": state["current_utility"],
                "proof_response": proof, "formal_candidate": formal, "validation_error": error,
                "kernel_result": check, "proof_gap_observation": state["proof_gap"],
                "bridge_specification": state["bridge_specification"],
                "global_bridge_view": state["global_bridge_view"], "repair_template": None}
            state["proof_attempts"].append(attempt); call["processing_status"] = "CHECKED"
            if check["success"]:
                verified = {**formal, "kernel_result": "PASS", "verified_at_call": call["call_index"],
                            "verified_after_action": operation, "utility_result": state["current_utility"]}
                state["verified_lemmas"].append(verified)
                retry = run_property_retry(project, root / "property_retry" / f"call_{call['call_index']:02d}",
                                           task, timeout, verified)
                attempt["final_property_result"] = retry
                if retry["success"]:
                    final_proof = retry["successful_proof_body"] or ""
                    used = bool(re.search(rf"(?<![A-Za-z0-9_']){re.escape(formal['lemma_name'])}(?![A-Za-z0-9_'])",
                                          final_proof))
                    ablation = run_delete_lemma_replay(project, root / "delete_lemma_replay.lean",
                                                       task, final_proof, timeout)
                    attributable = used and not ablation["success"]
                    state["property_rescue"] = {"status": ("PROPERTY_RESCUED_BY_LLM_LEMMA" if attributable
                        else "PROPERTY_PASS_NOT_ATTRIBUTABLE"), "candidate": verified,
                        "final_property_result": retry, "candidate_name_occurs_in_final_proof": used,
                        "delete_lemma_replay_pass": ablation["success"],
                        "verified_lemma_used_by_final": attributable}
                    state["next_stage"] = "DONE"
                else:
                    state["rejected_candidates"].append(candidate)
                    state["current_candidate"] = None; state["current_utility"] = None
                    state["next_stage"] = "STATEMENT_REDESIGN"
                    state["redesign_count"] += 1
            else:
                diagnosis = _diagnose(task, base, state, formal, check); attempt["diagnosis"] = diagnosis
                attempt["repair_template"] = diagnosis.get("repair_template")
                if operation == "PROVE" and diagnosis.get("repair_template"):
                    state["repair_context"] = {"diagnosis": diagnosis,
                                               "repair_template": diagnosis["repair_template"],
                                               "lean_evidence": check}
                    state["next_stage"] = "REPAIR_PROOF"
                else:
                    state["rejected_candidates"].append(candidate)
                    state["current_candidate"] = None; state["current_utility"] = None
                    if state["redesign_count"] < int(config["max_statement_redesign"]):
                        state["redesign_count"] += 1; state["next_stage"] = "STATEMENT_REDESIGN"
                    else:
                        state["next_stage"] = "EXHAUSTED"
        else:
            break
        atomic_json(state_path, state)

    rescue = state.get("property_rescue")
    first_round = state["statement_rounds"][0] if state["statement_rounds"] else {"candidates": []}
    first_selected = next((row for row in first_round["candidates"] if row.get("selected_for_proof")), None)
    redesign_rounds = [row for row in state["statement_rounds"] if row["operation"] == "REDESIGN"]
    result = {"schema": "rtl2lean-bridge_discovery-trial-v1", "completed": True,
        "run_manifest_sha256": manifest_hash, "challenge_id": task["challenge_id"],
        "task_id": task["task_id"], "dut": task["dut"], "trial_id": trial_id, "seed": seed,
        "foundation_only_pass": state["foundation_result"]["success"],
        "llm_invoked": bool(state["model_calls"]),
        "llm_assisted_property_pass": state["foundation_result"]["success"] or bool(
            rescue and rescue["final_property_result"]["success"]),
        "result_status": ("FOUNDATION_ONLY_PASS" if state["foundation_result"]["success"] else
                          rescue["status"] if rescue else "NOT_RESCUED"),
        "first_candidate_utility_pass": bool(first_selected),
        "first_candidate_statement_accepted": bool(first_selected),
        "first_candidate_kernel_pass": bool(state["proof_attempts"] and
            state["proof_attempts"][0]["kernel_result"]["success"]),
        "redesign_utility_pass": any(any(c["utility_result"].get("accepted") for c in row["candidates"])
                                     for row in redesign_rounds),
        "redesign_kernel_pass": any(row["operation"] == "PROVE" and row["kernel_result"]["success"]
                                    for row in state["proof_attempts"][1:]),
        "repair_success": any(row["operation"] == "REPAIR" and row["kernel_result"]["success"]
                              for row in state["proof_attempts"]),
        "low_utility_rejections": sum(c["utility_result"].get("classification") == "LOW_TARGET_UTILITY"
                                      for row in state["statement_rounds"] for c in row["candidates"]),
        "avoided_proof_attempts": sum(bool(c["utility_result"].get("proof_attempt_avoided"))
                                      for row in state["statement_rounds"] for c in row["candidates"]),
        "candidate_statement_count": sum(len(row["candidates"]) for row in state["statement_rounds"]),
        "model_calls": len(state["model_calls"]), "usage": _usage(state["model_calls"]),
        "api_wall_time_s": sum(float(row["model_response"].get("elapsed_s") or 0) for row in state["model_calls"]),
        "foundation_result": state["foundation_result"], "proof_gap": state["proof_gap"],
        "bridge_specification": state["bridge_specification"],
        "global_bridge_view": state["global_bridge_view"], "statement_rounds": state["statement_rounds"],
        "proof_attempts": state["proof_attempts"], "diagnoses": state["diagnoses"],
        "verified_lemmas": state["verified_lemmas"], "property_rescue": rescue}
    atomic_json(result_path, result, overwrite=False)
    state["status"] = "COMPLETED"; state["result_sha256"] = sha256_text(json.dumps(result, sort_keys=True))
    atomic_json(state_path, state)
    return result
