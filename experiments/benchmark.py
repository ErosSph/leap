"""Frozen challenge-corpus benchmark, with independent chronological pools.

Full reproduces the R17 graph-guided core-generation strategy, not the later
post-hoc deterministic repair. Direct receives the same definitions/foundations
and its own earlier verified targets, but no graph or reference template.
"""
import json
import re
import time

from experiments.adaptive_proving.io import atomic_json, atomic_text
from experiments.adaptive_proving.lean import FORBIDDEN_RE, check_source, synthetic_failure
from experiments.challenge_suite.ablation import _graph
from experiments.challenge_suite.direct import _feedback
from .release_runtime import PROJECT
from . import release_runtime
ROOT = PROJECT / "results"

MODELS = []
CONFIG = {"max_attempts": 5, "max_tokens": 4096, "temperature": 0.2,
          "lean_timeout_s": 120, "feedback_chars": 6000, "pool_limit": 8,
          "full_variant": "frozen_R17_graph_guided_LLM_core_without_posthoc_repair",
          "direct_variant": "direct_final_target_with_independent_same_design_pool",
          "context_truncation": False, "thinking_control": "provider_default",
          "format_adapter": "strip_fence_strip_single_theorem_header_add_missing_by_v1"}


def normalize_proof(proof):
    proof = re.sub(r"^```(?:lean|lean4)?\s*|\s*```$", "", proof.strip())
    match = re.match(r"^(?:theorem|lemma)\s+.*?:=\s*(by\b.*)$", proof, re.S)
    if match: proof = match.group(1)
    if proof and not proof.startswith("by"):
        proof = "by\n" + "\n".join("  " + line for line in proof.splitlines())
    return proof


def prepare():
    return release_runtime.prepare(ROOT, CONFIG)


def generate(model, prompt):
    response = release_runtime.generate(model, prompt, CONFIG)
    body = response.get("body", {})
    choice = (body.get("choices") or [{}])[0]
    try:
        answer = json.loads(choice.get("message", {}).get("content", ""))
        if not isinstance(answer, dict):
            answer = {}
    except (TypeError, ValueError):
        answer = {}
    response["candidate"] = answer
    response["usage"] = body.get("usage")
    response["returned_model"] = body.get("model")
    response["finish_reason"] = choice.get("finish_reason")
    return response


def source(task, entries, name, statement, proof):
    ns = task["module"] + "Verification"
    declarations = [f"theorem {e['name']} : {e['statement']} := {e['proof']}" for e in entries]
    # Inspect the actual elaborated proof term, not text mentions or retrieval.
    audit = f'''open Lean in
run_cmd do
  let ci ← getConstInfo `{ns}.{name}
  match ci with
  | .thmInfo ti =>
    for n in ti.value.getUsedConstants do
      logInfo m!"PAPER_DEP:{{n}}"
  | _ => throwError "expected theorem"
#print axioms {ns}.{name}
'''
    return "\n".join(["import Lean", "import R17Support", "set_option maxRecDepth 100000",
        "set_option maxHeartbeats 8000000", f"namespace {ns}", f"open {task['module']}",
        *declarations, f"theorem {name} : {statement} := {proof}", f"end {ns}", audit])


def checked(task, entries, name, statement, proof, model_dir, path):
    if (not proof.lstrip().startswith("by") or FORBIDDEN_RE.search(proof)
            or re.search(r"\b(run_tac|run_cmd|elab|IO|implemented_by|extern)\b|(?m:^\s*#)", proof)):
        return synthetic_failure("invalid or forbidden generated proof")
    result = check_source(source(task, entries, name, statement, proof), model_dir, path, CONFIG["lean_timeout_s"])
    output = result.get("stdout", "") + result.get("stderr", "")
    result["dependencies"] = re.findall(r"PAPER_DEP:([^\s]+)", output)
    if "sorryAx" in output or "declaration uses 'sorry'" in output:
        result["success"] = False
    return result


def context(model_dir, choices):
    return ((model_dir / "R16Support.lean").read_text() + "\n" +
            (model_dir / "R17Support.lean").read_text() + "\nFoundation declarations:\n" +
            "\n".join(f"theorem {c['theorem']} : {c['statement']}" for c in choices))


