"""Frozen deterministic property prover and Lean kernel gates."""
from __future__ import annotations

import re
from pathlib import Path
from typing import Any

from experiments.adaptive_proving.lean import check_source


FOUNDATION_TACTICS = [
    ("rfl", "by rfl"),
    ("simp", "by simp"),
    ("simp_all", "by simp_all"),
    ("grind", "by grind"),
    ("omega", "by omega"),
    ("aesop", "by aesop"),
    ("intros_simp_all", "by intros <;> simp_all"),
    ("intros_grind", "by intros <;> grind"),
    ("intros_aesop", "by intros <;> aesop"),
    ("intros_assumption", "by intros <;> first | assumption | constructor <;> assumption"),
]


def _header(task: dict[str, Any]) -> list[str]:
    return [
        f"import {task['context_import']}", "", "set_option maxRecDepth 100000",
        "set_option maxHeartbeats 8000000", "", f"namespace {task['module']}Verification",
        f"open {task['module']}", "",
    ]


def property_source(task: dict[str, Any], proof: str, lemma: dict[str, str] | None = None) -> str:
    rows = _header(task)
    if lemma:
        rows.extend([f"theorem {lemma['lemma_name']} : {lemma['lemma_statement']} := {lemma['proof_body']}", ""])
    rows.extend([f"theorem {task['task_id']} : {task['statement']} := {proof}", "",
                 f"end {task['module']}Verification", ""])
    return "\n".join(rows)


def lemma_source(task: dict[str, Any], lemma: dict[str, str]) -> str:
    return "\n".join([*_header(task),
        f"theorem {lemma['lemma_name']} : {lemma['lemma_statement']} := {lemma['proof_body']}", "",
        f"end {task['module']}Verification", ""])


def _binder_names(statement: str) -> list[str]:
    prefix = statement.split("), R3Temporal.", 1)[0] + ")"
    return re.findall(r"\(([A-Za-z_][A-Za-z0-9_']*)\s*:", prefix)


def generic_multiphase_bridge_proof(
    task: dict[str, Any], lemma_name: str, lemma_statement: str,
) -> str | None:
    """Build a DUT-independent proof for repeated Along endpoint phases.

    The algorithm depends only on binder order and the retrieved local-step list,
    never on a challenge identifier, DUT name, or state-field spelling.
    """
    # Triple-phase manifests also list the generic r3_run_append theorem.
    # Only local-step relations correspond one-to-one with temporal phases.
    phase_lemmas = [name for name in task.get("foundation_lemmas", [])
                    if str(name).endswith("_local_step")]
    phases = task["statement"].count("R3Temporal.Along")
    binders = _binder_names(task["statement"])
    if phases < 1 or phases != len(phase_lemmas) or len(binders) != 1 + 2 * phases:
        return None
    candidate_binders = re.findall(
        r"\(([A-Za-z_][A-Za-z0-9_']*)\s*:\s*[^()]+\)", lemma_statement
    )
    if not candidate_binders:
        return None
    candidate_args = " ".join("_" for _ in candidate_binders)
    hypotheses = [f"h{index}" for index in range(1, phases + 1)]
    lines = ["by", "  intro " + " ".join([*binders, *hypotheses])]

    def goal(index: int, indent: str) -> None:
        if index < phases - 1:
            lines.append(indent + "constructor")
            lines.append(indent + "· rw [r3_run_append]")
            lines.append(indent + f"  apply {phase_lemmas[index]}")
            lines.append(indent + f"  exact {lemma_name} {candidate_args} {hypotheses[index]}")
            lines.append(indent + "·")
            goal(index + 1, indent + "  ")
        else:
            lines.append(indent + "rw [r3_run_append]")
            lines.append(indent + f"apply {phase_lemmas[index]}")
            lines.append(indent + f"exact {lemma_name} {candidate_args} {hypotheses[index]}")

    goal(0, "  ")
    return "\n".join(lines)


def run_property_prover(
    project: Path, root: Path, task: dict[str, Any], timeout_s: int,
    lemma: dict[str, str] | None = None,
) -> dict[str, Any]:
    attempts = []
    tactics = list(FOUNDATION_TACTICS)
    if lemma:
        structural = generic_multiphase_bridge_proof(task, lemma["lemma_name"], lemma["lemma_statement"])
        if structural:
            tactics.append(("generic_multiphase_trace_bridge", structural))
    for index, (name, proof) in enumerate(tactics, 1):
        result = check_source(
            property_source(task, proof, lemma), project / task["model_dir"],
            root / f"attempt_{index:02d}_{name}.lean", timeout_s,
        )
        attempts.append({"attempt_index": index, "prover_rule": name, "proof_body": proof,
                         "lean_result": result})
        if result["success"]:
            break
    successful = next((row for row in attempts if row["lean_result"]["success"]), None)
    return {
        "success": successful is not None,
        "successful_rule": successful["prover_rule"] if successful else None,
        "successful_proof_body": successful["proof_body"] if successful else None,
        "attempts": attempts,
        "fixed_portfolio": [name for name, _ in FOUNDATION_TACTICS],
        "candidate_aware_generic_rule_enabled": lemma is not None,
    }


def kernel_gate(project: Path, root: Path, task: dict[str, Any], lemma: dict[str, str], timeout_s: int) -> dict[str, Any]:
    return check_source(lemma_source(task, lemma), project / task["model_dir"], root, timeout_s)


def prover_policy_manifest() -> dict[str, Any]:
    return {
        "schema": "rtl2lean-foundation_first-prover-policy-v1",
        "foundation_tactic_portfolio": [name for name, _ in FOUNDATION_TACTICS],
        "candidate_aware_rule": "generic_multiphase_trace_bridge",
        "challenge_specific_rules": False,
        "llm_generates_final_property_proof": False,
        "same_foundation_portfolio_before_and_after_candidate": True,
    }
