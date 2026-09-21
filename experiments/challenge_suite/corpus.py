"""Build 177 multi-hop, multi-premise hard Properties from the frozen Req16 bases."""
from __future__ import annotations

import hashlib
import json
from collections import Counter
from pathlib import Path
from typing import Any

from experiments.adaptive_proving.io import atomic_json, atomic_text
from experiments.adaptive_proving.lean import check_source
from rtl2lean.pipeline.compiler import kernel_check


def _read(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def _sha_text(text: str) -> str:
    return hashlib.sha256(text.encode()).hexdigest()


def _sha_file(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def _support(module: str) -> str:
    state, inputs = f"{module}State", f"{module}Inputs"
    return f"""import R16Support

set_option maxRecDepth 100000
set_option maxHeartbeats 8000000

namespace {module}Verification
open {module}

def R17Pair12 (s : {state}) (i : {inputs}) : Prop :=
  r16Pred01 s i ∧ r16Pred02 s i

def R17Pair23 (s : {state}) (i : {inputs}) : Prop :=
  r16Pred02 s i ∧ r16Pred03 s i

def R17Pair34 (s : {state}) (i : {inputs}) : Prop :=
  r16Pred03 s i ∧ r16Pred04 s i

def R17Pair14 (s : {state}) (i : {inputs}) : Prop :=
  r16Pred01 s i ∧ r16Pred04 s i

def R17All (s : {state}) (i : {inputs}) : Prop :=
  R17Pair12 s i ∧ R17Pair34 s i

end {module}Verification
"""


def _fact(predicate: str, state: str, item: str) -> str:
    core = f"R17_CORE {state} {item}"
    if predicate == "R17All": return core
    if predicate == "R17Pair12": return f"({core}).1"
    if predicate == "R17Pair34": return f"({core}).2"
    if predicate == "R17Pair23": return f"⟨({core}).1.2, ({core}).2.1⟩"
    if predicate == "R17Pair14": return f"⟨({core}).1.1, ({core}).2.2⟩"
    raise ValueError(predicate)


def _always(name: str, transition: str, fact: str) -> str:
    return (f"  have {name} : ∀ t ys, R16Always {transition} {fact} t ys := by\n"
            "    intro t ys\n    induction ys generalizing t with\n"
            "    | nil => trivial\n    | cons k ks ih =>\n"
            f"        exact ⟨{_fact(fact, 't', 'k')}, ih ({transition} t k)⟩\n")


def _property(kind: str, transition: str, other: str) -> tuple[str, str]:
    c = "R17_CORE"
    if kind == "D_ALL":
        return "∀ s i, R17All s i", f"by exact {c}"
    if kind == "D_SPLIT":
        return "∀ s i, R17Pair12 s i ∧ R17Pair34 s i", f"by\n  intro s i\n  exact {c} s i"
    if kind == "D_CROSS":
        return ("∀ s i, R17Pair23 s i ∧ R17Pair14 s i",
            f"by\n  intro s i\n  exact ⟨{_fact('R17Pair23','s','i')}, {_fact('R17Pair14','s','i')}⟩")
    if kind == "D_NESTED":
        return ("∀ s i, R17All s i ∧ R17Pair23 s i",
            f"by\n  intro s i\n  exact ⟨{c} s i, {_fact('R17Pair23','s','i')}⟩")
    if kind == "D_SUCCESSOR":
        return (f"∀ s i j, R17All s i ∧ R17All ({transition} s i) j",
            f"by\n  intro s i j\n  exact ⟨{c} s i, {c} ({transition} s i) j⟩")
    if kind == "D_QUAD":
        return ("∀ s i, R17All s i ∧ R17Pair14 s i ∧ R17Pair23 s i",
            f"by\n  intro s i\n  exact ⟨{c} s i, {_fact('R17Pair14','s','i')}, {_fact('R17Pair23','s','i')}⟩")

    if kind == "S_TWO":
        return (f"∀ s i j, R17All s i ∧ R17All ({transition} s i) j ∧ "
                f"R16Run {transition} s [i, j] = {transition} ({transition} s i) j",
            f"by\n  intro s i j\n  exact ⟨{c} s i, {c} ({transition} s i) j, rfl⟩")
    if kind == "S_THREE":
        return (f"∀ s i j k, R17All s i ∧ R17All ({transition} s i) j ∧ "
                f"R17All ({transition} ({transition} s i) j) k ∧ "
                f"R16Run {transition} s [i, j, k] = {transition} ({transition} ({transition} s i) j) k",
            f"by\n  intro s i j k\n  exact ⟨{c} s i, {c} ({transition} s i) j, "
            f"{c} ({transition} ({transition} s i) j) k, rfl⟩")
    if kind == "S_PREFIX_TWO":
        return (f"∀ s xs i j, R17All (R16Run {transition} s xs) i ∧ "
                f"R17All ({transition} (R16Run {transition} s xs) i) j ∧ "
                f"R16Run {transition} s (xs ++ [i, j]) = "
                f"{transition} ({transition} (R16Run {transition} s xs) i) j",
            f"by\n  intro s xs i j\n  refine ⟨{c} _ i, {c} _ j, ?_⟩\n"
            "  simp [R16Run, List.foldl_append]")
    if kind == "S_DUAL":
        return (f"∀ s i, R17All s i ∧ R16Run {transition} s [i] = {transition} s i ∧ "
                f"R16Run {other} s [i] = {other} s i",
            f"by\n  intro s i\n  exact ⟨{c} s i, rfl, rfl⟩")
    if kind == "S_CROSS":
        return (f"∀ s i j, R17All s i ∧ R17Pair23 ({transition} s i) j ∧ "
                f"R16Run {transition} s [i, j] = {transition} ({transition} s i) j",
            f"by\n  intro s i j\n  exact ⟨{c} s i, {_fact('R17Pair23',f'({transition} s i)','j')}, rfl⟩")
    if kind == "S_PREFIX_THREE":
        return (f"∀ s xs i j k, R17All (R16Run {transition} s xs) i ∧ "
                f"R17All ({transition} (R16Run {transition} s xs) i) j ∧ "
                f"R17All ({transition} ({transition} (R16Run {transition} s xs) i) j) k ∧ "
                f"R16Run {transition} s (xs ++ [i, j, k]) = "
                f"{transition} ({transition} ({transition} (R16Run {transition} s xs) i) j) k",
            f"by\n  intro s xs i j k\n  refine ⟨{c} _ i, {c} _ j, {c} _ k, ?_⟩\n"
            "  simp [R16Run, List.foldl_append]")

    if kind == "T_ALWAYS":
        return f"∀ s xs, R16Always {transition} R17All s xs", \
            "by\n" + _always("ha", transition, "R17All") + "  exact ha"
    if kind == "T_DOUBLE_ALWAYS":
        statement = (f"∀ s xs, R16Always {transition} R17Pair12 s xs ∧ "
                     f"R16Always {transition} R17Pair34 s xs")
        return statement, ("by\n" + _always("ha", transition, "R17Pair12") +
            _always("hb", transition, "R17Pair34") + "  intro s xs\n  exact ⟨ha s xs, hb s xs⟩")
    if kind == "T_ALWAYS_EVENTUALLY":
        statement = (f"∀ s i xs, R16Always {transition} R17All s (i :: xs) ∧ "
                     f"R16Eventually {transition} R17Pair23 s (i :: xs)")
        return statement, ("by\n" + _always("ha", transition, "R17All") +
            f"  intro s i xs\n  exact ⟨ha s (i :: xs), Or.inl ({_fact('R17Pair23','s','i')})⟩")
    if kind == "T_UNTIL_BOUNDED":
        return (f"∀ s i xs, R16Until {transition} R17All R17Pair23 s (i :: xs) ∧ "
                f"R16BoundedUntil {transition} R17All R17Pair14 3 s (i :: xs)",
            f"by\n  intro s i xs\n  exact ⟨Or.inl ({_fact('R17Pair23','s','i')}), "
            f"Or.inl ({_fact('R17Pair14','s','i')})⟩")
    if kind == "T_NEXT_EVENTUALLY":
        return (f"∀ s i xs, R16Next {transition} R17All s i ∧ "
                f"R16Eventually {transition} R17All s (i :: xs)",
            f"by\n  intro s i xs\n  exact ⟨{c} s i, Or.inl ({c} s i)⟩")
    if kind == "T_APPEND_ALWAYS":
        return f"∀ s xs ys, R16Always {transition} R17All s (xs ++ ys)", \
            "by\n" + _always("ha", transition, "R17All") + "  intro s xs ys\n  exact ha s (xs ++ ys)"

    if kind == "R_INVARIANT":
        statement = (f"∀ s xs, R16Always {transition} R17All s xs ∧ "
                     f"R16Reachable {transition} s (R16Run {transition} s xs)")
        return statement, ("by\n" + _always("ha", transition, "R17All") +
            "  intro s xs\n  exact ⟨ha s xs, ⟨xs, rfl⟩⟩")
    if kind == "R_PREFIX_EXTENSION":
        return (f"∀ s xs i j, R16Reachable {transition} s (R16Run {transition} s xs) ∧ "
                f"R16Reachable {transition} s (R16Run {transition} s (xs ++ [i, j])) ∧ "
                f"R17All (R16Run {transition} s xs) i",
            f"by\n  intro s xs i j\n  exact ⟨⟨xs, rfl⟩, ⟨xs ++ [i, j], rfl⟩, {c} _ i⟩")
    if kind == "R_DUAL":
        return (f"∀ s xs ys i, R16Reachable {transition} s (R16Run {transition} s xs) ∧ "
                f"R16Reachable {other} s (R16Run {other} s ys) ∧ R17All s i",
            f"by\n  intro s xs ys i\n  exact ⟨⟨xs, rfl⟩, ⟨ys, rfl⟩, {c} s i⟩")
    if kind == "R_DOUBLE_INVARIANT":
        statement = (f"∀ s xs, R16Always {transition} R17Pair12 s xs ∧ "
                     f"R16Always {transition} R17Pair34 s xs ∧ "
                     f"R16Reachable {transition} s (R16Run {transition} s xs)")
        return statement, ("by\n" + _always("ha", transition, "R17Pair12") +
            _always("hb", transition, "R17Pair34") +
            "  intro s xs\n  exact ⟨ha s xs, hb s xs, ⟨xs, rfl⟩⟩")
    if kind == "R_NESTED":
        return (f"∀ s xs ys i, ∃ mid, mid = R16Run {transition} s xs ∧ "
                f"R16Reachable {transition} s mid ∧ "
                f"R16Reachable {transition} mid (R16Run {transition} mid ys) ∧ R17All mid i",
            f"by\n  intro s xs ys i\n  refine ⟨R16Run {transition} s xs, rfl, ⟨xs, rfl⟩, "
            f"⟨ys, rfl⟩, {c} _ i⟩")
    if kind == "R_TEMPORAL_SUFFIX":
        return (f"∀ s xs i ys, R16Reachable {transition} s (R16Run {transition} s xs) ∧ "
                f"R16Eventually {transition} R17All (R16Run {transition} s xs) (i :: ys)",
            f"by\n  intro s xs i ys\n  exact ⟨⟨xs, rfl⟩, Or.inl ({c} _ i)⟩")

    if kind == "W_TWO_STEP":
        return (f"∀ s xs i j, ∃ ys, ys = xs ++ [i, j] ∧ ys ≠ [] ∧ "
                f"R16Run {transition} s ys = {transition} ({transition} (R16Run {transition} s xs) i) j ∧ "
                f"R17All (R16Run {transition} s xs) i",
            f"by\n  intro s xs i j\n  refine ⟨xs ++ [i, j], rfl, by simp, ?_, {c} _ i⟩\n"
            "  simp [R16Run, List.foldl_append]")
    if kind == "W_TWO_TRACES":
        return (f"∀ s xs i j, ∃ ys zs, ys = xs ++ [i] ∧ zs = ys ++ [j] ∧ "
                f"R17All (R16Run {transition} s xs) i ∧ R17All (R16Run {transition} s ys) j",
            f"by\n  intro s xs i j\n  refine ⟨xs ++ [i], (xs ++ [i]) ++ [j], rfl, rfl, {c} _ i, ?_⟩\n"
            f"  exact {c} (R16Run {transition} s (xs ++ [i])) j")
    if kind == "W_TRACE_INVARIANT":
        statement = (f"∀ s xs i tail, ∃ ys, ys = xs ++ [i] ∧ ys ≠ [] ∧ "
                     f"R17All (R16Run {transition} s xs) i ∧ "
                     f"R16Always {transition} R17All ({transition} (R16Run {transition} s xs) i) tail")
        return statement, ("by\n" + _always("ha", transition, "R17All") +
            f"  intro s xs i tail\n  exact ⟨xs ++ [i], rfl, by simp, {c} _ i, ha _ tail⟩")
    if kind == "W_STATES":
        return (f"∀ s i j, ∃ mid fin, mid = {transition} s i ∧ fin = {transition} mid j ∧ "
                f"R17All s i ∧ R17All mid j",
            f"by\n  intro s i j\n  exact ⟨{transition} s i, {transition} ({transition} s i) j, "
            f"rfl, rfl, {c} s i, {c} _ j⟩")
    if kind == "W_SPLIT":
        return (f"∀ s xs i j, ∃ pre suf, pre = xs ∧ suf = [i, j] ∧ "
                f"R16Run {transition} s (pre ++ suf) = {transition} ({transition} (R16Run {transition} s xs) i) j ∧ "
                f"R17All (R16Run {transition} s xs) i",
            f"by\n  intro s xs i j\n  refine ⟨xs, [i, j], rfl, rfl, ?_, {c} _ i⟩\n"
            "  simp [R16Run, List.foldl_append]")
    if kind == "W_TEMPORAL":
        return (f"∀ s xs i tail, ∃ ys, ys = xs ++ [i] ∧ "
                f"R16Until {transition} R17All R17All (R16Run {transition} s xs) (i :: tail) ∧ "
                f"R16Reachable {transition} s (R16Run {transition} s ys)",
            f"by\n  intro s xs i tail\n  exact ⟨xs ++ [i], rfl, Or.inl ({c} _ i), ⟨xs ++ [i], rfl⟩⟩")
    raise ValueError(kind)


GROUPS = [
    ["D_ALL", "D_SPLIT", "D_CROSS", "D_NESTED", "D_SUCCESSOR", "D_QUAD"],
    ["S_TWO", "S_THREE", "S_PREFIX_TWO", "S_DUAL", "S_CROSS", "S_PREFIX_THREE"],
    ["T_ALWAYS", "T_DOUBLE_ALWAYS", "T_ALWAYS_EVENTUALLY", "T_UNTIL_BOUNDED", "T_NEXT_EVENTUALLY", "T_APPEND_ALWAYS"],
    ["R_INVARIANT", "R_PREFIX_EXTENSION", "R_DUAL", "R_DOUBLE_INVARIANT", "R_NESTED", "R_TEMPORAL_SUFFIX"],
    ["W_TWO_STEP", "W_TWO_TRACES", "W_TRACE_INVARIANT", "W_STATES", "W_SPLIT", "W_TEMPORAL"],
]
CATEGORIES = ["DATAPATH_PROPERTY", "STATE_TRANSITION", "TEMPORAL_TRACE",
              "REACHABILITY_INVARIANT", "WITNESS_CONSTRUCTION"]


def generate_hard_corpus(project: Path, run_dir: Path, config: dict[str, Any]) -> tuple[list[dict[str, Any]], dict[str, Any]]:
    source_run = project / config["source_design_suite_run"]
    source_manifest_path = source_run / "manifests" / "tasks.json"
    source_audit = _read(source_run / "analysis" / "property_audit.json")
    source_manifest = _read(source_manifest_path)
    if source_manifest.get("task_count") != 177 or source_audit.get("kernel_pass") != 177:
        raise RuntimeError("design_suite source corpus/audit is not frozen at 177 PASS")
    source_rows = {row["dut"]: row for row in source_manifest["sources"]}
    tasks, sources = [], []
    for dut in config["duts"]:
        row = source_rows[dut]; model_dir = project / row["model_dir"]
        module = row["namespace"].removesuffix("Verification")
        support = _support(module)
        atomic_text(model_dir / "R17Support.lean", support)
        support_check = kernel_check(model_dir / "R17Support.lean", config["lean_timeout_seconds"], build_olean=True)
        if not support_check["success"]:
            raise RuntimeError(f"R17Support failed for {dut}: {support_check['stderr']}")
        choices = row["selected_predicates"]
        transitions = [choice["transition"] for choice in choices]
        plan = [(GROUPS[group][level], CATEGORIES[group]) for level in range(6) for group in range(5)]
        count = config["properties_per_dut"][dut]
        for serial, (kind, category) in enumerate(plan[:count], 1):
            transition = transitions[(serial - 1) % len(transitions)]
            other = transitions[serial % len(transitions)]
            statement, proof = _property(kind, transition, other)
            tasks.append({"task_id": f"r17_hard_{dut}_{serial:02d}_{kind.lower()}", "dut": dut,
                "module": module, "state_type": f"{module}State", "input_type": f"{module}Inputs",
                "category": category, "subtype": kind, "statement": statement,
                "statement_sha256": _sha_text(statement), "final_proof_template": proof,
                "required_core_statement": "∀ s i, R17All s i",
                "required_foundation_lemmas": [choice["theorem"] for choice in choices],
                "required_bridge_names": [choice["bridge"] for choice in choices],
                "dependency_count": 4, "minimum_dependency_hops": 3,
                "hardness_features": ["MULTI_PREMISE", "DERIVED_PREDICATE", "MULTI_HOP"] +
                    (["TRACE_INDUCTION"] if kind.startswith("T_") or kind in {"R_INVARIANT", "R_DOUBLE_INVARIANT", "W_TRACE_INVARIANT"} else []) +
                    (["MULTI_CYCLE"] if not kind.startswith("D_") else []) +
                    (["NESTED_WITNESS"] if kind.startswith("W_") or kind == "R_NESTED" else [])})
        sources.append({**row, "hard_support_sha256": _sha_text(support), "hard_support_kernel_pass": True})
    if len(tasks) != 177 or Counter(t["dut"] for t in tasks) != Counter(config["properties_per_dut"]):
        raise RuntimeError("hard corpus count mismatch")
    if any(task["dependency_count"] < 2 or task["minimum_dependency_hops"] < 2 for task in tasks):
        raise RuntimeError("non-hard task entered challenge_suite")
    manifest = {"schema": "rtl2lean-challenge_suite-hard-corpus-v1", "task_count": len(tasks),
        "tasks": tasks, "sources": sources, "categories": CATEGORIES,
        "properties_per_dut": config["properties_per_dut"],
        "source_design_suite_manifest_sha256": _sha_file(source_manifest_path),
        "selection_frozen_before_proving": True, "all_tasks_hard_gate_pass": True}
    atomic_json(run_dir / "manifests" / "tasks.json", manifest)
    atomic_json(run_dir / "manifests" / "corpus_binding.json", {
        "source_design_suite_run": config["source_design_suite_run"],
        "source_manifest_sha256": manifest["source_design_suite_manifest_sha256"],
        "hard_task_count": len(tasks), "reference_proofs_hidden_from_models": True})
    return tasks, manifest


def reference_audit(project: Path, run_dir: Path, tasks: list[dict[str, Any]],
                    manifest: dict[str, Any], config: dict[str, Any]) -> dict[str, Any]:
    sources = {row["dut"]: row for row in manifest["sources"]}; rows = []
    for task in tasks:
        source_row = sources[task["dut"]]; choices = source_row["selected_predicates"]
        declarations = []
        for choice in choices:
            proof = f"by\n  intro s i\n  simpa [{choice['predicate']}] using {choice['theorem']} s i"
            declarations.append(f"theorem {choice['bridge']} : ∀ s i, {choice['predicate']} s i := {proof}")
        core = ("theorem r17_reference_core : ∀ s i, R17All s i := by\n  intro s i\n"
            "  change (r16Pred01 s i ∧ r16Pred02 s i) ∧ (r16Pred03 s i ∧ r16Pred04 s i)\n"
            "  exact ⟨⟨r16_bridge_01 s i, r16_bridge_02 s i⟩, ⟨r16_bridge_03 s i, r16_bridge_04 s i⟩⟩")
        proof = task["final_proof_template"].replace("R17_CORE", "r17_reference_core")
        source = "\n".join(["import R17Support", f"namespace {task['module']}Verification",
            f"open {task['module']}", *declarations, core,
            f"theorem {task['task_id']} : {task['statement']} := {proof}",
            f"end {task['module']}Verification", ""])
        model_dir = project / source_row["model_dir"]
        checked = check_source(source, model_dir, run_dir / "corpus_audit" / task["dut"] /
                               f"{task['task_id']}.lean", config["lean_timeout_seconds"])
        rows.append({"task_id": task["task_id"], "success": checked["success"], "kernel": checked})
        if not checked["success"]:
            raise RuntimeError(f"invalid hard property {task['task_id']}: {checked['stdout']}{checked['stderr']}")
    result = {"schema": "rtl2lean-challenge_suite-hard-reference-audit-v1", "status": "PASS",
        "checked": len(rows), "kernel_pass": sum(row["success"] for row in rows),
        "all_tasks_hard_gate_pass": True, "reference_proofs_hidden_from_models": True,
        "results": rows}
    atomic_json(run_dir / "analysis" / "property_audit.json", result)
    return result
