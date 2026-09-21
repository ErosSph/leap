"""Freeze-first three-arm repeated-trial experiment for compositional_proofs."""
from __future__ import annotations

import hashlib
import json
import re
import statistics
import time
from dataclasses import asdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from rtl2lean.evaluation.experiment import _lean_check, run_direct_without_intermediate
from rtl2lean.pipeline.io import sha256, write_json
from rtl2lean.pipeline.manifest import Benchmark
from rtl2lean.proving.llm_prover import (
    AutonomousProofTask, CodexCLIProvider, PersistentLocalLemmaPool,
    ProvingBudget, run_budgeted_proof_search,
)
from rtl2lean.temporal_challenges.experiment import (
    _context_metrics, _proof_ast_depth, _proof_ast_size,
    _simple_foundation_specialization,
)
from rtl2lean.temporal.experiment import _declaration_block, _failure_kind, _novelty


MAX_LLM_CALLS = 8
MAX_TOTAL_TOKENS = 120_000
MAX_REPAIRS_PER_CANDIDATE = 1
PROVIDER_TIMEOUT_S = 300
LEMMA_BUDGET = ProvingBudget(
    max_generation_rounds=4, max_repair_rounds_per_candidate=MAX_REPAIRS_PER_CANDIDATE,
    max_intermediate_lemmas=3, max_llm_calls=MAX_LLM_CALLS,
    max_total_tokens=MAX_TOTAL_TOKENS,
)
BASELINE_PROOFS = [
    "by rfl", "by simp", "by simp_all", "by grind", "by omega", "by aesop",
    "by intros <;> simp_all", "by intros <;> grind", "by intros <;> aesop",
    "by intros <;> first | assumption | constructor <;> assumption",
]


