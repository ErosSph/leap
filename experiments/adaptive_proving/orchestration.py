"""Freeze, validate, run, resume, and report the adaptive_proving protocol."""
from __future__ import annotations

import hashlib
import importlib.metadata
import json
import os
import platform
import re
import subprocess
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from . import EXPERIMENT_VERSION
from .config import canonical_json, digest, load_config, load_yaml, validate_config
from .corpus import load_frozen_tasks, verify_frozen_tasks
from .io import atomic_json, atomic_text, read_json, sha256_file, sha256_text
from .lean import check_source, lean_version, statement_source
from .lemma_diagnosis import taxonomy_manifest
from .prompts import prompt_policy_manifest
from .proof_model import HEALTH_SCHEMA, create_proof_model
from .report import build_report, evaluate_phase_b_trigger, load_results
from .strategies import run_trial


# Keep the public strategy spelling centralized without importing report internals.
ADAPTIVE = "diagnosis_guided_adaptive_lemma_first"


def project_root() -> Path:
    return Path(__file__).resolve().parents[2]


def _utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def _git_info(project: Path) -> dict[str, Any]:
    def command(*args: str) -> str:
        completed = subprocess.run(
            ["git", *args], cwd=project, capture_output=True, text=True, check=False,
        )
        return completed.stdout.strip() if completed.returncode == 0 else "UNAVAILABLE"
    status = command("status", "--porcelain")
    return {
        "commit": command("rev-parse", "HEAD"),
        "dirty": bool(status and status != "UNAVAILABLE"),
        "status_sha256": sha256_text(status),
    }


def _dependencies() -> dict[str, str]:
    names = ["rtl2lean-autonomous", "pyslang", "pytest"]
    result = {}
    for name in names:
        try:
            result[name] = importlib.metadata.version(name)
        except importlib.metadata.PackageNotFoundError:
            result[name] = "not-installed-as-distribution"
    return result


def _paired_seed(config: dict[str, Any], source_hash: str, task_id: str, trial_id: int) -> int:
    raw = f"{config['sampling']['base_seed']}:{source_hash}:{task_id}:{trial_id}"
    return int(hashlib.sha256(raw.encode()).hexdigest()[:8], 16) & 0x7FFFFFFF


def _seed_manifest(config: dict[str, Any], tasks: list[dict[str, Any]], source_hash: str) -> dict[str, Any]:
    trials = [*config["trials"]["phase_a"], *config["trials"]["phase_b"]]
    rows = []
    for task in tasks:
        for trial_id in trials:
            seed = _paired_seed(config, source_hash, task["task_id"], trial_id)
            rows.append({
                "challenge_id": task["challenge_id"], "task_id": task["task_id"],
                "trial_id": trial_id, "paired_seed": seed,
                "direct_seed": seed, "adaptive_seed": seed,
            })
    return {
        "schema": "rtl2lean-adaptive_proving-seeds-v1",
        "policy": config["sampling"],
        "paired_across_strategies": True,
        "only_trial_id_and_seed_change_between_independent_trials": True,
        "rows": rows,
    }


def _diagnosis_policy(config: dict[str, Any]) -> dict[str, Any]:
    path = Path(__file__).with_name("lemma_diagnosis.py")
    return {
        "schema": "rtl2lean-adaptive_proving-diagnosis-policy-v1",
        **config["diagnosis_policy"],
        "implementation": "experiments/adaptive_proving/lemma_diagnosis.py",
        "implementation_sha256": sha256_file(path),
        "inputs": [
            "target", "candidate lemma name/statement/proof", "all proof attempts",
            "Lean errors", "unsolved goals/proof states", "local hypotheses",
            "theorem base", "verified context", "previous diagnosis/repair history",
        ],
        "report_controls_proof_flow": True,
        "rediagnose_after_every_failed_repair": True,
        "challenge_id_is_not_an_input": True,
    }


def _strategies_manifest(config: dict[str, Any]) -> dict[str, Any]:
    return {
        "schema": "rtl2lean-adaptive_proving-strategies-v1",
        "strategies": config["strategies"],
        "same_max_total_calls": config["max_total_calls"],
        "same_checkpoints": config["checkpoints"],
        "direct_local_intermediate_reasoning_allowed": True,
        "adaptive": {
            "kernel_gate_before_verified_context": True,
            "diagnosis_before_repair_or_redesign": True,
            "max_lemma_redesign": config["max_lemma_redesign"],
            "repair_freezes_name_and_statement": True,
            "diagnosis_model_calls": 0,
        },
        "phase_b_trigger_frozen_before_phase_a": config["phase_b_trigger"],
        "no_result_shaping": True,
    }


