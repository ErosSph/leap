"""Automatic adaptive_proving metrics, tables, case studies, and integrity audit."""
from __future__ import annotations

import csv
import json
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any

from .io import atomic_json, atomic_text, read_json, sha256_file


ADAPTIVE = "diagnosis_guided_adaptive_lemma_first"


def _csv(path: Path, rows: list[dict[str, Any]], fields: list[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    with temporary.open("w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=fields, extrasaction="ignore")
        writer.writeheader()
        writer.writerows(rows)
    temporary.replace(path)


def load_results(run_dir: Path) -> list[dict[str, Any]]:
    rows = []
    for phase in ("phaseA", "phaseB"):
        for arm in ("direct", "adaptive_lemma_first"):
            for path in sorted((run_dir / phase / arm).glob("C*/trial_*/result.json")):
                row = read_json(path)
                if not row.get("completed"):
                    raise RuntimeError(f"incomplete result stored as completed artifact: {path}")
                rows.append(row)
    return sorted(rows, key=lambda row: (row["trial_id"], row["challenge_id"], row["strategy"]))


def paired_results(rows: list[dict[str, Any]], checkpoints: list[int]) -> list[dict[str, Any]]:
    grouped: dict[tuple[str, int], dict[str, dict[str, Any]]] = defaultdict(dict)
    for row in rows:
        grouped[(row["challenge_id"], row["trial_id"])][row["strategy"]] = row
    pairs = []
    for (challenge_id, trial_id), arms in sorted(grouped.items(), key=lambda item: (item[0][1], item[0][0])):
        if set(arms) != {"direct", ADAPTIVE}:
            continue
        direct, adaptive = arms["direct"], arms[ADAPTIVE]
        checkpoint_pairs = {}
        for checkpoint in checkpoints:
            dpass = direct["success_by_checkpoint"][str(checkpoint)]
            apass = adaptive["success_by_checkpoint"][str(checkpoint)]
            checkpoint_pairs[str(checkpoint)] = (
                "BOTH_PASS" if dpass and apass else
                "DIRECT_PASS_ADAPTIVE_FAIL" if dpass else
                "DIRECT_FAIL_ADAPTIVE_PASS" if apass else "BOTH_FAIL"
            )
        mechanism = "—"
        verified = adaptive.get("verified_intermediate_lemma")
        if adaptive.get("final_pass") and verified:
            mechanism = verified.get("verified_after_action", "GENERATE")
        elif adaptive.get("diagnoses"):
            mechanism = "→".join(row["recommended_action"] for row in adaptive["diagnoses"])
        strict = bool(
            not direct["final_pass"] and adaptive["final_pass"]
            and adaptive.get("intermediate_lemma_kernel_pass")
            and adaptive.get("intermediate_lemma_used_by_final")
        )
        guided = bool(strict and adaptive.get("diagnosis_count", 0) > 0)
        pairs.append({
            "challenge_id": challenge_id,
            "task_id": direct["task_id"],
            "dut": direct["dut"],
            "trial_id": trial_id,
            "direct": "PASS" if direct["final_pass"] else "FAIL",
            "adaptive": "PASS" if adaptive["final_pass"] else "FAIL",
            "paired_result": checkpoint_pairs[str(checkpoints[-1])],
            "paired_result_by_checkpoint": checkpoint_pairs,
            "adaptive_mechanism": mechanism,
            "strict_decomposition_rescue": strict,
            "diagnosis_guided_rescue": guided,
        })
    return pairs


def evaluate_phase_b_trigger(rows: list[dict[str, Any]], config: dict[str, Any]) -> dict[str, Any]:
    phase_a = [row for row in rows if row["phase"] == "phaseA"]
    pairs = paired_results(phase_a, config["checkpoints"])
    counts = Counter(row["paired_result_by_checkpoint"]["10"] for row in pairs)
    direct_success = sum(row["strategy"] == "direct" and row["final_pass"] for row in phase_a)
    adaptive_success = sum(row["strategy"] == ADAPTIVE and row["final_pass"] for row in phase_a)
    policy = config["phase_b_trigger"]
    criterion_a = counts["DIRECT_FAIL_ADAPTIVE_PASS"] >= policy["direct_fail_adaptive_pass"]
    criterion_b = adaptive_success >= direct_success + policy["adaptive_success_advantage"]
    return {
        "schema": "rtl2lean-adaptive_proving-phase-b-trigger-v1",
        "pre_registered_policy": policy,
        "checkpoint": 10,
        "phase_a_complete_pairs": len(pairs),
        "direct_fail_adaptive_pass": counts["DIRECT_FAIL_ADAPTIVE_PASS"],
        "direct_success_challenges": direct_success,
        "adaptive_success_challenges": adaptive_success,
        "criterion_a": criterion_a,
        "criterion_b": criterion_b,
        "pilot_signal": criterion_a or criterion_b,
        "evaluated_after_phase_a_only": True,
        "policy_modified_after_results": False,
    }


def _checkpoint_rows(rows: list[dict[str, Any]], checkpoints: list[int]) -> list[dict[str, Any]]:
    output = []
    for strategy in ("direct", ADAPTIVE):
        selected = [row for row in rows if row["strategy"] == strategy]
        for checkpoint in checkpoints:
            successes = sum(row["success_by_checkpoint"][str(checkpoint)] for row in selected)
            output.append({
                "strategy": strategy,
                "checkpoint": checkpoint,
                "successes": successes,
                "trials": len(selected),
                "success_rate": successes / len(selected) if selected else None,
            })
    return output


def _diagnosis_analysis(rows: list[dict[str, Any]]) -> tuple[list[dict[str, Any]], dict[str, Any]]:
    diagnosis_rows = []
    for trial in rows:
        if trial["strategy"] != ADAPTIVE:
            continue
        attempts = trial["attempts"]
        for index, diagnosis in enumerate(trial.get("diagnoses", []), 1):
            # The stored report's proof_attempt_number is a stable index into lemma attempts.
            lemma_attempts = [row for row in attempts if row["stage"] == "LEMMA"]
            source_index = int(diagnosis.get("proof_attempt_number") or index) - 1
            next_attempt = lemma_attempts[source_index + 1] if source_index + 1 < len(lemma_attempts) else None
            action = diagnosis["recommended_action"]
            immediate_pass = bool(
                next_attempt and next_attempt["operation"] == action
                and next_attempt.get("lean_result", {}).get("success")
            )
            diagnosis_rows.append({
                "challenge_id": trial["challenge_id"],
                "task_id": trial["task_id"],
                "trial_id": trial["trial_id"],
                "diagnosis_index": index,
                "failure_level": diagnosis["failure_level"],
                "primary_cause": diagnosis["primary_cause"],
                "recommended_action": action,
                "eventually_pass": trial["final_pass"],
                "next_action_pass": immediate_pass,
                "avoided_invalid_repair": diagnosis.get("avoided_invalid_repair", False),
            })
    decisions = []
    for action in ("REPAIR", "REDESIGN", "UNKNOWN"):
        selected = [row for row in diagnosis_rows if row["recommended_action"] == action]
        passed = sum(row["eventually_pass"] for row in selected)
        decisions.append({
            "decision": action, "cases": len(selected), "eventually_pass": passed,
            "success_rate": passed / len(selected) if selected else None,
            "next_action_pass": sum(row["next_action_pass"] for row in selected),
            "next_action_pass_rate": (
                sum(row["next_action_pass"] for row in selected) / len(selected) if selected else None
            ),
        })
    effectiveness = {
        "schema": "rtl2lean-adaptive_proving-diagnosis-effectiveness-v1",
        "decisions": decisions,
        "diagnosis_repair_pass": sum(
            row["recommended_action"] == "REPAIR" and row["next_action_pass"] for row in diagnosis_rows
        ),
        "diagnosis_redesign_pass": sum(
            row["recommended_action"] == "REDESIGN" and row["next_action_pass"] for row in diagnosis_rows
        ),
        "diagnosis1_repair_diagnosis2_redesign": sum(
            trial.get("diagnosis1_repair_diagnosis2_redesign", False) for trial in rows
        ),
        "avoided_invalid_repairs": sum(row["avoided_invalid_repair"] for row in diagnosis_rows),
    }
    return diagnosis_rows, effectiveness


def _failure_modes(diagnosis_rows: list[dict[str, Any]]) -> dict[str, Any]:
    levels = Counter(row["failure_level"] for row in diagnosis_rows)
    causes = Counter(row["primary_cause"] for row in diagnosis_rows)
    return {
        "schema": "rtl2lean-adaptive_proving-failure-modes-v1",
        "Proof-Level Failures": levels["PROOF"],
        "Statement-Level Failures": levels["STATEMENT"],
        "Selection-Level Failures": levels["SELECTION"],
        "Unknown Failures": levels["UNKNOWN"],
        "failure_levels": dict(sorted(levels.items())),
        "primary_causes": dict(sorted(causes.items())),
    }


def _cause_rows(diagnosis_rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
    output = []
    for cause in sorted({row["primary_cause"] for row in diagnosis_rows}):
        selected = [row for row in diagnosis_rows if row["primary_cause"] == cause]
        output.append({
            "failure_cause": cause,
            "count": len(selected),
            "repair": sum(row["recommended_action"] == "REPAIR" for row in selected),
            "redesign": sum(row["recommended_action"] == "REDESIGN" for row in selected),
            "eventually_pass": sum(row["eventually_pass"] for row in selected),
        })
    return output


def _case_studies(run_dir: Path, rows: list[dict[str, Any]], pairs: list[dict[str, Any]], tasks: list[dict[str, Any]]) -> list[dict[str, Any]]:
    task_map = {row["challenge_id"]: row for row in tasks}
    trial_map = {(row["challenge_id"], row["trial_id"], row["strategy"]): row for row in rows}
    categories: dict[str, tuple[str, int] | None] = {
        "direct_fail_adaptive_pass": None,
        "diagnosis_repair_pass": None,
        "diagnosis_redesign_pass": None,
        "repair_then_redesign": None,
        "diagnosis_unknown_failure": None,
    }
    for pair in pairs:
        key = (pair["challenge_id"], pair["trial_id"])
        adaptive = trial_map[key + (ADAPTIVE,)]
        if pair["paired_result"] == "DIRECT_FAIL_ADAPTIVE_PASS":
            categories["direct_fail_adaptive_pass"] = categories["direct_fail_adaptive_pass"] or key
        verified = adaptive.get("verified_intermediate_lemma") or {}
        if adaptive["final_pass"] and verified.get("verified_after_action") == "REPAIR":
            categories["diagnosis_repair_pass"] = categories["diagnosis_repair_pass"] or key
        if adaptive["final_pass"] and verified.get("verified_after_action") == "REDESIGN":
            categories["diagnosis_redesign_pass"] = categories["diagnosis_redesign_pass"] or key
        if adaptive.get("diagnosis1_repair_diagnosis2_redesign"):
            categories["repair_then_redesign"] = categories["repair_then_redesign"] or key
        if not adaptive["final_pass"] and any(
            row["recommended_action"] == "UNKNOWN" for row in adaptive.get("diagnoses", [])
        ):
            categories["diagnosis_unknown_failure"] = categories["diagnosis_unknown_failure"] or key
    saved = []
    for category, key in categories.items():
        if key is None:
            continue
        direct = trial_map[key + ("direct",)]
        adaptive = trial_map[key + (ADAPTIVE,)]
        task = task_map[key[0]]
        payload = {
            "schema": "rtl2lean-adaptive_proving-case-study-v1",
            "category": category,
            "challenge_id": key[0], "trial_id": key[1],
            "target": {"name": task["task_id"], "statement": task["statement"]},
            "candidate_lemma": adaptive.get("verified_intermediate_lemma"),
            "proof_attempts": adaptive["attempts"],
            "lean_errors": [
                (str(row.get("lean_result", {}).get("stdout") or "")
                 + str(row.get("lean_result", {}).get("stderr") or ""))[-16000:]
                for row in adaptive["attempts"] if not row.get("lean_result", {}).get("success")
            ],
            "proof_states": [row.get("lean_result", {}).get("proof_state", "") for row in adaptive["attempts"]],
            "diagnosis_reports": adaptive.get("diagnoses", []),
            "repair_guidance": [d["repair_guidance"] for d in adaptive.get("diagnoses", [])],
            "redesign_guidance": [d["redesign_guidance"] for d in adaptive.get("diagnoses", [])],
            "final_lemma": adaptive.get("verified_intermediate_lemma"),
            "final_proof": next((
                row["model_response"]["candidate"]["proof_body"] for row in adaptive["attempts"]
                if row["stage"] == "TARGET" and row.get("lean_result", {}).get("success")
            ), None),
            "lean_result": adaptive["final_target_lean_result"],
            "direct_result": direct["final_target_lean_result"],
        }
        path = run_dir / "case_studies" / f"{category}.json"
        atomic_json(path, payload)
        saved.append({"category": category, "path": str(path.relative_to(run_dir)), **key_to_dict(key)})
    return saved


def key_to_dict(key: tuple[str, int]) -> dict[str, Any]:
    return {"challenge_id": key[0], "trial_id": key[1]}


def _integrity(run_dir: Path) -> dict[str, Any]:
    hashes = {}
    for path in sorted(candidate for candidate in run_dir.rglob("*") if candidate.is_file()):
        if path.name == "integrity.json" or path.name == "state.json":
            continue
        hashes[str(path.relative_to(run_dir))] = sha256_file(path)
    return {
        "schema": "rtl2lean-adaptive_proving-integrity-v1",
        "scope": "all immutable manifests, completed trials, analyses, tables, cases, and reports",
        "excluded_mutable_files": ["**/state.json", "integrity.json"],
        "artifact_count": len(hashes),
        "sha256": hashes,
    }


def build_report(run_dir: Path, config: dict[str, Any], tasks: list[dict[str, Any]]) -> dict[str, Any]:
    rows = load_results(run_dir)
    pairs = paired_results(rows, config["checkpoints"])
    checkpoints = _checkpoint_rows(rows, config["checkpoints"])
    diagnosis_rows, effectiveness = _diagnosis_analysis(rows)
    failures = _failure_modes(diagnosis_rows)
    causes = _cause_rows(diagnosis_rows)
    trigger_path = run_dir / "analysis" / "phase_b_trigger.json"
    trigger = read_json(trigger_path) if trigger_path.is_file() else evaluate_phase_b_trigger(rows, config)
    strict = [row for row in pairs if row["strict_decomposition_rescue"]]
    guided = [row for row in pairs if row["diagnosis_guided_rescue"]]

    atomic_json(run_dir / "analysis" / "checkpoint_success.json", {
        "schema": "rtl2lean-adaptive_proving-checkpoints-v1", "rows": checkpoints,
    })
    atomic_json(run_dir / "analysis" / "paired_results.json", {
        "schema": "rtl2lean-adaptive_proving-paired-v1", "rows": pairs,
    })
    atomic_json(run_dir / "analysis" / "decomposition_rescue.json", {
        "schema": "rtl2lean-adaptive_proving-strict-rescue-v1", "count": len(strict), "rows": strict,
    })
    atomic_json(run_dir / "analysis" / "diagnosis_guided_rescue.json", {
        "schema": "rtl2lean-adaptive_proving-guided-rescue-v1", "count": len(guided), "rows": guided,
    })
    atomic_json(run_dir / "analysis" / "diagnosis_effectiveness.json", effectiveness)
    atomic_json(run_dir / "analysis" / "failure_modes.json", failures)
    atomic_json(run_dir / "diagnosis" / "diagnosis_summary.json", {
        "schema": "rtl2lean-adaptive_proving-diagnosis-summary-v1",
        "diagnosis_count": len(diagnosis_rows), "causes": causes, "effectiveness": effectiveness,
    })

    _csv(run_dir / "tables" / "checkpoint_results.csv", checkpoints,
         ["strategy", "checkpoint", "successes", "trials", "success_rate"])
    pair_table = [{
        "challenge": row["challenge_id"], "trial": row["trial_id"],
        "direct": row["direct"], "adaptive": row["adaptive"],
        "paired_result": row["paired_result"], "adaptive_mechanism": row["adaptive_mechanism"],
    } for row in pairs]
    _csv(run_dir / "tables" / "paired_results.csv", pair_table,
         ["challenge", "trial", "direct", "adaptive", "paired_result", "adaptive_mechanism"])
    _csv(run_dir / "tables" / "diagnosis_results.csv", causes,
         ["failure_cause", "count", "repair", "redesign", "eventually_pass"])
    three = [row for row in checkpoints if len([x for x in rows if x["strategy"] == row["strategy"]]) == 30]
    _csv(run_dir / "tables" / "three_trial_results.csv", three,
         ["strategy", "checkpoint", "successes", "trials", "success_rate"])
    cases = _case_studies(run_dir, rows, pairs, tasks)

    strategies = {}
    for strategy in ("direct", ADAPTIVE):
        selected = [row for row in rows if row["strategy"] == strategy]
        successes = sum(row["final_pass"] for row in selected)
        strategies[strategy] = {
            "successes": successes, "trials": len(selected),
            "success_rate": successes / len(selected) if selected else None,
            "checkpoint_successes": {
                str(cp): sum(row["success_by_checkpoint"][str(cp)] for row in selected)
                for cp in config["checkpoints"]
            },
            "model_calls": sum(row["model_calls"] for row in selected),
            "tokens": sum(row["usage"]["total_tokens"] for row in selected),
            "wall_time_s": sum(row["wall_time_s"] for row in selected),
        }
    phase_b_ran = any(row["phase"] == "phaseB" for row in rows)
    expected = 60 if trigger.get("pilot_signal") else 20
    report = {
        "schema": "rtl2lean-adaptive_proving-final-report-v1",
        "status": "COMPLETE" if len(rows) == expected else "PARTIAL",
        "phase_b_triggered": bool(trigger.get("pilot_signal")),
        "phase_b_ran": phase_b_ran,
        "completed_trials": len(rows), "expected_trials": expected,
        "strategies": strategies,
        "paired_counts_at_10": dict(Counter(row["paired_result"] for row in pairs)),
        "diagnosis_count": len(diagnosis_rows),
        "diagnosis_effectiveness": effectiveness,
        "failure_modes": failures,
        "strict_decomposition_rescues": len(strict),
        "diagnosis_guided_rescues": len(guided),
        "case_studies": cases,
        "operational_failures": sum(row["status"] == "OPERATIONAL_FAILURE" for row in rows),
    }
    atomic_json(run_dir / "final_report.json", report)
    direct, adaptive = strategies["direct"], strategies[ADAPTIVE]
    cp_lines = "\n".join(
        f"| {cp} | {direct['checkpoint_successes'][str(cp)]}/{direct['trials']} | "
        f"{adaptive['checkpoint_successes'][str(cp)]}/{adaptive['trials']} |"
        for cp in config["checkpoints"]
    )
    paired_lines = "\n".join(f"- {key}: {value}" for key, value in sorted(report["paired_counts_at_10"].items()))
    cause_lines = "\n".join(f"- {row['failure_cause']}: {row['count']}" for row in causes) or "- No lemma failures diagnosed."
    markdown = f"""# adaptive_proving Final Report

## 1. Experiment Summary

Status: `{report['status']}`. Completed {len(rows)}/{expected} pre-registered trials using `{config['proof_model']['model']}`.
Phase B trigger: `{trigger.get('pilot_signal')}`; Phase B ran: `{phase_b_ran}`.

## 2. Overall Strategy Success

- Direct: {direct['successes']} / {direct['trials']} PASS
- Diagnosis-Guided Adaptive Lemma-First: {adaptive['successes']} / {adaptive['trials']} PASS
- Difference: {adaptive['successes'] - direct['successes']:+d} solved trials

## 3. Checkpoint Success

| Calls | Direct | Diagnosis-Guided Adaptive LF |
|---:|---:|---:|
{cp_lines}

## 4. Paired Results

{paired_lines or '- No complete pairs.'}

## 5. Diagnosis Summary

- Diagnoses: {len(diagnosis_rows)}
- Avoided invalid repairs: {effectiveness['avoided_invalid_repairs']}
- Diagnosis #1 REPAIR then Diagnosis #2 REDESIGN: {effectiveness['diagnosis1_repair_diagnosis2_redesign']}

## 6. Failure Causes

{cause_lines}

## 7. Repair / Redesign Effectiveness

- Diagnosis → REPAIR → immediate lemma PASS: {effectiveness['diagnosis_repair_pass']}
- Diagnosis → REDESIGN → immediate lemma PASS: {effectiveness['diagnosis_redesign_pass']}

## 8. STRICT_DECOMPOSITION_RESCUE

{len(strict)} paired trials.

## 9. DIAGNOSIS_GUIDED_RESCUE

{len(guided)} paired trials.

## 10. Representative Case Studies

{chr(10).join(f"- {row['category']}: {row['path']}" for row in cases) or '- No qualifying case in completed trials.'}
"""
    atomic_text(run_dir / "final_report.md", markdown)
    atomic_json(run_dir / "integrity.json", _integrity(run_dir))
    return report
