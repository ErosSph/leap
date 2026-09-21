"""Small provider-neutral client for the OpenAI-compatible Responses API."""
from __future__ import annotations

import json
import os
import re
import shutil
import socket
import subprocess
import tempfile
import time
import urllib.error
import urllib.request
from dataclasses import dataclass
from pathlib import Path
from typing import Any


PROOF_SCHEMA = {
    "type": "object",
    "properties": {
        "proof_body": {"type": "string"},
        "rationale": {"type": "string"},
    },
    "required": ["proof_body", "rationale"],
    "additionalProperties": False,
}


@dataclass(frozen=True)
class GenerationResult:
    status: str
    proof_body: str | None
    rationale: str | None
    usage: dict[str, int]
    elapsed_s: float
    response_metadata: dict[str, Any]
    error: str | None = None
    candidate: dict[str, Any] | None = None


def _output_text(payload: dict[str, Any]) -> str:
    pieces: list[str] = []
    for item in payload.get("output", []):
        if item.get("type") != "message":
            continue
        for content in item.get("content", []):
            if content.get("type") == "output_text" and isinstance(content.get("text"), str):
                pieces.append(content["text"])
    return "\n".join(pieces)


def _safe_error(value: str, secret: str) -> str:
    redacted = value.replace(secret, "[REDACTED]") if secret else value
    # Providers may echo a masked key prefix/suffix in authentication errors.
    redacted = re.sub(r"sk-[A-Za-z0-9_*.-]+", "[REDACTED_API_KEY_HINT]", redacted)
    return redacted[:12000]


class LLMBackend:
    """Generate one structured Lean proof without persisting credentials."""

    def generate(
        self, prompt: str, model_config: dict[str, Any], proof_budget: dict[str, Any],
        response_schema: dict[str, Any] | None = None,
    ) -> GenerationResult:
        started = time.perf_counter()
        env_name = model_config["api_key_env"]
        secret = os.environ.get(env_name, "")
        if not secret:
            return GenerationResult(
                "MISSING_API_KEY", None, None, {}, 0.0,
                {"provider": model_config["provider"], "model": model_config["model_id"]},
                f"{env_name} missing",
            )
        response_schema = response_schema or PROOF_SCHEMA
        payload = {
            "model": model_config["model_id"],
            "input": prompt,
            "reasoning": {"effort": model_config["reasoning_profile"]},
            "max_output_tokens": proof_budget["max_output_tokens"],
            "text": {"format": {
                "type": "json_schema", "name": "lean_proof_candidate",
                "strict": True, "schema": response_schema,
            }},
            "store": False,
        }
        request = urllib.request.Request(
            model_config["endpoint"],
            data=json.dumps(payload, ensure_ascii=False).encode("utf-8"),
            headers={
                "Authorization": f"Bearer {secret}",
                "Content-Type": "application/json",
                "User-Agent": "rtl2lean-model_calibration/1",
            },
            method="POST",
        )
        try:
            with urllib.request.urlopen(request, timeout=proof_budget["provider_timeout_s"]) as response:
                raw = response.read().decode("utf-8", errors="replace")
                status_code = response.status
            body = json.loads(raw)
            text = _output_text(body)
            usage_raw = body.get("usage") or {}
            usage = {
                "input_tokens": int(usage_raw.get("input_tokens") or 0),
                "output_tokens": int(usage_raw.get("output_tokens") or 0),
                "total_tokens": int(usage_raw.get("total_tokens") or 0),
                "reasoning_tokens": int(
                    (usage_raw.get("output_tokens_details") or {}).get("reasoning_tokens") or 0
                ),
            }
            metadata = {
                "provider": model_config["provider"], "requested_model": model_config["model_id"],
                "returned_model": body.get("model"), "response_id": body.get("id"),
                "response_status": body.get("status"), "http_status": status_code,
                "incomplete_details": body.get("incomplete_details"), "usage": usage,
            }
            try:
                candidate = json.loads(text)
                proof = candidate["proof_body"]
                rationale = candidate.get("rationale", "")
                if not isinstance(proof, str) or not proof.lstrip().startswith("by"):
                    raise ValueError("proof_body must be a Lean proof beginning with `by`")
            except (json.JSONDecodeError, KeyError, TypeError, ValueError) as error:
                return GenerationResult(
                    "INVALID_RESPONSE", None, None, usage, time.perf_counter() - started,
                    metadata, _safe_error(f"{error}; output={text}", secret),
                )
            return GenerationResult(
                "API_SUCCESS", proof, rationale, usage, time.perf_counter() - started, metadata,
                candidate=candidate,
            )
        except urllib.error.HTTPError as error:
            raw = error.read().decode("utf-8", errors="replace")
            status = "RATE_LIMIT" if error.code == 429 else "API_FAILURE"
            return GenerationResult(
                status, None, None, {}, time.perf_counter() - started,
                {"provider": model_config["provider"], "model": model_config["model_id"],
                 "http_status": error.code},
                _safe_error(raw or str(error), secret),
            )
        except (urllib.error.URLError, socket.timeout, TimeoutError, OSError, json.JSONDecodeError) as error:
            return GenerationResult(
                "API_FAILURE", None, None, {}, time.perf_counter() - started,
                {"provider": model_config["provider"], "model": model_config["model_id"]},
                _safe_error(repr(error), secret),
            )


