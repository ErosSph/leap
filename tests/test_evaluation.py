from pathlib import Path
import os
import subprocess
import sys

from rtl2lean.evaluation.corpus import _trivial_reasons
from rtl2lean.evaluation.experiment import _order
from rtl2lean.proving.llm_prover import CodexCLIProvider


def test_trivial_audit_uses_kernel_accepted_proof_not_candidate_text():
    target = {"theorem_statement": "∀ x : Nat, x = x", "property_family": "state_safety"}
    reasons = _trivial_reasons(target, {"status": "PASS", "proof": "by intro x; rfl"})
    assert "PURE_RFL" in reasons
    # A failed rfl candidate is not itself evidence that a non-reflexive target is trivial.
    target = {"theorem_statement": "∀ x : Nat, x = 0", "property_family": "semantic"}
    assert "PURE_RFL" not in _trivial_reasons(target, {"status": "UNSOLVED", "proof": "by rfl"})


def test_reachable_bitvector_range_is_still_a_type_truism():
    target = {
        "theorem_statement": "∀ s, Reachable s → StateWidthInvariant s",
        "property_family": "reachable_state_invariant",
    }
    assert "TYPE_OR_FUNCTION_TRUISM" in _trivial_reasons(target, None)


def test_property_orders_are_deterministic():
    properties = [
        {"property_id": "b", "property_family": "finite_reachability_witness",
         "dependency_cone": {"total": 5}},
        {"property_id": "a", "property_family": "control_transition",
         "dependency_cone": {"total": 2}},
    ]
    assert [item["property_id"] for item in _order(properties, "lexical")] == ["a", "b"]
    assert [item["property_id"] for item in _order(properties, "reverse")] == ["b", "a"]
    assert [item["property_id"] for item in _order(properties, "dependency")] == ["a", "b"]


def test_direct_ablation_prompt_forbids_new_intermediate(tmp_path: Path):
    provider = CodexCLIProvider(executable="codex", workdir=tmp_path)
    prompt = provider._prompt({
        "mode": "DIRECT_TARGET",
        "proof_task": {"target_name": "p", "target_statement": "True",
                       "property_type": "semantic", "assumptions": [],
                       "context_snippets": [], "relevant_foundational_lemmas": [],
                       "future_targets": []},
        "lean_feedback": "", "retrieved_lemmas": [], "attempt_history": [],
    })
    assert "no-new-intermediate ablation arm" in prompt
    assert "do not propose" in prompt


def test_shared_pool_prompt_requires_exact_target_and_no_new_lemma(tmp_path: Path):
    provider = CodexCLIProvider(executable="codex", workdir=tmp_path)
    prompt = provider._prompt({
        "mode": "TARGET_WITH_REUSE",
        "proof_task": {"target_name": "p", "target_statement": "True",
                       "property_type": "semantic", "assumptions": [],
                       "context_snippets": [], "relevant_foundational_lemmas": [],
                       "future_targets": []},
        "lean_feedback": "", "retrieved_lemmas": [], "attempt_history": [],
    })
    assert "shared-pool reuse arm" in prompt
    assert "Do not generate a new intermediate lemma" in prompt


def test_model_generation_is_hash_seed_deterministic():
    fixture = Path(__file__).parent / "fixtures" / "semantic_features.v"
    script = f"""
import hashlib
from rtl2lean.frontend import SVParser
from rtl2lean.middle_end.ir_converter import module_to_ir
from rtl2lean.middle_end.optimizer import Optimizer
from rtl2lean.middle_end.ir import normalize_combinational_schedule
from rtl2lean.backend.codegen import CodeGenerator
ast = SVParser().parse_files([{str(fixture)!r}], 'semantic_features')[0]
ir = normalize_combinational_schedule(Optimizer.optimize(module_to_ir(ast), 2))
print(hashlib.sha256(CodeGenerator.generate(ir).encode()).hexdigest())
"""
    hashes = []
    for seed in ("1", "271828"):
        env = os.environ.copy()
        env["PYTHONHASHSEED"] = seed
        hashes.append(subprocess.check_output([sys.executable, "-c", script], env=env, text=True).strip())
    assert hashes[0] == hashes[1]
