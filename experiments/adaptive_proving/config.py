"""Dependency-free loading and strict validation for adaptive_proving YAML."""
from __future__ import annotations

import ast
import hashlib
import json
from pathlib import Path
from typing import Any

from . import EXPERIMENT_VERSION


class ConfigError(ValueError):
    pass


def _scalar(raw: str) -> Any:
    value = raw.strip()
    if not value:
        return {}
    lowered = value.lower()
    if lowered in {"true", "false"}:
        return lowered == "true"
    if lowered in {"null", "none", "~"}:
        return None
    try:
        return ast.literal_eval(value)
    except (ValueError, SyntaxError):
        return value


def load_yaml(path: Path) -> dict[str, Any]:
    """Load the mapping-only YAML subset used by the frozen experiment config.

    Inline YAML sequences are parsed as Python literals. Keeping this tiny parser
    in-tree avoids making paper reproduction depend on an undeclared PyYAML install.
    """
    root: dict[str, Any] = {}
    stack: list[tuple[int, dict[str, Any]]] = [(-1, root)]
    for number, original in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if not original.strip() or original.lstrip().startswith("#"):
            continue
        indent = len(original) - len(original.lstrip(" "))
        if "\t" in original[:indent] or indent % 2:
            raise ConfigError(f"{path}:{number}: indentation must use pairs of spaces")
        content = original.strip()
        if ":" not in content:
            raise ConfigError(f"{path}:{number}: expected key: value")
        key, raw = content.split(":", 1)
        key = key.strip()
        if not key:
            raise ConfigError(f"{path}:{number}: empty key")
        while stack[-1][0] >= indent:
            stack.pop()
        parent = stack[-1][1]
        if key in parent:
            raise ConfigError(f"{path}:{number}: duplicate key {key!r}")
        value = _scalar(raw)
        parent[key] = value
        if value == {} and not raw.strip():
            stack.append((indent, value))
    return root


def canonical_json(value: Any) -> str:
    return json.dumps(value, sort_keys=True, ensure_ascii=False, separators=(",", ":"))


def digest(value: Any) -> str:
    return hashlib.sha256(canonical_json(value).encode()).hexdigest()


def _expect(condition: bool, message: str) -> None:
    if not condition:
        raise ConfigError(message)


def validate_config(config: dict[str, Any]) -> None:
    _expect(config.get("experiment_version") == EXPERIMENT_VERSION,
            f"experiment_version must be {EXPERIMENT_VERSION!r}")
    _expect(config.get("max_total_calls") == 10, "max_total_calls must be frozen at 10")
    _expect(config.get("max_lemma_redesign") == 1, "max_lemma_redesign must be frozen at 1")
    _expect(config.get("checkpoints") == [3, 5, 8, 10],
            "checkpoints must be frozen at [3, 5, 8, 10]")
    _expect(config.get("strategies") == [
        "direct", "diagnosis_guided_adaptive_lemma_first",
    ], "strategies do not match adaptive_proving")
    _expect(config.get("trials") == {"phase_a": [1], "phase_b": [2, 3]},
            "trials must be phase_a=[1], phase_b=[2,3]")
    trigger = config.get("phase_b_trigger") or {}
    _expect(trigger == {
        "checkpoint": 10,
        "direct_fail_adaptive_pass": 2,
        "adaptive_success_advantage": 2,
    }, "Phase B trigger differs from the pre-registered adaptive_proving trigger")
    model = config.get("proof_model") or {}
    for key in ("provider", "model", "api_key_env", "endpoint", "token_limit_policy"):
        _expect(bool(model.get(key)), f"proof_model.{key} is required")
    _expect(model["provider"] == "dashscope_openai_compatible",
            "formal provider must be DashScope's OpenAI-compatible API")
    _expect(model["model"] == "qwen3.8-flash", "formal proof model must be qwen3.8-flash")
    _expect(model["api_key_env"] == "DASHSCOPE_API_KEY",
            "formal API credential must come from DASHSCOPE_API_KEY")
    _expect(model["endpoint"] == "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions",
            "formal endpoint must be DashScope's official chat-completions endpoint")
    _expect(str(model["endpoint"]).startswith("https://"), "proof endpoint must use HTTPS")
    _expect(model["token_limit_policy"] == "provider_default_no_client_token_cap",
            "formal calls must use the provider default without a client token cap")
    forbidden_token_controls = {
        "max_completion_tokens", "max_tokens", "thinking_budget", "reasoning_effort",
    }
    present = sorted(forbidden_token_controls & model.keys())
    _expect(not present,
            "proof_model must omit client-side token/reasoning controls: " + ", ".join(present))
    diagnosis = config.get("diagnosis_policy") or {}
    _expect(diagnosis.get("model_calls") is False, "diagnosis must not call the proof model")
    _expect(diagnosis.get("challenge_specific_rules") is False,
            "challenge-specific diagnosis rules are forbidden")
    prompts = config.get("prompt_policy") or {}
    _expect(prompts.get("reference_proofs_hidden") is True,
            "reference proofs must be hidden from the proof model")
    _expect(prompts.get("candidate_lemmas_human_supplied") is False,
            "human-supplied intermediate lemmas are forbidden")


def resolve_path(project: Path, raw: str) -> Path:
    path = Path(raw)
    return path.resolve() if path.is_absolute() else (project / path).resolve()


def load_config(path: Path) -> dict[str, Any]:
    config = load_yaml(path.resolve())
    validate_config(config)
    return config
