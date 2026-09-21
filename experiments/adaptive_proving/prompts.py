"""Frozen prompt policy for the two adaptive_proving strategies."""
from __future__ import annotations

import json
from typing import Any

from .config import digest


TARGET_SCHEMA = {
    "type": "object",
    "properties": {
        "proof_body": {"type": "string"},
        "rationale": {"type": "string"},
        "used_lemmas": {"type": "array", "items": {"type": "string"}},
    },
    "required": ["proof_body", "rationale", "used_lemmas"],
    "additionalProperties": False,
}

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


COMMON = """This is a frozen adaptive_proving Lean 4 proof task.
Return exactly one JSON object matching the supplied response schema.

Hard constraints:
- Never change, weaken, or restate the frozen target.
- Never use sorry, admit, native_decide, unsafe, axiom, or unchecked code.
- Use only declarations in the frozen context below.
- proof_body must be a complete Lean term beginning with `by`.
- You have no tools and must not assume access to repository files.

Paired sampling seed/nonce (contains no proof information): {seed}
Import: {context_import}
Namespace: {module}Verification
Open namespace: {module}
Target theorem name: {task_id}
Target statement:
{statement}

Frozen retrieved Lean context (identical for both strategies):
{context}

Frozen baseline Lean feedback (identical for both strategies):
{baseline_error}
"""


DIRECT_INITIAL = COMMON + """
Strategy: DIRECT, initial final-target generation.
Generate the final target proof now. Local `have`, `suffices`, induction, cases, rw, simp,
apply, and exact are allowed. Do not propose a separate top-level intermediate theorem.
"""

DIRECT_REPAIR = COMMON + """
Strategy: DIRECT, final-target repair.
Repair the exact target proof using the full attempt history below. Preserve the target name and
statement. Return only a replacement proof_body plus rationale and used_lemmas.

Full prior target-attempt history:
{history}
"""

LEMMA_INITIAL = COMMON + """
Strategy: DIAGNOSIS-GUIDED ADAPTIVE LEMMA-FIRST, candidate L1 generation.
Generate and prove exactly one useful intermediate theorem. It must be strictly different from
the complete target and expose a bridge that materially helps the final target. It must not be a
renamed target or a wrapper around one existing theorem. lemma_name must begin with `{prefix}`.
No human-written candidate statement has been supplied.
"""

LEMMA_REPAIR = COMMON + """
Strategy: DIAGNOSIS-GUIDED ADAPTIVE LEMMA-FIRST, LEMMA_PROOF_REPAIR.
The deterministic local diagnosis selected REPAIR. Keep the exact lemma_name and
lemma_statement frozen; change proof_body only. The diagnosis primary cause, action, evidence,
and repair guidance below control this operation.

Frozen candidate:
{candidate}

Structured diagnosis:
{diagnosis}

Full lemma attempt/diagnosis history:
{history}
"""

LEMMA_REDESIGN = COMMON + """
Strategy: DIAGNOSIS-GUIDED ADAPTIVE LEMMA-FIRST, candidate L2 REDESIGN.
The deterministic local diagnosis selected REDESIGN. Abandon the prior proposition and generate
one different, better-scoped bridge. This is the single allowed redesign. The new lemma_name must
begin with `{prefix}`. Use the primary cause, evidence, and redesign guidance below; do not merely
retry the same statement with cosmetic changes.

Rejected candidate:
{candidate}

Structured diagnosis:
{diagnosis}

Full lemma attempt/diagnosis history:
{history}
"""

TARGET_AFTER_LEMMA = COMMON + """
Strategy: DIAGNOSIS-GUIDED ADAPTIVE LEMMA-FIRST, final target generation.
The following intermediate theorem passed Lean elaboration and kernel checking. Prove the exact
target and explicitly reference `{lemma_name}` in proof_body.

Kernel-verified intermediate theorem:
theorem {lemma_name} : {lemma_statement} := {lemma_proof}
"""

TARGET_REPAIR = COMMON + """
Strategy: DIAGNOSIS-GUIDED ADAPTIVE LEMMA-FIRST, final target repair.
Repair the exact target proof. Preserve the verified lemma and explicitly reference
`{lemma_name}` in proof_body. Return only the replacement target proof.

Kernel-verified intermediate theorem:
theorem {lemma_name} : {lemma_statement} := {lemma_proof}

Full prior target-attempt history:
{history}
"""


def _common(task: dict[str, Any], seed: int) -> dict[str, Any]:
    return {
        "seed": seed,
        "context_import": task["context_import"],
        "module": task["module"],
        "task_id": task["task_id"],
        "statement": task["statement"],
        "context": task["context"],
        "baseline_error": task["baseline_lean_error"],
    }


def direct_prompt(task: dict[str, Any], seed: int, history: list[dict[str, Any]]) -> str:
    values = _common(task, seed)
    if not history:
        return DIRECT_INITIAL.format(**values)
    return DIRECT_REPAIR.format(
        **values, history=json.dumps(history, indent=2, ensure_ascii=False)
    )


def lemma_prompt(
    task: dict[str, Any], seed: int, prefix: str, mode: str,
    candidate: dict[str, Any] | None = None,
    diagnosis: dict[str, Any] | None = None,
    history: list[dict[str, Any]] | None = None,
) -> str:
    values = _common(task, seed)
    if mode == "GENERATE":
        return LEMMA_INITIAL.format(**values, prefix=prefix)
    template = LEMMA_REPAIR if mode == "REPAIR" else LEMMA_REDESIGN
    return template.format(
        **values,
        prefix=prefix,
        candidate=json.dumps(candidate or {}, indent=2, ensure_ascii=False),
        diagnosis=json.dumps(diagnosis or {}, indent=2, ensure_ascii=False),
        history=json.dumps(history or [], indent=2, ensure_ascii=False),
    )


def target_after_lemma_prompt(
    task: dict[str, Any], seed: int, lemma: dict[str, str], history: list[dict[str, Any]],
) -> str:
    values = {
        **_common(task, seed),
        "lemma_name": lemma["lemma_name"],
        "lemma_statement": lemma["lemma_statement"],
        "lemma_proof": lemma["proof_body"],
    }
    if not history:
        return TARGET_AFTER_LEMMA.format(**values)
    return TARGET_REPAIR.format(
        **values, history=json.dumps(history, indent=2, ensure_ascii=False)
    )


def prompt_policy_manifest() -> dict[str, Any]:
    templates = {
        "common": COMMON,
        "direct_initial": DIRECT_INITIAL,
        "direct_repair": DIRECT_REPAIR,
        "lemma_initial": LEMMA_INITIAL,
        "lemma_repair": LEMMA_REPAIR,
        "lemma_redesign": LEMMA_REDESIGN,
        "target_after_lemma": TARGET_AFTER_LEMMA,
        "target_repair": TARGET_REPAIR,
    }
    return {
        "version": "adaptive_proving-prompts-v1",
        "templates_sha256": {name: digest(text) for name, text in templates.items()},
        "aggregate_sha256": digest(templates),
        "direct_allows_local_intermediate_reasoning": True,
        "reference_proofs_hidden": True,
        "same_frozen_context": True,
        "schemas": {"target": TARGET_SCHEMA, "lemma": LEMMA_SCHEMA},
    }
