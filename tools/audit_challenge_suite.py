#!/usr/bin/env python3
import argparse
import json
from collections import Counter
from pathlib import Path


def read(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def main() -> int:
    parser = argparse.ArgumentParser(); parser.add_argument("run_dir", type=Path)
    root = parser.parse_args().run_dir.resolve()
    report = read(root / "final_report.json")
    tasks = read(root / "manifests/tasks.json")["tasks"]
    direct = read(root / "direct/all_results.json")
    ablation = read(root / "ablation/graph_ablation.json")
    cache = read(root / "translation/cache_benchmark.json")
    property_audit = read(root / "analysis/property_audit.json")
    causal = read(root / "ablation/causal_deletion.json")
    repair = read(root / "analysis/tpoh_repair.json")
    reuse = read(root / "analysis/lemma_reuse.json")
    normalization = read(root / "translation/lean_ir_normalization.json")
    security = read(root / "security_scan.json")
    errors = []
    if len(tasks) != 177 or len(direct) != 177:
        errors.append("not the frozen 177-task corpus")
    if property_audit.get("kernel_pass") != 177 or not all(
            t.get("dependency_count", 0) >= 4 and t.get("minimum_dependency_hops", 0) >= 3
            for t in tasks):
        errors.append("hard corpus/reference audit gate failed")
    if Counter(t["task_id"] for t in tasks) != Counter(r["task_id"] for r in direct):
        errors.append("task identity mismatch")
    for row in direct:
        if row["iterations_used"] > 5 or row["lemma_pool_enabled"] or row["graph_enabled"]:
            errors.append(f"invalid Direct policy: {row['task_id']}")
        if not row["success"] and row["iterations_used"] != 5:
            errors.append(f"unsolved Direct task did not exhaust five attempts: {row['task_id']}")
        if row["success"] and not (row["baseline_kernel"]["success"] or any(
                attempt["kernel"]["success"] for attempt in row["attempts"])):
            errors.append(f"success without kernel evidence: {row['task_id']}")
    if ablation["task_count"] != 177 or not ablation["no_graph_is_not_direct"]:
        errors.append("invalid graph ablation")
    if (causal["checked"] != ablation["full_graph"]["successes"] or
            not causal["all_successful_graph_targets_causally_depend_on_core"]):
        errors.append("causal core-deletion audit failed")
    if not cache["repeat_translation_accelerated"] or cache["first_time_translation_accelerated"]:
        errors.append("translation cache claim is malformed")
    if (repair["before"]["target_successes"] != 151 or
            repair["after"]["target_successes"] != 177 or not repair["post_hoc"] or
            sum(row["causally_required_targets"] for row in repair["dut_repairs"]) != 26):
        errors.append("post-hoc TPOH repair evidence failed")
    before_reuse = reuse["before_repair"]
    after_reuse = reuse["after_posthoc_repair"]
    if (before_reuse["available_unique_kernel_verified_lemmas"] != 6 or
            before_reuse["actually_used_kernel_success_events"] != 151 or
            before_reuse["causally_required_events"] != 151 or
            after_reuse["available_unique_kernel_verified_lemmas"] != 7 or
            after_reuse["actually_used_kernel_success_events"] != 177 or
            after_reuse["causally_required_events"] != 177):
        errors.append("lemma reuse funnel is inconsistent")
    if (normalization["duts"] != 7 or normalization["kernel_validated_duts"] != 5 or
            not normalization["all_executed_models_kernel_pass"] or
            not normalization["all_executed_regenerated_l1_l4_frameworks_kernel_pass"] or
            normalization["aggregate"]["model_byte_reduction"] <= 0 or
            normalization["aggregate"]["redundant_schedule_validation_s_avoided"] <= 0):
        errors.append("Lean-oriented translation optimization audit failed")
    if security["status"] != "PASS":
        errors.append("security scan failed")
    audit = {"schema": "rtl2lean-challenge_suite-final-audit-v1",
        "status": "PASS" if not errors else "FAIL", "errors": errors,
        "tasks": len(direct), "direct_kernel_successes": sum(r["success"] for r in direct),
        "direct_api_calls": sum(len(r["attempts"]) for r in direct),
        "direct_tokens": sum(r["usage"]["total_tokens"] for r in direct),
        "tpoh_before": repair["before"]["target_successes"],
        "tpoh_after_posthoc_repair": repair["after"]["target_successes"],
        "lemma_reuse_causal_events_after_repair": after_reuse["causally_required_events"],
        "translation_kernel_validated_duts": normalization["kernel_validated_duts"]}
    target = root / "analysis/final_audit.json"; target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(json.dumps(audit, indent=2) + "\n", encoding="utf-8")
    print(audit["status"]); return 0 if not errors else 1


if __name__ == "__main__":
    raise SystemExit(main())
