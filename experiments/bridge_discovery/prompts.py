"""Frozen statement-selection and proof-generation prompts."""
from __future__ import annotations

import json
from typing import Any

from experiments.adaptive_proving.config import digest
from experiments.foundation_first.prompts import compact_context


STATEMENT_SCHEMA = {
    "type": "object", "properties": {"candidates": {"type": "array", "minItems": 3, "maxItems": 3,
        "items": {"type": "object", "properties": {
            "lemma_name": {"type": "string"}, "lemma_statement": {"type": "string"},
            "new_candidate_source": {"type": "string"}, "new_candidate_target": {"type": "string"},
            "how_it_bridges_gap": {"type": "string"},
            "which_previous_failure_is_avoided": {"type": "string"}},
            "required": ["lemma_name", "lemma_statement", "new_candidate_source", "new_candidate_target",
                         "how_it_bridges_gap", "which_previous_failure_is_avoided"],
            "additionalProperties": False}}}, "required": ["candidates"], "additionalProperties": False,
}

PROOF_SCHEMA = {"type": "object", "properties": {
    "proof_body": {"type": "string"}, "rationale": {"type": "string"},
    "used_lemmas": {"type": "array", "items": {"type": "string"}}},
    "required": ["proof_body", "rationale", "used_lemmas"], "additionalProperties": False}


STATEMENT_TEMPLATE = """You select intermediate Lean lemma STATEMENTS for a frozen experiment.
Return exactly three candidates matching the JSON schema. Do not provide proofs and do not prove the final Property.
Every lemma name starts with {prefix}. A statement is only the proposition after `:`.
Use only the declarations shown below. Do not restate the full target or an existing theorem.
Each candidate must explicitly identify its available source, required target, bridge, and avoided failure.
Prefer a reusable relation that reaches the next target-side premise. Never use challenge/DUT-specific heuristics.

Operation: {operation}
Seed: {seed}
Namespace: {module}Verification; open {module}
Target Property:
{statement}

ProofGapObservation:
{gap}

BridgeSpecification:
{bridge}

Global Bridge View:
{global_view}

Relevant Lean Context:
{context}

Previous evidence for redesign (empty on first generation):
{previous}
"""

PROOF_TEMPLATE = """You prove one FROZEN intermediate lemma in Lean 4. Return JSON matching the schema.
Do not change its name or statement. proof_body begins with `by`. Never use sorry, admit, native_decide,
unsafe, axiom, or unchecked code. Do not generate the final target proof.

Seed: {seed}
Namespace: {module}Verification; open {module}
Frozen lemma name: {lemma_name}
Frozen lemma statement: {lemma_statement}
Candidate utility evidence:
{utility}
Relevant Lean Context:
{context}
Failure diagnosis and frozen repair-template guidance (empty for first proof):
{repair}
"""


def statement_prompt(task: dict[str, Any], gap: dict[str, Any], bridge: dict[str, Any],
                     global_view: dict[str, Any], retrieved: list[dict[str, Any]], seed: int,
                     prefix: str, operation: str, previous: dict[str, Any] | None) -> str:
    context_task = {**task, "proof_gap_binders": gap["target_structure_ast"]["binders"]}
    values = {"prefix": prefix, "operation": operation, "seed": seed, "module": task["module"],
              "statement": task["statement"], "gap": json.dumps(gap, ensure_ascii=False, indent=2),
              "bridge": json.dumps(bridge, ensure_ascii=False, indent=2),
              "global_view": json.dumps(global_view, ensure_ascii=False, indent=2),
              "context": compact_context(context_task, retrieved),
              "previous": json.dumps(previous or {}, ensure_ascii=False, indent=2)}
    return STATEMENT_TEMPLATE.format(**values)


def proof_prompt(task: dict[str, Any], gap: dict[str, Any], retrieved: list[dict[str, Any]], seed: int,
                 candidate: dict[str, Any], utility: dict[str, Any], repair: dict[str, Any] | None) -> str:
    context_task = {**task, "proof_gap_binders": gap["target_structure_ast"]["binders"]}
    return PROOF_TEMPLATE.format(seed=seed, module=task["module"],
        lemma_name=candidate["lemma_name"], lemma_statement=candidate["lemma_statement"],
        utility=json.dumps(utility, ensure_ascii=False, indent=2),
        context=compact_context(context_task, retrieved),
        repair=json.dumps(repair or {}, ensure_ascii=False, indent=2))


def policy_manifest() -> dict[str, Any]:
    templates = {"statement": STATEMENT_TEMPLATE, "proof": PROOF_TEMPLATE}
    return {"schema": "rtl2lean-bridge_discovery-prompt-policy-v1",
            "template_hashes": {key: digest(value) for key, value in templates.items()},
            "statement_schema": STATEMENT_SCHEMA, "proof_schema": PROOF_SCHEMA,
            "statement_proof_separated": True, "candidate_count": 3,
            "direct_target_generation": False, "reference_proofs_hidden": True,
            "gap_specs_hidden": True}
