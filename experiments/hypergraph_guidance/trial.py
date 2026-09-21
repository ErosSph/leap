"""One TPOH/schema-guided lemma-first trial."""
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
from experiments.bridge_discovery.prover import formal_kernel_gate, run_delete_lemma_replay, run_foundation_prover, run_property_retry

from .corpus import theorem_base_for
from .hypergraph import annotate_failure, build_hypergraph, forward_reachability
from .prompts import EDGE_SCHEMA, HOLE_SCHEMA, edge_prompt, hole_prompt
from .schemas import fill_skeleton, generate_skeleton, select_schema, theorem_application_aligner
from .utility import graph_utility


def _normal(value: str) -> str: return re.sub(r"\s+", "", value)
def _prefix(task: dict[str, Any], trial: int) -> str: return f"r13_{task['challenge_id'].lower()}_t{trial}_"


def _edge_error(candidate: Any, task: dict[str, Any], prefix: str,
                rejected: list[dict[str, Any]], redesign: bool) -> str | None:
    if not isinstance(candidate, dict): return "candidate edge is not an object"
    name, statement = candidate.get("lemma_name"), candidate.get("lemma_statement")
    if not isinstance(name, str) or not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_']*", name): return "unsafe lemma name"
    if not name.startswith(prefix): return f"lemma name must start with {prefix}"
    if not isinstance(statement, str) or not statement.strip(): return "empty statement"
    if re.match(r"^\s*(?:theorem|lemma)\b", statement) or ":=" in statement: return "statement is not proposition-only"
    if FORBIDDEN_RE.search(statement): return "unchecked construct in statement"
    if _normal(statement) == _normal(task["statement"]): return "complete target duplicate"
    required = ("candidate_source", "candidate_target", "candidate_edge_type", "bridge_reason")
    if any(not isinstance(candidate.get(key), str) or not candidate[key].strip() for key in required):
        return "missing explicit edge binding"
    if redesign:
        for old in rejected[-3:]:
            same_statement = _normal(statement) == _normal(old.get("lemma_statement", ""))
            same_edge = all(candidate.get(k) == old.get(k) for k in
                            ("candidate_source", "candidate_target", "candidate_edge_type"))
            if same_statement and same_edge: return "redesign did not change source, target, edge type, or premise set"
    return None


def _hole_error(value: Any) -> str | None:
    if not isinstance(value, dict): return "hole response is not an object"
    for key in ("HOLE_BASE_CASE", "HOLE_STEP_CASE", "HOLE_MAIN"):
        if not isinstance(value.get(key), str): return f"missing {key}"
    joined = "\n".join(value.get(key, "") for key in ("HOLE_BASE_CASE", "HOLE_STEP_CASE", "HOLE_MAIN"))
    if FORBIDDEN_RE.search(joined): return "unchecked construct in proof holes"
    if any(part.lstrip().startswith("by") for part in (value["HOLE_BASE_CASE"], value["HOLE_STEP_CASE"], value["HOLE_MAIN"])):
        return "hole fragment must not regenerate outer `by` structure"
    return None


def _call(root: Path, state: dict[str, Any], model: ProofModel, prompt: str,
          schema: dict[str, Any], operation: str) -> dict[str, Any]:
    index = len(state["model_calls"]) + 1; directory = root / "calls" / f"call_{index:02d}"
    atomic_text(directory / "prompt.txt", prompt)
    marker = {"schema": "rtl2lean-hypergraph_guidance-request-marker-v1", "call_index": index,
        "operation": operation, "prompt_sha256": sha256_text(prompt), "seed": state["seed"] + index - 1,
        "response_persisted": False}
    atomic_json(directory / "request_started.json", marker)
    response = model.generate(prompt, schema, marker["seed"]).serializable(); atomic_json(directory / "response.json", response)
    marker["response_persisted"] = True; atomic_json(directory / "request_started.json", marker)
    row = {"call_index": index, "operation": operation, "model_response": response,
           "processing_status": "MODEL_RESPONSE_SAVED"}
    state["model_calls"].append(row); atomic_json(root / "state.json", state); return row


def _diagnose(task: dict[str, Any], base: dict[str, Any], state: dict[str, Any],
              candidate: dict[str, Any], check: dict[str, Any]) -> dict[str, Any]:
    history = [{"proof_state": a["kernel_result"].get("proof_state", ""),
                "candidate": a["formal_candidate"], "diagnosis": a.get("diagnosis")}
               for a in state["proof_attempts"]]
    return diagnose_lemma(task["statement"], candidate, history,
        [str(check.get("stdout") or "") + str(check.get("stderr") or "")],
        [str(check.get("proof_state") or "")],
        "\n".join(row["statement"] for row in state["retrieved_lemmas"]),
        base["theorems"], state["verified_lemmas"]).serializable()


