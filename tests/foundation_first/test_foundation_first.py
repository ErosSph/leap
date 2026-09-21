from __future__ import annotations

from pathlib import Path

from experiments.adaptive_proving.proof_model import ModelResponse
from experiments.foundation_first.config import load_config
from experiments.foundation_first.corpus import load_frozen_tasks, theorem_base_for
from experiments.foundation_first.proof_gap import extract_proof_gap, retrieve_lemmas
from experiments.foundation_first.prover import kernel_gate, run_property_prover
from experiments.foundation_first.trial import run_trial
from experiments.adaptive_proving.lemma_diagnosis import diagnose_lemma


PROJECT = Path(__file__).resolve().parents[2]


class FakeModel:
    def __init__(self, candidates):
        self.candidates = list(candidates)
        self.calls = 0

    def generate(self, prompt, response_schema, seed):
        candidate = self.candidates[self.calls]; self.calls += 1
        return ModelResponse("API_SUCCESS", candidate, "{}", {
            "input_tokens": 10, "output_tokens": 5, "total_tokens": 15,
            "reasoning_tokens": 0, "cached_tokens": 0,
        }, 0.01, {"seed": seed}, None)


def _inputs():
    config = load_config(PROJECT / "configs" / "foundation_first.yaml")
    config["lean_timeout_seconds"] = 30
    tasks, source = load_frozen_tasks(PROJECT, config)
    return config, tasks, source


def _trace_lemma(task, name, proof):
    input_type = "EventInput" if task["module"] == "ethmac" else f"{task['module']}Inputs"
    return {
        "lemma_name": name,
        "lemma_statement": (
            f"∀ (guard : {task['state_type']} → {input_type} → Prop) "
            f"(t : {task['state_type']}) (pre : List {input_type}) (item : {input_type}), "
            "R3Temporal.Along r3Step guard t (pre ++ [item]) → guard (r3Run t pre) item"
        ),
        "proof_body": proof, "rationale": "generic trace endpoint bridge", "used_lemmas": [],
    }


GOOD_PROOF = """by
  intro guard t pre
  induction pre generalizing t with
  | nil =>
      intro item h
      exact h.1
  | cons head tail ih =>
      intro item h
      exact ih (r3Step t head) item h.2"""


def test_config_is_foundation_first_and_has_no_direct_arm():
    config, _, _ = _inputs()
    assert config["proof_model"]["model"] == "qwen3.8-flash"
    assert config["prompt_policy"]["direct_target_generation"] is False
    assert "strategies" not in config


def test_frozen_tasks_exclude_answer_bearing_metadata():
    _, tasks, _ = _inputs()
    assert len(tasks) == 10
    for task in tasks:
        assert not ({"reference_proof", "gap_spec", "baseline_lean_error"} & task.keys())


def test_proof_gap_is_generic_and_complete():
    config, tasks, source = _inputs(); task = tasks[0]
    base = theorem_base_for(source, task["dut"])
    retrieved = retrieve_lemmas(task["statement"], base["theorems"], 16)
    foundation = {"attempts": [{"lean_result": {"unsolved_goals": ["⊢ residual"]}}]}
    gap = extract_proof_gap(task, base["theorems"], retrieved, foundation,
                            config["proof_gap_policy"]["version"])
    required = {"target_structure_ast", "target_symbols", "referenced_state_fields",
                "retrieved_lemmas", "covered_subgoals", "residual_uncovered_goals",
                "theorem_dependency_frontier", "temporal_structure", "available_local_relations",
                "missing_relation_class", "lean_unsolved_goals", "evidence",
                "candidate_requirements", "candidate_avoid_rules"}
    assert required <= gap.keys()
    assert gap["missing_relation_class"] == "TRACE_LAST_STEP_LIFT"
    assert "challenge_id" in gap["forbidden_input_fields"]


def test_declaration_in_statement_is_redesigned_not_repaired():
    report = diagnose_lemma(
        "∀ n : Nat, n = n",
        {"lemma_name": "bridge", "lemma_statement": "theorem bridge : ∀ n : Nat, n = n",
         "proof_body": "by intro n; rfl"},
        [{}], ["unexpected token theorem"], [""], "", [], [],
    )
    assert report.failure_level == "STATEMENT"
    assert report.primary_cause == "MALFORMED_LEMMA_DECLARATION"
    assert report.recommended_action == "REDESIGN"


