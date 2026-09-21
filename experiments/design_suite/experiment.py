"""Five-iteration, same-DUT-pool, lemma-first design_suite prover."""
from __future__ import annotations

import json
import re
import time
from pathlib import Path
from typing import Any

from experiments.adaptive_proving.io import atomic_json, atomic_text
from experiments.adaptive_proving.lean import FORBIDDEN_RE, check_source, synthetic_failure
from rtl2lean.pipeline.compiler import kernel_check


PROOF_SCHEMA = {"type": "object", "properties": {
    "proof_body": {"type": "string"}, "proof_idea": {"type": "string"}},
    "required": ["proof_body", "proof_idea"], "additionalProperties": False}


def _source(task: dict[str, Any], proof: str, bridge_proof: str | None = None,
            import_pool: bool = True) -> str:
    imported = "R16Pool" if import_pool else "R16Support"
    rows = [f"import {imported}", "set_option maxRecDepth 100000",
        "set_option maxHeartbeats 8000000", f"namespace {task['module']}Verification",
        f"open {task['module']}"]
    if bridge_proof is not None:
        rows.append(f"theorem {task['bridge_name']} : {task['bridge_statement']} := {bridge_proof}")
    rows.extend([f"theorem {task['task_id']} : {task['statement']} := {proof}",
                 f"end {task['module']}Verification", ""])
    return "\n".join(rows)


def _bridge_source(task: dict[str, Any], proof: str) -> str:
    return "\n".join(["import R16Pool", "set_option maxRecDepth 100000",
        "set_option maxHeartbeats 8000000", f"namespace {task['module']}Verification",
        f"open {task['module']}",
        f"theorem {task['bridge_name']} : {task['bridge_statement']} := {proof}",
        f"end {task['module']}Verification", ""])


def _prompt(task: dict[str, Any], iteration: int, feedback: dict[str, Any] | None) -> str:
    repair = "" if feedback is None else ("\nDeterministically extracted Lean feedback from the prior iteration:\n" +
        json.dumps(feedback, ensure_ascii=False, indent=2))
    return f"""Return JSON only. This is lemma-first proof synthesis: prove only the missing
intermediate lemma below, never the final Property. The final Property is deliberately hidden.
Use the existing typed foundation theorem and unfold the named predicate if needed.
Iteration: {iteration}/5
Namespace: {task['module']}Verification (already open {task['module']})
Missing lemma: {task['bridge_name']} : {task['bridge_statement']}
Predicate definition: {task['predicate']} s i := {task['foundation_statement'].split(',', 1)[-1].strip()}
Available theorem: {task['foundation_theorem']} : {task['foundation_statement']}
proof_body must begin with `by`. Never use sorry, admit, axiom, unsafe, or native_decide.{repair}"""


def _feedback(result: dict[str, Any]) -> dict[str, Any]:
    text = (str(result.get("stdout", "")) + "\n" + str(result.get("stderr", ""))).lower()
    categories = [label for needle, label in [
        ("unknown identifier", "UNKNOWN_IDENTIFIER"), ("unknown tactic", "UNKNOWN_TACTIC"),
        ("type mismatch", "TYPE_MISMATCH"), ("unsolved goals", "UNSOLVED_GOAL"),
        ("unexpected token", "SYNTAX_ERROR"), ("declaration uses 'sorry'", "FORBIDDEN_TERM")]
        if needle in text]
    return {"schema": "rtl2lean-design_suite-fixed-feedback-v1",
        "categories": categories or ["KERNEL_REJECT"],
        "unknown_identifiers": list(dict.fromkeys(re.findall(
            r"unknown identifier [`'‘]([^`'’]+)[`'’]", text))),
        "proof_state": str(result.get("proof_state", ""))[-4000:],
        "unsolved_goals": result.get("unsolved_goals", [])[:4],
        "policy": "fixed parser only; no Codex interpretation"}


