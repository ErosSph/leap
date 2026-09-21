"""Frozen prompts: the proof model only discovers candidate lemmas."""
from __future__ import annotations

import json
from typing import Any

from experiments.adaptive_proving.config import digest


LEMMA_SCHEMA = {
    "type": "object",
    "properties": {
        "lemma_name": {"type": "string"},
        "lemma_statement": {"type": "string"},
        "proof_body": {"type": "string"},
        "rationale": {"type": "string"},
        "used_lemmas": {"type": "array", "items": {"type": "string"}},
    },
    "required": ["lemma_name", "lemma_statement", "proof_body", "rationale", "used_lemmas"],
    "additionalProperties": False,
}


COMMON = """You are the lemma-discovery component of a frozen Lean 4 experiment.
Return exactly one JSON object matching the response schema. You propose one intermediate lemma,
not the final target proof. A deterministic prover, not you, will retry the target.

Hard constraints:
- Do not restate or weaken the target.
- Do not return the target conjunction as the lemma.
- Use only declarations shown in Relevant Lean Context.
- proof_body is a complete Lean term beginning with `by`.
- Never use sorry, admit, native_decide, unsafe, axiom, or unchecked code.
- lemma_name begins with `{prefix}`.
- lemma_statement contains only the proposition/type after `:`, never `theorem`, `lemma`, the name, or `:= by`.
- You have no tools or repository access.

Sampling seed/nonce: {seed}
Import: {context_import}
Namespace: {module}Verification
Open namespace: {module}

Frozen target:
{statement}

Fixed ProofGapObservation (generated before this model call):
{proof_gap}

Relevant Lean Context:
{context}

Temporary kernel-verified context from earlier candidates:
{verified_context}
"""

INITIAL = COMMON + """
Operation: DISCOVER.
Discover the smallest reusable missing bridge satisfying candidate_requirements. Prefer a general
trace lemma over a target-specific conjunction. Supply both its statement and kernel-checkable proof.
"""

REPAIR = COMMON + """
Operation: REPAIR.
The statement below is frozen because the deterministic diagnoser judged it plausible. Keep the exact
lemma_name and lemma_statement; change proof_body only using the Lean error and repair guidance.

Frozen candidate:
{candidate}

LemmaDiagnosisReport:
{diagnosis}
"""

REDESIGN = COMMON + """
Operation: REDESIGN.
Abandon the rejected statement and discover a genuinely different bridge. Follow redesign_guidance and
avoid_in_next_candidate. Do not make cosmetic changes to the rejected proposition.

Rejected candidate:
{candidate}

LemmaDiagnosisReport:
{diagnosis}
"""


def compact_context(task: dict[str, Any], retrieved: list[dict[str, Any]]) -> str:
    input_type = next((row["type"][5:] for row in task.get("proof_gap_binders", [])
                       if row["type"].startswith("List ")), "ι")
    state_type = task.get("state_type", "σ")
    definitions = f"""def R3Temporal.exec (step : σ → ι → σ) (s : σ) (inputs : List ι) : σ :=
  inputs.foldl step s
def R3Temporal.Along (step : σ → ι → σ) (guard : σ → ι → Prop) : σ → List ι → Prop
  | _, [] => True
  | s, i :: is => guard s i ∧ R3Temporal.Along step guard (step s i) is
def r3Step : {state_type} → {input_type} → {state_type}
def r3Run (s : {state_type}) (items : List {input_type}) : {state_type} :=
  R3Temporal.exec r3Step s items
"""
    declarations = "\n".join(
        f"theorem {row['name']} : {row['statement']}" for row in retrieved
    )
    return definitions + declarations


def candidate_prompt(
    task: dict[str, Any], proof_gap: dict[str, Any], retrieved: list[dict[str, Any]],
    seed: int, prefix: str, operation: str, candidate: dict[str, Any] | None = None,
    diagnosis: dict[str, Any] | None = None, verified_context: list[dict[str, Any]] | None = None,
) -> str:
    task_for_context = {**task, "proof_gap_binders": proof_gap["target_structure_ast"]["binders"]}
    values = {
        "prefix": prefix, "seed": seed, "context_import": task["context_import"],
        "module": task["module"], "statement": task["statement"],
        "proof_gap": json.dumps(proof_gap, ensure_ascii=False, indent=2),
        "context": compact_context(task_for_context, retrieved),
        "candidate": json.dumps(candidate or {}, ensure_ascii=False, indent=2),
        "diagnosis": json.dumps(diagnosis or {}, ensure_ascii=False, indent=2),
        "verified_context": json.dumps(verified_context or [], ensure_ascii=False, indent=2),
    }
    return {"DISCOVER": INITIAL, "REPAIR": REPAIR, "REDESIGN": REDESIGN}[operation].format(**values)


def policy_manifest() -> dict[str, Any]:
    templates = {"common": COMMON, "discover": INITIAL, "repair": REPAIR, "redesign": REDESIGN}
    return {
        "schema": "rtl2lean-foundation_first-prompt-policy-v1",
        "template_hashes": {key: digest(value) for key, value in templates.items()},
        "aggregate_hash": digest(templates),
        "direct_target_generation": False,
        "reference_proof_hidden": True,
        "gap_spec_hidden": True,
        "candidate_schema": LEMMA_SCHEMA,
    }
