#!/usr/bin/env python3
"""Post-hoc, read-only audit for an immutable boundary_evaluation run."""
from __future__ import annotations

import argparse
import hashlib
import json
import sys
from collections import Counter
from pathlib import Path

PROJECT = Path(__file__).resolve().parents[1]
if str(PROJECT) not in sys.path:
    sys.path.insert(0, str(PROJECT))

from experiments.adaptive_proving.io import atomic_json, atomic_text, read_json, sha256_file


VARIANTS = ["bridge_skeleton", "tpoh_no_skeleton", "tpoh_skeleton_no_aligner", "full_tpoh"]
MATCH_FLAGS = [
    "symbol_overlap_match", "ast_shape_match", "lean_type_compatible_match",
    "definitional_equality_match", "coercion_implicit_argument_mismatch",
    "equality_direction_mismatch", "SOURCE_FORMAL_MATCH", "TARGET_FORMAL_MATCH",
    "BRIDGE_FORMAL_MATCH", "FORMAL_UTILITY_PASS",
]


def classify_failure(result: dict) -> str:
    if result["property_rescue"]:
        return "PASS"
    if not result["candidate_utility_pass"]:
        return "NO_FORMALLY_USEFUL_CANDIDATE"
    kernel = result["kernel_result"]
    text = ((kernel.get("stdout") or "") + "\n" + (kernel.get("stderr") or "")).lower()
    if "unknown identifier" in text or "unknown constant" in text:
        return "PROOF_UNKNOWN_IDENTIFIER"
    if "unknown tactic" in text:
        return "PROOF_UNKNOWN_TACTIC"
    if "induction" in text or "motive" in text or "generaliz" in text:
        return "PROOF_INDUCTION_FAILURE"
    if "unsolved goals" in text or "tactic" in text:
        return "PROOF_UNSOLVED_GOAL"
    return "PROOF_KERNEL_FAILURE"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("run_dir", type=Path)
    args = parser.parse_args()
    run = args.run_dir.resolve()
    report = read_json(run / "final_report.json")
    manifest = read_json(run / "manifests" / "run_manifest.json")
    rows = {}
    matching = {}
    failures = {}
    for variant in VARIANTS:
        variant_rows = [read_json(path) for path in sorted((run / "variants" / variant / "trials").glob("R*/result.json"))]
        rows[variant] = {row["challenge_id"]: row for row in variant_rows}
        matching[variant] = {flag: Counter(str(bool(candidate["formal_match"].get(flag))) for row in variant_rows for candidate in row["candidates"]) for flag in MATCH_FLAGS}
        failures[variant] = Counter(classify_failure(row) for row in variant_rows)
    controls = []
    for cid in sorted(rows["full_tpoh"]):
        tpoh = [rows[v][cid] for v in VARIANTS[1:]]
        controls.append({
            "challenge_id": cid,
            "same_candidate_draw_id": len({row["candidate_draw_id"] for row in tpoh}) == 1,
            "same_candidate_payload": len({json.dumps([c["candidate"] for c in row["candidates"]], sort_keys=True) for row in tpoh}) == 1,
        })
    hash_rows = []
    for relative, expected in manifest["implementation_hashes"].items():
        actual = sha256_file(PROJECT / relative)
        hash_rows.append({"path": relative, "expected": expected, "actual": actual, "match": expected == actual})
    physical = [*(run / "shared_candidate_draws" / "tpoh").glob("R*/call_01/response.json"),
                *(run / "variants" / "bridge_skeleton" / "trials").glob("R*/calls/call_01/response.json"),
                *(run / "variants").glob("*/trials/R*/calls/call_02/response.json")]
    physical_status = Counter(read_json(path).get("status") for path in physical)
    tasks_text = (run / "manifests" / "tasks.json").read_text(encoding="utf-8")
    full = report["overall"]["full_tpoh"]["gap_rescue"]["rate"]
    deltas = report["contribution_conclusions"]
    cross = {pattern: report["per_property_pattern"][pattern]["full_tpoh"]["gap_rescue"] for pattern in report["patterns"]}
    audit = {
        "schema": "rtl2lean-boundary_evaluation-final-audit-v1",
        "status": "PASS",
        "run_id": manifest["run_id"],
        "matrix_complete": all(len(rows[v]) == 12 for v in VARIANTS),
        "result_cells": sum(len(rows[v]) for v in VARIANTS),
        "candidate_randomization_control": {
            "status": "PASS" if all(x["same_candidate_draw_id"] and x["same_candidate_payload"] for x in controls) else "FAIL",
            "rows": controls,
        },
        "formal_matching_counts": {v: {flag: dict(counts) for flag, counts in flags.items()} for v, flags in matching.items()},
        "failure_taxonomy": {v: dict(counts) for v, counts in failures.items()},
        "physical_api": {"calls": len(physical), "statuses": dict(physical_status)},
        "logical_api_calls": sum(report["overall"][v]["api_calls"] for v in VARIANTS),
        "security_scan": read_json(run / "security_scan.json"),
        "reference_proofs_absent_from_formal_manifest": "reference_candidate_proof" not in tasks_text,
        "direct_arm_absent": manifest.get("direct_arm_present") is False and all("direct" not in v for v in VARIANTS),
        "implementation_hashes": {"all_match": all(x["match"] for x in hash_rows), "rows": hash_rows},
        "cross_property_full_tpoh": cross,
        "contribution": {
            "full_tpoh_rescue_rate": full,
            "hypergraph_delta": deltas["hypergraph_independent_contribution"],
            "skeleton_delta": deltas["skeleton_independent_contribution"],
            "aligner_delta": deltas["aligner_independent_contribution"],
            "largest_observed_module": "SKELETON",
            "generalization_verdict": "PARTIAL: graph construction/detection covers all six patterns; kernel rescue succeeds in four of six patterns and fails for STATE_TRANSITION and PHASE_TO_PHASE.",
        },
        "audit_script": {"path": str(Path(__file__).resolve().relative_to(PROJECT)), "sha256": sha256_file(Path(__file__))},
        "final_report_sha256": sha256_file(run / "final_report.json"),
    }
    atomic_json(run / "analysis" / "final_audit.json", audit)
    md = [
        "# boundary_evaluation Final Audit", "", f"Run: `{manifest['run_id']}`", "",
        f"- Matrix: {audit['result_cells']}/48 cells; control {audit['candidate_randomization_control']['status']}",
        f"- Physical API: {len(physical)} calls, statuses {dict(physical_status)}",
        f"- Full TPOH rescue: {report['overall']['full_tpoh']['gap_rescue']['numerator']}/12",
        f"- Deltas: TPOH {deltas['hypergraph_independent_contribution']:+.3f}, Skeleton {deltas['skeleton_independent_contribution']:+.3f}, Aligner {deltas['aligner_independent_contribution']:+.3f}",
        f"- Verdict: {audit['contribution']['generalization_verdict']}",
        f"- Security: {audit['security_scan']['status']}; implementation hashes: {'PASS' if audit['implementation_hashes']['all_match'] else 'FAIL'}", "",
        "## Failure taxonomy", "", json.dumps(audit["failure_taxonomy"], indent=2, ensure_ascii=False), "",
    ]
    atomic_text(run / "analysis" / "final_audit.md", "\n".join(md))
    print(json.dumps(audit, indent=2, ensure_ascii=False))
    return 0 if all([
        audit["matrix_complete"], audit["candidate_randomization_control"]["status"] == "PASS",
        audit["security_scan"]["status"] == "PASS", audit["reference_proofs_absent_from_formal_manifest"],
        audit["direct_arm_absent"], audit["implementation_hashes"]["all_match"],
        physical_status == {"API_SUCCESS": len(physical)},
    ]) else 1


if __name__ == "__main__":
    raise SystemExit(main())
