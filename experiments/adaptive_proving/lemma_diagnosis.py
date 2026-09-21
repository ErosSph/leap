"""Challenge-independent candidate-lemma failure diagnosis.

The module is intentionally deterministic and local: it consumes Lean feedback
and structural relations, never a proof-model call or a challenge identifier.
"""
from __future__ import annotations

import re
import time
from dataclasses import asdict, dataclass
from difflib import SequenceMatcher
from typing import Any


PROOF_CAUSES = (
    "PROOF_SYNTAX_ERROR", "TACTIC_APPLICATION_FAILURE", "REWRITE_DIRECTION_ERROR",
    "THEOREM_APPLICATION_MISMATCH", "TYPE_MISMATCH", "PROOF_SEARCH_FAILURE",
    "INDUCTION_STATE_NOT_GENERALIZED", "TRACE_SINGLETON_NOT_DESTRUCTURED",
    "PROOF_IMPLEMENTATION_FAILURE",
)
STATEMENT_CAUSES = (
    "MISSING_PRECONDITION", "STATEMENT_TOO_STRONG", "WRONG_CONCLUSION",
    "STATEMENT_DIRECTION_MISMATCH", "QUANTIFIER_MISMATCH", "STATE_SCOPE_MISMATCH",
    "TIME_SCOPE_MISMATCH", "UNSUPPORTED_BY_AVAILABLE_CONTEXT", "COUNTEREXAMPLE_FOUND",
    "MALFORMED_LEMMA_DECLARATION", "UNKNOWN_STATEMENT_FAILURE",
)
SELECTION_CAUSES = (
    "LEMMA_IRRELEVANT_TO_TARGET", "LEMMA_TOO_CLOSE_TO_TARGET", "CIRCULAR_DECOMPOSITION",
    "WRONG_BRIDGE_LEMMA", "LOW_TARGET_UTILITY", "LEMMA_SELECTION_FAILURE",
)
ALL_CAUSES = (*PROOF_CAUSES, *STATEMENT_CAUSES, *SELECTION_CAUSES, "UNKNOWN")


@dataclass(frozen=True)
class LemmaDiagnosisReport:
    failure_level: str
    primary_cause: str
    secondary_causes: list[str]
    statement_plausibility: str
    target_relevance: str
    proof_progress: str
    recommended_action: str
    evidence: list[str]
    repair_guidance: list[str]
    redesign_guidance: list[str]
    core_unsolved_goal: str
    goal_similarity_to_previous: float | None
    avoided_invalid_repair: bool
    diagnosis_time_s: float

    def serializable(self) -> dict[str, Any]:
        return asdict(self)


IGNORED = {
    "theorem", "def", "fun", "forall", "true", "false", "prop", "type", "list",
    "bitvec", "nat", "and", "or", "not", "intro", "exact", "have", "show", "from",
}


def _tokens(value: str) -> set[str]:
    return {
        token.lower() for token in re.findall(r"[A-Za-z_][A-Za-z0-9_']*", value)
        if len(token) >= 3 and token.lower() not in IGNORED
    }


def _normalized(value: str) -> str:
    return re.sub(r"\s+", "", value)


def _core_goal(proof_states: list[str], lean_errors: list[str]) -> str:
    for value in reversed(proof_states):
        if value.strip():
            return value.strip()[-8000:]
    joined = "\n".join(lean_errors)
    match = re.search(r"(?ms)(⊢.*?)(?=\n[^\n]*:\d+:\d+: error:|\Z)", joined)
    return match.group(1).strip()[-8000:] if match else ""


def _relevance(target: str, lemma: str) -> tuple[str, float]:
    target_tokens, lemma_tokens = _tokens(target), _tokens(lemma)
    if not target_tokens or not lemma_tokens:
        return "LOW", 0.0
    coverage = len(target_tokens & lemma_tokens) / len(target_tokens)
    return ("HIGH" if coverage >= 0.45 else "MEDIUM" if coverage >= 0.18 else "LOW"), coverage


