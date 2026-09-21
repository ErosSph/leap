"""Fixed BridgeSpecification and Global Bridge View extraction."""
from __future__ import annotations

import re
from typing import Any

from experiments.adaptive_proving.config import digest


def _scope(phases: int, has_prefix: bool) -> str:
    if phases >= 3: return "THREE_STAGE_LAST_ITEM"
    if phases == 2: return "TWO_STAGE_LAST_ITEM"
    if phases == 1: return "PREFIX_LAST_ITEM"
    return "SINGLE_STEP" if not has_prefix else "PREFIX"


def build_bridge_specification(task: dict[str, Any], gap: dict[str, Any]) -> dict[str, Any]:
    temporal = gap["temporal_structure"]
    phases = temporal["along_occurrences"]
    local = gap["available_local_relations"]
    has_last = temporal["append_singleton_occurrences"] > 0
    relation = (
        "LAST_STEP_GUARD" if phases and has_last and local else
        "LOCAL_STEP_TO_TRACE_LIFT" if phases and local else
        "STATE_UPDATE_TO_INVARIANT" if not phases and local else "TRACE_DECOMPOSITION"
    )
    target_frontier = [{"subgoal": row["structure"], "needs": row.get("reason", "closure")}
                       for row in gap["residual_uncovered_goals"]]
    required_shape = (
        "Along step guard s (prefix ++ [last]) → guard (exec step s prefix) last"
        if relation == "LAST_STEP_GUARD" else
        "A proposition that supplies a premise of a retrieved local-step theorem"
    )
    result = {
        "schema": "rtl2lean-bridge_discovery-bridge-specification-v1",
        "source_frontier": {
            "available_target_premises": gap["target_structure_ast"].get("premises", []),
            "retrieved_theorems": gap["theorem_dependency_frontier"],
            "local_relations": local,
        },
        "target_frontier": target_frontier,
        "available_premises": {
            "temporal_assumptions": phases,
            "local_step_relations": local,
            "state_fields": gap["referenced_state_fields"],
        },
        "required_conclusion_shape": required_shape,
        "missing_relation_class": relation,
        "temporal_scope": _scope(phases, has_last),
        "state_fields": gap["referenced_state_fields"],
        "candidate_requirements": [
            "Conclusion must provide the next premise needed by the target-side local-step relation.",
            "The statement must be strictly smaller than the complete Property.",
            "The source side may use only target premises and retrieved theorem signatures.",
            *( ["For a last-item trace, conclude the guard at the prefix endpoint and last input."]
               if relation == "LAST_STEP_GUARD" else []),
        ],
        "candidate_avoid": [
            "trace execution identities that do not conclude a target-side guard or state relation",
            "the complete target statement", "existing theorem duplicates", "DUT-specific conjunction wrappers",
        ],
        "input_provenance": ["Target AST", "ProofGapObservation", "dependency frontier",
                             "Lean residual goals", "temporal structure", "theorem signatures"],
        "challenge_specific_rules": False, "dut_specific_rules": False,
    }
    result["bridge_specification_sha256"] = digest(result)
    return result


def build_global_bridge_view(task: dict[str, Any], gap: dict[str, Any], bridge: dict[str, Any]) -> dict[str, Any]:
    ast = gap["target_structure_ast"]
    result = {
        "schema": "rtl2lean-bridge_discovery-global-bridge-view-v1",
        "property_structure": {
            "binders": ast["binders"], "premise_count": ast["premise_count"],
            "conclusion_kind": ast["conclusion_kind"],
            "conclusion_subgoals": ast["conclusion_subgoals"],
        },
        "current_proof_position": "foundation prover exhausted; local-step facts retrieved but target remains open",
        "final_target_requirements": bridge["target_frontier"],
        "dependency_frontier": gap["theorem_dependency_frontier"],
        "next_theorem_premise": bridge["required_conclusion_shape"],
        "temporal_phase_count": gap["temporal_structure"]["along_occurrences"],
        "bridge_source": bridge["source_frontier"],
        "bridge_target": bridge["target_frontier"],
        "global_warning": "A locally true rewrite is useless unless it advances this source-to-target bridge.",
    }
    result["global_bridge_view_sha256"] = digest(result)
    return result


def policy_manifest() -> dict[str, Any]:
    return {"schema": "rtl2lean-bridge_discovery-bridge-policy-v1",
            "classes": ["LOCAL_STEP_TO_TRACE_LIFT", "PHASE_TO_PHASE_BRIDGE",
                        "STATE_UPDATE_TO_INVARIANT", "LAST_STEP_GUARD", "TRACE_DECOMPOSITION"],
            "challenge_specific_rules": False, "dut_specific_rules": False}
