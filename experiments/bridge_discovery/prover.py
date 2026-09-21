"""Deterministic property prover and formal/diagnostic Lean gates for Req12."""
from __future__ import annotations

import re
from pathlib import Path
from typing import Any

from experiments.adaptive_proving.lean import check_source
from experiments.foundation_first.prover import (
    FOUNDATION_TACTICS, generic_multiphase_bridge_proof, kernel_gate, property_source,
    run_property_prover as run_r11_property_prover,
)


def _named_proofs(task: dict[str, Any]) -> list[tuple[str, str]]:
    rows: list[tuple[str, str]] = []
    for name in task.get("foundation_lemmas", []):
        if str(name).endswith("_local_step"):
            rows.extend([
                (f"exact_{name}", f"by exact {name}"),
                (f"apply_{name}", f"by intros <;> apply {name} <;> assumption"),
            ])
    return rows


def run_foundation_prover(project: Path, root: Path, task: dict[str, Any], timeout_s: int) -> dict[str, Any]:
    """Try exact named theorem reuse, then the frozen tactic portfolio."""
    named_attempts = []
    for index, (name, proof) in enumerate(_named_proofs(task), 1):
        checked = check_source(property_source(task, proof), project / task["model_dir"],
                               root / f"named_{index:02d}_{name}.lean", timeout_s)
        row = {"prover_rule": name, "proof_body": proof, "lean_result": checked}
        named_attempts.append(row)
        if checked["success"]:
            return {"success": True, "successful_rule": name, "successful_proof_body": proof,
                "proof_source": "EXISTING_FOUNDATION_LEMMA", "attempts": named_attempts,
                "named_theorem_reuse_attempts": named_attempts,
                "fixed_portfolio": [name for name, _ in FOUNDATION_TACTICS],
                "candidate_aware_generic_rule_enabled": False}
    result = run_r11_property_prover(project, root / "portfolio", task, timeout_s)
    result["named_theorem_reuse_attempts"] = named_attempts
    result["attempts"] = [*named_attempts, *result["attempts"]]
    result["proof_source"] = "FIXED_TACTIC_PORTFOLIO" if result["success"] else None
    return result


def run_property_retry(project: Path, root: Path, task: dict[str, Any], timeout_s: int,
                       lemma: dict[str, str] | None) -> dict[str, Any]:
    if lemma:
        structural = generic_multiphase_bridge_proof(task, lemma["lemma_name"], lemma["lemma_statement"])
        if structural:
            checked = check_source(property_source(task, structural, lemma), project / task["model_dir"],
                                   root / "attempt_01_generic_bridge.lean", timeout_s)
            row = {"attempt_index": 1, "prover_rule": "generic_multiphase_trace_bridge",
                   "proof_body": structural, "lean_result": checked}
            if checked["success"]:
                return {"success": True, "successful_rule": row["prover_rule"],
                    "successful_proof_body": structural, "attempts": [row],
                    "fixed_portfolio": [name for name, _ in FOUNDATION_TACTICS],
                    "candidate_aware_generic_rule_enabled": True}
    return run_r11_property_prover(project, root / "fallback", task, timeout_s, lemma)


def hypothetical_source(task: dict[str, Any], candidate: dict[str, str], proof: str) -> str:
    """Candidate is a local theorem parameter, never an axiom or admitted theorem."""
    # A theorem declaration with auto-implicit σ/ι is universe-polymorphic, whereas a
    # local theorem parameter is necessarily monomorphic.  Instantiate those two
    # conventional generic type names to this target's concrete state/input types so
    # the diagnostic faithfully checks the relevant theorem instance.
    target = task["statement"]
    input_match = re.search(r"List\s+([A-Za-z_][A-Za-z0-9_'.]*)", target)
    if not input_match:
        input_match = re.search(r"\((?:item|i|x)\s*:\s*([A-Za-z_][A-Za-z0-9_'.]*)\)", target)
    specialized = candidate["lemma_statement"]
    specialized = re.sub(r"(?<![A-Za-z0-9_'])σ(?![A-Za-z0-9_'])", task["state_type"], specialized)
    if input_match:
        specialized = re.sub(r"(?<![A-Za-z0-9_'])ι(?![A-Za-z0-9_'])", input_match.group(1), specialized)
    return "\n".join([
        f"import {task['context_import']}", "", "set_option maxRecDepth 100000",
        "set_option maxHeartbeats 8000000", "", f"namespace {task['module']}Verification",
        f"open {task['module']}", "",
        f"theorem {task['task_id']}__utility",
        f"    (candidate_bridge : {specialized}) : {task['statement']} := {proof}",
        "", f"end {task['module']}Verification", "",
    ])


def run_hypothetical_property(project: Path, root: Path, task: dict[str, Any],
                              candidate: dict[str, str], timeout_s: int) -> dict[str, Any]:
    attempts = []
    structural = generic_multiphase_bridge_proof(task, "candidate_bridge", candidate["lemma_statement"])
    # The foundation portfolio has already failed before Utility Gate. Repeating it
    # cannot measure candidate contribution, so only candidate-referencing rules run.
    tactics = [("generic_bridge_using_hypothesis", structural)] if structural else []
    for index, (name, proof) in enumerate(tactics, 1):
        result = check_source(hypothetical_source(task, candidate, proof),
                              project / task["model_dir"], root / f"attempt_{index:02d}_{name}.lean",
                              timeout_s)
        used = bool(re.search(r"\bcandidate_bridge\b", proof))
        attempts.append({"prover_rule": name, "proof_body": proof, "candidate_referenced": used,
                         "lean_result": result})
        if result["success"] and used:
            break
    successful = next((row for row in attempts if row["lean_result"]["success"]
                       and row["candidate_referenced"]), None)
    return {"success": successful is not None,
            "successful_rule": successful["prover_rule"] if successful else None,
            "successful_proof_body": successful["proof_body"] if successful else None,
            "candidate_used": successful is not None, "attempts": attempts,
            "diagnostic_only": True, "counts_as_kernel_pass": False,
            "eligible_for_verified_pool": False}


def run_delete_lemma_replay(project: Path, path: Path, task: dict[str, Any],
                            final_proof: str, timeout_s: int) -> dict[str, Any]:
    """Keep the successful property proof byte-for-byte and delete only its lemma."""
    result = check_source(property_source(task, final_proof, None), project / task["model_dir"], path, timeout_s)
    result["ablation"] = "DELETE_LEMMA_DECLARATION_KEEP_FINAL_PROPERTY_PROOF"
    return result


def formal_kernel_gate(project: Path, path: Path, task: dict[str, Any],
                       lemma: dict[str, str], timeout_s: int) -> dict[str, Any]:
    return kernel_gate(project, path, task, lemma, timeout_s)


def policy_manifest() -> dict[str, Any]:
    return {
        "schema": "rtl2lean-bridge_discovery-prover-policy-v1",
        "foundation_tactics": [name for name, _ in FOUNDATION_TACTICS],
        "named_foundation_theorem_reuse": True,
        "hypothetical_candidate_is_local_parameter": True,
        "hypothetical_result_is_not_formal_proof": True,
        "llm_generates_final_property_proof": False,
        "direct_arm_present": False,
    }
