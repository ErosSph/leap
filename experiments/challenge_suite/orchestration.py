from __future__ import annotations

import hashlib
import json
import os
import re
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from experiments.adaptive_proving.io import atomic_json, atomic_text
from experiments.adaptive_proving.proof_model import create_proof_model
from .ablation import causal_audit, run as run_ablation
from .config import load_config
from .corpus import generate_hard_corpus, reference_audit
from .direct import run_all
from .report import build
from .translation_cache import benchmark as benchmark_translation


def project_root() -> Path:
    return Path(__file__).resolve().parents[2]


def _security(run_dir: Path, env_name: str) -> dict[str, Any]:
    secret = os.environ.get(env_name, "")
    pattern = re.compile(rb"sk-[A-Za-z0-9_.-]{20,}")
    findings = []
    for path in run_dir.rglob("*"):
        if path.is_file() and path.name != "security_scan.json":
            data = path.read_bytes()
            if (secret and secret.encode() in data) or pattern.search(data):
                findings.append(str(path.relative_to(run_dir)))
    result = {"status": "PASS" if not findings else "FAIL", "findings": findings,
              "credential_recorded": False}
    atomic_json(run_dir / "security_scan.json", result)
    if findings:
        raise RuntimeError("credential leaked into challenge_suite artifacts")
    return result


def prepare(config_path: Path) -> tuple[Path, dict[str, Any], list[dict[str, Any]], dict[str, Any]]:
    project = project_root(); config = load_config(config_path)
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
    fingerprint = hashlib.sha256(config_path.read_bytes()).hexdigest()[:10]
    run_dir = project / config["output_root"] / f"r17_{stamp}_{fingerprint}"
    run_dir.mkdir(parents=True, exist_ok=False)
    atomic_text(run_dir / "manifests" / "config.yaml", config_path.read_text(encoding="utf-8"))
    atomic_json(run_dir / "manifests" / "run_manifest.json", {
        "schema": "rtl2lean-challenge_suite-run-v1", "timestamp": datetime.now(timezone.utc).isoformat(),
        "model": config["proof_model"]["model"], "credential_source": config["proof_model"]["api_key_env"],
        "credential_recorded": False, "direct_max_iterations": 5,
        "direct_pool": False, "direct_graph": False,
        "ablation_changes_only_selector": True})
    tasks, manifest = generate_hard_corpus(project, run_dir, config)
    reference_audit(project, run_dir, tasks, manifest, config)
    return run_dir, config, tasks, manifest


def run_new(config_path: Path) -> tuple[Path, dict[str, Any]]:
    project = project_root(); run_dir, config, tasks, manifest = prepare(config_path)
    translation = benchmark_translation(project, run_dir, manifest, config)
    model = create_proof_model(config["proof_model"])
    ablation = run_ablation(project, run_dir, tasks, manifest, config, model)
    causal_audit(project, run_dir, tasks, manifest, config)
    direct = run_all(project, run_dir, tasks, manifest, config, model)
    req16 = json.loads((project / config["source_design_suite_run"] /
                        "final_report.json").read_text(encoding="utf-8"))
    report = build(run_dir, tasks, direct, ablation, translation, req16, config)
    security = _security(run_dir, config["proof_model"]["api_key_env"])
    atomic_json(run_dir / "progress.json", {"phase": "COMPLETE", "status": report["status"],
        "completed": len(direct), "total": len(tasks), "security": security["status"]})
    return run_dir, report


def resume_run(run_dir: Path) -> tuple[Path, dict[str, Any]]:
    project = project_root(); run_dir = run_dir.resolve()
    config = load_config(run_dir / "manifests" / "config.yaml")
    manifest = json.loads((run_dir / "manifests" / "tasks.json").read_text(encoding="utf-8"))
    tasks = manifest["tasks"]
    if json.loads((run_dir / "analysis/property_audit.json").read_text())["kernel_pass"] != 177:
        raise RuntimeError("cannot resume before the 177-task reference audit passes")
    translation = json.loads((run_dir / "translation/cache_benchmark.json").read_text())
    ablation = json.loads((run_dir / "ablation/graph_ablation.json").read_text())
    if not (run_dir / "ablation/causal_deletion.json").is_file():
        causal_audit(project, run_dir, tasks, manifest, config)
    direct = run_all(project, run_dir, tasks, manifest, config,
                     create_proof_model(config["proof_model"]))
    req16 = json.loads((project / config["source_design_suite_run"] /
                        "final_report.json").read_text(encoding="utf-8"))
    report = build(run_dir, tasks, direct, ablation, translation, req16, config)
    security = _security(run_dir, config["proof_model"]["api_key_env"])
    atomic_json(run_dir / "progress.json", {"phase": "COMPLETE", "status": report["status"],
        "completed": len(direct), "total": len(tasks), "security": security["status"]})
    return run_dir, report


def refresh_run(run_dir: Path) -> tuple[Path, dict[str, Any]]:
    """Rebuild reports from completed artifacts without creating an LLM client."""
    project = project_root(); run_dir = run_dir.resolve()
    config = load_config(run_dir / "manifests/config.yaml")
    manifest = json.loads((run_dir / "manifests/tasks.json").read_text(encoding="utf-8"))
    tasks = manifest["tasks"]
    translation = json.loads((run_dir / "translation/cache_benchmark.json").read_text())
    ablation = json.loads((run_dir / "ablation/graph_ablation.json").read_text())
    direct = json.loads((run_dir / "direct/all_results.json").read_text())
    req16 = json.loads((project / config["source_design_suite_run"] /
                        "final_report.json").read_text(encoding="utf-8"))
    report = build(run_dir, tasks, direct, ablation, translation, req16, config)
    security = _security(run_dir, config["proof_model"]["api_key_env"])
    atomic_json(run_dir / "progress.json", {"phase": "COMPLETE", "status": report["status"],
        "completed": len(direct), "total": len(tasks), "security": security["status"]})
    return run_dir, report
