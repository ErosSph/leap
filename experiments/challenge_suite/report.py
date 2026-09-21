from __future__ import annotations

import csv
import json
from collections import Counter
from pathlib import Path
from typing import Any

from experiments.adaptive_proving.io import atomic_json, atomic_text


def _rate(n: int, d: int) -> dict[str, Any]:
    return {"numerator": n, "denominator": d, "rate": n / d if d else 0.0}


def build(run_dir: Path, tasks: list[dict[str, Any]], direct: list[dict[str, Any]],
          ablation: dict[str, Any], translation: dict[str, Any],
          req16: dict[str, Any], config: dict[str, Any]) -> dict[str, Any]:
    per_dut = {}
    for dut in config["duts"]:
        rows = [row for row in direct if row["dut"] == dut]
        success = sum(row["success"] for row in rows)
        per_dut[dut] = {"tasks": len(rows), "success": _rate(success, len(rows)),
            "api_calls": sum(len(row["attempts"]) for row in rows),
            "tokens": sum(row["usage"]["total_tokens"] for row in rows),
            "wall_time_s": sum(row["elapsed_s"] for row in rows),
            "average_time_per_property_s": sum(row["elapsed_s"] for row in rows) / len(rows)}
    success = sum(row["success"] for row in direct)
    calls = sum(len(row["attempts"]) for row in direct)
    tokens = sum(row["usage"]["total_tokens"] for row in direct)
    iterations = {str(k): {"new_successes": sum(row["success_iteration"] == k for row in direct),
        "cumulative": _rate(sum(row["success_iteration"] is not None and row["success_iteration"] <= k
                               for row in direct), len(direct))} for k in range(0, 6)}
    complete = len(direct) == 177 and all(row["success"] or row["iterations_used"] == 5
                                          for row in direct)
    execution_path = run_dir / "direct" / "execution.json"
    execution = json.loads(execution_path.read_text()) if execution_path.is_file() else {}
    failure_categories = Counter(category for row in direct for attempt in row["attempts"]
        if not attempt["success"] for category in attempt["feedback"]["categories"])
    category_results = {}
    for category in sorted({row["category"] for row in direct}):
        rows = [row for row in direct if row["category"] == category]
        category_results[category] = _rate(sum(row["success"] for row in rows), len(rows))
    graph = ablation["full_graph"]; flat = ablation["no_graph_flat"]
    causal_path = run_dir / "ablation/causal_deletion.json"
    causal = json.loads(causal_path.read_text()) if causal_path.is_file() else None
    repair_path = run_dir / "analysis/tpoh_repair.json"
    repair = json.loads(repair_path.read_text()) if repair_path.is_file() else None
    reuse_path = run_dir / "analysis/lemma_reuse.json"
    reuse = json.loads(reuse_path.read_text()) if reuse_path.is_file() else None
    normalization_path = run_dir / "translation/lean_ir_normalization.json"
    normalization = (json.loads(normalization_path.read_text())
                     if normalization_path.is_file() else None)
    report = {"schema": "rtl2lean-challenge_suite-final-report-v1",
        "status": "PASS" if complete else "INCOMPLETE",
        "experiment_complete": complete,
        "source_task_count": len(tasks), "same_frozen_tasks_across_challenge_suite_arms": True,
        "derived_from_frozen_design_suite_theorem_bases": True,
        "direct_baseline": {"success": _rate(success, len(direct)), "physical_api_calls": calls,
            "total_tokens": tokens, "total_wall_time_s": sum(row["elapsed_s"] for row in direct),
            "end_to_end_wall_time_s": execution.get("end_to_end_wall_s"),
            "workers": execution.get("workers", 1),
            "average_time_per_property_s": sum(row["elapsed_s"] for row in direct) / len(direct),
            "success_by_iteration": iterations, "per_dut": per_dut,
            "graph": False, "pool": False, "top_level_intermediate_lemma": False,
            "prompt_truncation": {name: config[name] for name in
                ["context_char_limit", "feedback_char_limit", "previous_proof_char_limit"]},
            "success_by_category": category_results,
            "failed_attempt_categories": dict(failure_categories)},
        "design_suite_historical_nonpaired": {"success": req16["overall_success"],
            "physical_api_calls": req16["physical_api_calls"], "total_tokens": req16["total_tokens"],
            "same_dut_pool_reuse": req16["same_dut_pool_reuse"],
            "average_time_per_property_s": req16["average_time_per_property_s"]},
        "graph_ablation": {key: value for key, value in ablation.items() if key != "rows"},
        "causal_core_deletion": {key: value for key, value in (causal or {}).items() if key != "rows"},
        "lemma_reuse": reuse,
        "posthoc_tpoh_repair": ({key: value for key, value in repair.items()
                                  if key != "dut_repairs"} if repair else None),
        "paired_comparison": {
            "full_graph_success_rate": graph["successes"] / graph["total"],
            "direct_success_rate": success / len(direct),
            "full_graph_minus_direct_percentage_points": 100 * (
                graph["successes"] / graph["total"] - success / len(direct)),
            "graph_api_call_reduction_vs_direct": 1 - graph["physical_api_calls"] / calls,
            "graph_token_reduction_vs_direct": 1 - graph["total_tokens"] / tokens,
            "cluster_level_core_success": {"full_graph": f"{graph['core_successes']}/7",
                                           "no_graph": f"{flat['core_successes']}/7"}},
        "translation_optimization": {key: value for key, value in translation.items() if key != "entries"},
        "translation_lean_ir_normalization": ({key: value for key, value in normalization.items()
                                                if key != "entries"}
                                               if normalization else None),
        "paper_alignment": {"arxiv": "2607.16855", "three_stages": [
            "RTL-to-Lean semantic compilation", "four-layer theorem generation",
            "autonomous proving with lemma reuse"]},
        "limitations": [
            "The graph/no-graph ablation changes prompt representation only; conclusions should not be generalized beyond this model and corpus.",
            "The 177 graph outcomes are clustered behind seven DUT-level core lemmas; the effective independent core sample is seven.",
            "Translation cold times are provenance-preserved original measurements; only cache lookup is newly timed.",
            "A cache improves repeated runs, not first-time translation of changed RTL or compiler semantics."]}
    atomic_json(run_dir / "analysis" / "metrics.json", report)
    atomic_json(run_dir / "final_report.json", report)
    lines = ["# challenge_suite Final Report", "", f"Status: {report['status']}",
        f"Frozen hard tasks: {len(tasks)}", f"Direct: {success}/{len(direct)}",
        f"TPOH lemma-first: {ablation['full_graph']['successes']}/{len(tasks)}",
        f"No-graph lemma-first: {ablation['no_graph_flat']['successes']}/{len(tasks)}",
        f"Direct API calls: {calls}", f"Direct tokens: {tokens}",
        f"Req16 lemma-first API calls: {req16['physical_api_calls']}", "",
        "| DUT | Direct success | API calls | tokens | avg s/property |", "|---|---:|---:|---:|---:|"]
    for dut, row in per_dut.items():
        lines.append(f"| {dut} | {row['success']['numerator']}/{row['tasks']} | {row['api_calls']} | "
                     f"{row['tokens']} | {row['average_time_per_property_s']:.3f} |")
    lines += ["", "The no-graph ablation retains lemma-first, the kernel gate, and the same-DUT pool; "
        "it is not the Direct baseline.", ""]
    if repair and reuse:
        before = reuse["before_repair"]; after = reuse["after_posthoc_repair"]
        lines += ["## Post-hoc TPOH repair and lemma reuse", "",
            f"Frozen TPOH result: {repair['before']['target_successes']}/{repair['before']['target_total']}",
            f"Post-hoc structural repair: {repair['after']['target_successes']}/{repair['after']['target_total']}",
            f"Available unique core lemmas: {before['available_unique_kernel_verified_lemmas']} -> "
            f"{after['available_unique_kernel_verified_lemmas']}",
            f"Actually-used / causal events: {before['actually_used_kernel_success_events']}/"
            f"{before['causally_required_events']} -> {after['actually_used_kernel_success_events']}/"
            f"{after['causally_required_events']}",
            f"Repeated uses excluding first consumer: "
            f"{before['repeated_cross_target_uses_excluding_first_consumer']} -> "
            f"{after['repeated_cross_target_uses_excluding_first_consumer']}", "",
            "The repair is post-hoc and is reported separately from the frozen comparison.", ""]
    if normalization:
        aggregate = normalization["aggregate"]
        lines += ["## RTL-to-Lean translation optimization", "",
            "Optimization: Lean-oriented IR normalization plus phase-invariant schedule handoff.",
            f"Generated Lean byte reduction: {aggregate['model_byte_reduction']} "
            f"({100 * aggregate['model_byte_reduction_rate']:.3f}%).",
            f"Avoided redundant schedule validation: "
            f"{aggregate['redundant_schedule_validation_s_avoided']:.3f}s.",
            f"Kernel-validated DUTs: {normalization['kernel_validated_duts']}/"
            f"{normalization['duts']}; resource-capped: {normalization['resource_capped_duts']}.", ""]
    atomic_text(run_dir / "final_report.md", "\n".join(lines))
    table = run_dir / "tables" / "direct_results.csv"; table.parent.mkdir(parents=True, exist_ok=True)
    with table.open("w", newline="", encoding="utf-8") as stream:
        writer = csv.DictWriter(stream, fieldnames=["task_id", "dut", "category", "subtype",
            "success", "success_iteration", "iterations_used", "tokens", "elapsed_s"])
        writer.writeheader()
        for row in direct:
            writer.writerow({"task_id": row["task_id"], "dut": row["dut"],
                "category": row["category"], "subtype": row["subtype"], "success": row["success"],
                "success_iteration": row["success_iteration"], "iterations_used": row["iterations_used"],
                "tokens": row["usage"]["total_tokens"], "elapsed_s": row["elapsed_s"]})
    return report
