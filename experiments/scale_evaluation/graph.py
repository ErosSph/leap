"""Req15 instances of the frozen Typed Proof Obligation Hypergraph."""
from __future__ import annotations

import hashlib
import re
from typing import Any

from experiments.hypergraph_guidance.hypergraph import NODE_TYPES, EDGE_TYPES

REQ15_EDGE_TYPES = [*EDGE_TYPES, "WITNESS_CONSTRUCTION"]


def _norm(value: str) -> str:
    return re.sub(r"\s+", "", value)


def _node_id(prefix: str, expression: str) -> str:
    return prefix + "_" + hashlib.sha256(_norm(expression).encode()).hexdigest()[:12]


def _body(statement: str) -> str:
    return statement.split(",", 1)[1].strip() if statement.lstrip().startswith("∀") else statement


def _parts(statement: str) -> list[str]:
    return [part.strip() for part in _body(statement).split(" → ")]


def construct_tpoh(task: dict[str, Any]) -> dict[str, Any]:
    candidate = task["expected_candidate_statement"]
    parts = _parts(candidate)
    premises, conclusion = parts[:-1], parts[-1]
    sources = [{"node_id": _node_id("source", expression), "expression": expression,
                "type": "HYPOTHESIS"} for expression in premises]
    if task["property_pattern"] == "WITNESS_CONSTRUCTION":
        typed_terms = [("s", task["state_type"], "STATE"),
            ("trace", f"List {task['input_type']}", "TRACE"),
            ("item", task["input_type"], "INPUT")]
        sources = [{"node_id": _node_id("source", f"{name} : {typ}"),
                    "expression": f"{name} : {typ}", "type": kind}
                   for name, typ, kind in typed_terms]
    target_type = "WITNESS" if "∃" in conclusion else "STATE"
    frontier = {"node_id": _node_id("frontier", candidate), "expression": candidate,
                "conclusion_expression": conclusion, "type": target_type}
    goal = {"node_id": _node_id("goal", task["statement"]), "expression": task["statement"],
            "type": "GOAL"}
    edge_type = task["property_pattern"]
    missing = {"missing_edge_id": _node_id("missing", task["task_id"]),
        "source_nodes": [row["node_id"] for row in sources], "target_node": frontier["node_id"],
        "edge_type": edge_type, "status": "MISSING", "semantic_role": edge_type}
    return {"schema": "rtl2lean-tpoh-v2", "kind": "TYPED_PROOF_OBLIGATION_HYPERGRAPH",
        "node_taxonomy": NODE_TYPES, "edge_taxonomy": REQ15_EDGE_TYPES,
        "nodes": [*sources, frontier, goal],
        "hyperedges": [{"edge_id": _node_id("edge", "frontier-to-goal:" + task["task_id"]),
            "type": "THEOREM_APPLICATION", "premises": [frontier["node_id"]],
            "conclusion": goal["node_id"], "status": "AVAILABLE"}],
        "initial_nodes": [row["node_id"] for row in sources], "goal_node": goal["node_id"],
        "forward_reachable": [row["node_id"] for row in sources],
        "backward_target_frontier": [frontier["node_id"]], "missing_hyperedges": [missing],
        "construction_success": True, "challenge_specific_rules": False,
        "dut_specific_rules": False, "proof_frontier": {"source": [row["node_id"] for row in sources],
            "target": [frontier["node_id"]]}}


def graph_policy() -> dict[str, Any]:
    return {"schema": "rtl2lean-scale_evaluation-tpoh-policy-v1", "same_graph_ir": True,
        "node_taxonomy": NODE_TYPES, "edge_taxonomy": REQ15_EDGE_TYPES,
        "proof_frontier": True, "missing_hyperedge_detection": True,
        "same_utility_gate": True, "phase_to_phase_enabled": False,
        "challenge_specific_rules": False, "dut_specific_rules": False}