def run_design(model, arm, row, tasks):
    dut = row["dut"]; directory = ROOT / "proofs" / model / arm / dut
    model_dir = release_runtime.model_directory(dut)
    ctx = context(model_dir, row["selected_predicates"])
    graph = _graph(tasks[0], row["selected_predicates"])
    pool = []; core = None; results = []
    for task_index, task in enumerate(tasks):
        root = directory / task["task_id"]; result_path = root / "result.json"
        if result_path.exists():
            result = json.loads(result_path.read_text()); results.append(result)
            if result.get("new_entry"):
                pool.append(result["new_entry"])
                if arm == "full": core = result["new_entry"]
            continue
        start = time.perf_counter(); attempts = []; checks = []; previous = None
        name = "paper_core" if arm == "full" else task["task_id"]
        statement = task["required_core_statement"] if arm == "full" else task["statement"]
        # Pool selection uses only statement symbols, never reference proofs.
        words = set(re.findall(r"\w+", task["statement"]))
        chosen = sorted(pool, key=lambda e: -len(words & set(re.findall(r"\w+", e["statement"]))))[:CONFIG["pool_limit"]]
        # Earlier proofs may depend transitively on earlier entries: compile the
        # full chronological pool, while exposing only retrieved declarations.
        available = "\n".join(f"theorem {e['name']} : {e['statement']}" for e in chosen)
        solved_proof = None; new_entry = None
        # Identical cheap foundation tactic for both arms on the ORIGINAL target.
        base = checked(task, pool, task["task_id"] + "_baseline", task["statement"], "by simp",
                       model_dir, root / "baseline.lean")
        checks.append(base)
        success = base["success"]; iteration = 0 if success else None
        kernel = base
        reused = []
        if not success and arm == "full" and core:
            proof = task["final_proof_template"].replace("R17_CORE", core["name"])
            kernel = checked(task, pool, task["task_id"], task["statement"], proof, model_dir, root / "reused.lean")
            checks.append(kernel); success = kernel["success"]
            if success: iteration = 0
        if not success and not (arm == "full" and core):
            for attempt in range(1, CONFIG["max_attempts"] + 1):
                representation = ("\nProof dependency hypergraph:\n" + json.dumps(graph) if arm == "full" else
                    "\nProve the final target directly. Local have/suffices is allowed; no new top-level lemmas.")
                prompt = (f"Lean 4.26. Namespace {task['module']}Verification; open {task['module']}.\n"
                    f"Target: {name} : {statement}\nAttempt {attempt}/{CONFIG["max_attempts"]}.\n{representation}\n"
                    f"Definitions and foundation declarations (available in Lean):\n{ctx}\n"
                    f"Previously kernel-verified same-design declarations:\n{available or '(empty)'}\n"
                    "Return JSON with proof_body starting with by, not a theorem declaration. "
                    "Do not reference r16_bridge_* or R17_CORE: they are absent.\n"
                    + ("Fixed previous Lean diagnostics and previous proof:\n" + json.dumps(previous) if previous else ""))
                atomic_text(root / f"attempt_{attempt}_prompt.txt", prompt)
                response = generate(model, prompt)
                atomic_json(root / f"attempt_{attempt}_response.json", response)
                proof = str(response["candidate"].get("proof_body", ""))
                # Uniform format adapter (all models/arms), not a mathematical
                # repair. Models sometimes return tactic lines without `by`.
                proof = normalize_proof(proof)
                if response["status"] == "OK":
                    kernel = checked(task, pool, name, statement, proof, model_dir, root / f"attempt_{attempt}.lean")
                    checks.append(kernel)
                else:
                    kernel = synthetic_failure("API infrastructure failure")
                attempts.append({"attempt": attempt, "response": response, "kernel": kernel})
                if response["status"] != "OK":
                    # Preserve infrastructure errors; never spend five repeats
                    # on authentication/model failures or count them as proofs.
                    break
                if kernel["success"]:
                    solved_proof = proof; iteration = attempt
                    new_entry = {"name": name, "statement": statement, "proof": proof,
                                 "source_property": task["task_id"]}
                    if arm == "full":
                        core = new_entry
                        target_proof = task["final_proof_template"].replace("R17_CORE", name)
                        kernel = checked(task, pool + [core], task["task_id"], task["statement"], target_proof,
                            model_dir, root / "target.lean")
                        checks.append(kernel)
                    success = kernel["success"]
                    break
                previous = {"proof_body": proof[-CONFIG["feedback_chars"]:],
                            "feedback": _feedback(kernel, CONFIG["feedback_chars"])}
        if success:
            deps = set(kernel.get("dependencies", []))
            reused = [e["name"] for e in pool if task["module"] + "Verification." + e["name"] in deps]
        if new_entry:
            pool.append(new_entry)
        elif success and arm == "direct" and base["success"]:
            new_entry = {"name": task["task_id"], "statement": task["statement"], "proof": "by simp",
                         "source_property": task["task_id"]}
            pool.append(new_entry)
        usages = [a["response"].get("usage") for a in attempts]
        result = {"model": model, "arm": arm, "dut": dut, "task_id": task["task_id"],
            "success": success, "success_iteration": iteration if success else None,
            "status": "PASS" if success else ("INFRASTRUCTURE_ERROR" if any(a["response"]["status"] != "OK" for a in attempts) else "UNSOLVED"),
            "attempts": len(attempts), "api_calls": len(attempts),
            "input_tokens": sum((u or {}).get("prompt_tokens", 0) for u in usages),
            "output_tokens": sum((u or {}).get("completion_tokens", 0) for u in usages),
            "total_tokens": sum((u or {}).get("total_tokens", 0) for u in usages),
            "unknown_usage_calls": sum(u is None for u in usages),
            "llm_elapsed_s": sum(a["response"].get("elapsed_s", 0) for a in attempts),
            "lean_elapsed_s": sum(c.get("elapsed_s", 0) for c in checks),
            "wall_s": time.perf_counter() - start, "actual_reused_names": reused,
            "pool_available_before": len(pool) - int(new_entry is not None),
            "retrieved_names": [e["name"] for e in chosen], "new_entry": new_entry,
            "kernel": kernel, "baseline": base}
        atomic_json(result_path, result); results.append(result)
        print(model, arm, dut, task_index + 1, result["status"], "calls", len(attempts), flush=True)
    atomic_json(directory / "results.json", results)
    return results


