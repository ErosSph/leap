from __future__ import annotations

from rtl2lean.temporal_challenges.experiment import (
    _context_metrics,
    _proof_ast_depth,
    _proof_ast_size,
    _simple_foundation_specialization,
    _token_sum,
)
from rtl2lean.proving.llm_prover import AutonomousProofTask
from rtl2lean.temporal_challenges.foundation import chain_names


def test_direct_inline_depth_and_provider_token_accounting() -> None:
    assert _proof_ast_depth("by\n  constructor\n  · exact h\n  · exact h") == 2
    assert _proof_ast_size("by\n  exact h") > 0
    assert _token_sum({"history": [
        {"provider": {"tokens": 11}},
        {"provider": {"tokens": 7}},
    ]}) == 18


def test_simple_foundation_specialization_is_not_novel() -> None:
    foundation = [{
        "name": "R3Temporal.obeys_of_along",
        "statement": "∀ s xs, Along step guard s xs → Obeys step guard expected obs s xs",
    }]
    lemma = {
        "proof_body": "by\n  exact R3Temporal.obeys_of_along step guard expected obs local_step",
        "used_lemmas": ["R3Temporal.obeys_of_along"],
    }
    simple, reasons = _simple_foundation_specialization(lemma, foundation)
    assert simple
    assert any("KNOWN_GENERIC_SPECIALIZATION" in reason for reason in reasons)


def test_temporal_challenges_context_metric_is_deterministic() -> None:
    task = AutonomousProofTask(
        dut="d", target_name="t", target_statement="True", property_type="UNTIL",
        state_type="S", required_state_fields=[], required_input_fields=[], assumptions=[],
        context_import="R4Foundation", context_snippets=["theorem h : True := by trivial"],
        relevant_foundational_lemmas=[], base_lean_error="", future_targets=[],
    )
    assert _context_metrics(task) == _context_metrics(task)
    assert _context_metrics(task)["context_chars"] > 0


def test_until_foundation_has_five_distinct_named_stages() -> None:
    names = chain_names({"destination": "reg_name"})
    assert set(names) == {
        "post_comb_hold", "register_hold", "state_preservation",
        "prefix_preservation", "completion_witness",
    }
    assert len(set(names.values())) == 5
