"""Frozen Req15 schema selection, witness planning, and Lean skeletons."""
from __future__ import annotations

import re
from pathlib import Path
from typing import Any

from experiments.adaptive_proving.lean import check_source


SCHEMA_LIBRARY = ["GENERALIZED_STATE_INDUCTION", "TRACE_SINGLETON_DECOMPOSITION",
    "REWRITE_CHAIN", "CASE_ANALYSIS", "STATE_TRANSITION_SCHEMA",
    "WITNESS_CONSTRUCTION_SCHEMA", "THEOREM_APPLICATION_ALIGNMENT",
    "TYPE_AND_EQUALITY_ALIGNMENT"]


def select_schema(missing_edge: dict[str, Any], candidate: dict[str, Any]) -> dict[str, Any]:
    edge = missing_edge["edge_type"]
    statement = candidate["lemma_statement"]
    if edge == "STATE_TRANSITION" and "R3Temporal.Obeys" in statement:
        selected = "STATE_TRANSITION_SCHEMA"
    elif edge == "WITNESS_CONSTRUCTION" and "∃" in statement:
        selected = "WITNESS_CONSTRUCTION_SCHEMA"
    else:
        selected = None
    return {"schema": "rtl2lean-scale_evaluation-schema-selection-v1",
        "selected_schema": selected, "edge_type": edge,
        "selection_success": selected is not None,
        "selection_inputs": ["missing hyperedge type", "candidate target AST", "typed proposition"],
        "supported_schema_library": SCHEMA_LIBRARY, "challenge_specific_rule": False,
        "dut_specific_rule": False}


def plan_witness(project: Path, root: Path, task: dict[str, Any],
                 candidate: dict[str, Any], timeout_s: int) -> dict[str, Any]:
    spec = task["witness_spec"]
    statement = candidate["lemma_statement"]
    existential = re.search(r"∃\s+([A-Za-z_][A-Za-z0-9_']*)\s*:\s*([^,]+),", statement)
    proposal_success = existential is not None and existential.group(2).strip() == spec["existential_type"]
    source = "\n".join([
        f"import {task['context_import']}", f"namespace {task['module']}Verification",
        f"open {task['module']}",
        f"example (trace : List {task['input_type']}) (item : {task['input_type']}) : "
        f"{spec['existential_type']} := by exact {spec['candidate_witness']}",
        f"end {task['module']}Verification", "",
    ])
    typed = check_source(source, project / task["model_dir"], root / "typed_witness.lean", timeout_s)
    return {"schema": "rtl2lean-witness-plan-v1", "existential_target_detected": existential is not None,
        "existential_binder": existential.group(1) if existential else None,
        "existential_type": existential.group(2).strip() if existential else None,
        "witness_source": spec["source_kind"], "source_theorem": spec["source_theorem"],
        "candidate_witness": spec["candidate_witness"], "proposal_success": proposal_success,
        "typed_witness_acceptance": typed["success"], "typed_witness_result": typed,
        "llm_proposed_witness": False}


def state_skeleton(candidate: dict[str, Any], binding: dict[str, Any]) -> tuple[str, dict[str, Any]]:
    conclusion = candidate["lemma_statement"].split(" → ")[-1].strip()
    skeleton = "\n".join(["by", "  intro s xs h",
        f"  have transition_result : {conclusion} := {binding['application']}",
        "  __HOLE_MAIN__", ""])
    metadata = {"schema_id": "STATE_TRANSITION_SCHEMA", "current_state": "s",
        "next_state": "r3Step", "step_theorem": binding["fully_qualified_theorem_name"],
        "supporting_local_theorem": binding["supporting_theorem"], "required_premises": ["h"],
        "state_field_update": binding["required_specialization"]["obs"],
        "final_goal": conclusion, "remaining_proof_holes": ["HOLE_MAIN"],
        "hole_contract": {"HOLE_MAIN": "close the goal using local fact transition_result"},
        "llm_generates_outer_structure": False, "llm_selects_theorem_application": False}
    return skeleton, metadata


def witness_skeleton(task: dict[str, Any], plan: dict[str, Any]) -> tuple[str, dict[str, Any]]:
    spec = task["witness_spec"]
    skeleton = "\n".join(["by", "  intro s trace item",
        f"  refine ⟨{plan['candidate_witness']}, ?_, ?_⟩",
        "  · __HOLE_NONEMPTY__", f"  · rw [{spec['rewrite_theorem']}]",
        "    __HOLE_OBLIGATION__", ""])
    metadata = {"schema_id": "WITNESS_CONSTRUCTION_SCHEMA", "existential_target": True,
        "witness_generation_stage": {"source": plan["witness_source"],
            "typed_term": plan["candidate_witness"]},
        "obligation_stage": {"nonempty": "candidate trace is not []",
            "semantic": "run init candidate trace = r3Step s item"},
        "remaining_proof_holes": ["HOLE_NONEMPTY", "HOLE_OBLIGATION"],
        "hole_contract": {"HOLE_NONEMPTY": "prove append-singleton is nonempty",
            "HOLE_OBLIGATION": "close only the post-rewrite singleton-step equality; do not name another theorem"},
        "llm_generates_outer_structure": False, "llm_selects_witness": False}
    return skeleton, metadata


def fill_skeleton(skeleton: str, holes: dict[str, str]) -> str:
    result = skeleton
    for key in ["HOLE_MAIN", "HOLE_NONEMPTY", "HOLE_OBLIGATION"]:
        marker = "__" + key + "__"
        if marker not in result:
            continue
        line = next(line for line in result.splitlines() if marker in line)
        indent = len(line) - len(line.lstrip())
        value = str(holes.get(key, "")).strip()
        continuation = indent + 2 if line.lstrip().startswith("· ") else indent
        result = result.replace(marker, ("\n" + " " * continuation).join(value.splitlines()))
    if re.search(r"__HOLE_[A-Z_]+__", result):
        raise ValueError("one or more schema holes were not filled")
    return result


def schema_policy() -> dict[str, Any]:
    return {"schema": "rtl2lean-scale_evaluation-proof-schema-library-v1",
        "schemas": SCHEMA_LIBRARY, "new_frozen_schemas": ["STATE_TRANSITION_SCHEMA",
            "WITNESS_CONSTRUCTION_SCHEMA"], "selection_by_hyperedge_type": True,
        "witness_and_obligation_separated": True, "llm_generates_outer_structure": False,
        "challenge_specific_schemas": False, "dut_specific_schemas": False}
