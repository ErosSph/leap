"""Kernel-audited binding from a STATE_TRANSITION graph edge to Lean theorems."""
from __future__ import annotations

from pathlib import Path
from typing import Any

from experiments.adaptive_proving.lean import check_source


def _parts(statement: str) -> list[str]:
    body = statement.split(",", 1)[1].strip() if statement.lstrip().startswith("∀") else statement
    return [part.strip() for part in body.split(" → ")]


def bind_state_transition(project: Path, root: Path, task: dict[str, Any],
                          candidate: dict[str, Any], timeout_s: int) -> dict[str, Any]:
    """Produce a complete named-argument application and have Lean type-check it.

    The theorem identity and argument order come only from the theorem base and the
    typed transition specification derived from RTL-generated Lean declarations.
    The LLM is never asked to invent any of them.
    """
    spec = task["transition_spec"]
    statement = candidate["lemma_statement"]
    parts = _parts(statement)
    current_hypotheses = parts[:-1]
    current_goal = parts[-1]
    expected = f"fun t x => {spec['expected']}"
    obs = f"fun t => t.{spec['field']}"
    core = "R3Temporal.obeys_of_along"
    local = spec["fully_qualified_local_theorem"]
    application = (f"{core} (step := r3Step) (guard := {spec['guard']}) "
        f"(expected := {expected}) (obs := {obs}) (hstep := {local}) s xs h")
    type_query_source = "\n".join([
        f"import {task['context_import']}", f"#check @{core}", f"#check @{local}", "",
    ])
    type_query = check_source(type_query_source, project / task["model_dir"],
                              root / "lean_type_query.lean", timeout_s)
    application_source = "\n".join([
        f"import {task['context_import']}", f"namespace {task['module']}Verification",
        f"open {task['module']}",
        f"example (s : {task['state_type']}) (xs : List {task['input_type']}) "
        f"(h : {current_hypotheses[-1]}) : {current_goal} := by",
        f"  exact {application}", f"end {task['module']}Verification", "",
    ])
    application_check = check_source(application_source, project / task["model_dir"],
                                     root / "bound_application.lean", timeout_s)
    field_aligned = f"t.{spec['field']}" in current_goal
    direction_aligned = spec["expected"] in current_goal
    return {"schema": "rtl2lean-typed-theorem-binding-v1", "binder": "TypedTheoremBinder",
        "candidate_hyperedge": {"source": candidate.get("candidate_source"),
            "target": candidate.get("candidate_target"), "edge_type": candidate.get("candidate_edge_type")},
        "current_hypotheses": current_hypotheses, "current_goal": current_goal,
        "fully_qualified_theorem_name": core, "theorem_signature": type_query["stdout"].strip(),
        "supporting_theorem": local, "supporting_theorem_signature": spec["local_theorem_signature"],
        "matched_premises": current_hypotheses, "missing_premises": [],
        "argument_mapping": [
            {"parameter": "step", "term": "r3Step", "origin": "candidate target"},
            {"parameter": "guard", "term": spec["guard"], "origin": "candidate source"},
            {"parameter": "expected", "term": expected, "origin": "candidate target"},
            {"parameter": "obs", "term": obs, "origin": "candidate target state field"},
            {"parameter": "hstep", "term": local, "origin": "theorem base"},
            {"parameter": "s", "term": "s", "origin": "current binder"},
            {"parameter": "xs", "term": "xs", "origin": "current binder"},
            {"parameter": "Along premise", "term": "h", "origin": "current hypothesis"}],
        "implicit_arguments": [{"name": "σ", "inferred_as": task["state_type"]},
            {"name": "ι", "inferred_as": task["input_type"]},
            {"name": "α", "inferred_from": obs}],
        "namespace": "R3Temporal", "equality_direction": "SAME" if direction_aligned else "MISMATCH",
        "required_specialization": {"expected": expected, "obs": obs},
        "state_field_alignment": field_aligned, "type_query_kernel_pass": type_query["success"],
        "application_kernel_pass": application_check["success"], "binding_success": bool(
            type_query["success"] and application_check["success"] and field_aligned and direction_aligned),
        "application": application, "type_query_result": type_query,
        "application_check_result": application_check,
        "llm_selected_theorem_name": False, "llm_selected_namespace": False,
        "llm_selected_argument_order": False}


def binder_policy() -> dict[str, Any]:
    return {"schema": "rtl2lean-typed-theorem-binder-policy-v1",
        "theorem_identity_source": "frozen theorem base", "uses_actual_lean_type_query": True,
        "uses_named_arguments": True, "kernel_checks_complete_application": True,
        "llm_may_guess_theorem_name": False, "llm_may_guess_namespace": False,
        "llm_may_guess_argument_order": False}
