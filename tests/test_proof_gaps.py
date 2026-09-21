from __future__ import annotations

import json
from dataclasses import asdict
from pathlib import Path

from rtl2lean.pipeline.manifest import Benchmark
from rtl2lean.proof_gaps.corpus import symbolic_endpoint_property
from rtl2lean.proof_gaps.experiment import (
    LEMMA_BUDGET,
    MAX_LLM_CALLS,
    MAX_REPAIRS_PER_CANDIDATE,
    MAX_TOTAL_TOKENS,
    _alpha_fingerprint,
    _gap_alignment,
    _r7_novelty,
    _task,
)
from rtl2lean.proof_gaps.proof_gap import analyze_candidates
from rtl2lean.proof_gaps.report import _classification


def _benchmark() -> Benchmark:
    return Benchmark("dut", "top", "repo", "commit", (Path("dummy.v"),), ())


def _seed() -> dict:
    return {
        "seed_id": "r3seed_proc_counter_t", "destination": "counter",
        "guard_name": "counter_guard", "local_lemma": "counter_local_step",
        "local_expected": "(comb s item).counter_new", "branch_process": "s.counter_new",
        "branch_kind": "update", "multi_clock_model": False, "clock": "clk", "width": 8,
        "source_function": "proc", "referenced_inputs": [], "rtl_evidence": {}, "ir_evidence": {},
    }


def test_proof_gaps_arms_have_equal_budgets() -> None:
    assert LEMMA_BUDGET.max_llm_calls == MAX_LLM_CALLS
    assert LEMMA_BUDGET.max_total_tokens == MAX_TOTAL_TOKENS
    assert LEMMA_BUDGET.max_repair_rounds_per_candidate == MAX_REPAIRS_PER_CANDIDATE


def test_symbolic_endpoint_is_a_real_inductive_gap() -> None:
    prop = symbolic_endpoint_property(_benchmark(), _seed())
    assert prop["gap_spec"]["gap_depth"] == 2
    assert prop["gap_spec"]["missing_relation_derivable"]
    assert "induction pre generalizing s" in prop["reference_proof"]
    assert "counter_local_step" in prop["reference_proof"]


def test_preproof_analyzer_separates_exact_coverage_from_missing_relation(tmp_path) -> None:
    covered = {
        "property_id": "covered", "dut": "dut", "theorem_statement": "∀ x, P x",
        "foundation_lemmas": ["known"], "referenced_state_fields": [], "gap_spec": None,
    }
    challenge = {
        "property_id": "challenge", "dut": "dut",
        "theorem_statement": "∀ s pre item, Along s (pre ++ [item]) → Q s pre item",
        "foundation_lemmas": ["known"], "referenced_state_fields": ["counter"],
        "gap_spec": {
            "gap_type": "SYMBOLIC_POSITION_BRIDGE", "missing_relation": "symbolic endpoint counter",
            "required_lower_level_facts": ["known"], "missing_relation_derivable": True,
            "gap_depth": 2, "derivation_shape": "LIST_INDUCTION_PLUS_L3_LOCAL_STEP",
        },
    }
    candidates = {"properties": [covered, challenge], "metrics": {}}
    inventory = {"theorems": [{
        "dut": "dut", "name": "known", "statement": "∀ x, P x",
        "normalized_statement": "∀x,Px", "tokens": ["P", "x"],
    }]}
    # Use the analyzer's own normalization for the exact control.
    inventory["theorems"][0]["normalized_statement"] = "∀x,Px"
    result = analyze_candidates(candidates, inventory, tmp_path)
    assert result["properties"][0]["classification"] == "FOUNDATIONALLY_COVERED"
    assert result["properties"][1]["classification"] == "INTERMEDIATE_LEMMA_CHALLENGE"
    witness = result["properties"][1]["proof_gap_analysis"]["proof_gap_witness"]
    assert witness["target"] == challenge["theorem_statement"]
    assert witness["missing"] == "symbolic endpoint counter"
    assert witness["derivation_evidence"]["lower_level_theorems"] == ["known"]


