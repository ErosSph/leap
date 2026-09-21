from pathlib import Path
from typing import Any

from experiments.adaptive_proving.config import ConfigError, load_yaml
from . import EXPERIMENT_VERSION


DUTS = ["aes", "picorv32", "modexp", "serv", "ethmac", "zipcpu", "dma_axi"]


def validate_config(config: dict[str, Any]) -> None:
    if config.get("experiment_version") != EXPERIMENT_VERSION:
        raise ConfigError("wrong challenge_suite version")
    if config.get("duts") != DUTS:
        raise ConfigError("challenge_suite requires the frozen seven-DUT order")
    if config.get("max_iterations") != 5:
        raise ConfigError("Direct is capped at exactly five LLM attempts")
    if config.get("direct_workers") not in range(1, 9):
        raise ConfigError("direct_workers must be between one and eight")
    counts = config.get("properties_per_dut", {})
    if set(counts) != set(DUTS) or sum(counts.values()) != 177:
        raise ConfigError("challenge_suite must use the frozen 177-task corpus")
    model = config.get("proof_model", {})
    if (model.get("model"), model.get("api_key_env")) != ("qwen3.8-flash", "DASHSCOPE_API_KEY"):
        raise ConfigError("challenge_suite requires qwen3.8-flash via an environment credential")
    if model.get("endpoint") != "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions":
        raise ConfigError("wrong DashScope endpoint")
    for name in ("context_char_limit", "feedback_char_limit", "previous_proof_char_limit"):
        if not isinstance(config.get(name), int) or config[name] <= 0:
            raise ConfigError(f"{name} must be a positive integer")


def load_config(path: Path) -> dict[str, Any]:
    config = load_yaml(path.resolve())
    validate_config(config)
    return config
