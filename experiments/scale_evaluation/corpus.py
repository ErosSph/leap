"""Derive ten genuinely new Req15 tasks from the frozen theorem bases."""
from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any

from experiments.adaptive_proving.io import sha256_file, sha256_text, tree_digest
from experiments.hypergraph_guidance.config import load_config as load13_config
from experiments.hypergraph_guidance.corpus import load_tasks as load13_tasks


PATTERNS = ["STATE_TRANSITION", "WITNESS_CONSTRUCTION"]
LOCAL_RE = re.compile(
    r"∀\s*\(s\s*:\s*([^()]+)\)\s*\(item\s*:\s*([^()]+)\),\s*"
    r"([A-Za-z_][A-Za-z0-9_']*)\s+s\s+item\s*→\s*\(r3Step\s+s\s+item\)\."
    r"([A-Za-z_][A-Za-z0-9_']*)\s*=\s*(.*)", re.S,
)


def _read(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def _replace_vars(expression: str, state: str, item: str) -> str:
    expression = re.sub(r"(?<![A-Za-z0-9_'])s(?![A-Za-z0-9_'])", state, expression)
    return re.sub(r"(?<![A-Za-z0-9_'])item(?![A-Za-z0-9_'])", item, expression)


def _parse_local(theorem: dict[str, Any]) -> dict[str, str]:
    match = LOCAL_RE.fullmatch(theorem["statement"].strip())
    if not match:
        raise RuntimeError("unsupported local-step theorem: " + theorem["name"])
    state_type, input_type, guard, field, rhs = (value.strip() for value in match.groups())
    expected = _replace_vars(rhs, "t", "x")
    return {"state_type": state_type, "input_type": input_type, "guard": guard,
            "field": field, "rhs": rhs, "expected": expected}


def _wrapper(candidate: str) -> str:
    return f"({candidate}) ∧ True"


def load_tasks(project: Path, config: dict[str, Any]) -> tuple[list[dict[str, Any]], dict[str, Any]]:
    c13 = load13_config(project / "configs/hypergraph_guidance.yaml")
    old13, source13 = load13_tasks(project, c13)
    req14_path = project / config["boundary_evaluation_run"] / "manifests" / "tasks.json"
    req14 = _read(req14_path)
    historical = [*old13, *req14["tasks"]]
    used_steps = {name for task in historical for name in task.get("foundation_lemmas", [])
                  if str(name).endswith("_local_step")}
    old_ids = {task["task_id"] for task in historical}
    old_statements = {task["statement"] for task in historical}
    tasks: list[dict[str, Any]] = []
    selected: list[dict[str, Any]] = []

    # One state-transition and one witness task for every frozen target DUT.
    for base in source13["theorem_bases"]:
        local = next((row for row in sorted(base["theorems"], key=lambda row: row["name"])
                      if row["name"].endswith("_local_step") and row["name"] not in used_steps), None)
        if local is None:
            raise RuntimeError(f"no unseen local-step theorem remains for {base['dut']}")
        parsed = _parse_local(local)
        module = base["module"]
        common = {"dut": base["dut"], "module": module, "model_dir": base["model_dir"],
                  "context_import": "R5Foundation", "state_type": parsed["state_type"],
                  "input_type": parsed["input_type"], "reference_proof_excluded": True,
                  "previous_set_member": False, "theorem_base_tree_sha256": base["tree_sha256"]}

        state_candidate = (
            f"∀ (s : {parsed['state_type']}) (xs : List {parsed['input_type']}), "
            f"R3Temporal.Along r3Step {parsed['guard']} s xs → "
            f"R3Temporal.Obeys r3Step {parsed['guard']} "
            f"(fun t x => {parsed['expected']}) (fun t => t.{parsed['field']}) s xs"
        )
        fq_local = f"{module}Verification.{local['name']}"
        state_reference = (
            "by\n  intro s xs h\n  exact R3Temporal.obeys_of_along "
            f"(step := r3Step) (guard := {parsed['guard']}) "
            f"(expected := fun t x => {parsed['expected']}) (obs := fun t => t.{parsed['field']}) "
            f"(hstep := {fq_local}) s xs h"
        )
        state_task = {**common, "challenge_id": f"S{len(selected)+1:02d}",
            "task_id": f"r15_state_{sha256_text(local['name'])[:10]}",
            "property_pattern": "STATE_TRANSITION", "statement": _wrapper(state_candidate),
            "expected_candidate_statement": state_candidate, "foundation_lemmas": [local["name"]],
            "selected_local_step": local["name"], "reference_candidate_proof": state_reference,
            "transition_spec": {**parsed, "local_theorem_name": local["name"],
                "fully_qualified_local_theorem": fq_local, "local_theorem_signature": local["statement"]}}
        state_task["statement_sha256"] = sha256_text(state_task["statement"])
        tasks.append(state_task)

        witness_candidate = (
            f"∀ (s : {parsed['state_type']}) (trace : List {parsed['input_type']}) "
            f"(item : {parsed['input_type']}), ∃ extended : List {parsed['input_type']}, "
            f"extended ≠ [] ∧ r3Run s extended = r3Step (r3Run s trace) item"
        )
        witness_reference = """by
  intro s trace item
  refine ⟨trace ++ [item], ?_, ?_⟩
  · simp
  · rw [r3_run_append]
    rfl"""
        witness_task = {**common, "challenge_id": f"W{len(selected)+1:02d}",
            "task_id": f"r15_witness_{sha256_text(base['dut'])[:10]}",
            "property_pattern": "WITNESS_CONSTRUCTION", "statement": _wrapper(witness_candidate),
            "expected_candidate_statement": witness_candidate,
            "foundation_lemmas": ["r3_run_append"],
            "reference_candidate_proof": witness_reference,
            "witness_spec": {"existential_type": f"List {parsed['input_type']}",
                "candidate_witness": "trace ++ [item]", "source_theorem": None,
                "rewrite_theorem": "r3_run_append", "source_kind": "EXISTING_TRACE"}}
        witness_task["statement_sha256"] = sha256_text(witness_task["statement"])
        tasks.append(witness_task)
        selected.append({"dut": base["dut"], "state_local_step": local["name"],
                         "state_statement_sha256": state_task["statement_sha256"],
                         "witness_statement_sha256": witness_task["statement_sha256"]})

    source = {"schema": "rtl2lean-scale_evaluation-corpus-source-v1",
        "theorem_bases": source13["theorem_bases"], "selected": selected,
        "patterns": PATTERNS, "per_pattern": 5, "historical_task_ids": sorted(old_ids),
        "historical_statement_hashes": sorted(sha256_text(x) for x in old_statements),
        "boundary_evaluation_run": config["boundary_evaluation_run"],
        "boundary_evaluation_tasks_sha256": sha256_file(req14_path), "sets_disjoint": True,
        "selection_algorithm": "lexicographically-first-local-step-unused-by-Req13-and-Req14-per-DUT"}
    return tasks, source


def verify_tasks(project: Path, tasks: list[dict[str, Any]], source: dict[str, Any]) -> None:
    if len(tasks) != 10 or any(sum(t["property_pattern"] == p for t in tasks) != 5 for p in PATTERNS):
        raise RuntimeError("Req15 requires exactly five tasks per target pattern")
    if len({t["dut"] for t in tasks}) != 5 or len({t["task_id"] for t in tasks}) != 10:
        raise RuntimeError("Req15 multi-DUT/unseen corpus invariant failed")
    if {t["task_id"] for t in tasks} & set(source["historical_task_ids"]):
        raise RuntimeError("Req15 task ID leaks a historical task")
    if {t["statement_sha256"] for t in tasks} & set(source["historical_statement_hashes"]):
        raise RuntimeError("Req15 statement duplicates a historical Property")
    req14 = project / source["boundary_evaluation_run"] / "manifests" / "tasks.json"
    if sha256_file(req14) != source["boundary_evaluation_tasks_sha256"]:
        raise RuntimeError("frozen Req14 corpus changed")
    for task in tasks:
        if tree_digest(project / task["model_dir"]) != task["theorem_base_tree_sha256"]:
            raise RuntimeError(f"theorem base changed for {task['dut']}")
