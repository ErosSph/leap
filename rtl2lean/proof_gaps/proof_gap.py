"""Pre-proof theorem-base inventory and semantic gap analysis."""
from __future__ import annotations

import re
from pathlib import Path
from typing import Any

from rtl2lean.pipeline.io import write_json
from rtl2lean.pipeline.manifest import Benchmark


THEOREM_RE = re.compile(
    r"(?ms)^theorem\s+([A-Za-z_][A-Za-z0-9_']*)\s+(.*?)\s*:=\s*by"
)
IDENT_RE = re.compile(r"[A-Za-z_][A-Za-z0-9_'.]*")
TRACE_TOKENS = {
    "Along", "Obeys", "Eventually", "BoundedEventually", "Until",
    "r3Run", "r3Step", "take", "append", "Reachable",
}


def _normal(value: str) -> str:
    return re.sub(r"\s+", "", value).replace("(item)", "item")


def _tokens(value: str) -> set[str]:
    return {part.rsplit(".", 1)[-1] for part in IDENT_RE.findall(value)}


def _level(filename: str, name: str) -> str:
    if name.startswith("l1_"):
        return "L1"
    if name.startswith("l2_"):
        return "L2"
    if name.startswith("l4_") or filename == "R4Foundation.lean":
        return "L4"
    if filename == "R3Base.lean" or name.startswith("R3Temporal."):
        return "R3TEMPORAL"
    if filename == "R5Foundation.lean" or name.startswith("r5_"):
        return "EXISTING_R5"
    if name.startswith("l3_") or name.startswith("r3"):
        return "L3"
    return "OTHER"


def theorem_base_inventory(
    benchmarks: list[Benchmark], output_root: Path, requirement_root: Path,
) -> dict[str, Any]:
    rows: list[dict[str, Any]] = []
    filenames = ["Framework.lean", "R3Base.lean", "R3Foundation.lean", "R4Foundation.lean", "R5Foundation.lean"]
    for benchmark in benchmarks:
        model = output_root / benchmark.slug / "model"
        for filename in filenames:
            path = model / filename
            if not path.is_file():
                continue
            text = path.read_text(encoding="utf-8")
            namespace = "R3Temporal" if filename == "R3Base.lean" else f"{benchmark.top_module}Verification"
            for match in THEOREM_RE.finditer(text):
                raw_name = match.group(1)
                # Keep explicit parameter binders because they are part of the
                # usable theorem signature.  Declarations written `name : ∀`
                # have only their syntactic leading colon removed.
                statement = re.sub(r"^:\s*", "", match.group(2).strip())
                name = f"R3Temporal.{raw_name}" if filename == "R3Base.lean" else raw_name
                rows.append({
                    "dut": benchmark.design_id,
                    "module": benchmark.top_module,
                    "name": name,
                    "raw_name": raw_name,
                    "statement": statement,
                    "normalized_statement": _normal(statement),
                    "source_file": str(path),
                    "source_layer": _level(filename, name),
                    "namespace": namespace,
                    "tokens": sorted(_tokens(statement)),
                })
    by_level: dict[str, int] = {}
    for row in rows:
        by_level[row["source_layer"]] = by_level.get(row["source_layer"], 0) + 1
    payload = {
        "schema": "rtl2lean-proof_gaps-theorem-base-v1",
        "captured_before_any_proof_arm": True,
        "files_in_scope": filenames,
        "theorem_count": len(rows),
        "counts_by_level": by_level,
        "theorems": rows,
    }
    write_json(requirement_root / "proof_gap" / "theorem_base_inventory.json", payload)
    return payload


def _ratio(part: int, total: int) -> float:
    return 1.0 if total == 0 else part / total


def _coverage(
    prop: dict[str, Any], theorems: list[dict[str, Any]], direct: list[dict[str, Any]],
) -> tuple[float, dict[str, float], list[dict[str, Any]]]:
    statement = prop["theorem_statement"]
    target_tokens = _tokens(statement)
    fields = set(prop.get("referenced_state_fields", []))
    guards = {token for token in target_tokens if token.endswith("_guard")}
    trace = target_tokens & TRACE_TOKENS
    foundations = set(prop.get("foundation_lemmas", []))
    supporting = [row for row in theorems if (
        row["name"] in foundations
        or bool(fields & set(row["tokens"]))
        or bool(trace & set(row["tokens"]))
    )]
    support_tokens = set().union(*(set(row["tokens"]) for row in supporting)) if supporting else set()
    components = {
        "predicate_overlap": _ratio(len(trace & support_tokens), len(trace)),
        "state_field_overlap": _ratio(len(fields & support_tokens), len(fields)),
        "precondition_overlap": _ratio(len(guards & support_tokens), len(guards)),
        "postcondition_overlap": _ratio(len(fields & support_tokens), len(fields)),
        "trace_structure_overlap": _ratio(len(trace & support_tokens), len(trace)),
        "semantic_dependency_overlap": _ratio(len(foundations & {row["name"] for row in theorems}), len(foundations)),
    }
    score = sum(components.values()) / len(components)
    if direct:
        score = 1.0
    elif prop.get("gap_spec"):
        # A verified absent relation is itself uncovered target structure.  The
        # cap is semantic, fixed before arm outcomes, and prevents token overlap
        # with lower-level facts from being mistaken for full coverage.
        score = min(score, 0.74)
    return round(score, 4), components, supporting


