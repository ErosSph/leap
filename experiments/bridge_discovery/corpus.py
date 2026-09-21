"""Separate C01-C10 development data from frozen unseen E01-E10 evaluation data."""
from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from experiments.adaptive_proving.corpus import ALIASES
from experiments.adaptive_proving.io import sha256_file, sha256_text, tree_digest
from experiments.foundation_first.corpus import load_frozen_tasks as load_development_tasks


def _read(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def load_corpora(project: Path, config: dict[str, Any]) -> tuple[list[dict[str, Any]], list[dict[str, Any]], dict[str, Any]]:
    # Reuse the exact Req11 adapter only for the development set and theorem inventory.
    compat = {**config, "challenge_manifest": config["development_manifest"],
              "baseline_manifest": "outputs/multi_phase_proofs/baseline/results.json"}
    development, dev_source = load_development_tasks(project, compat)
    dev_ids = {task["task_id"] for task in development}
    evaluation_path = project / config["evaluation_manifest"]
    benchmark_path = project / config["benchmark_manifest"]
    rows = _read(evaluation_path).get("properties") or []
    unseen = [row for row in rows if row["property_id"] not in dev_ids]
    if len(rows) != 20 or len(unseen) != 10:
        raise RuntimeError("expected 20 frozen properties split into 10 development and 10 unseen")
    benchmarks = {row["design_id"]: row for row in _read(benchmark_path)["designs"]}
    tasks = []
    for index, prop in enumerate(unseen, 1):
        if prop.get("validation_status") != "KERNEL_VALIDATED":
            raise RuntimeError(f"unseen property is not kernel validated: {prop['property_id']}")
        benchmark = benchmarks[prop["dut"]]
        slug = ALIASES.get(prop["dut"], prop["dut"])
        model_dir = project / "outputs" / slug / "model"
        task = {
            "challenge_id": f"E{index:02d}", "task_id": prop["property_id"],
            "dut": prop["dut"], "module": benchmark["top_module"],
            "model_dir": str(model_dir.relative_to(project)), "context_import": "R5Foundation",
            "statement": prop["theorem_statement"],
            "statement_sha256": sha256_text(prop["theorem_statement"]),
            "property_family": prop["property_family"], "property_level": prop["property_level"],
            "state_type": f"{benchmark['top_module']}State",
            "required_state_fields": list(prop.get("referenced_state_fields", [])),
            "required_input_fields": list(prop.get("referenced_inputs", [])),
            "foundation_lemmas": list(prop.get("foundation_lemmas", [])),
            "source_property_sha256": sha256_text(json.dumps(prop, ensure_ascii=False, sort_keys=True)),
            "reference_proof_excluded": True, "gap_spec_excluded": True,
            "development_set_member": False, "unseen_evaluation_member": True,
        }
        tasks.append(task)
    source = {
        **dev_source,
        "development_manifest": config["development_manifest"],
        "development_manifest_sha256": sha256_file(project / config["development_manifest"]),
        "evaluation_manifest": config["evaluation_manifest"],
        "evaluation_manifest_sha256": sha256_file(evaluation_path),
        "development_task_ids": sorted(dev_ids),
        "evaluation_task_ids": [task["task_id"] for task in tasks],
        "sets_disjoint": not bool(dev_ids & {task["task_id"] for task in tasks}),
    }
    return development, tasks, source


def verify_corpora(project: Path, development: list[dict[str, Any]], tasks: list[dict[str, Any]], source: dict[str, Any]) -> None:
    if len(development) != 10 or len(tasks) != 10 or not source.get("sets_disjoint"):
        raise RuntimeError("development/evaluation split invariant failed")
    for key in ("development_manifest", "evaluation_manifest"):
        path = project / source[key]
        if sha256_file(path) != source[f"{key}_sha256"]:
            raise RuntimeError(f"frozen corpus changed: {path}")
    for base in source["theorem_bases"]:
        if tree_digest(project / base["model_dir"]) != base["tree_sha256"]:
            raise RuntimeError(f"theorem base changed: {base['dut']}")


def theorem_base_for(source: dict[str, Any], dut: str) -> dict[str, Any]:
    return next(row for row in source["theorem_bases"] if row["dut"] == dut)