def _error_cause(text: str) -> str:
    lowered = text.lower()
    if (("after simplification" in lowered and "r3temporal.along" in lowered
         and "guard" in lowered)
            or ("case nil" in lowered and "r3temporal.along" in lowered
                and re.search(r"⊢\s*guard\b", lowered))):
        return "TRACE_SINGLETON_NOT_DESTRUCTURED"
    if (re.search(r"has type\s+r3temporal\.along.*?\(step\s+", lowered, re.S)
            and re.search(r"expected to have type\s+r3temporal\.along", lowered, re.S)):
        return "INDUCTION_STATE_NOT_GENERALIZED"
    if "counterexample" in lowered:
        return "COUNTEREXAMPLE_FOUND"
    if any(marker in lowered for marker in (
        "unexpected token", "parser error", "unexpected end of input", "invalid syntax",
    )):
        return "PROOF_SYNTAX_ERROR"
    if any(marker in lowered for marker in (
        "rewrite tactic failed", "did not find instance of the pattern", "pattern is a metavariable",
    )):
        return "REWRITE_DIRECTION_ERROR"
    if any(marker in lowered for marker in (
        "application type mismatch", "function expected at", "invalid argument name",
        "unknown constant", "unknown identifier",
    )):
        return "THEOREM_APPLICATION_MISMATCH"
    if any(marker in lowered for marker in (
        "type mismatch", "failed to synthesize", "application mismatch", "invalid field",
    )):
        return "TYPE_MISMATCH"
    if any(marker in lowered for marker in (
        "unknown tactic", "tactic execution failed", "tactic '" , "tactic `",
    )):
        return "TACTIC_APPLICATION_FAILURE"
    if any(marker in lowered for marker in (
        "unsolved goals", "made no progress", "could not prove", "no goals to be solved",
    )):
        return "PROOF_SEARCH_FAILURE"
    if any(marker in lowered for marker in (
        "must be a non-empty", "must begin with", "structured response", "forbidden unchecked",
        "safe identifier", "schema validation",
    )):
        return "PROOF_IMPLEMENTATION_FAILURE"
    return "PROOF_IMPLEMENTATION_FAILURE" if text.strip() else "UNKNOWN"


