"""Audited temporal validation, baseline, and three-arm proof experiment."""
from __future__ import annotations

import json
import re
import time
from dataclasses import asdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from rtl2lean.evaluation.experiment import _lean_check, run_direct_without_intermediate
from rtl2lean.pipeline.io import sha256, write_json
from rtl2lean.pipeline.manifest import Benchmark
from rtl2lean.proving.llm_prover import (
    AutonomousProofTask,
    CodexCLIProvider,
    PersistentLocalLemmaPool,
    ProvingBudget,
    run_budgeted_proof_search,
)


GENERIC_BASELINE_PROOFS = (
    "by rfl",
    "by simp",
    "by simp_all",
    "by grind",
    "by intros <;> simp_all",
    "by intros <;> grind",
)

LEMMA_FIRST_BUDGET = ProvingBudget(
    max_generation_rounds=3,
    max_repair_rounds_per_candidate=1,
    max_intermediate_lemmas=3,
    max_llm_calls=8,
)


def _read(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8")) if path.is_file() else {}


def _source(benchmark: Benchmark, prop: dict[str, Any], declaration: str) -> str:
    return "\n".join([
        "import R3Foundation", "", "set_option maxRecDepth 100000",
        "set_option maxHeartbeats 8000000", "",
        f"namespace {benchmark.top_module}Verification",
        f"open {benchmark.top_module}", "", declaration, "",
        f"end {benchmark.top_module}Verification", "",
    ])


def _statement_source(benchmark: Benchmark, prop: dict[str, Any]) -> str:
    return _source(
        benchmark, prop,
        f"def {prop['property_id']}__statement : Prop := {prop['theorem_statement']}",
    )


def _proof_source(benchmark: Benchmark, prop: dict[str, Any], proof: str) -> str:
    return _source(
        benchmark, prop,
        f"theorem {prop['property_id']} : {prop['theorem_statement']} := {proof}",
    )


def validate_and_freeze_corpus(
    benchmarks: list[Benchmark], corpus: dict[str, Any], output_root: Path,
    requirement_root: Path,
) -> dict[str, Any]:
    """Validate unchanged statements and reference certificates before baseline."""
    benchmark_map = {item.design_id: item for item in benchmarks}
    rows: list[dict[str, Any]] = []
    accepted: list[dict[str, Any]] = []
    validation_root = requirement_root / "corpus" / "property_validation"
    for index, prop in enumerate(corpus["properties"]):
        benchmark = benchmark_map[prop["dut"]]
        target_root = validation_root / benchmark.slug / f"{index:03d}_{prop['property_id']}"
        target_root.mkdir(parents=True, exist_ok=True)
        statement_path = (target_root / "statement.lean").resolve()
        statement_path.write_text(_statement_source(benchmark, prop), encoding="utf-8")
        statement_check = _lean_check(statement_path, output_root / benchmark.slug / "model", 300)
        reference_check = None
        if statement_check["success"] and prop.get("proof_candidates"):
            reference_path = (target_root / "reference_proof.lean").resolve()
            reference_path.write_text(
                _proof_source(benchmark, prop, prop["proof_candidates"][0]), encoding="utf-8",
            )
            reference_check = _lean_check(reference_path, output_root / benchmark.slug / "model", 600)
        valid = bool(statement_check["success"] and reference_check and reference_check["success"])
        row = {
            "dut": prop["dut"], "property_id": prop["property_id"],
            "statement_check": statement_check, "reference_proof_check": reference_check,
            "statement_unchanged": True, "accepted": valid,
        }
        rows.append(row)
        checked = dict(prop)
        checked["validation_status"] = "KERNEL_VALIDATED" if valid else "REJECTED_BEFORE_FREEZE"
        if valid:
            accepted.append(checked)
        else:
            checked["rejection_reason"] = "ILL_TYPED_STATEMENT" if not statement_check["success"] else "REFERENCE_CERTIFICATE_REJECTED"
            rejection_path = requirement_root / "corpus" / "validation_rejections.json"
            existing = _read(rejection_path).get("properties", [])
            write_json(rejection_path, {"properties": [*existing, checked]})

    if len(accepted) != len(corpus["properties"]):
        # Fail closed: invalid generated targets are preserved as rejections and
        # never mislabeled as baseline/LLM proof failures.
        corpus = {**corpus, "properties": accepted}
    corpus["frozen_before_baseline"] = True
    corpus["freeze_status"] = "FROZEN_AFTER_KERNEL_VALIDATION"
    corpus["freeze_time"] = datetime.now(timezone.utc).isoformat()
    corpus["metrics"] = {
        **corpus.get("metrics", {}),
        "N_FINAL": len(accepted),
        "N_VALIDATED": len(accepted),
        "N_VALIDATION_REJECTED": len(rows) - len(accepted),
        "N_SINGLE_CYCLE": sum(x["property_level"] == "SINGLE_CYCLE" for x in accepted),
        "N_TRACE_BRIDGE": sum(x["property_level"] == "TRACE_BRIDGE" for x in accepted),
        "N_TRUE_MULTI_CYCLE": sum(x["semantic_multi_cycle"] for x in accepted),
    }
    corpus_path = requirement_root / "corpus" / "final_properties.json"
    write_json(corpus_path, corpus)
    freeze = {
        "schema": "rtl2lean-temporal-property-freeze-v1",
        "frozen_before_baseline": True,
        "property_count": len(accepted),
        "properties": [
            {"dut": item["dut"], "property_id": item["property_id"],
             "statement": item["theorem_statement"]} for item in accepted
        ],
        "validation_rows": rows,
        "final_properties_sha256": sha256(corpus_path),
    }
    write_json(requirement_root / "corpus" / "property_validation.json", {"rows": rows})
    write_json(requirement_root / "corpus" / "freeze.json", freeze)
    return corpus


def _baseline_suite(prop: dict[str, Any]) -> list[str]:
    proofs = list(GENERIC_BASELINE_PROOFS)
    # These two diagnostic layers are allowed to invoke the pre-frozen local or
    # trace foundation directly.  True temporal targets deliberately receive
    # no generator-owned reference certificate.
    if prop["property_level"] in {"SINGLE_CYCLE", "TRACE_BRIDGE"}:
        proofs.extend(prop.get("proof_candidates", []))
    return list(dict.fromkeys(proofs))


def _failure_kind(attempts: list[dict[str, Any]]) -> str | None:
    if any(item.get("returncode") == 124 for item in attempts):
        return "LEAN_TIMEOUT"
    text = "\n".join(item.get("stdout", "") + item.get("stderr", "") for item in attempts)
    if "maximum heartbeats" in text:
        return "HEARTBEAT_EXHAUSTED"
    if "unsolved goals" in text or "failed" in text:
        return "TACTIC_INCOMPLETE"
    return "LEAN_REJECTED" if attempts else None


def run_baseline(
    benchmarks: list[Benchmark], corpus: dict[str, Any], output_root: Path,
    requirement_root: Path,
) -> dict[str, Any]:
    freeze = _read(requirement_root / "corpus" / "freeze.json")
    if not freeze.get("frozen_before_baseline"):
        raise RuntimeError("temporal property corpus was not frozen before baseline")
    capability = {
        "schema": "rtl2lean-temporal-baseline-capability-v1",
        "frozen_before_results": True,
        "no_llm": True, "no_llm_generated_lemma": True,
        "generic_tactics": list(GENERIC_BASELINE_PROOFS),
        "pre_frozen_foundation": [
            "List induction", "Reachable induction", "run append/decomposition",
            "reachable-to-trace", "generic Along/Eventually/BoundedEventually/Until/Obeys lemmas",
            "kernel-validated IR local transition lemmas",
        ],
        "layer_policy": (
            "SINGLE_CYCLE and TRACE_BRIDGE may use their pre-frozen foundation certificate; "
            "TRUE_MULTI_CYCLE uses only the uniform generic tactic suite"
        ),
        "reference_certificate_is_not_a_true_multicycle_baseline_candidate": True,
        "property_freeze_sha256": freeze["final_properties_sha256"],
    }
    write_json(requirement_root / "baseline" / "baseline_capability.json", capability)

    benchmark_map = {item.design_id: item for item in benchmarks}
    results = []
    started = time.perf_counter()
    for index, prop in enumerate(corpus["properties"]):
        benchmark = benchmark_map[prop["dut"]]
        target_root = requirement_root / "baseline" / "attempts" / benchmark.slug / f"{index:03d}_{prop['property_id']}"
        target_root.mkdir(parents=True, exist_ok=True)
        attempts = []
        solved = None
        for attempt_index, proof in enumerate(_baseline_suite(prop)):
            path = (target_root / f"attempt_{attempt_index:02d}.lean").resolve()
            path.write_text(_proof_source(benchmark, prop, proof), encoding="utf-8")
            check = _lean_check(path, output_root / benchmark.slug / "model", 180)
            attempts.append({"proof": proof, "proof_steps": max(1, proof.count("\n") + 1), **check})
            if check["success"]:
                solved = proof
                break
        result = {
            "dut": prop["dut"], "property_id": prop["property_id"],
            "property_level": prop["property_level"], "property_family": prop["property_family"],
            "tags": prop["tags"], "status": "BASE_SOLVED" if solved else "BASE_FAILED",
            "proof": solved, "attempts": attempts,
            "failure_kind": None if solved else _failure_kind(attempts),
            "proof_time_s": sum(item["elapsed_s"] for item in attempts),
            "Te2e": sum(item["elapsed_s"] for item in attempts),
            "lean_time_s": sum(item["elapsed_s"] for item in attempts),
            "proof_steps": max(1, solved.count("\n") + 1) if solved else None,
            "theorem_statement_sha256": __import__("hashlib").sha256(prop["theorem_statement"].encode()).hexdigest(),
        }
        write_json(target_root / "result.json", result)
        results.append(result)
    elapsed = time.perf_counter() - started
    payload = {
        "schema": "rtl2lean-temporal-baseline-results-v1",
        "results": results,
        "metrics": {
            "TARGETS": len(results),
            "BASE_SOLVED": sum(x["status"] == "BASE_SOLVED" for x in results),
            "BASE_FAILED": sum(x["status"] == "BASE_FAILED" for x in results),
            "TLean": sum(x["lean_time_s"] for x in results),
            "Te2e": elapsed, "elapsed_s": elapsed,
        },
        "property_freeze_sha256": freeze["final_properties_sha256"],
        "capability": capability,
    }
    write_json(requirement_root / "baseline" / "baseline_results.json", payload)
    write_json(requirement_root / "baseline" / "selected_targets.json", {
        "selection_rule": "all BASE_FAILED from the frozen corpus",
        "targets": [
            {"dut": x["dut"], "property_id": x["property_id"], "status": x["status"]}
            for x in results if x["status"] == "BASE_FAILED"
        ],
    })
    return payload


def _declaration_block(source: str, name: str) -> str:
    pattern = re.compile(
        rf"(?ms)^(?:def|theorem|abbrev)\s+{re.escape(name)}\b.*?(?=\n\n(?:def|theorem|abbrev|end)\b|\Z)"
    )
    match = pattern.search(source)
    return match.group(0).strip() if match else f"-- declaration {name} is imported from R3Foundation"


def _task(
    benchmark: Benchmark, prop: dict[str, Any], base: dict[str, Any], output_root: Path,
    future: list[dict[str, Any]],
) -> AutonomousProofTask:
    base_source = (output_root / benchmark.slug / "model" / "R3Base.lean").read_text(encoding="utf-8")
    foundation_source = (output_root / benchmark.slug / "model" / "R3Foundation.lean").read_text(encoding="utf-8")
    names = ["r3Step", "r3Run", *prop.get("foundation_lemmas", [])]
    snippets = [base_source, *(_declaration_block(foundation_source, name) for name in names)]
    errors = "\n".join(
        (item.get("stdout", "") + item.get("stderr", ""))[-3000:]
        for item in base["attempts"] if not item["success"]
    )[-10000:]
    assumptions = [
        *prop.get("environment_assumptions", []),
        *prop.get("protocol_assumptions", []),
        *prop.get("reset_assumptions", []),
    ]
    relevant = [
        _declaration_block(foundation_source, name).split(":= by", 1)[0]
        for name in prop.get("foundation_lemmas", [])
    ]
    return AutonomousProofTask(
        dut=benchmark.design_id, target_name=prop["property_id"],
        target_statement=prop["theorem_statement"], property_type=prop["property_family"],
        state_type=f"{benchmark.top_module}State",
        required_state_fields=list(prop.get("referenced_state_fields", [])),
        required_input_fields=list(prop.get("referenced_inputs", [])), assumptions=assumptions,
        context_import="R3Foundation", context_snippets=snippets,
        relevant_foundational_lemmas=relevant, base_lean_error=errors,
        future_targets=[{"name": x["property_id"], "statement": x["theorem_statement"]} for x in future[:3]],
    )


def run_direct(
    benchmarks: list[Benchmark], corpus: dict[str, Any], baseline: dict[str, Any],
    output_root: Path, requirement_root: Path, provider_options: dict[str, Any],
    resume: bool = False,
) -> dict[str, Any]:
    benchmark_map = {x.design_id: x for x in benchmarks}
    properties = {(x["dut"], x["property_id"]): x for x in corpus["properties"]}
    failed = [x for x in baseline["results"] if x["status"] == "BASE_FAILED"]
    results = []
    started = time.perf_counter()
    provider = CodexCLIProvider(workdir=Path(__file__).resolve().parents[2], **provider_options)
    if not provider.available and failed:
        raise RuntimeError("Codex CLI provider unavailable for temporal Direct arm")
    for index, base in enumerate(failed):
        prop = properties[(base["dut"], base["property_id"])]
        benchmark = benchmark_map[base["dut"]]
        target_root = requirement_root / "direct_llm" / "targets" / benchmark.slug / f"{index:03d}_{prop['property_id']}"
        saved = target_root / "result.json"
        if resume and saved.is_file():
            prior = _read(saved)
            history = prior.get("proof_result", {}).get("history", [])
            # Provider-only failures are infrastructure failures, not terminal
            # proof outcomes, and must be retried on resume.
            if any(item.get("status") != "PROVIDER_FAILURE" for item in history):
                results.append(prior)
                continue
        future = [properties[(x["dut"], x["property_id"])] for x in failed[index + 1:] if x["dut"] == base["dut"]]
        task = _task(benchmark, prop, base, output_root, future)
        proof = run_direct_without_intermediate(
            task, benchmark, output_root / benchmark.slug / "model", target_root / "proof",
            provider, budget_calls=3,
        )
        result = {
            "dut": base["dut"], "property_id": prop["property_id"],
            "property_level": prop["property_level"], "property_family": prop["property_family"],
            "tags": prop["tags"], "status": "DIRECT_SOLVED" if proof["target_kernel_pass"] else "DIRECT_FAILED",
            "target_kernel_pass": proof["target_kernel_pass"], "final_proof": proof.get("final_proof"),
            "llm_calls": proof["llm_calls"], "repair_rounds": max(0, proof["llm_calls"] - 1),
            "llm_time_s": proof["llm_time_s"], "lean_time_s": proof["lean_time_s"],
            "elapsed_s": proof["llm_time_s"] + proof["lean_time_s"],
            "Te2e": proof["llm_time_s"] + proof["lean_time_s"],
            "new_intermediate_lemmas": 0, "proof_result": proof,
            "theorem_statement": prop["theorem_statement"],
        }
        write_json(saved, result)
        results.append(result)
    elapsed = time.perf_counter() - started
    payload = {
        "schema": "rtl2lean-temporal-direct-results-v1", "results": results,
        "metrics": {
            "TARGETS": len(results), "DIRECT_SOLVED": sum(x["status"] == "DIRECT_SOLVED" for x in results),
            "DIRECT_FAILED": sum(x["status"] == "DIRECT_FAILED" for x in results),
            "LLM_CALLS": sum(x["llm_calls"] for x in results),
            "TLean": sum(x["lean_time_s"] for x in results),
            "TLLM": sum(x["llm_time_s"] for x in results),
            "Te2e": elapsed, "elapsed_s": elapsed,
        },
    }
    write_json(requirement_root / "direct_llm" / "results.json", payload)
    return payload


def _normalize_statement(value: str) -> str:
    return re.sub(r"\s+", "", value).replace("(", "").replace(")", "")


def _foundation_statements(output_root: Path, benchmark: Benchmark) -> list[dict[str, str]]:
    text = "\n".join([
        (output_root / benchmark.slug / "model" / "R3Base.lean").read_text(encoding="utf-8"),
        (output_root / benchmark.slug / "model" / "R3Foundation.lean").read_text(encoding="utf-8"),
    ])
    rows = []
    for match in re.finditer(r"(?ms)^theorem\s+([A-Za-z_][A-Za-z0-9_']*)\s*:\s*(.*?)\s*:=\s*by", text):
        rows.append({"name": match.group(1), "statement": match.group(2).strip()})
    return rows


def _novelty(
    lemma: dict[str, Any], prop: dict[str, Any], foundation: list[dict[str, str]],
) -> dict[str, Any]:
    statement = lemma.get("proposition") or lemma.get("statement", "")
    normalized = _normalize_statement(statement)
    alpha_matches = [x["name"] for x in foundation if _normalize_statement(x["statement"]) == normalized]
    target_equal = normalized == _normalize_statement(prop["theorem_statement"])
    fields = prop.get("referenced_state_fields", [])
    target_specific = any(field in statement for field in fields) or prop["property_id"] in statement
    trivial_specialization = bool(alpha_matches or target_equal)
    return {
        "dut": prop["dut"], "target": prop["property_id"], "lemma": lemma.get("name"),
        "statement": statement,
        "alpha_equivalent_to_foundation": bool(alpha_matches),
        "alpha_equivalent_foundation_matches": alpha_matches,
        "trivial_specialization": trivial_specialization,
        "already_in_initial_pool": False,
        "target_specific": target_specific,
        "semantic_novelty": not trivial_specialization,
        "novelty_method": "whitespace/parenthesis-normalized exact proposition comparison; target equality rejection",
    }


def run_lemma_first(
    benchmarks: list[Benchmark], corpus: dict[str, Any], baseline: dict[str, Any],
    direct: dict[str, Any], output_root: Path, requirement_root: Path,
    provider_options: dict[str, Any], resume: bool = False,
) -> dict[str, Any]:
    benchmark_map = {x.design_id: x for x in benchmarks}
    properties = {(x["dut"], x["property_id"]): x for x in corpus["properties"]}
    direct_map = {(x["dut"], x["property_id"]): x for x in direct["results"]}
    failed = [x for x in baseline["results"] if x["status"] == "BASE_FAILED"]
    results, intermediate, novelty, causal = [], [], [], []
    started = time.perf_counter()
    provider = CodexCLIProvider(workdir=Path(__file__).resolve().parents[2], **provider_options)
    if not provider.available and failed:
        raise RuntimeError("Codex CLI provider unavailable for temporal Lemma-First arm")
    for index, base in enumerate(failed):
        prop = properties[(base["dut"], base["property_id"])]
        benchmark = benchmark_map[base["dut"]]
        target_root = requirement_root / "lemma_first" / "targets" / benchmark.slug / f"{index:03d}_{prop['property_id']}"
        saved = target_root / "result.json"
        if resume and saved.is_file():
            result = _read(saved)
            results.append(result)
            intermediate.extend(result.get("intermediate_lemmas", []))
            novelty.extend(result.get("lemma_novelty", []))
            causal.append(result["causal_row"])
            continue
        pool_path = target_root / "initial_empty_pool.json"
        write_json(pool_path, {
            "schema": PersistentLocalLemmaPool.SCHEMA, "dut": benchmark.design_id,
            "lemmas": [], "metrics": {"verified_lemmas": 0, "actual_reused_lemmas": 0, "actual_reuse_hits": 0},
        })
        pool = PersistentLocalLemmaPool(pool_path, benchmark.design_id)
        future = [properties[(x["dut"], x["property_id"])] for x in failed[index + 1:] if x["dut"] == base["dut"]]
        task = _task(benchmark, prop, base, output_root, future)
        proof = run_budgeted_proof_search(
            task, provider, pool, output_root / benchmark.slug / "model", target_root / "proof",
            LEMMA_FIRST_BUDGET, allow_pool_first=False,
        )
        lemmas = [asdict(x) for x in pool.lemmas if x.origin == "llm" and x.source_target == prop["property_id"]]
        # The final target is inserted with origin llm-target and is excluded.
        foundation = _foundation_statements(output_root, benchmark)
        novelty_rows = [_novelty(x, prop, foundation) for x in lemmas]
        direct_result = direct_map[(base["dut"], prop["property_id"])]
        usage = proof.get("intermediate_lemma_usage", [])
        exact_required = any(x.get("causally_necessary") for x in usage)
        three_arm = (
            base["status"] == "BASE_FAILED"
            and direct_result["status"] == "DIRECT_FAILED"
            and proof["target_kernel_pass"]
        )
        causal_row = {
            "dut": base["dut"], "property_id": prop["property_id"],
            "arm_A_baseline": "FAIL", "arm_B_direct": direct_result["status"],
            "arm_C_lemma_first": "LEMMA_FIRST_SOLVED" if proof["target_kernel_pass"] else "LEMMA_FIRST_FAILED",
            "same_theorem_statement": direct_result["theorem_statement"] == prop["theorem_statement"],
            "same_initial_foundation": True, "initial_pool_empty": True,
            "intermediate_lemma_causally_helpful": three_arm,
            "exact_successful_proof_lemma_causally_required": exact_required,
            "deletion_checks": usage,
        }
        result = {
            "dut": base["dut"], "property_id": prop["property_id"],
            "property_level": prop["property_level"], "property_family": prop["property_family"],
            "tags": prop["tags"],
            "status": "LEMMA_FIRST_SOLVED" if proof["target_kernel_pass"] else "LEMMA_FIRST_FAILED",
            "target_kernel_pass": proof["target_kernel_pass"], "final_proof": proof.get("final_proof"),
            "llm_calls": proof["total_llm_calls"], "repair_rounds": proof["repair_rounds_used"],
            "llm_time_s": proof["llm_time_s"], "lean_time_s": proof["lean_time_s"],
            "elapsed_s": proof["llm_time_s"] + proof["lean_time_s"],
            "Te2e": proof["llm_time_s"] + proof["lean_time_s"],
            "intermediate_lemmas": lemmas, "lemma_novelty": novelty_rows,
            "causal_row": causal_row, "proof_result": proof,
            "theorem_statement": prop["theorem_statement"],
        }
        write_json(saved, result)
        results.append(result)
        intermediate.extend(lemmas); novelty.extend(novelty_rows); causal.append(causal_row)
    elapsed = time.perf_counter() - started
    payload = {
        "schema": "rtl2lean-temporal-lemma-first-results-v1", "results": results,
        "metrics": {
            "TARGETS": len(results),
            "LEMMA_FIRST_SOLVED": sum(x["status"] == "LEMMA_FIRST_SOLVED" for x in results),
            "LEMMA_FIRST_FAILED": sum(x["status"] == "LEMMA_FIRST_FAILED" for x in results),
            "VERIFIED_INTERMEDIATE_LEMMAS": len(intermediate),
            "NOVEL_INTERMEDIATE_LEMMAS": sum(x["semantic_novelty"] for x in novelty),
            "THREE_ARM_CAUSALLY_HELPFUL": sum(x["intermediate_lemma_causally_helpful"] for x in causal),
            "EXACT_DELETION_REQUIRED": sum(x["exact_successful_proof_lemma_causally_required"] for x in causal),
            "LLM_CALLS": sum(x["llm_calls"] for x in results),
            "TLean": sum(x["lean_time_s"] for x in results),
            "TLLM": sum(x["llm_time_s"] for x in results),
            "Te2e": elapsed, "elapsed_s": elapsed,
        },
    }
    write_json(requirement_root / "lemma_first" / "results.json", payload)
    write_json(requirement_root / "lemma_first" / "intermediate_lemmas.json", {"lemmas": intermediate})
    write_json(requirement_root / "lemma_first" / "lemma_novelty.json", {"rows": novelty})
    write_json(requirement_root / "lemma_first" / "causal_ablation.json", {"rows": causal})
    return payload