def test_state_drift_and_identical_repair_trigger_specific_redesign():
    candidate = {"lemma_name": "bridge", "lemma_statement": "∀ n : Nat, n = n",
                 "proof_body": "by intro n; rfl"}
    error = ("The argument h has type R3Temporal.Along step guard (step s a) xs "
             "but is expected to have type R3Temporal.Along step guard s xs")
    report = diagnose_lemma(
        "∀ n : Nat, n = n ∧ n = n", candidate,
        [{"candidate": candidate, "diagnosis": {"recommended_action": "REPAIR"},
          "proof_state": "⊢ same"}, {"candidate": candidate, "proof_state": "⊢ same"}],
        [error], ["⊢ same"], "", [], [],
    )
    assert "INDUCTION_STATE_NOT_GENERALIZED" in [report.primary_cause, *report.secondary_causes]
    assert report.proof_progress == "STALLED"
    assert report.recommended_action == "REDESIGN"


def test_current_error_overrides_stale_history_and_detects_singleton_case():
    candidate = {"lemma_name": "bridge", "lemma_statement": "∀ n : Nat, n = n",
                 "proof_body": "by intro n; rfl"}
    stale = ("h has type R3Temporal.Along step guard (step s a) xs but is expected to have type "
             "R3Temporal.Along step guard s xs")
    current = ("Type mismatch: After simplification, term h has type "
               "R3Temporal.Along step guard s [item] but is expected to have type "
               "guard (R3Temporal.exec step s []) item")
    report = diagnose_lemma(
        "∀ n : Nat, n = n ∧ n = n", candidate, [{}], [stale, current], [""], "", [], [],
    )
    assert report.primary_cause == "TRACE_SINGLETON_NOT_DESTRUCTURED"
    assert report.recommended_action == "REPAIR"
    assert any("singleton" in line for line in report.repair_guidance)


def test_kernel_gate_and_generic_property_rescue(tmp_path):
    config, tasks, _ = _inputs(); task = tasks[0]
    lemma = _trace_lemma(task, "r11_c01_t1_trace_last", GOOD_PROOF)
    gate = kernel_gate(PROJECT, tmp_path / "lemma.lean", task, lemma, 30)
    assert gate["success"]
    rescue = run_property_prover(PROJECT, tmp_path / "rescue", task, 30, lemma)
    assert rescue["success"]
    assert rescue["successful_rule"] == "generic_multiphase_trace_bridge"
    assert lemma["lemma_name"] in rescue["successful_proof_body"]


def test_three_phase_manifest_filters_nonlocal_foundation_theorem(tmp_path):
    config, tasks, _ = _inputs(); task = tasks[1]
    lemma = _trace_lemma(task, "r11_c02_t1_trace_last", GOOD_PROOF)
    assert "r3_run_append" in task["foundation_lemmas"]
    rescue = run_property_prover(PROJECT, tmp_path / "three_phase", task, 30, lemma)
    assert rescue["success"]
    assert rescue["successful_rule"] == "generic_multiphase_trace_bridge"


def test_failed_first_candidate_feedback_repairs_and_rescues(tmp_path):
    config, tasks, source = _inputs(); task = tasks[0]
    name = "r11_c01_t1_trace_last"
    bad = _trace_lemma(task, name, "by exact 1")
    good = _trace_lemma(task, name, GOOD_PROOF)
    model = FakeModel([bad, good])
    result = run_trial(PROJECT, tmp_path / "run", task, 1, 123, config, source, "manifest", model)
    assert result["foundation_only_pass"] is False
    assert result["first_candidate_kernel_pass"] is False
    assert result["feedback_candidate_kernel_pass"] is True
    assert result["repair_success"] is True
    assert result["result_status"] == "PROPERTY_RESCUED_BY_LLM_LEMMA"
    assert result["property_rescue"]["verified_lemma_used_by_final"] is True
    assert result["property_rescue"]["ablation_without_candidate_pass"] is False
    assert model.calls == 2
