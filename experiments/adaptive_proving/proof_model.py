"""Model-agnostic proof generation over OpenAI-compatible chat APIs."""
from __future__ import annotations

import json
import os
import re
import socket
import time
import urllib.error
import urllib.request
from dataclasses import asdict, dataclass
from typing import Any, Protocol


SYSTEM_MESSAGE = (
    "You are the proof-generation component of a controlled Lean 4 experiment. "
    "You have no tools and no access to files. Follow the user's exact JSON schema and "
    "never use sorry, admit, native_decide, unsafe, axioms, or unchecked code."
)


@dataclass(frozen=True)
class ModelResponse:
    status: str
    candidate: dict[str, Any] | None
    raw_text: str
    usage: dict[str, int]
    elapsed_s: float
    metadata: dict[str, Any]
    error: str | None = None

    def serializable(self) -> dict[str, Any]:
        return asdict(self)


class ProofModel(Protocol):
    def generate(self, prompt: str, response_schema: dict[str, Any], seed: int) -> ModelResponse:
        """Make exactly one proof-model API request."""


def _safe(value: str, secret: str) -> str:
    if secret:
        value = value.replace(secret, "[REDACTED]")
    value = re.sub(r"sk-[A-Za-z0-9_.-]+", "[REDACTED_API_KEY_HINT]", value)
    return value[-16000:]


