from pathlib import Path

from experiments.adaptive_proving.config import ConfigError, load_yaml
from . import EXPERIMENT_VERSION

EXPECTED_VARIANTS = ["legacy_untyped_control", "full_req15"]
EXPECTED_PATTERNS = ["STATE_TRANSITION", "WITNESS_CONSTRUCTION"]


def validate_config(config: dict) -> None:
    if config.get("experiment_version") != EXPERIMENT_VERSION:
        raise ConfigError("wrong scale_evaluation experiment version")
    if config.get("variants") != EXPECTED_VARIANTS:
        raise ConfigError("Req15 requires the frozen paired control/full variants")
    if config.get("patterns") != EXPECTED_PATTERNS or config.get("tasks_per_pattern") != 5:
        raise ConfigError("Req15 requires five State and five Witness unseen tasks")
    if config.get("candidate_count") != 3 or config.get("candidate_calls") != 2:
        raise ConfigError("candidate budget must be 3 candidates and at most 2 calls")
    if config.get("proof_calls") != 2 or config.get("trial_ids") != [1]:
        raise ConfigError("proof/seed policy changed")
    if config.get("sampling", {}).get("base_seed") != 271828:
        raise ConfigError("base seed changed")
    model = config.get("proof_model", {})
    if model.get("model") != "qwen3.8-flash" or model.get("api_key_env") != "DASHSCOPE_API_KEY":
        raise ConfigError("wrong model or credential source")
    if model.get("endpoint") != "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions":
        raise ConfigError("wrong DashScope endpoint")
    if model.get("temperature") != 0.2 or model.get("enable_thinking") is not False:
        raise ConfigError("frozen sampling policy changed")


def load_config(path: Path) -> dict:
    config = load_yaml(path.resolve())
    validate_config(config)
    return config
