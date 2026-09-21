"""Statement-level target-utility checks before spending an LLM proof call."""
from __future__ import annotations

import re
from pathlib import Path
from typing import Any

from .prover import run_hypothetical_property


def _normal(value: str) -> str:
    return re.sub(r"\s+", "", value)


def _shape_score(statement: str, bridge: dict[str, Any]) -> tuple[float, dict[str, bool]]:
    lower = statement.lower()
    relation = bridge["missing_relation_class"]
    checks = {
        "uses_available_temporal_fact": "r3temporal.along" in lower,
        "uses_prefix_plus_last": bool(re.search(r"\+\+\s*\[", statement)),
        "concludes_required_guard": "→" in statement and "guard" in statement.rsplit("→", 1)[-1].lower(),
        "concludes_prefix_endpoint": bool(re.search(r"(?:exec|r3Run).*\b(?:pre|xs)\b", statement.rsplit("→", 1)[-1])),
    }
    weights = (0.20, 0.20, 0.35, 0.25) if relation == "LAST_STEP_GUARD" else (0.25,) * 4
    return sum(weight for weight, passed in zip(weights, checks.values()) if passed), checks


def evaluate_candidate(project: Path, root: Path, task: dict[str, Any], candidate: dict[str, str],
                       bridge: dict[str, Any], existing_theorems: list[dict[str, Any]],
                       timeout_s: int, medium_threshold: float) -> dict[str, Any]:
    statement = candidate["lemma_statement"]
    duplicate_target = _normal(statement) == _normal(task["statement"])
    duplicate_existing = any(_normal(statement) == _normal(str(row.get("statement") or ""))
                             for row in existing_theorems)
    score, components = _shape_score(statement, bridge)
    hypothetical = None
    if not duplicate_target and not duplicate_existing:
        hypothetical = run_hypothetical_property(project, root, task, candidate, timeout_s)
    if duplicate_target or duplicate_existing:
        classification, reason = "LOW_TARGET_UTILITY", "duplicate target/existing theorem"
    elif hypothetical and hypothetical["success"]:
        classification, reason = "HIGH_TARGET_UTILITY", "candidate assumption closes target and is referenced"
    elif score >= medium_threshold:
        classification, reason = "MEDIUM_TARGET_UTILITY", "structure advances the required bridge frontier"
    else:
        classification, reason = "LOW_TARGET_UTILITY", "same core bridge remains after hypothetical retry"
    return {
        "schema": "rtl2lean-bridge_discovery-candidate-utility-v1",
        "classification": classification, "accepted": classification != "LOW_TARGET_UTILITY",
        "reason": reason, "structural_score": round(score, 4), "score_components": components,
        "target_duplicate": duplicate_target, "existing_theorem_duplicate": duplicate_existing,
        "hypothetical_property_result": hypothetical,
        "temporary_assumption_only": True, "formal_kernel_pass": False,
        "entered_verified_pool": False,
        "proof_attempt_avoided": classification == "LOW_TARGET_UTILITY",
    }


def policy_manifest() -> dict[str, Any]:
    return {"schema": "rtl2lean-bridge_discovery-utility-policy-v1",
            "classes": ["HIGH_TARGET_UTILITY", "MEDIUM_TARGET_UTILITY", "LOW_TARGET_UTILITY"],
            "high_requires_candidate_referenced_hypothetical_pass": True,
            "temporary_assumption_counts_as_formal_proof": False,
            "low_candidate_enters_pool": False}
