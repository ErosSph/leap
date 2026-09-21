"""Execute the paired legacy/full Req15 experiment without a direct proof arm."""
from __future__ import annotations

import hashlib
import json
import re
import sys
import time
from pathlib import Path
from typing import Any

from experiments.adaptive_proving.io import atomic_json, atomic_text, read_json
from experiments.adaptive_proving.lean import FORBIDDEN_RE, check_source, synthetic_failure
from experiments.bridge_discovery.prover import run_foundation_prover
from .binder import bind_state_transition
from .graph import REQ15_EDGE_TYPES, construct_tpoh
from .schemas import fill_skeleton, plan_witness, select_schema, state_skeleton, witness_skeleton


VARIANTS = {
    "legacy_untyped_control": {"typed_binder": False, "specialized_schema": False},
    "full_req15": {"typed_binder": True, "specialized_schema": True},
}

CANDIDATE_SCHEMA = {"type": "object", "properties": {"candidates": {
    "type": "array", "minItems": 3, "maxItems": 3, "items": {"type": "object",
        "properties": {"lemma_name": {"type": "string"}, "lemma_statement": {"type": "string"},
            "candidate_source": {"type": "array", "items": {"type": "string"}},
            "candidate_target": {"type": "string"},
            "candidate_edge_type": {"type": "string", "enum": REQ15_EDGE_TYPES},
            "bridge_reason": {"type": "string"}},
        "required": ["lemma_name", "lemma_statement", "candidate_source", "candidate_target",
                     "candidate_edge_type", "bridge_reason"], "additionalProperties": False}}},
    "required": ["candidates"], "additionalProperties": False}
FULL_PROOF_SCHEMA = {"type": "object", "properties": {"proof_body": {"type": "string"},
    "proof_idea": {"type": "string"}}, "required": ["proof_body", "proof_idea"],
    "additionalProperties": False}
STATE_HOLES = {"type": "object", "properties": {"HOLE_MAIN": {"type": "string"},
    "proof_idea": {"type": "string"}}, "required": ["HOLE_MAIN", "proof_idea"],
    "additionalProperties": False}
WITNESS_HOLES = {"type": "object", "properties": {"HOLE_NONEMPTY": {"type": "string"},
    "HOLE_OBLIGATION": {"type": "string"}, "proof_idea": {"type": "string"}},
    "required": ["HOLE_NONEMPTY", "HOLE_OBLIGATION", "proof_idea"], "additionalProperties": False}


def _theorem_source(task: dict[str, Any], name: str, statement: str, proof: str,
                    include_target: bool = False) -> str:
    rows = [f"import {task['context_import']}", "set_option maxRecDepth 100000",
        "set_option maxHeartbeats 8000000", f"namespace {task['module']}Verification",
        f"open {task['module']}", f"theorem {name} : {statement} := {proof}"]
    if include_target:
        rows.append(f"theorem {task['task_id']} : {task['statement']} := by exact ⟨{name}, trivial⟩")
    rows.extend([f"end {task['module']}Verification", ""])
    return "\n".join(rows)


def _candidate_context(task: dict[str, Any], source: dict[str, Any]) -> str:
    base = next(row for row in source["theorem_bases"] if row["dut"] == task["dut"])
    rows = []
    for name in task["foundation_lemmas"]:
        theorem = next((row for row in base["theorems"] if row["name"] == name), None)
        if theorem:
            rows.append(f"theorem {task['module']}Verification.{name} : {theorem['statement']}")
    if task["property_pattern"] == "STATE_TRANSITION":
        rows.append("theorem R3Temporal.obeys_of_along (step) (guard) (expected) (obs) "
                    "(hstep : ∀ s i, guard s i → obs (step s i) = expected s i) : "
                    "∀ s xs, R3Temporal.Along step guard s xs → "
                    "R3Temporal.Obeys step guard expected obs s xs")
    return "\n".join(rows)


def candidate_prompt(task: dict[str, Any], graph: dict[str, Any], context: str, seed: int,
                     feedback: dict[str, Any] | None = None) -> str:
    repair = "" if feedback is None else ("\nThe previous slate failed the fixed formal Utility Gate. "
        "Correct only the listed structural errors and return a new slate:\n" +
        json.dumps(feedback, ensure_ascii=False, indent=2))
    return f"""Predict exactly three intermediate-lemma hyperedges for Lean 4. Return JSON only.
This is lemma-first: never prove the wrapper Property and never emit a proof in this call.
The required typed frontier is explicit in the graph. A useful candidate must have exactly the
same proposition as that frontier, cite every initial node ID in order, cite the target node ID,
and use missing_hyperedges[0].edge_type. Names must begin r15_{task['challenge_id'].lower()}_candidate_.
Seed: {seed}
Property: {task['statement']}
Typed Proof Obligation Hypergraph:
{json.dumps(graph, ensure_ascii=False, indent=2)}
Available declarations:
{context}{repair}"""


