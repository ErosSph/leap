"""Paired TPOH/no-graph lemma-first ablation on the 177 hard Properties."""
from __future__ import annotations

import json
import time
from pathlib import Path
from typing import Any

from experiments.adaptive_proving.io import atomic_json, atomic_text
from experiments.adaptive_proving.lean import FORBIDDEN_RE, check_source, synthetic_failure
from .direct import PROOF_SCHEMA, _feedback


def _graph(task: dict[str, Any], choices: list[dict[str, Any]]) -> dict[str, Any]:
    nodes, edges = [], []
    for index, choice in enumerate(choices, 1):
        foundation, predicate = f"foundation:{index}", f"predicate:{index}"
        nodes += [{"id": foundation, "type": "FOUNDATION_THEOREM",
                   "theorem_name": choice["theorem"], "expression": choice["statement"]},
                  {"id": predicate, "type": "FACT",
                   "definition_name": choice["predicate"],
                   "expression": f"∀ s i, {choice['predicate']} s i"}]
        edges.append({"from": [foundation], "to": predicate, "type": "THEOREM_APPLICATION",
                      "binding": {"theorem": choice["theorem"],
                                  "predicate": choice["predicate"],
                                  "bridge_rule": "simpa [predicate] using theorem s i"}})
    nodes += [{"id": "pair12", "type": "INTERMEDIATE", "expression": "∀ s i, R17Pair12 s i"},
              {"id": "pair34", "type": "INTERMEDIATE", "expression": "∀ s i, R17Pair34 s i"},
              {"id": "core", "type": "PROOF_FRONTIER", "expression": task["required_core_statement"]},
              {"id": "goal", "type": "GOAL", "expression": task["statement"]}]
    edges += [{"from": ["predicate:1", "predicate:2"], "to": "pair12", "type": "CONJUNCTION"},
              {"from": ["predicate:3", "predicate:4"], "to": "pair34", "type": "CONJUNCTION"},
              {"from": ["pair12", "pair34"], "to": "core", "type": "DEFINITION_EXPANSION"},
              {"from": ["core"], "to": "goal", "type": task["category"]}]
    return {"schema": "rtl2lean-challenge_suite-tpoh-v2", "nodes": nodes, "hyperedges": edges,
        "initial_nodes": [f"foundation:{index}" for index in range(1, 5)], "goal": "goal",
        "proof_frontier": "core", "minimum_path_hops": 3,
        "backward_required_foundations": [f"foundation:{index}" for index in range(1, 5)]}


def _core_source(task: dict[str, Any], name: str, proof: str) -> str:
    return "\n".join(["import R17Support", "set_option maxRecDepth 100000",
        "set_option maxHeartbeats 8000000", f"namespace {task['module']}Verification",
        f"open {task['module']}", f"theorem {name} : {task['required_core_statement']} := {proof}",
        f"end {task['module']}Verification", ""])


def _target_source(task: dict[str, Any], name: str, core_proof: str) -> str:
    proof = task["final_proof_template"].replace("R17_CORE", name)
    return "\n".join(["import R17Support", "set_option maxRecDepth 100000",
        "set_option maxHeartbeats 8000000", f"namespace {task['module']}Verification",
        f"open {task['module']}", f"theorem {name} : {task['required_core_statement']} := {core_proof}",
        f"theorem {task['task_id']} : {task['statement']} := {proof}",
        f"end {task['module']}Verification", ""])


def _context(model_dir: Path, choices: list[dict[str, Any]]) -> str:
    definitions = (model_dir / "R17Support.lean").read_text(encoding="utf-8")
    foundations = "\n".join(f"theorem {row['theorem']} : {row['statement']}" for row in choices)
    return definitions + "\nAvailable foundation declarations:\n" + foundations


