"""scale_evaluation metrics, acceptance answers, and framework-freeze decision."""
from __future__ import annotations

import csv
from collections import Counter
from pathlib import Path
from typing import Any

from experiments.adaptive_proving.io import atomic_json, atomic_text, read_json, sha256_file


def _rate(numerator: int, denominator: int) -> dict[str, Any]:
    return {"numerator": numerator, "denominator": denominator,
            "rate": numerator / denominator if denominator else None}


def _load(run_dir: Path, variant: str) -> list[dict[str, Any]]:
    return [read_json(path) for path in sorted((run_dir / "variants" / variant / "trials").glob("*/result.json"))]


def _metrics(rows: list[dict[str, Any]]) -> dict[str, Any]:
    count = len(rows)
    state = [row for row in rows if row["property_pattern"] == "STATE_TRANSITION"]
    witness = [row for row in rows if row["property_pattern"] == "WITNESS_CONSTRUCTION"]
    return {"tasks": count,
        "tpoh_graph_construction": _rate(sum(row["tpoh_graph_construction"] for row in rows), count),
        "missing_hyperedge_detection": _rate(sum(row["missing_hyperedge_detection"] for row in rows), count),
        "candidate_utility_pass": _rate(sum(row["candidate_utility_pass"] for row in rows), count),
        "schema_selection": _rate(sum(row["schema_selection_success"] for row in rows), count),
        "skeleton_generation": _rate(sum(row["skeleton_generation_success"] for row in rows), count),
        "first_kernel_pass": _rate(sum(row["first_kernel_pass"] for row in rows), count),
        "kernel_pass_after_repair": _rate(sum(row["kernel_pass_after_repair"] for row in rows), count),
        "property_rescue": _rate(sum(row["property_rescue"] for row in rows), count),
        "verified_lemma_use": _rate(sum(row["verified_lemma_used_by_final"] for row in rows), count),
        "state_transition": {"typed_theorem_binding_success": _rate(sum(
            row["typed_theorem_binding_success"] for row in state), len(state)),
            "namespace_mismatch": sum(row["namespace_mismatch"] for row in state),
            "implicit_argument_mismatch": sum(row["implicit_argument_mismatch"] for row in state),
            "theorem_application_mismatch": sum(row["theorem_application_mismatch"] for row in state),
            "state_field_alignment_failure": sum(row["state_field_alignment_failure"] for row in state)},
        "witness": {"witness_proposal_success": _rate(sum(row["witness_proposal_success"] for row in witness), len(witness)),
            "typed_witness_acceptance": _rate(sum(row["typed_witness_acceptance"] for row in witness), len(witness)),
            "refine_skeleton_success": _rate(sum(row["refine_skeleton_success"] for row in witness), len(witness)),
            "witness_obligation_kernel_pass": _rate(sum(row["witness_obligation_kernel_pass"] for row in witness), len(witness))},
        "api_calls": sum(row["proof_attempts"] for row in rows),
        "api_failures": sum(status != "API_SUCCESS" for row in rows for status in row["api_statuses"]),
        "tokens": {key: sum(row["usage"][key] for row in rows)
                   for key in ["input_tokens", "output_tokens", "total_tokens", "cached_tokens"]},
        "api_wall_time_s": sum(row["api_wall_time_s"] for row in rows),
        "total_variant_wall_time_s": sum(row["variant_wall_time_s"] for row in rows),
        "failure_categories": dict(Counter(category for row in rows if not row["property_rescue"]
            for category in row["failure_diagnosis"]["categories"]))}


