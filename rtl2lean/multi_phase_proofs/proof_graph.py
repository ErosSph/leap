"""Pre-proof dependency graphs and operational bottleneck analysis."""
from __future__ import annotations

import hashlib
import json
import re
from pathlib import Path
from typing import Any

from rtl2lean.pipeline.io import write_json
from rtl2lean.pipeline.manifest import Benchmark


IDENT_RE = re.compile(r"[A-Za-z_][A-Za-z0-9_'.]*")


def _read(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def _normal(value: str) -> str:
    return re.sub(r"\s+", "", value).replace("(", "").replace(")", "")


def _tokens(value: str) -> set[str]:
    return {token.rsplit(".", 1)[-1] for token in IDENT_RE.findall(value)}


def build_theorem_dependency_graph(
    benchmarks: list[Benchmark], output_root: Path, requirement_root: Path,
) -> dict[str, Any]:
    inventory_path = output_root / "proof_gaps" / "proof_gap" / "theorem_base_inventory.json"
    inventory = _read(inventory_path)
    nodes: dict[str, dict[str, Any]] = {}
    edges: list[dict[str, Any]] = []
    edge_keys: set[tuple[str, str, str]] = set()

    def add_edge(source: str, target: str, relation: str, evidence: str) -> None:
        key = (source, target, relation)
        if key not in edge_keys:
            edge_keys.add(key)
            edges.append({"source": source, "target": target, "relation": relation, "evidence": evidence})

    for theorem in inventory["theorems"]:
        dut, name, statement = theorem["dut"], theorem["name"], theorem["statement"]
        theorem_id = f"theorem::{dut}::{name}"
        nodes[theorem_id] = {
            "id": theorem_id, "kind": "THEOREM", "dut": dut, "name": name,
            "layer": theorem["source_layer"], "statement": statement,
            "source_file": theorem["source_file"],
        }
        pieces = statement.split("→")
        premise_tokens = _tokens("→".join(pieces[:-1])) if len(pieces) > 1 else set()
        conclusion_tokens = _tokens(pieces[-1])
        interesting = {
            token for token in premise_tokens | conclusion_tokens
            if token.endswith("_guard") or token in {
                "Along", "Obeys", "Until", "Eventually", "BoundedEventually",
                "r3Run", "r3Step", "exec", "run", "Reachable",
            }
        }
        for token in sorted(interesting):
            relation_id = f"relation::{dut}::{token}"
            nodes.setdefault(relation_id, {
                "id": relation_id,
                "kind": "PROPERTY_PREDICATE" if token.endswith("_guard") else "TRACE_RELATION",
                "dut": dut, "name": token,
            })
            if token in premise_tokens:
                add_edge(relation_id, theorem_id, "PREMISE_TO_CONCLUSION", token)
            if token in conclusion_tokens:
                add_edge(theorem_id, relation_id, "STATE_PHASE_DEPENDENCY", token)
        if "=" in statement:
            rewrite_id = f"rewrite::{dut}::{name}"
            nodes[rewrite_id] = {
                "id": rewrite_id, "kind": "STATE_RELATION", "dut": dut,
                "name": f"rewrite:{name}",
            }
            add_edge(theorem_id, rewrite_id, "REWRITE_RELATION", "equality conclusion")

    by_dut: dict[str, list[dict[str, Any]]] = {}
    for theorem in inventory["theorems"]:
        by_dut.setdefault(theorem["dut"], []).append(theorem)
    for dut, theorems in by_dut.items():
        generic = [row for row in theorems if row["name"] == "R3Temporal.exec_append"]
        specialized = [row for row in theorems if row["name"] == "r3_run_append"]
        if generic and specialized:
            add_edge(
                f"theorem::{dut}::R3Temporal.exec_append",
                f"theorem::{dut}::r3_run_append",
                "INSTANTIABLE_RELATION", "r3Run specializes exec to r3Step",
            )

    payload = {
        "schema": "rtl2lean-multi_phase_proofs-theorem-dependency-graph-v1",
        "captured_before_proof": True,
        "source_inventory": str(inventory_path),
        "source_inventory_sha256": hashlib.sha256(inventory_path.read_bytes()).hexdigest(),
        "nodes": sorted(nodes.values(), key=lambda row: row["id"]),
        "edges": edges,
        "metrics": {
            "N_NODES": len(nodes), "N_EDGES": len(edges),
            "N_THEOREMS": sum(row["kind"] == "THEOREM" for row in nodes.values()),
            "N_RELATIONS": sum(row["kind"] != "THEOREM" for row in nodes.values()),
        },
    }
    write_json(requirement_root / "proof_graph" / "theorem_dependency_graph.json", payload)
    return payload


def analyze_targets(
    candidates: dict[str, Any], graph: dict[str, Any], requirement_root: Path,
) -> dict[str, Any]:
    theorem_nodes = [row for row in graph["nodes"] if row["kind"] == "THEOREM"]
    target_graphs: list[dict[str, Any]] = []
    alternatives: list[dict[str, Any]] = []
    properties: list[dict[str, Any]] = []
    bottlenecks: list[dict[str, Any]] = []
    strengths: list[dict[str, Any]] = []
    for prop in candidates["properties"]:
        statement = prop["theorem_statement"]
        target_tokens = _tokens(statement)
        theorems = [row for row in theorem_nodes if row["dut"] == prop["dut"]]
        exact = [row for row in theorems if _normal(row["statement"]) == _normal(statement)]
        scored = sorted(
            ((len(target_tokens & _tokens(row["statement"])), row) for row in theorems),
            key=lambda item: (-item[0], item[1]["name"]),
        )
        reachable = [row["id"] for score, row in scored if score > 0][:20]
        gap = prop.get("gap_spec") or {}
        required_facts = gap.get("required_lower_level_facts", prop.get("foundation_lemmas", []))
        derivation_shape = gap.get("derivation_shape", "")
        simple_structural_route = bool(
            prop.get("property_family") == "SYMBOLIC_POSITION_BRIDGE"
            or derivation_shape == "LIST_INDUCTION_PLUS_L3_LOCAL_STEP"
        )
        real_semantic_evidence = bool(prop.get("rtl_evidence") and prop.get("ir_evidence"))
        relation_derivable = bool(gap.get("missing_relation_derivable", False))
        semantic_relation_required = bool(gap.get("missing_relation"))
        candidate = bool(
            not exact and not simple_structural_route and semantic_relation_required
            and relation_derivable and real_semantic_evidence and len(required_facts) >= 2
        )
        strength_evidence = gap.get("candidate_strength_evidence", {})
        strong_evidence = bool(
            candidate and (
                strength_evidence.get("real_update_regions", 0) >= 3
                and strength_evidence.get("required_lower_level_fact_count", 0) >= 3
                or derivation_shape == "SHARED_LAST_GUARD_INDUCTION_PLUS_THREE_L3_LOCAL_STEPS"
            )
        )
        existing_names = {row["name"] for row in theorems}
        unresolved_predicates = [] if exact else [
            strength_evidence.get("new_semantic_abstraction", "SYMBOLIC_LAST_GUARD_EXTRACTION")
        ]
        unresolved_relations = [] if exact else [
            gap.get("missing_relation", "TARGET_CLOSURE_RELATION")
        ]
        if prop["r8_experiment_class"] == "FOUNDATION_COVERED" or exact:
            strength, bottleneck = "NONE", False
            routes = [{
                "route": "EXISTING_FOUNDATION_MATCH", "complexity": 0,
                "uses_new_semantic_relation": False, "simple": True,
            }]
        elif simple_structural_route or not candidate:
            strength, bottleneck = "WEAK", False
            routes = [
                {"route": "INLINE_LIST_INDUCTION", "complexity": 1,
                 "uses_new_semantic_relation": True, "simple": True},
                {"route": "r3_run_append_PLUS_INLINE_LAST_GUARD", "complexity": 2,
                 "uses_new_semantic_relation": True, "simple": True},
            ]
        elif not strong_evidence:
            strength, bottleneck = "MEDIUM", True
            routes = [
                {"route": "INLINE_DERIVED_SEMANTIC_BRIDGE", "complexity": 2 + len(required_facts),
                 "uses_new_semantic_relation": True, "simple": False},
                {"route": "THEOREM_CHAIN_WITH_UNRESOLVED_SEMANTIC_BRIDGE", "complexity": 1 + len(required_facts),
                 "uses_new_semantic_relation": True, "simple": False},
            ]
        else:
            strength, bottleneck = "STRONG", True
            routes = [
                {"route": "INLINE_DERIVED_SHARED_SEMANTIC_BRIDGE", "complexity": 3 + len(required_facts),
                 "uses_new_semantic_relation": True, "simple": False},
                {"route": "SHARED_SEMANTIC_ABSTRACTION_PLUS_LOWER_LEVEL_FACTS", "complexity": 2 + len(required_facts),
                 "uses_new_semantic_relation": True, "simple": False},
            ]
        theorem_chain = [row["name"] for score, row in scored if score > 0][:8]
        target_graph = {
            "property_id": prop["property_id"], "dut": prop["dut"],
            "reachable_support_nodes": reachable,
            "candidate_chains": [theorem_chain] if theorem_chain else [],
            "chain_depth": len(theorem_chain),
            "unresolved_predicates": unresolved_predicates,
            "unresolved_relations": unresolved_relations,
            "alternative_routes": routes,
            "branching_factor": len(routes),
            "minimum_unresolved_bridge_count": 0 if exact else 1,
            "direct_foundation_matches": [row["name"] for row in exact],
            "theorem_only_closure": bool(exact),
            "proof_grammar_considered": [
                "retrieve", "instantiate", "chain", "rewrite", "simp", "induction", "cases",
            ],
            "selection_basis": "THEOREM_CLOSURE_PLUS_RTL_IR_SEMANTIC_DEPENDENCY",
            "trace_phase_count_recorded_only": statement.count("R3Temporal.Along"),
            "analysis_completed_before_proof": True,
        }
        alternative = {
            "property_id": prop["property_id"], "dut": prop["dut"],
            "routes": routes,
            "simple_alternative_found": any(row["simple"] for row in routes),
            "alternative_route_count": len(routes),
            "all_theorem_only_routes_closed": bool(exact),
            "analysis_completed_before_proof": True,
        }
        classification = (
            "FOUNDATION_COVERED" if strength == "NONE" else
            "WEAK_GAP" if strength == "WEAK" else
            f"{strength}_BOTTLENECK"
        )
        analysis = {
            "property_id": prop["property_id"], "dut": prop["dut"],
            "classification": classification,
            "bottleneck_strength": strength,
            "bottleneck_scope": "OPERATIONAL_UNDER_FROZEN_ENVIRONMENT",
            "BOTTLENECK_CANDIDATE": bottleneck,
            "foundation_direct_match": bool(exact),
            "theorem_only_closure": bool(exact),
            "simple_alternative_path_found": any(row["simple"] for row in routes),
            "minimum_unresolved_bridge_count": target_graph["minimum_unresolved_bridge_count"],
            "candidate_bottleneck_relation": gap.get("missing_relation"),
            "relation_exists_in_foundation": False if not exact else True,
            "relation_derivable_from_real_semantics": relation_derivable or bool(exact),
            "required_lower_level_facts": required_facts,
            "rtl_evidence": prop.get("rtl_evidence", []),
            "ir_evidence": prop.get("ir_evidence", []),
            "selection_basis": "THEOREM_CLOSURE_PLUS_RTL_IR_SEMANTIC_DEPENDENCY",
            "raw_phase_count_used_for_classification": False,
            "semantic_dependency_evidence": gap.get("semantic_dependency_evidence", {}),
            "alternative_routes": routes,
            "known_foundation_capabilities": sorted(existing_names & {
                "r3_run_append", "R3Temporal.exec_append", "R3Temporal.along_take",
                "R3Temporal.observe_preserved", "R3Temporal.obeys_of_along",
            }),
            "analysis_completed_before_proof": True,
        }
        properties.append({
            **prop, "r8_experiment_class": classification,
            "operational_bottleneck_candidate": bottleneck,
            "bottleneck_analysis": analysis,
        })
        target_graphs.append(target_graph)
        alternatives.append(alternative)
        bottlenecks.append(analysis)
        strengths.append({
            "property_id": prop["property_id"], "dut": prop["dut"],
            "strength": strength, "classification": classification,
            "scope": "OPERATIONAL_UNDER_FROZEN_ENVIRONMENT",
            "reason": (
                "direct foundation closure" if strength == "NONE" else
                "simple structural alternative route exists" if strength == "WEAK" else
                "no simple theorem-only closure; complex alternative candidate remains" if strength == "MEDIUM" else
                "all theorem-only routes converge on the same shared trace bridge"
            ),
        })
    analyzed = {
        **candidates,
        "schema": "rtl2lean-multi_phase_proofs-analyzed-candidates-v2-semantic-classification",
        "properties": properties,
        "proof_graph_analysis_completed": True,
        "proof_arms_observed": False,
    }
    write_json(requirement_root / "proof_graph" / "target_graphs.json", {"rows": target_graphs})
    write_json(requirement_root / "proof_graph" / "alternative_paths.json", {"rows": alternatives})
    write_json(requirement_root / "bottleneck" / "candidates.json", {"rows": bottlenecks})
    write_json(requirement_root / "bottleneck" / "strength.json", {"rows": strengths})
    return analyzed
