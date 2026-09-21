"""Deterministic, challenge-independent proof-gap extraction."""
from __future__ import annotations

import re
from typing import Any

from experiments.adaptive_proving.config import digest


IDENT_RE = re.compile(r"[A-Za-z_][A-Za-z0-9_'.]*")
FIELD_RE = re.compile(r"\.([A-Za-z_][A-Za-z0-9_']*)")
IGNORED = {"theorem", "true", "false", "prop", "list", "forall", "comb"}


def _tokens(text: str) -> set[str]:
    return {token.rsplit(".", 1)[-1] for token in IDENT_RE.findall(text)
            if token.lower() not in IGNORED and len(token) > 1}


def _binders(statement: str) -> list[dict[str, str]]:
    prefix = statement.split("), R3Temporal.", 1)[0] + ")"
    return [{"name": name, "type": typ.strip()} for name, typ in
            re.findall(r"\(([A-Za-z_][A-Za-z0-9_']*)\s*:\s*([^()]*)\)", prefix)]


def _top_level_parts(text: str, separator: str) -> list[str]:
    parts, start, depth = [], 0, 0
    i = 0
    while i < len(text):
        char = text[i]
        if char in "([{" :
            depth += 1
        elif char in ")]}":
            depth = max(0, depth - 1)
        if depth == 0 and text.startswith(separator, i):
            parts.append(text[start:i].strip())
            start = i + len(separator)
            i += len(separator)
            continue
        i += 1
    parts.append(text[start:].strip())
    return [part for part in parts if part]


def _conclusion(statement: str) -> str:
    parts = _top_level_parts(statement, " → ")
    return parts[-1] if parts else statement


def _strip_outer(text: str) -> str:
    value = text.strip()
    while value.startswith("(") and value.endswith(")"):
        depth, valid = 0, True
        for index, char in enumerate(value):
            depth += char == "("
            depth -= char == ")"
            if depth == 0 and index != len(value) - 1:
                valid = False
                break
        if not valid:
            break
        value = value[1:-1].strip()
    return value


def _conjuncts(text: str) -> list[str]:
    value = _strip_outer(text)
    parts = _top_level_parts(value, " ∧ ")
    if len(parts) == 1:
        return [value]
    return [_strip_outer(parts[0]), *_conjuncts(" ∧ ".join(parts[1:]))]


def retrieve_lemmas(target: str, theorem_base: list[dict[str, Any]], limit: int) -> list[dict[str, Any]]:
    target_tokens = _tokens(target)
    fields = set(FIELD_RE.findall(target))
    rows = []
    for theorem in theorem_base:
        statement = str(theorem.get("statement") or "")
        theorem_tokens = _tokens(statement) | _tokens(str(theorem.get("name") or ""))
        overlap = target_tokens & theorem_tokens
        field_overlap = fields & theorem_tokens
        score = len(overlap) + 4 * len(field_overlap)
        if str(theorem.get("name")) in target:
            score += 8
        if score:
            rows.append({
                "name": theorem.get("name"), "statement": statement,
                "source_file": theorem.get("source_file"), "score": score,
                "matched_symbols": sorted(overlap), "matched_state_fields": sorted(field_overlap),
            })
    return sorted(rows, key=lambda row: (-row["score"], str(row["name"])))[:limit]