class DutPool:
    def __init__(self, model_dir: Path, root: Path, module: str, timeout_s: int):
        self.model_dir, self.root, self.module, self.timeout_s = model_dir, root, module, timeout_s
        self.bridges: dict[str, dict[str, str]] = {}
        self.properties: list[dict[str, str]] = []
        self.compile()

    @property
    def path(self) -> Path:
        return self.model_dir / "R16Pool.lean"

    def render(self, omit_bridge: str | None = None, include_properties: bool = True) -> str:
        rows = ["import R16Support", "set_option maxRecDepth 100000",
            "set_option maxHeartbeats 8000000", f"namespace {self.module}Verification",
            f"open {self.module}"]
        for name, row in self.bridges.items():
            if name != omit_bridge:
                rows.append(f"theorem {name} : {row['statement']} := {row['proof']}")
        if include_properties:
            for row in self.properties:
                rows.append(f"theorem {row['name']} : {row['statement']} := {row['proof']}")
        rows.extend([f"end {self.module}Verification", ""])
        return "\n".join(rows)

    def compile(self) -> dict[str, Any]:
        atomic_text(self.path, self.render())
        result = kernel_check(self.path, self.timeout_s, build_olean=True)
        if not result["success"]:
            raise RuntimeError("verified pool failed to compile: " + result.get("stderr", ""))
        return result

    def add_success(self, task: dict[str, Any], bridge_proof: str) -> dict[str, Any]:
        self.bridges.setdefault(task["bridge_name"], {
            "statement": task["bridge_statement"], "proof": bridge_proof,
            "origin_task": task["task_id"]})
        self.properties.append({"name": task["task_id"], "statement": task["statement"],
                                "proof": task["final_proof"]})
        return self.compile()


def run_task(project: Path, run_dir: Path, model_dir: Path, task: dict[str, Any],
             config: dict[str, Any], model, pool: DutPool, seed: int) -> dict[str, Any]:
    root = run_dir / "trials" / task["dut"] / task["task_id"]
    result_path = root / "result.json"
    if result_path.is_file():
        return json.loads(result_path.read_text(encoding="utf-8"))
    started = time.perf_counter()
    attempts: list[dict[str, Any]] = []
    bridge = pool.bridges.get(task["bridge_name"])
    reused = bridge is not None
    success = False
    successful_iteration = None
    bridge_proof = bridge["proof"] if bridge else ""
    final_kernel = synthetic_failure("not attempted")
    candidate_kernel = synthetic_failure("pool miss")

    if reused:
        final_kernel = check_source(_source(task, task["final_proof"], None, True), model_dir,
                                    root / "kernel" / "iteration_01_final.lean",
                                    config["lean_timeout_seconds"])
        attempts.append({"iteration": 1, "method": "SAME_DUT_VERIFIED_POOL",
            "api_call": False, "usage": {}, "candidate_kernel": None,
            "final_kernel": final_kernel, "success": final_kernel["success"]})
        success, successful_iteration = final_kernel["success"], 1 if final_kernel["success"] else None
    else:
        feedback = None
        for iteration in range(1, config["max_iterations"] + 1):
            prompt = _prompt(task, iteration, feedback)
            atomic_text(root / "calls" / f"iteration_{iteration:02d}_prompt.txt", prompt)
            response = model.generate(prompt, PROOF_SCHEMA, seed + iteration).serializable()
            atomic_json(root / "calls" / f"iteration_{iteration:02d}_response.json", response)
            answer = response.get("candidate") or {}
            bridge_proof = str(answer.get("proof_body") or "")
            if bridge_proof.lstrip().startswith("by") and not FORBIDDEN_RE.search(bridge_proof):
                candidate_kernel = check_source(_bridge_source(task, bridge_proof), model_dir,
                    root / "kernel" / f"iteration_{iteration:02d}_candidate.lean",
                    config["lean_timeout_seconds"])
            else:
                candidate_kernel = synthetic_failure(
                    response.get("error") or "missing/forbidden proof_body")
            if candidate_kernel["success"]:
                final_kernel = check_source(_source(task, task["final_proof"], bridge_proof, True),
                    model_dir, root / "kernel" / f"iteration_{iteration:02d}_final.lean",
                    config["lean_timeout_seconds"])
            else:
                final_kernel = synthetic_failure("candidate lemma did not pass kernel gate")
            success = bool(candidate_kernel["success"] and final_kernel["success"])
            attempts.append({"iteration": iteration, "method": "LLM_LEMMA_FIRST",
                "api_call": True, "model_status": response.get("status"),
                "usage": response.get("usage") or {}, "api_elapsed_s": response.get("elapsed_s", 0),
                "proof_idea": answer.get("proof_idea"), "candidate_kernel": candidate_kernel,
                "final_kernel": final_kernel, "success": success})
            if success:
                successful_iteration = iteration
                break
            feedback = _feedback(candidate_kernel if not candidate_kernel["success"] else final_kernel)

    deletion = synthetic_failure("property not proved")
    pool_compile = None
    if success:
        # Rebuild an ablation context with this bridge removed. Other bridge
        # lemmas remain, but no cross-DUT declarations are ever imported.
        ablation_source = pool.render(omit_bridge=task["bridge_name"], include_properties=False)
        ablation_source = ablation_source.rsplit(f"end {task['module']}Verification", 1)[0]
        ablation_source += (f"theorem {task['task_id']}__delete : {task['statement']} := "
                            f"{task['final_proof']}\nend {task['module']}Verification\n")
        deletion = check_source(ablation_source, model_dir, root / "ablation" /
                                "delete_reused_lemma.lean", config["lean_timeout_seconds"])
        pool_compile = pool.add_success(task, bridge_proof)
    usage_keys = ["input_tokens", "output_tokens", "total_tokens", "reasoning_tokens", "cached_tokens"]
    usage = {key: sum(int(a.get("usage", {}).get(key) or 0) for a in attempts) for key in usage_keys}
    result = {"schema": "rtl2lean-design_suite-result-v1", "task_id": task["task_id"],
        "dut": task["dut"], "category": task["category"], "subtype": task["subtype"],
        "success": success, "successful_iteration": successful_iteration,
        "iterations_used": len(attempts), "max_iterations": config["max_iterations"],
        "same_dut_pool_reuse": reused, "reused_lemma": task["bridge_name"] if reused else None,
        "cross_dut_reuse": False, "candidate_kernel_pass": candidate_kernel["success"] if not reused else None,
        "final_kernel_pass": final_kernel["success"],
        "causal_deletion_failure": bool(success and not deletion["success"]),
        "deletion_ablation": deletion, "pool_compile_pass": bool(pool_compile and pool_compile["success"]),
        "usage": usage, "elapsed_s": time.perf_counter() - started, "attempts": attempts}
    atomic_json(result_path, result)
    return result


