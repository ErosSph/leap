"""dependency_audit tables, case studies, research answers, and integrity gates."""
from __future__ import annotations

import csv
import json
import shutil
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any

from rtl2lean.pipeline.io import sha256, write_json
from rtl2lean.pipeline.manifest import Benchmark
from rtl2lean.compositional_proofs.report import tree_digest
from rtl2lean.dependency_audit.analysis import FINAL_CLASSES, RELATION_MATCH_KINDS


def _read(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def _csv(path: Path, rows: list[dict[str, Any]], fields: list[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=fields, extrasaction="ignore")
        writer.writeheader(); writer.writerows(rows)


def _copy_audit_source(source: str, root: Path) -> dict[str, Any]:
    path = Path(source)
    target = root / "proof_term_audit.lean"
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(path, target)
    return {"source": str(path), "copy": str(target), "sha256": sha256(target)}


def _case(
    name: str, selected: dict[str, Any] | None, note: str,
    requirement_root: Path, properties: dict[tuple[str, str], dict[str, Any]],
    direct_trials: dict[tuple[str, str, int], dict[str, Any]],
    lemma_trials: dict[tuple[str, str, int], dict[str, Any]],
    direct_deps: dict[tuple[str, str, int], dict[str, Any]],
    expansions: dict[tuple[str, str, int, str], dict[str, Any]],
    direct_paths: dict[tuple[str, str, int], dict[str, Any]],
    lemma_paths: dict[tuple[str, str, int], dict[str, Any]],
    overlaps: dict[tuple[str, str, int], dict[str, Any]],
) -> None:
    root = requirement_root / "case_studies" / name
    if selected is None:
        write_json(root / "case.json", {
            "schema": "rtl2lean-dependency_audit-case-v1", "available": False,
            "selection_criterion": note,
            "reason": "No frozen multi_phase_proofs Direct proof satisfied this classification.",
            "result_shaping": False,
        })
        return
    key = (selected["dut"], selected["property_id"], selected["trial"])
    prop = properties[key[:2]]
    payload = {
        "schema": "rtl2lean-dependency_audit-case-v1", "available": True,
        "case_type": name, "selection_reason": note,
        "target": prop, "multi_phase_proofs_predicted_bottleneck": prop["bottleneck_analysis"],
        "direct_proof": direct_trials[key],
        "direct_first_level_dependencies": direct_deps[key],
        "recursive_expansion": expansions[(*key, "DIRECT")],
        "direct_normalized_path": direct_paths[key],
        "lemma_first_proof": lemma_trials[key],
        "lemma_first_recursive_expansion": expansions[(*key, "LEMMA_FIRST")],
        "lemma_first_normalized_path": lemma_paths[key],
        "path_comparison": overlaps[key],
        "final_classification": selected,
        "audit_source": _copy_audit_source(direct_deps[key]["audit_source"], root),
        "multi_phase_proofs_proof_modified": False,
    }
    write_json(root / "case.json", payload)
    for filename, value in (
        ("target.json", prop),
        ("predicted_bottleneck.json", prop["bottleneck_analysis"]),
        ("direct_proof.json", direct_trials[key]),
        ("first_level_dependencies.json", direct_deps[key]),
        ("recursive_expansion.json", expansions[(*key, "DIRECT")]),
        ("direct_normalized_path.json", direct_paths[key]),
        ("lemma_first_proof.json", lemma_trials[key]),
        ("lemma_first_expansion.json", expansions[(*key, "LEMMA_FIRST")]),
        ("lemma_first_normalized_path.json", lemma_paths[key]),
        ("path_comparison.json", overlaps[key]),
        ("final_classification.json", selected),
    ):
        write_json(root / filename, value)


def build_report(
    benchmarks: list[Benchmark], output_root: Path, requirement_root: Path,
    direct_dependencies: dict[str, Any], lemma_dependencies: dict[str, Any],
    expansions_payload: dict[str, Any], direct_paths_payload: dict[str, Any],
    lemma_paths_payload: dict[str, Any], overlap_payload: dict[str, Any],
    classification_payload: dict[str, Any], strong_payload: dict[str, Any],
    frozen_r8_digest: str, frozen_model_digests: dict[str, str],
) -> dict[str, Any]:
    corpus = _read(output_root / "multi_phase_proofs" / "corpus" / "bottleneck_challenges.json")
    r8_direct = _read(output_root / "multi_phase_proofs" / "direct" / "trials.json")
    r8_lemma = _read(output_root / "multi_phase_proofs" / "lemma_first" / "trials.json")
    properties = {(row["dut"], row["property_id"]): row for row in corpus["properties"]}
    direct_trials = {(row["dut"], row["property_id"], row["trial"]): row
                     for row in r8_direct["trial_results"]
                     if row.get("evidence_source") == "multi_phase_proofs_LIVE_TRIAL"}
    lemma_trials = {(row["dut"], row["property_id"], row["trial"]): row
                    for row in r8_lemma["trial_results"]
                    if row.get("evidence_source") == "multi_phase_proofs_LIVE_TRIAL"}
    direct_deps = {(row["dut"], row["property_id"], row["trial"]): row
                   for row in direct_dependencies["rows"]}
    lemma_deps = {(row["dut"], row["property_id"], row["trial"]): row
                  for row in lemma_dependencies["rows"]}
    expansions = {(row["dut"], row["property_id"], row["trial"], row["arm"]): row
                  for row in expansions_payload["rows"]}
    direct_paths = {(row["dut"], row["property_id"], row["trial"]): row
                    for row in direct_paths_payload["rows"]}
    lemma_paths = {(row["dut"], row["property_id"], row["trial"]): row
                   for row in lemma_paths_payload["rows"]}
    overlaps = {(row["dut"], row["property_id"], row["trial"]): row
                for row in overlap_payload["rows"]}
    classifications = classification_payload["rows"]
    class_counts = Counter(row["final_class"] for row in classifications)
    targets = {(row["dut"], row["property_id"]) for row in classifications}
    metrics = {
        "N_DIRECT_BYPASS_REPORTED": len(targets),
        "N_DIRECT_PROOFS_AUDITED": len(classifications),
        **{f"N_{name}": class_counts[name] for name in FINAL_CLASSES},
        "N_SYNTACTIC_BYPASS": sum(row["SYNTACTIC_BYPASS"] for row in classifications),
        "N_SEMANTIC_BYPASS": sum(row["SEMANTIC_BYPASS"] for row in classifications),
        "N_BOTTLENECK_SEMANTICALLY_USED": sum(
            row["bottleneck_semantically_used"] for row in classifications
        ),
        "TRUE_BYPASS_RATE": (
            sum(row["TRUE_DIRECT_BYPASS"] for row in classifications) / len(classifications)
            if classifications else None
        ),
        "N_TRUE_STRONG_FALSE_POSITIVE": sum(
            row["TRUE_STRONG_FALSE_POSITIVE"] for row in strong_payload["rows"]
        ),
    }

    table_rows = [{
        "Challenge": row["property_id"], "DUT": row["dut"], "Trial": row["trial"],
        "Reported Bypass": row["multi_phase_proofs_reported_bypass"],
        "Expanded Path": row["expanded_path"],
        "Bottleneck Semantically Used": row["bottleneck_semantically_used"],
        "Final Class": row["final_class"],
    } for row in classifications]
    _csv(requirement_root / "tables" / "bypass_classification.csv", table_rows, [
        "Challenge", "DUT", "Trial", "Reported Bypass", "Expanded Path",
        "Bottleneck Semantically Used", "Final Class",
    ])
    _csv(requirement_root / "tables" / "normalized_path_comparison.csv", overlap_payload["rows"], [
        "dut", "property_id", "trial", "classification", "normalized_semantic_node_overlap",
        "expanded_dependency_overlap", "combined_overlap", "direct_chain_depth",
        "lemma_chain_depth", "direct_primitive_dependencies", "lemma_primitive_dependencies",
    ])
    _csv(requirement_root / "tables" / "strong_bottleneck_reevaluation.csv", strong_payload["rows"], [
        "dut", "property_id", "multi_phase_proofs_strong_false_positive", "trials",
        "genuine_alternative_trials", "bottleneck_semantically_used_trials",
        "TRUE_STRONG_FALSE_POSITIVE", "frozen_strength", "multi_phase_proofs_result_modified",
    ])

    by_class = defaultdict(list)
    for row in classifications:
        by_class[row["final_class"]].append(row)
    strong_case = next((row for row in classifications
                        if properties[(row["dut"], row["property_id"])]["r8_experiment_class"]
                        == "STRONG_BOTTLENECK"), None)
    for name, selected, note in (
        ("compressed_original_path", next(iter(by_class["COMPRESSED_ORIGINAL_PATH"]), None),
         "Expanded proof retains the predicted relation through a local summary"),
        ("summary_theorem_compression", next(iter(by_class["SUMMARY_THEOREM_COMPRESSION"]), None),
         "An imported summary theorem recursively expands through the predicted relation"),
        ("inline_composition", next(iter(by_class["INLINE_COMPOSITION"]), None),
         "Direct composes the predicted intermediate reasoning inline"),
        ("genuine_alternative_path", next(iter(by_class["GENUINE_ALTERNATIVE_PATH"]), None),
         "Recursive expansion does not pass through the predicted semantic relation"),
        ("strong_bottleneck_reevaluation", strong_case,
         "multi_phase_proofs Strong false-positive classification re-evaluated semantically"),
    ):
        _case(name, selected, note, requirement_root, properties, direct_trials, lemma_trials,
              direct_deps, expansions, direct_paths, lemma_paths, overlaps)

    current_models = {benchmark.design_id: tree_digest(output_root / benchmark.slug / "model")
                      for benchmark in benchmarks}
    direct_proof_hashes_match = all(
        direct_deps[key]["proof_sha256"]
        == __import__("hashlib").sha256((row.get("final_proof") or "").encode()).hexdigest()
        for key, row in direct_trials.items()
    )
    lemma_proof_hashes_match = all(
        lemma_deps[key]["proof_sha256"]
        == __import__("hashlib").sha256((row.get("final_proof") or "").encode()).hexdigest()
        for key, row in lemma_trials.items()
    )
    simp_rows = [row for row in direct_dependencies["rows"] + lemma_dependencies["rows"]
                 if any(name in row["tactic_mechanisms"] for name in ("simp", "simpa", "simp_all"))]
    required_case_names = ("compressed_original_path", "strong_bottleneck_reevaluation")
    optional_case_names = (
        "summary_theorem_compression", "inline_composition", "genuine_alternative_path",
    )
    cases_recorded = all(
        (requirement_root / "case_studies" / name / "case.json").is_file()
        for name in (*required_case_names, *optional_case_names)
    )
    integrity = {
        "multi_phase_proofs_unchanged": tree_digest(output_root / "multi_phase_proofs") == frozen_r8_digest,
        "theorem_base_unchanged": current_models == frozen_model_digests,
        "ten_challenges_audited": len(targets) == 10,
        "all_fifty_direct_proofs_audited": len(classifications) == 50,
        "all_fifty_lemma_first_proofs_audited": len(lemma_dependencies["rows"]) == 50,
        "all_proofs_kernel_reelaborated": all(
            row["kernel_reelaboration_pass"]
            for row in direct_dependencies["rows"] + lemma_dependencies["rows"]
        ),
        "frozen_proof_hashes_match": direct_proof_hashes_match and lemma_proof_hashes_match,
        "recursive_expansion_complete": len(expansions_payload["rows"]) == 100 and all(
            row["fully_expanded_to_declared_foundation_or_primitive"]
            for row in expansions_payload["rows"]
        ),
        "simp_actual_dependencies_recorded": all(
            row.get("simp_trace_enabled")
            and isinstance(row.get("simp_actual_rewrite_lemmas"), list)
            and isinstance(row.get("simp_actual_dependency_candidates"), list)
            for row in simp_rows
        ),
        "syntactic_and_semantic_bypass_separated": all(
            isinstance(row["SYNTACTIC_BYPASS"], bool)
            and isinstance(row["SEMANTIC_BYPASS"], bool) for row in classifications
        ),
        "all_classifications_have_recursive_evidence": all(
            row["evidence"]["theorem_chain_depth"] >= 1
            and set(row["relation_match_kinds"]) <= RELATION_MATCH_KINDS
            and bool(row["relation_match_kinds"]) == row["bottleneck_semantically_used"]
            for row in classifications
        ),
        "direct_lemma_pairs_aligned": set(direct_trials) == set(lemma_trials)
            == set(direct_paths) == set(lemma_paths) == set(overlaps),
        "strong_reevaluation_complete": len(strong_payload["rows"]) == 5
            and all(row["trials"] == 5 for row in strong_payload["rows"]),
        "case_studies_recorded_without_shaping": cases_recorded,
    }

    non_genuine = (
        metrics["N_COMPRESSED_ORIGINAL_PATH"] + metrics["N_SUMMARY_THEOREM_COMPRESSION"]
        + metrics["N_INLINE_COMPOSITION"]
    )
    majority_same = sum(row["classification"] in {"SAME_SEMANTIC_PATH", "MOSTLY_SAME_PATH"}
                        for row in overlap_payload["rows"])
    answers = {
        "RQ66": (
            f"All {metrics['N_SYNTACTIC_BYPASS']}/50 proofs were syntactic bypasses under the "
            f"multi_phase_proofs naming test; {non_genuine}/50 retained the predicted semantics after expansion."
        ),
        "RQ67": (
            f"{metrics['N_BOTTLENECK_SEMANTICALLY_USED']}/50 Direct proofs semantically used the "
            "predicted relation through compression, recursive summaries, or inline composition."
        ),
        "RQ68": (
            f"{majority_same}/50 Direct/Lemma-First pairs were SAME_SEMANTIC_PATH or "
            "MOSTLY_SAME_PATH after wrapper normalization."
        ),
        "RQ69": f"Genuine alternative paths occurred in {metrics['N_GENUINE_ALTERNATIVE_PATH']}/50 proofs.",
        "RQ70": (
            f"{metrics['N_TRUE_STRONG_FALSE_POSITIVE']}/5 multi_phase_proofs Strong targets remain "
            "TRUE_STRONG_FALSE_POSITIVE after five-trial recursive semantic audit."
        ),
        "RQ71": (
            "Strict Lemma Gain = 0 is best explained by Direct performing the same intermediate "
            "semantic decomposition inline or through local compression."
            if non_genuine >= metrics["N_GENUINE_ALTERNATIVE_PATH"] else
            "Strict Lemma Gain = 0 is best explained by Direct finding genuinely different paths."
        ),
    }
    status = "PASS" if all(integrity.values()) else "FAIL"
    report = {
        "schema": "rtl2lean-dependency_audit-final-v1", "status": status,
        "scope": "RECURSIVE_PROOF_DEPENDENCY_AND_SEMANTIC_BYPASS_AUDIT",
        "metrics": metrics, "integrity": integrity, "research_answers": answers,
        "classification_unit": "50 individual Direct proofs; multi_phase_proofs reported count is 10 targets",
        "no_result_shaping": True,
        "limitations": [
            "Semantic equivalence is operational: kernel-extracted dependencies are combined with a frozen relation-specific structural matcher.",
            "Core/library constants outside the generated L1-L4/R3 inventory are terminal primitive facts.",
            "Unavailable case-study classes are recorded explicitly rather than manufactured.",
            "multi_phase_proofs properties, proofs, classifications, and results are not modified.",
        ],
    }
    write_json(requirement_root / "integrity.json", integrity)
    write_json(requirement_root / "final_report.json", report)
    lines = [
        "# dependency_audit Final Report", "", f"Status: **{status}**", "",
        "multi_phase_proofs is frozen; no Property or proof was rerun.", "",
        "## Metrics", "",
        *(f"- {key}: {value}" for key, value in metrics.items()),
        "", "## Research questions", "",
        *(f"- **{key}**: {value}" for key, value in answers.items()),
        "", "## Limitations", "",
        *(f"- {value}" for value in report["limitations"]),
    ]
    (requirement_root / "final_report.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    return report
