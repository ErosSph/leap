"""Pool-free final-target generation used as the RTL2Lean-style Direct baseline."""
from __future__ import annotations

import json
import re
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
from typing import Any

from experiments.adaptive_proving.io import atomic_json, atomic_text
from experiments.adaptive_proving.lean import FORBIDDEN_RE, check_source, synthetic_failure


PROOF_SCHEMA = {"type": "object", "properties": {
    "proof_body": {"type": "string"}, "proof_idea": {"type": "string"}},
    "required": ["proof_body", "proof_idea"], "additionalProperties": False}


def _source(task: dict[str, Any], proof: str) -> str:
    return "\n".join(["import R17Support", "set_option maxRecDepth 100000",
        "set_option maxHeartbeats 8000000", f"namespace {task['module']}Verification",
        f"open {task['module']}", f"theorem {task['task_id']} : {task['statement']} := {proof}",
        f"end {task['module']}Verification", ""])


def _feedback(result: dict[str, Any], limit: int) -> dict[str, Any]:
    raw = str(result.get("stdout", "")) + "\n" + str(result.get("stderr", ""))
    lower = raw.lower()
    categories = [label for needle, label in [
        ("unknown identifier", "UNKNOWN_IDENTIFIER"), ("unknown tactic", "UNKNOWN_TACTIC"),
        ("type mismatch", "TYPE_MISMATCH"), ("unsolved goals", "UNSOLVED_GOAL"),
        ("no additional binders", "INTRO_ARITY"),
        ("unexpected token", "SYNTAX_ERROR"), ("declaration uses 'sorry'", "FORBIDDEN_TERM")]
        if needle in lower]
    return {"schema": "rtl2lean-challenge_suite-fixed-feedback-v1",
        "categories": categories or ["KERNEL_REJECT"],
        "unknown_identifiers": list(dict.fromkeys(re.findall(
            r"unknown identifier [`'‘]([^`'’]+)[`'’]", lower))),
        "proof_state": str(result.get("proof_state", ""))[-limit:],
        "unsolved_goals": result.get("unsolved_goals", [])[:4],
        "diagnostic_tail": raw[-limit:],
        "policy": "fixed parser and fixed truncation; no Codex interpretation"}


def _context(model_dir: Path, source_row: dict[str, Any], limit: int) -> tuple[str, dict[str, Any]]:
    support = ((model_dir / "R16Support.lean").read_text(encoding="utf-8") + "\n" +
               (model_dir / "R17Support.lean").read_text(encoding="utf-8"))
    declarations = "\n".join(
        f"theorem {row['theorem']} : {row['statement']}" for row in source_row["selected_predicates"])
    full = support + "\n\nAvailable foundation declarations:\n" + declarations
    rendered = full[:limit]
    return rendered, {"full_chars": len(full), "sent_chars": len(rendered),
                      "truncated": len(rendered) < len(full), "policy": "prefix_char_limit"}


def _prompt(task: dict[str, Any], context: str, iteration: int,
            baseline: dict[str, Any], previous: dict[str, Any] | None,
            config: dict[str, Any]) -> str:
    repair = ""
    if previous:
        prior = str(previous.get("proof_body") or "")[-config["previous_proof_char_limit"]:]
        repair = "\nPrevious final-target proof and fixed Lean feedback:\n" + json.dumps(
            {"proof_body_tail": prior, "lean_feedback": previous["feedback"]},
            ensure_ascii=False, indent=2)
    return f"""Return JSON only. Prove the final Lean theorem directly.
This is the pool-free RTL2Lean Direct baseline: do not declare or assume any top-level
intermediate lemma. Local have/suffices inside proof_body is allowed. No prior generated
Property or reusable lemma pool is available.
Iteration: {iteration}/5
Namespace: {task['module']}Verification (open {task['module']})
Target: {task['task_id']} : {task['statement']}

Truncated Lean context:
{context}

Initial fixed prover feedback:
{json.dumps(baseline, ensure_ascii=False, indent=2)}

proof_body must start with `by`. Never use sorry, admit, axiom, unsafe, or native_decide.
Introduce exactly the binders present in the target; never invent an extra hypothesis.
Do not reference r16_bridge_* or R17_CORE because those declarations are absent.{repair}"""


