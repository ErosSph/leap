"""Strict configuration for the isolated foundation_first experiment."""
from __future__ import annotations

from pathlib import Path
from typing import Any

from experiments.adaptive_proving.config import ConfigError, load_yaml

from . import EXPERIMENT_VERSION


def _expect(value: bool, message: str) -> None:
    if not value:
        raise ConfigError(message)


def validate_config(config: dict[str, Any]) -> None:
    _expect(config.get("experiment_version") == EXPERIMENT_VERSION,
            f"experiment_version must be {EXPERIMENT_VERSION}")
    _expect(config.get("max_candidate_calls", 0) > 0, "max_candidate_calls must be positive")
    _expect(config.get("max_lemma_redesign", -1) >= 0, "max_lemma_redesign must be nonnegative")
    _expect(config.get("trial_ids") == [1], "foundation_first v1 freezes one trial per property")
    model = config.get("proof_model") or {}
    _expect(model.get("provider") == "dashscope_openai_compatible", "DashScope provider required")
    _expect(model.get("model") == "qwen3.8-flash", "Note requires qwen3.8-flash")
    _expect(model.get("api_key_env") == "DASHSCOPE_API_KEY", "credential must use DASHSCOPE_API_KEY")
    _expect(model.get("endpoint") == "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions",
            "endpoint differs from foundation_first Note")
    _expect(str(model.get("endpoint", "")).startswith("https://"), "HTTPS endpoint required")
    _expect(config.get("prompt_policy", {}).get("direct_target_generation") is False,
            "Direct target generation is forbidden")
    _expect(config.get("proof_gap_policy", {}).get("challenge_specific_rules") is False,
            "challenge-specific proof-gap rules are forbidden")
    _expect(config.get("proof_gap_policy", {}).get("reads_reference_proof") is False,
            "ProofGapExtractor may not read reference proofs")
    _expect(config.get("proof_gap_policy", {}).get("reads_gap_spec") is False,
            "ProofGapExtractor may not read human-authored gap_spec")
    diagnosis = config.get("diagnosis_policy") or {}
    _expect(diagnosis.get("model_calls") is False, "diagnosis must be deterministic and local")
    _expect(diagnosis.get("challenge_specific_rules") is False,
            "challenge-specific diagnosis rules are forbidden")


def load_config(path: Path) -> dict[str, Any]:
    result = load_yaml(path.resolve())
    validate_config(result)
    return result
