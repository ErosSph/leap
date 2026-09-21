from __future__ import annotations

import hashlib
import json
import os
import re
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from experiments.adaptive_proving.io import atomic_json, atomic_text
from experiments.adaptive_proving.proof_model import HEALTH_SCHEMA, create_proof_model
from experiments.adaptive_proving.lean import lean_version
from .config import load_config
from .corpus import generate_corpus, reference_audit
from .experiment import run_all
from .report import build_report


def project_root() -> Path:
    return Path(__file__).resolve().parents[2]


def _adaptation(project: Path, config: dict[str, Any]) -> dict[str, Any]:
    rows = []
    metadata = {
        "zipcpu": ("zipcore", "https://github.com/ZipCPU/zipcpu.git",
                   "42606d2d6ef55df313772232977621b2d72f0159"),
        "dma_axi": ("dma_axi32_core0_ch", "https://github.com/freecores/dma_axi.git",
                    "bdd0b77559c6410b0a48799026453e3a9fd7b0d3"),
    }
    for dut in ["zipcpu", "dma_axi"]:
        model = project / config["adaptation_root"] / dut / "model"
        stage1 = project / config["adaptation_root"] / dut / "stage1.json"
        stage2 = project / config["adaptation_root"] / dut / "stage2.json"
        payload1 = json.loads(stage1.read_text()) if stage1.is_file() else {}
        payload2 = json.loads(stage2.read_text()) if stage2.is_file() else {}
        top, repo, commit = metadata[dut]
        rows.append({"dut": dut, "top_module": top, "repository": repo, "commit": commit,
            "stage1_model_kernel_pass": payload1.get("status") == "STAGE1_PASS",
            "stage2_foundation_kernel_pass": payload2.get("status") == "STAGE2_PASS",
            "generated_lean_loc": payload1.get("generated_lean_loc"),
            "model_olean_present": (model / "Model.olean").is_file(),
            "framework_olean_present": (model / "Framework.olean").is_file()})
    return {"status": "PASS" if all(r["stage1_model_kernel_pass"] and
        r["stage2_foundation_kernel_pass"] for r in rows) else "FAIL", "designs": rows,
        "adapters": ["STATIC_INITIAL_TO_LEAN_INIT", "UNIFIED_COMPILATION_UNIT",
                     "ALLOW_LEGACY_USE_BEFORE_DECLARE", "UNDRIVEN_CHILD_OUTPUT_FILTER",
                     "CONTEXT_WIDTHED_CONTINUOUS_ASSIGN"]}


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
        raise RuntimeError("credential leaked into design_suite artifacts")
    return result


def validate(config_path: Path, api: bool = True) -> dict[str, Any]:
    project = project_root(); config = load_config(config_path)
    model = create_proof_model(config["proof_model"])
    health = model.generate("Return exactly {\"status\":\"ok\"}.", HEALTH_SCHEMA,
                            config["base_seed"]).serializable() if api else {"status": "SKIPPED"}
    adaptation = _adaptation(project, config)
    result = {"status": "PASS" if adaptation["status"] == "PASS" and
              (not api or health["status"] == "API_SUCCESS") else "FAIL",
              "lean": lean_version(), "adaptation": adaptation, "api_health": health}
    out = project / config["output_root"] / "validation" / "latest.json"
    atomic_json(out, result); return result


def run_new(config_path: Path, argv: list[str]) -> tuple[Path, dict[str, Any]]:
    project = project_root(); config = load_config(config_path)
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
    fingerprint = hashlib.sha256(config_path.read_bytes()).hexdigest()[:10]
    run_dir = project / config["output_root"] / f"r16_{stamp}_{fingerprint}"
    run_dir.mkdir(parents=True, exist_ok=False)
    atomic_text(run_dir / "manifests" / "config.yaml",
                config_path.resolve().read_text(encoding="utf-8"))
    atomic_json(run_dir / "manifests" / "run_manifest.json", {
        "schema": "rtl2lean-design_suite-run-v1", "timestamp": datetime.now(timezone.utc).isoformat(),
        "argv": argv, "model": config["proof_model"]["model"],
        "credential_source": config["proof_model"]["api_key_env"], "credential_recorded": False,
        "lemma_first_only": True, "direct_arm": False, "max_iterations": 5,
        "same_dut_pool_only": True})
    adaptation = _adaptation(project, config)
    if adaptation["status"] != "PASS":
        raise RuntimeError("ZipCPU/AXI DMA adaptation must pass before proving")
    tasks, manifest = generate_corpus(project, run_dir, config)
    reference_audit(project, run_dir, tasks, manifest, config)
    results = run_all(project, run_dir, tasks, manifest, config,
                      create_proof_model(config["proof_model"]))
    report = build_report(run_dir, tasks, results, config, adaptation)
    _security(run_dir, config["proof_model"]["api_key_env"])
    atomic_json(run_dir / "progress.json", {"status": report["status"],
                                             "completed": len(results), "total": len(tasks)})
    return run_dir, report