def extract_proof_gap(
    task: dict[str, Any], theorem_base: list[dict[str, Any]], retrieved: list[dict[str, Any]],
    foundation_result: dict[str, Any], policy_version: str,
) -> dict[str, Any]:
    """Explain a failed foundation proof without answer metadata or task-specific rules."""
    target = task["statement"]
    conclusion = _conclusion(target)
    subgoals = _conjuncts(conclusion)
    target_symbols = sorted(_tokens(target))
    fields = sorted(set(task.get("required_state_fields", [])) | set(FIELD_RE.findall(target)))
    temporal = {
        "along_occurrences": target.count("R3Temporal.Along"),
        "run_occurrences": len(re.findall(r"\br3Run\b", target)),
        "append_singleton_occurrences": len(re.findall(r"\+\+\s*\[", target)),
        "implication_count": len(_top_level_parts(target, " → ")) - 1,
        "conjunct_count": len(subgoals),
    }
    local = [row for row in retrieved if str(row["name"]).endswith("_local_step")]
    covered, residual = [], []
    for index, goal in enumerate(subgoals, 1):
        goal_fields = set(FIELD_RE.findall(goal))
        support = [row["name"] for row in local if goal_fields & set(row["matched_state_fields"])]
        row = {"subgoal_index": index, "structure": goal, "supporting_local_relations": support}
        (covered if support else residual).append(row)
    lean_attempts = foundation_result.get("attempts", [])
    unsolved = []
    for attempt in lean_attempts:
        unsolved.extend((attempt.get("lean_result") or {}).get("unsolved_goals", []))
    unsolved = list(dict.fromkeys(goal for goal in unsolved if goal))[-8:]
    has_trace_endpoint_shape = (
        temporal["along_occurrences"] > 0 and temporal["append_singleton_occurrences"] > 0
        and bool(local)
    )
    missing_class = (
        "TRACE_LAST_STEP_LIFT" if has_trace_endpoint_shape else
        "THEOREM_COMPOSITION" if len(subgoals) > 1 else "UNCLASSIFIED_PROOF_GAP"
    )
    requirements = []
    if has_trace_endpoint_shape:
        requirements.extend([
            "Bridge Along over a prefix-plus-singleton trace to the guard at the state after the prefix.",
            "Prefer one reusable theorem quantified over guard, state, prefix, and final input.",
            "Make the bridge usable with the retrieved local_step relations and r3_run_append.",
        ])
    else:
        requirements.append("Prove one strict intermediate relation that closes an uncovered target subgoal.")
    result = {
        "schema": "rtl2lean-foundation_first-proof-gap-observation-v1",
        "policy_version": policy_version,
        "policy_input_fields": ["target", "theorem_base", "retrieved_lemmas", "foundation_lean_feedback"],
        "forbidden_input_fields": ["challenge_id", "reference_proof", "gap_spec", "human_candidate_lemma"],
        "target_structure_ast": {
            "kind": "FORALL_IMPLICATION_CHAIN",
            "binders": _binders(target),
            "premise_count": temporal["implication_count"],
            "conclusion_kind": "CONJUNCTION" if len(subgoals) > 1 else "ATOMIC",
            "conclusion_subgoals": subgoals,
        },
        "target_symbols": target_symbols,
        "referenced_state_fields": fields,
        "retrieved_lemmas": retrieved,
        "covered_subgoals": covered,
        "residual_uncovered_goals": residual or [
            {"subgoal_index": row["subgoal_index"], "structure": row["structure"],
             "reason": "local relation exists but temporal endpoint lift was not closed"}
            for row in covered
        ],
        "theorem_dependency_frontier": [row["name"] for row in retrieved[:8]],
        "temporal_structure": temporal,
        "available_local_relations": [row["name"] for row in local],
        "missing_relation_class": missing_class,
        "lean_unsolved_goals": unsolved,
        "evidence": [
            f"fixed_foundation_attempts={len(lean_attempts)}",
            f"retrieved_lemmas={len(retrieved)}",
            f"local_step_relations={len(local)}",
            f"trace_phases={temporal['along_occurrences']}",
            "all fixed Foundation-Only tactics failed Lean verification",
        ],
        "candidate_requirements": requirements,
        "candidate_avoid_rules": [
            "Do not restate the complete target or its full conjunction.",
            "Do not duplicate an existing theorem statement.",
            "Do not use sorry, admit, native_decide, unsafe, or axioms.",
            "Do not depend on challenge-specific names when a quantified trace bridge is possible.",
        ],
    }
    result["observation_sha256"] = digest(result)
    return result


def policy_manifest() -> dict[str, Any]:
    return {
        "schema": "rtl2lean-foundation_first-proof-gap-policy-v1",
        "algorithm": "lexical-AST plus theorem-token retrieval plus Lean residual goals",
        "challenge_specific_rules": False,
        "reads_reference_proof": False,
        "reads_gap_spec": False,
        "missing_relation_classes": ["TRACE_LAST_STEP_LIFT", "THEOREM_COMPOSITION", "UNCLASSIFIED_PROOF_GAP"],
    }
