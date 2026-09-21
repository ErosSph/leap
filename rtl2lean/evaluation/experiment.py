"""Formal evaluation baseline, LLM, ablation, pool and order experiments."""
from __future__ import annotations

import json
import hashlib
import re
import shutil
import subprocess
import time
from dataclasses import asdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from rtl2lean.pipeline.compiler import find_lean, kernel_check
from rtl2lean.pipeline.io import sha256, write_json
from rtl2lean.pipeline.manifest import Benchmark
from rtl2lean.proving.context import select_context
from rtl2lean.proving.llm_prover import (
    AutonomousProofTask,
    CodexCLIProvider,
    PersistentLocalLemmaPool,
    ProvingBudget,
    StructuredCandidate,
    VerifiedLemmaRecord,
    _autonomous_kernel_check,
    _validate_structured_candidate,
    run_budgeted_proof_search,
)
from rtl2lean.theorems.generator import GeneratedTheorem
from rtl2lean.backend.codegen import CodeGenerator
from rtl2lean.frontend import SVParser
from rtl2lean.middle_end.ir import normalize_combinational_schedule
from rtl2lean.middle_end.ir_converter import module_to_ir
from rtl2lean.middle_end.optimizer import Optimizer
from rtl2lean.middle_end.type_checker import TypeChecker
from rtl2lean.pipeline.schema import build_design_ir


DEFAULT_BUDGET = ProvingBudget(
    max_generation_rounds=3,
    max_repair_rounds_per_candidate=2,
    max_intermediate_lemmas=4,
    max_llm_calls=10,
)

GENERIC_BASELINE_PROOFS = ("by rfl", "by simp", "by simp_all", "by grind")


