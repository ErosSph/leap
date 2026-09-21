from __future__ import annotations

import json
import subprocess
from pathlib import Path

from rtl2lean.model_calibration.backend import CodexCLIBackend, LLMBackend, _output_text
from rtl2lean.model_calibration.runner import (
    classify_failure, normalize_result_classification,
)


PROJECT = Path(__file__).resolve().parents[1]
R10 = PROJECT / "outputs" / "model_calibration"


def test_backend_reports_missing_key_without_a_request(monkeypatch) -> None:
    monkeypatch.delenv("R10A_TEST_KEY", raising=False)
    result = LLMBackend().generate("prompt", {
        "provider": "test", "model_id": "test-model", "api_key_env": "R10A_TEST_KEY",
        "endpoint": "https://invalid.example/responses", "reasoning_profile": "high",
    }, {"max_output_tokens": 8, "provider_timeout_s": 1})
    assert result.status == "MISSING_API_KEY"
    assert result.proof_body is None
    assert "R10A_TEST_KEY" in result.error


def test_responses_output_text_ignores_reasoning_items() -> None:
    payload = {"output": [
        {"type": "reasoning", "content": [{"type": "reasoning_text", "text": "private"}]},
        {"type": "message", "content": [{"type": "output_text", "text": '{"proof_body":"by rfl"}'}]},
    ]}
    assert _output_text(payload) == '{"proof_body":"by rfl"}'


def test_codex_fallback_uses_isolated_account_auth(monkeypatch, tmp_path) -> None:
    original_home = tmp_path / "original-codex-home"
    original_home.mkdir()
    (original_home / "auth.json").write_text('{"auth_mode":"test"}')
    monkeypatch.setenv("CODEX_HOME", str(original_home))
    monkeypatch.setenv("OPENAI_API_KEY", "must-not-reach-child")
    monkeypatch.setattr("shutil.which", lambda name: "/fake/codex")
    observed = {}

    def fake_run(command, **kwargs):
        if command[-1] == "--version":
            return subprocess.CompletedProcess(command, 0, "codex-cli test\n", "")
        response = Path(command[command.index("--output-last-message") + 1])
        response.write_text('{"proof_body":"by trivial","rationale":"test"}')
        observed.update(kwargs["env"])
        return subprocess.CompletedProcess(command, 0, "tokens used\n1,234\n", "")

    monkeypatch.setattr(subprocess, "run", fake_run)
    result = CodexCLIBackend().generate(
        "same frozen prompt", {"model_id": "gpt-5.6-sol", "reasoning_profile": "high"},
        {"provider_timeout_s": 300},
    )
    assert result.status == "API_SUCCESS"
    assert result.proof_body == "by trivial"
    assert result.usage["total_tokens"] == 1234
    assert "OPENAI_API_KEY" not in observed
    assert observed["CODEX_HOME"] != str(original_home)


def test_failure_taxonomy_covers_required_lean_categories() -> None:
    assert classify_failure("unknown identifier x", "by exact x") == "UNKNOWN_IDENTIFIER"
    assert classify_failure("unexpected token", "by exact x") == "SYNTAX_ERROR"
    assert classify_failure("application type mismatch", "by exact x") == "TYPE_ERROR"
    assert classify_failure("unsolved goals", "by constructor") == "INCOMPLETE_PROOF"
    assert classify_failure("", "by exact h", exhausted=True) == "TOKEN_BUDGET_EXHAUSTED"
    row = {
        "final_pass": False, "status": "UNSOLVED",
        "failure_category": "REPAIR_BUDGET_EXHAUSTED",
        "attempts": [{"response_metadata": {
            "incomplete_details": {"reason": "max_output_tokens"},
        }}],
    }
    normalized = normalize_result_classification(row)
    assert normalized["failure_category"] == "TOKEN_BUDGET_EXHAUSTED"
    assert normalized["lean_error_category"] == "TOKEN_BUDGET_EXHAUSTED"


def test_frozen_corpus_is_balanced_distinct_and_kernel_validated() -> None:
    frozen = json.loads((R10 / "calibration_manifest.json").read_text())
    tasks = json.loads((R10 / "manifests" / "tasks.json").read_text())
    validation = json.loads((R10 / "manifests" / "validation.json").read_text())
    assert frozen["frozen_before_api_calls"]
    assert frozen["expected_runs"] == 135
    assert tasks["difficulty_counts"] == {"EASY": 5, "MEDIUM": 5, "HARD": 5}
    assert tasks["excluded_multi_phase_proofs_bottleneck_challenges"]
    assert all(row["kernel_validated"] for row in validation["rows"])
    assert all("preA" in row["statement"] and "preB" in row["statement"]
               for row in tasks["tasks"] if row["difficulty"] == "HARD")


def test_frozen_prompts_are_model_neutral_and_within_budget() -> None:
    prompts = json.loads((R10 / "manifests" / "prompts.json").read_text())
    budget = json.loads((R10 / "manifests" / "budgets.json").read_text())
    assert len(prompts["rows"]) == 45
    assert all(row["estimated_input_tokens"] <= budget["max_input_tokens"]
               for row in prompts["rows"])
    forbidden = ("gpt-5.6-sol", "deepseek-v4-pro", "deepseek-v4-flash")
    assert all(not any(name in row["prompt"] for name in forbidden) for row in prompts["rows"])


def test_authorized_transport_amendment_preserves_frozen_inputs() -> None:
    amendment = json.loads(
        (R10 / "manifests" / "transport_amendment_codex_fallback.json").read_text()
    )
    assert amendment["post_freeze_amendment"] and amendment["user_authorized"]
    assert amendment["affected_model_key"] == "gpt"
    assert amendment["new_transport"]["kind"] == "codex_cli"
    assert "frozen_prompt_hashes" in amendment["unchanged_conditions"]