def analyze_candidates(
    candidates: dict[str, Any], inventory: dict[str, Any], requirement_root: Path,
) -> dict[str, Any]:
    by_dut: dict[str, list[dict[str, Any]]] = {}
    for theorem in inventory["theorems"]:
        by_dut.setdefault(theorem["dut"], []).append(theorem)

    properties, coverage_rows, missing_rows, depth_rows = [], [], [], []
    for prop in candidates["properties"]:
        theorems = by_dut.get(prop["dut"], [])
        direct = [row for row in theorems
                  if row["normalized_statement"] == _normal(prop["theorem_statement"])]
        score, components, supporting = _coverage(prop, theorems, direct)
        gap = prop.get("gap_spec")
        relation = gap.get("missing_relation") if gap else None
        relation_tokens = _tokens(relation or "")
        pool_matches = [row for row in theorems if relation_tokens and
                        _ratio(len(relation_tokens & set(row["tokens"])), len(relation_tokens)) >= 0.9]
        missing_exists = bool(gap and not direct and not pool_matches)
        derivable = bool(gap and gap.get("missing_relation_derivable"))
        classification = (
            "INTERMEDIATE_LEMMA_CHALLENGE"
            if missing_exists and derivable else "FOUNDATIONALLY_COVERED"
        )
        band = "HIGH_COVERAGE" if score >= 0.75 else ("MEDIUM_COVERAGE" if score >= 0.4 else "LOW_COVERAGE")
        depth = int(gap.get("gap_depth", 0) if gap else (0 if direct else 1))
        possible_chain = [row["name"] for row in supporting[:8]]
        analysis = {
            "property_id": prop["property_id"],
            "dut": prop["dut"],
            "target_statement": prop["theorem_statement"],
            "available_supporting_theorems": [row["name"] for row in supporting],
            "directly_matching_theorems": [row["name"] for row in direct],
            "possible_theorem_chain": possible_chain,
            "chain_length": len(possible_chain),
            "coverage_score": score,
            "coverage_band": band,
            "coverage_components": components,
            "missing_relation": relation,
            "missing_relation_type": gap.get("gap_type") if gap else None,
            "missing_relation_exists_in_pool": bool(pool_matches),
            "missing_relation_pool_matches": [row["name"] for row in pool_matches],
            "missing_relation_derivable": derivable,
            "required_lower_level_facts": gap.get("required_lower_level_facts", []) if gap else [],
            "proof_gap_depth": depth,
            "classification": classification,
            "analysis_completed_before_proof": True,
        }
        analysis["proof_gap_witness"] = {
            "target": prop["theorem_statement"],
            "existing": {
                "direct_matches": [row["name"] for row in direct],
                "supporting_theorem_chain": possible_chain,
            },
            "missing": relation,
            "derivation_evidence": {
                "lower_level_theorems": gap.get("required_lower_level_facts", []) if gap else [],
                "derivation_shape": gap.get("derivation_shape") if gap else "DIRECT_FOUNDATION_MATCH",
                "rtl_regions": prop.get("rtl_evidence", []),
                "ir_regions": prop.get("ir_evidence", []),
                "kernel_reference_validation_required_before_freeze": True,
            },
        }
        properties.append({**prop, "proof_gap_analysis": analysis,
                           "classification": classification,
                           "coverage_score": score, "coverage_band": band,
                           "proof_gap_depth": depth})
        coverage_rows.append({key: analysis[key] for key in (
            "property_id", "dut", "coverage_score", "coverage_band", "coverage_components",
            "available_supporting_theorems", "directly_matching_theorems", "possible_theorem_chain", "chain_length",
        )})
        missing_rows.append({key: analysis[key] for key in (
            "property_id", "dut", "missing_relation", "missing_relation_type",
            "missing_relation_exists_in_pool", "missing_relation_pool_matches",
            "missing_relation_derivable", "required_lower_level_facts", "classification",
        )})
        depth_rows.append({
            "property_id": prop["property_id"], "dut": prop["dut"],
            "proof_gap_depth": depth, "classification": classification,
            "derivation_shape": gap.get("derivation_shape") if gap else "DIRECT_FOUNDATION_MATCH",
        })

    payload = {
        **candidates,
        "schema": "rtl2lean-proof_gaps-analyzed-corpus-v1",
        "properties": properties,
        "proof_gap_analysis_completed": True,
        "proof_arms_observed": False,
        "metrics": {
            **candidates["metrics"],
            "N_FOUNDATIONALLY_COVERED": sum(row["classification"] == "FOUNDATIONALLY_COVERED" for row in properties),
            "N_INTERMEDIATE_LEMMA_CHALLENGE": sum(row["classification"] == "INTERMEDIATE_LEMMA_CHALLENGE" for row in properties),
        },
    }
    write_json(requirement_root / "proof_gap" / "proof_gap_analysis.json", {
        "schema": "rtl2lean-proof_gaps-proof-gap-analysis-v1",
        "analysis_completed_before_proof": True,
        "proof_arms_observed": False,
        "rows": [row["proof_gap_analysis"] for row in properties],
    })
    write_json(requirement_root / "proof_gap" / "coverage_analysis.json", {"rows": coverage_rows})
    write_json(requirement_root / "proof_gap" / "missing_relations.json", {"rows": missing_rows})
    write_json(requirement_root / "proof_gap" / "proof_gap_depth.json", {"rows": depth_rows})
    return payload
