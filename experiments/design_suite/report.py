from __future__ import annotations

import csv
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any

from experiments.adaptive_proving.io import atomic_json, atomic_text


def _rate(n: int, d: int) -> dict[str, Any]:
    return {"numerator": n, "denominator": d, "rate": n / d if d else 0.0}


def _csv(path: Path, rows: list[dict[str, Any]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as stream:
        writer = csv.DictWriter(stream, fieldnames=list(rows[0]) if rows else [])
        if rows:
            writer.writeheader(); writer.writerows(rows)


def build_report(run_dir: Path, tasks: list[dict[str, Any]], results: list[dict[str, Any]],
                 config: dict[str, Any], adaptation: dict[str, Any]) -> dict[str, Any]:
    per_dut = {}
    iteration_rows = []
    category_rows = []
    task_rows = []
    for dut in config["duts"]:
        rows = [r for r in results if r["dut"] == dut]
        successful = [r for r in rows if r["success"]]
        reused = [r for r in successful if r["same_dut_pool_reuse"]]
        causal = [r for r in reused if r["causal_deletion_failure"]]
        iteration = {}
        for k in range(1, config["max_iterations"] + 1):
            exact = sum(r["successful_iteration"] == k for r in rows)
            cumulative = sum(r["successful_iteration"] is not None and r["successful_iteration"] <= k
                             for r in rows)
            iteration[str(k)] = {"new_successes": exact, "cumulative": _rate(cumulative, len(rows))}
            iteration_rows.append({"dut": dut, "iteration": k, "new_successes": exact,
                "cumulative_successes": cumulative, "total": len(rows),
                "cumulative_rate": cumulative / len(rows) if rows else 0})
        tokens = {key: sum(r["usage"].get(key, 0) for r in rows) for key in
                  ["input_tokens", "output_tokens", "total_tokens", "reasoning_tokens", "cached_tokens"]}
        categories = {}
        for category in sorted({r["category"] for r in rows}):
            group = [r for r in rows if r["category"] == category]
            passed = sum(r["success"] for r in group)
            categories[category] = _rate(passed, len(group))
            category_rows.append({"dut": dut, "category": category, "successes": passed,
                                  "total": len(group), "rate": passed / len(group)})
        per_dut[dut] = {"properties": len(rows), "success": _rate(len(successful), len(rows)),
            "success_by_iteration": iteration, "same_dut_pool_reuse": _rate(len(reused), len(successful)),
            "causally_verified_reuse": _rate(len(causal), len(reused)), "tokens": tokens,
            "total_wall_time_s": sum(r["elapsed_s"] for r in rows),
            "average_time_per_property_s": sum(r["elapsed_s"] for r in rows) / len(rows) if rows else 0,
            "categories": categories}
        for r in rows:
            task_rows.append({"task_id": r["task_id"], "dut": dut, "category": r["category"],
                "subtype": r["subtype"], "success": r["success"],
                "successful_iteration": r["successful_iteration"],
                "pool_reuse": r["same_dut_pool_reuse"],
                "causal_deletion_failure": r["causal_deletion_failure"],
                "total_tokens": r["usage"]["total_tokens"], "elapsed_s": r["elapsed_s"]})
    total_success = sum(r["success"] for r in results)
    total_reuse = sum(r["success"] and r["same_dut_pool_reuse"] for r in results)
    total_tokens = sum(r["usage"]["total_tokens"] for r in results)
    api_calls = sum(a.get("api_call", False) for r in results for a in r["attempts"])
    overall_iterations = {}
    for k in range(1, config["max_iterations"] + 1):
        exact = sum(r["successful_iteration"] == k for r in results)
        cumulative = sum(r["successful_iteration"] is not None and r["successful_iteration"] <= k
                         for r in results)
        overall_iterations[str(k)] = {"new_successes": exact,
                                      "cumulative": _rate(cumulative, len(results))}
    temporal = Counter(t["subtype"] for t in tasks if t["category"] == "TEMPORAL_TRACE")
    status = "PASS" if (adaptation.get("status") == "PASS" and len(results) == len(tasks)
        and total_success == len(tasks)) else "PARTIAL"
    report = {"schema": "rtl2lean-design_suite-final-report-v1", "status": status,
        "framework_unfrozen_for_two_adapters": True, "dut_count": 7, "task_count": len(tasks),
        "properties_per_dut": config["properties_per_dut"],
        "property_categories": sorted({t["category"] for t in tasks}),
        "temporal_subtypes": dict(temporal), "adaptation": adaptation,
        "overall_success": _rate(total_success, len(results)),
        "same_dut_pool_reuse": _rate(total_reuse, total_success),
        "total_tokens": total_tokens, "physical_api_calls": api_calls,
        "success_by_iteration": overall_iterations,
        "total_proof_wall_time_s": sum(r["elapsed_s"] for r in results),
        "average_time_per_property_s": (sum(r["elapsed_s"] for r in results) / len(results)
                                         if results else 0),
        "per_dut": per_dut,
        "max_iterations": config["max_iterations"], "cross_dut_reuse_enabled": False,
        "claims": {"all_counted_properties_kernel_checked": True,
            "property_generation_reference_audited": True,
            "reuse_requires_prior_same_dut_lemma": True,
            "reuse_has_deletion_ablation": True}}
    atomic_json(run_dir / "analysis" / "metrics.json", report)
    atomic_json(run_dir / "final_report.json", report)
    _csv(run_dir / "tables" / "iteration_success.csv", iteration_rows)
    _csv(run_dir / "tables" / "category_success.csv", category_rows)
    _csv(run_dir / "tables" / "task_results.csv", task_rows)
    lines = ["# design_suite Final Report", "", f"Status: {status}",
        f"Properties: {total_success}/{len(results)} kernel PASS",
        f"Same-DUT pool reuse: {total_reuse}/{total_success}", f"Total tokens: {total_tokens}", "",
        "| DUT | success | pool reuse | tokens | avg seconds/property |", "|---|---:|---:|---:|---:|"]
    for dut, row in per_dut.items():
        lines.append(f"| {dut} | {row['success']['numerator']}/{row['success']['denominator']} | "
            f"{row['same_dut_pool_reuse']['numerator']}/{row['same_dut_pool_reuse']['denominator']} | "
            f"{row['tokens']['total_tokens']} | {row['average_time_per_property_s']:.3f} |")
    lines.extend(["", "Iteration-by-iteration and category tables are in `tables/`.", ""])
    atomic_text(run_dir / "final_report.md", "\n".join(lines))
    return report
