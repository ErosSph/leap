"""Validation, freezing, execution, resume, and reporting for foundation_first."""
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

from experiments.adaptive_proving.config import canonical_json, digest, load_yaml
from experiments.adaptive_proving.io import atomic_json, atomic_text, read_json, sha256_file, sha256_text
from experiments.adaptive_proving.lean import check_source, lean_version, statement_source
from experiments.adaptive_proving.lemma_diagnosis import taxonomy_manifest
from experiments.adaptive_proving.proof_model import HEALTH_SCHEMA, create_proof_model

from . import EXPERIMENT_VERSION
from .config import load_config, validate_config
from .corpus import load_frozen_tasks, verify_frozen_tasks
from .proof_gap import policy_manifest as gap_policy_manifest
from .prompts import policy_manifest as prompt_policy_manifest
from .prover import prover_policy_manifest
from .report import build_report, load_results
from .trial import run_trial


def project_root() -> Path:
    return Path(__file__).resolve().parents[2]


def _now() -> str:
    return datetime.now(timezone.utc).isoformat()


def _git(project: Path) -> dict[str, Any]:
    def command(*args: str) -> str:
        result = subprocess.run(["git", *args], cwd=project, capture_output=True, text=True, check=False)
        return result.stdout.strip() if result.returncode == 0 else "UNAVAILABLE"
    status = command("status", "--porcelain")
    return {"commit": command("rev-parse", "HEAD"), "dirty": bool(status and status != "UNAVAILABLE"),
            "status_sha256": sha256_text(status)}


def _dependencies() -> dict[str, str]:
    result = {}
    for name in ("rtl2lean-autonomous", "pyslang", "pytest"):
        try:
            result[name] = importlib.metadata.version(name)
        except importlib.metadata.PackageNotFoundError:
            result[name] = "not-installed-as-distribution"
    return result


def _secret_present(value: Any) -> bool:
    return bool(re.search(r"sk-[A-Za-z0-9_.-]{12,}", canonical_json(value)))


def _seed(config: dict[str, Any], source_hash: str, task_id: str, trial_id: int) -> int:
    raw = f"{config['sampling']['base_seed']}:{source_hash}:{task_id}:{trial_id}"
    return int(hashlib.sha256(raw.encode()).hexdigest()[:8], 16) & 0x7FFFFFFF


def validate_environment(
    config_path: Path, *, check_api: bool = True, persist: bool = True,
) -> tuple[dict[str, Any], list[dict[str, Any]], dict[str, Any], dict[str, Any]]:
    project = project_root(); config = load_config(config_path)
    if _secret_present(config):
        raise RuntimeError("API key literal detected in config; use DASHSCOPE_API_KEY")
    tasks, source = load_frozen_tasks(project, config)
    verify_frozen_tasks(project, tasks, source)
    checks = []
    with tempfile.TemporaryDirectory(prefix="foundation_first-validate-") as raw:
        for task in tasks:
            result = check_source(statement_source(task), project / task["model_dir"],
                                  Path(raw) / f"{task['challenge_id']}.lean",
                                  int(config["lean_timeout_seconds"]))
            checks.append({"challenge_id": task["challenge_id"], "success": result["success"],
                           "elapsed_s": result["elapsed_s"],
                           "error": None if result["success"] else (result["stdout"] + result["stderr"])[-4000:]})
    if not all(row["success"] for row in checks):
        raise RuntimeError("one or more frozen target statements do not elaborate")
    api = {"checked": False, "success": None, "formal_result_consumed": False}
    if check_api:
        health_config = {**config["proof_model"], "timeout_seconds": min(90, config["proof_model"]["timeout_seconds"]),
                         "max_completion_tokens": min(256, config["proof_model"]["max_completion_tokens"])}
        response = create_proof_model(health_config).generate(
            "Return a JSON object whose status field is exactly ok.", HEALTH_SCHEMA, 11)
        api = {"checked": True, "success": response.status == "API_SUCCESS" and response.candidate == {"status": "ok"},
               "status": response.status, "metadata": response.metadata, "usage": response.usage,
               "error": response.error, "formal_result_consumed": False}
        if not api["success"]:
            raise RuntimeError(f"proof-model API validation failed: {response.status}: {response.error}")
    result = {
        "schema": "rtl2lean-foundation_first-validation-v1", "timestamp": _now(), "status": "PASS",
        "config_sha256": digest(config), "frozen_challenges": len(tasks),
        "challenge_manifest_sha256": source["challenge_manifest_sha256"], "lean_version": lean_version(),
        "statement_checks": checks, "api": api, "credential_recorded": False,
        "forbidden_answer_fields_absent": all(
            not ({"reference_proof", "gap_spec", "baseline_lean_error"} & task.keys()) for task in tasks),
    }
    if persist:
        root = project / config["output_root"] / "validation"; root.mkdir(parents=True, exist_ok=True)
        atomic_json(root / datetime.now(timezone.utc).strftime("validation_%Y%m%dT%H%M%S%fZ.json"), result,
                    overwrite=False)
        atomic_json(root / "latest.json", result)
    return config, tasks, source, result


