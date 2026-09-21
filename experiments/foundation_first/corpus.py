"""Freeze multi_phase_proofs challenges while excluding all answer-bearing fields."""
from __future__ import annotations

from pathlib import Path
from typing import Any

from experiments.adaptive_proving.corpus import (
    load_frozen_tasks as load_r10c_tasks,
    theorem_base_for,
    verify_frozen_tasks,
)


def load_frozen_tasks(project: Path, config: dict[str, Any]) -> tuple[list[dict[str, Any]], dict[str, Any]]:
    tasks, source = load_r10c_tasks(project, config)
    # R10C already excludes reference_proof.  Rebuild a minimal task record so
    # foundation_first cannot accidentally consume gap_spec or other pre-analysis.
    allowed = {
        "challenge_id", "task_id", "dut", "module", "model_dir", "context_import",
        "statement", "statement_sha256", "property_type", "state_type",
        "required_state_fields", "required_input_fields", "assumptions",
        "context_sha256", "foundation_lemmas", "source_challenge_sha256",
        "adapted_task_sha256", "reference_proof_excluded_from_task",
    }
    frozen = [{key: value for key, value in task.items() if key in allowed} for task in tasks]
    for task in frozen:
        task["reference_proof_excluded_from_task"] = True
        task["gap_spec_excluded_from_task"] = True
        task["baseline_feedback_excluded_from_task"] = True
    return frozen, source


__all__ = ["load_frozen_tasks", "verify_frozen_tasks", "theorem_base_for"]