def summarize():
    rows = [json.loads(p.read_text()) for p in (ROOT / "proofs").glob("*/*/*/*/result.json")]
    summaries = []
    for model in MODELS:
        for arm in ("full", "direct"):
            selected = [r for r in rows if (r["model"], r["arm"]) == (model, arm)]
            if not selected: continue
            by_dut = []
            for dut in dict.fromkeys(r["dut"] for r in selected):
                sub = [r for r in selected if r["dut"] == dut]
                by_dut.append({"dut": dut, "completed": len(sub), "proved": sum(r["success"] for r in sub),
                    "reuse_targets": sum(bool(r["actual_reused_names"]) for r in sub),
                    "reuse_percent": 100 * sum(bool(r["actual_reused_names"]) for r in sub) / len(sub),
                    "mean_wall_s": sum(r["wall_s"] for r in sub) / len(sub)})
            summary = {"model": model, "arm": arm, "completed": len(selected), "expected": 177,
                "proved": sum(r["success"] for r in selected),
                "success_by_iteration": {str(i): sum(r["success"] and r["success_iteration"] <= i for r in selected) for i in range(6)},
                "infrastructure_errors": sum(r["status"] == "INFRASTRUCTURE_ERROR" for r in selected),
                "by_dut": by_dut, "macro_reuse_percent": sum(r["reuse_percent"] for r in by_dut) / len(by_dut)}
            for key in ("api_calls", "input_tokens", "output_tokens", "total_tokens", "unknown_usage_calls", "llm_elapsed_s", "lean_elapsed_s", "wall_s"):
                summary[key] = sum(r[key] for r in selected)
            summaries.append(summary)
    atomic_json(ROOT / "proofs/summary.json", summaries)
    return summaries


def main():
    release_runtime.main(__import__(__name__, fromlist=["main"]))


if __name__ == "__main__": main()
