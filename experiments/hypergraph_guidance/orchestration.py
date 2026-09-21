"""Freeze a paired unseen experiment and run bridge-only vs TPOH/schema-guided arms."""
from __future__ import annotations

import hashlib
import os
import re
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from experiments.adaptive_proving.config import canonical_json, digest, load_yaml
from experiments.adaptive_proving.io import atomic_json, atomic_text, read_json, sha256_file, sha256_text
from experiments.adaptive_proving.lean import check_source, lean_version, statement_source
from experiments.adaptive_proving.proof_model import HEALTH_SCHEMA, create_proof_model
from experiments.bridge_discovery.trial import run_trial as run_control_trial
from experiments.bridge_discovery.bridge import policy_manifest as bridge_policy
from experiments.bridge_discovery.prover import policy_manifest as prover_policy

from . import EXPERIMENT_VERSION
from .config import load_config, validate_config
from .corpus import VALIDATION_HELPER, load_tasks, reference_proof, verify_tasks
from .hypergraph import policy_manifest as hypergraph_policy
from .prompts import policy_manifest as prompt_policy
from .report import build_report, load_control_results, load_schema_results
from .schemas import policy_manifest as schema_policy
from .trial import run_trial
from .utility import policy_manifest as utility_policy


def project_root() -> Path: return Path(__file__).resolve().parents[2]
def _now() -> str: return datetime.now(timezone.utc).isoformat()


def _seed(config: dict[str, Any], source_hash: str, task_id: str, trial: int) -> int:
    raw = f"{config['sampling']['base_seed']}:{source_hash}:{task_id}:{trial}"
    return int(hashlib.sha256(raw.encode()).hexdigest()[:8], 16) & 0x7fffffff


def _validation_source(task: dict[str, Any]) -> str:
    helper = VALIDATION_HELPER if task["property_level"] == "MULTI_CYCLE" else ""
    return "\n".join([f"import {task['context_import']}", "", "set_option maxRecDepth 100000",
        "set_option maxHeartbeats 8000000", "", f"namespace {task['module']}Verification", f"open {task['module']}",
        "", helper, f"theorem {task['task_id']} : {task['statement']} := {reference_proof(task)}", "",
        f"end {task['module']}Verification", ""])


def validate_environment(config_path: Path, check_api: bool = True, persist: bool = True):
    project = project_root(); config = load_config(config_path)
    if re.search(r"sk-[A-Za-z0-9_.-]{12,}", canonical_json(config)): raise RuntimeError("secret literal in config")
    tasks, source = load_tasks(project, config); verify_tasks(project, tasks, source); checks = []
    with tempfile.TemporaryDirectory(prefix="hypergraph_guidance-validation-") as raw:
        for task in tasks:
            statement = check_source(statement_source(task), project / task["model_dir"], Path(raw) / f"{task['challenge_id']}_statement.lean", 30)
            reference = check_source(_validation_source(task), project / task["model_dir"], Path(raw) / f"{task['challenge_id']}_reference.lean", 30)
            checks.append({"challenge_id": task["challenge_id"], "statement_elaborates": statement["success"],
                           "reference_kernel_pass": reference["success"], "reference_error": None if reference["success"] else
                           (reference["stdout"] + reference["stderr"])[-4000:]})
    if not all(row["statement_elaborates"] and row["reference_kernel_pass"] for row in checks):
        raise RuntimeError("new unseen corpus validation failed")
    api = {"checked": False, "success": None}
    if check_api:
        health = {**config["proof_model"], "timeout_seconds": 90, "max_completion_tokens": 256}
        response = create_proof_model(health).generate("Return a JSON object whose status field is exactly ok.", HEALTH_SCHEMA, 13)
        api = {"checked": True, "success": response.status == "API_SUCCESS" and response.candidate == {"status": "ok"},
               "status": response.status, "usage": response.usage, "metadata": response.metadata, "error": response.error}
        if not api["success"]: raise RuntimeError(f"API health failed: {response.status}: {response.error}")
    result = {"schema": "rtl2lean-hypergraph_guidance-validation-v1", "status": "PASS", "timestamp": _now(),
        "unseen_task_count": len(tasks), "previous_sets_disjoint": source["sets_disjoint"], "checks": checks,
        "api": api, "lean_version": lean_version(), "reference_proofs_excluded_from_formal_tasks": True,
        "credential_recorded": False, "direct_arm_present": False}
    if persist:
        root = project / config["output_root"] / "validation"; root.mkdir(parents=True, exist_ok=True)
        atomic_json(root / "latest.json", result)
    return config, tasks, source, result