def _secret_literal_present(value: Any) -> bool:
    return bool(re.search(r"sk-[A-Za-z0-9_.-]{12,}", canonical_json(value)))


def validate_environment(
    config_path: Path, *, check_api: bool = True, persist_validation: bool = True,
) -> tuple[dict[str, Any], list[dict[str, Any]], dict[str, Any], dict[str, Any]]:
    project = project_root()
    config = load_config(config_path)
    if _secret_literal_present(config):
        raise RuntimeError("API key literal detected in config; use the named environment variable")
    tasks, source = load_frozen_tasks(project, config)
    verify_frozen_tasks(project, tasks, source)
    statement_checks = []
    with tempfile.TemporaryDirectory(prefix="adaptive_proving-validate-") as raw:
        temporary = Path(raw)
        for task in tasks:
            check = check_source(
                statement_source(task), project / task["model_dir"],
                temporary / f"{task['challenge_id']}_statement.lean",
                int(config["lean_timeout_seconds"]),
            )
            statement_checks.append({
                "challenge_id": task["challenge_id"], "task_id": task["task_id"],
                "success": check["success"], "elapsed_s": check["elapsed_s"],
                "error": (check["stdout"] + check["stderr"])[-4000:] if not check["success"] else None,
            })
    if not all(row["success"] for row in statement_checks):
        raise RuntimeError("one or more frozen target statements failed Lean elaboration")

    api = {"checked": False, "success": None}
    if check_api:
        health_model_config = {
            **config["proof_model"],
            "timeout_seconds": min(90, int(config["proof_model"]["timeout_seconds"])),
        }
        model = create_proof_model(health_model_config)
        response = model.generate(
            "Return a JSON object whose status field is exactly ok. This is an API validation, not a proof trial.",
            HEALTH_SCHEMA,
            10,
        )
        api = {
            "checked": True,
            "success": response.status == "API_SUCCESS" and response.candidate == {"status": "ok"},
            "status": response.status,
            "metadata": response.metadata,
            "usage": response.usage,
            "error": response.error,
            "formal_result_consumed": False,
            "health_check_overrides": {
                "timeout_seconds": health_model_config["timeout_seconds"],
            },
            "client_token_caps_sent": False,
            "formal_model_config_sha256": digest(config["proof_model"]),
        }
        if not api["success"]:
            raise RuntimeError(f"proof-model API validation failed: {response.status}: {response.error}")

    result = {
        "schema": "rtl2lean-adaptive_proving-validation-v1",
        "timestamp": _utc_now(),
        "status": "PASS",
        "formal_result_consumed": False,
        "config_sha256": digest(config),
        "frozen_challenges": len(tasks),
        "challenge_manifest_sha256": source["challenge_manifest_sha256"],
        "lean_version": lean_version(),
        "statement_checks": statement_checks,
        "api": api,
        "credential_recorded": False,
    }
    if persist_validation:
        validation_root = project / config["output_root"] / "validation"
        validation_root.mkdir(parents=True, exist_ok=True)
        name = datetime.now(timezone.utc).strftime("validation_%Y%m%dT%H%M%S%fZ.json")
        atomic_json(validation_root / name, result, overwrite=False)
        atomic_json(validation_root / "latest.json", result)
    return config, tasks, source, result


