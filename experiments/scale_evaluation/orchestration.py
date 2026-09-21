from __future__ import annotations

import os
import re
import tempfile
from datetime import datetime, timezone
from pathlib import Path

from experiments.adaptive_proving.config import canonical_json, digest, load_yaml
from experiments.adaptive_proving.io import atomic_json, atomic_text, read_json, sha256_file
from experiments.adaptive_proving.lean import check_source, lean_version
from experiments.adaptive_proving.proof_model import HEALTH_SCHEMA, create_proof_model
from experiments.bridge_discovery.prover import run_foundation_prover
from . import EXPERIMENT_VERSION
from .binder import bind_state_transition, binder_policy
from .config import load_config, validate_config
from .corpus import load_tasks, verify_tasks
from .experiment import VARIANTS, _theorem_source, run_all
from .graph import construct_tpoh, graph_policy
from .report import build_report
from .schemas import plan_witness, schema_policy


def project_root() -> Path:
    return Path(__file__).resolve().parents[2]


def validate_environment(config_path: Path, api: bool = True, persist: bool = True):
    project = project_root()
    config = load_config(config_path)
    if re.search(r"sk-[A-Za-z0-9_.-]{12,}", canonical_json(config)):
        raise RuntimeError("credential must not be stored in config")
    tasks, source = load_tasks(project, config)
    verify_tasks(project, tasks, source)
    checks = []
    with tempfile.TemporaryDirectory(prefix="r15-validation-") as raw:
        temp = Path(raw)
        for task in tasks:
            reference = check_source(_theorem_source(task, "r15_reference",
                task["expected_candidate_statement"], task["reference_candidate_proof"], True),
                project / task["model_dir"], temp / task["challenge_id"] / "reference.lean",
                config["lean_timeout_seconds"])
            foundation = run_foundation_prover(project, temp / task["challenge_id"] / "foundation",
                                               task, config["lean_timeout_seconds"])
            graph = construct_tpoh(task)
            typed_ok = False
            if task["property_pattern"] == "STATE_TRANSITION":
                candidate = {"lemma_statement": task["expected_candidate_statement"],
                    "candidate_source": graph["initial_nodes"],
                    "candidate_target": graph["backward_target_frontier"][0],
                    "candidate_edge_type": task["property_pattern"]}
                typed_ok = bind_state_transition(project, temp / task["challenge_id"] / "binder",
                    task, candidate, config["lean_timeout_seconds"])["binding_success"]
            else:
                candidate = {"lemma_statement": task["expected_candidate_statement"]}
                witness = plan_witness(project, temp / task["challenge_id"] / "witness", task,
                                       candidate, config["lean_timeout_seconds"])
                typed_ok = witness["proposal_success"] and witness["typed_witness_acceptance"]
            checks.append({"challenge_id": task["challenge_id"], "dut": task["dut"],
                "pattern": task["property_pattern"], "reference_kernel_pass": reference["success"],
                "foundation_gap_confirmed": not foundation["success"],
                "tpoh_constructed": graph["construction_success"],
                "missing_hyperedge_detected": bool(graph["missing_hyperedges"]),
                "typed_precondition_pass": typed_ok,
                "reference_error": None if reference["success"] else (reference["stdout"] + reference["stderr"])[-3000:]})
    if not all(row["reference_kernel_pass"] for row in checks):
        raise RuntimeError("one or more Req15 reference proofs are not kernel valid")
    if not all(row["foundation_gap_confirmed"] for row in checks):
        raise RuntimeError("one or more Req15 tasks are not genuine foundation gaps")
    if not all(row["tpoh_constructed"] and row["missing_hyperedge_detected"] and
               row["typed_precondition_pass"] for row in checks):
        raise RuntimeError("Req15 graph/schema typed prevalidation failed")
    health = {"checked": False}
    if api:
        model_config = {**config["proof_model"], "timeout_seconds": 90, "max_completion_tokens": 256}
        response = create_proof_model(model_config).generate(
            "Return a JSON object whose status field is exactly ok.", HEALTH_SCHEMA, 15)
        health = {"checked": True, "success": response.status == "API_SUCCESS" and
            response.candidate == {"status": "ok"}, "status": response.status,
            "error": response.error, "usage": response.usage}
        if not health["success"]:
            raise RuntimeError("Qwen API health check failed")
    validation = {"schema": "rtl2lean-scale_evaluation-validation-v1", "status": "PASS",
        "timestamp": datetime.now(timezone.utc).isoformat(), "checks": checks, "api": health,
        "lean_version": lean_version(), "unseen_task_count": len(tasks), "dut_count": 5,
        "reference_proofs_excluded": True, "direct_arm_present": False}
    if persist:
        atomic_json(project / config["output_root"] / "validation" / "latest.json", validation)
    formal = [{key: value for key, value in task.items() if key != "reference_candidate_proof"}
              for task in tasks]
    return config, tasks, formal, source, validation