def _create_run(config_path: Path, argv: list[str]) -> tuple[Path, dict[str, Any], list[dict[str, Any]], dict[str, Any], str]:
    project = project_root()
    config, tasks, source, validation = validate_environment(config_path, check_api=True)
    run_id = datetime.now(timezone.utc).strftime("r11_%Y%m%dT%H%M%S%fZ_") + digest(config)[:10]
    run_dir = project / config["output_root"] / run_id
    for directory in ("manifests", "trials", "analysis", "tables", "case_studies"):
        (run_dir / directory).mkdir(parents=True, exist_ok=True)
    manifests = run_dir / "manifests"
    atomic_text(manifests / "config.yaml", config_path.resolve().read_text(encoding="utf-8"), overwrite=False)
    atomic_json(manifests / "challenges.json", {
        "schema": "rtl2lean-foundation_first-frozen-challenges-v1", "frozen_before_run": True,
        "challenge_count": len(tasks), "tasks": tasks, "source": source,
        "reference_proofs_excluded": True, "gap_specs_excluded": True,
    }, overwrite=False)
    package = Path(__file__).resolve().parent
    shared_diagnoser = package.parent / "adaptive_proving" / "lemma_diagnosis.py"
    policies = {
        "prompts.json": {**prompt_policy_manifest(), "implementation": "experiments/foundation_first/prompts.py",
                         "implementation_sha256": sha256_file(package / "prompts.py")},
        "proof_gap_policy.json": {**gap_policy_manifest(), "implementation": "experiments/foundation_first/proof_gap.py",
                                  "implementation_sha256": sha256_file(package / "proof_gap.py")},
        "prover_policy.json": {**prover_policy_manifest(), "implementation": "experiments/foundation_first/prover.py",
                               "implementation_sha256": sha256_file(package / "prover.py")},
        "diagnosis_taxonomy.json": taxonomy_manifest(),
        "diagnosis_policy.json": {**config["diagnosis_policy"],
            "implementation": "experiments/adaptive_proving/lemma_diagnosis.py",
            "implementation_sha256": sha256_file(shared_diagnoser)},
    }
    for name, payload in policies.items():
        atomic_json(manifests / name, payload, overwrite=False)
    seeds = [{"challenge_id": task["challenge_id"], "task_id": task["task_id"], "trial_id": trial,
              "seed": _seed(config, source["challenge_manifest_sha256"], task["task_id"], trial)}
             for task in tasks for trial in config["trial_ids"]]
    atomic_json(manifests / "seeds.json", {"schema": "rtl2lean-foundation_first-seeds-v1",
                                           "policy": config["sampling"], "rows": seeds}, overwrite=False)
    frozen_names = ["config.yaml", "challenges.json", *policies.keys(), "seeds.json"]
    hashes = {name: sha256_file(manifests / name) for name in frozen_names}
    manifest = {
        "schema": "rtl2lean-foundation_first-run-manifest-v1", "experiment_version": EXPERIMENT_VERSION,
        "run_id": run_id, "timestamp": _now(), "git": _git(project),
        "config_hash": digest(config), "challenge_manifest_hash": source["challenge_manifest_sha256"],
        "prompt_hash": hashes["prompts.json"], "proof_gap_policy_hash": hashes["proof_gap_policy.json"],
        "diagnosis_policy_hash": hashes["diagnosis_policy.json"], "prover_policy_hash": hashes["prover_policy.json"],
        "proof_model": {key: value for key, value in config["proof_model"].items() if key != "api_key"},
        "seeds": seeds, "lean_version": validation["lean_version"], "python_version": sys.version,
        "dependency_versions": _dependencies(), "platform": platform.platform(), "actual_cli_command": argv,
        "credential_environment_variable": config["proof_model"]["api_key_env"], "credential_recorded": False,
        "direct_arm_present": False, "llm_generates_final_property_proof": False,
        "frozen_manifest_hashes": hashes,
    }
    atomic_json(manifests / "run_manifest.json", manifest, overwrite=False)
    return run_dir, config, tasks, source, sha256_file(manifests / "run_manifest.json")


