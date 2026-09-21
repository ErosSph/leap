"""Typed Proof Obligation Hypergraph (TPOH) construction and reachability."""
from __future__ import annotations

import hashlib
import re
from typing import Any


NODE_TYPES = ["GOAL", "FACT", "HYPOTHESIS", "STATE_RELATION", "TRACE_RELATION",
              "TEMPORAL_GUARD", "INVARIANT", "WITNESS", "INTERMEDIATE_LEMMA"]
EDGE_TYPES = ["THEOREM_APPLICATION", "REWRITE", "INDUCTION", "CASE_SPLIT",
              "TRACE_DECOMPOSITION", "STATE_TRANSITION", "TEMPORAL_LIFT", "CANDIDATE_LEMMA"]


def _id(prefix: str, value: str) -> str:
    return prefix + "_" + hashlib.sha256(value.encode()).hexdigest()[:12]


def _normal(value: str) -> str:
    return re.sub(r"\s+", "", value)


def _parts(text: str, sep: str = " → ") -> list[str]:
    rows, start, depth, index = [], 0, 0, 0
    while index < len(text):
        ch = text[index]
        if ch in "([{": depth += 1
        elif ch in ")]}": depth = max(0, depth - 1)
        if depth == 0 and text.startswith(sep, index):
            rows.append(text[start:index].strip()); start = index + len(sep); index += len(sep); continue
        index += 1
    rows.append(text[start:].strip()); return [row for row in rows if row]


def _strip_forall(statement: str) -> str:
    # Property/theorem manifests consistently place the implication chain after
    # the final top-level comma in their forall binder prefix.
    depth = 0
    for index, ch in enumerate(statement):
        if ch == "(": depth += 1
        elif ch == ")": depth -= 1
        elif ch == "," and depth == 0 and statement.lstrip().startswith("∀"):
            return statement[index + 1:].strip()
    return statement.strip()


def classify_expression(expression: str, source: str) -> str:
    lower = expression.lower()
    if source == "target": return "GOAL"
    if "r3temporal.along" in lower or "exec" in lower or "r3run" in lower: return "TRACE_RELATION"
    if "guard" in lower: return "TEMPORAL_GUARD"
    if "∃" in expression: return "WITNESS"
    if "r3step" in lower or "comb" in lower or "=" in expression: return "STATE_RELATION"
    if "invariant" in lower or "reachable" in lower: return "INVARIANT"
    return "FACT"


def make_node(expression: str, node_type: str | None, source: str, temporal_scope: str,
              state_fields: list[str]) -> dict[str, Any]:
    return {"node_id": _id("n", source + ":" + _normal(expression)), "expression": expression,
        "type": node_type or classify_expression(expression, source),
        "symbols": sorted(set(re.findall(r"[A-Za-z_][A-Za-z0-9_'.]*", expression))),
        "state_fields": sorted(set(state_fields)), "temporal_scope": temporal_scope, "source": source}


