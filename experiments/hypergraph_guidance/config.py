from __future__ import annotations

from pathlib import Path
from typing import Any

from experiments.adaptive_proving.config import ConfigError, load_yaml
from . import EXPERIMENT_VERSION


def _expect(value: bool, message: str) -> None:
    if not value: raise ConfigError(message)


def validate_config(config: dict[str, Any]) -> None:
    _expect(config.get("experiment_version") == EXPERIMENT_VERSION, "wrong experiment version")
    _expect(config.get("max_total_calls") == 6, "freeze max_total_calls=6")
    _expect(config.get("candidate_edges_per_call") == 3, "freeze three candidate edges")
    _expect(config.get("trial_ids") == [1], "one frozen trial required")
    model = config.get("proof_model") or {}
    _expect(model.get("model") == "qwen3.8-flash", "Note requires qwen3.8-flash")
    _expect(model.get("api_key_env") == "DASHSCOPE_API_KEY", "credential must use environment")
    _expect(model.get("endpoint") == "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions",
            "endpoint differs from Note")
    _expect(config.get("evaluation", {}).get("paired_bridge_only_control") is True,
            "paired bridge-only control required to measure effect")
    _expect(config.get("evaluation", {}).get("direct_arm_present") is False, "Direct is forbidden")
    policy = config.get("hypergraph_policy") or {}
    _expect(policy.get("challenge_specific_rules") is False and policy.get("dut_specific_rules") is False,
            "special graph rules forbidden")


def load_config(path: Path) -> dict[str, Any]:
    result = load_yaml(path.resolve()); validate_config(result); return result