def create_run(config_path: Path, argv: list[str]):
    project = project_root()
    config, private, formal, source, validation = validate_environment(config_path, api=True)
    run_id = datetime.now(timezone.utc).strftime("r15_%Y%m%dT%H%M%S%fZ_") + digest(config)[:10]
    run_dir = project / config["output_root"] / run_id
    manifests = run_dir / "manifests"
    manifests.mkdir(parents=True)
    atomic_text(manifests / "config.yaml", config_path.resolve().read_text(encoding="utf-8"))
    atomic_json(manifests / "tasks.json", {"tasks": formal, "source": source,
        "reference_proofs_excluded": True, "frozen_before_formal_run": True})
    files = [Path(__file__).parent / name for name in ["config.py", "corpus.py", "graph.py",
        "binder.py", "schemas.py", "experiment.py", "report.py", "orchestration.py"]]
    hashes = {str(path.relative_to(project)): sha256_file(path) for path in files}
    atomic_json(manifests / "implementation_hashes.json", hashes)
    atomic_json(manifests / "policies.json", {"graph": graph_policy(), "binder": binder_policy(),
                                               "schemas": schema_policy()})
    atomic_json(manifests / "run_manifest.json", {"schema": "rtl2lean-scale_evaluation-run-v1",
        "experiment_version": EXPERIMENT_VERSION, "run_id": run_id,
        "timestamp": datetime.now(timezone.utc).isoformat(), "argv": argv,
        "variants": config["variants"], "variant_modules": VARIANTS,
        "same_candidate_draw_between_variants": True, "same_model_seed_budget": True,
        "direct_arm_present": False, "phase_to_phase_present": False,
        "reference_proofs_hidden": True, "unseen_tasks_frozen": True,
        "implementation_hashes": hashes})
    return run_dir, config, private, source


def security_scan(run_dir: Path, env_name: str) -> dict:
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
        raise RuntimeError("credential leaked into Req15 artifacts")
    return result


def run_new(config_path: Path, argv: list[str]):
    run_dir, config, tasks, source = create_run(config_path, argv)
    model = create_proof_model(config["proof_model"])
    run_all(project_root(), run_dir, tasks, config, source, model)
    report = build_report(project_root(), run_dir, tasks, config["variants"], config["boundary_evaluation_run"])
    security_scan(run_dir, config["proof_model"]["api_key_env"])
    return run_dir, report


def load_run(run_dir: Path):
    config = load_yaml(run_dir / "manifests" / "config.yaml")
    validate_config(config)
    formal = read_json(run_dir / "manifests" / "tasks.json")
    private, source = load_tasks(project_root(), config)
    if [row["task_id"] for row in private] != [row["task_id"] for row in formal["tasks"]]:
        raise RuntimeError("frozen task manifest mismatch")
    return config, private, source


def resume(run_dir: Path):
    config, tasks, source = load_run(run_dir)
    run_all(project_root(), run_dir, tasks, config, source, create_proof_model(config["proof_model"]))
    report = build_report(project_root(), run_dir, tasks, config["variants"], config["boundary_evaluation_run"])
    security_scan(run_dir, config["proof_model"]["api_key_env"])
    return report


def rebuild_report(run_dir: Path):
    config, tasks, source = load_run(run_dir)
    report = build_report(project_root(), run_dir, tasks, config["variants"], config["boundary_evaluation_run"])
    security_scan(run_dir, config["proof_model"]["api_key_env"])
    return report