def _load_run(run_dir: Path) -> tuple[dict[str, Any], list[dict[str, Any]], dict[str, Any], str]:
    manifests = run_dir.resolve() / "manifests"; manifest = read_json(manifests / "run_manifest.json")
    if manifest.get("experiment_version") != EXPERIMENT_VERSION:
        raise RuntimeError("run is not foundation_first")
    for name, expected in manifest["frozen_manifest_hashes"].items():
        if sha256_file(manifests / name) != expected:
            raise RuntimeError(f"frozen artifact changed: {name}")
    config = load_yaml(manifests / "config.yaml"); validate_config(config)
    frozen = read_json(manifests / "challenges.json")
    verify_frozen_tasks(project_root(), frozen["tasks"], frozen["source"])
    return config, frozen["tasks"], frozen["source"], sha256_file(manifests / "run_manifest.json")


def _security_scan(run_dir: Path, env_name: str) -> dict[str, Any]:
    secret = os.environ.get(env_name, ""); generic = re.compile(rb"sk-[A-Za-z0-9_.-]{20,}")
    findings = []
    for path in sorted(item for item in run_dir.rglob("*") if item.is_file() and item.name != "security_scan.json"):
        data = path.read_bytes()
        if (secret and secret.encode() in data) or generic.search(data):
            findings.append(str(path.relative_to(run_dir)))
    result = {"schema": "rtl2lean-foundation_first-secret-scan-v1",
              "status": "PASS" if not findings else "FAIL", "findings": findings,
              "credential_value_recorded": False}
    atomic_json(run_dir / "security_scan.json", result)
    if findings:
        raise RuntimeError("credential-like literal found in run artifacts")
    return result


def _progress(run_dir: Path, expected: int) -> None:
    rows = load_results(run_dir)
    atomic_json(run_dir / "progress.json", {
        "schema": "rtl2lean-foundation_first-progress-v1", "completed": len(rows), "expected": expected,
        "foundation_pass": sum(row["foundation_only_pass"] for row in rows),
        "assisted_pass": sum(row["llm_assisted_property_pass"] for row in rows), "updated": _now()})


def _execute(run_dir: Path, config: dict[str, Any], tasks: list[dict[str, Any]], source: dict[str, Any],
             manifest_hash: str) -> None:
    model = create_proof_model(config["proof_model"]); expected = len(tasks) * len(config["trial_ids"])
    seeds = {(row["challenge_id"], row["trial_id"]): row["seed"]
             for row in read_json(run_dir / "manifests" / "seeds.json")["rows"]}
    for trial_id in config["trial_ids"]:
        for task in tasks:
            run_trial(project_root(), run_dir, task, trial_id, seeds[(task["challenge_id"], trial_id)],
                      config, source, manifest_hash, model)
            _progress(run_dir, expected)


def run_new(config_path: Path, argv: list[str]) -> tuple[Path, dict[str, Any]]:
    run_dir, config, tasks, source, manifest_hash = _create_run(config_path, argv)
    _execute(run_dir, config, tasks, source, manifest_hash)
    report = build_report(run_dir, tasks); _security_scan(run_dir, config["proof_model"]["api_key_env"])
    return run_dir, report


def resume_run(run_dir: Path) -> dict[str, Any]:
    run_dir = run_dir.resolve(); config, tasks, source, manifest_hash = _load_run(run_dir)
    _execute(run_dir, config, tasks, source, manifest_hash)
    report = build_report(run_dir, tasks); _security_scan(run_dir, config["proof_model"]["api_key_env"])
    return report


def report_run(run_dir: Path) -> dict[str, Any]:
    run_dir = run_dir.resolve(); config, tasks, _source, _hash = _load_run(run_dir)
    report = build_report(run_dir, tasks); _security_scan(run_dir, config["proof_model"]["api_key_env"])
    return report
