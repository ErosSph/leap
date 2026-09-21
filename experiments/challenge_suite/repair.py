"""Auditable post-hoc repair and lemma-reuse accounting for challenge_suite.

The repair is deliberately a generic TPOH edge executor: it consumes the four
predicate/foundation bindings from the manifest and never branches on a DUT,
module, signal, or theorem name.
"""
from __future__ import annotations

import argparse
import json
from collections import defaultdict
from pathlib import Path
from typing import Any

from experiments.adaptive_proving.io import atomic_json
from experiments.adaptive_proving.lean import check_source
from .ablation import _core_source, _target_source
from .config import load_config


def structural_core_proof(choices: list[dict[str, Any]]) -> str:
    """Compile THEOREM_APPLICATION/CONJUNCTION TPOH edges to a Lean proof."""
    if len(choices) != 4:
        raise ValueError("R17 aggregate core requires exactly four typed bindings")
    leaves = [
        f"by simpa [{choice['predicate']}] using {choice['theorem']} s i"
        for choice in choices
    ]
    return "\n".join([
        "by", "  intro s i", "  simp only [R17All, R17Pair12, R17Pair34]",
        "  exact ⟨", f"    ⟨{leaves[0]}, {leaves[1]}⟩,",
        f"    ⟨{leaves[2]}, {leaves[3]}⟩", "  ⟩",
    ])


def _deletion_source(task: dict[str, Any], core_name: str) -> str:
    proof = task["final_proof_template"].replace("R17_CORE", core_name)
    return "\n".join([
        "import R17Support", f"namespace {task['module']}Verification",
        f"open {task['module']}",
        f"theorem {task['task_id']}__delete_repaired_core : {task['statement']} := {proof}",
        f"end {task['module']}Verification", "",
    ])


def _reuse_funnel(tasks: list[dict[str, Any]], graph: dict[str, Any],
                  causal: dict[str, Any], repaired: dict[str, Any] | None = None) -> dict[str, Any]:
    task_count = len(tasks)
    by_dut_total: dict[str, int] = defaultdict(int)
    by_dut_used_before: dict[str, int] = defaultdict(int)
    for task in tasks:
        by_dut_total[task["dut"]] += 1
    for row in graph["rows"]:
        if row["full_graph"]["success"] and row["full_graph"]["core_reused"]:
            by_dut_used_before[row["dut"]] += 1
    causal_before = sum(bool(row["causally_required"]) for row in causal["rows"])
    repaired_duts = {
        row["dut"] for row in (repaired or {}).get("dut_repairs", []) if row["core_kernel_pass"]
    }
    before_fanout = {dut: by_dut_used_before.get(dut, 0) for dut in sorted(by_dut_total)}
    after_fanout = {
        dut: (by_dut_total[dut] if dut in repaired_duts else by_dut_used_before.get(dut, 0))
        for dut in sorted(by_dut_total)
    }

    def stage(fanout: dict[str, int], causal_events: int) -> dict[str, Any]:
        available = sum(count > 0 for count in fanout.values())
        used = sum(fanout.values())
        return {
            "available_unique_kernel_verified_lemmas": available,
            "retrieved_events": used,
            "actually_used_kernel_success_events": used,
            "causally_required_events": causal_events,
            "property_coverage": {"numerator": used, "denominator": task_count,
                                  "rate": used / task_count if task_count else 0.0},
            "repeated_cross_target_uses_excluding_first_consumer":
                sum(max(0, count - 1) for count in fanout.values()),
            "average_successful_consumers_per_available_lemma":
                used / available if available else 0.0,
            "fanout_by_dut": fanout,
        }

    repaired_causal = sum(row.get("causally_required_targets", 0)
                          for row in (repaired or {}).get("dut_repairs", []))
    return {
        "schema": "rtl2lean-challenge_suite-lemma-reuse-funnel-v1",
        "unit_of_available": "unique DUT-level aggregate core lemma",
        "unit_of_events": "target proof consuming that core lemma",
        "strict_cross_property_note": (
            "The core is generated before target Properties, so this is shared cross-target reuse; "
            "it is not a lemma mined from one earlier Property proof."),
        "before_repair": stage(before_fanout, causal_before),
        "after_posthoc_repair": stage(after_fanout, causal_before + repaired_causal),
    }


