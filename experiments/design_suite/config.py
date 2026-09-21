from pathlib import Path
from typing import Any

from experiments.adaptive_proving.config import ConfigError, load_yaml
from . import EXPERIMENT_VERSION


CATEGORIES = [
    "REACHABILITY_INVARIANT", "TEMPORAL_TRACE", "STATE_TRANSITION",
    "WITNESS_CONSTRUCTION", "DATAPATH_PROPERTY",
]
TEMPORAL_KINDS = ["ALWAYS", "EVENTUALLY", "UNTIL", "NEXT", "BOUNDED_UNTIL"]
DUTS = ["aes", "picorv32", "modexp", "serv", "ethmac", "zipcpu", "dma_axi"]


def validate_config(config: dict[str, Any]) -> None:
    if config.get("experiment_version") != EXPERIMENT_VERSION:
        raise ConfigError("wrong design_suite version")
    if config.get("duts") != DUTS:
        raise ConfigError("design_suite requires the fixed seven-DUT order")
    counts = config.get("properties_per_dut", {})
    if set(counts) != set(DUTS) or any(counts[dut] not in range(20, 31) for dut in DUTS):
        raise ConfigError("each DUT needs an explicit 20-30 Property count")
    if len(set(counts.values())) != len(DUTS):
        raise ConfigError("design_suite uses distinct per-DUT Property counts")
    if config.get("max_iterations") != 5:
        raise ConfigError("the proof budget must be exactly five iterations")
    model = config.get("proof_model", {})
    if (model.get("model"), model.get("api_key_env")) != ("qwen3.8-flash", "DASHSCOPE_API_KEY"):
        raise ConfigError("design_suite requires qwen3.8-flash and an environment credential")
    if model.get("endpoint") != "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions":
        raise ConfigError("wrong DashScope endpoint")


def load_config(path: Path) -> dict[str, Any]:
    config = load_yaml(path.resolve())
    validate_config(config)
    return config
