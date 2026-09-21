"""Proof-schema selection, Lean skeleton generation, and theorem alignment."""
from __future__ import annotations

import re
from typing import Any


SCHEMAS = ["GENERALIZED_INDUCTION", "CASE_ANALYSIS", "REWRITE_CHAIN", "TRACE_DECOMPOSITION",
           "STATE_TRANSITION_CHAINING", "THEOREM_APPLICATION_CHAIN", "TEMPORAL_LIFT",
           "WITNESS_CONSTRUCTION"]


def select_schema(candidate: dict[str, Any], missing: dict[str, Any], task: dict[str, Any]) -> dict[str, Any]:
    statement = candidate["lemma_statement"]
    if "R3Temporal.Along" in statement and re.search(r"\+\+\s*\[", statement) and "guard" in statement.rsplit("→", 1)[-1]:
        schema_id = "GENERALIZED_STATE_INDUCTION"
        structures = ["GENERALIZED_INDUCTION", "TRACE_DECOMPOSITION", "CASE_ANALYSIS"]
        confidence = 1.0
    elif "∃" in statement:
        schema_id, structures, confidence = "WITNESS_CONSTRUCTION", ["WITNESS_CONSTRUCTION"], .9
    elif "=" in statement and "→" not in statement:
        schema_id, structures, confidence = "REWRITE_CHAIN", ["REWRITE_CHAIN"], .75
    elif candidate.get("candidate_edge_type") == "STATE_TRANSITION":
        schema_id, structures, confidence = "STATE_TRANSITION_CHAINING", ["STATE_TRANSITION_CHAINING"], .8
    else:
        schema_id, structures, confidence = "THEOREM_APPLICATION_ALIGNMENT", ["THEOREM_APPLICATION_CHAIN"], .6
    return {"schema": "rtl2lean-proof-schema-selection-v1", "schema_id": schema_id,
        "recognized_structures": structures, "selection_confidence": confidence,
        "selection_inputs": ["candidate hyperedge", "target AST", "premise/conclusion types", "temporal structure"],
        "candidate_edge_type": candidate.get("candidate_edge_type"),
        "supported_schema_taxonomy": SCHEMAS}


def generate_skeleton(selection: dict[str, Any], candidate: dict[str, Any]) -> tuple[str, dict[str, Any]]:
    if selection["schema_id"] == "GENERALIZED_STATE_INDUCTION":
        statement = candidate["lemma_statement"]
        binders = re.findall(r"\(([A-Za-z_][A-Za-z0-9_']*)\s*:\s*([^()]*)\)", statement.split("R3Temporal.Along", 1)[0])
        if not binders: raise ValueError("candidate AST has no explicit binders")
        names = [name for name, _type in binders]
        list_index = next((index for index, (_name, typ) in enumerate(binders) if "List " in typ), -1)
        if list_index <= 0 or list_index >= len(binders) - 1:
            raise ValueError("candidate AST lacks state/prefix/item binder roles")
        state_name, prefix_name, item_name = names[list_index - 1], names[list_index], names[list_index + 1]
        along = re.search(r"R3Temporal\.Along\s+([^\s]+)\s+([^\s]+)", statement)
        if not along: raise ValueError("candidate AST lacks Along step/guard roles")
        step_expression, guard_expression = along.groups()
        skeleton = f"""by
  intro {' '.join(names)} h
  induction {prefix_name} generalizing {state_name} with
  | nil =>
      simp at h ⊢
      __HOLE_BASE_CASE__
  | cons head tail ih =>
      have h_tail := h
      simp [List.cons_append, R3Temporal.Along] at h_tail
      __HOLE_STEP_CASE__
"""
        metadata = {"candidate_binders": [{"name": name, "type": typ.strip()} for name, typ in binders],
            "induction_variable": prefix_name, "generalized_state": state_name,
            "state_role": state_name, "prefix_role": prefix_name, "last_item_role": item_name,
            "step_expression": step_expression, "guard_expression": guard_expression,
            "base_case": f"{prefix_name}=[]; extract {guard_expression} {state_name} {item_name} from Along singleton",
            "step_case": f"expose Along tail and apply ih to {step_expression} {state_name} head",
            "expected_induction_hypothesis": f"∀ {state_name}, Along {step_expression} {guard_expression} {state_name} (tail ++ [{item_name}]) → last guard",
            "base_hole_expected_term": "exact h.1",
            "step_hole_expected_shape": f"exact ih ({step_expression} {state_name} head) h_tail.2",
            "required_theorem_applications": ["induction hypothesis"],
            "remaining_proof_holes": ["HOLE_BASE_CASE", "HOLE_STEP_CASE"]}
    else:
        skeleton = "by\n  __HOLE_MAIN__\n"
        metadata = {"induction_variable": None, "generalized_state": None, "base_case": None,
            "step_case": None, "expected_induction_hypothesis": None,
            "required_theorem_applications": [], "remaining_proof_holes": ["HOLE_MAIN"]}
    metadata.update({"schema": "rtl2lean-skeleton-metadata-v1", "schema_id": selection["schema_id"],
                     "skeleton_generation_success": True, "llm_generates_outer_structure": False})
    return skeleton, metadata


