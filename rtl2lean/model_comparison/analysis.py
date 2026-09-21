"""Analyze Lemma-First results and compare them with the frozen Direct arm."""
from __future__ import annotations

import csv
import json
import os
import re
import statistics
from collections import Counter
from pathlib import Path
from typing import Any

from rtl2lean.pipeline.io import sha256, write_json
from rtl2lean.compositional_proofs.report import tree_digest
from rtl2lean.model_calibration.runner import OPERATIONAL_FAILURES


def _read(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def _rate(n: int, d: int) -> float | None:
    return round(n / d, 6) if d else None


def _mean(values: list[float | int]) -> float | None:
    return round(statistics.mean(values), 6) if values else None


def _csv(path: Path, rows: list[dict[str, Any]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=list(rows[0]) if rows else ["empty"])
        writer.writeheader(); writer.writerows(rows)


def _secret_scan(root: Path) -> bool:
    secrets = [os.environ.get(name, "").encode() for name in ("OPENAI_API_KEY", "DEEPSEEK_API_KEY")
               if os.environ.get(name)]
    for path in root.rglob("*"):
        if not path.is_file():
            continue
        data = path.read_bytes()
        if any(secret in data for secret in secrets) or re.search(rb"sk-[A-Za-z0-9_-]{16,}", data):
            return False
    return True


def _labels(ranked: list[dict[str, Any]]) -> bool:
    if len(ranked) != 3:
        return False
    gap1 = ranked[0]["overall_success_rate"] - ranked[1]["overall_success_rate"]
    gap2 = ranked[1]["overall_success_rate"] - ranked[2]["overall_success_rate"]
    if gap1 >= 0.05 and gap2 >= 0.05:
        for row, label in zip(ranked, ("STRONG", "MEDIUM", "WEAK")):
            row["capability_label"] = label
        return True
    if gap1 >= 0.05 and gap2 < 0.05:
        ranked[0]["capability_label"] = "HIGHER_CAPABILITY"
        ranked[1]["capability_label"] = ranked[2]["capability_label"] = "SIMILAR_CAPABILITY"
    elif gap1 < 0.05 and gap2 >= 0.05:
        ranked[0]["capability_label"] = ranked[1]["capability_label"] = "SIMILAR_CAPABILITY"
        ranked[2]["capability_label"] = "LOWER_CAPABILITY"
    else:
        for row in ranked:
            row["capability_label"] = "ORDERED_BUT_NOT_CLEARLY_SEPARATED"
    return False


def build_analysis(output_root: Path, requirement_root: Path) -> dict[str, Any]:
    frozen = _read(requirement_root / "calibration_manifest.json")
    models = _read(requirement_root / "manifests" / "models.json")["models"]
    tasks_payload = _read(requirement_root / "manifests" / "tasks.json")
    tasks = tasks_payload["tasks"]
    prompts = _read(requirement_root / "manifests" / "prompts.json")["rows"]
    budgets = _read(requirement_root / "manifests" / "budgets.json")
    theorem_base = _read(requirement_root / "manifests" / "theorem_base.json")
    direct_snapshot = _read(requirement_root / "manifests" / "direct_baseline_snapshot.json")["rows"]
    runs_path = requirement_root / "runs" / "all_results.json"
    runs = _read(runs_path)["rows"] if runs_path.is_file() else []
    model_keys = [model["model_key"] for model in models]

    overall, difficulty_rows, first_rows, repair_rows, token_rows, failure_rows, stage_rows = ([] for _ in range(7))
    for key in model_keys:
        selected = [row for row in runs if row["model_key"] == key]
        valid = [row for row in selected if row["valid_proof_run"]]
        solved = [row for row in valid if row["final_pass"]]
        lemma_pass = [row for row in valid if row["intermediate_lemma_pass"]]
        actual_reuse = [row for row in solved if row["intermediate_lemma_actual_reuse"]]
        operational = [row for row in selected if row["status"] in OPERATIONAL_FAILURES]
        overall.append({
            "model_key": key, "strategy": "LEMMA_FIRST", "total_scheduled_runs": len(selected),
            "valid_proof_runs": len(valid), "kernel_verified_solved": len(solved),
            "KERNEL_VERIFIED_SUCCESS_RATE": _rate(len(solved), len(valid)),
            "operational_failures_excluded": len(operational),
        })
        stage_rows.append({
            "model_key": key, "valid_proof_runs": len(valid),
            "kernel_verified_intermediate_lemmas": len(lemma_pass),
            "INTERMEDIATE_LEMMA_SUCCESS_RATE": _rate(len(lemma_pass), len(valid)),
            "kernel_verified_targets": len(solved),
            "targets_with_explicit_lemma_reuse": len(actual_reuse),
            "ACTUAL_LEMMA_REUSE_RATE_AMONG_SOLVED": _rate(len(actual_reuse), len(solved)),
        })
        initial = sum(row["initial_pass"] for row in valid)
        first_rows.append({
            "model_key": key, "valid_proof_runs": len(valid),
            "both_stages_first_attempt_passes": initial,
            "FIRST_ATTEMPT_SUCCESS_RATE": _rate(initial, len(valid)),
            "target_first_attempt_passes": sum(row["target_first_attempt_pass"] for row in valid),
        })
        repair_rows.append({
            "model_key": key, "valid_proof_runs": len(valid),
            "average_repair_rounds_all_valid": _mean([row["repair_rounds"] for row in valid]),
            "average_repair_rounds_solved": _mean([row["repair_rounds"] for row in solved]),
            "solved_after_repair": sum(row["final_pass"] and not row["initial_pass"] for row in valid),
        })
        split = all(
            (attempt.get("response_metadata") or {}).get("usage_granularity") != "total_only"
            for row in valid for attempt in row["attempts"]
        )
        token_rows.append({
            "model_key": key, "input_output_split_available": split,
            "average_input_tokens_valid": _mean([row["input_tokens"] for row in valid]) if split else None,
            "average_output_tokens_valid": _mean([row["output_tokens"] for row in valid]) if split else None,
            "average_total_tokens_valid": _mean([row["total_tokens"] for row in valid]),
            "average_tokens_per_solved_proof": _mean([row["total_tokens"] for row in solved]),
            "average_wall_time_s": _mean([row["wall_time_s"] for row in valid]),
            "average_solved_proof_ast_size": _mean([
                row["proof_ast_size"] for row in solved if row["proof_ast_size"] is not None
            ]),
        })
        for (category, terminal_stage), count in sorted(Counter(
            (row["failure_category"], row["attempts"][-1]["stage"])
            for row in selected if row.get("failure_category")
        ).items()):
            failure_rows.append({
                "model_key": key, "failure_category": category, "count": count,
                "terminal_stage": terminal_stage,
                "failure_domain": "OPERATIONAL_EXCLUDED" if category in OPERATIONAL_FAILURES else "PROOF_OR_BUDGET",
            })
        for level in ("EASY", "MEDIUM", "HARD"):
            subset = [row for row in valid if row["difficulty"] == level]
            count = sum(row["final_pass"] for row in subset)
            difficulty_rows.append({
                "model_key": key, "difficulty": level, "valid_proof_runs": len(subset),
                "kernel_verified_solved": count,
                "KERNEL_VERIFIED_SUCCESS_RATE": _rate(count, len(subset)),
            })

    overall_map = {row["model_key"]: row for row in overall}
    first_map = {row["model_key"]: row for row in first_rows}
    repair_map = {row["model_key"]: row for row in repair_rows}
    hard_map = {row["model_key"]: row for row in difficulty_rows if row["difficulty"] == "HARD"}
    complete = all(overall_map[key]["valid_proof_runs"] == 45 for key in model_keys)
    order = sorted(model_keys, key=lambda key: (
        -overall_map[key]["KERNEL_VERIFIED_SUCCESS_RATE"],
        -hard_map[key]["KERNEL_VERIFIED_SUCCESS_RATE"],
        -first_map[key]["FIRST_ATTEMPT_SUCCESS_RATE"],
        repair_map[key]["average_repair_rounds_all_valid"], key,
    )) if complete else []
    ranked = [{
        "rank": index, "model_key": key,
        "overall_success_rate": overall_map[key]["KERNEL_VERIFIED_SUCCESS_RATE"],
        "hard_success_rate": hard_map[key]["KERNEL_VERIFIED_SUCCESS_RATE"],
        "first_attempt_success_rate": first_map[key]["FIRST_ATTEMPT_SUCCESS_RATE"],
        "average_repair_rounds": repair_map[key]["average_repair_rounds_all_valid"],
        "capability_label": None,
    } for index, key in enumerate(order, 1)]
    separated = _labels(ranked) if ranked else False
    ranking = {
        "schema": "rtl2lean-model_comparison-ranking-v1",
        "status": "COMPLETE" if complete else "INCOMPLETE",
        "ranking_policy": ["overall kernel success", "hard success", "first-attempt success", "repair efficiency"],
        "strong_medium_weak_assigned": separated, "rows": ranked,
    }

    direct_map: dict[tuple[str, str, int], dict[str, Any]] = {
        (row["model_key"], row["task_id"], row["trial_id"]): row for row in direct_snapshot
    }
    comparison_rows = []
    for key in model_keys:
        direct_rows = [row for row in direct_snapshot if row["model_key"] == key and row["valid_proof_run"]]
        lemma_rows = [row for row in runs if row["model_key"] == key and row["valid_proof_run"]]
        direct_rate = _rate(sum(row["final_pass"] for row in direct_rows), len(direct_rows))
        lemma_rate = _rate(sum(row["final_pass"] for row in lemma_rows), len(lemma_rows))
        paired = [
            (direct_map[(row["model_key"], row["task_id"], row["trial_id"])]["final_pass"], row["final_pass"])
            for row in lemma_rows
        ]
        comparison_rows.append({
            "model_key": key, "direct_success_rate": direct_rate,
            "lemma_first_success_rate": lemma_rate,
            "lemma_first_minus_direct": round(lemma_rate - direct_rate, 6),
            "direct_fail_to_lemma_first_pass": sum(not d and l for d, l in paired),
            "direct_pass_to_lemma_first_fail": sum(d and not l for d, l in paired),
        })

    payloads = {
        "overall_success.json": {"schema": "r10lf-overall-v1", "rows": overall},
        "difficulty_success.json": {"schema": "r10lf-difficulty-v1", "rows": difficulty_rows},
        "first_attempt.json": {"schema": "r10lf-first-v1", "rows": first_rows},
        "repair_analysis.json": {"schema": "r10lf-repair-v1", "rows": repair_rows},
        "token_analysis.json": {"schema": "r10lf-token-v1", "rows": token_rows},
        "failure_modes.json": {"schema": "r10lf-failure-v1", "rows": failure_rows},
        "stage_success.json": {"schema": "r10lf-stage-v1", "rows": stage_rows},
        "direct_comparison.json": {"schema": "r10lf-direct-comparison-v1", "rows": comparison_rows},
    }
    for name, payload in payloads.items():
        write_json(requirement_root / "analysis" / name, payload)
    write_json(requirement_root / "capability_ranking.json", ranking)
    for name, rows in (
        ("overall_results.csv", overall), ("difficulty_results.csv", difficulty_rows),
        ("failure_modes.csv", failure_rows), ("model_comparison.csv", comparison_rows),
        ("stage_results.csv", stage_rows),
    ):
        _csv(requirement_root / "tables" / name, rows)

    expected = {
        (model["model_key"], task["task_id"], trial)
        for model in models for task in tasks for trial in range(1, frozen["trials_per_task"] + 1)
    }
    actual = {(row["model_key"], row["task_id"], row["trial_id"]) for row in runs}
    prompt_map = {(row["task_id"], row["trial_id"]): row for row in prompts}
    theorem_map = {row["dut"]: row["theorem_base_hash"] for row in theorem_base["duts"]}
    current_theorem = {
        row["dut"]: tree_digest(output_root / row["slug"] / "model") for row in theorem_base["duts"]
    }
    model_success = {
        key: any("API_SUCCESS" in row["api_statuses"] for row in runs if row["model_key"] == key)
        for key in model_keys
    }
    target_stage_order_valid = all(
        all(
            any(
                earlier["stage"] == "INTERMEDIATE_LEMMA"
                and (earlier.get("kernel_check") or {}).get("success")
                for earlier in row["attempts"][:index]
            )
            for index, attempt in enumerate(row["attempts"]) if attempt["stage"] == "TARGET"
        ) for row in runs
    )
    generated = [attempt for row in runs for attempt in row["attempts"] if attempt.get("generated_proof")]
    source = output_root / "model_calibration"
    source_bindings = _read(requirement_root / "manifests" / "source_bindings.json")
    integrity = {
        "three_model_effective_backends_successfully_called": all(model_success.values()),
        "api_key_not_leaked": _secret_scan(requirement_root),
        "same_fifteen_tasks_as_direct": source_bindings["direct_tasks_sha256"] == sha256(source / "manifests" / "tasks.json"),
        "same_models_as_direct": source_bindings["direct_models_sha256"] == sha256(source / "manifests" / "models.json"),
        "same_theorem_base_as_direct": source_bindings["direct_theorem_base_sha256"] == sha256(source / "manifests" / "theorem_base.json"),
        "same_trials_and_seeds_as_direct": source_bindings["direct_seeds_sha256"] == sha256(source / "manifests" / "seeds.json"),
        "same_configured_framework_budget_as_direct": budgets["source_direct_budget_sha256"] == sha256(source / "manifests" / "budgets.json"),
        "same_initial_prompt_and_stage_policy_across_models": all(
            row["prompt_hash"] == prompt_map[(row["task_id"], row["trial_id"])]["prompt_hash"] for row in runs
        ),
        "same_frozen_context_across_models": all(
            row["context_hash"] == prompt_map[(row["task_id"], row["trial_id"])]["context_hash"] for row in runs
        ),
        "theorem_base_unchanged": current_theorem == theorem_map and all(
            row["theorem_base_hash"] == theorem_map[row["dut"]] for row in runs
        ),
        "complete_raw_run_matrix": len(runs) == 135 and actual == expected,
        "intermediate_lemma_kernel_checked_before_target": target_stage_order_valid,
        "all_generated_proofs_checked": all(attempt.get("kernel_check") is not None for attempt in generated),
        "all_solved_targets_actually_reuse_verified_lemma": all(
            not row["final_pass"] or row["intermediate_lemma_actual_reuse"] for row in runs
        ),
        "api_and_proof_failures_separated": all(
            (not row["valid_proof_run"] and not row["proof_failure"])
            if row["status"] in OPERATIONAL_FAILURES else row["valid_proof_run"] for row in runs
        ),
        "direct_baseline_snapshot_unchanged": source_bindings["direct_runs_sha256"] == sha256(source / "runs" / "all_results.json"),
        "capability_ranking_complete": ranking["status"] == "COMPLETE",
        "frozen_manifest_hashes_match": all(
            sha256(requirement_root / rel) == digest for rel, digest in frozen["frozen_artifact_hashes"].items()
        ),
    }
    status = "PASS" if all(integrity.values()) else (
        "INCOMPLETE_CONFIGURATION" if not complete or not all(model_success.values()) else "FAIL"
    )
    report = {
        "schema": "rtl2lean-model_comparison-final-v1", "status": status,
        "question": "Three-model Lemma-First capability on the same frozen 15 Lean tasks",
        "metrics": {"expected_runs": 135, "recorded_runs": len(runs)},
        "overall": overall, "difficulty": difficulty_rows, "stages": stage_rows,
        "direct_comparison": comparison_rows, "ranking": ranking, "integrity": integrity,
        "transport_deviation": {
            "status": "USER_AUTHORIZED_CODEX_FALLBACK", "affected_model": "gpt",
            "original_openai_key_transport_used": False,
            "limitation": (
                "Both Direct and Lemma-First GPT arms use Codex account authentication. The CLI "
                "reports total tokens only and cannot independently enforce/audit the 8000 output-token sub-limit."
            ),
        },
        "interpretation": (
            "Under the same three-call total budget, Lemma-First reduced success for all three models. "
            "Most DeepSeek failures terminated while constructing the intermediate lemma, so this result "
            "does not show that verified decomposition is intrinsically harmful; it shows that autonomous "
            "lemma discovery plus two proof stages does not fit these models and this budget as well as Direct."
        ),
    }
    write_json(requirement_root / "integrity.json", integrity)
    write_json(requirement_root / "final_report.json", report)
    lines = [
        "# model_comparison Lemma-First Report", "", f"Status: **{status}**", "",
        "## Lemma-First overall", "",
        *(f"- {row['model_key']}: {row['kernel_verified_solved']}/{row['valid_proof_runs']} "
          f"({row['KERNEL_VERIFIED_SUCCESS_RATE']})" for row in overall),
        "", "## Direct comparison", "",
        *(f"- {row['model_key']}: Direct={row['direct_success_rate']}, "
          f"Lemma-First={row['lemma_first_success_rate']}, delta={row['lemma_first_minus_direct']}"
          for row in comparison_rows),
        "", "## Ranking", "",
        *(f"- {row['rank']}. {row['model_key']}: {row['capability_label']}" for row in ranked),
        "", "## Integrity", "",
        *(f"- {key}: {value}" for key, value in integrity.items()),
        "", "## Authorized transport deviation", "", f"- {report['transport_deviation']['limitation']}", "",
        "## Interpretation", "", report["interpretation"], "",
    ]
    (requirement_root / "final_report.md").write_text("\n".join(lines), encoding="utf-8")
    return report
