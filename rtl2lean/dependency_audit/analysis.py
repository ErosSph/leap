"""Normalize proof paths and distinguish syntactic from semantic bypass."""
from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any

from rtl2lean.pipeline.io import write_json


FINAL_CLASSES = (
    "COMPRESSED_ORIGINAL_PATH", "SUMMARY_THEOREM_COMPRESSION",
    "INLINE_COMPOSITION", "GENUINE_ALTERNATIVE_PATH",
)
RELATION_MATCH_KINDS = {
    "EXACT_R", "SEMANTIC_EQUIVALENT_R", "SPECIALIZATION_OF_R",
    "GENERALIZATION_OF_R", "IMPLICIT_COMPOSITION_EQUIVALENT_TO_R",
}


def _read(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def _short(name: str) -> str:
    return name.rsplit(".", 1)[-1]


def _dependency_names(expansion: dict[str, Any]) -> set[str]:
    return {node["id"] for node in expansion["nodes"]}


def _contains_dependency(names: set[str], requested: str) -> bool:
    return requested in names or any(name.endswith("." + requested) for name in names)


def _local_guard_summary(proof: str) -> bool:
    return bool(
        re.search(r"\bhave\s+[A-Za-z0-9_]*(?:guard|along|last|endpoint)[A-Za-z0-9_]*", proof, re.I)
        and "induction" in proof
    )


def _descendants(expansion: dict[str, Any], source: str) -> set[str]:
    """Return every declaration reachable from ``source`` in the kernel graph."""
    adjacency: dict[str, set[str]] = {}
    for edge in expansion["edges"]:
        adjacency.setdefault(edge["source"], set()).add(edge["target"])
    seen: set[str] = set()
    pending = list(adjacency.get(source, ()))
    while pending:
        name = pending.pop()
        if name in seen:
            continue
        seen.add(name)
        pending.extend(adjacency.get(name, ()))
    return seen


def _summary_theorem_compression(
    prop: dict[str, Any], dependency: dict[str, Any], expansion: dict[str, Any],
) -> list[str]:
    """Find a directly used, named theorem that packages the bottleneck path.

    Local-step facts and generic append machinery are not summary theorems.  A
    candidate must be a first-level theorem dependency whose recursively
    expanded body reaches every required RTL local-step fact.  Requiring the
    whole set avoids misclassifying one ordinary L3 fact as a summary.
    """
    required = (prop.get("gap_spec") or {}).get("required_lower_level_facts", [])
    required_steps = [name for name in required if name.endswith("_local_step")]
    if not required_steps:
        return []
    nodes = {node["id"]: node for node in expansion["nodes"]}
    summaries: list[str] = []
    for name in dependency.get("first_level_theorem_dependencies", []):
        short = _short(name)
        if short in required_steps or short in {
            "exec_append", "r3_run_append", "foldl_append",
        }:
            continue
        node = nodes.get(name)
        if not node or not node.get("statement"):
            continue
        reachable = _descendants(expansion, name) | {name}
        if all(_contains_dependency(reachable, fact) for fact in required_steps):
            summaries.append(name)
    return sorted(summaries)


def _canonical_statement(statement: str) -> str:
    return re.sub(r"\s+", "", statement).replace("→", "->").lower()


def _statement_atoms(statement: str) -> set[str]:
    """Conservative identifiers used only for declared formal R matching."""
    ignored = {
        "forall", "fun", "let", "in", "prop", "type", "true", "false",
        "and", "or", "not", "list", "nat", "bitvec",
    }
    return {
        token.lower() for token in re.findall(r"[A-Za-z_][A-Za-z0-9_'.]*", statement)
        if token.lower() not in ignored
    }


def _relation_match_kinds(
    prop: dict[str, Any], expansion: dict[str, Any], semantic_used: bool,
) -> list[str]:
    """Match the candidate bottleneck relation to recursively used theorems.

    Exact/specialization/generalization checks are enabled only when the corpus
    supplies a formal ``missing_relation_statement``.  Natural-language
    descriptions are not promoted to formal equivalence; in that case kernel
    dependency plus the normalized semantic composition is reported explicitly.
    """
    gap = prop.get("gap_spec") or {}
    relation = gap.get("missing_relation_statement")
    matches: set[str] = set()
    if relation:
        relation_norm = _canonical_statement(relation)
        relation_atoms = _statement_atoms(relation)
        anchors = {str(item).lower() for item in gap.get("relation_anchors", [])}
        for node in expansion["nodes"]:
            statement = node.get("statement")
            if not statement:
                continue
            statement_norm = _canonical_statement(statement)
            statement_atoms = _statement_atoms(statement)
            if statement_norm == relation_norm:
                matches.add("EXACT_R")
            elif relation_atoms and relation_atoms < statement_atoms:
                matches.add("GENERALIZATION_OF_R")
            elif statement_atoms and statement_atoms < relation_atoms:
                matches.add("SPECIALIZATION_OF_R")
            if anchors and anchors <= {atom.rsplit(".", 1)[-1] for atom in statement_atoms}:
                matches.add("SEMANTIC_EQUIVALENT_R")
    if semantic_used:
        matches.add("IMPLICIT_COMPOSITION_EQUIVALENT_TO_R")
    return sorted(matches)


def _normalized_path(
    arm: str, prop: dict[str, Any], trial: dict[str, Any],
    dependency: dict[str, Any], expansion: dict[str, Any],
) -> dict[str, Any]:
    final_proof = trial.get("final_proof") or ""
    lemma_proofs = "\n".join(
        (lemma.get("proof_body") or lemma.get("proof") or "")
        for lemma in trial.get("intermediate_lemmas", [])
    )
    proof = final_proof + "\n" + lemma_proofs
    names = _dependency_names(expansion)
    required = (prop.get("gap_spec") or {}).get("required_lower_level_facts", [])
    local_steps = [name for name in required if name.endswith("_local_step")]
    matched_steps = [name for name in local_steps if _contains_dependency(names, name)]
    has_induction = bool(re.search(r"\binduction\b", proof))
    has_along = "R3Temporal.Along" in prop["theorem_statement"] and (
        "R3Temporal.Along" in proof or has_induction
    )
    has_append = any(_contains_dependency(names, name) for name in (
        "r3_run_append", "R3Temporal.exec_append", "List.foldl_append",
    ))
    has_local_guard = _local_guard_summary(final_proof)
    semantic_used = bool(
        has_along and has_induction and local_steps
        and len(matched_steps) == len(local_steps)
    )

    semantic_nodes = ["ALONG_ASSUMPTIONS"]
    if has_induction:
        semantic_nodes.extend(["TRACE_PREFIX_RECURSION", "LAST_STEP_GUARD_EXTRACTION"])
    if arm == "LEMMA_FIRST" and trial.get("intermediate_lemmas"):
        semantic_nodes.append("NAMED_INTERMEDIATE_ABSTRACTION")
    if has_append:
        semantic_nodes.append("RUN_APPEND_NORMALIZATION")
    if matched_steps:
        semantic_nodes.append("RTL_LOCAL_STEP_SEMANTICS")
    if "constructor" in proof or "And.intro" in names:
        semantic_nodes.append("CONJUNCTION_ASSEMBLY")
    semantic_nodes.append("TARGET_CONCLUSION")
    edges = [
        {"source": semantic_nodes[index], "target": semantic_nodes[index + 1]}
        for index in range(len(semantic_nodes) - 1)
    ]
    return {
        "arm": arm, "dut": prop["dut"], "property_id": prop["property_id"],
        "trial": trial["trial"], "root": dependency["root"],
        "semantic_nodes": semantic_nodes, "semantic_edges": edges,
        "normalized_path": " → ".join(semantic_nodes),
        "intermediate_states": [
            node for node in semantic_nodes
            if node not in {"ALONG_ASSUMPTIONS", "TARGET_CONCLUSION", "CONJUNCTION_ASSEMBLY"}
        ],
        "theorem_chain_depth": expansion["max_depth"],
        "primitive_dependency_count": expansion["primitive_dependency_count"],
        "expanded_theorem_dependencies": sorted(
            node["id"] for node in expansion["nodes"]
            if node["layer"] != "PRIMITIVE_DEFINITION"
        ),
        "expanded_primitive_dependencies": expansion["primitive_leaves"],
        "required_lower_level_facts": required,
        "matched_local_step_facts": matched_steps,
        "trace_induction_present": has_induction,
        "local_guard_summary_present": has_local_guard,
        "run_append_normalization_present": has_append,
        "bottleneck_semantically_used": semantic_used,
        "semantic_match_evidence": (
            "IMPLICIT_COMPOSITION_EQUIVALENT_TO_R" if semantic_used else "NO_MATCH"
        ),
    }


def _overlap(direct: dict[str, Any], lemma: dict[str, Any]) -> dict[str, Any]:
    ignored = {"NAMED_INTERMEDIATE_ABSTRACTION"}
    left = set(direct["semantic_nodes"]) - ignored
    right = set(lemma["semantic_nodes"]) - ignored
    union = left | right
    node_score = len(left & right) / len(union) if union else 1.0
    left_deps = {_short(name) for name in direct["expanded_theorem_dependencies"]}
    right_deps = {_short(name) for name in lemma["expanded_theorem_dependencies"]}
    dep_union = left_deps | right_deps
    dependency_score = len(left_deps & right_deps) / len(dep_union) if dep_union else 1.0
    score = (node_score + dependency_score) / 2
    if node_score == 1.0 and dependency_score == 1.0:
        classification = "SAME_SEMANTIC_PATH"
    elif score >= 0.8:
        classification = "MOSTLY_SAME_PATH"
    elif score >= 0.4:
        classification = "PARTIALLY_OVERLAPPING"
    else:
        classification = "GENUINELY_DIFFERENT_PATH"
    return {
        "dut": direct["dut"], "property_id": direct["property_id"], "trial": direct["trial"],
        "classification": classification,
        "normalized_semantic_node_overlap": round(node_score, 6),
        "expanded_dependency_overlap": round(dependency_score, 6),
        "combined_overlap": round(score, 6),
        "shared_semantic_nodes": sorted(left & right),
        "direct_only_semantic_nodes": sorted(left - right),
        "lemma_only_semantic_nodes": sorted(right - left),
        "direct_chain_depth": direct["theorem_chain_depth"],
        "lemma_chain_depth": lemma["theorem_chain_depth"],
        "direct_primitive_dependencies": direct["primitive_dependency_count"],
        "lemma_primitive_dependencies": lemma["primitive_dependency_count"],
    }


def analyze_paths(
    output_root: Path, requirement_root: Path,
    direct_dependencies: dict[str, Any], lemma_dependencies: dict[str, Any],
    expansions: dict[str, Any],
) -> tuple[dict[str, Any], dict[str, Any], dict[str, Any], dict[str, Any]]:
    corpus = _read(output_root / "multi_phase_proofs" / "corpus" / "bottleneck_challenges.json")
    direct_payload = _read(output_root / "multi_phase_proofs" / "direct" / "trials.json")
    lemma_payload = _read(output_root / "multi_phase_proofs" / "lemma_first" / "trials.json")
    bypass_payload = _read(output_root / "multi_phase_proofs" / "direct" / "bypass_audit.json")
    props = {(row["dut"], row["property_id"]): row for row in corpus["properties"]}
    direct_trials = {
        (row["dut"], row["property_id"], row["trial"]): row
        for row in direct_payload["trial_results"]
        if row.get("evidence_source") == "multi_phase_proofs_LIVE_TRIAL"
    }
    lemma_trials = {
        (row["dut"], row["property_id"], row["trial"]): row
        for row in lemma_payload["trial_results"]
        if row.get("evidence_source") == "multi_phase_proofs_LIVE_TRIAL"
    }
    direct_dep = {(row["dut"], row["property_id"], row["trial"]): row
                  for row in direct_dependencies["rows"]}
    lemma_dep = {(row["dut"], row["property_id"], row["trial"]): row
                 for row in lemma_dependencies["rows"]}
    direct_exp = {(row["dut"], row["property_id"], row["trial"]): row
                  for row in expansions["rows"] if row["arm"] == "DIRECT"}
    lemma_exp = {(row["dut"], row["property_id"], row["trial"]): row
                 for row in expansions["rows"] if row["arm"] == "LEMMA_FIRST"}
    reported = {(row["dut"], row["property_id"]): row
                for row in bypass_payload["per_target"]}

    direct_paths: list[dict[str, Any]] = []
    lemma_paths: list[dict[str, Any]] = []
    overlaps: list[dict[str, Any]] = []
    classifications: list[dict[str, Any]] = []
    for key in sorted(direct_trials):
        target_key = key[:2]
        prop = props[target_key]
        dpath = _normalized_path(
            "DIRECT", prop, direct_trials[key], direct_dep[key], direct_exp[key],
        )
        lpath = _normalized_path(
            "LEMMA_FIRST", prop, lemma_trials[key], lemma_dep[key], lemma_exp[key],
        )
        direct_paths.append(dpath); lemma_paths.append(lpath)
        overlap = _overlap(dpath, lpath)
        overlaps.append(overlap)
        structural_semantic_use = dpath["bottleneck_semantically_used"]
        proof = direct_trials[key].get("final_proof") or ""
        syntactic = bool(reported[target_key].get("DIRECT_BYPASS"))
        summary_theorems = _summary_theorem_compression(
            prop, direct_dep[key], direct_exp[key],
        )
        # A local summary explicitly packages the predicted Along-to-last-guard
        # relation. Without such a local theorem, the same composition is inline.
        matches = _relation_match_kinds(prop, direct_exp[key], structural_semantic_use)
        semantically_used = bool(matches)
        dpath["bottleneck_semantically_used"] = semantically_used
        dpath["semantic_match_evidence"] = matches or ["NO_MATCH"]
        if not semantically_used:
            final_class = "GENUINE_ALTERNATIVE_PATH"
        elif summary_theorems:
            final_class = "SUMMARY_THEOREM_COMPRESSION"
        elif dpath["local_guard_summary_present"]:
            final_class = "COMPRESSED_ORIGINAL_PATH"
        else:
            final_class = "INLINE_COMPOSITION"
        classifications.append({
            "dut": key[0], "property_id": key[1], "trial": key[2],
            "multi_phase_proofs_reported_bypass": reported[target_key].get("DIRECT_BYPASS", False),
            "SYNTACTIC_BYPASS": syntactic,
            "SEMANTIC_BYPASS": not semantically_used,
            "TRUE_DIRECT_BYPASS": final_class == "GENUINE_ALTERNATIVE_PATH",
            "bottleneck_semantically_used": semantically_used,
            "bottleneck_relation": prop["bottleneck_analysis"].get("candidate_bottleneck_relation"),
            "relation_match_kinds": matches,
            "final_class": final_class,
            "expanded_path": dpath["normalized_path"],
            "direct_uses_named_intermediate_lemma": False,
            "local_summary_detected": dpath["local_guard_summary_present"],
            "summary_theorems_detected": summary_theorems,
            "inline_induction_detected": dpath["trace_induction_present"],
            "proof_sha256": direct_dep[key]["proof_sha256"],
            "evidence": {
                "matched_local_step_facts": dpath["matched_local_step_facts"],
                "theorem_chain_depth": dpath["theorem_chain_depth"],
                "proof_term_dependencies": direct_dep[key]["first_level_dependencies"],
                "summary_theorem_dependencies": summary_theorems,
                "normalized_path_overlap": overlap["classification"],
                "proof_excerpt": proof[:1200],
            },
        })

    direct_result = {"schema": "rtl2lean-dependency_audit-direct-paths-v1", "rows": direct_paths}
    lemma_result = {"schema": "rtl2lean-dependency_audit-lemma-paths-v1", "rows": lemma_paths}
    overlap_result = {"schema": "rtl2lean-dependency_audit-path-overlap-v1", "rows": overlaps}
    classification_result = {
        "schema": "rtl2lean-dependency_audit-bypass-classification-v1", "rows": classifications,
    }
    normalized = requirement_root / "normalized_paths"
    write_json(normalized / "direct_paths.json", direct_result)
    write_json(normalized / "lemma_first_paths.json", lemma_result)
    write_json(normalized / "path_overlap.json", overlap_result)
    bypass_root = requirement_root / "bypass"
    write_json(bypass_root / "syntactic_bypass.json", {
        "schema": "rtl2lean-dependency_audit-syntactic-bypass-v1",
        "rows": [{key: row[key] for key in (
            "dut", "property_id", "trial", "multi_phase_proofs_reported_bypass", "SYNTACTIC_BYPASS",
        )} for row in classifications],
    })
    write_json(bypass_root / "semantic_bypass.json", {
        "schema": "rtl2lean-dependency_audit-semantic-bypass-v1",
        "rows": [{key: row[key] for key in (
            "dut", "property_id", "trial", "SEMANTIC_BYPASS", "TRUE_DIRECT_BYPASS",
            "bottleneck_semantically_used", "relation_match_kinds", "expanded_path",
        )} for row in classifications],
    })
    write_json(bypass_root / "classification.json", classification_result)
    return direct_result, lemma_result, overlap_result, classification_result


def reevaluate_strong(
    output_root: Path, requirement_root: Path, classification: dict[str, Any],
) -> dict[str, Any]:
    corpus = _read(output_root / "multi_phase_proofs" / "corpus" / "bottleneck_challenges.json")
    strong = {(row["dut"], row["property_id"]): row for row in corpus["properties"]
              if row["r8_experiment_class"] == "STRONG_BOTTLENECK"}
    rows = []
    for key, prop in strong.items():
        trials = [row for row in classification["rows"]
                  if (row["dut"], row["property_id"]) == key]
        genuine = sum(row["final_class"] == "GENUINE_ALTERNATIVE_PATH" for row in trials)
        rows.append({
            "dut": key[0], "property_id": key[1],
            "multi_phase_proofs_strong_false_positive": True,
            "trials": len(trials), "genuine_alternative_trials": genuine,
            "bottleneck_semantically_used_trials": sum(
                row["bottleneck_semantically_used"] for row in trials
            ),
            "TRUE_STRONG_FALSE_POSITIVE": len(trials) >= 5 and genuine == len(trials),
            "frozen_strength": prop["bottleneck_analysis"]["bottleneck_strength"],
            "multi_phase_proofs_result_modified": False,
        })
    result = {"schema": "rtl2lean-dependency_audit-strong-reevaluation-v1", "rows": rows}
    write_json(requirement_root / "strong_bottleneck" / "reevaluation.json", result)
    return result