def _read(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8")) if path.is_file() else {}


def _source(benchmark: Benchmark, declaration: str) -> str:
    return "\n".join([
        "import R5Foundation", "", "set_option maxRecDepth 100000",
        "set_option maxHeartbeats 8000000", "",
        f"namespace {benchmark.top_module}Verification", f"open {benchmark.top_module}",
        "", declaration, "", f"end {benchmark.top_module}Verification", "",
    ])


def _proof_source(benchmark: Benchmark, prop: dict[str, Any], proof: str) -> str:
    return _source(benchmark, f"theorem {prop['property_id']} : {prop['theorem_statement']} := {proof}")


def validate_and_freeze(
    benchmarks: list[Benchmark], generated: dict[str, Any], output_root: Path,
    requirement_root: Path,
) -> dict[str, Any]:
    benchmark_map = {x.design_id: x for x in benchmarks}
    accepted, rows = [], []
    for index, prop in enumerate(generated["properties"]):
        benchmark = benchmark_map[prop["dut"]]
        root = requirement_root / "compositional_hard" / "validation" / benchmark.slug / f"{index:03d}_{prop['property_id']}"
        statement = root / "statement.lean"
        reference = root / "reference_proof.lean"
        statement.parent.mkdir(parents=True, exist_ok=True)
        statement.write_text(_source(benchmark, f"def {prop['property_id']}__statement : Prop := {prop['theorem_statement']}"), encoding="utf-8")
        statement_check = _lean_check(statement, output_root / benchmark.slug / "model", 1200)
        reference.write_text(_proof_source(benchmark, prop, prop["proof_candidates"][0]), encoding="utf-8")
        reference_check = (_lean_check(reference, output_root / benchmark.slug / "model", 1200)
                           if statement_check["success"] else None)
        valid = bool(statement_check["success"] and reference_check and reference_check["success"])
        checked = {**prop, "validation_status": "KERNEL_VALIDATED" if valid else "REJECTED_BEFORE_FREEZE"}
        if valid:
            accepted.append(checked)
        rows.append({"dut": prop["dut"], "property_id": prop["property_id"], "accepted": valid,
                     "statement_check": statement_check, "reference_check": reference_check,
                     "rejection_reason": None if valid else (
                         "ILL_TYPED_STATEMENT" if not statement_check["success"] else "REFERENCE_PROOF_REJECTED"
                     )})
    frozen = {
        **generated, "properties": accepted, "frozen_before_baseline": True,
        "freeze_time": datetime.now(timezone.utc).isoformat(),
        "metrics": {**generated["metrics"], "N_GENERATED": len(generated["properties"]),
                    "N_FINAL": len(accepted),
                    "N_VALIDATION_REJECTED": len(generated["properties"]) - len(accepted),
                    "N_COMPOSITIONAL_HARD": sum(x["property_family"] == "COMPOSITIONAL_HARD" for x in accepted),
                    "N_UNTIL": sum(x["property_family"] == "UNTIL" for x in accepted)},
    }
    final_path = requirement_root / "compositional_hard" / "final_properties.json"
    write_json(final_path, frozen)
    write_json(requirement_root / "compositional_hard" / "validation.json", {"rows": rows})
    write_json(requirement_root / "compositional_hard" / "freeze.json", {
        "schema": "rtl2lean-compositional_proofs-freeze-v1", "frozen_before_baseline": True,
        "property_count": len(accepted), "final_properties_sha256": sha256(final_path),
        "properties": [{"dut": x["dut"], "property_id": x["property_id"],
                        "statement_sha256": hashlib.sha256(x["theorem_statement"].encode()).hexdigest()}
                       for x in accepted],
    })
    write_json(requirement_root / "until" / "results.json", {
        "schema": "rtl2lean-compositional_proofs-until-results-v1",
        "properties": [x for x in accepted if x["property_family"] == "UNTIL"],
        "N": sum(x["property_family"] == "UNTIL" for x in accepted),
    })
    return frozen


def run_baseline(
    benchmarks: list[Benchmark], corpus: dict[str, Any], output_root: Path,
    requirement_root: Path,
) -> dict[str, Any]:
    benchmark_map = {x.design_id: x for x in benchmarks}
    results, started = [], time.perf_counter()
    for index, prop in enumerate(corpus["properties"]):
        benchmark = benchmark_map[prop["dut"]]
        root = requirement_root / "baseline" / "attempts" / benchmark.slug / f"{index:03d}_{prop['property_id']}"
        attempts, solved = [], None
        for attempt_index, proof in enumerate(BASELINE_PROOFS):
            path = root / f"attempt_{attempt_index:02d}.lean"
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(_proof_source(benchmark, prop, proof), encoding="utf-8")
            check = _lean_check(path, output_root / benchmark.slug / "model", 600)
            attempts.append({"proof": proof, **check})
            if check["success"]:
                solved = proof
                break
        results.append({
            "dut": prop["dut"], "property_id": prop["property_id"],
            "property_family": prop["property_family"],
            "status": "BASE_SOLVED" if solved else "BASE_FAILED", "proof": solved,
            "attempts": attempts, "failure_kind": None if solved else _failure_kind(attempts),
            "lean_time_s": sum(x["elapsed_s"] for x in attempts),
            "theorem_statement": prop["theorem_statement"],
            "statement_sha256": hashlib.sha256(prop["theorem_statement"].encode()).hexdigest(),
        })
    payload = {
        "schema": "rtl2lean-compositional_proofs-baseline-v1", "results": results,
        "capability": {"generic_proofs": BASELINE_PROOFS, "imports_temporal_challenges_foundation": True,
                       "no_llm": True, "reference_proofs_hidden": True},
        "metrics": {"TARGETS": len(results),
                    "BASE_SOLVED": sum(x["status"] == "BASE_SOLVED" for x in results),
                    "BASE_FAILED": sum(x["status"] == "BASE_FAILED" for x in results),
                    "TLean": sum(x["lean_time_s"] for x in results),
                    "Te2e": time.perf_counter() - started},
    }
    write_json(requirement_root / "baseline" / "results.json", payload)
    return payload


def _task(
    benchmark: Benchmark, prop: dict[str, Any], base: dict[str, Any], output_root: Path,
) -> AutonomousProofTask:
    model_dir = output_root / benchmark.slug / "model"
    r3_base = (model_dir / "R3Base.lean").read_text(encoding="utf-8")
    r3_foundation = (model_dir / "R3Foundation.lean").read_text(encoding="utf-8")
    r5_foundation = (model_dir / "R5Foundation.lean").read_text(encoding="utf-8")
    combined = r3_foundation + "\n" + r5_foundation
    snippets = [r3_base, r5_foundation, """
compositional_proofs abstraction policy: do not rename run_append, run_cons, List
induction, or an existing L1-L4/foundation theorem. Prefer a phase-entry/exit,
phase-progress, prefix/suffix invariant, wide-state relation, completion bridge,
counter-progress, or cross-clock composition that removes target dependencies.
""".strip()]
    for name in ["r3Step", "r3Run", *prop.get("foundation_lemmas", [])]:
        snippets.append(_declaration_block(combined, name))
    errors = "\n".join(
        (x.get("stdout", "") + x.get("stderr", ""))[-2500:]
        for x in base.get("attempts", []) if not x.get("success")
    )[-12000:]
    relevant = [
        _declaration_block(combined, name).split(":= by", 1)[0]
        for name in prop.get("foundation_lemmas", [])
    ]
    return AutonomousProofTask(
        dut=benchmark.design_id, target_name=prop["property_id"],
        target_statement=prop["theorem_statement"], property_type=prop["property_family"],
        state_type=f"{benchmark.top_module}State",
        required_state_fields=list(prop.get("referenced_state_fields", [])),
        required_input_fields=list(prop.get("referenced_inputs", [])),
        assumptions=[*prop.get("environment_assumptions", []), *prop.get("protocol_assumptions", []),
                     *prop.get("reset_assumptions", [])],
        context_import="R5Foundation", context_snippets=snippets,
        relevant_foundational_lemmas=relevant, base_lean_error=errors, future_targets=[],
    )


def _task_hash(task: AutonomousProofTask) -> str:
    return hashlib.sha256(json.dumps(asdict(task), ensure_ascii=False, sort_keys=True).encode()).hexdigest()


def _provider(options: dict[str, Any]) -> CodexCLIProvider:
    return CodexCLIProvider(workdir=Path(__file__).resolve().parents[2], **options)


def _require_live_provider(proof: dict[str, Any], *, direct: bool) -> None:
    """Fail closed when an arm never received a model response.

    A missing executable is caught before the run, but a present CLI can still
    fail to initialise (authentication, filesystem, or app-server failure).
    Such a run is infrastructure failure, not evidence that a proof strategy
    failed, and must never enter the experimental aggregate.
    """
    history_key = "history" if direct else "attempt_history"
    history = proof.get(history_key, [])
    if direct:
        calls = [item.get("provider", {}) for item in history if item.get("call")]
    else:
        calls = [item.get("provider_call", {}) for item in history
                 if item.get("event") in {"LLM_RESPONSE", "LLM_PROVIDER_FAILURE"}]
    if calls and any(call.get("success") for call in calls):
        return
    detail = next((call.get("stderr") or call.get("error") for call in calls if call), None)
    raise RuntimeError("LLM provider produced no successful response; "
                       "trial is infrastructure-invalid: " + (detail or "unknown provider failure"))


def _aggregate_trials(rows: list[dict[str, Any]], solved_status: str) -> list[dict[str, Any]]:
    keys = sorted(set((x["dut"], x["property_id"]) for x in rows))
    result = []
    for key in keys:
        trials = [x for x in rows if (x["dut"], x["property_id"]) == key]
        calls = [x["llm_calls"] for x in trials]
        tokens = [x["tokens"] for x in trials]
        result.append({
            "dut": key[0], "property_id": key[1], "trials": len(trials),
            "successes": sum(x["status"] == solved_status for x in trials),
            "success_rate": sum(x["status"] == solved_status for x in trials) / len(trials),
            "mean_calls": statistics.mean(calls), "calls_variance": statistics.pvariance(calls),
            "mean_tokens": statistics.mean(tokens), "tokens_variance": statistics.pvariance(tokens),
            "repair_rate": sum(x["repair_rounds"] > 0 for x in trials) / len(trials),
            "mean_lean_time_s": statistics.mean(x["lean_time_s"] for x in trials),
            "mean_total_time_s": statistics.mean(x["Te2e"] for x in trials),
        })
    return result


def audit_direct(rows: list[dict[str, Any]], requirement_root: Path) -> dict[str, Any]:
    audited = []
    for row in rows:
        proof = row.get("final_proof") or ""
        count = lambda word: len(re.findall(rf"\b{word}\b", proof))
        have = count("have")
        suffices = count("suffices")
        induction = count("induction")
        cases = count("cases") + count("rcases") + count("constructor")
        local = have + count("let") + count("show")
        depth = _proof_ast_depth(proof)
        # local_fact_count deliberately includes `have`; do not count those
        # declarations twice when deriving the classification score.
        decomposition = suffices + induction + cases + local
        audited.append({
            "trial": row["trial"], "dut": row["dut"], "property_id": row["property_id"],
            "have_count": have, "suffices_count": suffices, "induction_count": induction,
            "case_split_count": cases, "local_fact_count": local,
            "proof_ast_depth": depth, "proof_ast_size": _proof_ast_size(proof),
            "max_nested_depth": depth, "inline_decomposition_count": decomposition,
            "classification": "INLINE_DECOMPOSED_DIRECT" if decomposition else "MONOLITHIC_DIRECT",
        })
    payload = {"schema": "rtl2lean-compositional_proofs-direct-inline-v1", "rows": audited}
    write_json(requirement_root / "direct_llm" / "inline_decomposition.json", payload)
    return payload


def run_direct_trials(
    benchmarks: list[Benchmark], corpus: dict[str, Any], baseline: dict[str, Any],
    output_root: Path, requirement_root: Path, provider_options: dict[str, Any],
    trials: int, resume: bool,
) -> dict[str, Any]:
    benchmark_map = {x.design_id: x for x in benchmarks}
    prop_map = {(x["dut"], x["property_id"]): x for x in corpus["properties"]}
    failed = [x for x in baseline["results"] if x["status"] == "BASE_FAILED"]
    rows = []
    for trial in range(1, trials + 1):
        provider = _provider(provider_options)
        if failed and not provider.available:
            raise RuntimeError("Codex CLI unavailable for compositional_proofs Direct trials")
        for index, base in enumerate(failed):
            prop = prop_map[(base["dut"], base["property_id"])]
            benchmark = benchmark_map[base["dut"]]
            task = _task(benchmark, prop, base, output_root)
            root = requirement_root / "direct_llm" / "trials" / f"trial_{trial:02d}" / benchmark.slug / f"{index:03d}_{prop['property_id']}"
            saved = root / "result.json"
            if resume and saved.is_file():
                prior = _read(saved)
                if prior.get("statement_sha256") == hashlib.sha256(prop["theorem_statement"].encode()).hexdigest():
                    rows.append(prior)
                    continue
            proof = run_direct_without_intermediate(
                task, benchmark, output_root / benchmark.slug / "model", root / "proof", provider,
                budget_calls=MAX_LLM_CALLS, budget_tokens=MAX_TOTAL_TOKENS,
                max_repair_rounds_per_candidate=MAX_REPAIRS_PER_CANDIDATE,
            )
            _require_live_provider(proof, direct=True)
            result = {
                "trial": trial, "sampling_seed": None,
                "dut": prop["dut"], "property_id": prop["property_id"],
                "property_family": prop["property_family"],
                "status": "DIRECT_SOLVED" if proof["target_kernel_pass"] else "DIRECT_FAILED",
                "target_kernel_pass": proof["target_kernel_pass"],
                "final_proof": proof.get("final_proof"), "llm_calls": proof["llm_calls"],
                "tokens": proof.get("llm_tokens", 0),
                "repair_rounds": proof.get("repair_rounds_used", 0),
                "lean_time_s": proof["lean_time_s"], "llm_time_s": proof["llm_time_s"],
                "Te2e": proof["lean_time_s"] + proof["llm_time_s"], "proof_result": proof,
                "theorem_statement": prop["theorem_statement"],
                "statement_sha256": hashlib.sha256(prop["theorem_statement"].encode()).hexdigest(),
                "task_sha256": _task_hash(task), **_context_metrics(task),
            }
            write_json(saved, result); rows.append(result)
    aggregate = _aggregate_trials(rows, "DIRECT_SOLVED")
    payload = {
        "schema": "rtl2lean-compositional_proofs-direct-v1", "trial_results": rows,
        "per_target": aggregate,
        "budget": {"max_llm_calls": MAX_LLM_CALLS, "max_total_tokens": MAX_TOTAL_TOKENS,
                   "max_repair_rounds_per_candidate": MAX_REPAIRS_PER_CANDIDATE,
                   "timeout_s": PROVIDER_TIMEOUT_S},
        "metrics": {"TRIAL_TARGETS": len(rows), "SOLVED": sum(x["status"] == "DIRECT_SOLVED" for x in rows),
                    "LLM_CALLS": sum(x["llm_calls"] for x in rows), "TOKENS": sum(x["tokens"] for x in rows),
                    "TLean": sum(x["lean_time_s"] for x in rows), "Te2e": sum(x["Te2e"] for x in rows)},
    }
    write_json(requirement_root / "direct_llm" / "results.json", payload)
    audit_direct(rows, requirement_root)
    write_json(requirement_root / "repeated_trials" / "direct.json", payload)
    return payload


def _foundation_statements(output_root: Path, benchmark: Benchmark) -> list[dict[str, str]]:
    text = "\n".join(
        (output_root / benchmark.slug / "model" / name).read_text(encoding="utf-8")
        for name in ("R3Base.lean", "R3Foundation.lean", "R4Foundation.lean", "R5Foundation.lean")
    )
    return [{"name": match.group(1), "statement": match.group(2).strip()} for match in re.finditer(
        r"(?ms)^theorem\s+([A-Za-z_][A-Za-z0-9_']*)\s*:\s*(.*?)\s*:=\s*by", text
    )]


def _syntax_size(text: str) -> int:
    return len(re.findall(r"[A-Za-z_][A-Za-z0-9_'.]*|[0-9]+|→|∀|∧|∨|[()\[\],]", text))


def _abstraction_rows(
    lemmas: list[dict[str, Any]], prop: dict[str, Any], proof: dict[str, Any],
    foundation: list[dict[str, str]], context_chars: int,
) -> list[dict[str, Any]]:
    usage = {x["lemma"]: x for x in proof.get("intermediate_lemma_usage", [])}
    rows = []
    for lemma in lemmas:
        novelty = _novelty(lemma, prop, foundation)
        simple, reasons = _simple_foundation_specialization(lemma, foundation)
        statement = lemma.get("proposition", "")
        target_size, statement_size = _syntax_size(prop["theorem_statement"]), _syntax_size(statement)
        target_fields = set(prop.get("referenced_state_fields", []))
        lemma_fields = {field for field in target_fields if field in statement}
        use = usage.get(lemma["name"])
        semantic_novelty = novelty["semantic_novelty"] and not simple
        expression_reduction = target_size - statement_size
        dependency_reduction = len(prop.get("foundation_lemmas", [])) - len(lemma.get("used_lemmas", []))
        rows.append({
            "dut": prop["dut"], "target": prop["property_id"], "lemma": lemma["name"],
            "statement_size": statement_size, "target_statement_size": target_size,
            "dependency_reduction": dependency_reduction,
            "context_reduction": context_chars - len(statement),
            "expression_reduction": expression_reduction,
            "proof_reuse_count": 1 if use else 0,
            "final_proof_dependency": bool(use and use.get("causally_necessary")),
            "semantic_novelty": semantic_novelty, "target_specific": novelty["target_specific"],
            "foundation_specialization": simple, "specialization_reasons": reasons,
            "target_state_field_count": len(target_fields), "lemma_state_field_count": len(lemma_fields),
            "ABSTRACTION_GAIN": bool(
                semantic_novelty and use and expression_reduction > 0
                and (len(lemma_fields) < len(target_fields) or dependency_reduction > 0)
            ),
            "measurement_method": "Lean lexical syntax size and explicit dependency/state-field set reduction",
        })
    return rows


def _intermediate_policy(
    candidate: Any, prop: dict[str, Any], foundation: list[dict[str, str]],
) -> None:
    """Enforce compositional_proofs's no-foundation-wrapper rule before pool entry."""
    if candidate.lemma_name == prop["property_id"]:
        return
    lemma = asdict(candidate)
    novelty = _novelty(lemma, prop, foundation)
    simple, reasons = _simple_foundation_specialization(lemma, foundation)
    if not novelty["semantic_novelty"]:
        raise ValueError("compositional_proofs rejects an intermediate statement already present "
                         "in the foundation or equal to the target")
    if simple:
        raise ValueError("compositional_proofs forbids foundation wrappers: " + ",".join(reasons))


def _saved_lemmas_policy_valid(
    result: dict[str, Any], prop: dict[str, Any], foundation: list[dict[str, str]],
) -> bool:
    try:
        for lemma in result.get("intermediate_lemmas", []):
            novelty = _novelty(lemma, prop, foundation)
            simple, _ = _simple_foundation_specialization(lemma, foundation)
            if simple or not novelty["semantic_novelty"]:
                return False
    except (KeyError, TypeError):
        return False
    return True


def run_lemma_trials(
    benchmarks: list[Benchmark], corpus: dict[str, Any], baseline: dict[str, Any],
    direct: dict[str, Any], output_root: Path, requirement_root: Path,
    provider_options: dict[str, Any], trials: int, resume: bool,
) -> dict[str, Any]:
    benchmark_map = {x.design_id: x for x in benchmarks}
    prop_map = {(x["dut"], x["property_id"]): x for x in corpus["properties"]}
    direct_map = {(x["trial"], x["dut"], x["property_id"]): x for x in direct["trial_results"]}
    failed = [x for x in baseline["results"] if x["status"] == "BASE_FAILED"]
    rows, all_lemmas, abstraction, causal = [], [], [], []
    for trial in range(1, trials + 1):
        provider = _provider(provider_options)
        if failed and not provider.available:
            raise RuntimeError("Codex CLI unavailable for compositional_proofs Lemma-First trials")
        for index, base in enumerate(failed):
            prop = prop_map[(base["dut"], base["property_id"])]
            benchmark = benchmark_map[base["dut"]]
            task = _task(benchmark, prop, base, output_root)
            foundation = _foundation_statements(output_root, benchmark)
            root = requirement_root / "lemma_first" / "trials" / f"trial_{trial:02d}" / benchmark.slug / f"{index:03d}_{prop['property_id']}"
            saved = root / "result.json"
            if resume and saved.is_file():
                prior = _read(saved)
                if (prior.get("statement_sha256") == hashlib.sha256(prop["theorem_statement"].encode()).hexdigest()
                        and _saved_lemmas_policy_valid(prior, prop, foundation)):
                    rows.append(prior); all_lemmas.extend(prior.get("intermediate_lemmas", []))
                    abstraction.extend(prior.get("abstraction_gain", [])); causal.append(prior["causal_row"])
                    continue
            pool_path = root / "initial_empty_pool.json"
            write_json(pool_path, {"schema": PersistentLocalLemmaPool.SCHEMA, "dut": benchmark.design_id,
                                   "lemmas": [], "metrics": {"verified_lemmas": 0,
                                   "actual_reused_lemmas": 0, "actual_reuse_hits": 0}})
            pool = PersistentLocalLemmaPool(pool_path, benchmark.design_id)
            proof = run_budgeted_proof_search(
                task, provider, pool, output_root / benchmark.slug / "model", root / "proof",
                LEMMA_BUDGET, allow_pool_first=False,
                candidate_policy=lambda candidate: _intermediate_policy(
                    candidate, prop, foundation
                ),
            )
            _require_live_provider(proof, direct=False)
            lemmas = [asdict(x) for x in pool.lemmas
                      if x.origin == "llm" and x.source_target == prop["property_id"]]
            gains = _abstraction_rows(
                lemmas, prop, proof, foundation,
                _context_metrics(task)["context_chars"],
            )
            direct_row = direct_map[(trial, prop["dut"], prop["property_id"])]
            causal_row = {
                "trial": trial, "dut": prop["dut"], "property_id": prop["property_id"],
                "baseline": "FAIL", "direct": direct_row["status"],
                "lemma_first": "LEMMA_FIRST_SOLVED" if proof["target_kernel_pass"] else "LEMMA_FIRST_FAILED",
                "STRICT_LEMMA_CAUSAL_GAIN": direct_row["status"] == "DIRECT_FAILED" and proof["target_kernel_pass"],
                "same_theorem": direct_row["theorem_statement"] == prop["theorem_statement"],
                "same_task_context": direct_row["task_sha256"] == _task_hash(task),
                "same_budget": True, "deletion_checks": proof.get("intermediate_lemma_usage", []),
            }
            result = {
                "trial": trial, "sampling_seed": None, "dut": prop["dut"],
                "property_id": prop["property_id"], "property_family": prop["property_family"],
                "status": "LEMMA_FIRST_SOLVED" if proof["target_kernel_pass"] else "LEMMA_FIRST_FAILED",
                "target_kernel_pass": proof["target_kernel_pass"], "final_proof": proof.get("final_proof"),
                "llm_calls": proof["total_llm_calls"], "tokens": proof.get("total_llm_tokens", 0),
                "repair_rounds": proof["repair_rounds_used"], "lean_time_s": proof["lean_time_s"],
                "llm_time_s": proof["llm_time_s"], "Te2e": proof["lean_time_s"] + proof["llm_time_s"],
                "intermediate_lemmas": lemmas, "abstraction_gain": gains,
                "causal_row": causal_row, "proof_result": proof,
                "theorem_statement": prop["theorem_statement"],
                "statement_sha256": hashlib.sha256(prop["theorem_statement"].encode()).hexdigest(),
                "task_sha256": _task_hash(task), **_context_metrics(task),
            }
            write_json(saved, result); rows.append(result); all_lemmas.extend(lemmas)
            abstraction.extend(gains); causal.append(causal_row)
    aggregate = _aggregate_trials(rows, "LEMMA_FIRST_SOLVED")
    payload = {
        "schema": "rtl2lean-compositional_proofs-lemma-first-v1", "trial_results": rows,
        "per_target": aggregate,
        "budget": {**asdict(LEMMA_BUDGET), "timeout_s": PROVIDER_TIMEOUT_S},
        "metrics": {"TRIAL_TARGETS": len(rows),
                    "SOLVED": sum(x["status"] == "LEMMA_FIRST_SOLVED" for x in rows),
                    "STRICT_LEMMA_CAUSAL_GAIN": sum(x["STRICT_LEMMA_CAUSAL_GAIN"] for x in causal),
                    "VERIFIED_INTERMEDIATE_LEMMAS": len(all_lemmas),
                    "ABSTRACTION_GAIN_LEMMAS": sum(x["ABSTRACTION_GAIN"] for x in abstraction),
                    "LLM_CALLS": sum(x["llm_calls"] for x in rows),
                    "TOKENS": sum(x["tokens"] for x in rows),
                    "TLean": sum(x["lean_time_s"] for x in rows), "Te2e": sum(x["Te2e"] for x in rows)},
    }
    write_json(requirement_root / "lemma_first" / "results.json", payload)
    write_json(requirement_root / "lemma_first" / "lemmas.json", {"lemmas": all_lemmas})
    write_json(requirement_root / "lemma_first" / "abstraction_gain.json", {"rows": abstraction})
    write_json(requirement_root / "lemma_first" / "causal.json", {"rows": causal})
    write_json(requirement_root / "repeated_trials" / "lemma_first.json", payload)
    summary = {"schema": "rtl2lean-compositional_proofs-stability-v1", "trials": trials,
               "direct": direct["per_target"], "lemma_first": aggregate,
               "explicit_sampling_seed_supported": False,
               "independence_method": "fresh ephemeral Codex CLI process/session; byte-identical task context",
               "warning": "The installed provider exposes no sampling-seed option; trial ID is not injected into prompts."}
    write_json(requirement_root / "repeated_trials" / "summary.json", summary)
    return payload
