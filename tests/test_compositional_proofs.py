from __future__ import annotations

import pytest

from rtl2lean.compositional_proofs.experiment import (
    LEMMA_BUDGET,
    MAX_LLM_CALLS,
    MAX_REPAIRS_PER_CANDIDATE,
    MAX_TOTAL_TOKENS,
    PROVIDER_TIMEOUT_S,
    _require_live_provider,
    _intermediate_policy,
    audit_direct,
)
from rtl2lean.compositional_proofs.foundation import chain_names
from rtl2lean.compositional_proofs.latency import COUNTER
from rtl2lean.proving.llm_prover import StructuredCandidate


def test_compositional_proofs_arms_have_equal_resource_budgets() -> None:
    assert LEMMA_BUDGET.max_llm_calls == MAX_LLM_CALLS
    assert LEMMA_BUDGET.max_total_tokens == MAX_TOTAL_TOKENS
    assert LEMMA_BUDGET.max_repair_rounds_per_candidate == MAX_REPAIRS_PER_CANDIDATE
    assert PROVIDER_TIMEOUT_S > 0


def test_provider_failure_is_infrastructure_invalid() -> None:
    failed = {
        "history": [{
            "call": 1,
            "status": "PROVIDER_FAILURE",
            "provider": {"success": False, "stderr": "cannot initialise"},
        }],
    }
    with pytest.raises(RuntimeError, match="infrastructure-invalid"):
        _require_live_provider(failed, direct=True)

    _require_live_provider({
        "history": [{"call": 1, "provider": {"success": True}}],
    }, direct=True)


def test_direct_inline_audit_records_required_structure(tmp_path) -> None:
    rows = [{
        "trial": 1,
        "dut": "dut",
        "property_id": "target",
        "final_proof": "by\n  intro h\n  have h1 := h\n  cases h1",
    }]
    result = audit_direct(rows, tmp_path)
    row = result["rows"][0]
    assert row["have_count"] == 1
    assert row["case_split_count"] == 1
    assert row["local_fact_count"] == 1
    assert row["inline_decomposition_count"] == 2
    assert row["classification"] == "INLINE_DECOMPOSED_DIRECT"
    for field in (
        "suffices_count", "induction_count", "proof_ast_depth",
        "proof_ast_size", "max_nested_depth",
    ):
        assert field in row


def test_until_foundation_exposes_full_five_stage_chain() -> None:
    names = chain_names({"destination": "counter_reg"})
    assert set(names) == {
        "post_comb_hold", "register_hold", "state_preservation",
        "prefix_preservation", "completion_witness",
    }
    assert len(set(names.values())) == 5
    assert all(name.startswith("r5_counter_reg_") for name in names.values())


def test_compositional_proofs_rejects_exact_foundation_wrapper() -> None:
    prop = {
        "dut": "dut", "property_id": "target", "theorem_statement": "True",
        "referenced_state_fields": [],
    }
    foundation = [{"name": "known", "statement": "∀ x, P x"}]
    candidate = StructuredCandidate(
        action="INTERMEDIATE_LEMMA", lemma_name="renamed_known",
        lemma_statement="∀ x, P x", proof_body="by\n  intro x\n  exact known x",
        used_lemmas=["known"], rationale="wrapper",
    )
    with pytest.raises(ValueError, match="foundation or equal to the target|foundation wrappers"):
        _intermediate_policy(candidate, prop, foundation)


def test_counter_detection_does_not_misclassify_control_signals() -> None:
    assert COUNTER.search("round_ctr_reg")
    assert COUNTER.search("cycle_counter")
    assert COUNTER.search("count_instr")
    assert COUNTER.search("rx_ByteCnt_reg")
    assert not COUNTER.search("aes_core_ctrl_reg")
    assert not COUNTER.search("control_state")