def diagnose_lemma(
    target: str,
    candidate_lemma: dict[str, Any],
    proof_attempts: list[dict[str, Any]],
    lean_errors: list[str],
    proof_states: list[str],
    local_context: str,
    theorem_base: list[dict[str, Any]],
    verified_context: list[dict[str, Any]],
) -> LemmaDiagnosisReport:
    """Diagnose one failed lemma and choose REPAIR/REDESIGN/ABORT/UNKNOWN."""
    started = time.perf_counter()
    name = str(candidate_lemma.get("lemma_name") or "")
    statement = str(candidate_lemma.get("lemma_statement") or "")
    proof = str(candidate_lemma.get("proof_body") or "")
    # The primary cause must describe the current candidate.  Earlier errors
    # are retained separately for progress/stall comparison, never allowed to
    # overwrite the latest failure classification.
    current_error = (lean_errors[-1] if lean_errors else "")[-24000:]
    current_goal = _core_goal(proof_states[-1:], lean_errors[-1:])
    relevance, coverage = _relevance(target, statement)
    evidence = [f"target_token_coverage={coverage:.3f}"]
    secondary: list[str] = []
    repair: list[str] = []
    redesign: list[str] = []
    plausibility = "UNKNOWN"
    previous_goal = ""
    previous_action = None
    if len(proof_attempts) >= 2:
        prior = proof_attempts[-2]
        previous_goal = str(prior.get("proof_state") or "")
        previous_action = (prior.get("diagnosis") or {}).get("recommended_action")
    similarity = None
    progress = "UNKNOWN"
    if previous_goal and current_goal:
        similarity = SequenceMatcher(None, _normalized(previous_goal), _normalized(current_goal)).ratio()
        if similarity >= 0.96:
            progress = "STALLED"
        elif len(_normalized(current_goal)) < len(_normalized(previous_goal)) * 0.8:
            progress = "PROGRESS"
        elif len(_normalized(current_goal)) > len(_normalized(previous_goal)) * 1.25:
            progress = "REGRESSED"
        else:
            progress = "PROGRESS"
        evidence.append(f"core_goal_similarity_to_previous={similarity:.3f}")
    if len(proof_attempts) >= 2:
        previous_candidate = proof_attempts[-2].get("candidate") or {}
        if (_normalized(str(previous_candidate.get("proof_body") or ""))
                and _normalized(str(previous_candidate.get("proof_body") or "")) == _normalized(proof)):
            progress = "STALLED"
            evidence.append("candidate proof_body is identical to the previous failed attempt")

    normalized_target, normalized_statement = _normalized(target), _normalized(statement)
    lean_cause = _error_cause(current_error)
    if re.match(r"^\s*(?:theorem|lemma)\b", statement) or ":=" in statement:
        level, cause, action = "STATEMENT", "MALFORMED_LEMMA_DECLARATION", "REDESIGN"
        plausibility = "LOW"
        evidence.append("lemma_statement contains a declaration header/body instead of only a proposition")
        redesign.append("Return only the proposition after the declaration colon in lemma_statement.")
    elif not statement or not name:
        level, cause, action = "STATEMENT", "UNKNOWN_STATEMENT_FAILURE", "REDESIGN"
        plausibility = "LOW"
        evidence.append("candidate name or statement is empty")
        redesign.append("Generate a well-typed, fresh bridge theorem with an explicit proposition.")
    elif normalized_statement == normalized_target:
        level, cause, action = "SELECTION", "LEMMA_TOO_CLOSE_TO_TARGET", "REDESIGN"
        plausibility = "HIGH"
        evidence.append("candidate proposition is whitespace-equivalent to the complete target")
        redesign.append("Choose a strict sub-result needed by, but not identical to, the target.")
    elif re.search(rf"(?<![A-Za-z0-9_']){re.escape(name)}(?![A-Za-z0-9_'])", proof):
        level, cause, action = "SELECTION", "CIRCULAR_DECOMPOSITION", "REDESIGN"
        plausibility = "UNKNOWN"
        evidence.append("candidate proof refers to the theorem currently being defined")
        redesign.append("Select an acyclic bridge supported only by the frozen theorem base.")
    elif "counterexample" in current_error.lower():
        level, cause, action = "STATEMENT", "COUNTEREXAMPLE_FOUND", "REDESIGN"
        plausibility = "LOW"
        evidence.append("Lean/local checker feedback contains counterexample evidence")
        redesign.append("Weaken or condition the statement to exclude the demonstrated counterexample.")
    elif lean_cause in PROOF_CAUSES and lean_cause != "PROOF_SEARCH_FAILURE":
        level, cause, action, plausibility = "PROOF", lean_cause, "REPAIR", "HIGH"
        evidence.append(f"lean_feedback_class={cause}")
        repair.append("Keep the exact lemma name and statement; modify proof_body only.")
        repair.append("Address the reported Lean goal and error using only frozen declarations.")
    elif relevance == "LOW":
        level, cause, action = "SELECTION", "LOW_TARGET_UTILITY", "REDESIGN"
        plausibility = "UNKNOWN"
        evidence.append("candidate shares too little semantic vocabulary with the target")
        redesign.append("Select a bridge mentioning the target's transition, trace, or state relation.")
    elif ("R3Temporal.Along" in target or "r3Run" in target) and not (
        "R3Temporal.Along" in statement or "r3Run" in statement or "r3Step" in statement
    ):
        level, cause, action = "STATEMENT", "TIME_SCOPE_MISMATCH", "REDESIGN"
        plausibility = "LOW"
        evidence.append("temporal target has no transition/trace anchor in candidate statement")
        redesign.append("State a bridge at the required trace prefix or transition endpoint.")
    elif statement.count("∀") > target.count("∀") + 2:
        level, cause, action = "STATEMENT", "QUANTIFIER_MISMATCH", "REDESIGN"
        plausibility = "LOW"
        evidence.append("candidate introduces substantially more universal scope than the target")
        redesign.append("Restrict quantification to the state, prefix, and endpoint needed by the target.")
    else:
        cause = lean_cause
        if cause in PROOF_CAUSES:
            level, action, plausibility = "PROOF", "REPAIR", "HIGH"
            repair.append("Keep the exact lemma name and statement; modify proof_body only.")
            repair.append("Address the reported Lean goal and error using only frozen declarations.")
        elif cause in STATEMENT_CAUSES:
            level, action, plausibility = "STATEMENT", "REDESIGN", "LOW"
            redesign.append("Replace the proposition with a weaker or correctly scoped target bridge.")
        else:
            level, action = "UNKNOWN", "UNKNOWN"
        evidence.append(f"lean_feedback_class={cause}")

    # A proof-level repair that returns the same core goal has supplied evidence
    # that another blind proof repair is low value. Escalate to decomposition redesign.
    if action == "REPAIR" and progress == "STALLED" and previous_action == "REPAIR":
        secondary.append(cause)
        level, cause, action = "SELECTION", "LEMMA_SELECTION_FAILURE", "REDESIGN"
        evidence.append("a diagnosis-guided proof repair left the core goal materially unchanged")
        repair = []
        redesign.extend([
            "Abandon the stalled statement instead of repeating the same proof repair.",
            "Choose a smaller bridge whose conclusion directly closes one target subgoal.",
        ])

    if action == "REPAIR":
        if cause == "REWRITE_DIRECTION_ERROR":
            repair.append("Reverse or localize the failing rewrite; inspect the exact goal orientation.")
        elif cause == "THEOREM_APPLICATION_MISMATCH":
            repair.append("Instantiate theorem arguments in declared order and satisfy every premise explicitly.")
        elif cause == "TYPE_MISMATCH":
            repair.append("Align inferred state/prefix types with the expected Lean goal before applying the theorem.")
        elif cause == "INDUCTION_STATE_NOT_GENERALIZED":
            repair.extend([
                "Generalize the evolving state before induction over the input prefix.",
                "Ensure the induction hypothesis accepts the successor state produced by step.",
            ])
        elif cause == "TRACE_SINGLETON_NOT_DESTRUCTURED":
            repair.extend([
                "In the empty-prefix case, unfold or destructure Along on the singleton trace.",
                "Use the first conjunct as the final guard fact; simplify exec on the empty prefix separately.",
            ])
        elif cause == "PROOF_SEARCH_FAILURE":
            repair.append("Decompose the current goal and prove the displayed unsolved subgoals explicitly.")
    elif action == "REDESIGN" and not redesign:
        redesign.append("Generate one alternative L2 bridge guided by the failure evidence.")

    known_names = {str(row.get("name")) for row in theorem_base}
    referenced = _tokens(proof) & {name.lower() for name in known_names}
    if cause == "THEOREM_APPLICATION_MISMATCH" and not referenced:
        secondary.append("UNSUPPORTED_BY_AVAILABLE_CONTEXT")
    if verified_context:
        evidence.append(f"verified_context_count={len(verified_context)}")
    evidence.append(f"local_context_chars={len(local_context)}")
    evidence.append(f"proof_attempt_count={len(proof_attempts)}")

    return LemmaDiagnosisReport(
        failure_level=level,
        primary_cause=cause if cause in ALL_CAUSES else "UNKNOWN",
        secondary_causes=list(dict.fromkeys(secondary)),
        statement_plausibility=plausibility,
        target_relevance=relevance,
        proof_progress=progress,
        recommended_action=action,
        evidence=evidence,
        repair_guidance=repair,
        redesign_guidance=redesign,
        core_unsolved_goal=current_goal,
        goal_similarity_to_previous=similarity,
        avoided_invalid_repair=action == "REDESIGN" and level in {"STATEMENT", "SELECTION"},
        diagnosis_time_s=time.perf_counter() - started,
    )


def taxonomy_manifest() -> dict[str, Any]:
    return {
        "proof_level": list(PROOF_CAUSES),
        "statement_level": list(STATEMENT_CAUSES),
        "selection_level": list(SELECTION_CAUSES),
        "unknown": ["UNKNOWN"],
    }