def run(project: Path, run_dir: Path) -> dict[str, Any]:
    config = load_config(run_dir / "manifests/config.yaml")
    manifest = json.loads((run_dir / "manifests/tasks.json").read_text(encoding="utf-8"))
    tasks = manifest["tasks"]
    sources = {row["dut"]: row for row in manifest["sources"]}
    graph = json.loads((run_dir / "ablation/graph_ablation.json").read_text(encoding="utf-8"))
    causal = json.loads((run_dir / "ablation/causal_deletion.json").read_text(encoding="utf-8"))
    failed_duts = sorted({row["dut"] for row in graph["rows"]
                          if not row["full_graph"]["success"]})
    repairs = []
    for dut in failed_duts:
        source = sources[dut]
        model_dir = project / source["model_dir"]
        dut_tasks = [task for task in tasks if task["dut"] == dut]
        proof = structural_core_proof(source["selected_predicates"])
        core_name = "r17_full_graph_repaired_core"
        core_kernel = check_source(
            _core_source({**dut_tasks[0], "model_dir": source["model_dir"]}, core_name, proof),
            model_dir, run_dir / "posthoc_repair/core" / dut / "core.lean",
            config["lean_timeout_seconds"],
        )
        target_rows = []
        causal_required = 0
        if core_kernel["success"]:
            for task in dut_tasks:
                target = check_source(
                    _target_source(task, core_name, proof), model_dir,
                    run_dir / "posthoc_repair/targets" / dut / f"{task['task_id']}.lean",
                    config["lean_timeout_seconds"],
                )
                deletion = check_source(
                    _deletion_source(task, core_name), model_dir,
                    run_dir / "posthoc_repair/causal_deletion" / dut /
                    f"{task['task_id']}.lean", config["lean_timeout_seconds"],
                )
                required = target["success"] and not deletion["success"]
                causal_required += int(required)
                target_rows.append({"task_id": task["task_id"], "kernel_pass": target["success"],
                                    "causally_required": required,
                                    "target_kernel": target, "deletion_kernel": deletion})
        repairs.append({
            "dut": dut, "repair_kind": "GENERIC_TPOH_STRUCTURAL_EDGE_EXECUTION",
            "post_hoc": True, "llm_calls": 0, "core_proof": proof,
            "core_kernel_pass": core_kernel["success"], "core_kernel": core_kernel,
            "target_total": len(dut_tasks),
            "target_kernel_pass": sum(row["kernel_pass"] for row in target_rows),
            "causally_required_targets": causal_required, "targets": target_rows,
        })
    repaired_successes = sum(row["target_kernel_pass"] for row in repairs)
    result = {
        "schema": "rtl2lean-challenge_suite-posthoc-tpoh-repair-v1",
        "post_hoc": True,
        "claim_policy": "diagnostic upper bound; not a replacement for the frozen pre-repair result",
        "observed_failure": "predicate propositions were supplied where proof terms were required",
        "generic_change": [
            "bind each FACT node to its foundation theorem identifier and predicate definition",
            "execute definitional bridge and conjunction hyperedges deterministically",
            "kernel-gate the repaired core before adding it to the pool",
            "reserve LLM repair for graph edges without a trusted structural rule",
        ],
        "failed_duts_before": failed_duts,
        "before": {"core_successes": graph["full_graph"]["core_successes"],
                   "target_successes": graph["full_graph"]["successes"], "target_total": len(tasks)},
        "after": {"core_successes": graph["full_graph"]["core_successes"] +
                  sum(row["core_kernel_pass"] for row in repairs),
                  "target_successes": graph["full_graph"]["successes"] + repaired_successes,
                  "target_total": len(tasks)},
        "dut_repairs": repairs,
    }
    atomic_json(run_dir / "analysis/tpoh_repair.json", result)
    reuse = _reuse_funnel(tasks, graph, causal, result)
    atomic_json(run_dir / "analysis/lemma_reuse.json", reuse)
    return result


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("run_dir", type=Path)
    args = parser.parse_args()
    project = Path(__file__).resolve().parents[2]
    result = run(project, args.run_dir.resolve())
    print(json.dumps({"before": result["before"], "after": result["after"]}, indent=2))
    return 0 if result["after"]["target_successes"] == result["after"]["target_total"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
