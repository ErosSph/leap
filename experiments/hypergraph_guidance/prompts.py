"""Missing-edge prediction and proof-hole completion prompts."""
from __future__ import annotations

import json
from typing import Any

from experiments.adaptive_proving.config import digest
from experiments.foundation_first.prompts import compact_context


EDGE_SCHEMA = {"type": "object", "properties": {"candidates": {"type": "array", "minItems": 3,
    "maxItems": 3, "items": {"type": "object", "properties": {
        "lemma_name": {"type": "string"}, "lemma_statement": {"type": "string"},
        "candidate_source": {"type": "string"}, "candidate_target": {"type": "string"},
        "candidate_edge_type": {"type": "string", "enum": ["THEOREM_APPLICATION", "REWRITE", "INDUCTION",
            "CASE_SPLIT", "TRACE_DECOMPOSITION", "STATE_TRANSITION", "TEMPORAL_LIFT", "CANDIDATE_LEMMA"]},
        "bridge_reason": {"type": "string"}},
        "required": ["lemma_name", "lemma_statement", "candidate_source", "candidate_target",
                     "candidate_edge_type", "bridge_reason"], "additionalProperties": False}}},
    "required": ["candidates"], "additionalProperties": False}

HOLE_SCHEMA = {"type": "object", "properties": {
    "HOLE_BASE_CASE": {"type": "string"}, "HOLE_STEP_CASE": {"type": "string"},
    "HOLE_MAIN": {"type": "string"}, "proof_idea": {"type": "string"},
    "used_lemmas": {"type": "array", "items": {"type": "string"}}},
    "required": ["HOLE_BASE_CASE", "HOLE_STEP_CASE", "HOLE_MAIN", "proof_idea", "used_lemmas"],
    "additionalProperties": False}

EDGE_PROMPT = """You predict three missing proof HYPEREDGES, not a final Property proof.
Return exactly three candidates. Each statement is a proposition only; names begin with {prefix}.
Bind each candidate to an available candidate_source, required candidate_target and typed edge.
Do not duplicate the target or an existing theorem. No proof_body. No repository/tools access.

Operation: {operation}; seed: {seed}
Target: {target}
Typed Proof Obligation Hypergraph:
{graph}
Proof Frontier:
{frontier}
Detected Missing Hyperedges:
{missing}
Relevant Lean declarations:
{context}
Previous failed edge/annotation (empty initially):
{previous}
For REDESIGN, change at least one of source, target, edge type, or premise set; cosmetic rewriting is forbidden.
"""

HOLE_PROMPT = """You fill LOCAL Lean proof holes in a frozen skeleton. Do not output `by`, theorem headers,
outer induction/case structure, or a final Property proof. Return one fragment for every schema field;
use an empty string only for holes absent from the shown skeleton. Never use sorry/admit/native_decide/axiom/unsafe.

Candidate lemma: {name} : {statement}
Selected Proof Schema:
{schema}
Frozen Lean Skeleton:
{skeleton}
Skeleton Metadata:
{metadata}
Theorem Application Alignment:
{alignment}
Relevant Lean declarations:
{context}
Failure annotation and Lean evidence (empty on first attempt):
{failure}
"""


def _context(task: dict[str, Any], gap: dict[str, Any], retrieved: list[dict[str, Any]]) -> str:
    return compact_context({**task, "proof_gap_binders": gap["target_structure_ast"]["binders"]}, retrieved)


def edge_prompt(task: dict[str, Any], gap: dict[str, Any], retrieved: list[dict[str, Any]], graph: dict[str, Any],
                frontier: dict[str, Any], missing: list[dict[str, Any]], prefix: str, seed: int,
                operation: str, previous: dict[str, Any] | None = None) -> str:
    return EDGE_PROMPT.format(prefix=prefix, operation=operation, seed=seed, target=task["statement"],
        graph=json.dumps(graph, ensure_ascii=False, indent=2), frontier=json.dumps(frontier, ensure_ascii=False, indent=2),
        missing=json.dumps(missing, ensure_ascii=False, indent=2), context=_context(task, gap, retrieved),
        previous=json.dumps(previous or {}, ensure_ascii=False, indent=2))


def hole_prompt(task: dict[str, Any], gap: dict[str, Any], retrieved: list[dict[str, Any]],
                candidate: dict[str, Any], schema: dict[str, Any], skeleton: str,
                metadata: dict[str, Any], alignment: dict[str, Any], failure: dict[str, Any] | None) -> str:
    return HOLE_PROMPT.format(name=candidate["lemma_name"], statement=candidate["lemma_statement"],
        schema=json.dumps(schema, ensure_ascii=False, indent=2), skeleton=skeleton,
        metadata=json.dumps(metadata, ensure_ascii=False, indent=2),
        alignment=json.dumps(alignment, ensure_ascii=False, indent=2), context=_context(task, gap, retrieved),
        failure=json.dumps(failure or {}, ensure_ascii=False, indent=2))


def policy_manifest() -> dict[str, Any]:
    templates = {"edge": EDGE_PROMPT, "hole": HOLE_PROMPT}
    return {"schema": "rtl2lean-hypergraph_guidance-prompts-v1",
        "template_hashes": {key: digest(value) for key, value in templates.items()},
        "edge_schema": EDGE_SCHEMA, "hole_schema": HOLE_SCHEMA,
        "llm_generates_outer_proof_structure": False, "direct_target_generation": False,
        "reference_proofs_hidden": True}
