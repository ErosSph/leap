from __future__ import annotations

from pathlib import Path

from experiments.adaptive_proving.config import load_config
from experiments.adaptive_proving.lemma_diagnosis import diagnose_lemma
from experiments.adaptive_proving.proof_model import ModelResponse, OpenAICompatibleChatProofModel
from experiments.adaptive_proving.report import evaluate_phase_b_trigger
from experiments.adaptive_proving.strategies import run_trial


PROJECT = Path(__file__).resolve().parents[2]


class FakeModel:
    def __init__(self, candidates):
        self.candidates = list(candidates)
        self.calls = 0

    def generate(self, prompt, response_schema, seed):
        candidate = self.candidates[self.calls]
        self.calls += 1
        return ModelResponse(
            "API_SUCCESS", candidate, "{}",
            {"input_tokens": 10, "output_tokens": 5, "total_tokens": 15,
             "reasoning_tokens": 0, "cached_tokens": 0},
            0.01, {"seed": seed}, None,
        )


def config():
    value = load_config(PROJECT / "configs" / "adaptive_proving.yaml")
    value["lean_timeout_seconds"] = 30
    return value


def task():
    statement = "∀ (n : Nat), Nat.succ n = n + 1 ∧ n = n"
    return {
        "challenge_id": "C01", "task_id": "target", "dut": "demo", "module": "Nat",
        "model_dir": "model", "context_import": "Init", "statement": statement,
        "statement_sha256": __import__("hashlib").sha256(statement.encode()).hexdigest(),
        "context": "theorem Nat.succ_eq_add_one_demo : ∀ n : Nat, Nat.succ n = n + 1 := by intro n; rfl",
        "context_sha256": "context", "baseline_lean_error": "unsolved goals",
        "relevant_foundational_lemmas": [],
    }


def source():
    return {"theorem_bases": [{
        "dut": "demo", "tree_sha256": "base", "theorems": [
            {"name": "Nat.zero_eq", "statement": "(0 : Nat) = 0"},
        ],
    }]}


def test_frozen_config():
    value = config()
    assert value["proof_model"]["model"] == "qwen3.8-flash"
    assert value["proof_model"]["provider"] == "dashscope_openai_compatible"
    assert value["proof_model"]["token_limit_policy"] == "provider_default_no_client_token_cap"
    for key in ("max_completion_tokens", "max_tokens", "thinking_budget", "reasoning_effort"):
        assert key not in value["proof_model"]
    assert value["max_total_calls"] == 10
    assert value["checkpoints"] == [3, 5, 8, 10]


def test_api_payload_has_no_token_or_reasoning_cap(monkeypatch):
    captured = {}

    class Response:
        status = 200

        def __enter__(self):
            return self

        def __exit__(self, *args):
            return False

        def read(self):
            return (b'{"id":"test","model":"qwen3.8-flash","choices":'
                    b'[{"finish_reason":"stop","message":{"content":"{\\"status\\":\\"ok\\"}"}}],'
                    b'"usage":{"prompt_tokens":1,"completion_tokens":1,"total_tokens":2}}')

    def fake_urlopen(request, timeout):
        captured["payload"] = __import__("json").loads(request.data)
        return Response()

    monkeypatch.setenv("DASHSCOPE_API_KEY", "test-only-secret")
    monkeypatch.setattr("urllib.request.urlopen", fake_urlopen)
    model = OpenAICompatibleChatProofModel(config()["proof_model"])
    response = model.generate("health", {
        "type": "object", "properties": {"status": {"type": "string"}},
        "required": ["status"], "additionalProperties": False,
    }, 10)
    assert response.status == "API_SUCCESS"
    for key in ("max_completion_tokens", "max_tokens", "thinking_budget", "reasoning_effort"):
        assert key not in captured["payload"]
    assert captured["payload"]["response_format"]["type"] == "json_schema"
    assert captured["payload"]["seed"] == 10