def _usage(calls: list[dict[str, Any]]) -> dict[str, int]:
    keys = ("input_tokens", "output_tokens", "total_tokens", "reasoning_tokens", "cached_tokens")
    return {key: sum(int(call["model_response"].get("usage", {}).get(key) or 0) for call in calls) for key in keys}


def run_trial(project: Path, run_dir: Path, task: dict[str, Any], trial_id: int, seed: int,
              config: dict[str, Any], source: dict[str, Any], manifest_hash: str,
              model: ProofModel) -> dict[str, Any]:
    root = run_dir / "schema_guided" / "trials" / task["challenge_id"] / f"trial_{trial_id:02d}"
    result_path = root / "result.json"
    if result_path.is_file(): return read_json(result_path)
    state_path = root / "state.json"
    if state_path.is_file(): state = read_json(state_path)
    else:
        state = {"schema": "rtl2lean-hypergraph_guidance-state-v1", "seed": seed, "task_id": task["task_id"],
            "challenge_id": task["challenge_id"], "run_manifest_sha256": manifest_hash,
            "foundation_result": None, "retrieved_lemmas": [], "proof_gap": None, "hypergraph": None,
            "proof_frontier": None, "missing_hyperedges": [], "model_calls": [], "candidate_rounds": [],
            "proof_attempts": [], "failure_annotations": [], "verified_lemmas": [], "rejected_edges": [],
            "current_candidate": None, "current_edge": None, "current_utility": None,
            "selected_schema": None, "skeleton": None, "skeleton_metadata": None, "alignment": None,
            "next_stage": "EDGE_DISCOVER", "redesign_count": 0, "repair_count": 0, "property_rescue": None}
        atomic_json(state_path, state)
    base = theorem_base_for(source, task["dut"]); timeout = int(config["lean_timeout_seconds"])
    if state["foundation_result"] is None:
        state["retrieved_lemmas"] = retrieve_lemmas(task["statement"], base["theorems"], int(config["retrieval_limit"]))
        # Ensure the selected dependency is present even if lexical retrieval ranks it lower.
        selected = next((row for row in base["theorems"] if row["name"] == task["selected_local_step"]), None)
        if selected and not any(row["name"] == selected["name"] for row in state["retrieved_lemmas"]):
            state["retrieved_lemmas"].insert(0, {"name": selected["name"], "statement": selected["statement"],
                "source_file": selected.get("source_file"), "score": 100, "matched_symbols": [],
                "matched_state_fields": task["required_state_fields"]})
        state["foundation_result"] = run_foundation_prover(project, root / "foundation_only", task, timeout)
        if not state["foundation_result"]["success"]:
            state["proof_gap"] = extract_proof_gap(task, base["theorems"], state["retrieved_lemmas"],
                                                    state["foundation_result"], "hypergraph_guidance-gap-v1")
            graph, frontier, missing = build_hypergraph(task, state["proof_gap"], state["retrieved_lemmas"])
            state.update(hypergraph=graph, proof_frontier=frontier, missing_hyperedges=missing)
            graph_root = root / "graph"
            atomic_json(graph_root / "proof_hypergraph.json", graph)
            atomic_json(graph_root / "proof_frontier.json", frontier)
            atomic_json(graph_root / "missing_hyperedges.json", missing)
            atomic_json(graph_root / "graph_reachability.json", forward_reachability(graph))
            atomic_json(graph_root / "candidate_edges.json", [])
        atomic_json(state_path, state)
    while (not state["foundation_result"]["success"] and not state["property_rescue"] and
           len(state["model_calls"]) < int(config["max_total_calls"])):
        stage = state["next_stage"]
        if stage in {"EDGE_DISCOVER", "EDGE_REDESIGN"}:
            redesign = stage == "EDGE_REDESIGN"; previous = None
            if redesign:
                previous = {"rejected_edge": state["rejected_edges"][-1] if state["rejected_edges"] else None,
                    "failure_annotation": state["failure_annotations"][-1] if state["failure_annotations"] else None,
                    "required_change": "change source, target, edge type, or premise set"}
            prompt = edge_prompt(task, state["proof_gap"], state["retrieved_lemmas"], state["hypergraph"],
                state["proof_frontier"], state["missing_hyperedges"], _prefix(task, trial_id), seed,
                "REDESIGN_EDGE" if redesign else "PREDICT_MISSING_EDGE", previous)
            call = _call(root, state, model, prompt, EDGE_SCHEMA, "REDESIGN_EDGE" if redesign else "PREDICT_EDGE")
            response = call["model_response"]; payload = response.get("candidate") if response.get("status") == "API_SUCCESS" else {}
            candidates = payload.get("candidates", []) if isinstance(payload, dict) else []
            round_row = {"operation": "REDESIGN_EDGE" if redesign else "PREDICT_EDGE", "call_index": call["call_index"],
                         "candidates": []}
            for position, candidate in enumerate(candidates, 1):
                error = _edge_error(candidate, task, _prefix(task, trial_id), state["rejected_edges"], redesign)
                if error is None:
                    utility, graph_edge = graph_utility(project, root / "graph" / "utility" /
                        f"call_{call['call_index']:02d}_candidate_{position:02d}", task, candidate,
                        state["hypergraph"], state["missing_hyperedges"], base["theorems"], timeout)
                else:
                    utility = {"classification": "LOW_TARGET_UTILITY", "accepted": False, "reason": error,
                               "proof_attempt_avoided": True}; graph_edge = {}
                round_row["candidates"].append({"position": position, "candidate": candidate,
                    "validation_error": error, "candidate_hyperedge": graph_edge, "graph_utility": utility})
            accepted = [row for row in round_row["candidates"] if row["graph_utility"].get("accepted")]
            accepted.sort(key=lambda row: (row["graph_utility"]["classification"] == "HIGH_TARGET_UTILITY",
                row["graph_utility"].get("reachable_node_gain", 0)), reverse=True)
            if accepted:
                choice = accepted[0]; choice["selected"] = True
                state["current_candidate"] = choice["candidate"]; state["current_edge"] = choice["candidate_hyperedge"]
                state["current_utility"] = choice["graph_utility"]
                selection = select_schema(choice["candidate"], state["missing_hyperedges"][0], task)
                skeleton, metadata = generate_skeleton(selection, choice["candidate"])
                local = next((row for row in base["theorems"] if row["name"] == task["selected_local_step"]), None)
                alignment = theorem_application_aligner(local,
                    state["missing_hyperedges"][0]["target_frontier"],
                    next(node["expression"] for node in state["hypergraph"]["nodes"]
                         if node["node_id"] == state["hypergraph"]["goal_node"]))
                state.update(selected_schema=selection, skeleton=skeleton,
                             skeleton_metadata=metadata, alignment=alignment, next_stage="FILL_HOLES", repair_count=0)
                schema_root = root / "proof_schema"
                atomic_json(schema_root / "selected_schema.json", selection); atomic_text(schema_root / "skeleton.lean", skeleton)
                atomic_json(schema_root / "skeleton_metadata.json", metadata)
                atomic_json(root / "theorem_application_alignment.json", alignment)
            else:
                state["rejected_edges"].extend(row["candidate"] for row in round_row["candidates"] if isinstance(row["candidate"], dict))
                if state["redesign_count"] < int(config["max_edge_redesign"]):
                    state["redesign_count"] += 1; state["next_stage"] = "EDGE_REDESIGN"
                else: state["next_stage"] = "EXHAUSTED"
            state["candidate_rounds"].append(round_row)
            atomic_json(root / "graph" / "candidate_edges.json", state["candidate_rounds"])
        elif stage in {"FILL_HOLES", "REPAIR_HOLES"}:
            failure = state["failure_annotations"][-1] if stage == "REPAIR_HOLES" else None
            prompt = hole_prompt(task, state["proof_gap"], state["retrieved_lemmas"], state["current_candidate"],
                state["selected_schema"], state["skeleton"], state["skeleton_metadata"], state["alignment"], failure)
            operation = "REPAIR_SCHEMA_HOLES" if stage == "REPAIR_HOLES" else "FILL_SCHEMA_HOLES"
            call = _call(root, state, model, prompt, HOLE_SCHEMA, operation)
            response = call["model_response"]; holes = response.get("candidate") if response.get("status") == "API_SUCCESS" else {}
            error = _hole_error(holes)
            try: proof = fill_skeleton(state["skeleton"], holes) if error is None else ""
            except ValueError as caught: error = str(caught); proof = ""
            formal = {**state["current_candidate"], "proof_body": proof}
            check = (formal_kernel_gate(project, root / "kernel_checks" / f"call_{call['call_index']:02d}.lean",
                                        task, formal, timeout) if error is None
                     else synthetic_failure(error or response.get("error") or response.get("status", "model failure")))
            attempt = {"call_index": call["call_index"], "operation": operation, "candidate_edge": state["current_edge"],
                "graph_utility": state["current_utility"], "selected_schema": state["selected_schema"],
                "skeleton": state["skeleton"], "skeleton_metadata": state["skeleton_metadata"],
                "hole_response": holes, "composed_proof_body": proof, "formal_candidate": formal,
                "kernel_result": check, "validation_error": error, "theorem_alignment": state["alignment"]}
            state["proof_attempts"].append(attempt)
            if check["success"]:
                verified = {**formal, "kernel_result": "PASS", "verified_at_call": call["call_index"]}
                state["verified_lemmas"].append(verified)
                retry = run_property_retry(project, root / "property_retry" / f"call_{call['call_index']:02d}", task,
                                           timeout, verified); attempt["final_property_result"] = retry
                if retry["success"]:
                    final_proof = retry["successful_proof_body"] or ""
                    used = bool(re.search(rf"(?<![A-Za-z0-9_']){re.escape(verified['lemma_name'])}(?![A-Za-z0-9_'])", final_proof))
                    delete = run_delete_lemma_replay(project, root / "delete_lemma_replay.lean", task, final_proof, timeout)
                    state["property_rescue"] = {"status": "PROPERTY_RESCUED_BY_SCHEMA_LEMMA" if used and not delete["success"]
                        else "PROPERTY_PASS_NOT_ATTRIBUTABLE", "candidate": verified, "final_property_result": retry,
                        "candidate_used": used, "delete_lemma_replay_pass": delete["success"],
                        "verified_lemma_used_by_final": used and not delete["success"]}; state["next_stage"] = "DONE"
                else:
                    state["rejected_edges"].append(state["current_candidate"]); state["next_stage"] = "EDGE_REDESIGN"
            else:
                diagnosis = _diagnose(task, base, state, formal, check); attempt["diagnosis"] = diagnosis
                annotation = annotate_failure(state["hypergraph"], state["current_edge"], diagnosis,
                                              state["alignment"], state["selected_schema"])
                attempt["hypergraph_failure_annotation"] = annotation; state["failure_annotations"].append(annotation)
                atomic_json(root / "graph" / f"failure_annotation_call_{call['call_index']:02d}.json", annotation)
                if stage == "FILL_HOLES" and annotation["repair_or_redesign"] == "REPAIR_SCHEMA":
                    state["repair_count"] += 1; state["next_stage"] = "REPAIR_HOLES"
                elif state["redesign_count"] < int(config["max_edge_redesign"]):
                    state["rejected_edges"].append(state["current_candidate"]); state["redesign_count"] += 1
                    state["next_stage"] = "EDGE_REDESIGN"
                else: state["next_stage"] = "EXHAUSTED"
        else: break
        atomic_json(state_path, state)
    rescue = state["property_rescue"]
    result = {"schema": "rtl2lean-hypergraph_guidance-trial-v1", "completed": True,
        "run_manifest_sha256": manifest_hash, "challenge_id": task["challenge_id"], "task_id": task["task_id"],
        "dut": task["dut"], "property_level": task["property_level"], "foundation_only_pass": state["foundation_result"]["success"],
        "result_status": "FOUNDATION_ONLY_PASS" if state["foundation_result"]["success"] else
                         rescue["status"] if rescue else "NOT_RESCUED",
        "llm_assisted_property_pass": state["foundation_result"]["success"] or bool(rescue),
        "graph_construction_success": bool(state["hypergraph"] and state["hypergraph"]["construction_success"]),
        "missing_hyperedge_detection_success": bool(state["missing_hyperedges"]),
        "candidate_utility_pass": any(c["graph_utility"].get("accepted") for r in state["candidate_rounds"] for c in r["candidates"]),
        "schema_selection_success": bool(state["selected_schema"]),
        "skeleton_generation_success": bool(state["skeleton_metadata"] and state["skeleton_metadata"]["skeleton_generation_success"]),
        "first_kernel_pass": bool(state["proof_attempts"] and state["proof_attempts"][0]["kernel_result"]["success"]),
        "kernel_pass_after_repair": any(a["operation"] == "REPAIR_SCHEMA_HOLES" and a["kernel_result"]["success"] for a in state["proof_attempts"]),
        "model_calls": len(state["model_calls"]), "usage": _usage(state["model_calls"]),
        "api_wall_time_s": sum(float(c["model_response"].get("elapsed_s") or 0) for c in state["model_calls"]),
        "foundation_result": state["foundation_result"], "proof_gap": state["proof_gap"],
        "hypergraph": state["hypergraph"], "proof_frontier": state["proof_frontier"],
        "missing_hyperedges": state["missing_hyperedges"], "candidate_rounds": state["candidate_rounds"],
        "proof_attempts": state["proof_attempts"], "failure_annotations": state["failure_annotations"],
        "verified_lemmas": state["verified_lemmas"], "property_rescue": rescue}
    atomic_json(result_path, result, overwrite=False); return result