def _create_run(config_path: Path, argv: list[str]) -> tuple[Path, dict[str, Any], list[dict[str, Any]], dict[str, Any], str]:
    project = project_root()
    config, tasks, source, validation = validate_environment(config_path, check_api=True)
    source_hash = source["challenge_manifest_sha256"]
    run_id = datetime.now(timezone.utc).strftime("r10c_%Y%m%dT%H%M%S%fZ_") + digest(config)[:10]
    run_dir = project / config["output_root"] / run_id
    run_dir.mkdir(parents=True, exist_ok=False)
    manifests = run_dir / "manifests"
    for directory in (
        manifests, run_dir / "phaseA" / "direct", run_dir / "phaseA" / "adaptive_lemma_first",
        run_dir / "phaseB" / "direct", run_dir / "phaseB" / "adaptive_lemma_first",
        run_dir / "diagnosis" / "reports", run_dir / "analysis", run_dir / "tables",
        run_dir / "case_studies",
    ):
        directory.mkdir(parents=True, exist_ok=True)

    atomic_text(manifests / "config.yaml", config_path.resolve().read_text(encoding="utf-8"), overwrite=False)
    atomic_json(manifests / "challenges.json", {
        "schema": "rtl2lean-adaptive_proving-frozen-challenges-v1",
        "frozen_before_phase_a": True,
        "challenge_count": len(tasks),
        "tasks": tasks,
        "source": source,
    }, overwrite=False)
    atomic_json(manifests / "strategies.json", _strategies_manifest(config), overwrite=False)
    atomic_json(manifests / "diagnosis_policy.json", _diagnosis_policy(config), overwrite=False)
    atomic_json(manifests / "diagnosis_taxonomy.json", taxonomy_manifest(), overwrite=False)
    seeds = _seed_manifest(config, tasks, source_hash)
    atomic_json(manifests / "seeds.json", seeds, overwrite=False)
    atomic_json(manifests / "prompts.json", prompt_policy_manifest(), overwrite=False)
    frozen_paths = [
        "config.yaml", "challenges.json", "strategies.json", "diagnosis_policy.json",
        "diagnosis_taxonomy.json", "seeds.json", "prompts.json",
    ]
    frozen_hashes = {name: sha256_file(manifests / name) for name in frozen_paths}
    manifest = {
        "schema": "rtl2lean-adaptive_proving-run-manifest-v1",
        "experiment_version": EXPERIMENT_VERSION,
        "run_id": run_id,
        "timestamp": _utc_now(),
        "git": _git_info(project),
        "challenge_manifest_hash": source_hash,
        "frozen_challenges_hash": frozen_hashes["challenges.json"],
        "prompt_template_hash": frozen_hashes["prompts.json"],
        "diagnosis_policy_hash": frozen_hashes["diagnosis_policy.json"],
        "config_hash": digest(config),
        "config_file_hash": frozen_hashes["config.yaml"],
        "proof_model_name": config["proof_model"]["model"],
        "proof_model_provider": config["proof_model"]["provider"],
        "sampling_parameters": {
            "temperature": config["proof_model"]["temperature"],
            "token_limit_policy": config["proof_model"]["token_limit_policy"],
            "client_token_caps_sent": False,
        },
        "trial_seeds": seeds["rows"],
        "lean_version": validation["lean_version"],
        "python_version": sys.version,
        "dependency_versions": _dependencies(),
        "os_environment": {
            "platform": platform.platform(), "system": platform.system(),
            "release": platform.release(), "machine": platform.machine(),
        },
        "actual_cli_command": argv,
        "credential_environment_variable": config["proof_model"]["api_key_env"],
        "credential_recorded": False,
        "validation": {
            "status": validation["status"], "api_status": validation["api"]["status"],
            "formal_result_consumed": False,
        },
        "frozen_manifest_hashes": frozen_hashes,
        "phase_b_trigger_frozen_before_phase_a": config["phase_b_trigger"],
        "no_result_shaping": True,
    }
    atomic_json(manifests / "run_manifest.json", manifest, overwrite=False)
    return run_dir, config, tasks, source, sha256_file(manifests / "run_manifest.json")


def _load_run(run_dir: Path) -> tuple[dict[str, Any], list[dict[str, Any]], dict[str, Any], str]:
    run_dir = run_dir.resolve()
    manifests = run_dir / "manifests"
    manifest = read_json(manifests / "run_manifest.json")
    if manifest.get("experiment_version") != EXPERIMENT_VERSION:
        raise RuntimeError("run uses another experiment version")
    for name, expected in manifest["frozen_manifest_hashes"].items():
        path = manifests / name
        if not path.is_file() or sha256_file(path) != expected:
            raise RuntimeError(f"frozen run artifact changed: {path}")
    config = load_yaml(manifests / "config.yaml")
    validate_config(config)
    frozen = read_json(manifests / "challenges.json")
    tasks, source = frozen["tasks"], frozen["source"]
    verify_frozen_tasks(project_root(), tasks, source)
    return config, tasks, source, sha256_file(manifests / "run_manifest.json")


def _seed_map(run_dir: Path) -> dict[tuple[str, int], int]:
    rows = read_json(run_dir / "manifests" / "seeds.json")["rows"]
    return {(row["challenge_id"], row["trial_id"]): row["paired_seed"] for row in rows}


def _progress(run_dir: Path, expected: int, phase: str) -> None:
    rows = load_results(run_dir)
    atomic_json(run_dir / "progress.json", {
        "schema": "rtl2lean-adaptive_proving-progress-v1",
        "phase": phase, "completed_trials": len(rows), "expected_trials": expected,
        "pass": sum(row["final_pass"] for row in rows),
        "fail": sum(not row["final_pass"] for row in rows),
        "last_update": _utc_now(),
    })


