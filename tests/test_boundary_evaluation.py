from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from experiments.adaptive_proving.lean import check_source, synthetic_failure
from experiments.adaptive_proving.proof_model import ModelResponse
from experiments.hypergraph_guidance.hypergraph import EDGE_TYPES, NODE_TYPES
from experiments.boundary_evaluation.config import load_config
from experiments.boundary_evaluation.corpus import PATTERNS, load_tasks, verify_tasks
from experiments.boundary_evaluation.experiment import (
    VARIANTS, candidate_prompt, fill, formal_match, proof_prompt, representation,
    run_variant, skeleton_for, theorem_source,
)
from experiments.boundary_evaluation.report import build_report


PROJECT = Path(__file__).resolve().parents[1]


def fixture():
    config = load_config(PROJECT / "configs/boundary_evaluation.yaml")
    tasks, source = load_tasks(PROJECT, config)
    return config, tasks, source


def valid_holes(task):
    pattern = task["property_pattern"]
    if pattern == "TEMPORAL_LIFT":
        return {"HOLE_BASE_CASE": "exact h.1", "HOLE_STEP_CASE": "exact ih (r3Step s head) h_tail.2", "HOLE_MAIN": "", "proof_idea": "induct on prefix"}
    if pattern == "WITNESS_CONSTRUCTION":
        return {"HOLE_BASE_CASE": "", "HOLE_STEP_CASE": "", "HOLE_MAIN": "simp", "proof_idea": "reverse twice"}
    if pattern == "REWRITE_CHAIN":
        return {"HOLE_BASE_CASE": "", "HOLE_STEP_CASE": "", "HOLE_MAIN": "rw [R3Temporal.exec_append, R3Temporal.exec_append]", "proof_idea": "rewrite twice"}
    if pattern == "STATE_TRANSITION":
        proof = task["reference_candidate_proof"]
        return {"HOLE_BASE_CASE": "", "HOLE_STEP_CASE": "", "HOLE_MAIN": proof.split("by intro s xs h; exact ", 1)[1].join(["exact ", ""]), "proof_idea": "apply transition theorem"}
    if pattern == "CASE_ANALYSIS":
        return {"HOLE_BASE_CASE": "exact Or.inl rfl", "HOLE_STEP_CASE": "exact Or.inr ⟨head, tail, rfl⟩", "HOLE_MAIN": "", "proof_idea": "constructors"}
    return {"HOLE_BASE_CASE": "", "HOLE_STEP_CASE": "", "HOLE_MAIN": "exact ⟨last s p1 i1 h1, last (R3Temporal.exec step s (p1 ++ [i1])) p2 i2 h2⟩", "proof_idea": "two phases"}


class FakeModel:
    def __init__(self, responses):
        self.responses = list(responses)

    def generate(self, prompt, response_schema, seed):
        candidate = self.responses.pop(0)
        return ModelResponse("API_SUCCESS", candidate, "{}", {"input_tokens": 10, "output_tokens": 5, "total_tokens": 15, "cached_tokens": 0}, 0.01, {"seed": seed})


