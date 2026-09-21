"""Derive and freeze new H01-H10 tasks from previously unused local-step theorems."""
from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any

from experiments.adaptive_proving.io import sha256_file, sha256_text, tree_digest
from experiments.bridge_discovery.config import load_config as load_r12_config
from experiments.bridge_discovery.corpus import load_corpora as load_r12_corpora


LOCAL_RE = re.compile(
    r"∀\s*\(s\s*:\s*([^()]+)\)\s*\(item\s*:\s*([^()]+)\),\s*"
    r"([A-Za-z_][A-Za-z0-9_']*)\s+s\s+item\s*→\s*\(r3Step\s+s\s+item\)\."
    r"([A-Za-z_][A-Za-z0-9_']*)\s*=\s*(.*)", re.S)


def _read(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def _symbolic(statement: str) -> tuple[str, dict[str, str]]:
    match = LOCAL_RE.fullmatch(statement.strip())
    if not match: raise RuntimeError("unsupported local-step signature: " + statement[:160])
    state_type, input_type, guard, field, rhs = (value.strip() for value in match.groups())
    rhs = re.sub(r"(?<![A-Za-z0-9_'])s(?![A-Za-z0-9_'])", "(r3Run s pre)", rhs)
    target = (f"∀ (s : {state_type}) (pre : List {input_type}) (item : {input_type}), "
        f"R3Temporal.Along r3Step {guard} s (pre ++ [item]) → "
        f"(r3Run s (pre ++ [item])).{field} = {rhs}")
    return target, {"state_type": state_type, "input_type": input_type, "guard": guard, "field": field}


def load_tasks(project: Path, config: dict[str, Any]) -> tuple[list[dict[str, Any]], dict[str, Any]]:
    r12_config = load_r12_config(project / "configs/bridge_discovery.yaml")
    development, evaluation, source = load_r12_corpora(project, r12_config)
    used = {name for task in development + evaluation for name in task.get("foundation_lemmas", [])
            if str(name).endswith("_local_step")}
    previous_ids = {task["task_id"] for task in development + evaluation}
    pilot_records = []
    for pilot_run in config.get("pilot_runs", []):
        pilot_path = project / str(pilot_run) / "manifests" / "unseen_tasks.json"
        if not pilot_path.is_file(): raise RuntimeError(f"missing declared pilot corpus: {pilot_path}")
        pilot = _read(pilot_path); pilot_records.append({"run": pilot_run, "corpus_sha256": sha256_file(pilot_path)})
        used.update(task["selected_local_step"] for task in pilot["tasks"])
        previous_ids.update(task["task_id"] for task in pilot["tasks"])
    tasks = []; selected = []
    for base in source["theorem_bases"]:
        candidates = sorted((row for row in base["theorems"]
            if str(row.get("name", "")).endswith("_local_step") and row["name"] not in used),
            key=lambda row: row["name"])
        if not candidates: raise RuntimeError(f"no unused local-step theorem for {base['dut']}")
        theorem = candidates[0]; symbolic, parsed = _symbolic(theorem["statement"])
        tag = sha256_text(theorem["name"])[:8]
        common = {"dut": base["dut"], "module": base["module"], "model_dir": base["model_dir"],
            "context_import": "R5Foundation", "state_type": parsed["state_type"],
            "required_state_fields": [parsed["field"]], "required_input_fields": [],
            "foundation_lemmas": [theorem["name"]], "selected_local_step": theorem["name"],
            "reference_proof_excluded": True, "gap_spec_excluded": True,
            "development_set_member": False, "bridge_discovery_evaluation_member": False,
            "hypergraph_guidance_unseen_member": True}
        pair = [
            {**common, "task_id": f"r13v2_covered_{parsed['field']}_{tag}", "statement": theorem["statement"],
             "property_family": "FOUNDATION_LOCAL_STEP", "property_level": "SINGLE_STEP"},
            {**common, "task_id": f"r13v2_symbolic_endpoint_{parsed['field']}_{tag}", "statement": symbolic,
             "property_family": "SYMBOLIC_POSITION_BRIDGE", "property_level": "MULTI_CYCLE"},
        ]
        for task in pair:
            task["challenge_id"] = f"J{len(tasks)+1:02d}"
            task["statement_sha256"] = sha256_text(task["statement"]); tasks.append(task)
        selected.append({"dut": base["dut"], "local_step": theorem["name"],
                         "local_step_statement_sha256": sha256_text(theorem["statement"])})
    old_ids = previous_ids
    if len(tasks) != 10 or old_ids & {task["task_id"] for task in tasks}:
        raise RuntimeError("Req13 unseen split invariant failed")
    result_source = {**source, "selection_algorithm": "lexicographically-first-unused-local-step-per-DUT",
        "selected_local_steps": selected, "previous_task_ids": sorted(old_ids),
        "evaluation_task_ids": [task["task_id"] for task in tasks], "sets_disjoint": True,
        "bridge_discovery_run": config["bridge_discovery_run"],
        "bridge_discovery_report_sha256": sha256_file(project / config["bridge_discovery_run"] / "final_report.json"),
        "pilot_runs": pilot_records,
        "pilot_excluded_from_formal_evaluation": True}
    return tasks, result_source


def verify_tasks(project: Path, tasks: list[dict[str, Any]], source: dict[str, Any]) -> None:
    if len(tasks) != 10 or not source.get("sets_disjoint"): raise RuntimeError("invalid Req13 corpus")
    if {task["task_id"] for task in tasks} & set(source["previous_task_ids"]):
        raise RuntimeError("Req13 evaluation leaks a previous property")
    if sha256_file(project / source["bridge_discovery_run"] / "final_report.json") != source["bridge_discovery_report_sha256"]:
        raise RuntimeError("Req12 source report changed")
    for record in source.get("pilot_runs", []):
        pilot = project / record["run"] / "manifests" / "unseen_tasks.json"
        if not pilot.is_file() or sha256_file(pilot) != record["corpus_sha256"]:
            raise RuntimeError("Req13 pilot corpus changed")
    for base in source["theorem_bases"]:
        if tree_digest(project / base["model_dir"]) != base["tree_sha256"]:
            raise RuntimeError(f"theorem base changed: {base['dut']}")


def theorem_base_for(source: dict[str, Any], dut: str) -> dict[str, Any]:
    return next(row for row in source["theorem_bases"] if row["dut"] == dut)


def reference_proof(task: dict[str, Any]) -> str:
    if task["property_level"] == "SINGLE_STEP": return f"by exact {task['selected_local_step']}"
    return """by
  intro s pre item h
  rw [r3_run_append]
  apply LOCAL_STEP
  exact r13_validation_last_guard _ _ _ _ _ h""".replace("LOCAL_STEP", task["selected_local_step"])


VALIDATION_HELPER = """theorem r13_validation_last_guard :
    ∀ (step : σ → ι → σ) (guard : σ → ι → Prop) (s : σ) (pre : List ι) (item : ι),
      R3Temporal.Along step guard s (pre ++ [item]) →
      guard (R3Temporal.exec step s pre) item := by
  intro step guard s pre item h
  induction pre generalizing s with
  | nil =>
    simp at h ⊢
    exact h.1
  | cons a rest ih =>
    have h' := h
    simp [List.cons_append, R3Temporal.Along] at h'
    exact ih (step s a) h'.2
"""
