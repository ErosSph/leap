"""Generate kernel-audited categorized Properties from each DUT theorem base."""
from __future__ import annotations

import hashlib
import json
import re
from pathlib import Path
from typing import Any

from experiments.adaptive_proving.io import atomic_json, atomic_text
from experiments.adaptive_proving.lean import check_source
from rtl2lean.pipeline.compiler import kernel_check
from .config import CATEGORIES, TEMPORAL_KINDS


UNIVERSAL = re.compile(
    r"∀\s*\(s\s*:\s*([^()]+)\)\s*\(i\s*:\s*([^()]+)\),\s*(.*)", re.S
)


def _read(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def _sha(text: str) -> str:
    return hashlib.sha256(text.encode()).hexdigest()


def model_dirs(project: Path, config: dict[str, Any]) -> dict[str, Path]:
    result = {dut: project / "outputs" / dut / "model" for dut in config["duts"][:5]}
    for dut in config["duts"][5:]:
        result[dut] = project / config["adaptation_root"] / dut / "model"
    return result


def _support(module: str, state: str, inputs: str, predicates: list[dict[str, Any]]) -> str:
    rows = ["import Framework", "", "set_option maxRecDepth 100000",
        "set_option maxHeartbeats 8000000", "", f"namespace {module}Verification",
        f"open {module}", "",
        f"def R16Run (trans : {state} → {inputs} → {state}) (s : {state}) "
        f"(xs : List {inputs}) : {state} := xs.foldl trans s", "",
        f"def R16Always (trans : {state} → {inputs} → {state}) "
        f"(P : {state} → {inputs} → Prop) : {state} → List {inputs} → Prop",
        "  | _, [] => True", "  | s, i :: xs => P s i ∧ R16Always trans P (trans s i) xs", "",
        f"def R16Eventually (trans : {state} → {inputs} → {state}) "
        f"(P : {state} → {inputs} → Prop) : {state} → List {inputs} → Prop",
        "  | _, [] => False", "  | s, i :: xs => P s i ∨ R16Eventually trans P (trans s i) xs", "",
        f"def R16Until (trans : {state} → {inputs} → {state}) "
        f"(P Q : {state} → {inputs} → Prop) : {state} → List {inputs} → Prop",
        "  | _, [] => False", "  | s, i :: xs => Q s i ∨ (P s i ∧ R16Until trans P Q (trans s i) xs)", "",
        f"def R16BoundedUntil (trans : {state} → {inputs} → {state}) "
        f"(P Q : {state} → {inputs} → Prop) : Nat → {state} → List {inputs} → Prop",
        "  | 0, _, _ => False", "  | _ + 1, _, [] => False",
        "  | n + 1, s, i :: xs => Q s i ∨ (P s i ∧ R16BoundedUntil trans P Q n (trans s i) xs)", "",
        f"def R16Next (trans : {state} → {inputs} → {state}) "
        f"(P : {state} → {inputs} → Prop) (s : {state}) (i : {inputs}) : Prop := P s i", "",
        f"def R16Reachable (trans : {state} → {inputs} → {state}) "
        f"(s t : {state}) : Prop := ∃ xs, R16Run trans s xs = t", ""]
    for pred in predicates:
        rows.extend([f"def {pred['predicate']} (s : {state}) (i : {inputs}) : Prop :=",
                     f"  {pred['body']}", ""])
    rows.extend([f"end {module}Verification", ""])
    return "\n".join(rows)


def _always_proof(bridge: str, trans: str) -> str:
    return ("by\n  intro s xs\n  induction xs generalizing s with\n"
            "  | nil => trivial\n  | cons i xs ih =>\n"
            f"      exact ⟨{bridge} s i, ih ({trans} s i)⟩")


def _task(dut: str, module: str, state: str, inputs: str, pred: dict[str, Any],
          serial: int, category: str, subtype: str,
          secondary: dict[str, Any] | None = None) -> dict[str, Any]:
    p, trans, bridge = pred["predicate"], pred["transition"], pred["bridge"]
    if subtype == "DATAPATH":
        statement, proof = f"∀ s i, {p} s i", f"by exact {bridge}"
    elif subtype == "STATE_TRANSITION":
        statement = f"∀ s i, {p} s i ∧ R16Run {trans} s [i] = {trans} s i"
        proof = f"by\n  intro s i\n  exact ⟨{bridge} s i, rfl⟩"
    elif subtype == "ALWAYS":
        statement = f"∀ s xs, R16Always {trans} {p} s xs"
        proof = _always_proof(bridge, trans)
    elif subtype == "INVARIANT":
        statement = (f"∀ s xs, R16Always {trans} {p} s xs ∧ "
                     f"R16Reachable {trans} s (R16Run {trans} s xs)")
        proof = ("by\n  intro s xs\n  constructor\n"
                 "  · induction xs generalizing s with\n"
                 "    | nil => trivial\n"
                 "    | cons i xs ih =>\n"
                 f"        exact ⟨{bridge} s i, ih ({trans} s i)⟩\n"
                 "  · exact ⟨xs, rfl⟩")
    elif subtype == "NEXT":
        statement = f"∀ s i, R16Next {trans} {p} s i"
        proof = f"by\n  intro s i\n  exact {bridge} s i"
    elif subtype == "EVENTUALLY":
        statement = f"∀ s i xs, R16Eventually {trans} {p} s (i :: xs)"
        proof = f"by\n  intro s i xs\n  exact Or.inl ({bridge} s i)"
    elif subtype == "UNTIL":
        statement = f"∀ s i xs, R16Until {trans} {p} {p} s (i :: xs)"
        proof = f"by\n  intro s i xs\n  exact Or.inl ({bridge} s i)"
    elif subtype == "BOUNDED_UNTIL":
        statement = f"∀ s i xs, R16BoundedUntil {trans} {p} {p} 1 s (i :: xs)"
        proof = f"by\n  intro s i xs\n  exact Or.inl ({bridge} s i)"
    elif subtype == "REACHABILITY":
        statement = (f"∀ s xs i, R16Reachable {trans} s (R16Run {trans} s xs) ∧ "
                     f"{p} (R16Run {trans} s xs) i")
        proof = (f"by\n  intro s xs i\n  constructor\n  · exact ⟨xs, rfl⟩\n"
                 f"  · exact {bridge} (R16Run {trans} s xs) i")
    elif subtype == "WITNESS":
        statement = (f"∀ s xs i, ∃ ys, ys = xs ++ [i] ∧ "
                     f"R16Run {trans} s ys = {trans} (R16Run {trans} s xs) i ∧ "
                     f"{p} (R16Run {trans} s xs) i")
        proof = (f"by\n  intro s xs i\n  refine ⟨xs ++ [i], rfl, ?_, "
                 f"{bridge} (R16Run {trans} s xs) i⟩\n"
                 "  simp [R16Run, List.foldl_append]")
    elif subtype == "DATAPATH_PAIR":
        assert secondary is not None
        q, other = secondary["predicate"], secondary["bridge"]
        statement = f"∀ s i, {p} s i ∧ {q} s i"
        proof = f"by\n  intro s i\n  exact ⟨{bridge} s i, {other} s i⟩"
    elif subtype == "STATE_TRACE_TWO":
        statement = (f"∀ s i j, {p} s i ∧ {p} ({trans} s i) j ∧ "
                     f"R16Run {trans} s [i, j] = {trans} ({trans} s i) j")
        proof = (f"by\n  intro s i j\n  exact ⟨{bridge} s i, "
                 f"{bridge} ({trans} s i) j, rfl⟩")
    elif subtype == "ALWAYS_EVENTUALLY":
        statement = (f"∀ s i xs, R16Always {trans} {p} s (i :: xs) ∧ "
                     f"R16Eventually {trans} {p} s (i :: xs)")
        proof = ("by\n  intro s i xs\n"
                 f"  have hall : ∀ t ys, R16Always {trans} {p} t ys := by\n"
                 "    intro t ys\n    induction ys generalizing t with\n"
                 "    | nil => trivial\n    | cons j ys ih =>\n"
                 f"        exact ⟨{bridge} t j, ih ({trans} t j)⟩\n"
                 f"  exact ⟨hall s (i :: xs), Or.inl ({bridge} s i)⟩")
    elif subtype == "REACHABLE_WITNESS":
        statement = (f"∀ s xs i, R16Reachable {trans} s (R16Run {trans} s xs) ∧ "
                     f"∃ ys, ys = xs ++ [i] ∧ {p} (R16Run {trans} s xs) i")
        proof = (f"by\n  intro s xs i\n  constructor\n  · exact ⟨xs, rfl⟩\n"
                 f"  · exact ⟨xs ++ [i], rfl, {bridge} (R16Run {trans} s xs) i⟩")
    elif subtype == "TEMPORAL_COMBINED":
        statement = (f"∀ s i xs, R16Until {trans} {p} {p} s (i :: xs) ∧ "
                     f"R16BoundedUntil {trans} {p} {p} 1 s (i :: xs)")
        proof = (f"by\n  intro s i xs\n  exact ⟨Or.inl ({bridge} s i), "
                 f"Or.inl ({bridge} s i)⟩")
    elif subtype == "WITNESS_NONEMPTY":
        statement = (f"∀ s xs i, ∃ ys, ys = xs ++ [i] ∧ ys ≠ [] ∧ "
                     f"{p} (R16Run {trans} s xs) i")
        proof = (f"by\n  intro s xs i\n  refine ⟨xs ++ [i], rfl, by simp, "
                 f"{bridge} (R16Run {trans} s xs) i⟩")
    else:
        raise ValueError(subtype)
    task_id = f"r16_{dut}_{serial:02d}_{subtype.lower()}"
    return {"task_id": task_id, "dut": dut, "module": module,
        "state_type": state, "input_type": inputs, "category": category,
        "subtype": subtype, "statement": statement, "statement_sha256": _sha(statement),
        "predicate": p, "transition": trans, "bridge_name": bridge,
        "bridge_statement": f"∀ s i, {p} s i", "foundation_theorem": pred["theorem"],
        "foundation_statement": pred["statement"], "final_proof": proof,
        "additional_bridge_names": [secondary["bridge"]] if secondary else []}


def generate_corpus(project: Path, root: Path, config: dict[str, Any]) -> tuple[list[dict[str, Any]], dict[str, Any]]:
    tasks: list[dict[str, Any]] = []
    sources: list[dict[str, Any]] = []
    for dut, model_dir in model_dirs(project, config).items():
        targets_path = model_dir / "targets.json"
        framework = model_dir / "Framework.olean"
        if not targets_path.is_file() or not framework.is_file():
            raise FileNotFoundError(f"adaptation/theorem base incomplete for {dut}: {model_dir}")
        payload = _read(targets_path)
        module = payload["namespace"].removesuffix("Verification")
        choices = []
        for target in payload["targets"]:
            match = UNIVERSAL.fullmatch(target["statement"].strip())
            funcs = target.get("source_functions") or []
            if target.get("layer") not in {"L1", "L2"} or not match or not funcs:
                continue
            state, inputs, body = (x.strip() for x in match.groups())
            if state != f"{module}State" or inputs != f"{module}Inputs":
                continue
            index = len(choices) + 1
            choices.append({"predicate": f"r16Pred{index:02d}",
                "bridge": f"r16_bridge_{index:02d}", "transition": funcs[0],
                "theorem": target["name"], "statement": target["statement"], "body": body})
            if len(choices) == 4:
                break
        if len(choices) != 4:
            raise RuntimeError(f"{dut} has fewer than four typed datapath transition theorems")
        support = _support(module, f"{module}State", f"{module}Inputs", choices)
        atomic_text(model_dir / "R16Support.lean", support)
        support_check = kernel_check(model_dir / "R16Support.lean",
                                     config["lean_timeout_seconds"], build_olean=True)
        atomic_json(model_dir / "r16_support_check.json", support_check)
        if not support_check["success"]:
            raise RuntimeError(f"R16Support rejected for {dut}: {support_check['stderr']}")

        plan = []
        plan += [(p, "DATAPATH_PROPERTY", "DATAPATH") for p in choices]
        plan += [(p, "STATE_TRANSITION", "STATE_TRANSITION") for p in choices]
        plan += [(choices[0], "TEMPORAL_TRACE", "ALWAYS"), (choices[1], "TEMPORAL_TRACE", "ALWAYS"),
                 (choices[2], "TEMPORAL_TRACE", "NEXT"), (choices[3], "TEMPORAL_TRACE", "NEXT"),
                 (choices[0], "TEMPORAL_TRACE", "EVENTUALLY"),
                 (choices[1], "TEMPORAL_TRACE", "UNTIL"),
                 (choices[2], "TEMPORAL_TRACE", "BOUNDED_UNTIL"),
                 (choices[3], "TEMPORAL_TRACE", "BOUNDED_UNTIL")]
        plan += [(choices[0], "REACHABILITY_INVARIANT", "REACHABILITY"),
                 (choices[1], "REACHABILITY_INVARIANT", "INVARIANT"),
                 (choices[2], "REACHABILITY_INVARIANT", "INVARIANT")]
        plan += [(choices[0], "WITNESS_CONSTRUCTION", "WITNESS"),
                 (choices[1], "WITNESS_CONSTRUCTION", "WITNESS"),
                 (choices[3], "WITNESS_CONSTRUCTION", "WITNESS")]
        plan += [
            (choices[0], "DATAPATH_PROPERTY", "DATAPATH_PAIR", choices[1]),
            (choices[1], "STATE_TRANSITION", "STATE_TRACE_TWO", None),
            (choices[2], "TEMPORAL_TRACE", "ALWAYS_EVENTUALLY", None),
            (choices[3], "REACHABILITY_INVARIANT", "REACHABLE_WITNESS", None),
            (choices[2], "DATAPATH_PROPERTY", "DATAPATH_PAIR", choices[3]),
            (choices[0], "STATE_TRANSITION", "STATE_TRACE_TWO", None),
            (choices[1], "TEMPORAL_TRACE", "TEMPORAL_COMBINED", None),
            (choices[2], "WITNESS_CONSTRUCTION", "WITNESS_NONEMPTY", None),
        ]
        count = config["properties_per_dut"][dut]
        normalized_plan = [(p, c, s, None) for p, c, s in plan[:22]] + plan[22:]
        selected_plan = normalized_plan[:count]
        dut_tasks = [_task(dut, module, f"{module}State", f"{module}Inputs", p, n, c, s, extra)
                     for n, (p, c, s, extra) in enumerate(selected_plan, 1)]
        if len(dut_tasks) != count:
            raise RuntimeError("property plan/config count mismatch")
        tasks.extend(dut_tasks)
        sources.append({"dut": dut, "model_dir": str(model_dir.relative_to(project)),
            "namespace": payload["namespace"], "selected_predicates": choices,
            "targets_sha256": _sha(targets_path.read_text(encoding="utf-8")),
            "support_sha256": _sha(support), "support_kernel_pass": True})
    manifest = {"schema": "rtl2lean-design_suite-corpus-v1", "tasks": tasks,
        "sources": sources, "categories": CATEGORIES, "temporal_kinds": TEMPORAL_KINDS,
        "task_count": len(tasks), "properties_per_dut": config["properties_per_dut"]}
    atomic_json(root / "manifests" / "tasks.json", manifest)
    return tasks, manifest


def reference_audit(project: Path, root: Path, tasks: list[dict[str, Any]],
                    manifest: dict[str, Any], config: dict[str, Any]) -> dict[str, Any]:
    rows = []
    by_dut = {row["dut"]: row for row in manifest["sources"]}
    for task in tasks:
        model_dir = project / by_dut[task["dut"]]["model_dir"]
        bridge_proof = (f"by\n  intro s i\n  simpa [{task['predicate']}] using "
                        f"{task['foundation_theorem']} s i")
        extra_bridges = []
        selected = by_dut[task["dut"]]["selected_predicates"]
        for name in task.get("additional_bridge_names", []):
            predicate = next(row for row in selected if row["bridge"] == name)
            extra_proof = (f"by\n  intro s i\n  simpa [{predicate['predicate']}] using "
                           f"{predicate['theorem']} s i")
            extra_bridges.append(
                f"theorem {name} : ∀ s i, {predicate['predicate']} s i := {extra_proof}")
        source = "\n".join(["import R16Support", f"namespace {task['module']}Verification",
            f"open {task['module']}", f"theorem {task['bridge_name']} : {task['bridge_statement']} := {bridge_proof}",
            *extra_bridges,
            f"theorem {task['task_id']} : {task['statement']} := {task['final_proof']}",
            f"end {task['module']}Verification", ""])
        checked = check_source(source, model_dir, root / "corpus_audit" / task["dut"] /
                               f"{task['task_id']}.lean", config["lean_timeout_seconds"])
        rows.append({"task_id": task["task_id"], "success": checked["success"],
                     "lean_result": checked})
        if not checked["success"]:
            raise RuntimeError(f"invalid generated property {task['task_id']}: {checked['stderr']}")
    result = {"schema": "rtl2lean-design_suite-property-audit-v1", "status": "PASS",
        "checked": len(rows), "kernel_pass": sum(r["success"] for r in rows), "results": rows,
        "reference_proofs_hidden_from_model": True}
    atomic_json(root / "analysis" / "property_audit.json", result)
    return result