def _utility_source(task: dict[str, Any], statement: str) -> str:
    return "\n".join([f"import {task['context_import']}", "set_option maxRecDepth 100000",
        "set_option maxHeartbeats 8000000", f"namespace {task['module']}Verification",
        f"open {task['module']}", f"theorem utility (candidate_bridge : {statement}) : "
        f"{task['expected_candidate_statement']} := by exact candidate_bridge",
        f"end {task['module']}Verification", ""])


def formal_utility(project: Path, root: Path, task: dict[str, Any], graph: dict[str, Any],
                   candidate: dict[str, Any], timeout_s: int) -> dict[str, Any]:
    expected_sources = graph["initial_nodes"]
    expected_target = graph["backward_target_frontier"][0]
    source_match = candidate.get("candidate_source") == expected_sources
    target_match = candidate.get("candidate_target") == expected_target
    edge_match = candidate.get("candidate_edge_type") == task["property_pattern"]
    statement = str(candidate.get("lemma_statement") or "")
    lean = check_source(_utility_source(task, statement), project / task["model_dir"],
                        root / "utility.lean", timeout_s)
    exact_text = re.sub(r"\s+", "", statement) == re.sub(r"\s+", "", task["expected_candidate_statement"])
    formal = bool(source_match and target_match and edge_match and lean["success"])
    return {"SOURCE_FORMAL_MATCH": source_match, "TARGET_FORMAL_MATCH": target_match,
        "EDGE_TYPE_MATCH": edge_match, "LEAN_TYPE_COMPATIBLE": lean["success"],
        "EXACT_FRONTIER_TEXT_MATCH": exact_text, "FORMAL_UTILITY_PASS": formal,
        "graph_match_class": "GRAPH_MATCH_TRUE_POSITIVE" if formal else (
            "GRAPH_MATCH_FALSE_NEGATIVE" if lean["success"] else "GRAPH_MATCH_TRUE_NEGATIVE"),
        "lean_result": lean}


def _call(model, prompt: str, schema: dict[str, Any], seed: int, root: Path, index: int,
          operation: str) -> dict[str, Any]:
    call_root = root / f"call_{index:02d}"
    atomic_text(call_root / "prompt.txt", prompt)
    response = model.generate(prompt, schema, seed).serializable()
    atomic_json(call_root / "response.json", response)
    return {"operation": operation, "response": response, "physical_call": True}


def _evaluate_slate(project: Path, root: Path, task: dict[str, Any], graph: dict[str, Any],
                    response: dict[str, Any], timeout_s: int) -> list[dict[str, Any]]:
    rows = []
    payload = response.get("candidate") or {}
    for position, raw in enumerate(payload.get("candidates", []), 1):
        candidate = raw if isinstance(raw, dict) else {}
        error = None
        if not isinstance(raw, dict):
            error = "candidate is not an object"
        elif not re.fullmatch(rf"r15_{task['challenge_id'].lower()}_candidate_[A-Za-z0-9_]+",
                              str(candidate.get("lemma_name", ""))):
            error = "invalid lemma name"
        elif not isinstance(candidate.get("lemma_statement"), str) or FORBIDDEN_RE.search(
                candidate.get("lemma_statement", "")):
            error = "invalid lemma statement"
        match = formal_utility(project, root / str(position), task, graph, candidate, timeout_s) \
            if error is None else {"FORMAL_UTILITY_PASS": False, "graph_match_class": "INVALID"}
        rows.append({"position": position, "candidate": candidate, "error": error,
                     "formal_match": match, "utility_pass": bool(match["FORMAL_UTILITY_PASS"])})
    return rows


