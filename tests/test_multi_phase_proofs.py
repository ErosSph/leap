from __future__ import annotations

import json
from dataclasses import asdict
from pathlib import Path

import pytest

from rtl2lean.pipeline.manifest import Benchmark
from rtl2lean.multi_phase_proofs.experiment import (
    LEMMA_BUDGET, MAX_LLM_CALLS, MAX_REPAIRS_PER_CANDIDATE,
    MAX_TOTAL_TOKENS, _alignment, _closure, _trial_task,
)
from rtl2lean.multi_phase_proofs.proof_graph import analyze_targets
from rtl2lean.multi_phase_proofs.report import _repairs_within_per_candidate_budget


def _benchmark() -> Benchmark:
    return Benchmark("dut", "top", "repo", "commit", (Path("dummy.v"),), ())


def _prop(class_name: str, phase_count: int) -> dict:
    along = " → ".join(
        f"R3Temporal.Along r3Step guard{i} s xs{i}" for i in range(phase_count)
    )
    statement = (along + " → True") if along else "∀ s, guard s → True"
    shapes = {
        "WEAK_GAP": "LIST_INDUCTION_PLUS_L3_LOCAL_STEP",
        "MEDIUM_BOTTLENECK": "TWO_FACT_SEMANTIC_BRIDGE",
        "STRONG_BOTTLENECK": "SHARED_LAST_GUARD_INDUCTION_PLUS_THREE_L3_LOCAL_STEPS",
    }
    fact_counts = {"WEAK_GAP": 1, "MEDIUM_BOTTLENECK": 2, "STRONG_BOTTLENECK": 3}
    return {
        "property_id": class_name.lower(), "dut": "dut", "module": "top",
        "theorem_statement": statement, "r8_experiment_class": class_name,
        "referenced_state_fields": [f"field{i}" for i in range(max(1, phase_count))],
        "foundation_lemmas": ["known"], "rtl_evidence": [{}], "ir_evidence": [{}],
        "gap_spec": None if phase_count == 0 else {
            "missing_relation": "secret bottleneck", "missing_relation_derivable": True,
            "required_lower_level_facts": [f"known{i}" for i in range(fact_counts[class_name])],
            "relation_anchors": ["Along", "r3Run"],
            "derivation_shape": shapes[class_name],
            "candidate_strength_evidence": {
                "real_update_regions": fact_counts[class_name],
                "required_lower_level_fact_count": fact_counts[class_name],
                "new_semantic_abstraction": "semantic_bridge",
            },
        },
    }


def test_multi_phase_proofs_fair_total_budget_and_minimum_trials() -> None:
    assert LEMMA_BUDGET.max_llm_calls == MAX_LLM_CALLS
    assert LEMMA_BUDGET.max_total_tokens == MAX_TOTAL_TOKENS
    assert LEMMA_BUDGET.max_repair_rounds_per_candidate == MAX_REPAIRS_PER_CANDIDATE
    from rtl2lean.multi_phase_proofs.main import main
    with pytest.raises(SystemExit, match="requires --trials >= 5"):
        main(["--trials", "4", "--phase", "corpus"])


def test_preproof_graph_uses_semantics_not_phase_count(tmp_path) -> None:
    candidates = {
        "properties": [
            _prop("WEAK_GAP", 3), _prop("MEDIUM_BOTTLENECK", 2),
            _prop("STRONG_BOTTLENECK", 1),
        ],
        "metrics": {},
    }
    graph = {"nodes": [{
        "id": "theorem::dut::known", "kind": "THEOREM", "dut": "dut",
        "name": "known", "statement": "∀ x, P x", "layer": "L3",
    }]}
    result = analyze_targets(candidates, graph, tmp_path)
    assert [row["r8_experiment_class"] for row in result["properties"]] == [
        "WEAK_GAP", "MEDIUM_BOTTLENECK", "STRONG_BOTTLENECK",
    ]
    assert not result["properties"][0]["operational_bottleneck_candidate"]
    assert all(row["operational_bottleneck_candidate"] for row in result["properties"][1:])
    assert all(
        row["bottleneck_analysis"]["bottleneck_scope"]
        == "OPERATIONAL_UNDER_FROZEN_ENVIRONMENT"
        for row in result["properties"]
    )
    assert all(
        not row["bottleneck_analysis"]["raw_phase_count_used_for_classification"]
        for row in result["properties"]
    )