def _csv(path: Path, rows: list[dict[str, Any]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as stream:
        writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
        writer.writeheader(); writer.writerows(rows)


def build_report(project: Path, run_dir: Path, tasks: list[dict[str, Any]],
                 variants: list[str], req14_run: str) -> dict[str, Any]:
    rows = {variant: _load(run_dir, variant) for variant in variants}
    if any(len(group) != len(tasks) for group in rows.values()):
        raise RuntimeError("incomplete scale_evaluation result matrix")
    overall = {variant: _metrics(group) for variant, group in rows.items()}
    per_pattern = {pattern: {variant: _metrics([row for row in group if row["property_pattern"] == pattern])
        for variant, group in rows.items()} for pattern in ["STATE_TRANSITION", "WITNESS_CONSTRUCTION"]}
    full = overall["full_req15"]
    control = overall["legacy_untyped_control"]
    state_full = per_pattern["STATE_TRANSITION"]["full_req15"]
    state_control = per_pattern["STATE_TRANSITION"]["legacy_untyped_control"]
    witness_full = per_pattern["WITNESS_CONSTRUCTION"]["full_req15"]
    witness_control = per_pattern["WITNESS_CONSTRUCTION"]["legacy_untyped_control"]
    req14_report_path = project / req14_run / "final_report.json"
    req14 = read_json(req14_report_path)
    prior_full = req14["per_property_pattern"]
    prior_support = {pattern: prior_full[pattern]["full_tpoh"]["gap_rescue"]
                     for pattern in ["TEMPORAL_LIFT", "REWRITE_CHAIN", "CASE_ANALYSIS"]}
    stable_state = state_full["property_rescue"]["numerator"] == 5
    stable_witness = witness_full["property_rescue"]["numerator"] == 5
    prior_stable = all(value["numerator"] == value["denominator"] for value in prior_support.values())
    framework_complete = stable_state and stable_witness and prior_stable
    answers = {
        "1_typed_binding_resolves_state_failure": {"answer": stable_state and
            state_full["state_transition"]["typed_theorem_binding_success"]["numerator"] == 5,
            "full_rescue": state_full["property_rescue"], "legacy_rescue": state_control["property_rescue"],
            "full_binding": state_full["state_transition"]["typed_theorem_binding_success"]},
        "2_state_schema_kernel_stable": {"answer": stable_state,
            "first_kernel_pass": state_full["first_kernel_pass"],
            "pass_after_repair": state_full["kernel_pass_after_repair"]},
        "3_witness_split_stable": {"answer": stable_witness,
            "typed_witness": witness_full["witness"]["typed_witness_acceptance"],
            "obligation_kernel_pass": witness_full["witness"]["witness_obligation_kernel_pass"]},
        "4_witness_schema_more_reliable_than_free_generation": {"answer":
            witness_full["property_rescue"]["rate"] > witness_control["property_rescue"]["rate"],
            "schema_rescue": witness_full["property_rescue"], "free_lemma_proof_rescue": witness_control["property_rescue"]},
        "5_one_tpoh_supports_five_patterns": {"answer": framework_complete,
            "prior_req14": prior_support, "req15_state": state_full["property_rescue"],
            "req15_witness": witness_full["property_rescue"]},
        "6_unseen_generalization": {"answer": stable_state and stable_witness,
            "unseen_tasks": len(tasks), "duts": len({task["dut"] for task in tasks}),
            "historical_overlap": 0}}
    candidate_files = sorted((run_dir / "shared_candidate_draws").glob("*/result.json"))
    candidates = [read_json(path) for path in candidate_files]
    shared_metrics = {"physical_api_calls": sum(len(row["calls"]) for row in candidates),
        "candidate_repair_calls": sum(row["candidate_repair_used"] for row in candidates),
        "candidate_utility_pass": _rate(sum(row["candidate_utility_pass"] for row in candidates), len(candidates)),
        "tokens": {key: sum(row["usage"][key] for row in candidates)
                   for key in ["input_tokens", "output_tokens", "total_tokens", "cached_tokens"]},
        "api_wall_time_s": sum(row["api_wall_time_s"] for row in candidates)}
    report = {"schema": "rtl2lean-scale_evaluation-final-report-v1",
        "status": "PASS" if framework_complete else "FRAMEWORK_NOT_YET_COMPLETE",
        "framework_complete": framework_complete, "framework_frozen": framework_complete,
        "task_count": len(tasks), "duts": sorted({task["dut"] for task in tasks}),
        "patterns": ["STATE_TRANSITION", "WITNESS_CONSTRUCTION"], "direct_arm_present": False,
        "overall": overall, "per_pattern": per_pattern, "shared_candidate_generation": shared_metrics,
        "acceptance_answers": answers, "req14_report_sha256": sha256_file(req14_report_path)}
    analysis = run_dir / "analysis"
    atomic_json(analysis / "metrics.json", {"overall": overall, "per_pattern": per_pattern,
                                             "shared_candidate_generation": shared_metrics})
    atomic_json(analysis / "acceptance_answers.json", answers)
    atomic_json(analysis / "framework_freeze.json", {"framework_complete": framework_complete,
        "framework_frozen": framework_complete, "conditions": {"state_5_of_5": stable_state,
            "witness_5_of_5": stable_witness, "prior_temporal_rewrite_case_all_pass": prior_stable},
        "frozen_components": ["TPOH", "Node / Hyperedge taxonomy", "Proof Frontier",
            "Missing Hyperedge Detection", "Graph Utility", "Proof Schema Library",
            "Typed Theorem Binding", "Lean Skeleton Generation", "Repair / Diagnosis policy"]
            if framework_complete else []})
    task_rows = []
    indexed = {variant: {row["challenge_id"]: row for row in group} for variant, group in rows.items()}
    for task in tasks:
        cid = task["challenge_id"]
        task_rows.append({"challenge_id": cid, "dut": task["dut"], "pattern": task["property_pattern"],
            "legacy_rescue": indexed["legacy_untyped_control"][cid]["property_rescue"],
            "full_rescue": indexed["full_req15"][cid]["property_rescue"],
            "full_first_kernel": indexed["full_req15"][cid]["first_kernel_pass"],
            "full_after_repair": indexed["full_req15"][cid]["kernel_pass_after_repair"]})
    _csv(run_dir / "tables" / "task_results.csv", task_rows)
    pattern_rows = []
    for pattern, variants_data in per_pattern.items():
        for variant, metrics in variants_data.items():
            pattern_rows.append({"pattern": pattern, "variant": variant,
                "candidate_utility": f"{metrics['candidate_utility_pass']['numerator']}/{metrics['candidate_utility_pass']['denominator']}",
                "schema_selection": f"{metrics['schema_selection']['numerator']}/{metrics['schema_selection']['denominator']}",
                "first_kernel": f"{metrics['first_kernel_pass']['numerator']}/{metrics['first_kernel_pass']['denominator']}",
                "repair_pass": f"{metrics['kernel_pass_after_repair']['numerator']}/{metrics['kernel_pass_after_repair']['denominator']}",
                "rescue": f"{metrics['property_rescue']['numerator']}/{metrics['property_rescue']['denominator']}"})
    _csv(run_dir / "tables" / "pattern_results.csv", pattern_rows)
    atomic_json(run_dir / "final_report.json", report)
    lines = ["# scale_evaluation Final Report", "", f"Status: {report['status']}",
        f"Framework complete/frozen: {framework_complete}", "", "## Paired results", ""]
    for pattern in ["STATE_TRANSITION", "WITNESS_CONSTRUCTION"]:
        lines.append(f"- {pattern}: legacy {per_pattern[pattern]['legacy_untyped_control']['property_rescue']['numerator']}/5; "
            f"full {per_pattern[pattern]['full_req15']['property_rescue']['numerator']}/5")
    lines.extend(["", "## Acceptance answers", "", str(answers), ""])
    atomic_text(run_dir / "final_report.md", "\n".join(lines))
    return report