def shared_candidate(project: Path, run_dir: Path, task: dict[str, Any], source: dict[str, Any],
                     config: dict[str, Any], model, seed: int) -> dict[str, Any]:
    root = run_dir / "shared_candidate_draws" / task["challenge_id"]
    cache = root / "result.json"
    if cache.is_file():
        return read_json(cache)
    graph = construct_tpoh(task)
    context = _candidate_context(task, source)
    calls = []
    candidates: list[dict[str, Any]] = []
    for index in range(1, config["candidate_calls"] + 1):
        feedback = None
        if candidates:
            feedback = {"rejected_candidates": [{"position": row["position"],
                "error": row["error"], "source_match": row["formal_match"].get("SOURCE_FORMAL_MATCH"),
                "target_match": row["formal_match"].get("TARGET_FORMAL_MATCH"),
                "edge_match": row["formal_match"].get("EDGE_TYPE_MATCH"),
                "lean_type_compatible": row["formal_match"].get("LEAN_TYPE_COMPATIBLE")}
                for row in candidates]}
        call = _call(model, candidate_prompt(task, graph, context, seed, feedback), CANDIDATE_SCHEMA,
                     seed + index - 1, root / "calls", index, "CANDIDATE" if index == 1 else "CANDIDATE_REPAIR")
        calls.append(call)
        candidates = _evaluate_slate(project, root / "matches" / f"call_{index:02d}", task, graph,
                                     call["response"], config["lean_timeout_seconds"])
        if any(row["utility_pass"] for row in candidates):
            break
    selected = next((row for row in candidates if row["utility_pass"]), None)
    result = {"schema": "rtl2lean-scale_evaluation-shared-candidate-v1",
        "challenge_id": task["challenge_id"], "draw_id": f"r15:{task['challenge_id']}:{seed}",
        "graph": graph, "calls": calls, "candidates": candidates,
        "selected": selected, "candidate_utility_pass": selected is not None,
        "candidate_repair_used": len(calls) > 1,
        "usage": {key: sum(int(call["response"].get("usage", {}).get(key) or 0) for call in calls)
                  for key in ["input_tokens", "output_tokens", "total_tokens", "cached_tokens"]},
        "api_wall_time_s": sum(float(call["response"].get("elapsed_s") or 0) for call in calls)}
    atomic_json(cache, result)
    return result


def _legacy_prompt(task: dict[str, Any], candidate: dict[str, Any], context: str,
                   feedback: dict[str, Any] | None = None) -> str:
    repair = "" if feedback is None else "\nFixed Lean feedback from the previous attempt:\n" + json.dumps(
        feedback, ensure_ascii=False, indent=2)
    return f"""Return JSON only. Prove this intermediate lemma (not the final wrapper Property).
No proof schema, typed binder, theorem application, or witness is supplied. Generate the complete
proof_body beginning with `by`. Use only the listed declarations.
Lemma: {candidate['lemma_name']} : {candidate['lemma_statement']}
Declarations:
{context}
Never use sorry, admit, native_decide, unsafe, or axiom.{repair}"""


def _full_prompt(task: dict[str, Any], candidate: dict[str, Any], skeleton: str,
                 metadata: dict[str, Any], typed_artifact: dict[str, Any],
                 feedback: dict[str, Any] | None = None) -> str:
    repair = "" if feedback is None else "\nFixed Lean feedback from the previous hole filling:\n" + json.dumps(
        feedback, ensure_ascii=False, indent=2)
    prohibition = ("The theorem name, namespace, arguments, and full theorem application are already "
        "bound in the skeleton; do not repeat or replace them." if task["property_pattern"] == "STATE_TRANSITION"
        else "The typed witness is already inserted; do not replace it or regenerate the existential proof.")
    return f"""Return JSON only. Fill exactly the named local Lean proof holes in the frozen skeleton.
Never regenerate the outer by/intro/refine structure. {prohibition}
Lemma: {candidate['lemma_name']} : {candidate['lemma_statement']}
Skeleton:
{skeleton}
Schema metadata:
{json.dumps(metadata, ensure_ascii=False, indent=2)}
Typed artifact summary:
{json.dumps({k: v for k, v in typed_artifact.items() if not k.endswith('_result')}, ensure_ascii=False, indent=2)}
Never use sorry, admit, native_decide, unsafe, or axiom.{repair}"""


def _diagnose(kernel: dict[str, Any]) -> dict[str, Any]:
    text = (str(kernel.get("stdout", "")) + "\n" + str(kernel.get("stderr", ""))).lower()
    if kernel.get("success"):
        return {"schema": "rtl2lean-fixed-lean-feedback-v1", "categories": [],
            "unknown_identifiers": [], "proof_state": "", "unsolved_goals": [],
            "policy": "deterministic extraction only; no Codex interpretation"}
    categories = []
    for needle, category in [("unknown identifier", "UNKNOWN_IDENTIFIER"), ("unknown tactic", "UNKNOWN_TACTIC"),
            ("unsolved goals", "UNSOLVED_GOAL"), ("type mismatch", "TYPE_MISMATCH"),
            ("function expected", "THEOREM_APPLICATION_MISMATCH"), ("unexpected token", "SYNTAX_ERROR")]:
        if needle in text:
            categories.append(category)
    unknown = re.findall(r"unknown identifier [`'‘]([^`'’]+)[`'’]", text)
    return {"schema": "rtl2lean-fixed-lean-feedback-v1", "categories": categories or ["KERNEL_REJECT"],
        "unknown_identifiers": list(dict.fromkeys(unknown)),
        "proof_state": kernel.get("proof_state", "")[-4000:],
        "unsolved_goals": kernel.get("unsolved_goals", [])[:4],
        "policy": "deterministic extraction only; no Codex interpretation"}