def test_alignment_uses_operational_categories() -> None:
    prop = _prop("STRONG_BOTTLENECK", 3)
    prop["dut"] = "dut"
    prop["bottleneck_analysis"] = {"bottleneck_strength": "STRONG"}
    row = _alignment(prop, {
        "name": "last_guard", "proposition": "Along r3Step guard s xs → r3Run s xs = s",
    }, 1)
    assert row["classification"] in {
        "SEMANTIC_ALIGNMENT", "PARTIAL_ALIGNMENT", "ALTERNATIVE_VALID_ABSTRACTION",
    }


def test_trial_nonce_does_not_leak_bottleneck(tmp_path) -> None:
    model = tmp_path / "dut" / "model"
    model.mkdir(parents=True)
    (model / "R3Base.lean").write_text("", encoding="utf-8")
    (model / "R3Foundation.lean").write_text("theorem known : True := by trivial\n", encoding="utf-8")
    (model / "R5Foundation.lean").write_text("", encoding="utf-8")
    prop = _prop("STRONG_BOTTLENECK", 3)
    prop.update({
        "property_id": "target", "theorem_statement": "True",
        "referenced_inputs": [], "bottleneck_analysis": {
            "candidate_bottleneck_relation": "DO NOT LEAK THIS ANSWER",
        },
    })
    task = _trial_task(_benchmark(), prop, {"attempts": []}, tmp_path, 12345)
    encoded = json.dumps(asdict(task))
    assert "12345" in encoded
    assert "DO NOT LEAK THIS ANSWER" not in encoded
    assert "candidate_bottleneck_relation" not in encoded


def test_closure_requires_direct_comparative_improvement() -> None:
    prop = _prop("MEDIUM_BOTTLENECK", 2)
    base = {"status": "BASE_FAILED", "attempts": [{"stdout": "⊢ unresolved", "stderr": ""}]}
    usage = [{
        "lemma": "bridge", "causally_necessary": True,
        "kernel_ablation_without_lemma_pass": False,
    }]
    proof = {
        "target_kernel_pass": True, "final_proof": "by exact bridge",
        "repair_rounds_used": 0, "intermediate_lemma_usage": usage,
    }
    direct_same = {
        "status": "DIRECT_SOLVED", "final_proof": "by exact bridge", "repair_rounds": 0,
    }
    assert not _closure(prop, base, direct_same, proof, [{"kernel_verified": True}], 1)[
        "BOTTLENECK_CLOSURE"
    ]
    direct_larger = {
        "status": "DIRECT_SOLVED",
        "final_proof": "by\n  have h : True := by trivial\n  have h2 : True := by trivial\n  exact h",
        "repair_rounds": 1,
    }
    assert _closure(prop, base, direct_larger, proof, [{"kernel_verified": True}], 1)[
        "BOTTLENECK_CLOSURE"
    ]


def test_repair_budget_audit_supports_both_history_schemas(tmp_path) -> None:
    direct_prompt = tmp_path / "direct.txt"
    repair_prompt = tmp_path / "repair.txt"
    direct_prompt.write_text("Current mode: DIRECT_TARGET\n", encoding="utf-8")
    repair_prompt.write_text("Current mode: REPAIR\n", encoding="utf-8")
    legacy = {
        "proof_result": {"history": [
            {"provider": {"prompt": str(direct_prompt)}},
            {"provider": {"prompt": str(repair_prompt)}},
            {"provider": {"prompt": str(direct_prompt)}},
            {"provider": {"prompt": str(repair_prompt)}},
        ]},
    }
    assert _repairs_within_per_candidate_budget(legacy, 1)
    legacy["proof_result"]["history"].append({"provider": {"prompt": str(repair_prompt)}})
    assert not _repairs_within_per_candidate_budget(legacy, 1)
    assert _repairs_within_per_candidate_budget({
        "proof_result": {"attempt_history": [{"repair_round": 1}]},
    }, 1)
    assert not _repairs_within_per_candidate_budget({
        "proof_result": {"attempt_history": [{"repair_round": 2}]},
    }, 1)