def _execute_phase(
    run_dir: Path, phase: str, trials: list[int], config: dict[str, Any],
    tasks: list[dict[str, Any]], source: dict[str, Any], run_manifest_hash: str,
    expected: int,
) -> list[dict[str, Any]]:
    model = create_proof_model(config["proof_model"])
    seeds = _seed_map(run_dir)
    results = []
    for trial_id in trials:
        for task in tasks:
            for strategy in config["strategies"]:
                result = run_trial(
                    project_root(), run_dir, phase, strategy, task, trial_id,
                    seeds[(task["challenge_id"], trial_id)], config, source,
                    run_manifest_hash, model,
                )
                results.append(result)
                _progress(run_dir, expected, phase)
    return results


def _freeze_trigger(run_dir: Path, result: dict[str, Any]) -> dict[str, Any]:
    path = run_dir / "analysis" / "phase_b_trigger.json"
    if path.is_file():
        existing = read_json(path)
        if existing != result:
            raise RuntimeError("stored Phase B trigger result disagrees with deterministic reevaluation")
        return existing
    atomic_json(path, result, overwrite=False)
    return result


def _security_scan(run_dir: Path, credential_env: str) -> dict[str, Any]:
    findings = []
    secret = os.environ.get(credential_env, "")
    generic = re.compile(rb"sk-[A-Za-z0-9_.-]{20,}")
    for path in sorted(candidate for candidate in run_dir.rglob("*") if candidate.is_file()):
        if path.name == "security_scan.json":
            continue
        data = path.read_bytes()
        if (secret and secret.encode() in data) or generic.search(data):
            findings.append(str(path.relative_to(run_dir)))
    result = {
        "schema": "rtl2lean-adaptive_proving-secret-scan-v1",
        "status": "PASS" if not findings else "FAIL",
        "scanned_files": sum(candidate.is_file() for candidate in run_dir.rglob("*")),
        "credential_literal_findings": findings,
        "credential_value_recorded": False,
    }
    atomic_json(run_dir / "security_scan.json", result)
    if findings:
        raise RuntimeError("credential-like literal found in run artifacts")
    return result


def run_new(config_path: Path, argv: list[str]) -> tuple[Path, dict[str, Any]]:
    run_dir, config, tasks, source, manifest_hash = _create_run(config_path, argv)
    _execute_phase(
        run_dir, "phaseA", config["trials"]["phase_a"], config, tasks, source,
        manifest_hash, 20,
    )
    phase_a = [row for row in load_results(run_dir) if row["phase"] == "phaseA"]
    if len(phase_a) != 20:
        raise RuntimeError(f"Phase A incomplete: expected 20 completed trials, got {len(phase_a)}")
    trigger = _freeze_trigger(run_dir, evaluate_phase_b_trigger(phase_a, config))
    if trigger["pilot_signal"]:
        _execute_phase(
            run_dir, "phaseB", config["trials"]["phase_b"], config, tasks, source,
            manifest_hash, 60,
        )
    build_report(run_dir, config, tasks)
    _security_scan(run_dir, config["proof_model"]["api_key_env"])
    return run_dir, build_report(run_dir, config, tasks)


def resume_run(run_dir: Path) -> dict[str, Any]:
    run_dir = run_dir.resolve()
    config, tasks, source, manifest_hash = _load_run(run_dir)
    if not os.environ.get(config["proof_model"]["api_key_env"]):
        raise RuntimeError(f"{config['proof_model']['api_key_env']} is required to resume")
    _execute_phase(
        run_dir, "phaseA", config["trials"]["phase_a"], config, tasks, source,
        manifest_hash, 20,
    )
    phase_a = [row for row in load_results(run_dir) if row["phase"] == "phaseA"]
    if len(phase_a) != 20:
        raise RuntimeError(f"Phase A incomplete after resume: {len(phase_a)}/20")
    trigger = _freeze_trigger(run_dir, evaluate_phase_b_trigger(phase_a, config))
    if trigger["pilot_signal"]:
        _execute_phase(
            run_dir, "phaseB", config["trials"]["phase_b"], config, tasks, source,
            manifest_hash, 60,
        )
    build_report(run_dir, config, tasks)
    _security_scan(run_dir, config["proof_model"]["api_key_env"])
    return build_report(run_dir, config, tasks)


def report_run(run_dir: Path) -> dict[str, Any]:
    run_dir = run_dir.resolve()
    config, tasks, _source, _manifest_hash = _load_run(run_dir)
    result = build_report(run_dir, config, tasks)
    _security_scan(run_dir, config["proof_model"]["api_key_env"])
    # Rebuild once more so integrity includes the freshly generated security scan.
    return build_report(run_dir, config, tasks)