def run_variant(project: Path, run_dir: Path, task: dict[str, Any], variant: str,
                shared: dict[str, Any], source: dict[str, Any], config: dict[str, Any], model,
                foundation: dict[str, Any], seed: int) -> dict[str, Any]:
    root = run_dir / "variants" / variant / "trials" / task["challenge_id"]
    result_path = root / "result.json"
    if result_path.is_file():
        return read_json(result_path)
    started = time.perf_counter()
    selected = shared.get("selected")
    kernel = synthetic_failure("no formally useful candidate")
    calls: list[dict[str, Any]] = []
    schema_selection = None
    skeleton = ""
    metadata: dict[str, Any] = {}
    typed_artifact: dict[str, Any] = {}
    proof = ""
    first_kernel_pass = False
    kernel_pass_after_repair = False
    if selected:
        candidate = selected["candidate"]
        context = _candidate_context(task, source)
        if VARIANTS[variant]["specialized_schema"]:
            schema_selection = select_schema(shared["graph"]["missing_hyperedges"][0], candidate)
            if task["property_pattern"] == "STATE_TRANSITION":
                typed_artifact = bind_state_transition(project, root / "typed_binding", task, candidate,
                                                       config["lean_timeout_seconds"])
                if typed_artifact["binding_success"]:
                    skeleton, metadata = state_skeleton(candidate, typed_artifact)
                response_schema = STATE_HOLES
            else:
                typed_artifact = plan_witness(project, root / "witness_plan", task, candidate,
                                              config["lean_timeout_seconds"])
                if typed_artifact["proposal_success"] and typed_artifact["typed_witness_acceptance"]:
                    skeleton, metadata = witness_skeleton(task, typed_artifact)
                response_schema = WITNESS_HOLES
            atomic_json(root / "proof_schema" / "selection.json", schema_selection)
            atomic_json(root / "proof_schema" / "metadata.json", metadata)
            atomic_text(root / "proof_schema" / "skeleton.lean", skeleton or "SCHEMA_PRECONDITION_FAILED\n")
            atomic_json(root / "proof_schema" / "typed_artifact.json", typed_artifact)
        else:
            response_schema = FULL_PROOF_SCHEMA
            atomic_json(root / "proof_schema" / "metadata.json", {"schema_id": None,
                "ablation": "SPECIALIZED_SCHEMA_AND_TYPED_BINDING_REMOVED"})
            atomic_text(root / "proof_schema" / "skeleton.lean", "NO_SKELETON\n")
        if not VARIANTS[variant]["specialized_schema"] or skeleton:
            previous = None
            for attempt in range(1, config["proof_calls"] + 1):
                prompt = (_full_prompt(task, candidate, skeleton, metadata, typed_artifact, previous)
                    if VARIANTS[variant]["specialized_schema"] else _legacy_prompt(
                        task, candidate, context, previous))
                call = _call(model, prompt, response_schema, seed + 100 + attempt,
                             root / "calls", attempt, "PROOF" if attempt == 1 else "PROOF_REPAIR")
                calls.append(call)
                answer = call["response"].get("candidate") or {}
                try:
                    proof = fill_skeleton(skeleton, answer) if VARIANTS[variant]["specialized_schema"] \
                        else str(answer.get("proof_body") or "")
                except Exception as error:
                    proof = ""
                    kernel = synthetic_failure(str(error))
                if proof.lstrip().startswith("by") and not FORBIDDEN_RE.search(proof):
                    kernel = check_source(_theorem_source(task, candidate["lemma_name"],
                        candidate["lemma_statement"], proof, True), project / task["model_dir"],
                        root / "kernel" / f"attempt_{attempt:02d}.lean", config["lean_timeout_seconds"])
                elif proof:
                    kernel = synthetic_failure("proof body must begin with by and contain no forbidden token")
                if attempt == 1:
                    first_kernel_pass = kernel["success"]
                if kernel["success"]:
                    kernel_pass_after_repair = attempt > 1
                    break
                previous = {"previous_answer": answer, "lean_feedback": _diagnose(kernel),
                    "skeleton_is_immutable": VARIANTS[variant]["specialized_schema"]}
    candidate = selected["candidate"] if selected else None
    rescue = bool(kernel["success"] and candidate)
    delete_replay = synthetic_failure("no successful lemma")
    if rescue:
        delete_replay = check_source(_theorem_source(task, "unrelated", "True", "by trivial", False) +
            "\n".join([f"namespace {task['module']}Verification", f"open {task['module']}",
                f"theorem {task['task_id']}__delete : {task['statement']} := by exact ⟨{candidate['lemma_name']}, trivial⟩",
                f"end {task['module']}Verification", ""]), project / task["model_dir"],
            root / "kernel" / "delete_lemma_replay.lean", config["lean_timeout_seconds"])
    diagnostics = _diagnose(kernel)
    binding = typed_artifact if task["property_pattern"] == "STATE_TRANSITION" else {}
    witness = typed_artifact if task["property_pattern"] == "WITNESS_CONSTRUCTION" else {}
    result = {"schema": "rtl2lean-scale_evaluation-result-v1", "challenge_id": task["challenge_id"],
        "task_id": task["task_id"], "dut": task["dut"], "property_pattern": task["property_pattern"],
        "variant": variant, "direct_arm": False, "foundation_pass": foundation["success"],
        "tpoh_graph_construction": shared["graph"]["construction_success"],
        "missing_hyperedge_detection": bool(shared["graph"]["missing_hyperedges"]),
        "candidate_draw_id": shared["draw_id"], "candidate_utility_pass": selected is not None,
        "schema_selection": schema_selection, "schema_selection_success": bool(
            schema_selection and schema_selection["selection_success"]),
        "skeleton_generation_success": bool(skeleton), "first_kernel_pass": first_kernel_pass,
        "kernel_pass_after_repair": kernel_pass_after_repair, "property_rescue": rescue,
        "verified_lemma_used_by_final": rescue and not delete_replay["success"],
        "typed_theorem_binding_success": bool(binding.get("binding_success")),
        "namespace_mismatch": "UNKNOWN_IDENTIFIER" in diagnostics["categories"] if binding else False,
        "implicit_argument_mismatch": bool(binding and not binding.get("application_kernel_pass")),
        "theorem_application_mismatch": "THEOREM_APPLICATION_MISMATCH" in diagnostics["categories"],
        "state_field_alignment_failure": bool(binding and not binding.get("state_field_alignment")),
        "witness_proposal_success": bool(witness.get("proposal_success")),
        "typed_witness_acceptance": bool(witness.get("typed_witness_acceptance")),
        "refine_skeleton_success": bool(witness and skeleton),
        "witness_obligation_kernel_pass": bool(witness and kernel["success"]),
        "proof_attempts": len(calls), "proof_repair_used": len(calls) > 1,
        "api_statuses": [call["response"].get("status") for call in calls],
        "usage": {key: sum(int(call["response"].get("usage", {}).get(key) or 0) for call in calls)
                  for key in ["input_tokens", "output_tokens", "total_tokens", "cached_tokens"]},
        "api_wall_time_s": sum(float(call["response"].get("elapsed_s") or 0) for call in calls),
        "variant_wall_time_s": time.perf_counter() - started, "kernel_result": kernel,
        "delete_lemma_replay": delete_replay, "failure_diagnosis": diagnostics}
    atomic_json(result_path, result)
    return result


