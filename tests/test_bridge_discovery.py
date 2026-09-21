from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from experiments.adaptive_proving.proof_model import ModelResponse
from experiments.bridge_discovery.bridge import build_bridge_specification, build_global_bridge_view
from experiments.bridge_discovery.config import load_config
from experiments.bridge_discovery.corpus import load_corpora, theorem_base_for, verify_corpora
from experiments.bridge_discovery.prover import run_foundation_prover
from experiments.bridge_discovery.repair_templates import lookup
from experiments.bridge_discovery.trial import run_trial
from experiments.bridge_discovery.utility import evaluate_candidate
from experiments.foundation_first.proof_gap import extract_proof_gap, retrieve_lemmas


PROJECT = Path(__file__).resolve().parents[1]


def corpora():
    config = load_config(PROJECT / "configs/bridge_discovery.yaml")
    development, evaluation, source = load_corpora(PROJECT, config)
    return config, development, evaluation, source


class FakeModel:
    def __init__(self, target: dict):
        prefix = "r12_e02_t1_"
        self.statement = "∀ (step : σ → ι → σ) (guard : σ → ι → Prop) (s : σ) (pre : List ι) (item : ι), R3Temporal.Along step guard s (pre ++ [item]) → guard (R3Temporal.exec step s pre) item"
        common = {"new_candidate_source": "Along over prefix plus last",
                  "new_candidate_target": "guard at the prefix endpoint",
                  "how_it_bridges_gap": "extracts the final guard needed by local_step",
                  "which_previous_failure_is_avoided": "avoids an exec-only identity"}
        self.slate = {"candidates": [
            {"lemma_name": prefix + "last_guard", "lemma_statement": self.statement, **common},
            {"lemma_name": prefix + "target_copy", "lemma_statement": target["statement"], **common},
            {"lemma_name": prefix + "exec_only", "lemma_statement":
             "∀ (step : σ → ι → σ) (s : σ) (xs : List ι) (x : ι), R3Temporal.exec step s (xs ++ [x]) = step (R3Temporal.exec step s xs) x", **common},
        ]}
        self.proof = {"proof_body": """by
  intro step guard s pre item h
  induction pre generalizing s with
  | nil =>
    simp at h ⊢
    exact h.1
  | cons a as ih =>
    have h' := h
    simp [List.cons_append, R3Temporal.Along] at h'
    exact ih (step s a) h'.2""", "rationale": "generalize evolving state", "used_lemmas": []}

    def generate(self, prompt, schema, seed):
        value = self.slate if "candidates" in schema.get("properties", {}) else self.proof
        return ModelResponse("API_SUCCESS", value, "{}", {"total_tokens": 1}, 0.001,
                             {"provider": "fake", "credential_recorded": False})


class BridgeDiscoveryTests(unittest.TestCase):
    def test_frozen_split_is_disjoint(self):
        config, development, evaluation, source = corpora()
        verify_corpora(PROJECT, development, evaluation, source)
        self.assertEqual((len(development), len(evaluation)), (10, 10))
        self.assertTrue(source["sets_disjoint"])
        self.assertTrue(all("reference_proof" not in row and "gap_spec" not in row for row in evaluation))

    def test_repair_templates_are_generic(self):
        self.assertEqual(lookup("INDUCTION_STATE_NOT_GENERALIZED")["template_id"],
                         "RT_INDUCTION_GENERALIZE_STATE_V1")
        self.assertIsNone(lookup("DUT_SPECIAL_CASE"))

    def test_foundation_reuses_named_local_step(self):
        config, _, evaluation, _ = corpora()
        with tempfile.TemporaryDirectory() as raw:
            result = run_foundation_prover(PROJECT, Path(raw), evaluation[0], 30)
        self.assertTrue(result["success"])
        self.assertEqual(result["proof_source"], "EXISTING_FOUNDATION_LEMMA")

    def test_exec_identity_is_low_and_last_guard_is_high(self):
        config, _, evaluation, source = corpora(); task = evaluation[1]
        base = theorem_base_for(source, task["dut"])
        bridge = {"missing_relation_class": "LAST_STEP_GUARD"}
        bad = {"lemma_name": "bad", "lemma_statement":
            "∀ (step : σ → ι → σ) (s : σ) (xs : List ι) (x : ι), R3Temporal.exec step s (xs ++ [x]) = step (R3Temporal.exec step s xs) x"}
        good = {"lemma_name": "good", "lemma_statement":
            "∀ (step : σ → ι → σ) (guard : σ → ι → Prop) (s : σ) (pre : List ι) (item : ι), R3Temporal.Along step guard s (pre ++ [item]) → guard (R3Temporal.exec step s pre) item"}
        with tempfile.TemporaryDirectory() as raw:
            bad_result = evaluate_candidate(PROJECT, Path(raw) / "bad", task, bad, bridge,
                                            base["theorems"], 30, .6)
            good_result = evaluate_candidate(PROJECT, Path(raw) / "good", task, good, bridge,
                                             base["theorems"], 30, .6)
        self.assertEqual(bad_result["classification"], "LOW_TARGET_UTILITY")
        self.assertTrue(bad_result["proof_attempt_avoided"])
        self.assertEqual(good_result["classification"], "HIGH_TARGET_UTILITY")

    def test_bridge_spec_has_required_fields(self):
        config, _, evaluation, source = corpora(); task = evaluation[1]
        base = theorem_base_for(source, task["dut"]); retrieved = retrieve_lemmas(task["statement"], base["theorems"], 16)
        fake_failure = {"attempts": []}
        gap = extract_proof_gap(task, base["theorems"], retrieved, fake_failure, "test")
        bridge = build_bridge_specification(task, gap); view = build_global_bridge_view(task, gap, bridge)
        for key in ("source_frontier", "target_frontier", "available_premises", "required_conclusion_shape",
                    "missing_relation_class", "temporal_scope", "state_fields", "candidate_requirements",
                    "candidate_avoid"):
            self.assertIn(key, bridge)
        self.assertEqual(bridge["missing_relation_class"], "LAST_STEP_GUARD")
        self.assertIn("bridge_source", view)

    def test_statement_and_proof_are_separate_integration(self):
        config, _, evaluation, source = corpora(); task = evaluation[1]
        with tempfile.TemporaryDirectory() as raw:
            run_dir = Path(raw)
            result = run_trial(PROJECT, run_dir, task, 1, 123, config, source, "fake-manifest", FakeModel(task))
        self.assertEqual([row["operation"] for row in result["proof_attempts"]], ["PROVE"])
        self.assertEqual(result["model_calls"], 2)
        self.assertEqual(result["result_status"], "PROPERTY_RESCUED_BY_LLM_LEMMA")


if __name__ == "__main__":
    unittest.main()
