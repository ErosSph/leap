"""Frozen, deterministic analysis of Req11 development-set failures."""
from __future__ import annotations

from collections import Counter
from pathlib import Path
from typing import Any

from experiments.adaptive_proving.io import read_json


CATEGORIES = {
    "A": "STATEMENT_UNREASONABLE", "B": "STATEMENT_TOO_STRONG",
    "C": "MISSING_NECESSARY_PREMISE", "D": "TEMPORAL_OR_STATE_SCOPE_MISMATCH",
    "E": "RELATED_BUT_NOT_MISSING_BRIDGE", "F": "TOO_LOCAL",
    "G": "STATEMENT_PLAUSIBLE_PROOF_IMPLEMENTATION_FAILED",
    "H": "EXISTING_THEOREM_DUPLICATE_OR_TRIVIAL_WRAPPER",
}


def _results(project: Path, development_run: str) -> list[dict[str, Any]]:
    root = project / development_run / "trials"
    return [read_json(path) for path in sorted(root.glob("C*/trial_*/result.json"))]


def _initial_class(attempt: dict[str, Any]) -> tuple[str, str]:
    candidate = attempt.get("model_response", {}).get("candidate") or {}
    statement = str(candidate.get("lemma_statement") or "")
    diagnosis = attempt.get("diagnosis") or {}
    if attempt.get("classification") == "EXISTING_THEOREM_DUPLICATE":
        return "H", "statement duplicates a theorem already in the base"
    if "R3Temporal.Along" in statement and "guard" in statement and "→" in statement:
        return "G", f"bridge-shaped statement; Lean failure={diagnosis.get('primary_cause', 'unknown')}"
    if "R3Temporal.exec" in statement and "guard" not in statement.rsplit("→", 1)[-1]:
        return "E", "trace identity does not conclude the target-side guard"
    if diagnosis.get("primary_cause") in {"TYPE_MISMATCH", "INDUCTION_STATE_NOT_GENERALIZED",
                                          "TRACE_SINGLETON_NOT_DESTRUCTURED",
                                          "THEOREM_APPLICATION_MISMATCH", "PROOF_IMPLEMENTATION_FAILURE"}:
        return "G", f"diagnoser identified proof-level failure {diagnosis.get('primary_cause')}"
    return "A", "statement has no recognized source-to-target bridge shape"


def build_development_analyses(project: Path, config: dict[str, Any]) -> tuple[dict[str, Any], dict[str, Any]]:
    rows = _results(project, config["development_run"])
    initial_cases = []
    for result in rows:
        first = result["candidate_attempts"][0]
        code, evidence = _initial_class(first)
        initial_cases.append({"challenge_id": result["challenge_id"], "category": code,
            "category_name": CATEGORIES[code], "evidence": evidence,
            "kernel_pass": bool(first.get("kernel_result", {}).get("success")),
            "diagnosis": (first.get("diagnosis") or {}).get("primary_cause")})
    initial_counts = Counter(row["category"] for row in initial_cases)
    initial = {"schema": "rtl2lean-bridge_discovery-initial-failure-analysis-v1",
        "source_requirement": 11, "development_set_only": True, "case_count": len(initial_cases),
        "taxonomy": CATEGORIES, "distribution": {key: initial_counts.get(key, 0) for key in CATEGORIES},
        "cases": initial_cases,
        "derived_generic_observation": (
            "Most first statements already had the needed last-step-guard direction; their dominant failure "
            "was proof construction, motivating statement/proof separation and frozen repair templates."),
        "rules_frozen_before_unseen_evaluation": True}
    redesign_cases = []
    mapping = {"LOW_TARGET_UTILITY": "utility still LOW",
        "LEMMA_SELECTION_FAILURE": "did not change old lemma core structure",
        "THEOREM_APPLICATION_MISMATCH": "proof feasibility/theorem application mismatch",
        "TYPE_MISMATCH": "proof feasibility/type mismatch",
        "TRACE_SINGLETON_NOT_DESTRUCTURED": "proof feasibility/singleton trace not exposed"}
    for result in rows:
        for attempt in result["candidate_attempts"]:
            if attempt.get("operation") != "REDESIGN":
                continue
            cause = (attempt.get("diagnosis") or {}).get("primary_cause", "UNCLASSIFIED")
            redesign_cases.append({"challenge_id": result["challenge_id"],
                "call_index": attempt["call_index"], "kernel_pass": attempt.get("kernel_result", {}).get("success"),
                "failure_class": "KERNEL_PASS" if attempt.get("kernel_result", {}).get("success") else mapping.get(
                    cause, "proof feasibility too low"), "diagnosis": cause})
    counts = Counter(row["failure_class"] for row in redesign_cases)
    redesign = {"schema": "rtl2lean-bridge_discovery-redesign-failure-analysis-v1",
        "source_requirement": 11, "development_set_only": True, "case_count": len(redesign_cases),
        "distribution": dict(sorted(counts.items())), "cases": redesign_cases,
        "redesign_policy": ["show both available source and required target frontier",
            "require explicit explanation of the changed bridge", "utility-check every redesigned statement",
            "stop proof generation when redesigned utility remains LOW"],
        "rules_frozen_before_unseen_evaluation": True}
    return initial, redesign