class OpenAICompatibleChatProofModel:
    """Provider-adapted transport; proof strategies depend only on ProofModel."""

    def __init__(self, model_config: dict[str, Any]):
        self.config = dict(model_config)

    def generate(self, prompt: str, response_schema: dict[str, Any], seed: int) -> ModelResponse:
        started = time.perf_counter()
        env_name = self.config["api_key_env"]
        secret = os.environ.get(env_name, "")
        base_metadata = {
            "provider": self.config["provider"],
            "requested_model": self.config["model"],
            "transport": "openai_compatible_chat_completions",
            "endpoint": self.config["endpoint"],
            "seed": seed,
            "credential_source": env_name,
            "credential_recorded": False,
        }
        if not secret:
            return ModelResponse(
                "MISSING_API_KEY", None, "", {}, 0.0, base_metadata,
                f"environment variable {env_name} is not set",
            )
        provider = self.config["provider"]
        system_message = SYSTEM_MESSAGE
        if provider == "deepseek_openai_compatible":
            # DeepSeek supports JSON Object mode rather than OpenAI JSON Schema mode.
            # Preserve the exact logical schema by including it in the system message.
            system_message += (
                " Return JSON conforming exactly to this schema: "
                + json.dumps(response_schema, ensure_ascii=False, sort_keys=True)
            )
            response_format: dict[str, Any] = {"type": "json_object"}
            seed_transport = "prompt_nonce_only_provider_has_no_seed_parameter"
        elif provider == "dashscope_openai_compatible":
            response_format = {
                "type": "json_schema",
                "json_schema": {
                    "name": "lean_proof_candidate",
                    "strict": True,
                    "schema": response_schema,
                },
            }
            seed_transport = "api_parameter_and_prompt_nonce"
        else:
            raise ValueError(f"unsupported proof-model provider: {provider!r}")

        base_metadata["seed_transport"] = seed_transport
        payload: dict[str, Any] = {
            "model": self.config["model"],
            "messages": [
                {"role": "system", "content": system_message},
                {"role": "user", "content": prompt},
            ],
            "response_format": response_format,
            "temperature": float(self.config["temperature"]),
            "stream": False,
        }
        # Optional, provider-supported controls are deliberately configuration
        # driven.  adaptive_proving omits them; later isolated experiments may
        # freeze them explicitly without changing the transport abstraction.
        if "max_completion_tokens" in self.config:
            payload["max_completion_tokens"] = int(self.config["max_completion_tokens"])
        if "enable_thinking" in self.config:
            payload["enable_thinking"] = bool(self.config["enable_thinking"])
        if provider == "dashscope_openai_compatible":
            payload["seed"] = int(seed) & 0x7FFFFFFF
        request = urllib.request.Request(
            self.config["endpoint"],
            data=json.dumps(payload, ensure_ascii=False).encode("utf-8"),
            headers={
                "Authorization": f"Bearer {secret}",
                "Content-Type": "application/json",
                "User-Agent": "rtl2lean-adaptive_proving/1",
            },
            method="POST",
        )
        raw = ""
        try:
            with urllib.request.urlopen(
                request, timeout=int(self.config["timeout_seconds"])
            ) as response:
                raw = response.read().decode("utf-8", errors="replace")
                http_status = response.status
            body = json.loads(raw)
            choices = body.get("choices") or []
            if not choices:
                raise ValueError("response has no choices")
            choice = choices[0]
            message = choice.get("message") or {}
            text = message.get("content")
            if isinstance(text, list):
                text = "".join(
                    item.get("text", "") for item in text if isinstance(item, dict)
                )
            if not isinstance(text, str):
                raise ValueError("assistant content is not text")
            usage_raw = body.get("usage") or {}
            details = usage_raw.get("completion_tokens_details") or {}
            usage = {
                "input_tokens": int(usage_raw.get("prompt_tokens") or usage_raw.get("input_tokens") or 0),
                "output_tokens": int(usage_raw.get("completion_tokens") or usage_raw.get("output_tokens") or 0),
                "total_tokens": int(usage_raw.get("total_tokens") or 0),
                "reasoning_tokens": int(details.get("reasoning_tokens") or 0),
                "cached_tokens": int((usage_raw.get("prompt_tokens_details") or {}).get("cached_tokens") or 0),
            }
            metadata = {
                **base_metadata,
                "http_status": http_status,
                "response_id": body.get("id"),
                "returned_model": body.get("model"),
                "finish_reason": choice.get("finish_reason"),
                "system_fingerprint": body.get("system_fingerprint"),
            }
            if choice.get("finish_reason") == "length":
                return ModelResponse(
                    "OUTPUT_TRUNCATED", None, text, usage, time.perf_counter() - started,
                    metadata, "completion stopped at length limit before a usable JSON answer",
                )
            try:
                candidate = json.loads(text)
                if not isinstance(candidate, dict):
                    raise ValueError("structured response is not a JSON object")
            except (json.JSONDecodeError, ValueError, TypeError) as error:
                return ModelResponse(
                    "INVALID_RESPONSE", None, text, usage, time.perf_counter() - started,
                    metadata, _safe(repr(error), secret),
                )
            return ModelResponse(
                "API_SUCCESS", candidate, text, usage, time.perf_counter() - started, metadata,
            )
        except urllib.error.HTTPError as error:
            response_text = error.read().decode("utf-8", errors="replace")
            status = "RATE_LIMIT" if error.code == 429 else "API_FAILURE"
            return ModelResponse(
                status, None, "", {}, time.perf_counter() - started,
                {**base_metadata, "http_status": error.code},
                _safe(response_text or repr(error), secret),
            )
        except (urllib.error.URLError, socket.timeout, TimeoutError, OSError) as error:
            return ModelResponse(
                "API_FAILURE", None, "", {}, time.perf_counter() - started,
                base_metadata, _safe(repr(error), secret),
            )
        except (json.JSONDecodeError, ValueError, TypeError, KeyError) as error:
            return ModelResponse(
                "INVALID_RESPONSE", None, raw[-16000:], {}, time.perf_counter() - started,
                base_metadata, _safe(repr(error), secret),
            )


def create_proof_model(model_config: dict[str, Any]) -> ProofModel:
    provider = model_config.get("provider")
    if provider in {"dashscope_openai_compatible", "deepseek_openai_compatible"}:
        return OpenAICompatibleChatProofModel(model_config)
    raise ValueError(f"unsupported proof-model provider: {provider!r}")


# Kept as a source-compatible alias for older local callers; new code should use
# OpenAICompatibleChatProofModel or the model-agnostic create_proof_model factory.
DashScopeChatProofModel = OpenAICompatibleChatProofModel


HEALTH_SCHEMA = {
    "type": "object",
    "properties": {"status": {"type": "string", "enum": ["ok"]}},
    "required": ["status"],
    "additionalProperties": False,
}
