#!/usr/bin/env python3
"""Fail-closed consistency audit for a completed design_suite run."""
from __future__ import annotations

import argparse
import json
from collections import Counter
from pathlib import Path


def read(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("run_dir", type=Path)
    args = parser.parse_args(); root = args.run_dir.resolve()
    report = read(root / "final_report.json")
    corpus = read(root / "manifests/tasks.json")
    results = read(root / "runs/all_results.json")
    security = read(root / "security_scan.json")
    errors = []
    expected_counts = {"aes": 30, "picorv32": 27, "modexp": 24, "serv": 21,
                       "ethmac": 29, "zipcpu": 26, "dma_axi": 20}
    expected_total = sum(expected_counts.values())
    if len(corpus["tasks"]) != expected_total or len(results) != expected_total:
        errors.append(f"expected {expected_total} frozen tasks and results")
    ids = [t["task_id"] for t in corpus["tasks"]]
    if len(ids) != len(set(ids)) or set(ids) != {r["task_id"] for r in results}:
        errors.append("task identity mismatch")
    for result in results:
        if not result["success"] or not result["final_kernel_pass"]:
            errors.append(f"unproved result: {result['task_id']}")
        if not result["causal_deletion_failure"]:
            errors.append(f"deletion ablation did not fail: {result['task_id']}")
        if result["successful_iteration"] not in range(1, 6):
            errors.append(f"iteration out of budget: {result['task_id']}")
        if result["cross_dut_reuse"]:
            errors.append(f"cross-DUT reuse present: {result['task_id']}")
    calls = [a for r in results for a in r["attempts"] if a.get("api_call")]
    tokens = sum(r["usage"]["total_tokens"] for r in results)
    if len(calls) != report["physical_api_calls"] or tokens != report["total_tokens"]:
        errors.append("API/token aggregation mismatch")
    if Counter(t["dut"] for t in corpus["tasks"]) != Counter(expected_counts):
        errors.append("per-DUT corpus count mismatch")
    if security["status"] != "PASS" or report["adaptation"]["status"] != "PASS":
        errors.append("security or adaptation gate failed")
    for dut in report["per_dut"]:
        for name in ["inventory.json", "R16Pool.lean", "R16Support.lean"]:
            if not (root / "pools" / dut / name).is_file():
                errors.append(f"missing pool snapshot: {dut}/{name}")
    audit = {"schema": "rtl2lean-design_suite-final-audit-v1",
        "status": "PASS" if not errors else "FAIL", "errors": errors,
        "task_count": len(results), "kernel_successes": sum(r["success"] for r in results),
        "causal_deletion_failures": sum(r["causal_deletion_failure"] for r in results),
        "api_calls": len(calls), "total_tokens": tokens}
    target = root / "analysis/final_audit.json"
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(json.dumps(audit, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(audit["status"]); return 0 if not errors else 1


if __name__ == "__main__":
    raise SystemExit(main())