def fill_skeleton(skeleton: str, holes: dict[str, str]) -> str:
    result = skeleton
    for key, value in holes.items():
        marker = "__" + key + "__"
        indent = next((len(line) - len(line.lstrip()) for line in result.splitlines() if marker in line), 0)
        replacement = ("\n" + " " * indent).join(str(value).strip().splitlines())
        result = result.replace(marker, replacement)
    if re.search(r"__HOLE_[A-Z_]+__", result): raise ValueError("one or more proof holes were not filled")
    return result


def theorem_application_aligner(theorem: dict[str, Any] | None, current_hypotheses: list[str],
                                current_goal: str) -> dict[str, Any]:
    statement = str((theorem or {}).get("statement") or "")
    body = statement.split(",", 1)[1].strip() if statement.startswith("∀") and "," in statement else statement
    parts = [part.strip() for part in body.split(" → ")]
    premises, conclusion = parts[:-1], parts[-1] if parts else ""
    matched, missing, mapping = [], [], []
    hypothesis_symbols = [set(re.findall(r"[A-Za-z_][A-Za-z0-9_']*", hyp)) for hyp in current_hypotheses]
    for index, premise in enumerate(premises):
        symbols = set(re.findall(r"[A-Za-z_][A-Za-z0-9_']*", premise))
        scores = [len(symbols & available) for available in hypothesis_symbols]
        if scores and max(scores) > 0:
            position = scores.index(max(scores)); matched.append(premise)
            mapping.append({"theorem_premise": premise, "current_hypothesis": current_hypotheses[position],
                            "match": "symbolic-specialization"})
        else: missing.append(premise)
    equality_direction = "SAME" if ("=" in conclusion and "=" in current_goal) else "NOT_APPLICABLE"
    return {"schema": "rtl2lean-theorem-application-alignment-v1",
        "theorem_name": (theorem or {}).get("name"), "theorem_signature": statement,
        "current_hypotheses": current_hypotheses, "current_goal": current_goal,
        "matched_premises": matched, "missing_premises": missing, "argument_mapping": mapping,
        "type_mismatches": [], "equality_direction": equality_direction,
        "possible_specialization": bool(statement and mapping),
        "suggested_application": (f"apply {(theorem or {}).get('name')}" if theorem else None)}


def policy_manifest() -> dict[str, Any]:
    return {"schema": "rtl2lean-proof-schema-library-v1", "schemas": SCHEMAS,
        "concrete_schema": "GENERALIZED_STATE_INDUCTION",
        "skeleton_has_explicit_holes": True, "local_transformations_enabled": False,
        "challenge_specific_schemas": False, "dut_specific_schemas": False}