def _create_run(config_path: Path, argv: list[str]):
    project = project_root(); config, tasks, source, validation = validate_environment(config_path, True)
    run_id = datetime.now(timezone.utc).strftime("r13_%Y%m%dT%H%M%S%fZ_") + digest(config)[:10]
    run_dir = project / config["output_root"] / run_id; manifests = run_dir / "manifests"; manifests.mkdir(parents=True)
    atomic_text(manifests / "config.yaml", config_path.resolve().read_text(), overwrite=False)
    atomic_json(manifests / "unseen_tasks.json", {"schema": "rtl2lean-hypergraph_guidance-unseen-tasks-v1",
        "frozen_before_run": True, "tasks": tasks, "source": source, "reference_proofs_excluded": True}, overwrite=False)
    package = Path(__file__).resolve().parent
    policies = {"hypergraph_policy.json": (hypergraph_policy(), package / "hypergraph.py"),
        "schema_policy.json": (schema_policy(), package / "schemas.py"),
        "utility_policy.json": (utility_policy(), package / "utility.py"),
        "prompt_policy.json": (prompt_policy(), package / "prompts.py"),
        "bridge_control_policy.json": (bridge_policy(), package.parent / "bridge_discovery" / "bridge.py"),
        "prover_policy.json": (prover_policy(), package.parent / "bridge_discovery" / "prover.py")}
    for name, (payload, impl) in policies.items():
        atomic_json(manifests / name, {**payload, "implementation": str(impl.relative_to(project)),
                                     "implementation_sha256": sha256_file(impl)}, overwrite=False)
    source_hash = sha256_file(manifests / "unseen_tasks.json")
    seeds = [{"challenge_id": task["challenge_id"], "trial_id": trial,
              "seed": _seed(config, source_hash, task["task_id"], trial)} for task in tasks for trial in config["trial_ids"]]
    atomic_json(manifests / "seeds.json", {"policy": config["sampling"], "rows": seeds}, overwrite=False)
    names = ["config.yaml", "unseen_tasks.json", *policies.keys(), "seeds.json"]
    hashes = {name: sha256_file(manifests / name) for name in names}
    manifest = {"schema": "rtl2lean-hypergraph_guidance-run-manifest-v1", "experiment_version": EXPERIMENT_VERSION,
        "run_id": run_id, "timestamp": _now(), "config_hash": digest(config), "frozen_manifest_hashes": hashes,
        "proof_model": config["proof_model"], "credential_recorded": False, "direct_arm_present": False,
        "paired_bridge_only_control": True, "same_unseen_tasks_and_seeds": True,
        "llm_generates_final_property_proof": False, "lean_version": validation["lean_version"],
        "actual_cli_command": argv, "python_version": sys.version}
    atomic_json(manifests / "run_manifest.json", manifest, overwrite=False)
    return run_dir, config, tasks, source, sha256_file(manifests / "run_manifest.json")


def _load_run(run_dir: Path):
    project = project_root(); manifests = run_dir / "manifests"; manifest = read_json(manifests / "run_manifest.json")
    if manifest["experiment_version"] != EXPERIMENT_VERSION: raise RuntimeError("not Req13")
    for name, expected in manifest["frozen_manifest_hashes"].items():
        if sha256_file(manifests / name) != expected: raise RuntimeError(f"frozen artifact changed: {name}")
    config = load_yaml(manifests / "config.yaml"); validate_config(config); corpus = read_json(manifests / "unseen_tasks.json")
    verify_tasks(project, corpus["tasks"], corpus["source"])
    return config, corpus["tasks"], corpus["source"], sha256_file(manifests / "run_manifest.json")


def _security(run_dir: Path, env_name: str):
    secret = os.environ.get(env_name, ""); regex = re.compile(rb"sk-[A-Za-z0-9_.-]{20,}"); findings = []
    for path in run_dir.rglob("*"):
        if path.is_file() and path.name != "security_scan.json":
            data = path.read_bytes()
            if (secret and secret.encode() in data) or regex.search(data): findings.append(str(path.relative_to(run_dir)))
    result = {"schema": "rtl2lean-hypergraph_guidance-secret-scan-v1", "status": "PASS" if not findings else "FAIL",
              "findings": findings, "credential_value_recorded": False}; atomic_json(run_dir / "security_scan.json", result)
    if findings: raise RuntimeError("credential found in artifacts")


def _execute(run_dir: Path, config: dict[str, Any], tasks: list[dict[str, Any]], source: dict[str, Any], manifest_hash: str):
    model = create_proof_model(config["proof_model"]); seeds = {(r["challenge_id"], r["trial_id"]): r["seed"]
        for r in read_json(run_dir / "manifests" / "seeds.json")["rows"]}
    control_config = {**config, "max_statement_redesign": config["max_edge_redesign"],
        "candidate_statements_per_call": config["candidate_edges_per_call"],
        "utility_policy": {"medium_structural_score": .6}}
    expected = len(tasks)
    for trial in config["trial_ids"]:
        for task in tasks:
            seed = seeds[(task["challenge_id"], trial)]
            run_control_trial(project_root(), run_dir / "control_bridge_only", task, trial, seed,
                              control_config, source, manifest_hash, model)
            run_trial(project_root(), run_dir, task, trial, seed, config, source, manifest_hash, model)
            schema_rows, control_rows = load_schema_results(run_dir), load_control_results(run_dir)
            atomic_json(run_dir / "progress.json", {"schema_completed": len(schema_rows),
                "control_completed": len(control_rows), "expected": expected,
                "schema_pass": sum(r["llm_assisted_property_pass"] for r in schema_rows),
                "control_pass": sum(r["llm_assisted_property_pass"] for r in control_rows), "updated": _now()})


def run_new(config_path: Path, argv: list[str]):
    run_dir, config, tasks, source, manifest_hash = _create_run(config_path, argv)
    _execute(run_dir, config, tasks, source, manifest_hash); report = build_report(run_dir, tasks)
    _security(run_dir, config["proof_model"]["api_key_env"]); return run_dir, report


def resume_run(run_dir: Path):
    config, tasks, source, manifest_hash = _load_run(run_dir.resolve()); _execute(run_dir.resolve(), config, tasks, source, manifest_hash)
    report = build_report(run_dir.resolve(), tasks); _security(run_dir.resolve(), config["proof_model"]["api_key_env"]); return report


def report_run(run_dir: Path):
    config, tasks, _source, _hash = _load_run(run_dir.resolve()); report = build_report(run_dir.resolve(), tasks)
    _security(run_dir.resolve(), config["proof_model"]["api_key_env"]); return report
