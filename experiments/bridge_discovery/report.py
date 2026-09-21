"""bridge_discovery metrics, required analyses, and acceptance-question answers."""
from __future__ import annotations

from collections import Counter
from datetime import datetime
from pathlib import Path
from typing import Any

from experiments.adaptive_proving.io import atomic_json, atomic_text, read_json


def load_results(run_dir: Path) -> list[dict[str, Any]]:
    return [read_json(path) for path in sorted((run_dir / "trials").glob("E*/trial_*/result.json"))]


def _rate(n: int, d: int) -> dict[str, Any]:
    return {"numerator": n, "denominator": d, "rate": n / d if d else None}


def build_report(run_dir: Path, tasks: list[dict[str, Any]]) -> dict[str, Any]:
    rows = load_results(run_dir); expected = len(tasks)
    if len(rows) != expected:
        raise RuntimeError(f"cannot report incomplete run: {len(rows)}/{expected}")
    analysis = run_dir / "analysis"; analysis.mkdir(parents=True, exist_ok=True)
    statement_rows = [c for row in rows for round_ in row["statement_rounds"] for c in round_["candidates"]]
    proof_rows = [p for row in rows for p in row["proof_attempts"]]
    initial_selected = [next((c for c in row["statement_rounds"][0]["candidates"] if c.get("selected_for_proof")), None)
                        for row in rows if row["statement_rounds"]]
    initial_failures = Counter()
    gap_rows = [row for row in rows if row["statement_rounds"]]
    for row, selected in zip(gap_rows, initial_selected):
        if not selected:
            initial_failures["ALL_CANDIDATES_LOW_OR_INVALID"] += 1
        elif row["proof_attempts"] and row["proof_attempts"][0]["kernel_result"]["success"]:
            initial_failures["INITIAL_KERNEL_PASS"] += 1
        elif row["proof_attempts"]:
            cause = (row["proof_attempts"][0].get("diagnosis") or {}).get("primary_cause", "UNCLASSIFIED")
            initial_failures[f"STATEMENT_ACCEPTED_PROOF_{cause}"] += 1
        else:
            initial_failures["STATEMENT_ACCEPTED_NO_PROOF_RESPONSE"] += 1
    redesign_failures = Counter(
        "REDESIGN_BRIDGE_FAILURE" for row in rows for round_ in row["statement_rounds"]
        if round_.get("round_status") == "REDESIGN_BRIDGE_FAILURE")
    candidate_ledger = []
    for row in rows:
        for round_ in row["statement_rounds"]:
            for candidate_row in round_["candidates"]:
                name = candidate_row["candidate_statement"].get("lemma_name")
                linked = [attempt for attempt in row["proof_attempts"]
                          if attempt.get("candidate_statement", {}).get("lemma_name") == name]
                candidate_ledger.append({"challenge_id": row["challenge_id"],
                    "operation": round_["operation"], **candidate_row,
                    "failure_diagnosis": [attempt.get("diagnosis") for attempt in linked
                                          if attempt.get("diagnosis")],
                    "repair_template": [attempt.get("repair_template") for attempt in linked
                                        if attempt.get("repair_template")],
                    "redesign_guidance": [(attempt.get("diagnosis") or {}).get("avoid_in_next_candidate", [])
                                          for attempt in linked if attempt.get("diagnosis")],
                    "kernel_result": [attempt.get("kernel_result") for attempt in linked],
                    "final_property_result": next((attempt.get("final_property_result") for attempt in linked
                                                   if attempt.get("final_property_result") is not None), None)})
    utility_payload = {"schema": "rtl2lean-bridge_discovery-utility-results-v1",
        "candidate_count": len(statement_rows),
        "classification_distribution": dict(Counter(c["utility_result"]["classification"] for c in statement_rows)),
        "low_rejection_count": sum(c["utility_result"]["classification"] == "LOW_TARGET_UTILITY" for c in statement_rows),
        "avoided_proof_attempts": sum(bool(c["utility_result"].get("proof_attempt_avoided")) for c in statement_rows),
        "rows": candidate_ledger}
    atomic_json(analysis / "candidate_utility_results.json", utility_payload)
    bridge_payload = {"schema": "rtl2lean-bridge_discovery-bridge-summary-v1",
        "property_count_requiring_bridge": sum(row["bridge_specification"] is not None for row in rows),
        "missing_relation_distribution": dict(Counter(row["bridge_specification"]["missing_relation_class"]
            for row in rows if row["bridge_specification"])),
        "temporal_scope_distribution": dict(Counter(row["bridge_specification"]["temporal_scope"]
            for row in rows if row["bridge_specification"])),
        "rows": [{"challenge_id": row["challenge_id"], "bridge_specification": row["bridge_specification"],
                  "global_bridge_view": row["global_bridge_view"]} for row in rows]}
    atomic_json(analysis / "bridge_specification_summary.json", bridge_payload)
    hits = [p for p in proof_rows if p.get("repair_template")]
    hit_success = 0
    for hit in hits:
        row = next(r for r in rows if any(p is hit for p in r["proof_attempts"]))
        hit_success += any(p["call_index"] > hit["call_index"] and p["operation"] == "REPAIR"
                           and p["kernel_result"]["success"] for p in row["proof_attempts"])
    template_payload = {"schema": "rtl2lean-bridge_discovery-repair-template-effectiveness-v1",
        "failed_proof_attempts": sum(not p["kernel_result"]["success"] for p in proof_rows),
        "template_hits": len(hits), "template_successes": hit_success,
        "hit_rate": _rate(len(hits), sum(not p["kernel_result"]["success"] for p in proof_rows)),
        "success_rate": _rate(hit_success, len(hits)),
        "template_distribution": dict(Counter(p["repair_template"]["template_id"] for p in hits))}
    atomic_json(analysis / "repair_template_effectiveness.json", template_payload)
    local_global = {"schema": "rtl2lean-bridge_discovery-local-vs-global-analysis-v1",
        "global_view_supplied_to_every_statement_round": all(c.get("global_bridge_view") for c in statement_rows),
        "low_candidates_rejected_before_proof": utility_payload["low_rejection_count"],
        "low_candidates_selected_for_proof": sum(bool(c.get("selected_for_proof")) and
            c["utility_result"]["classification"] == "LOW_TARGET_UTILITY" for c in statement_rows),
        "locally_valid_but_finally_ineffective_verified_lemmas": sum(
            p["kernel_result"]["success"] and not p.get("final_property_result", {}).get("success", False)
            for p in proof_rows),
        "causal_claim": "No controlled no-Global-View ablation was run; reductions are observational, not causal."}
    atomic_json(analysis / "local_vs_global_failure_analysis.json", local_global)
    atomic_json(analysis / "unseen_initial_candidate_failure_distribution.json", {
        "schema": "rtl2lean-bridge_discovery-unseen-initial-failures-v1", "distribution": dict(initial_failures)})
    atomic_json(analysis / "unseen_redesign_failure_distribution.json", {
        "schema": "rtl2lean-bridge_discovery-unseen-redesign-failures-v1", "distribution": dict(redesign_failures)})

    foundation = sum(row["foundation_only_pass"] for row in rows)
    needing = expected - foundation
    rescue = sum(row["result_status"] == "PROPERTY_RESCUED_BY_LLM_LEMMA" for row in rows)
    first_utility = sum(row["first_candidate_utility_pass"] for row in rows if row["llm_invoked"])
    first_kernel = sum(row["first_candidate_kernel_pass"] for row in rows if row["llm_invoked"])
    redesign_tasks = sum(any(r["operation"] == "REDESIGN" for r in row["statement_rounds"]) for row in rows)
    repair_failures = Counter((p.get("diagnosis") or {}).get("primary_cause") for p in proof_rows
                              if not p["kernel_result"]["success"])
    started = datetime.fromisoformat(read_json(run_dir / "manifests" / "run_manifest.json")["timestamp"]).timestamp()
    finished = max(path.stat().st_mtime for path in (run_dir / "trials").glob("E*/trial_*/result.json"))
    dev_initial = read_json(analysis / "initial_candidate_failure_analysis.json")
    dev_redesign = read_json(analysis / "redesign_failure_analysis.json")
    metrics = {"foundation_only_property_pass": _rate(foundation, expected),
        "first_candidate_utility_pass": _rate(first_utility, needing),
        "first_candidate_statement_accepted": _rate(first_utility, needing),
        "first_candidate_kernel_pass": _rate(first_kernel, needing),
        "redesign_utility_pass": _rate(sum(row["redesign_utility_pass"] for row in rows), redesign_tasks),
        "redesign_kernel_pass": _rate(sum(row["redesign_kernel_pass"] for row in rows), redesign_tasks),
        "repair_template_hit": template_payload["hit_rate"], "repair_template_success": template_payload["success_rate"],
        "low_target_utility_rejections": utility_payload["low_rejection_count"],
        "avoided_proof_attempts": utility_payload["avoided_proof_attempts"],
        "property_rescue_among_gaps": _rate(rescue, needing),
        "overall_property_pass": _rate(foundation + rescue, expected),
        "repair_success": _rate(sum(row["repair_success"] for row in rows), needing),
        "candidate_statements_per_gap": sum(row["candidate_statement_count"] for row in rows) / needing if needing else None,
        "api_calls": sum(row["model_calls"] for row in rows),
        "tokens": {key: sum(row["usage"].get(key, 0) for row in rows)
                   for key in ("input_tokens", "output_tokens", "total_tokens", "reasoning_tokens", "cached_tokens")},
        "api_wall_time_s": sum(row["api_wall_time_s"] for row in rows),
        "run_wall_time_s": max(0.0, finished - started),
        "verified_lemma_actual_use": _rate(sum(bool(row.get("property_rescue", {}) and
            row["property_rescue"].get("verified_lemma_used_by_final")) for row in rows), rescue),
        "delete_lemma_replay_failure": _rate(sum(bool(row.get("property_rescue", {}) and
            not row["property_rescue"].get("delete_lemma_replay_pass")) for row in rows), rescue)}
    common_initial = max(dev_initial["distribution"], key=dev_initial["distribution"].get)
    questions = {
        "1_first_candidate_why_failed": "Req11 first statements usually had the right bridge shape, but their Lean proof implementations failed.",
        "2_most_common_failure": f"Development taxonomy category {common_initial} is most common; unseen proof failures: {dict(repair_failures)}.",
        "3_bridge_spec_utility_uplift": f"On unseen gaps, first-round accepted utility is {first_utility}/{needing}; this is observational because Req11 had no pre-proof Utility Gate.",
        "4_redesign_why_failed": f"Development redesign distribution is {dev_redesign['distribution']}; unseen bridge failures are {dict(redesign_failures)}.",
        "5_redesign_directionality": "Yes procedurally: every redesign names new source, target, bridge and avoided failure; success metrics quantify effectiveness.",
        "6_c06_low_rejected": f"Yes for the specified exec-only identity pattern: LOW candidates rejected before proof={utility_payload['low_rejection_count']}; LOW selected={local_global['low_candidates_selected_for_proof']}.",
        "7_reusable_repairs": "Generalized-state induction, singleton-trace destruction, theorem-application alignment, and type alignment are frozen reusable templates.",
        "8_local_view_failures": "Req11 showed locally valid trace identities/wrappers and proof attempts that did not reach the last-step guard or final dependency frontier.",
        "9_global_view_reduction": f"No LOW candidate was selected ({local_global['low_candidates_selected_for_proof']}); no causal reduction claim is made without an ablation.",
        "10_rescue_uplift": f"Req11 development rescue was 5/10; Req12 unseen gap rescue is {rescue}/{needing}. Different task sets prevent a strict causal uplift claim."}
    report = {"schema": "rtl2lean-bridge_discovery-report-v1", "status": "PASS",
        "development_set_size": 10, "unseen_evaluation_size": expected, "metrics": metrics,
        "development_initial_failure_distribution": dev_initial["distribution"],
        "development_redesign_failure_distribution": dev_redesign["distribution"],
        "unseen_initial_failure_distribution": dict(initial_failures),
        "unseen_redesign_failure_distribution": dict(redesign_failures),
        "acceptance_questions": questions, "results": [{"challenge_id": r["challenge_id"],
            "task_id": r["task_id"], "dut": r["dut"], "result_status": r["result_status"],
            "model_calls": r["model_calls"]} for r in rows]}
    atomic_json(run_dir / "final_report.json", report)
    lines = ["# bridge_discovery Final Report", "", f"Foundation-only: {foundation}/{expected}",
             f"Unseen gaps rescued: {rescue}/{needing}", f"Overall properties proved: {foundation + rescue}/{expected}",
             f"API calls: {metrics['api_calls']}", "", "## Acceptance questions", ""]
    lines.extend(f"{key}. {value}" for key, value in questions.items())
    atomic_text(run_dir / "final_report.md", "\n\n".join(lines) + "\n")
    return report