def _core_prompt(task: dict[str, Any], context: str, graph: dict[str, Any] | None,
                 iteration: int, prior: dict[str, Any] | None) -> str:
    representation = ("Typed Proof Obligation Hypergraph:\n" + json.dumps(graph, ensure_ascii=False, indent=2)
        if graph else "No dependency graph is available; infer the intermediate proof from the flat declarations.")
    repair = "" if prior is None else "\nPrior proof and fixed Lean feedback:\n" + json.dumps(
        prior, ensure_ascii=False, indent=2)
    return f"""Return JSON only. This is lemma-first proof generation, not final-target generation.
Prove exactly the aggregate intermediate lemma `{task['required_core_statement']}`. It combines
four RTL semantic facts through derived definitions and will later be kernel-gated and pooled.
Iteration: {iteration}/5
{representation}

Lean definitions and declarations:
{context}

proof_body must begin with `by`. Introduce exactly `s i`; do not invent hypotheses.
Never use sorry, admit, axiom, unsafe, native_decide, r16_bridge_*, or R17_CORE.{repair}"""


def _prove_core(project: Path, root: Path, task: dict[str, Any], choices: list[dict[str, Any]],
                graph: dict[str, Any] | None, arm: str, config: dict[str, Any], model,
                seed: int) -> dict[str, Any]:
    name = f"r17_{arm}_core"
    model_dir = project / task["model_dir"]
    context = _context(model_dir, choices)
    attempts, previous, proof, success = [], None, "", False
    for iteration in range(1, config["max_iterations"] + 1):
        prompt = _core_prompt(task, context, graph, iteration, previous)
        atomic_text(root / "calls" / f"iteration_{iteration:02d}_prompt.txt", prompt)
        response = model.generate(prompt, PROOF_SCHEMA, seed + iteration).serializable()
        atomic_json(root / "calls" / f"iteration_{iteration:02d}_response.json", response)
        answer = response.get("candidate") if isinstance(response.get("candidate"), dict) else {}
        proof = str(answer.get("proof_body") or "")
        if response.get("status") == "API_SUCCESS" and proof.lstrip().startswith("by") and not FORBIDDEN_RE.search(proof):
            kernel = check_source(_core_source(task, name, proof), model_dir,
                root / "kernel" / f"iteration_{iteration:02d}.lean", config["lean_timeout_seconds"])
        else:
            kernel = synthetic_failure(response.get("error") or "invalid/forbidden proof")
        feedback = _feedback(kernel, config["feedback_char_limit"])
        attempts.append({"iteration": iteration, "model_status": response.get("status"),
            "usage": response.get("usage") or {}, "api_elapsed_s": response.get("elapsed_s", 0),
            "kernel": kernel, "success": kernel["success"]})
        success = kernel["success"]
        if success: break
        previous = {"proof_body_tail": proof[-config["previous_proof_char_limit"]:],
                    "lean_feedback": feedback}
    keys = ["input_tokens", "output_tokens", "total_tokens", "reasoning_tokens", "cached_tokens"]
    return {"arm": arm, "core_name": name, "success": success, "proof": proof if success else "",
        "successful_iteration": next((row["iteration"] for row in attempts if row["success"]), None),
        "attempts": attempts,
        "usage": {key: sum(int(row["usage"].get(key) or 0) for row in attempts) for key in keys}}


