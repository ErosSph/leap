"""Graph reachability utility with a Lean hypothetical cross-check."""
from __future__ import annotations

import re
from pathlib import Path
from typing import Any

from experiments.hypergraph_guidance.hypergraph import _id, forward_reachability
from experiments.bridge_discovery.utility import evaluate_candidate as lean_utility


def graph_utility(project: Path, root: Path, task: dict[str, Any], candidate: dict[str, Any],
                  graph: dict[str, Any], missing: list[dict[str, Any]],
                  existing_theorems: list[dict[str, Any]], timeout_s: int) -> tuple[dict[str, Any], dict[str, Any]]:
    if not missing:
        result = {"classification": "LOW_TARGET_UTILITY", "accepted": False,
                  "reason": "no missing hyperedge exists", "proof_attempt_avoided": True}
        return result, {}
    predicted = missing[0]; statement = candidate["lemma_statement"]
    conclusion = statement.rsplit("→", 1)[-1]
    target_expression = predicted["target_frontier"][0]
    structural_target = ("guard" in conclusion.lower() and ("exec" in conclusion or "r3Run" in conclusion)
                         and "R3Temporal.Along" in statement and bool(re.search(r"\+\+\s*\[", statement)))
    edge = {"edge_id": _id("candidate", candidate["lemma_name"] + statement), "type": "CANDIDATE_LEMMA",
        "premises": predicted["candidate_source_nodes"], "conclusion": predicted["candidate_target_node"],
        "source": candidate.get("candidate_source"), "target": candidate.get("candidate_target"),
        "declared_edge_type": candidate.get("candidate_edge_type"), "statement": statement,
        "structurally_matches_missing_edge": structural_target}
    before = forward_reachability(graph)
    after = forward_reachability(graph, [edge] if structural_target else [])
    req12_bridge = {"missing_relation_class": "LAST_STEP_GUARD"}
    lean = lean_utility(project, root / "lean_hypothetical", task, candidate, req12_bridge,
                        existing_theorems, timeout_s, .6)
    if after["goal_reachable"] and lean["classification"] == "HIGH_TARGET_UTILITY":
        classification, accepted, reason = "HIGH_TARGET_UTILITY", True, "candidate closes graph frontier and hypothetical Lean target"
    elif after["reachable_count"] > before["reachable_count"] or lean["accepted"]:
        classification, accepted, reason = "MEDIUM_TARGET_UTILITY", True, "candidate advances graph or Lean frontier"
    else:
        classification, accepted, reason = "LOW_TARGET_UTILITY", False, "candidate does not change the missing frontier"
    edge["utility_class"] = classification
    result = {"schema": "rtl2lean-tpoh-graph-utility-v1", "classification": classification,
        "accepted": accepted, "reason": reason, "before": before, "after": after,
        "reachable_node_gain": after["reachable_count"] - before["reachable_count"],
        "goal_became_reachable": not before["goal_reachable"] and after["goal_reachable"],
        "lean_hypothetical_crosscheck": lean, "temporary_edge_only": True,
        "entered_verified_pool": False, "proof_attempt_avoided": not accepted}
    return result, edge


def policy_manifest() -> dict[str, Any]:
    return {"schema": "rtl2lean-tpoh-utility-policy-v1", "forward_reachability_recomputed": True,
        "lean_hypothetical_crosscheck": True, "low_candidate_enters_proof": False}