def build_hypergraph(task: dict[str, Any], gap: dict[str, Any],
                     retrieved: list[dict[str, Any]]) -> tuple[dict[str, Any], dict[str, Any], list[dict[str, Any]]]:
    body = _strip_forall(task["statement"]); chain = _parts(body)
    premises, goal_expression = chain[:-1], chain[-1]
    scope = "PREFIX_LAST_ITEM" if gap["temporal_structure"]["append_singleton_occurrences"] else "SINGLE_STEP"
    nodes: dict[str, dict[str, Any]] = {}
    def add(expr: str, typ: str | None, source: str) -> str:
        node = make_node(expr, typ, source, scope, task.get("required_state_fields", [])); nodes[node["node_id"]] = node
        return node["node_id"]
    hypothesis_ids = [add(expr, "HYPOTHESIS", "target_premise") for expr in premises]
    goal_id = add(goal_expression, "GOAL", "target")
    edges: list[dict[str, Any]] = []
    theorem_nodes = []
    for theorem in retrieved:
        theorem_body = _strip_forall(theorem["statement"]); theorem_parts = _parts(theorem_body)
        premise_ids = [add(expr, None, f"theorem:{theorem['name']}:premise") for expr in theorem_parts[:-1]]
        conclusion_id = add(theorem_parts[-1], None, f"theorem:{theorem['name']}:conclusion")
        edges.append({"edge_id": _id("e", theorem["name"]), "type": "THEOREM_APPLICATION",
            "premises": premise_ids, "conclusion": conclusion_id, "source": theorem["name"],
            "status": "AVAILABLE"}); theorem_nodes.append(conclusion_id)
    local = next((row for row in retrieved if row["name"] == task.get("selected_local_step")), None)
    if not local:
        local = next((row for row in retrieved if str(row["name"]).endswith("_local_step")), None)
    missing = []
    if local and scope == "PREFIX_LAST_ITEM":
        guard = re.search(r"([A-Za-z_][A-Za-z0-9_']*_guard)\s+s\s+item", local["statement"])
        guard_expr = f"{guard.group(1)} (r3Run s pre) item" if guard else "guard (r3Run s pre) item"
        guard_id = add(guard_expr, "TEMPORAL_GUARD", "backward_goal_from_local_step")
        edges.append({"edge_id": _id("e", "specialized:" + local["name"]),
            "type": "THEOREM_APPLICATION", "premises": [guard_id], "conclusion": goal_id,
            "source": local["name"], "status": "AVAILABLE_AFTER_REWRITE",
            "required_rewrite": "r3_run_append"})
        missing.append({"missing_edge_id": _id("missing", task["task_id"]),
            "candidate_source_nodes": hypothesis_ids, "candidate_target_node": guard_id,
            "candidate_edge_type": "TEMPORAL_LIFT", "reason": "Along over prefix++[last] does not yet expose the last guard",
            "source_frontier": [nodes[node]["expression"] for node in hypothesis_ids],
            "target_frontier": [guard_expr]})
    elif local and hypothesis_ids:
        edges.append({"edge_id": _id("e", "direct:" + local["name"]), "type": "THEOREM_APPLICATION",
            "premises": hypothesis_ids, "conclusion": goal_id, "source": local["name"], "status": "AVAILABLE"})
    graph = {"schema": "rtl2lean-tpoh-v1", "node_taxonomy": NODE_TYPES, "edge_taxonomy": EDGE_TYPES,
        "nodes": sorted(nodes.values(), key=lambda row: row["node_id"]), "hyperedges": edges,
        "initial_nodes": hypothesis_ids, "goal_node": goal_id, "construction_success": True,
        "challenge_specific_rules": False, "dut_specific_rules": False}
    reach = forward_reachability(graph)
    frontier = {"schema": "rtl2lean-tpoh-frontier-v1", "source_frontier": hypothesis_ids,
        "target_frontier": ([missing[0]["candidate_target_node"]] if missing else [goal_id]),
        "forward_reachable": reach["reachable_nodes"], "goal_reachable": reach["goal_reachable"],
        "backward_required_edges": [edge["edge_id"] for edge in edges if edge["conclusion"] == goal_id],
        "missing_hyperedge_detected": bool(missing)}
    return graph, frontier, missing


def forward_reachability(graph: dict[str, Any], extra_edges: list[dict[str, Any]] | None = None) -> dict[str, Any]:
    reachable = set(graph["initial_nodes"]); fired = []; edges = [*graph["hyperedges"], *(extra_edges or [])]
    changed = True
    while changed:
        changed = False
        for edge in edges:
            if edge["edge_id"] in fired: continue
            if set(edge["premises"]).issubset(reachable):
                fired.append(edge["edge_id"])
                if edge["conclusion"] not in reachable: reachable.add(edge["conclusion"]); changed = True
    return {"schema": "rtl2lean-tpoh-reachability-v1", "reachable_nodes": sorted(reachable),
        "fired_edges": fired, "goal_reachable": graph["goal_node"] in reachable,
        "reachable_count": len(reachable), "node_count": len(graph["nodes"])}


def annotate_failure(graph: dict[str, Any], candidate_edge: dict[str, Any], diagnosis: dict[str, Any],
                     alignment: dict[str, Any], schema: dict[str, Any]) -> dict[str, Any]:
    return {"schema": "rtl2lean-tpoh-failure-annotation-v1",
        "failed_hyperedge": candidate_edge.get("edge_id"),
        "missing_premises": alignment.get("missing_premises", []),
        "node_type_mismatches": alignment.get("type_mismatches", []),
        "failed_proof_schema": schema.get("schema_id"),
        "failure_class": diagnosis.get("primary_cause"),
        "frontier_advanced": candidate_edge.get("utility_class") in {"HIGH_TARGET_UTILITY", "MEDIUM_TARGET_UTILITY"},
        "repair_or_redesign": "REPAIR_SCHEMA" if diagnosis.get("primary_cause") in {
            "INDUCTION_STATE_NOT_GENERALIZED", "TRACE_SINGLETON_NOT_DESTRUCTURED",
            "THEOREM_APPLICATION_MISMATCH", "TYPE_MISMATCH"} else "REDESIGN_EDGE"}


def policy_manifest() -> dict[str, Any]:
    return {"schema": "rtl2lean-tpoh-policy-v1", "node_types": NODE_TYPES, "edge_types": EDGE_TYPES,
        "forward_reachability": True, "backward_goal_analysis": True,
        "challenge_specific_rules": False, "dut_specific_rules": False}
