from __future__ import annotations

from pathlib import Path
from typing import Any

from experiments.adaptive_proving.config import ConfigError, load_yaml
from . import EXPERIMENT_VERSION


def _expect(condition: bool, message: str) -> None:
    if not condition:
        raise ConfigError(message)


def validate_config(config: dict[str, Any]) -> None:
    _expect(config.get("experiment_version") == EXPERIMENT_VERSION, "wrong experiment_version")
    _expect(config.get("max_total_calls") == 6, "Req12 freezes max_total_calls=6")
    _expect(config.get("candidate_statements_per_call") == 3, "Req12 freezes three statement candidates")
    _expect(config.get("trial_ids") == [1], "Req12 v1 uses one frozen unseen trial")
    model = config.get("proof_model") or {}
    _expect(model.get("provider") == "dashscope_openai_compatible", "DashScope provider required")
    _expect(model.get("model") == "qwen3.8-flash", "Note requires qwen3.8-flash")
    _expect(model.get("api_key_env") == "DASHSCOPE_API_KEY", "credential must use environment")
    _expect(model.get("endpoint") == "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions",
            "endpoint differs from Note")
    prompt = config.get("prompt_policy") or config.get("prompt") or {}
    _expect(prompt.get("multi_candidate_mode") is True, "multi-candidate mode must be frozen")
    _expect(prompt.get("statement_proof_separated") is True, "statement/proof calls must be separated")
    _expect(prompt.get("direct_target_generation") is False, "Direct is forbidden")
    bridge = config.get("bridge_policy") or {}
    _expect(bridge.get("challenge_specific_rules") is False, "challenge-specific bridge rules forbidden")
    _expect(bridge.get("dut_specific_rules") is False, "DUT-specific bridge rules forbidden")


def load_config(path: Path) -> dict[str, Any]:
    result = load_yaml(path.resolve()); validate_config(result); return result