def test_diagnosis_selects_repair_for_syntax():
    report = diagnose_lemma(
        "∀ n : Nat, Nat.succ n = n + 1 ∧ n = n",
        {"lemma_name": "bridge", "lemma_statement": "∀ n : Nat, Nat.succ n = n + 1", "proof_body": "by ("},
        [{}], ["unexpected token ')'"], ["⊢ ∀ n : Nat, Nat.succ n = n + 1"], "", [], [],
    )
    assert report.primary_cause == "PROOF_SYNTAX_ERROR"
    assert report.recommended_action == "REPAIR"


def test_diagnosis_rejects_target_duplicate():
    target = "∀ n : Nat, n = n"
    report = diagnose_lemma(
        target, {"lemma_name": "bridge", "lemma_statement": target, "proof_body": "by rfl"},
        [{}], ["unsolved goals"], [target], "", [], [],
    )
    assert report.primary_cause == "LEMMA_TOO_CLOSE_TO_TARGET"
    assert report.recommended_action == "REDESIGN"


def test_failed_repair_is_rediagnosed_and_can_redesign():
    goal = "⊢ ∀ n : Nat, Nat.succ n = n + 1"
    previous = {"proof_state": goal, "diagnosis": {"recommended_action": "REPAIR"}}
    report = diagnose_lemma(
        "∀ n : Nat, Nat.succ n = n + 1 ∧ n = n",
        {"lemma_name": "bridge", "lemma_statement": "∀ n : Nat, Nat.succ n = n + 1", "proof_body": "by exact 1"},
        [previous, {"proof_state": goal}], ["type mismatch"], [goal], "Nat.succ", [], [],
    )
    assert report.proof_progress == "STALLED"
    assert report.primary_cause == "LEMMA_SELECTION_FAILURE"
    assert report.recommended_action == "REDESIGN"


def test_adaptive_kernel_gate_repair_and_resume(tmp_path):
    project = tmp_path / "project"
    run_dir = project / "run"
    (project / "model").mkdir(parents=True)
    name = "r10c_c01_t1_bridge"
    model = FakeModel([
        {"lemma_name": name, "lemma_statement": "∀ n : Nat, Nat.succ n = n + 1",
         "proof_body": "by exact (show False from by trivial)", "rationale": "bad",
         "used_lemmas": []},
        {"lemma_name": name, "lemma_statement": "∀ n : Nat, Nat.succ n = n + 1", "proof_body": "by intro n; rfl",
         "rationale": "fixed", "used_lemmas": []},
        {"proof_body": f"by intro n; constructor; exact {name} n; rfl", "rationale": "use bridge",
         "used_lemmas": [name]},
    ])
    result = run_trial(
        project, run_dir, "phaseA", "diagnosis_guided_adaptive_lemma_first", task(), 1,
        123, config(), source(), "manifest", model,
    )
    assert result["final_pass"] is True
    assert result["model_calls"] == 3
    assert result["diagnosis_count"] == 1
    assert result["proof_repair_count"] == 1
    assert result["intermediate_lemma_kernel_pass"] is True
    assert result["intermediate_lemma_used_by_final"] is True
    calls = model.calls
    resumed = run_trial(
        project, run_dir, "phaseA", "diagnosis_guided_adaptive_lemma_first", task(), 1,
        123, config(), source(), "manifest", model,
    )
    assert resumed == result
    assert model.calls == calls


def test_pre_registered_phase_b_trigger():
    rows = []
    for index in range(10):
        for strategy in ("direct", "diagnosis_guided_adaptive_lemma_first"):
            passed = strategy != "direct" or index >= 2
            rows.append({
                "phase": "phaseA", "challenge_id": f"C{index+1:02d}", "task_id": str(index),
                "dut": "d", "trial_id": 1, "strategy": strategy, "final_pass": passed,
                "success_by_checkpoint": {str(cp): passed for cp in [3, 5, 8, 10]},
                "verified_intermediate_lemma": None, "diagnoses": [],
                "intermediate_lemma_kernel_pass": False, "intermediate_lemma_used_by_final": False,
            })
    result = evaluate_phase_b_trigger(rows, config())
    assert result["direct_fail_adaptive_pass"] == 2
    assert result["pilot_signal"] is True