def run(project: Path, run_dir: Path, tasks: list[dict[str, Any]], manifest: dict[str, Any],
        config: dict[str, Any], model) -> dict[str, Any]:
    sources = {row["dut"]: row for row in manifest["sources"]}
    arm_results = {"full_graph": [], "no_graph_flat": []}
    all_rows = []
    for dut_index, dut in enumerate(config["duts"]):
        dut_tasks = [task for task in tasks if task["dut"] == dut]
        source = sources[dut]; choices = source["selected_predicates"]
        enriched = [{**task, "model_dir": source["model_dir"]} for task in dut_tasks]
        graph = _graph(enriched[0], choices)
        core_results = {}
        for arm_index, arm in enumerate(["full_graph", "no_graph_flat"]):
            core_results[arm] = _prove_core(project, run_dir / "ablation" / arm / "core" / dut,
                enriched[0], choices, graph if arm == "full_graph" else None, arm, config, model,
                config["base_seed"] + 50000 + dut_index * 100 + arm_index * 10)
            atomic_json(run_dir / "ablation" / arm / "core" / dut / "result.json", core_results[arm])
        for task in enriched:
            paired = {"task_id": task["task_id"], "dut": dut, "graph": graph}
            for arm in ["full_graph", "no_graph_flat"]:
                core = core_results[arm]
                if core["success"]:
                    kernel = check_source(_target_source(task, core["core_name"], core["proof"]),
                        project / source["model_dir"], run_dir / "ablation" / arm / "targets" / dut /
                        f"{task['task_id']}.lean", config["lean_timeout_seconds"])
                else:
                    kernel = synthetic_failure("aggregate intermediate lemma was not proved")
                row = {"task_id": task["task_id"], "dut": dut, "arm": arm,
                    "success": kernel["success"], "lemma_first": True, "same_dut_pool": True,
                    "graph_enabled": arm == "full_graph", "core_reused": core["success"], "kernel": kernel}
                arm_results[arm].append(row); paired[arm] = row
            all_rows.append(paired)
        print(f"[Req17 Hard Ablation] {dut} {len(dut_tasks)} tasks", flush=True)
    summaries = {}
    for arm, rows in arm_results.items():
        cores = [json.loads(path.read_text()) for path in sorted(
            (run_dir / "ablation" / arm / "core").glob("*/result.json"))]
        summaries[arm] = {"successes": sum(row["success"] for row in rows), "total": len(rows),
            "core_successes": sum(row["success"] for row in cores), "core_total": len(cores),
            "physical_api_calls": sum(len(row["attempts"]) for row in cores),
            "total_tokens": sum(row["usage"]["total_tokens"] for row in cores)}
    result = {"schema": "rtl2lean-challenge_suite-hard-graph-ablation-v2",
        "task_count": len(tasks), "full_graph": summaries["full_graph"],
        "no_graph_flat": summaries["no_graph_flat"], "paired_seed_policy": True,
        "no_graph_is_not_direct": True,
        "held_constant": ["hard targets", "aggregate lemma statement", "foundation declarations",
                          "lemma-first", "kernel gate", "same-DUT pool", "five-attempt budget"],
        "changed_only": "explicit TPOH dependency representation in the lemma prompt",
        "rows": all_rows}
    atomic_json(run_dir / "ablation" / "graph_ablation.json", result)
    return result


def causal_audit(project: Path, run_dir: Path, tasks: list[dict[str, Any]],
                 manifest: dict[str, Any], config: dict[str, Any]) -> dict[str, Any]:
    """Delete the pooled core declaration and replay every successful graph target."""
    sources = {row["dut"]: row for row in manifest["sources"]}
    ablation = json.loads((run_dir / "ablation/graph_ablation.json").read_text())
    successful = {row["task_id"] for row in ablation["rows"] if row["full_graph"]["success"]}
    rows = []
    for task in tasks:
        if task["task_id"] not in successful:
            continue
        core_name = "r17_full_graph_core"
        proof = task["final_proof_template"].replace("R17_CORE", core_name)
        source = "\n".join(["import R17Support", f"namespace {task['module']}Verification",
            f"open {task['module']}",
            f"theorem {task['task_id']}__delete_core : {task['statement']} := {proof}",
            f"end {task['module']}Verification", ""])
        checked = check_source(source, project / sources[task["dut"]]["model_dir"],
            run_dir / "ablation/causal_deletion" / task["dut"] / f"{task['task_id']}.lean",
            config["lean_timeout_seconds"])
        rows.append({"task_id": task["task_id"], "dut": task["dut"],
            "deletion_kernel_pass": checked["success"], "causally_required": not checked["success"],
            "kernel": checked})
    result = {"schema": "rtl2lean-challenge_suite-core-deletion-audit-v1",
        "successful_graph_targets": len(successful), "checked": len(rows),
        "deletion_failures": sum(row["causally_required"] for row in rows),
        "all_successful_graph_targets_causally_depend_on_core": bool(rows) and all(
            row["causally_required"] for row in rows), "rows": rows}
    atomic_json(run_dir / "ablation/causal_deletion.json", result)
    return result
