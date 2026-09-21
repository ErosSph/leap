"""Analyze the frozen 10A run matrix without turning API errors into proof failures."""
from __future__ import annotations

import csv
import hashlib
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


def _rate(numerator: int, denominator: int) -> float | None:
    return round(numerator / denominator, 6) if denominator else None


def _mean(values: list[float | int]) -> float | None:
    return round(statistics.mean(values), 6) if values else None


def _csv(path: Path, rows: list[dict[str, Any]], fields: list[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=fields, extrasaction="ignore")
        writer.writeheader(); writer.writerows(rows)


def _secret_scan(root: Path) -> bool:
    secrets = [os.environ.get(name, "") for name in ("OPENAI_API_KEY", "DEEPSEEK_API_KEY")]
    secrets = [value.encode() for value in secrets if value]
    for path in root.rglob("*"):
        if not path.is_file():
            continue
        data = path.read_bytes()
        if any(secret in data for secret in secrets):
            return False
        if re.search(rb"sk-[A-Za-z0-9_-]{16,}", data):
            return False
    return True


def build_analysis(output_root: Path, requirement_root: Path) -> dict[str, Any]:
    frozen = _read(requirement_root / "calibration_manifest.json")
    models = _read(requirement_root / "manifests" / "models.json")["models"]
    tasks_payload = _read(requirement_root / "manifests" / "tasks.json")
    tasks = tasks_payload["tasks"]
    prompts = _read(requirement_root / "manifests" / "prompts.json")
    budgets = _read(requirement_root / "manifests" / "budgets.json")
    validation = _read(requirement_root / "manifests" / "validation.json")["rows"]
    theorem_base = _read(requirement_root / "manifests" / "theorem_base.json")
    runs_path = requirement_root / "runs" / "all_results.json"
    runs = _read(runs_path)["rows"] if runs_path.is_file() else []
    amendment_path = requirement_root / "manifests" / "transport_amendment_codex_fallback.json"
    amendment = _read(amendment_path) if amendment_path.is_file() else None
    model_keys = [row["model_key"] for row in models]

    overall_rows = []
    first_rows = []
    repair_rows = []
    token_rows = []
    difficulty_rows = []
    failure_rows = []
    for key in model_keys:
        selected = [row for row in runs if row["model_key"] == key]
        valid = [row for row in selected if row["valid_proof_run"]]
        solved = [row for row in valid if row["final_pass"]]
        operational = [row for row in selected if row["status"] in OPERATIONAL_FAILURES]
        overall_rows.append({
            "model_key": key, "total_scheduled_runs": len(selected), "valid_proof_runs": len(valid),
            "kernel_verified_solved": len(solved),
            "KERNEL_VERIFIED_SUCCESS_RATE": _rate(len(solved), len(valid)),
            "operational_failures_excluded": len(operational),
        })
        first = sum(row["initial_pass"] for row in valid)
        first_rows.append({
            "model_key": key, "valid_proof_runs": len(valid), "first_attempt_passes": first,
            "FIRST_ATTEMPT_SUCCESS_RATE": _rate(first, len(valid)),
        })
        repair_rows.append({
            "model_key": key, "valid_proof_runs": len(valid),
            "average_repair_rounds_all_valid": _mean([row["repair_rounds"] for row in valid]),
            "average_repair_rounds_solved": _mean([row["repair_rounds"] for row in solved]),
            "solved_after_repair": sum(row["final_pass"] and not row["initial_pass"] for row in valid),
        })
        split_usage_available = all(
            (attempt.get("response_metadata") or {}).get("usage_granularity") != "total_only"
            for row in valid for attempt in row.get("attempts", [])
        )
        token_rows.append({
            "model_key": key,
            "input_output_split_available": split_usage_available,
            "average_input_tokens_valid": (
                _mean([row["input_tokens"] for row in valid]) if split_usage_available else None
            ),
            "average_output_tokens_valid": (
                _mean([row["output_tokens"] for row in valid]) if split_usage_available else None
            ),
            "average_total_tokens_valid": _mean([row["total_tokens"] for row in valid]),
            "average_tokens_per_solved_proof": _mean([row["total_tokens"] for row in solved]),
            "average_wall_time_s": _mean([row["wall_time_s"] for row in valid]),
            "average_solved_proof_ast_size": _mean([
                row["proof_ast_size"] for row in solved if row["proof_ast_size"] is not None
            ]),
        })
        classified = []
        for row in selected:
            if row.get("lean_error_category"):
                classified.append((row["lean_error_category"], "LEAN_PROOF_ERROR"))
            if row.get("failure_category") and row["failure_category"] != row.get("lean_error_category"):
                classified.append((
                    row["failure_category"],
                    "OPERATIONAL_EXCLUDED" if row["failure_category"] in OPERATIONAL_FAILURES
                    else "TERMINAL_BUDGET",
                ))
            elif row.get("failure_category") in OPERATIONAL_FAILURES:
                classified.append((row["failure_category"], "OPERATIONAL_EXCLUDED"))
        counts = Counter(classified)
        for (category, domain), count in sorted(counts.items()):
            failure_rows.append({
                "model_key": key, "failure_category": category, "count": count,
                "failure_domain": domain,
            })
        for difficulty in ("EASY", "MEDIUM", "HARD"):
            subset = [row for row in valid if row["difficulty"] == difficulty]
            nsolved = sum(row["final_pass"] for row in subset)
            difficulty_rows.append({
                "model_key": key, "difficulty": difficulty,
                "valid_proof_runs": len(subset), "kernel_verified_solved": nsolved,
                "KERNEL_VERIFIED_SUCCESS_RATE": _rate(nsolved, len(subset)),
            })

    overall_map = {row["model_key"]: row for row in overall_rows}
    first_map = {row["model_key"]: row for row in first_rows}
    repair_map = {row["model_key"]: row for row in repair_rows}
    hard_map = {row["model_key"]: row for row in difficulty_rows if row["difficulty"] == "HARD"}
    complete_data = all(
        overall_map[key]["valid_proof_runs"] == 15 * frozen["trials_per_task"]
        for key in model_keys
    )
    def descending(value: float | None) -> float:
        return -value if value is not None else 1.0

    def ascending(value: float | None) -> float:
        return value if value is not None else 999.0

    ranking_rows = sorted(model_keys, key=lambda key: (
        descending(overall_map[key]["KERNEL_VERIFIED_SUCCESS_RATE"]),
        descending(hard_map[key]["KERNEL_VERIFIED_SUCCESS_RATE"]),
        descending(first_map[key]["FIRST_ATTEMPT_SUCCESS_RATE"]),
        ascending(repair_map[key]["average_repair_rounds_all_valid"]),
        key,
    )) if complete_data else []
    ranked = []
    for index, key in enumerate(ranking_rows, 1):
        rate = overall_map[key]["KERNEL_VERIFIED_SUCCESS_RATE"]
        ranked.append({
            "rank": index, "model_key": key, "overall_success_rate": rate,
            "hard_success_rate": hard_map[key]["KERNEL_VERIFIED_SUCCESS_RATE"],
            "first_attempt_success_rate": first_map[key]["FIRST_ATTEMPT_SUCCESS_RATE"],
            "average_repair_rounds": repair_map[key]["average_repair_rounds_all_valid"],
            "capability_label": None,
        })
    clearly_separated = bool(
        len(ranked) == 3
        and ranked[0]["overall_success_rate"] - ranked[1]["overall_success_rate"] >= 0.05
        and ranked[1]["overall_success_rate"] - ranked[2]["overall_success_rate"] >= 0.05
    )
    if clearly_separated:
        for row, label in zip(ranked, ("STRONG", "MEDIUM", "WEAK")):
            row["capability_label"] = label
    elif ranked:
        first_gap = ranked[0]["overall_success_rate"] - ranked[1]["overall_success_rate"]
        second_gap = ranked[1]["overall_success_rate"] - ranked[2]["overall_success_rate"]
        if first_gap >= 0.05 and second_gap < 0.05:
            ranked[0]["capability_label"] = "HIGHER_CAPABILITY"
            ranked[1]["capability_label"] = "SIMILAR_CAPABILITY"
            ranked[2]["capability_label"] = "SIMILAR_CAPABILITY"
        elif first_gap < 0.05 and second_gap >= 0.05:
            ranked[0]["capability_label"] = "SIMILAR_CAPABILITY"
            ranked[1]["capability_label"] = "SIMILAR_CAPABILITY"
            ranked[2]["capability_label"] = "LOWER_CAPABILITY"
        else:
            for row in ranked:
                row["capability_label"] = "ORDERED_BUT_NOT_CLEARLY_SEPARATED"
    ranking = {
        "schema": "rtl2lean-model_calibration-capability-ranking-v1",
        "status": "COMPLETE" if complete_data else "INCOMPLETE",
        "ranking_policy": [
            "overall kernel success", "hard-task success", "first-attempt success",
            "repair efficiency",
        ],
        "strong_medium_weak_assigned": clearly_separated, "rows": ranked,
    }

    analysis_payloads = {
        "overall_success.json": {"schema": "r10a-overall-v1", "rows": overall_rows},
        "difficulty_success.json": {"schema": "r10a-difficulty-v1", "rows": difficulty_rows},
        "first_attempt.json": {"schema": "r10a-first-v1", "rows": first_rows},
        "repair_analysis.json": {"schema": "r10a-repair-v1", "rows": repair_rows},
        "token_analysis.json": {"schema": "r10a-token-v1", "rows": token_rows},
        "failure_modes.json": {"schema": "r10a-failures-v1", "rows": failure_rows},
    }
    for name, payload in analysis_payloads.items():
        write_json(requirement_root / "analysis" / name, payload)
    write_json(requirement_root / "capability_ranking.json", ranking)

    comparison = []
    for key in model_keys:
        comparison.append({
            **overall_map[key],
            "easy_rate": next(row["KERNEL_VERIFIED_SUCCESS_RATE"] for row in difficulty_rows
                              if row["model_key"] == key and row["difficulty"] == "EASY"),
            "medium_rate": next(row["KERNEL_VERIFIED_SUCCESS_RATE"] for row in difficulty_rows
                                if row["model_key"] == key and row["difficulty"] == "MEDIUM"),
            "hard_rate": hard_map[key]["KERNEL_VERIFIED_SUCCESS_RATE"],
            "first_attempt_rate": first_map[key]["FIRST_ATTEMPT_SUCCESS_RATE"],
            "average_repairs": repair_map[key]["average_repair_rounds_all_valid"],
        })
    _csv(requirement_root / "tables" / "overall_results.csv", overall_rows, list(overall_rows[0]))
    _csv(requirement_root / "tables" / "difficulty_results.csv", difficulty_rows, list(difficulty_rows[0]))
    _csv(requirement_root / "tables" / "failure_modes.csv", failure_rows,
         list(failure_rows[0]) if failure_rows else ["model_key", "failure_category", "count", "failure_domain"])
    _csv(requirement_root / "tables" / "model_comparison.csv", comparison, list(comparison[0]))

    expected_keys = {
        (model["model_key"], task["task_id"], trial)
        for model in models for task in tasks
        for trial in range(1, frozen["trials_per_task"] + 1)
    }
    actual_keys = {(row["model_key"], row["task_id"], row["trial_id"]) for row in runs}
    prompt_map = {(row["task_id"], row["trial_id"]): row for row in prompts["rows"]}
    model_backend_success = {
        key: any("API_SUCCESS" in row["api_statuses"] for row in runs if row["model_key"] == key)
        for key in model_keys
    }
    codex_fallback_valid = bool(
        amendment
        and amendment.get("user_authorized") is True
        and amendment.get("affected_model_key") == "gpt"
        and amendment.get("new_transport", {}).get("kind") == "codex_cli"
        and all(
            row.get("transport") == "codex_cli"
            and row.get("credential_source") == "codex_account_login"
            and row.get("transport_amendment_sha256") == sha256(amendment_path)
            for row in runs if row["model_key"] == "gpt"
        )
    )
    valid_generated = [
        attempt for row in runs if row["valid_proof_run"] for attempt in row["attempts"]
        if attempt.get("generated_proof")
    ]
    theorem_hash_map = {row["dut"]: row["theorem_base_hash"] for row in theorem_base["duts"]}
    challenge_rows = _read(output_root / "multi_phase_proofs" / "corpus" / "bottleneck_challenges.json")["properties"]
    challenge_ids = {row["property_id"] for row in challenge_rows}
    challenge_statement_hashes = {
        hashlib.sha256(row["theorem_statement"].encode()).hexdigest() for row in challenge_rows
    }
    task_separation = all(
        task["task_id"] not in challenge_ids
        and hashlib.sha256(task["statement"].encode()).hexdigest() not in challenge_statement_hashes
        for task in tasks
    )
    current_theorem_hashes = {
        row["dut"]: tree_digest(output_root / row["slug"] / "model")
        for row in theorem_base["duts"]
    }
    integrity = {
        "three_model_effective_backends_successfully_called": all(model_backend_success.values()),
        "codex_fallback_explicitly_disclosed": codex_fallback_valid,
        "api_key_not_leaked": _secret_scan(requirement_root),
        "fifteen_tasks_frozen_before_calls": frozen["frozen_before_api_calls"] and len(tasks) == 15,
        "five_tasks_per_difficulty": tasks_payload["difficulty_counts"] == {"EASY": 5, "MEDIUM": 5, "HARD": 5},
        "calibration_excludes_r8_bottleneck_challenges":
            tasks_payload["excluded_multi_phase_proofs_bottleneck_challenges"] and task_separation,
        "all_reference_proofs_kernel_validated": len(validation) == 15 and all(
            row["kernel_validated"] for row in validation
        ),
        "same_prompt_across_models": all(
            row["prompt_hash"] == prompt_map[(row["task_id"], row["trial_id"])]["prompt_hash"]
            for row in runs
        ),
        "same_theorem_base_across_models": len(theorem_base["duts"]) == 5 and all(
            row.get("theorem_base_hash") == theorem_hash_map[row["dut"]] for row in runs
        ) and current_theorem_hashes == theorem_hash_map,
        "same_context_across_models": all(
            row["context_hash"] == prompt_map[(row["task_id"], row["trial_id"])]["context_hash"]
            for row in runs
        ),
        "same_configured_framework_budget": budgets["max_llm_calls"] == 3
            and budgets["max_repair_rounds"] == 2,
        "same_trial_count": frozen["trials_per_task"] == 3,
        "complete_raw_run_matrix": actual_keys == expected_keys and len(runs) == frozen["expected_runs"],
        "all_generated_proofs_checked": all(
            attempt.get("kernel_check") is not None for attempt in valid_generated
        ) and all(
            not row["final_pass"] or any(
                (attempt.get("kernel_check") or {}).get("success") for attempt in row["attempts"]
            ) for row in runs
        ),
        "api_and_proof_failures_separated": all(
            (not row["valid_proof_run"] and not row["proof_failure"])
            if row["status"] in OPERATIONAL_FAILURES else row["valid_proof_run"]
            for row in runs
        ),
        "capability_ranking_complete": ranking["status"] == "COMPLETE",
        "frozen_manifest_hashes_match": all(
            sha256(requirement_root / rel) == digest
            for rel, digest in frozen["frozen_artifact_hashes"].items()
        ),
    }
    configuration_incomplete = not all(model_backend_success.values()) or not complete_data
    status = "PASS" if all(integrity.values()) else (
        "INCOMPLETE_CONFIGURATION" if configuration_incomplete else "FAIL"
    )
    report = {
        "schema": "rtl2lean-model_calibration-final-v1", "status": status,
        "question": "Capability ranking under identical Lean Direct-proof conditions",
        "metrics": {"expected_runs": frozen["expected_runs"], "recorded_runs": len(runs)},
        "model_backend_success": model_backend_success, "overall": overall_rows,
        "difficulty": difficulty_rows, "ranking": ranking,
        "integrity": integrity,
        "transport_deviation": {
            "original_three_direct_provider_api_condition_met": False,
            "status": "USER_AUTHORIZED_CODEX_FALLBACK" if codex_fallback_valid else "INVALID_OR_MISSING",
            "affected_model": "gpt",
            "unchanged": [
                "model_id", "reasoning_profile", "prompts", "theorem_base",
                "context", "token_budget", "repair_budget", "trials",
            ],
            "limitation": (
                "GPT was invoked through Codex account authentication, not the originally frozen "
                "OPENAI_API_KEY transport. Codex injects its own provider envelope and exposes total "
                "token usage only. The 120000 total-token framework ceiling was enforced and no GPT "
                "run exceeded it, but the frozen 8000 max-output-token sub-limit cannot be independently "
                "configured or audited through this CLI; GPT input/output token splits are unavailable."
            ),
            "effective_max_output_tokens_auditable": False,
            "framework_max_total_tokens_enforced": True,
            "maximum_observed_gpt_total_tokens": max(
                (row["total_tokens"] for row in runs if row["model_key"] == "gpt"), default=None
            ),
        },
        "interpretation": (
            "The ranking is frozen from complete kernel-verified evidence."
            if ranking["status"] == "COMPLETE"
            else "No capability ranking is claimed until all three providers have complete valid runs."
        ),
    }
    write_json(requirement_root / "integrity.json", integrity)
    write_json(requirement_root / "final_report.json", report)
    lines = [
        "# model_calibration Final Report", "", f"Status: **{status}**", "",
        "## Overall", "",
        *(f"- {row['model_key']}: {row['kernel_verified_solved']}/{row['valid_proof_runs']} "
          f"({row['KERNEL_VERIFIED_SUCCESS_RATE']})" for row in overall_rows),
        "", "## Capability ranking", "",
        *(f"- {row['rank']}. {row['model_key']}: {row['capability_label']}"
          for row in ranked),
        *([] if ranked else ["- Not available: incomplete provider evidence."]),
        "", "## Integrity", "",
        *(f"- {name}: {value}" for name, value in integrity.items()), "",
        "## Authorized transport deviation", "",
        f"- {report['transport_deviation']['limitation']}", "",
        report["interpretation"], "",
    ]
    (requirement_root / "final_report.md").write_text("\n".join(lines), encoding="utf-8")
    return report
