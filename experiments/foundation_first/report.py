"""foundation_first tables, metrics, case studies, and final reports."""
from __future__ import annotations

import csv
import json
from collections import Counter
from pathlib import Path
from typing import Any

from experiments.adaptive_proving.io import atomic_json, atomic_text, read_json, sha256_file


def load_results(run_dir: Path) -> list[dict[str, Any]]:
    return [read_json(path) for path in sorted((run_dir / "trials").glob("C*/trial_*/result.json"))]


def _rate(numerator: int, denominator: int) -> float | None:
    return numerator / denominator if denominator else None


def _csv(path: Path, rows: list[dict[str, Any]], fields: list[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    with temporary.open("w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=fields, extrasaction="ignore")
        writer.writeheader(); writer.writerows(rows)
    temporary.replace(path)


def _integrity(run_dir: Path) -> dict[str, Any]:
    hashes = {}
    for path in sorted(item for item in run_dir.rglob("*") if item.is_file()):
        if path.name in {"integrity.json", "state.json"}:
            continue
        hashes[str(path.relative_to(run_dir))] = sha256_file(path)
    return {"schema": "rtl2lean-foundation_first-integrity-v1", "artifact_count": len(hashes),
            "excluded_mutable_files": ["**/state.json", "integrity.json"], "sha256": hashes}


def build_report(run_dir: Path, tasks: list[dict[str, Any]]) -> dict[str, Any]:
    rows = load_results(run_dir)
    n = len(rows)
    foundation = sum(row["foundation_only_pass"] for row in rows)
    assisted = sum(row["llm_assisted_property_pass"] for row in rows)
    called = [row for row in rows if not row["foundation_only_pass"]]
    first = sum(row["first_candidate_kernel_pass"] for row in called)
    feedback = sum(row["feedback_candidate_kernel_pass"] for row in called)
    repair_cases = sum(any(a["operation"] == "REPAIR" for a in row["candidate_attempts"]) for row in called)
    redesign_cases = sum(any(a["operation"] == "REDESIGN" for a in row["candidate_attempts"]) for row in called)
    repaired = sum(row["repair_success"] for row in called)
    redesigned = sum(row["redesign_success"] for row in called)
    rescues = [row for row in rows if row["result_status"] == "PROPERTY_RESCUED_BY_LLM_LEMMA"]
    property_table = [{
        "challenge_id": row["challenge_id"], "task_id": row["task_id"], "dut": row["dut"],
        "foundation_only": "PASS" if row["foundation_only_pass"] else "FAIL",
        "llm_assisted": "PASS" if row["llm_assisted_property_pass"] else "FAIL",
        "result_status": row["result_status"], "model_calls": row["model_calls"],
        "candidate_count": row["candidate_count"],
        "verified_lemma_used": bool((row.get("property_rescue") or {}).get("verified_lemma_used_by_final")),
    } for row in rows]
    candidate_table = []
    diagnoses = []
    gap_types = Counter()
    for row in rows:
        if row.get("proof_gap"):
            gap_types[row["proof_gap"]["missing_relation_class"]] += 1
        for attempt in row["candidate_attempts"]:
            candidate = attempt["model_response"].get("candidate") or {}
            candidate_table.append({
                "challenge_id": row["challenge_id"], "call_index": attempt["call_index"],
                "operation": attempt["operation"], "lemma_name": candidate.get("lemma_name"),
                "kernel_pass": bool(attempt.get("kernel_result", {}).get("success")),
                "property_retry_pass": bool(attempt.get("property_retry", {}).get("success")),
                "failure_level": (attempt.get("diagnosis") or {}).get("failure_level"),
                "primary_cause": (attempt.get("diagnosis") or {}).get("primary_cause"),
            })
        diagnoses.extend(row["diagnoses"])
    diagnosis_levels = Counter(row["failure_level"] for row in diagnoses)
    diagnosis_causes = Counter(row["primary_cause"] for row in diagnoses)
    phase_stats = {}
    for phases in sorted({row["proof_gap"]["temporal_structure"]["along_occurrences"]
                          for row in called if row.get("proof_gap")}):
        selected = [row for row in called
                    if row["proof_gap"]["temporal_structure"]["along_occurrences"] == phases]
        phase_stats[str(phases)] = {
            "properties": len(selected),
            "properties_with_kernel_valid_candidate": sum(bool(row["verified_lemmas"]) for row in selected),
            "property_rescues": sum(row["result_status"] == "PROPERTY_RESCUED_BY_LLM_LEMMA"
                                    for row in selected),
            "model_calls": sum(row["model_calls"] for row in selected),
            "total_tokens": sum(row["usage"]["total_tokens"] for row in selected),
        }
    repair_attempts = sum(attempt["operation"] == "REPAIR" for row in called
                          for attempt in row["candidate_attempts"])
    redesign_attempts = sum(attempt["operation"] == "REDESIGN" for row in called
                            for attempt in row["candidate_attempts"])
    kernel_pass_attempts = sum(bool(attempt.get("kernel_result", {}).get("success")) for row in called
                               for attempt in row["candidate_attempts"])
    usage = {key: sum(row["usage"].get(key, 0) for row in rows) for key in
             ("input_tokens", "output_tokens", "total_tokens", "reasoning_tokens", "cached_tokens")}
    report = {
        "schema": "rtl2lean-foundation_first-final-report-v1",
        "status": "COMPLETE" if n == len(tasks) else "PARTIAL",
        "completed_properties": n, "expected_properties": len(tasks),
        "methods": {
            "Foundation-Only": {"passes": foundation, "total": n, "pass_rate": _rate(foundation, n)},
            "Foundation + LLM Lemma Discovery": {"passes": assisted, "total": n,
                                                   "pass_rate": _rate(assisted, n)},
        },
        "PROPERTY_RESCUED_BY_LLM_LEMMA": len(rescues),
        "first_candidate_kernel_pass": {"passes": first, "eligible": len(called), "rate": _rate(first, len(called))},
        "feedback_candidate_kernel_pass": {"passes": feedback, "eligible": len(called), "rate": _rate(feedback, len(called))},
        "repair_success": {"passes": repaired, "cases": repair_cases, "rate": _rate(repaired, repair_cases)},
        "redesign_success": {"passes": redesigned, "cases": redesign_cases, "rate": _rate(redesigned, redesign_cases)},
        "attempt_level": {
            "kernel_pass_attempts": kernel_pass_attempts,
            "repair_attempts": repair_attempts,
            "repair_kernel_passes": sum(
                attempt["operation"] == "REPAIR" and bool(attempt.get("kernel_result", {}).get("success"))
                for row in called for attempt in row["candidate_attempts"]),
            "redesign_attempts": redesign_attempts,
            "redesign_kernel_passes": sum(
                attempt["operation"] == "REDESIGN" and bool(attempt.get("kernel_result", {}).get("success"))
                for row in called for attempt in row["candidate_attempts"]),
        },
        "property_rescue_rate": _rate(len(rescues), len(called)),
        "candidates_per_property": _rate(sum(row["candidate_count"] for row in called), len(called)),
        "model_calls": sum(row["model_calls"] for row in rows), "usage": usage,
        "api_wall_time_s": sum(row["api_wall_time_s"] for row in rows),
        "verified_lemma_used_by_final_count": sum(
            bool((row.get("property_rescue") or {}).get("verified_lemma_used_by_final")) for row in rows),
        "existing_theorem_duplicate_count": sum(row["candidate_existing_theorem_duplicate"] for row in rows),
        "proof_gap_types": dict(sorted(gap_types.items())),
        "candidate_failure_levels": dict(sorted(diagnosis_levels.items())),
        "candidate_failure_causes": dict(sorted(diagnosis_causes.items())),
        "temporal_phase_statistics": phase_stats,
        "property_rows": property_table,
    }
    atomic_json(run_dir / "analysis" / "foundation_only_success.json", {
        "method": "Foundation-Only", "passes": foundation, "total": n,
        "rows": property_table,
    })
    atomic_json(run_dir / "analysis" / "llm_assisted_success.json", {
        "method": "Foundation + LLM Lemma Discovery", "passes": assisted, "total": n,
        "rows": property_table,
    })
    atomic_json(run_dir / "analysis" / "candidate_lemma_validation.json", {"rows": candidate_table})
    atomic_json(run_dir / "analysis" / "proof_gap_statistics.json", dict(gap_types))
    atomic_json(run_dir / "analysis" / "candidate_failure_diagnosis.json", {
        "levels": dict(diagnosis_levels), "causes": dict(diagnosis_causes)})
    atomic_json(run_dir / "analysis" / "repair_redesign_statistics.json", {
        "repair_cases": repair_cases, "repair_success": repaired,
        "redesign_cases": redesign_cases, "redesign_success": redesigned})
    atomic_json(run_dir / "analysis" / "property_rescue.json", {
        "count": len(rescues), "rows": [{"challenge_id": row["challenge_id"],
                                           "task_id": row["task_id"],
                                           **row["property_rescue"]} for row in rescues]})
    atomic_json(run_dir / "analysis" / "api_usage.json", {
        "calls": report["model_calls"], "usage": usage, "wall_time_s": report["api_wall_time_s"]})
    _csv(run_dir / "tables" / "foundation_and_assisted.csv", property_table,
         ["challenge_id", "task_id", "dut", "foundation_only", "llm_assisted", "result_status",
          "model_calls", "candidate_count", "verified_lemma_used"])
    _csv(run_dir / "tables" / "candidate_lemmas.csv", candidate_table,
         ["challenge_id", "call_index", "operation", "lemma_name", "kernel_pass",
          "property_retry_pass", "failure_level", "primary_cause"])
    for row in rescues:
        atomic_json(run_dir / "case_studies" / f"{row['challenge_id']}_rescue.json", {
            "challenge_id": row["challenge_id"], "task_id": row["task_id"],
            "proof_gap": row["proof_gap"], "candidate_attempts": row["candidate_attempts"],
            "diagnoses": row["diagnoses"], "property_rescue": row["property_rescue"],
        })
    atomic_json(run_dir / "final_report.json", report)
    lines = "\n".join(
        f"| {row['challenge_id']} | {row['dut']} | {row['foundation_only']} | {row['llm_assisted']} | {row['result_status']} |"
        for row in property_table
    ) or "| — | — | — | — | no completed properties |"
    markdown = f"""# foundation_first Final Report

Status: `{report['status']}` ({n}/{len(tasks)} properties completed).

| Method | Property PASS |
|---|---:|
| Foundation-Only | {foundation} / {n} |
| Foundation + LLM Lemma Discovery | {assisted} / {n} |

`PROPERTY_RESCUED_BY_LLM_LEMMA = {len(rescues)}`

## Property Results

| Challenge | DUT | Foundation | Assisted | Result |
|---|---|---:|---:|---|
{lines}

## Candidate and Feedback Metrics

- First Candidate kernel PASS: {first}/{len(called)}
- Feedback Candidate kernel PASS: {feedback}/{len(called)}
- REPAIR success: {repaired}/{repair_cases}
- REDESIGN success: {redesigned}/{redesign_cases}
- Verified lemma actually used by final proof: {report['verified_lemma_used_by_final_count']}
- Existing-theorem duplicate candidates: {report['existing_theorem_duplicate_count']}
- API calls/tokens/wall time: {report['model_calls']} / {usage['total_tokens']} / {report['api_wall_time_s']:.3f}s
- Temporal phase statistics: `{json.dumps(phase_stats, ensure_ascii=False, sort_keys=True)}`

## Fixed Observation Statistics

- Proof-gap classes: `{json.dumps(dict(gap_types), ensure_ascii=False, sort_keys=True)}`
- Candidate failure levels: `{json.dumps(dict(diagnosis_levels), ensure_ascii=False, sort_keys=True)}`
- Candidate failure causes: `{json.dumps(dict(diagnosis_causes), ensure_ascii=False, sort_keys=True)}`
"""
    atomic_text(run_dir / "final_report.md", markdown)
    atomic_json(run_dir / "integrity.json", _integrity(run_dir))
    return report
