from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from experiments.adaptive_proving.lean import check_source, synthetic_failure
from experiments.adaptive_proving.proof_model import ModelResponse
from experiments.scale_evaluation.binder import bind_state_transition
from experiments.scale_evaluation.config import load_config
from experiments.scale_evaluation.corpus import load_tasks, verify_tasks
from experiments.scale_evaluation.experiment import VARIANTS, _theorem_source, run_variant
from experiments.scale_evaluation.graph import construct_tpoh
from experiments.scale_evaluation.schemas import (fill_skeleton, plan_witness, select_schema,
    state_skeleton, witness_skeleton)


PROJECT = Path(__file__).resolve().parents[1]


def fixture():
    config = load_config(PROJECT / "configs/scale_evaluation.yaml")
    tasks, source = load_tasks(PROJECT, config)
    return config, tasks, source


class FakeModel:
    def __init__(self, answers):
        self.answers = list(answers)

    def generate(self, prompt, response_schema, seed):
        answer = self.answers.pop(0)
        return ModelResponse("API_SUCCESS", answer, "{}", {"input_tokens": 10,
            "output_tokens": 5, "total_tokens": 15, "cached_tokens": 0}, 0.01, {"seed": seed})


class ScaleEvaluationTests(unittest.TestCase):
    def test_corpus_is_unseen_balanced_and_five_dut(self):
        _, tasks, source = fixture()
        verify_tasks(PROJECT, tasks, source)
        self.assertEqual(len(tasks), 10)
        self.assertEqual(len({task["dut"] for task in tasks}), 5)
        self.assertEqual(sum(task["property_pattern"] == "STATE_TRANSITION" for task in tasks), 5)
        self.assertEqual(sum(task["property_pattern"] == "WITNESS_CONSTRUCTION" for task in tasks), 5)

    def test_same_tpoh_and_schema_selection(self):
        _, tasks, _ = fixture()
        for task in tasks:
            graph = construct_tpoh(task)
            self.assertTrue(graph["construction_success"])
            self.assertEqual(len(graph["missing_hyperedges"]), 1)
            candidate = {"lemma_statement": task["expected_candidate_statement"]}
            selected = select_schema(graph["missing_hyperedges"][0], candidate)
            self.assertTrue(selected["selection_success"])
            self.assertEqual(selected["selected_schema"], task["property_pattern"] + "_SCHEMA")

    def test_typed_binder_and_witness_planner_all_duts(self):
        config, tasks, _ = fixture()
        with tempfile.TemporaryDirectory(prefix="r15-typed-") as raw:
            root = Path(raw)
            for task in tasks:
                graph = construct_tpoh(task)
                candidate = {"lemma_statement": task["expected_candidate_statement"],
                    "candidate_source": graph["initial_nodes"],
                    "candidate_target": graph["backward_target_frontier"][0],
                    "candidate_edge_type": task["property_pattern"]}
                if task["property_pattern"] == "STATE_TRANSITION":
                    typed = bind_state_transition(PROJECT, root / task["challenge_id"], task,
                        candidate, config["lean_timeout_seconds"])
                    self.assertTrue(typed["binding_success"], task["challenge_id"])
                    self.assertFalse(typed["llm_selected_theorem_name"])
                else:
                    plan = plan_witness(PROJECT, root / task["challenge_id"], task, candidate,
                                        config["lean_timeout_seconds"])
                    self.assertTrue(plan["proposal_success"], task["challenge_id"])
                    self.assertTrue(plan["typed_witness_acceptance"], task["challenge_id"])
                    self.assertFalse(plan["llm_proposed_witness"])

    def test_full_skeletons_are_kernel_valid_with_local_holes(self):
        config, tasks, _ = fixture()
        with tempfile.TemporaryDirectory(prefix="r15-skeleton-") as raw:
            root = Path(raw)
            for task in tasks:
                graph = construct_tpoh(task)
                candidate = {"lemma_statement": task["expected_candidate_statement"],
                    "candidate_source": graph["initial_nodes"],
                    "candidate_target": graph["backward_target_frontier"][0],
                    "candidate_edge_type": task["property_pattern"]}
                if task["property_pattern"] == "STATE_TRANSITION":
                    artifact = bind_state_transition(PROJECT, root / "bind" / task["challenge_id"],
                        task, candidate, config["lean_timeout_seconds"])
                    skeleton, _ = state_skeleton(candidate, artifact)
                    proof = fill_skeleton(skeleton, {"HOLE_MAIN": "exact transition_result"})
                else:
                    artifact = plan_witness(PROJECT, root / "witness" / task["challenge_id"],
                        task, candidate, config["lean_timeout_seconds"])
                    skeleton, _ = witness_skeleton(task, artifact)
                    proof = fill_skeleton(skeleton, {"HOLE_NONEMPTY": "simp",
                        "HOLE_OBLIGATION": "rfl"})
                result = check_source(_theorem_source(task, "r15_schema_reference",
                    task["expected_candidate_statement"], proof, True), PROJECT / task["model_dir"],
                    root / "proof" / f"{task['challenge_id']}.lean", config["lean_timeout_seconds"])
                self.assertTrue(result["success"], f"{task['challenge_id']}: {result['stderr']}")

    def test_paired_variants_share_candidate_and_no_direct_arm(self):
        config, tasks, source = fixture()
        for task in [tasks[0], tasks[1]]:
            graph = construct_tpoh(task)
            candidate = {"lemma_name": f"r15_{task['challenge_id'].lower()}_candidate_exact",
                "lemma_statement": task["expected_candidate_statement"],
                "candidate_source": graph["initial_nodes"],
                "candidate_target": graph["backward_target_frontier"][0],
                "candidate_edge_type": task["property_pattern"], "bridge_reason": "exact frontier"}
            shared = {"draw_id": f"r15:{task['challenge_id']}:42", "graph": graph,
                "selected": {"candidate": candidate}, "candidate_utility_pass": True}
            with tempfile.TemporaryDirectory(prefix="r15-paired-") as raw:
                run = Path(raw)
                for variant in VARIANTS:
                    if variant == "legacy_untyped_control":
                        answers = [{"proof_body": task["reference_candidate_proof"], "proof_idea": "reference"}]
                    elif task["property_pattern"] == "STATE_TRANSITION":
                        answers = [{"HOLE_MAIN": "exact transition_result", "proof_idea": "bound result"}]
                    else:
                        answers = [{"HOLE_NONEMPTY": "simp", "HOLE_OBLIGATION":
                            "rfl", "proof_idea": "append singleton"}]
                    result = run_variant(PROJECT, run, task, variant, shared, source, config,
                        FakeModel(answers), synthetic_failure("foundation gap"), 42)
                    self.assertTrue(result["property_rescue"], variant)
                    self.assertFalse(result["direct_arm"])
                    self.assertEqual(result["candidate_draw_id"], shared["draw_id"])


if __name__ == "__main__":
    unittest.main()