def run_all(project: Path, run_dir: Path, tasks: list[dict[str, Any]], manifest: dict[str, Any],
            config: dict[str, Any], model) -> list[dict[str, Any]]:
    sources = {row["dut"]: row for row in manifest["sources"]}
    results = []
    for dut in config["duts"]:
        model_dir = project / sources[dut]["model_dir"]
        module = sources[dut]["namespace"].removesuffix("Verification")
        pool = DutPool(model_dir, run_dir / "pools" / dut, module, config["lean_timeout_seconds"])
        dut_tasks = [task for task in tasks if task["dut"] == dut]
        for index, task in enumerate(dut_tasks, 1):
            print(f"[Req16] {dut} {index}/{len(dut_tasks)} {task['subtype']}", flush=True)
            result = run_task(project, run_dir, model_dir, task, config, model, pool,
                              config["base_seed"] + config["duts"].index(dut) * 1000 + index * 10)
            results.append(result)
            atomic_json(run_dir / "progress.json", {"status": "RUNNING", "completed": len(results),
                "total": len(tasks), "latest": task["task_id"]})
        atomic_json(run_dir / "pools" / dut / "inventory.json", {
            "dut": dut, "bridge_lemmas": pool.bridges, "property_lemmas": pool.properties,
            "same_dut_only": True})
        atomic_text(run_dir / "pools" / dut / "R16Pool.lean", pool.render())
        atomic_text(run_dir / "pools" / dut / "R16Support.lean",
                    (model_dir / "R16Support.lean").read_text(encoding="utf-8"))
    atomic_json(run_dir / "runs" / "all_results.json", results)
    return results