def test_gap_metadata_is_not_leaked_into_llm_task(tmp_path) -> None:
    model = tmp_path / "dut" / "model"
    model.mkdir(parents=True)
    (model / "R3Base.lean").write_text("", encoding="utf-8")
    (model / "R3Foundation.lean").write_text(
        "def r3Step := 0\ndef r3Run := 0\ntheorem counter_local_step : True := by trivial\n",
        encoding="utf-8",
    )
    (model / "R5Foundation.lean").write_text("", encoding="utf-8")
    prop = {
        "property_id": "target", "theorem_statement": "True",
        "foundation_lemmas": ["counter_local_step"], "referenced_state_fields": ["counter"],
        "referenced_inputs": [], "gap_spec": {"missing_relation": "SECRET GAP ANSWER"},
    }
    base = {"attempts": []}
    task = _task(_benchmark(), prop, base, tmp_path)
    encoded = json.dumps(asdict(task))
    assert "SECRET GAP ANSWER" not in encoded
    assert "gap_spec" not in encoded


def test_gap_alignment_and_strict_result_classification() -> None:
    prop = {
        "dut": "dut", "property_id": "target", "referenced_state_fields": ["counter"],
        "gap_spec": {"gap_type": "SYMBOLIC_POSITION_BRIDGE",
                     "missing_relation": "endpoint relation",
                     "relation_anchors": ["Along", "r3Run", "pre", "item", "counter"]},
    }
    row = _gap_alignment(prop, {"name": "bridge", "proposition":
        "∀ s pre item, Along s pre → (r3Run s pre).counter = counter"})
    assert row["classification"] in {"SEMANTIC_MATCH", "PARTIAL_MATCH"}
    covered = _gap_alignment(
        {"dut": "dut", "property_id": "covered", "referenced_state_fields": [], "gap_spec": None},
        {"name": "helper", "proposition": "True"},
    )
    assert covered["classification"] == "NO_PREDICTED_GAP"
    assert _classification(
        {"status": "BASE_FAILED"}, [{"status": "DIRECT_FAILED"}],
        [{"status": "LEMMA_FIRST_SOLVED", "causal_row": {"STRICT_LEMMA_CAUSAL_GAIN": True}}],
    ) == "STRICT_LEMMA_CAUSAL_GAIN"


def test_novelty_rejects_alpha_renames_and_exec_append_specializations() -> None:
    assert _alpha_fingerprint("∀ (x : Nat), x = x") == _alpha_fingerprint(
        "∀ (value : Nat), value = value"
    )
    prop = {
        "dut": "dut", "property_id": "target", "referenced_state_fields": [],
        "theorem_statement": "True",
    }
    foundation = [{
        "name": "R3Temporal.exec_append",
        "statement": "(step : σ → ι → σ) (s : σ) (xs ys : List ι) : "
                     "R3Temporal.exec step s (xs ++ ys) = "
                     "R3Temporal.exec step (R3Temporal.exec step s xs) ys",
    }]
    lemma = {
        "name": "r3Run_append_singleton",
        "proposition": "∀ (s : DutState) (pre : List DutInputs) (item : DutInputs), "
                       "r3Run s (pre ++ [item]) = r3Step (r3Run s pre) item",
        "proof_body": "by simp [r3Run, R3Temporal.exec, List.foldl_append]",
        "dependencies": ["List.foldl_append"],
    }
    novelty = _r7_novelty(lemma, prop, foundation)
    assert not novelty["semantic_novelty"]
    assert novelty["foundation_specialization"]
    assert novelty["semantic_duplication"]
    assert novelty["specialization_reasons"] == [
        "DEFINITIONAL_INSTANCE:R3Temporal.exec_append(ys := [item])"
    ]
    structured_shape = {
        "lemma_name": lemma["name"], "lemma_statement": lemma["proposition"],
        "proof_body": lemma["proof_body"], "used_lemmas": lemma["dependencies"],
    }
    structured_novelty = _r7_novelty(structured_shape, prop, foundation)
    assert not structured_novelty["semantic_novelty"]
    assert structured_novelty["foundation_specialization"]