def _read(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8")) if path.is_file() else {}


def _module(benchmark: Benchmark) -> str:
    return benchmark.top_module


def _framework_path(output_root: Path, benchmark: Benchmark) -> Path:
    return output_root / benchmark.slug / "model" / "R2Framework.lean"


def prepare_framework(output_root: Path, benchmark: Benchmark) -> dict[str, Any]:
    path = _framework_path(output_root, benchmark)
    path.write_text(
        "import Framework\n\nset_option maxRecDepth 100000\n"
        "set_option maxHeartbeats 8000000\n",
        encoding="utf-8",
    )
    result = kernel_check(path)
    write_json(path.with_name("r2_framework_check.json"), result)
    if not result["success"]:
        raise RuntimeError(f"evaluation framework rejected for {benchmark.design_id}: "
                           + (result.get("stdout", "") + result.get("stderr", ""))[-4000:])
    return result


def measure_translation_phases(benchmarks: list[Benchmark], output_root: Path,
                               requirement_root: Path) -> dict[str, Any]:
    """Measure frozen translator phases without changing their implementation."""
    rows = []
    for benchmark in benchmarks:
        total_started = time.perf_counter()
        started = time.perf_counter()
        ast = SVParser().parse_files(list(benchmark.source_files), benchmark.top_module)[0]
        _, errors = TypeChecker.check_module(ast)
        if errors:
            raise ValueError("frozen frontend regression: " + "; ".join(map(str, errors)))
        frontend = time.perf_counter() - started

        started = time.perf_counter()
        ir = normalize_combinational_schedule(Optimizer.optimize(module_to_ir(ast), 2))
        typed = build_design_ir(benchmark.design_id, ast, ir)
        ir_time = time.perf_counter() - started

        started = time.perf_counter()
        model = CodeGenerator.generate(ir) + "\n"
        lean_generation = time.perf_counter() - started
        generated_hash = hashlib.sha256(model.encode()).hexdigest()
        frozen_path = output_root / benchmark.slug / "model" / "Model.lean"
        frozen_hash = sha256(frozen_path)
        if generated_hash != frozen_hash:
            raise RuntimeError(f"frozen translator changed for {benchmark.design_id}")
        rows.append({
            "dut": benchmark.design_id, "Tfrontend": frontend, "Tir": ir_time,
            "Tlean_generation": lean_generation,
            "Ttranslation": frontend + ir_time + lean_generation,
            "elapsed_s": time.perf_counter() - total_started,
            "generated_model_sha256": generated_hash, "frozen_model_sha256": frozen_hash,
            "model_match": True, "typed_signal_count": len(typed.module.signals),
        })
    payload = {"schema": "rtl2lean-evaluation-translation-timing-v1", "rows": rows}
    write_json(requirement_root / "runtime" / "translation_phases.json", payload)
    return payload


def _property_source(benchmark: Benchmark, prop: dict[str, Any], proof: str) -> str:
    return "\n".join([
        "import R2Framework", "", "set_option maxRecDepth 100000",
        "set_option maxHeartbeats 8000000", "",
        f"namespace {_module(benchmark)}Verification", f"open {_module(benchmark)}", "",
        f"theorem {prop['property_id']} : {prop['theorem_statement']} := {proof}", "",
        f"end {_module(benchmark)}Verification", "",
    ])


def _property_statement_source(benchmark: Benchmark, prop: dict[str, Any]) -> str:
    """Compile the proposition independently so type errors are never proof failures."""
    return "\n".join([
        "import R2Framework", "", "set_option maxRecDepth 100000",
        "set_option maxHeartbeats 8000000", "",
        f"namespace {_module(benchmark)}Verification", f"open {_module(benchmark)}", "",
        f"def {prop['property_id']}__statement : Prop := {prop['theorem_statement']}", "",
        f"end {_module(benchmark)}Verification", "",
    ])


def _lean_check(path: Path, model_dir: Path, timeout_s: int = 600) -> dict[str, Any]:
    lean = find_lean()
    env = dict(**__import__("os").environ)
    env["LEAN_PATH"] = str(model_dir) + (":" + env["LEAN_PATH"] if env.get("LEAN_PATH") else "")
    started = time.perf_counter()
    try:
        completed = subprocess.run(
            [lean, "-s", "65536", str(path)], cwd=path.parent, env=env,
            capture_output=True, text=True, check=False, timeout=timeout_s,
        )
        return {
            "success": completed.returncode == 0, "returncode": completed.returncode,
            "stdout": completed.stdout, "stderr": completed.stderr,
            "elapsed_s": time.perf_counter() - started,
            "command": [lean, "-s", "65536", str(path)],
        }
    except subprocess.TimeoutExpired as error:
        return {
            "success": False, "returncode": 124,
            "stdout": error.stdout.decode() if isinstance(error.stdout, bytes) else (error.stdout or ""),
            "stderr": (error.stderr.decode() if isinstance(error.stderr, bytes) else (error.stderr or ""))
                      + f"\ntimeout after {timeout_s}s",
            "elapsed_s": time.perf_counter() - started,
            "command": [lean, "-s", "65536", str(path)],
        }


def run_baseline(
    benchmarks: list[Benchmark], corpus: dict[str, Any], output_root: Path, requirement_root: Path,
) -> dict[str, Any]:
    started = time.perf_counter()
    results = []
    framework_time = 0.0
    for benchmark in benchmarks:
        framework_time += float(prepare_framework(output_root, benchmark).get("elapsed_s", 0.0))
        model_dir = output_root / benchmark.slug / "model"
        properties = [item for item in corpus["properties"] if item["dut"] == benchmark.design_id]
        for index, prop in enumerate(properties):
            attempts = []
            solved_proof = None
            property_dir = requirement_root / "baseline" / "attempts" / benchmark.slug / f"{index:03d}_{prop['property_id']}"
            property_dir.mkdir(parents=True, exist_ok=True)
            statement_path = property_dir / "statement_check.lean"
            statement_path.write_text(_property_statement_source(benchmark, prop), encoding="utf-8")
            statement_check = _lean_check(statement_path, model_dir)
            write_json(property_dir / "statement_check.json", statement_check)
            if not statement_check["success"]:
                raise RuntimeError(
                    f"ill-typed formal property {benchmark.design_id}/{prop['property_id']}: "
                    + (statement_check.get("stdout", "") + statement_check.get("stderr", ""))[-4000:]
                )
            proof_suite = list(dict.fromkeys([
                *GENERIC_BASELINE_PROOFS, *prop.get("proof_candidates", []),
            ]))
            for proof_index, proof in enumerate(proof_suite):
                path = property_dir / f"attempt_{proof_index:02d}.lean"
                path.write_text(_property_source(benchmark, prop, proof), encoding="utf-8")
                check = _lean_check(path, model_dir)
                attempts.append({"proof": proof, "proof_steps": max(1, proof.count(";") + proof.count("\n") + 1), **check})
                if check["success"]:
                    solved_proof = proof
                    break
            result = {
                "property_id": prop["property_id"], "dut": benchmark.design_id,
                "status": "BASE_SOLVED" if solved_proof else "BASE_FAILED",
                "proof": solved_proof, "proof_tactics": solved_proof,
                "used_L1": prop.get("L1", []), "used_L2": prop.get("L2", []),
                "used_L3": prop.get("L3", []), "used_L4": prop.get("L4", []),
                "used_shared_lemmas": [], "proof_time_s": sum(item["elapsed_s"] for item in attempts),
                "proof_steps": next((item["proof_steps"] for item in attempts if item["success"]), None),
                "statement_well_formed": True, "statement_check": statement_check,
                "attempts": attempts,
            }
            write_json(property_dir / "result.json", result)
            results.append(result)
    payload = {
        "schema": "rtl2lean-evaluation-baseline-v1", "results": results,
        "property_corpus_sha256": sha256(requirement_root / "corpus" / "property_corpus.json"),
        "strategy": {
            "generic_proofs": list(GENERIC_BASELINE_PROOFS),
            "contextual_proofs": "mechanically emitted from the property source function",
            "applied_to": "every property before target selection",
        },
        "metrics": {
            "TARGETS": len(results), "BASE_SOLVED": sum(item["status"] == "BASE_SOLVED" for item in results),
            "BASE_FAILED": sum(item["status"] == "BASE_FAILED" for item in results),
            "BASE_SUCCESS_RATE": sum(item["status"] == "BASE_SOLVED" for item in results) / len(results),
            "Tbaseline": sum(item["proof_time_s"] for item in results),
            "TLean_framework": framework_time,
            "elapsed_s": time.perf_counter() - started,
        },
    }
    write_json(requirement_root / "baseline" / "baseline_results.json", payload)
    candidates = [{"property_id": item["property_id"], "dut": item["dut"], "status": item["status"]}
                  for item in results]
    selected = [item for item in candidates if item["status"] == "BASE_FAILED"]
    selection = {
        "schema": "rtl2lean-evaluation-target-selection-v1",
        "selection_rule": "all valid BASE_FAILED high-level properties from the pre-frozen corpus",
        "selection_frozen_before_llm": True,
        "candidate_targets": candidates, "selected_targets": selected,
    }
    write_json(requirement_root / "baseline" / "candidate_targets.json", {"targets": candidates})
    write_json(requirement_root / "baseline" / "selected_targets.json", {"targets": selected})
    write_json(requirement_root / "baseline" / "selection_rule.json", {
        "rule": selection["selection_rule"], "frozen_before_llm": True,
    })
    write_json(requirement_root / "baseline" / "target_selection.json", selection)
    return payload


def _generated_target(prop: dict[str, Any]) -> GeneratedTheorem:
    return GeneratedTheorem(
        name=prop["property_id"], layer="PROPERTY", statement=prop["theorem_statement"],
        property_family=prop["property_family"],
        source_functions=tuple(prop.get("source_functions", [])),
        state_fields=tuple(prop.get("referenced_state_fields", [])),
        input_fields=tuple(prop.get("referenced_inputs", [])),
        proof_candidates=tuple(prop.get("proof_candidates", [])), high_level=True,
    )


def _task(
    benchmark: Benchmark, prop: dict[str, Any], output_root: Path, property_dir: Path,
    pool: PersistentLocalLemmaPool, baseline: dict[str, Any], future: list[dict[str, Any]],
) -> AutonomousProofTask:
    # Context selector consumes the dataclass version retained in the frozen compiler cache.
    import pickle
    typed = pickle.loads((output_root / benchmark.slug / "ir" / "compiler_objects.pkl").read_bytes())["typed_ir"]
    selected = select_context(
        _generated_target(prop), typed, output_root / benchmark.slug / "model" / "Model.lean",
        [{**asdict(item), "statement": item.proposition,
          "state_fields": prop.get("referenced_state_fields", [])} for item in pool.lemmas],
        property_dir / "context_selection.json",
    )
    framework_targets = _read(output_root / benchmark.slug / "model" / "targets.json").get("targets", [])
    dependency_names = set().union(*(set(prop.get(layer, [])) for layer in ("L1", "L2", "L3", "L4")))
    foundational = [f"{item['name']} : {item['statement']}" for item in framework_targets
                    if item["name"] in dependency_names]
    error = "\n".join((attempt.get("stdout", "") + attempt.get("stderr", ""))[-5000:]
                      for attempt in baseline.get("attempts", []) if not attempt.get("success"))
    return AutonomousProofTask(
        dut=benchmark.design_id, target_name=prop["property_id"],
        target_statement=prop["theorem_statement"], property_type=prop["property_family"],
        state_type=f"{benchmark.top_module}State",
        required_state_fields=list(prop.get("referenced_state_fields", [])),
        required_input_fields=list(prop.get("referenced_inputs", [])), assumptions=[],
        context_import="R2Framework", context_snippets=[
            (output_root / benchmark.slug / "model" / "Foundation.lean").read_text(encoding="utf-8"),
            *selected["model_snippets"],
        ],
        relevant_foundational_lemmas=foundational, base_lean_error=error,
        future_targets=[{"name": item["property_id"], "statement": item["theorem_statement"]}
                        for item in future[:4]],
    )


def _record_for_property(benchmark: Benchmark, prop: dict[str, Any], proof: str,
                         origin: str) -> VerifiedLemmaRecord:
    return VerifiedLemmaRecord(
        name=prop["property_id"], proposition=prop["theorem_statement"], proof_body=proof,
        source_target=prop["property_id"], generation_round=0, kernel_result="PASS",
        created_time=datetime.now(timezone.utc).isoformat(), origin=origin,
        property_category=prop["property_family"], state_type=f"{benchmark.top_module}State",
        involved_functions=list(prop.get("source_functions", [])), used_lemmas=[],
        dut=benchmark.design_id, module=benchmark.top_module,
        statement=prop["theorem_statement"], proof=proof, kernel_verified=True,
        dependencies=sum((list(prop.get(layer, [])) for layer in ("L1", "L2", "L3", "L4")), []),
        tags=[prop["property_family"], prop.get("semantic_relatedness", "")],
    )


def run_direct_without_intermediate(
    task: AutonomousProofTask, benchmark: Benchmark, model_dir: Path, output_dir: Path,
    provider: CodexCLIProvider, budget_calls: int = 3,
    budget_tokens: int | None = None,
    max_repair_rounds_per_candidate: int | None = None,
) -> dict[str, Any]:
    """Arm B: ask for the exact final target while forbidding new intermediates."""
    pool = PersistentLocalLemmaPool(output_dir / "initial_pool.json", benchmark.design_id)
    # Ensure reruns do not inherit any prior generated lemma.
    write_json(pool.path, {"schema": pool.SCHEMA, "dut": benchmark.design_id, "lemmas": [],
                           "metrics": {"verified_lemmas": 0, "actual_reused_lemmas": 0,
                                       "actual_reuse_hits": 0}})
    pool = PersistentLocalLemmaPool(pool.path, benchmark.design_id)
    history = []
    previous: StructuredCandidate | None = None
    repairs_current_strategy = 0
    repairs_used = 0
    strategy_index = 1
    feedback = task.base_lean_error
    llm_time = lean_time = 0.0
    llm_tokens = 0
    calls_made = 0
    for call_index in range(1, budget_calls + 1):
        if budget_tokens is not None and llm_tokens >= budget_tokens:
            break
        mode = "DIRECT_TARGET" if previous is None else "REPAIR"
        context = {
            "mode": mode, "generation_round": strategy_index,
            "repair_round": repairs_current_strategy + 1 if mode == "REPAIR" else 0,
            "proof_task": asdict(task), "lean_feedback": feedback,
            "retrieved_lemmas": [], "attempt_history": history,
            "previous_candidate": asdict(previous) if previous else None,
        }
        candidate = provider.generate(context, output_dir / "llm_calls" / f"call_{call_index:02d}")
        calls_made += 1
        llm_time += float(provider.last_call.get("elapsed_s", 0.0))
        if isinstance(provider.last_call.get("tokens"), int):
            llm_tokens += provider.last_call["tokens"]
        if not candidate:
            history.append({"call": call_index, "status": "PROVIDER_FAILURE", "provider": provider.last_call})
            previous = None
            repairs_current_strategy = 0
            strategy_index += 1
            continue
        if mode == "REPAIR":
            repairs_used += 1
            repairs_current_strategy += 1
        try:
            _validate_structured_candidate(candidate, task, mode, previous)
        except ValueError as error:
            feedback = str(error)
            history.append({"call": call_index, "status": "STRUCTURE_REJECTED",
                            "candidate": asdict(candidate), "error": feedback,
                            "provider": provider.last_call})
            previous = candidate
            if (max_repair_rounds_per_candidate is not None
                    and repairs_current_strategy >= max_repair_rounds_per_candidate):
                previous = None
                repairs_current_strategy = 0
                strategy_index += 1
            continue
        check = _autonomous_kernel_check(
            candidate, task, pool, model_dir,
            output_dir / "lean_checks" / f"candidate_{call_index:02d}.lean", find_lean(),
        )
        lean_time += float(check["elapsed_s"])
        history.append({"call": call_index, "status": "PASS" if check["success"] else "LEAN_REJECTED",
                        "candidate": asdict(candidate), "kernel_check": check,
                        "provider": provider.last_call})
        if check["success"]:
            result = {
                "status": "PASS", "target_kernel_pass": True,
                "final_candidate": asdict(candidate), "final_proof": candidate.proof_body,
                "llm_calls": calls_made, "llm_tokens": llm_tokens,
                "repair_rounds_used": repairs_used,
                "token_budget_exhausted": budget_tokens is not None and llm_tokens >= budget_tokens,
                "llm_time_s": llm_time, "lean_time_s": lean_time,
                "new_intermediate_lemmas": 0, "history": history,
            }
            write_json(output_dir / "result.json", result)
            return result
        feedback = check.get("stdout", "") + check.get("stderr", "")
        previous = candidate
        if (max_repair_rounds_per_candidate is not None
                and repairs_current_strategy >= max_repair_rounds_per_candidate):
            previous = None
            repairs_current_strategy = 0
            strategy_index += 1
    result = {
        "status": "FAIL", "target_kernel_pass": False, "final_candidate": None,
        "final_proof": None, "llm_calls": calls_made, "llm_tokens": llm_tokens,
        "repair_rounds_used": repairs_used,
        "token_budget_exhausted": budget_tokens is not None and llm_tokens >= budget_tokens,
        "llm_time_s": llm_time,
        "lean_time_s": lean_time, "new_intermediate_lemmas": 0, "history": history,
    }
    write_json(output_dir / "result.json", result)
    return result


def _order(properties: list[dict[str, Any]], rule: str) -> list[dict[str, Any]]:
    lexical = sorted(properties, key=lambda item: item["property_id"])
    if rule == "reverse":
        return list(reversed(lexical))
    if rule == "lexical":
        return lexical
    if rule == "dependency":
        return sorted(properties, key=lambda item: (
            1 if item["property_family"] in {
                "finite_reachability_witness", "multi_cycle_transition_witness",
            } else 0,
            item["dependency_cone"]["total"], item["property_id"],
        ))
    raise ValueError(rule)


def run_pool_configuration(
    name: str, benchmarks: list[Benchmark], corpus: dict[str, Any], baseline_payload: dict[str, Any],
    output_root: Path, requirement_root: Path, provider_options: dict[str, Any],
    shared: bool, order_rule: str,
) -> dict[str, Any]:
    config_root = requirement_root / "runs" / name
    baseline_map = {(item["dut"], item["property_id"]): item for item in baseline_payload["results"]}
    all_results = []
    retrieval_events = []
    started = time.perf_counter()
    for benchmark in benchmarks:
        properties = _order([item for item in corpus["properties"] if item["dut"] == benchmark.design_id], order_rule)
        shared_path = config_root / benchmark.slug / "shared_pool.json"
        shared_pool = None
        if shared:
            write_json(shared_path, {"schema": PersistentLocalLemmaPool.SCHEMA,
                                     "dut": benchmark.design_id, "lemmas": [],
                                     "metrics": {"verified_lemmas": 0,
                                                 "actual_reused_lemmas": 0,
                                                 "actual_reuse_hits": 0}})
            shared_pool = PersistentLocalLemmaPool(shared_path, benchmark.design_id)
        else:
            shared_path.unlink(missing_ok=True)
        provider = CodexCLIProvider(workdir=Path(__file__).resolve().parents[2], **provider_options)
        for index, prop in enumerate(properties):
            property_dir = config_root / benchmark.slug / f"{index:03d}_{prop['property_id']}"
            if shared:
                assert shared_pool is not None
                pool = shared_pool
            else:
                pool_path = property_dir / "fresh_pool.json"
                write_json(pool_path, {"schema": PersistentLocalLemmaPool.SCHEMA,
                                       "dut": benchmark.design_id, "lemmas": [],
                                       "metrics": {"verified_lemmas": 0,
                                                   "actual_reused_lemmas": 0, "actual_reuse_hits": 0}})
                pool = PersistentLocalLemmaPool(pool_path, benchmark.design_id)
            base = baseline_map[(benchmark.design_id, prop["property_id"])]
            task = _task(benchmark, prop, output_root, property_dir, pool, base, properties[index + 1:])
            retrieval_started = time.perf_counter()
            retrieved = pool.retrieve(task)
            retrieval_time = time.perf_counter() - retrieval_started
            retrieval_events.append({
                "configuration": name, "dut": benchmark.design_id, "property_id": prop["property_id"],
                "available": len(pool.lemmas), "retrieved": [
                    {"rank": rank, "lemma": item["name"], "source_property": item["source_target"],
                     "retrieval_score": item["relevance_score"]}
                    for rank, item in enumerate(retrieved, 1)
                ], "retrieval_time_s": retrieval_time,
            })
            if base["status"] == "BASE_SOLVED":
                result = {
                    "dut": benchmark.design_id, "property_id": prop["property_id"],
                    "status": "PASS", "method": "BASELINE", "proof": base["proof"],
                    "llm_calls": 0, "repair_rounds": 0, "new_lemmas": 0,
                    "proof_time_s": base["proof_time_s"], "lean_time_s": base["proof_time_s"],
                    "actual_reuse": [], "retrieved_count": len(retrieved),
                    "pool_path": str(pool.path),
                }
                if shared:
                    pool.add_verified(_record_for_property(benchmark, prop, base["proof"], "baseline-property"))
            else:
                llm_result = run_budgeted_proof_search(
                    task, provider, pool, output_root / benchmark.slug / "model", property_dir / "llm",
                    DEFAULT_BUDGET, allow_pool_first=shared,
                )
                result = {
                    "dut": benchmark.design_id, "property_id": prop["property_id"],
                    "status": "PASS" if llm_result["target_kernel_pass"] else "FAIL",
                    "method": "LLM_WITH_INTERMEDIATE", "proof": llm_result.get("final_proof"),
                    "llm_calls": llm_result["total_llm_calls"],
                    "repair_rounds": llm_result["repair_rounds_used"],
                    "new_lemmas": len(llm_result["accepted_intermediate_lemmas"]),
                    "verified_intermediate_lemmas": llm_result["accepted_intermediate_lemmas"],
                    "proof_time_s": llm_result["llm_time_s"] + llm_result["lean_time_s"],
                    "lean_time_s": llm_result["lean_time_s"],
                    "llm_time_s": llm_result["llm_time_s"],
                    "actual_reuse": llm_result["actual_reuse"],
                    "intermediate_lemma_usage": llm_result["intermediate_lemma_usage"],
                    "causally_used_intermediate_lemmas": llm_result["causally_used_intermediate_lemmas"],
                    "retrieved_count": len(retrieved), "proof_result": llm_result,
                    "pool_path": str(pool.path),
                }
            all_results.append(result)
            write_json(property_dir / "configuration_result.json", result)
    payload = {
        "schema": "rtl2lean-evaluation-pool-configuration-v1",
        "name": name, "shared_pool": shared, "order_rule": order_rule,
        "results": all_results, "retrieval_events": retrieval_events,
        "metrics": {
            "targets": len(all_results), "solved": sum(item["status"] == "PASS" for item in all_results),
            "llm_calls": sum(item["llm_calls"] for item in all_results),
            "repair_rounds": sum(item["repair_rounds"] for item in all_results),
            "new_lemmas": sum(item["new_lemmas"] for item in all_results),
            "proof_time_s": sum(item["proof_time_s"] for item in all_results),
            "lean_time_s": sum(item["lean_time_s"] for item in all_results),
            "retrieval_time_s": sum(item["retrieval_time_s"] for item in retrieval_events),
            "elapsed_s": time.perf_counter() - started,
        },
    }
    write_json(config_root / "summary.json", payload)
    return payload


def run_intermediate_ablation(
    benchmarks: list[Benchmark], corpus: dict[str, Any], baseline: dict[str, Any],
    assisted: dict[str, Any], output_root: Path, requirement_root: Path,
    provider_options: dict[str, Any],
    run_label: str = "official_run1",
) -> dict[str, Any]:
    properties = {(item["dut"], item["property_id"]): item for item in corpus["properties"]}
    baseline_map = {(item["dut"], item["property_id"]): item for item in baseline["results"]}
    assisted_map = {(item["dut"], item["property_id"]): item for item in assisted["results"]}
    rows = []
    for benchmark in benchmarks:
        for key, base in baseline_map.items():
            if key[0] != benchmark.design_id or base["status"] != "BASE_FAILED":
                continue
            prop = properties[key]
            with_intermediate = assisted_map[key]
            if not with_intermediate.get("proof_result", {}).get("target_kernel_pass"):
                rows.append({"dut": benchmark.design_id, "target": key[1], "baseline": "FAIL",
                             "llm_no_intermediate": "NOT_RUN", "llm_with_intermediate": "FAIL",
                             "remove_lemma": "NOT_RUN", "restore_lemma": "NOT_RUN", "causal": False})
                continue
            arm_root = (requirement_root / "llm" / "ablation_attempts" / run_label /
                        benchmark.slug / key[1])
            empty_path = arm_root / "task_pool.json"
            write_json(empty_path, {"schema": PersistentLocalLemmaPool.SCHEMA, "dut": benchmark.design_id,
                                    "lemmas": [], "metrics": {"verified_lemmas": 0,
                                    "actual_reused_lemmas": 0, "actual_reuse_hits": 0}})
            task_pool = PersistentLocalLemmaPool(empty_path, benchmark.design_id)
            task = _task(benchmark, prop, output_root, arm_root, task_pool, base, [])
            direct = run_direct_without_intermediate(
                task, benchmark, output_root / benchmark.slug / "model", arm_root / "direct_no_intermediate",
                CodexCLIProvider(workdir=Path(__file__).resolve().parents[2], **provider_options),
            )
            usage = with_intermediate["proof_result"].get("intermediate_lemma_usage", [])
            remove_fails = bool(usage) and all(not item["ablation_check"]["success"] for item in usage)

            # Configuration 3: replay the exact successful final proof after restoring
            # the verified intermediate environment.
            source_pool_path = Path(with_intermediate["pool_path"])
            restored_pool = PersistentLocalLemmaPool(source_pool_path, benchmark.design_id)
            final = with_intermediate["proof_result"]["final_candidate"]
            candidate = StructuredCandidate(**final)
            restore = _autonomous_kernel_check(
                candidate, task, restored_pool, output_root / benchmark.slug / "model",
                arm_root / "restore" / "restored_exact_proof.lean", find_lean(),
                omitted_pool_lemma=task.target_name,
            )
            strict_causal = (base["status"] == "BASE_FAILED" and not direct["target_kernel_pass"]
                             and with_intermediate["status"] == "PASS")
            exact_necessary = with_intermediate["status"] == "PASS" and remove_fails and restore["success"]
            rows.append({
                "dut": benchmark.design_id, "target": key[1], "baseline": "FAIL",
                "llm_no_intermediate": "PASS" if direct["target_kernel_pass"] else "FAIL",
                "llm_with_intermediate": with_intermediate["status"],
                "verified_intermediate_lemmas": with_intermediate.get("verified_intermediate_lemmas", []),
                "remove_lemma": "FAIL" if remove_fails else "PASS",
                "restore_lemma": "PASS" if restore["success"] else "FAIL",
                "intermediate_lemma_causally_helpful_three_arm": strict_causal,
                "exact_successful_proof_lemma_causally_required": exact_necessary,
                "direct_result": direct, "restore_check": restore,
            })
    payload = {
        "schema": "rtl2lean-evaluation-intermediate-ablation-v1", "rows": rows,
        "metrics": {
            "N_LLM_SOLVED": sum(item["llm_with_intermediate"] == "PASS" for item in rows),
            "N_LEMMA_REQUIRED": sum(item.get("exact_successful_proof_lemma_causally_required", False) for item in rows),
            "N_LEMMA_NOT_REQUIRED": sum(item["llm_with_intermediate"] == "PASS" and
                                        not item.get("exact_successful_proof_lemma_causally_required", False)
                                        for item in rows),
            "N_THREE_ARM_CAUSAL": sum(item.get("intermediate_lemma_causally_helpful_three_arm", False)
                                      for item in rows),
        },
    }
    solved = payload["metrics"]["N_LLM_SOLVED"]
    payload["metrics"]["LEMMA_CAUSAL_RATE"] = (
        payload["metrics"]["N_LEMMA_REQUIRED"] / solved if solved else 0.0
    )
    artifact_name = ("lemma_ablation.json" if run_label == "official_run1"
                     else f"lemma_ablation_{run_label}.json")
    write_json(requirement_root / "llm" / artifact_name, payload)
    intermediate_name = ("intermediate_lemmas.json" if run_label == "official_run1"
                         else f"intermediate_lemmas_{run_label}.json")
    write_json(requirement_root / "llm" / intermediate_name, {
        "lemmas": [{"dut": row["dut"], "target": row["target"],
                    "lemmas": row.get("verified_intermediate_lemmas", [])} for row in rows],
    })
    return payload


def summarize_assisted(assisted: dict[str, Any], requirement_root: Path) -> dict[str, Any]:
    results = assisted["results"]
    payload = {
        "schema": "rtl2lean-evaluation-assisted-results-v1", "configuration": assisted["name"],
        "results": results,
        "metrics": {
            "TARGETS": len(results), "LLM_TRIGGERED": sum(item["method"] == "LLM_WITH_INTERMEDIATE" for item in results),
            "LLM_SOLVED": sum(item["method"] == "LLM_WITH_INTERMEDIATE" and item["status"] == "PASS" for item in results),
            "LLM_UNSOLVED": sum(item["method"] == "LLM_WITH_INTERMEDIATE" and item["status"] != "PASS" for item in results),
            "LLM_CALLS": sum(item["llm_calls"] for item in results),
            "REPAIR_ROUNDS": sum(item["repair_rounds"] for item in results),
            "VERIFIED_INTERMEDIATE_LEMMAS": sum(item["new_lemmas"] for item in results),
        },
    }
    write_json(requirement_root / "llm" / "assisted_results.json", payload)
    return payload


def run_reuse_audit(
    official: dict[str, Any], benchmarks: list[Benchmark], corpus: dict[str, Any],
    baseline: dict[str, Any], output_root: Path, requirement_root: Path,
) -> dict[str, Any]:
    """Audit retrieval/use/causality without equating any two funnel levels."""
    property_map = {(item["dut"], item["property_id"]): item for item in corpus["properties"]}
    baseline_map = {(item["dut"], item["property_id"]): item for item in baseline["results"]}
    benchmark_map = {item.design_id: item for item in benchmarks}
    retrieval = official["retrieval_events"]
    used = []
    causal = []
    for result in official["results"]:
        key = (result["dut"], result["property_id"])
        for event in result.get("actual_reuse", []):
            proof = result.get("proof") or ""
            record = {
                "dut": result["dut"], "source_property": event["source_target"],
                "source_lemma": event["lemma"], "target_property": result["property_id"],
                "retrieval_rank": next((row["rank"] for retrieval_event in retrieval
                                        if retrieval_event["dut"] == result["dut"]
                                        and retrieval_event["property_id"] == result["property_id"]
                                        for row in retrieval_event["retrieved"]
                                        if row["lemma"] == event["lemma"]), None),
                "retrieval_score": next((row["retrieval_score"] for retrieval_event in retrieval
                                         if retrieval_event["dut"] == result["dut"]
                                         and retrieval_event["property_id"] == result["property_id"]
                                         for row in retrieval_event["retrieved"]
                                         if row["lemma"] == event["lemma"]), None),
                "proof_position": proof.find(event["lemma"]),
                "proof_dependency": "syntactic reference confirmed by Lean deletion ablation",
                "reuse_result": "ACTUALLY_USED",
                "without_lemma": event["ablation_check"],
            }
            used.append(record)
            benchmark = benchmark_map[result["dut"]]
            prop = property_map[key]
            pool_path = requirement_root / "runs" / official["name"] / benchmark.slug / "shared_pool.json"
            pool = PersistentLocalLemmaPool(pool_path, benchmark.design_id)
            task = _task(benchmark, prop, output_root,
                         requirement_root / "reuse" / "restore_attempts" / benchmark.slug / prop["property_id"],
                         pool, baseline_map[key], [])
            final = result.get("proof_result", {}).get("final_candidate")
            restore = {"success": False, "stderr": "missing final candidate"}
            if final:
                restore = _autonomous_kernel_check(
                    StructuredCandidate(**final), task, pool, output_root / benchmark.slug / "model",
                    requirement_root / "reuse" / "restore_attempts" / benchmark.slug /
                    prop["property_id"] / f"restore_{event['lemma']}.lean", find_lean(),
                    omitted_pool_lemma=task.target_name,
                )
            required = not event["ablation_check"]["success"] and restore["success"]
            causal.append({**record, "restore": restore,
                           "reuse_result": "CAUSALLY_REQUIRED" if required else "USED_BUT_NOT_REQUIRED",
                           "causally_required": required})

    available = sum(item["available"] for item in retrieval)
    retrieved_count = sum(len(item["retrieved"]) for item in retrieval)
    metrics = {
        "REUSE_AVAILABLE": available, "REUSE_RETRIEVED": retrieved_count,
        "REUSE_USED": len(used),
        "REUSE_CAUSALLY_REQUIRED": sum(item["causally_required"] for item in causal),
        "RETRIEVAL_RATE": retrieved_count / available if available else 0.0,
        "ACTUAL_USE_RATE": len(used) / retrieved_count if retrieved_count else 0.0,
        "CAUSAL_REUSE_RATE": sum(item["causally_required"] for item in causal) / len(used) if used else 0.0,
    }
    write_json(requirement_root / "reuse" / "retrieval.json", {
        "schema": "rtl2lean-evaluation-retrieval-v1", "events": retrieval,
        "warning": "retrieval is not counted as proof use", "metrics": metrics,
    })
    write_json(requirement_root / "reuse" / "actual_use.json", {
        "schema": "rtl2lean-evaluation-actual-use-v1", "events": used,
    })
    write_json(requirement_root / "reuse" / "causal_reuse.json", {
        "schema": "rtl2lean-evaluation-causal-reuse-v1", "events": causal, "metrics": metrics,
    })

    relation_rows = []
    for relation in ("CORE_RELATED", "RELATED", "CONTROL_UNRELATED"):
        target_keys = {(item["dut"], item["property_id"]) for item in corpus["properties"]
                       if item.get("semantic_relatedness") == relation}
        rel_retrieval = [item for item in retrieval if (item["dut"], item["property_id"]) in target_keys]
        rel_used = [item for item in used if (item["dut"], item["target_property"]) in target_keys]
        rel_causal = [item for item in causal if (item["dut"], item["target_property"]) in target_keys
                      and item["causally_required"]]
        rel_available = sum(item["available"] for item in rel_retrieval)
        rel_retrieved = sum(len(item["retrieved"]) for item in rel_retrieval)
        relation_rows.append({
            "category": relation, "targets": len(target_keys), "available": rel_available,
            "retrieved": rel_retrieved, "actually_used": len(rel_used),
            "causally_required": len(rel_causal),
            "retrieval_rate": rel_retrieved / rel_available if rel_available else 0.0,
            "actual_use_rate": len(rel_used) / rel_retrieved if rel_retrieved else 0.0,
            "causal_reuse_rate": len(rel_causal) / len(rel_used) if rel_used else 0.0,
            # The funnel rates above answer whether retrieved/used lemmas survive
            # each later stage.  Per-target rates are the appropriate denominator
            # for comparing how often a property category benefits at all.
            "actual_use_target_rate": len(rel_used) / len(target_keys) if target_keys else 0.0,
            "causal_use_target_rate": len(rel_causal) / len(target_keys) if target_keys else 0.0,
            "proof_success": sum(item["status"] == "PASS" and
                                 (item["dut"], item["property_id"]) in target_keys
                                 for item in official["results"]),
            "llm_calls": sum(item["llm_calls"] for item in official["results"]
                             if (item["dut"], item["property_id"]) in target_keys),
        })
    relatedness = {"schema": "rtl2lean-evaluation-relatedness-v1", "rows": relation_rows}
    write_json(requirement_root / "reuse" / "relatedness.json", relatedness)
    return {"metrics": metrics, "retrieval": retrieval, "used": used,
            "causal": causal, "relatedness": relation_rows}


def compile_configuration_bundles(
    config: dict[str, Any], benchmarks: list[Benchmark], output_root: Path,
    requirement_root: Path,
) -> list[dict[str, Any]]:
    """Recheck each shared configuration as one complete Lean theorem library."""
    checks = []
    for benchmark in benchmarks:
        pool_path = requirement_root / "runs" / config["name"] / benchmark.slug / "shared_pool.json"
        targets: list[tuple[Path, str | None]] = []
        if pool_path.is_file():
            targets.append((pool_path, None))
        else:
            for result in config["results"]:
                if (result["dut"] == benchmark.design_id
                        and result["method"] == "LLM_WITH_INTERMEDIATE"
                        and result["status"] == "PASS"):
                    targets.append((Path(result["pool_path"]), result["property_id"]))
        for index, (current_pool_path, property_id) in enumerate(targets):
            pool = PersistentLocalLemmaPool(current_pool_path, benchmark.design_id)
            filename = ("OfficialTheorems.lean" if property_id is None
                        else f"FreshOfficialTheorems_{index:03d}.lean")
            path = requirement_root / "runs" / config["name"] / benchmark.slug / filename
            lines = ["import R2Framework", "", "set_option maxRecDepth 100000",
                     "set_option maxHeartbeats 8000000", "",
                     f"namespace {benchmark.top_module}Verification", f"open {benchmark.top_module}", ""]
            lines.extend(f"theorem {lemma.name} : {lemma.proposition} := {lemma.proof_body}\n"
                         for lemma in pool.lemmas)
            lines.extend([f"end {benchmark.top_module}Verification", ""])
            path.write_text("\n".join(lines), encoding="utf-8")
            check = _lean_check(path, output_root / benchmark.slug / "model", timeout_s=1200)
            check.update({"dut": benchmark.design_id, "configuration": config["name"],
                          "property_id": property_id, "source": str(path)})
            check_name = ("official_theorems_check.json" if property_id is None
                          else f"fresh_official_theorems_check_{index:03d}.json")
            write_json(path.with_name(check_name), check)
            checks.append(check)
    return checks