def run_all(project: Path, run_dir: Path, tasks: list[dict[str, Any]], config: dict[str, Any],
            source: dict[str, Any], model) -> None:
    for task in tasks:
        foundation_root = run_dir / "shared_foundation" / task["challenge_id"]
        foundation_path = foundation_root / "result.json"
        if foundation_path.is_file():
            foundation = read_json(foundation_path)
        else:
            foundation = run_foundation_prover(project, foundation_root, task,
                                               config["lean_timeout_seconds"])
            atomic_json(foundation_path, foundation)
        seed = int(hashlib.sha256(f"{config['sampling']['base_seed']}:{task['task_id']}".encode()).hexdigest()[:8], 16) & 0x7fffffff
        shared = shared_candidate(project, run_dir, task, source, config, model, seed)
        for variant in config["variants"]:
            run_variant(project, run_dir, task, variant, shared, source, config, model,
                        foundation, seed)
        completed = sum(all((run_dir / "variants" / variant / "trials" / row["challenge_id"] /
                             "result.json").is_file() for variant in config["variants"]) for row in tasks)
        atomic_json(run_dir / "progress.json", {"completed_tasks": completed,
            "expected_tasks": len(tasks), "status": "COMPLETE" if completed == len(tasks) else "RUNNING"})
        print(f"[scale_evaluation] completed {task['challenge_id']} ({task['property_pattern']})",
              file=sys.stderr, flush=True)
