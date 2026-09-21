#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

from experiments.adaptive_proving.io import sha256_file


def read(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("run_dir", type=Path)
    args = parser.parse_args()
    run = args.run_dir.resolve()
    report = read(run / "final_report.json")
    manifest = read(run / "manifests" / "run_manifest.json")
    tasks = read(run / "manifests" / "tasks.json")
    security = read(run / "security_scan.json")
    problems = []
    if len(tasks["tasks"]) != 10 or len({row["dut"] for row in tasks["tasks"]}) != 5:
        problems.append("formal unseen corpus is not 10 tasks / 5 DUTs")
    if any("reference_candidate_proof" in row for row in tasks["tasks"]):
        problems.append("reference proof leaked into formal manifest")
    if manifest.get("direct_arm_present") or report.get("direct_arm_present"):
        problems.append("direct arm is present")
    if manifest.get("phase_to_phase_present"):
        problems.append("Phase-to-Phase is present")
    if security.get("status") != "PASS":
        problems.append("security scan failed")
    project = Path(__file__).resolve().parents[1]
    for relative, expected in manifest.get("implementation_hashes", {}).items():
        path = project / relative
        if not path.is_file() or sha256_file(path) != expected:
            problems.append("implementation hash mismatch: " + relative)
    all_results = sorted((run / "variants").glob("*/trials/*/result.json"))
    if len(all_results) != 20:
        problems.append(f"expected 20 result cells, found {len(all_results)}")
    rows = [read(path) for path in all_results]
    by_task = {}
    for row in rows:
        by_task.setdefault(row["challenge_id"], []).append(row)
    if any(len(group) != 2 or len({row["candidate_draw_id"] for row in group}) != 1
           for group in by_task.values()):
        problems.append("paired arms do not share candidate draw")
    full = [row for row in rows if row["variant"] == "full_req15"]
    if report.get("framework_complete"):
        if len(full) != 10 or not all(row["property_rescue"] for row in full):
            problems.append("framework-complete claim lacks 10/10 kernel rescue")
        if not all(row["verified_lemma_used_by_final"] for row in full):
            problems.append("delete-lemma replay does not prove actual lemma use")
        if not all(row["typed_theorem_binding_success"] for row in full
                   if row["property_pattern"] == "STATE_TRANSITION"):
            problems.append("one State binding failed")
        if not all(row["typed_witness_acceptance"] and row["witness_obligation_kernel_pass"]
                   for row in full if row["property_pattern"] == "WITNESS_CONSTRUCTION"):
            problems.append("one Witness schema stage failed")
    secret_pattern = re.compile(rb"sk-[A-Za-z0-9_.-]{20,}")
    leaked = [str(path.relative_to(run)) for path in run.rglob("*")
              if path.is_file() and path.name != "security_scan.json" and secret_pattern.search(path.read_bytes())]
    if leaked:
        problems.append("credential-like string persisted: " + ", ".join(leaked))
    audit = {"schema": "rtl2lean-scale_evaluation-final-audit-v1",
        "status": "PASS" if not problems else "FAIL", "problems": problems,
        "result_cells": len(rows), "full_kernel_rescue": sum(row["property_rescue"] for row in full),
        "framework_complete": report.get("framework_complete")}
    target = run / "analysis" / "final_audit.json"
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(json.dumps(audit, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(json.dumps(audit, indent=2, ensure_ascii=False))
    return 0 if not problems else 1


if __name__ == "__main__":
    raise SystemExit(main())