def run_task(project: Path, run_dir: Path, task: dict[str, Any], source_row: dict[str, Any],
             config: dict[str, Any], model, seed: int) -> dict[str, Any]:
    root = run_dir / "direct" / "trials" / task["dut"] / task["task_id"]
    result_path = root / "result.json"
    if result_path.is_file():
        return json.loads(result_path.read_text(encoding="utf-8"))
    model_dir = project / source_row["model_dir"]
    context, context_stats = _context(model_dir, source_row, config["context_char_limit"])
    started = time.perf_counter()
    baseline_kernel = check_source(_source(task, "by simp"), model_dir,
        root / "kernel" / "baseline.lean", config["lean_timeout_seconds"])
    baseline_feedback = _feedback(baseline_kernel, config["feedback_char_limit"])
    attempts = []
    success = baseline_kernel["success"]
    success_iteration = 0 if success else None
    previous = None
    if not success:
        for iteration in range(1, config["max_iterations"] + 1):
            prompt = _prompt(task, context, iteration, baseline_feedback, previous, config)
            atomic_text(root / "calls" / f"iteration_{iteration:02d}_prompt.txt", prompt)
            response = model.generate(prompt, PROOF_SCHEMA, seed + iteration).serializable()
            atomic_json(root / "calls" / f"iteration_{iteration:02d}_response.json", response)
            answer = response.get("candidate") if isinstance(response.get("candidate"), dict) else {}
            proof = str(answer.get("proof_body") or "")
            if response.get("status") == "API_SUCCESS" and proof.lstrip().startswith("by") \
                    and not FORBIDDEN_RE.search(proof):
                kernel = check_source(_source(task, proof), model_dir,
                    root / "kernel" / f"iteration_{iteration:02d}.lean",
                    config["lean_timeout_seconds"])
            else:
                kernel = synthetic_failure(response.get("error") or "invalid/forbidden proof_body")
            success = kernel["success"]
            feedback = _feedback(kernel, config["feedback_char_limit"])
            attempts.append({"iteration": iteration, "api_call": True,
                "model_status": response.get("status"), "usage": response.get("usage") or {},
                "api_elapsed_s": response.get("elapsed_s", 0), "proof_idea": answer.get("proof_idea"),
                "proof_body_chars": len(proof), "kernel": kernel, "feedback": feedback,
                "success": success})
            if success:
                success_iteration = iteration
                break
            previous = {"proof_body": proof, "feedback": feedback}
    keys = ["input_tokens", "output_tokens", "total_tokens", "reasoning_tokens", "cached_tokens"]
    result = {"schema": "rtl2lean-challenge_suite-direct-result-v1",
        "task_id": task["task_id"], "dut": task["dut"], "category": task["category"],
        "subtype": task["subtype"], "success": success,
        "success_iteration": success_iteration, "iterations_used": len(attempts),
        "max_iterations": config["max_iterations"], "strategy": "RTL2LEAN_DIRECT",
        "direct_final_target_generation": True, "top_level_intermediate_lemma": False,
        "lemma_pool_enabled": False, "graph_enabled": False,
        "baseline_kernel": baseline_kernel, "context": context_stats,
        "usage": {key: sum(int(row["usage"].get(key) or 0) for row in attempts) for key in keys},
        "attempts": attempts, "elapsed_s": time.perf_counter() - started}
    atomic_json(result_path, result)
    return result


def run_all(project: Path, run_dir: Path, tasks: list[dict[str, Any]], manifest: dict[str, Any],
            config: dict[str, Any], model) -> list[dict[str, Any]]:
    sources = {row["dut"]: row for row in manifest["sources"]}
    execution_path = run_dir / "direct" / "execution.json"
    previous_execution = (json.loads(execution_path.read_text(encoding="utf-8"))
                          if execution_path.is_file() else None)
    preexisting = sum((run_dir / "direct" / "trials" / task["dut"] /
                       task["task_id"] / "result.json").is_file() for task in tasks)
    started = time.perf_counter(); ordered: dict[int, dict[str, Any]] = {}
    workers = config["direct_workers"]
    with ThreadPoolExecutor(max_workers=workers) as executor:
        pending = {executor.submit(run_task, project, run_dir, task, sources[task["dut"]],
            config, model, config["base_seed"] + index * 10): (index, task)
            for index, task in enumerate(tasks, 1)}
        for completed, future in enumerate(as_completed(pending), 1):
            index, task = pending[future]
            ordered[index] = future.result()
            print(f"[Req17 Direct] {completed}/177 done {task['dut']} {task['subtype']}", flush=True)
            atomic_json(run_dir / "progress.json", {"phase": "DIRECT", "completed": completed,
                "total": len(tasks), "latest": task["task_id"], "workers": workers})
    results = [ordered[index] for index in range(1, len(tasks) + 1)]
    atomic_json(run_dir / "direct" / "all_results.json", results)
    execution = {"workers": workers, "end_to_end_wall_s": time.perf_counter() - started,
        "task_elapsed_sum_s": sum(row["elapsed_s"] for row in results),
        "preexisting_results": preexisting, "scheduling_changes_proof_budget": False}
    if preexisting == len(tasks) and previous_execution:
        execution = {**previous_execution, "last_cached_resume_wall_s": execution["end_to_end_wall_s"]}
    atomic_json(execution_path, execution)
    return results