class BoundaryEvaluationTests(unittest.TestCase):
    def test_unseen_corpus_has_two_per_pattern(self):
        _, tasks, source = fixture()
        verify_tasks(PROJECT, tasks, source)
        self.assertEqual(len(tasks), 12)
        self.assertTrue(source["sets_disjoint"])
        self.assertEqual({p: sum(t["property_pattern"] == p for t in tasks) for p in PATTERNS}, {p: 2 for p in PATTERNS})

    def test_unified_tpoh_taxonomy_and_multiphase_edges(self):
        _, tasks, _ = fixture()
        for task in tasks:
            graph = representation(task, True)
            self.assertEqual(graph["node_taxonomy"], NODE_TYPES)
            self.assertEqual(graph["edge_taxonomy"], EDGE_TYPES)
            self.assertTrue(graph["missing_hyperedges"])
            self.assertFalse(graph["challenge_specific_rules"])
            self.assertFalse(graph["dut_specific_rules"])
        phases = [representation(t, True) for t in tasks if t["property_pattern"] == "PHASE_TO_PHASE"]
        self.assertTrue(all(len(g["missing_hyperedges"]) >= 3 for g in phases))

    def test_all_skeletons_accept_known_good_holes(self):
        _, tasks, _ = fixture()
        with tempfile.TemporaryDirectory(prefix="r14-skeleton-") as raw:
            for task in tasks:
                candidate = {"lemma_statement": task["expected_candidate_statement"], "candidate_edge_type": "TEMPORAL_LIFT"}
                skeleton, _ = skeleton_for(task, candidate)
                proof = fill(skeleton, valid_holes(task))
                result = check_source(theorem_source(task, "r14_reference", task["expected_candidate_statement"], proof, True), PROJECT / task["model_dir"], Path(raw) / f"{task['challenge_id']}.lean", 30)
                self.assertTrue(result["success"], f"{task['challenge_id']}: {result['stderr']}")

    def test_formal_match_uses_node_refs_and_lean(self):
        config, tasks, _ = fixture()
        task = tasks[2]
        graph = representation(task, True)
        base = {"lemma_statement": task["expected_candidate_statement"], "candidate_source": graph["initial_nodes"], "candidate_target": graph["backward_target_frontier"][0]}
        with tempfile.TemporaryDirectory(prefix="r14-formal-") as raw:
            good = formal_match(PROJECT, Path(raw) / "good", task, base, graph, config["lean_timeout_seconds"])
            bad = formal_match(PROJECT, Path(raw) / "bad", task, {**base, "candidate_target": "not_a_node"}, graph, config["lean_timeout_seconds"])
        self.assertTrue(good["FORMAL_UTILITY_PASS"])
        self.assertTrue(good["definitional_equality_match"])
        self.assertEqual(good["graph_match_class"], "GRAPH_MATCH_TRUE_POSITIVE")
        self.assertEqual(bad["graph_match_class"], "GRAPH_MATCH_FALSE_NEGATIVE")

    def test_prompts_do_not_leak_variant_labels(self):
        _, tasks, source = fixture()
        task = tasks[2]
        graph = representation(task, True)
        prompts = [candidate_prompt(task, v, graph, "", 42) for v in ["tpoh_no_skeleton", "tpoh_skeleton_no_aligner", "full_tpoh"]]
        self.assertEqual(prompts[0], prompts[1])
        self.assertEqual(prompts[1], prompts[2])
        candidate = {"lemma_name": "r14_r03_candidate_exact", "lemma_statement": task["expected_candidate_statement"]}
        skeleton, meta = skeleton_for(task, candidate)
        align = {"enabled": True, "matched_premises": [], "missing_premises": [], "argument_mapping": [], "type_mismatches": [], "equality_direction": "NOT_APPLICABLE"}
        self.assertEqual(proof_prompt(task, candidate, "bridge_skeleton", skeleton, meta, align, ""), proof_prompt(task, candidate, "full_tpoh", skeleton, meta, align, ""))

    def test_fake_model_runs_all_four_arms(self):
        config, tasks, source = fixture()
        task = tasks[2]
        with tempfile.TemporaryDirectory(prefix="r14-arms-") as raw:
            run = Path(raw)
            shared = None
            for variant in VARIANTS:
                rep = representation(task, VARIANTS[variant]["tpoh"])
                sources = [n["node_id"] for n in rep["source_frontier"]] if rep["kind"] == "BRIDGE_SPECIFICATION" else rep["initial_nodes"]
                target = rep["target_frontier"]["node_id"] if rep["kind"] == "BRIDGE_SPECIFICATION" else rep["backward_target_frontier"][0]
                candidates = [{"lemma_name": f"r14_r03_candidate_{i}", "lemma_statement": task["expected_candidate_statement"], "candidate_source": sources, "candidate_target": target, "candidate_edge_type": "CANDIDATE_LEMMA", "bridge_reason": "exact typed frontier"} for i in range(1, 4)]
                proof = valid_holes(task) if VARIANTS[variant]["skeleton"] else {"proof_body": task["reference_candidate_proof"], "proof_idea": "reverse twice"}
                if VARIANTS[variant]["tpoh"]:
                    if shared is None:
                        response = ModelResponse("API_SUCCESS", {"candidates": candidates}, "{}", {"input_tokens": 10, "output_tokens": 5, "total_tokens": 15, "cached_tokens": 0}, 0.01, {"seed": 42}).serializable()
                        shared = {"operation": "CANDIDATE", "response": response, "physical_call": True, "shared_draw_id": "tpoh:R03:42"}
                    model, override = FakeModel([proof]), shared
                else:
                    model, override = FakeModel([{"candidates": candidates}, proof]), None
                result = run_variant(PROJECT, run, task, variant, 42, config, source, model, synthetic_failure("expected foundation gap"), override)
                self.assertTrue(result["property_rescue"], variant)
                self.assertEqual(result["skeleton_enabled"], VARIANTS[variant]["skeleton"])
                self.assertEqual(result["candidate_draw_shared"], VARIANTS[variant]["tpoh"])
                if not VARIANTS[variant]["skeleton"]:
                    self.assertIsNone(result["schema_id"])
            report = build_report(run, [task], list(VARIANTS))
            self.assertEqual(report["candidate_randomization_control"], "PASS")
            self.assertTrue((run / "tables" / "ablation.csv").is_file())


if __name__ == "__main__":
    unittest.main()
