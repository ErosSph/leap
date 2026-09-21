"""Lean source construction, kernel checking, and feedback extraction."""
from __future__ import annotations

import os
import re
import shutil
import subprocess
import time
from pathlib import Path
from typing import Any

from .io import atomic_text, sha256_file


FORBIDDEN_RE = re.compile(r"(?i)(?<![A-Za-z0-9_])(sorry|admit|native_decide|unsafe|axiom)(?![A-Za-z0-9_])")


def find_lean() -> str:
    candidates = [
        os.environ.get("RTL2LEAN_LEAN"),
        shutil.which("lean"),
    ]
    for candidate in candidates:
        if candidate and Path(candidate).is_file():
            # Preserve argv[0] dispatch when lean is an elan symlink.
            return str(Path(candidate).absolute())
    raise FileNotFoundError("Lean 4 executable not found; set RTL2LEAN_LEAN")


def statement_source(task: dict[str, Any]) -> str:
    return "\n".join([
        f"import {task['context_import']}", "", "set_option maxRecDepth 100000",
        "set_option maxHeartbeats 8000000", "", f"namespace {task['module']}Verification",
        f"open {task['module']}", "",
        f"def {task['task_id']}__r10c_statement : Prop := {task['statement']}", "",
        f"end {task['module']}Verification", "",
    ])


def theorem_source(task: dict[str, Any], name: str, statement: str, proof: str) -> str:
    return "\n".join([
        f"import {task['context_import']}", "", "set_option maxRecDepth 100000",
        "set_option maxHeartbeats 8000000", "", f"namespace {task['module']}Verification",
        f"open {task['module']}", "", f"theorem {name} : {statement} := {proof}", "",
        f"end {task['module']}Verification", "",
    ])


def target_with_lemma_source(task: dict[str, Any], lemma: dict[str, str], proof: str) -> str:
    return "\n".join([
        f"import {task['context_import']}", "", "set_option maxRecDepth 100000",
        "set_option maxHeartbeats 8000000", "", f"namespace {task['module']}Verification",
        f"open {task['module']}", "",
        f"theorem {lemma['lemma_name']} : {lemma['lemma_statement']} := {lemma['proof_body']}", "",
        f"theorem {task['task_id']} : {task['statement']} := {proof}", "",
        f"end {task['module']}Verification", "",
    ])


def synthetic_failure(message: str) -> dict[str, Any]:
    return {
        "success": False, "returncode": None, "stdout": "", "stderr": message,
        "elapsed_s": 0.0, "source": None, "source_sha256": None,
        "unsolved_goals": [message], "proof_state": message, "local_hypotheses": [],
    }


def extract_feedback(stdout: str, stderr: str) -> dict[str, Any]:
    text = (stdout + "\n" + stderr)[-32000:]
    goals: list[str] = []
    hypotheses: list[str] = []
    lines = text.splitlines()
    for index, line in enumerate(lines):
        if "⊢" not in line:
            continue
        block = [line.strip()]
        for following in lines[index + 1:index + 16]:
            if re.search(r":\d+:\d+: (?:error|warning):", following):
                break
            if following.strip():
                block.append(following.strip())
        goals.append("\n".join(block))
        prior = []
        for previous in reversed(lines[max(0, index - 12):index]):
            stripped = previous.strip()
            if not stripped or "error:" in stripped:
                break
            if ":" in stripped and "⊢" not in stripped:
                prior.append(stripped)
        hypotheses.extend(reversed(prior))
    return {
        "unsolved_goals": list(dict.fromkeys(goals)),
        "proof_state": "\n\n".join(dict.fromkeys(goals)),
        "local_hypotheses": list(dict.fromkeys(hypotheses)),
    }


def check_source(source: str, model_dir: Path, path: Path, timeout_s: int) -> dict[str, Any]:
    atomic_text(path, source)
    env = os.environ.copy()
    env["LEAN_PATH"] = str(model_dir) + (":" + env["LEAN_PATH"] if env.get("LEAN_PATH") else "")
    started = time.perf_counter()
    try:
        completed = subprocess.run(
            [find_lean(), "-s", "65536", str(path)], cwd=path.parent, env=env,
            capture_output=True, text=True, check=False, timeout=timeout_s,
        )
        stdout, stderr = completed.stdout[-16000:], completed.stderr[-16000:]
        return {
            "success": completed.returncode == 0,
            "returncode": completed.returncode,
            "stdout": stdout,
            "stderr": stderr,
            "elapsed_s": time.perf_counter() - started,
            "source": str(path),
            "source_sha256": sha256_file(path),
            **extract_feedback(stdout, stderr),
        }
    except subprocess.TimeoutExpired as error:
        stdout = error.stdout.decode() if isinstance(error.stdout, bytes) else (error.stdout or "")
        stderr = error.stderr.decode() if isinstance(error.stderr, bytes) else (error.stderr or "")
        stderr += f"\nLean kernel check timed out after {timeout_s}s"
        return {
            "success": False, "returncode": 124, "stdout": stdout[-16000:],
            "stderr": stderr[-16000:], "elapsed_s": time.perf_counter() - started,
            "source": str(path), "source_sha256": sha256_file(path),
            **extract_feedback(stdout, stderr),
        }


def lean_version() -> str:
    completed = subprocess.run([find_lean(), "--version"], capture_output=True, text=True, check=False)
    return (completed.stdout or completed.stderr).strip()