class CodexCLIBackend:
    """Use the Codex login session as an audited transport for the same GPT model."""

    def generate(
        self, prompt: str, model_config: dict[str, Any], proof_budget: dict[str, Any],
        response_schema: dict[str, Any] | None = None,
    ) -> GenerationResult:
        started = time.perf_counter()
        executable = shutil.which("codex")
        if not executable:
            return GenerationResult(
                "API_FAILURE", None, None, {}, 0.0,
                {"provider": "openai", "transport": "codex_cli"}, "codex executable missing",
            )
        response_schema = response_schema or PROOF_SCHEMA
        with tempfile.TemporaryDirectory(prefix="r10a-codex-") as raw_dir:
            temporary_root = Path(raw_dir)
            response_path = temporary_root / "response.json"
            schema = temporary_root / "response.schema.json"
            schema.write_text(json.dumps(response_schema), encoding="utf-8")
            codex_home = temporary_root / "codex-home"
            codex_home.mkdir(mode=0o700)
            source_codex_home = Path(os.environ.get("CODEX_HOME", Path.home() / ".codex"))
            auth_source = source_codex_home / "auth.json"
            if not auth_source.is_file():
                return GenerationResult(
                    "API_FAILURE", None, None, {}, time.perf_counter() - started,
                    {"provider": "openai", "transport": "codex_cli"},
                    "Codex account auth.json missing",
                )
            shutil.copy2(auth_source, codex_home / "auth.json")
            command = [
                executable, "exec", "--skip-git-repo-check", "--ephemeral",
                "--ignore-user-config", "--sandbox", "read-only",
                "-m", model_config["model_id"],
                "-c", f'model_reasoning_effort="{model_config["reasoning_profile"]}"',
                "--output-schema", str(schema), "--output-last-message", str(response_path), "-",
            ]
            child_env = os.environ.copy()
            child_env["CODEX_HOME"] = str(codex_home)
            # Force Codex account authentication; the rejected API key must not
            # influence this explicitly authorized fallback transport.
            for key in (
                "OPENAI_API_KEY", "OPENAI_BASE_URL", "CODEX_SESSION_ID", "CODEX_THREAD_ID",
                "CODEX_PERMISSION_PROFILE", "CODEX_CI", "CODEX_SANDBOX_NETWORK_DISABLED",
                "CODEX_MANAGED_BY_NPM", "CODEX_MANAGED_PACKAGE_ROOT",
            ):
                child_env.pop(key, None)
            try:
                completed = subprocess.run(
                    command, input=prompt, text=True, capture_output=True, check=False,
                    timeout=proof_budget["provider_timeout_s"], env=child_env,
                )
                combined = completed.stdout + completed.stderr
                token_match = re.search(r"tokens used\s*\n\s*([0-9,]+)", combined, re.I)
                total_tokens = int(token_match.group(1).replace(",", "")) if token_match else 0
                usage = {
                    "input_tokens": 0, "output_tokens": 0,
                    "total_tokens": total_tokens, "reasoning_tokens": 0,
                }
                metadata = {
                    "provider": "openai", "transport": "codex_cli",
                    "requested_model": model_config["model_id"],
                    "returncode": completed.returncode,
                    "usage_granularity": "total_only" if token_match else "unavailable",
                    "codex_cli_version": _codex_version(executable),
                    "account_auth_used": True, "api_key_used": False,
                }
                if completed.returncode != 0 or not response_path.is_file():
                    return GenerationResult(
                        "API_FAILURE", None, None, usage, time.perf_counter() - started,
                        metadata, _safe_error(combined[-12000:], ""),
                    )
                try:
                    candidate = json.loads(response_path.read_text(encoding="utf-8"))
                    proof = candidate["proof_body"]
                    rationale = candidate.get("rationale", "")
                    if not isinstance(proof, str) or not proof.lstrip().startswith("by"):
                        raise ValueError("proof_body must begin with `by`")
                except (json.JSONDecodeError, KeyError, TypeError, ValueError) as error:
                    return GenerationResult(
                        "INVALID_RESPONSE", None, None, usage, time.perf_counter() - started,
                        metadata, str(error),
                    )
                return GenerationResult(
                    "API_SUCCESS", proof, rationale, usage,
                    time.perf_counter() - started, metadata, candidate=candidate,
                )
            except (subprocess.TimeoutExpired, OSError) as error:
                return GenerationResult(
                    "API_FAILURE", None, None, {}, time.perf_counter() - started,
                    {"provider": "openai", "transport": "codex_cli"}, repr(error),
                )


def _codex_version(executable: str) -> str | None:
    try:
        completed = subprocess.run(
            [executable, "--version"], capture_output=True, text=True,
            check=False, timeout=10,
        )
        return (completed.stdout or completed.stderr).strip().splitlines()[-1]
    except (OSError, subprocess.TimeoutExpired, IndexError):
        return None
