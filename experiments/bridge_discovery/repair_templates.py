"""Frozen reusable failure-class to proof-repair guidance library."""
from __future__ import annotations

from typing import Any


TEMPLATES = {
    "INDUCTION_STATE_NOT_GENERALIZED": {
        "template_id": "RT_INDUCTION_GENERALIZE_STATE_V1",
        "guidance": ["Generalize the evolving state before induction over the prefix.",
                     "Apply the induction hypothesis to the successor state produced by step.",
                     "Do not keep the initial state fixed in the induction hypothesis."],
    },
    "TRACE_SINGLETON_NOT_DESTRUCTURED": {
        "template_id": "RT_TRACE_SINGLETON_DESTRUCT_V1",
        "guidance": ["Handle the empty-prefix and cons-prefix cases explicitly.",
                     "In the empty-prefix case destructure Along on [last] and use its first conjunct.",
                     "Simplify exec on [] separately from destructuring Along."],
    },
    "THEOREM_APPLICATION_MISMATCH": {
        "template_id": "RT_THEOREM_APPLICATION_ALIGN_V1",
        "guidance": ["Compare the theorem's binders with the actual hypotheses in declared order.",
                     "Supply all state/input/premise arguments explicitly where inference is ambiguous.",
                     "Use apply only when its conclusion matches the current goal direction."],
    },
    "TYPE_MISMATCH": {
        "template_id": "RT_TYPE_ALIGNMENT_V1",
        "guidance": ["Compare expected and actual types before changing the statement.",
                     "Normalize coercions, equality direction, and argument order.",
                     "Introduce a typed intermediate have when elaboration cannot infer the intended term."],
    },
}


def lookup(failure_class: str) -> dict[str, Any] | None:
    template = TEMPLATES.get(failure_class)
    return {"failure_class": failure_class, **template} if template else None


def policy_manifest() -> dict[str, Any]:
    return {"schema": "rtl2lean-bridge_discovery-repair-template-library-v1",
            "frozen_from_development_set": True, "challenge_specific_templates": False,
            "local_transformations_enabled": False, "templates": TEMPLATES}
