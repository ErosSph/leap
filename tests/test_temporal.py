from rtl2lean.temporal.corpus import _clock_event, _semantic_tag
from rtl2lean.temporal.experiment import _baseline_suite, _novelty
from rtl2lean.temporal.report import (
    AES_COMPLEXITY_ORDER,
    FAMILY_ORDER,
    PROOF_COMPLEXITY_FIELDS,
    _ordered_groups,
    _proof_complexity_row,
)


def test_clock_event_is_derived() -> None:
    assert _clock_event("wb.clk-i") == "on_wb_clk_i"


def test_semantic_role_is_not_a_dut_quota() -> None:
    assert _semantic_tag("round_counter") == "CONTROL"
    assert _semantic_tag("payload_data") == "DATAPATH"


def test_true_multicycle_does_not_receive_reference_certificate() -> None:
    prop = {
        "property_level": "TRUE_MULTI_CYCLE",
        "proof_candidates": ["by exact generator_owned_answer"],
    }
    assert "by exact generator_owned_answer" not in _baseline_suite(prop)


def test_trace_bridge_may_use_prefrozen_certificate() -> None:
    prop = {"property_level": "TRACE_BRIDGE", "proof_candidates": ["by exact r3_model_run_append"]}
    assert "by exact r3_model_run_append" in _baseline_suite(prop)


def test_target_duplicate_is_not_novel() -> None:
    prop = {
        "dut": "d", "property_id": "p", "theorem_statement": "∀ x, P x",
        "referenced_state_fields": [],
    }
    row = _novelty({"name": "helper", "proposition": "∀ x, P x"}, prop, [])
    assert row["trivial_specialization"] is True
    assert row["semantic_novelty"] is False


def test_zero_candidate_families_remain_in_paper_table() -> None:
    rows = _ordered_groups([], FAMILY_ORDER, {"UNTIL": "no valid candidate"})
    assert [row["group"] for row in rows] == FAMILY_ORDER
    until = next(row for row in rows if row["group"] == "UNTIL")
    assert until["theorems"] == 0
    assert until["why_not_found"] == "no valid candidate"
    assert len(AES_COMPLEXITY_ORDER) == 9


def test_proof_complexity_contains_every_required_metric() -> None:
    prop = {
        "dut": "d", "property_id": "p", "property_level": "TRUE_MULTI_CYCLE",
        "property_family": "INVARIANT", "theorem_statement": "∀ s xs, P s xs",
        "trace_lower_bound": 2, "trace_upper_bound": None,
        "minimum_required_transitions": 2, "semantic_transition_count": 2,
        "syntactic_multi_cycle": True, "tags": ["TRUE_MULTI_CYCLE"],
        "source_functions": ["proc_alwaysff"], "foundation_lemmas": ["seed_local_step"],
        "trigger_condition": "(a && (b || c))", "dependency_cone": {"total": 3},
        "ir_evidence": {"expression_node_count": 4}, "referenced_state_fields": ["q"],
        "max_signal_width": 32, "aggregate_data_width": 32, "clock_domain": "clk",
    }
    baseline = {"status": "BASE_FAILED", "attempts": [{"proof": "by simp"}], "lean_time_s": 1.0, "proof_time_s": 1.0}
    direct = {"status": "DIRECT_SOLVED", "final_proof": "by\n  exact h", "llm_calls": 1, "repair_rounds": 0, "lean_time_s": 0.5, "elapsed_s": 2.0}
    lemma = {"status": "LEMMA_FIRST_SOLVED", "final_proof": "by\n  exact helper", "llm_calls": 2, "repair_rounds": 0, "lean_time_s": 1.0, "elapsed_s": 3.0, "intermediate_lemmas": [{}]}
    result = _proof_complexity_row({"property": prop, "baseline": baseline, "direct": direct, "lemma": lemma})
    assert set(PROOF_COMPLEXITY_FIELDS) <= set(result)
    assert result["clock_domain_count"] == 1
    assert result["intermediate_lemma_count"] == 1


def test_proof_complexity_accepts_null_trigger() -> None:
    prop = {
        "dut": "d", "property_id": "trace", "property_level": "TRACE_BRIDGE",
        "property_family": "TRACE_BRIDGE", "theorem_statement": "∀ s, P s",
        "minimum_required_transitions": 0, "semantic_transition_count": 0,
        "syntactic_multi_cycle": True, "tags": ["TRACE_BRIDGE"],
        "source_functions": [], "foundation_lemmas": ["r3_model_run_append"],
        "trigger_condition": None, "dependency_cone": {}, "ir_evidence": {},
        "referenced_state_fields": [], "clock_domain": "clk",
    }
    baseline = {"status": "BASE_SOLVED", "attempts": [], "proof_steps": 1}
    result = _proof_complexity_row({"property": prop, "baseline": baseline, "direct": None, "lemma": None})
    assert result["branch_depth"] == 0
