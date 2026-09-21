"""Freeze-first multi-trial multi_phase_proofs proof experiment."""
from __future__ import annotations

import hashlib
import json
import re
import statistics
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import asdict, replace
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from rtl2lean.evaluation.experiment import _lean_check, run_direct_without_intermediate
from rtl2lean.pipeline.io import sha256, write_json
from rtl2lean.pipeline.manifest import Benchmark
from rtl2lean.proving.llm_prover import (
    CodexCLIProvider, PersistentLocalLemmaPool, ProvingBudget,
    run_budgeted_proof_search,
)
from rtl2lean.temporal_challenges.experiment import (
    _context_metrics, _proof_ast_depth, _proof_ast_size,
)
from rtl2lean.compositional_proofs.experiment import BASELINE_PROOFS, _failure_kind, _require_live_provider
from rtl2lean.proof_gaps.experiment import (
    _audit_generated_lemmas, _candidate_policy, _foundation_statements,
    _proof_source, _source, _task, _task_hash,
)


MAX_LLM_CALLS = 8
MAX_TOTAL_TOKENS = 120_000
MAX_REPAIRS_PER_CANDIDATE = 1
PROVIDER_TIMEOUT_S = 300
MAX_TOTAL_WALL_TIME_S = MAX_LLM_CALLS * PROVIDER_TIMEOUT_S
LEMMA_BUDGET = ProvingBudget(
    max_generation_rounds=4,
    max_repair_rounds_per_candidate=MAX_REPAIRS_PER_CANDIDATE,
    max_intermediate_lemmas=3,
    max_llm_calls=MAX_LLM_CALLS,
    max_total_tokens=MAX_TOTAL_TOKENS,
)
NOVELTY_POLICY_VERSION = "r8-alpha-defeq-specialization-v1"
CLOSURE_POLICY_VERSION = "r8-direct-comparative-two-metric-v1"


def _read(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8")) if path.is_file() else {}


def _seed(corpus_digest: str, arm: str, property_id: str, trial: int) -> int:
    raw = f"{corpus_digest}:{arm}:{property_id}:{trial}".encode()
    return int(hashlib.sha256(raw).hexdigest()[:8], 16)


def _trial_task(
    benchmark: Benchmark, prop: dict[str, Any], base: dict[str, Any],
    output_root: Path, sampling_seed: int,
):
    task = _task(benchmark, prop, base, output_root)
    seed_note = (
        "multi_phase_proofs frozen independent-trial sampling nonce: "
        f"{sampling_seed}. This nonce carries no proof or bottleneck information."
    )
    return replace(
        task,
        property_type="OPERATIONAL_PROOF_BOTTLENECK",
        context_snippets=[*task.context_snippets, seed_note],
    )


def validate_and_freeze(
    benchmarks: list[Benchmark], analyzed: dict[str, Any], output_root: Path,
    requirement_root: Path, trials: int,
) -> dict[str, Any]:
    benchmark_map = {row.design_id: row for row in benchmarks}
    accepted: list[dict[str, Any]] = []
    validation: list[dict[str, Any]] = []
    for index, prop in enumerate(analyzed["properties"]):
        benchmark = benchmark_map[prop["dut"]]
        root = requirement_root / "corpus" / "validation" / benchmark.slug / f"{index:03d}_{prop['property_id']}"
        statement_path = root / "statement.lean"
        reference_path = root / "reference_proof.lean"
        statement_path.parent.mkdir(parents=True, exist_ok=True)
        statement_path.write_text(
            _source(
                benchmark,
                f"def {prop['property_id']}__statement : Prop := {prop['theorem_statement']}",
            ),
            encoding="utf-8",
        )
        statement_check = _lean_check(
            statement_path, output_root / benchmark.slug / "model", 1200
        )
        reference_path.write_text(
            _proof_source(benchmark, prop, prop["reference_proof"]), encoding="utf-8"
        )
        reference_check = (
            _lean_check(reference_path, output_root / benchmark.slug / "model", 1200)
            if statement_check["success"] else None
        )
        valid = bool(statement_check["success"] and reference_check and reference_check["success"])
        checked = {**prop, "validation_status": "KERNEL_VALIDATED" if valid else "REJECTED_BEFORE_FREEZE"}
        if valid:
            accepted.append(checked)
        validation.append({
            "property_id": prop["property_id"], "dut": prop["dut"], "accepted": valid,
            "classification_before_proof": prop["r8_experiment_class"],
            "statement_check": statement_check, "reference_check": reference_check,
            "rejection_reason": None if valid else (
                "ILL_TYPED_STATEMENT" if not statement_check["success"] else "REFERENCE_PROOF_REJECTED"
            ),
        })

    frozen = {
        **analyzed,
        "schema": "rtl2lean-multi_phase_proofs-frozen-corpus-v1",
        "properties": accepted,
        "frozen_before_baseline": True,
        "frozen_before_llm": True,
        "freeze_time": datetime.now(timezone.utc).isoformat(),
        "bottleneck_scope": "OPERATIONAL_UNDER_FROZEN_ENVIRONMENT",
        "metrics": {
            **analyzed["metrics"],
            "N_VALIDATED": len(accepted),
            "N_VALIDATION_REJECTED": len(analyzed["properties"]) - len(accepted),
            "N_BOTTLENECK_CHALLENGES": sum(row["operational_bottleneck_candidate"] for row in accepted),
        },
    }
    final_path = requirement_root / "corpus" / "final_properties.json"
    write_json(final_path, frozen)
    digest = sha256(final_path)
    challenge = [row for row in accepted if row["operational_bottleneck_candidate"]]
    write_json(requirement_root / "corpus" / "bottleneck_challenges.json", {
        "schema": "rtl2lean-multi_phase_proofs-bottleneck-challenges-v1",
        "frozen_before_proof": True, "properties": challenge,
    })
    seed_rows = []
    for prop in challenge:
        for trial in range(1, trials + 1):
            # The provider has no exposed RNG-seed API. The frozen value is
            # injected as a semantically inert prompt nonce to create distinct,
            # reproducible trial contexts with the same template.
            seed_rows.append({
                "property_id": prop["property_id"], "dut": prop["dut"], "trial": trial,
                "direct_seed": _seed(digest, "paired", prop["property_id"], trial),
                "lemma_first_seed": _seed(digest, "paired", prop["property_id"], trial),
                "injection": "SEMANTICALLY_INERT_PROMPT_NONCE",
                "provider_rng_seed_exposed": False,
            })
    write_json(requirement_root / "corpus" / "trial_seeds.json", {
        "schema": "rtl2lean-multi_phase_proofs-trial-seeds-v1",
        "frozen_before_proof": True, "trials_per_bottleneck": trials, "rows": seed_rows,
    })
    write_json(requirement_root / "corpus" / "validation.json", {"rows": validation})
    write_json(requirement_root / "corpus" / "freeze.json", {
        "schema": "rtl2lean-multi_phase_proofs-freeze-v1",
        "final_properties_sha256": digest,
        "frozen_before_baseline": True,
        "property_count": len(accepted),
        "bottleneck_count": len(challenge),
        "classification_sha256": hashlib.sha256(json.dumps(
            [(row["property_id"], row["r8_experiment_class"], row["bottleneck_analysis"])
             for row in accepted], sort_keys=True, ensure_ascii=False,
        ).encode()).hexdigest(),
    })
    write_json(requirement_root / "bottleneck" / "frozen_classification.json", {
        "schema": "rtl2lean-multi_phase_proofs-frozen-classification-v1",
        "scope": "OPERATIONAL_UNDER_FROZEN_ENVIRONMENT",
        "frozen_before_proof": True,
        "rows": [{
            "property_id": row["property_id"], "dut": row["dut"],
            "classification": row["r8_experiment_class"],
            "strength": row["bottleneck_analysis"]["bottleneck_strength"],
            "BOTTLENECK_CANDIDATE": row["operational_bottleneck_candidate"],
            "analysis": row["bottleneck_analysis"],
        } for row in accepted],
    })
    return frozen


def run_baseline(
    benchmarks: list[Benchmark], corpus: dict[str, Any], output_root: Path,
    requirement_root: Path,
) -> dict[str, Any]:
    benchmark_map = {row.design_id: row for row in benchmarks}
    rows: list[dict[str, Any]] = []
    started = time.perf_counter()
    for index, prop in enumerate(corpus["properties"]):
        benchmark = benchmark_map[prop["dut"]]
        root = requirement_root / "baseline" / "attempts" / benchmark.slug / f"{index:03d}_{prop['property_id']}"
        attempts, proof = [], None
        for attempt_index, candidate in enumerate(BASELINE_PROOFS):
            path = root / f"attempt_{attempt_index:02d}.lean"
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(_proof_source(benchmark, prop, candidate), encoding="utf-8")
            check = _lean_check(path, output_root / benchmark.slug / "model", 600)
            attempts.append({"proof": candidate, **check})
            if check["success"]:
                proof = candidate
                break
        rows.append({
            "property_id": prop["property_id"], "dut": prop["dut"],
            "experiment_class": prop["r8_experiment_class"],
            "status": "BASE_SOLVED" if proof else "BASE_FAILED", "proof": proof,
            "attempts": attempts, "failure_kind": None if proof else _failure_kind(attempts),
            "lean_time_s": sum(row["elapsed_s"] for row in attempts),
            "theorem_statement": prop["theorem_statement"],
            "statement_sha256": hashlib.sha256(prop["theorem_statement"].encode()).hexdigest(),
        })
    payload = {
        "schema": "rtl2lean-multi_phase_proofs-baseline-v1", "results": rows,
        "capability": {"generic_proofs": BASELINE_PROOFS, "unchanged_from_proof_gaps": True},
        "metrics": {
            "TARGETS": len(rows), "BASE_SOLVED": sum(row["status"] == "BASE_SOLVED" for row in rows),
            "BASE_FAILED": sum(row["status"] == "BASE_FAILED" for row in rows),
            "TLean": sum(row["lean_time_s"] for row in rows), "Te2e": time.perf_counter() - started,
        },
    }
    write_json(requirement_root / "baseline" / "results.json", payload)
    return payload


def _provider(options: dict[str, Any]) -> CodexCLIProvider:
    return CodexCLIProvider(workdir=Path(__file__).resolve().parents[2], **options)


def _aggregate(rows: list[dict[str, Any]], solved_status: str) -> list[dict[str, Any]]:
    result = []
    for key in sorted({(row["dut"], row["property_id"]) for row in rows}):
        selected = [row for row in rows if (row["dut"], row["property_id"]) == key]
        result.append({
            "dut": key[0], "property_id": key[1], "trials": len(selected),
            "successes": sum(row["status"] == solved_status for row in selected),
            "success_rate": sum(row["status"] == solved_status for row in selected) / len(selected),
            "mean_calls": statistics.mean(row["llm_calls"] for row in selected),
            "mean_tokens": statistics.mean(row["tokens"] for row in selected),
            "mean_wall_time_s": statistics.mean(row["Te2e"] for row in selected),
        })
    return result


def _import_r7_direct(prop: dict[str, Any], row: dict[str, Any]) -> dict[str, Any]:
    return {
        **row, "experiment_class": prop["r8_experiment_class"],
        "evidence_source": "proof_gaps_FROZEN_TRIAL",
        "sampling_seed": None, "provider_rng_seed_exposed": False,
    }


def run_direct(
    benchmarks: list[Benchmark], corpus: dict[str, Any], baseline: dict[str, Any],
    output_root: Path, requirement_root: Path, provider_options: dict[str, Any],
    trials: int, resume: bool, workers: int = 1,
) -> dict[str, Any]:
    benchmark_map = {row.design_id: row for row in benchmarks}
    base_map = {(row["dut"], row["property_id"]): row for row in baseline["results"]}
    r7 = _read(output_root / "proof_gaps" / "direct" / "results.json")
    r7_map = {(row["dut"], row["property_id"]): row for row in r7.get("trial_results", [])}
    seed_payload = _read(requirement_root / "corpus" / "trial_seeds.json")
    seeds = {(row["dut"], row["property_id"], row["trial"]): row["direct_seed"] for row in seed_payload["rows"]}
    rows: list[dict[str, Any]] = []
    challenges = [row for row in corpus["properties"] if row["operational_bottleneck_candidate"]]
    controls = [row for row in corpus["properties"] if not row["operational_bottleneck_candidate"]]
    for prop in controls:
        prior = r7_map.get((prop["dut"], prop["property_id"]))
        if prior:
            rows.append(_import_r7_direct(prop, prior))
    def run_one(trial: int, index: int, prop: dict[str, Any]) -> dict[str, Any]:
        benchmark = benchmark_map[prop["dut"]]
        base = base_map[(prop["dut"], prop["property_id"])]
        sampling_seed = seeds[(prop["dut"], prop["property_id"], trial)]
        task = _trial_task(benchmark, prop, base, output_root, sampling_seed)
        root = requirement_root / "direct" / "runs" / f"trial_{trial:02d}" / benchmark.slug / f"{index:03d}_{prop['property_id']}"
        saved = root / "result.json"
        digest = hashlib.sha256(prop["theorem_statement"].encode()).hexdigest()
        if resume and saved.is_file():
            prior = _read(saved)
            if (prior.get("statement_sha256") == digest
                    and prior.get("sampling_seed") == sampling_seed):
                return prior
        provider = _provider(provider_options)
        if not provider.available:
            raise RuntimeError("Codex CLI unavailable for multi_phase_proofs Direct arm")
        proof = run_direct_without_intermediate(
            task, benchmark, output_root / benchmark.slug / "model", root / "proof", provider,
            budget_calls=MAX_LLM_CALLS, budget_tokens=MAX_TOTAL_TOKENS,
            max_repair_rounds_per_candidate=MAX_REPAIRS_PER_CANDIDATE,
        )
        _require_live_provider(proof, direct=True)
        result = {
            "trial": trial, "sampling_seed": sampling_seed,
            "provider_rng_seed_exposed": False,
            "dut": prop["dut"], "property_id": prop["property_id"],
            "experiment_class": prop["r8_experiment_class"],
            "status": "DIRECT_SOLVED" if proof["target_kernel_pass"] else "DIRECT_FAILED",
            "target_kernel_pass": proof["target_kernel_pass"], "final_proof": proof.get("final_proof"),
            "llm_calls": proof["llm_calls"], "tokens": proof.get("llm_tokens", 0),
            "repair_rounds": proof.get("repair_rounds_used", 0),
            "lean_time_s": proof["lean_time_s"], "llm_time_s": proof["llm_time_s"],
            "Te2e": proof["lean_time_s"] + proof["llm_time_s"], "proof_result": proof,
            "theorem_statement": prop["theorem_statement"], "statement_sha256": digest,
            "task_sha256": _task_hash(task), "evidence_source": "multi_phase_proofs_LIVE_TRIAL",
            **_context_metrics(task),
        }
        write_json(saved, result)
        return result

    jobs = [
        (trial, index, prop)
        for trial in range(1, trials + 1)
        for index, prop in enumerate(challenges)
    ]
    with ThreadPoolExecutor(max_workers=max(1, workers)) as executor:
        futures = {executor.submit(run_one, *job): job for job in jobs}
        for future in as_completed(futures):
            rows.append(future.result())
    rows.sort(key=lambda row: (row.get("evidence_source", ""), row["trial"], row["dut"], row["property_id"]))
    payload = {
        "schema": "rtl2lean-multi_phase_proofs-direct-trials-v1", "trial_results": rows,
        "per_target": _aggregate(rows, "DIRECT_SOLVED"),
        "budget": {
            "max_llm_calls": MAX_LLM_CALLS, "max_total_tokens": MAX_TOTAL_TOKENS,
            "max_repair_rounds_per_candidate": MAX_REPAIRS_PER_CANDIDATE,
            "provider_timeout_s": PROVIDER_TIMEOUT_S, "max_total_wall_time_s": MAX_TOTAL_WALL_TIME_S,
        },
        "metrics": {
            "TRIAL_TARGETS": len(rows),
            "LIVE_BOTTLENECK_TRIALS": sum(row["evidence_source"] == "multi_phase_proofs_LIVE_TRIAL" for row in rows),
            "workers": max(1, workers),
            "SOLVED": sum(row["status"] == "DIRECT_SOLVED" for row in rows),
            "FAILED": sum(row["status"] == "DIRECT_FAILED" for row in rows),
            "LLM_CALLS": sum(row["llm_calls"] for row in rows),
            "TOKENS": sum(row["tokens"] for row in rows),
        },
    }
    write_json(requirement_root / "direct" / "trials.json", payload)
    audit_direct_bypass(corpus, payload, requirement_root)
    return payload


def audit_direct_bypass(
    corpus: dict[str, Any], direct: dict[str, Any], requirement_root: Path,
) -> dict[str, Any]:
    prop_map = {(row["dut"], row["property_id"]): row for row in corpus["properties"]}
    rows = []
    for trial in direct["trial_results"]:
        prop = prop_map[(trial["dut"], trial["property_id"])]
        proof = trial.get("final_proof") or ""
        induction = len(re.findall(r"\binduction\b", proof))
        local = len(re.findall(r"\b(?:have|suffices|show)\b", proof))
        foundation_refs = [name for name in prop.get("foundation_lemmas", []) if name in proof]
        if trial["status"] != "DIRECT_SOLVED":
            route = "UNRESOLVED"
        elif induction and local:
            route = "INLINE_INDUCTION_WITH_LOCAL_ABSTRACTION"
        elif induction:
            route = "INLINE_STRUCTURAL_INDUCTION"
        elif foundation_refs and local:
            route = "MIXED_FOUNDATION_AND_INLINE_RELATION"
        elif foundation_refs:
            route = "EXISTING_THEOREM_CHAIN"
        else:
            route = "OTHER_VALID_ROUTE"
        rows.append({
            "trial": trial["trial"], "dut": trial["dut"], "property_id": trial["property_id"],
            "experiment_class": prop["r8_experiment_class"],
            "preproof_strength": prop["bottleneck_analysis"]["bottleneck_strength"],
            "status": trial["status"], "DIRECT_BYPASS_PATH": route if trial["status"] == "DIRECT_SOLVED" else None,
            "induction_count": induction, "local_abstraction_count": local,
            "foundation_references": foundation_refs,
            "proof_ast_depth": _proof_ast_depth(proof), "proof_ast_size": _proof_ast_size(proof),
        })
    summary = []
    for key in sorted({(row["dut"], row["property_id"]) for row in rows}):
        selected = [row for row in rows if (row["dut"], row["property_id"]) == key]
        prop = prop_map[key]
        successes = sum(row["status"] == "DIRECT_SOLVED" for row in selected)
        summary.append({
            "dut": key[0], "property_id": key[1], "trials": len(selected),
            "successes": successes, "DIRECT_SUCCESS_RATE": successes / len(selected),
            "preproof_strength": prop["bottleneck_analysis"]["bottleneck_strength"],
            "DIRECT_BYPASS": successes > 0 and prop["operational_bottleneck_candidate"],
            "BOTTLENECK_FALSE_POSITIVE": bool(
                prop["bottleneck_analysis"]["bottleneck_strength"] == "STRONG"
                and successes == len(selected) and len(selected) >= 5
            ),
            "observed_routes": sorted({row["DIRECT_BYPASS_PATH"] for row in selected if row["DIRECT_BYPASS_PATH"]}),
        })
    payload = {"schema": "rtl2lean-multi_phase_proofs-direct-bypass-v1", "rows": rows, "per_target": summary}
    write_json(requirement_root / "direct" / "bypass_audit.json", payload)
    return payload


def _alignment(prop: dict[str, Any], lemma: dict[str, Any], trial: int) -> dict[str, Any]:
    gap = prop.get("gap_spec") or {}
    statement = lemma.get("proposition") or lemma.get("statement", "")
    anchors = gap.get("relation_anchors", [])
    matched = [anchor for anchor in anchors if anchor in statement]
    score = len(matched) / len(anchors) if anchors else 0.0
    expected = gap.get("missing_relation_statement")
    normalized = lambda value: re.sub(r"\s+|[()]", "", value or "")
    if not gap:
        classification = "NO_PREDICTED_BOTTLENECK"
    elif expected and normalized(expected) == normalized(statement):
        classification = "EXACT_ALIGNMENT"
    elif score == 1.0:
        classification = "SEMANTIC_ALIGNMENT"
    elif score >= 0.5:
        classification = "PARTIAL_ALIGNMENT"
    elif re.search(r"Along|r3Run|phase|prefix|guard", statement, re.I):
        classification = "ALTERNATIVE_VALID_ABSTRACTION"
    else:
        classification = "NO_ALIGNMENT"
    return {
        "trial": trial, "dut": prop["dut"], "property_id": prop["property_id"],
        "lemma": lemma.get("name"), "pre_gap": gap.get("missing_relation"),
        "bottleneck_strength": prop["bottleneck_analysis"]["bottleneck_strength"],
        "classification": classification, "anchor_score": round(score, 4),
        "matched_anchors": matched, "required_anchors": anchors,
    }


def _closure(
    prop: dict[str, Any], base: dict[str, Any], direct: dict[str, Any],
    proof: dict[str, Any], lemmas: list[dict[str, Any]], trial: int,
) -> dict[str, Any]:
    usage = proof.get("intermediate_lemma_usage", [])
    causal = any(row.get("causally_necessary") for row in usage)
    final_proof = proof.get("final_proof") or ""
    direct_proof = direct.get("final_proof") or ""
    baseline_subgoals = sum(
        (row.get("stdout", "") + row.get("stderr", "")).count("⊢")
        for row in base.get("attempts", [])
    )
    metrics = {
        "subgoal_reduction": baseline_subgoals if proof.get("target_kernel_pass") else 0,
        "chain_reduction": max(0, _proof_ast_size(direct_proof) - _proof_ast_size(final_proof)),
        "context_reduction": max(0, len(direct_proof) - len(final_proof)),
        "proof_ast_reduction": max(0, _proof_ast_depth(direct_proof) - _proof_ast_depth(final_proof)),
        "repair_reduction": max(0, direct.get("repair_rounds", 0) - proof.get("repair_rounds_used", 0)),
    }
    comparative_improvements = sum(
        metrics[name] > 0 for name in (
            "chain_reduction", "context_reduction", "proof_ast_reduction", "repair_reduction"
        )
    )
    closure = bool(
        base["status"] == "BASE_FAILED" and proof.get("target_kernel_pass") and causal
        and (direct.get("status") != "DIRECT_SOLVED" or comparative_improvements >= 2)
    )
    return {
        "trial": trial, "dut": prop["dut"], "property_id": prop["property_id"],
        "foundation_only": base["status"],
        "with_generated_lemma": "PASS" if proof.get("target_kernel_pass") else "FAIL",
        "verified_lemma_count": sum(row.get("kernel_verified", False) for row in lemmas),
        **metrics,
        "metric_method": {
            "subgoal_reduction": "Baseline Lean error goal markers reduced to zero",
            "chain_reduction": "Direct proof AST size minus lemma-first final-proof AST size",
            "context_reduction": "Direct proof characters minus lemma-first final-proof characters",
            "proof_ast_reduction": "Direct proof AST depth minus lemma-first final-proof AST depth",
            "repair_reduction": "Direct repair rounds minus lemma-first repair rounds",
        },
        "BOTTLENECK_CLOSURE": closure,
        "closure_policy": CLOSURE_POLICY_VERSION,
        "direct_comparative_improvement_count": comparative_improvements,
        "closure_threshold": "Direct failed, or at least 2/4 Direct-comparative metrics improved",
        "SCRIPT_CAUSALLY_REQUIRED": causal,
        "delete_pass": all(
            row.get("kernel_ablation_without_lemma_pass", False) for row in usage
        ) if usage else None,
        "restore_pass": bool(proof.get("target_kernel_pass")),
        "deletion_checks": usage,
    }


def _import_r7_lemma(
    prop: dict[str, Any], prior: dict[str, Any], base: dict[str, Any], direct: dict[str, Any],
) -> tuple[dict[str, Any], list[dict[str, Any]], list[dict[str, Any]], dict[str, Any], dict[str, Any]]:
    lemmas = prior.get("intermediate_lemmas", [])
    novelty = [{**row, "evidence_source": "proof_gaps_FROZEN_TRIAL"} for row in prior.get("novelty", [])]
    alignment = [_alignment(prop, lemma, 1) for lemma in lemmas]
    closure = _closure(prop, base, direct, prior.get("proof_result", {}), lemmas, 1)
    causal = {
        **prior.get("causal_row", {}),
        "experiment_class": prop["r8_experiment_class"],
        "evidence_source": "proof_gaps_FROZEN_TRIAL",
        "SCRIPT_CAUSALLY_REQUIRED": closure["SCRIPT_CAUSALLY_REQUIRED"],
        "restore_pass": closure["restore_pass"],
    }
    result = {
        **prior, "experiment_class": prop["r8_experiment_class"],
        "evidence_source": "proof_gaps_FROZEN_TRIAL", "sampling_seed": None,
        "provider_rng_seed_exposed": False, "alignment": alignment, "closure": closure,
    }
    return result, novelty, alignment, closure, causal


def run_lemma_first(
    benchmarks: list[Benchmark], corpus: dict[str, Any], baseline: dict[str, Any],
    direct: dict[str, Any], output_root: Path, requirement_root: Path,
    provider_options: dict[str, Any], trials: int, resume: bool, workers: int = 1,
) -> dict[str, Any]:
    benchmark_map = {row.design_id: row for row in benchmarks}
    base_map = {(row["dut"], row["property_id"]): row for row in baseline["results"]}
    direct_map = {(row["trial"], row["dut"], row["property_id"]): row for row in direct["trial_results"]}
    r7 = _read(output_root / "proof_gaps" / "lemma_first" / "results.json")
    r7_map = {(row["dut"], row["property_id"]): row for row in r7.get("trial_results", [])}
    seeds_payload = _read(requirement_root / "corpus" / "trial_seeds.json")
    seeds = {(row["dut"], row["property_id"], row["trial"]): row["lemma_first_seed"] for row in seeds_payload["rows"]}
    rows: list[dict[str, Any]] = []
    all_lemmas: list[dict[str, Any]] = []
    novelty_rows: list[dict[str, Any]] = []
    alignment_rows: list[dict[str, Any]] = []
    closure_rows: list[dict[str, Any]] = []
    causal_rows: list[dict[str, Any]] = []
    challenges = [row for row in corpus["properties"] if row["operational_bottleneck_candidate"]]
    controls = [row for row in corpus["properties"] if not row["operational_bottleneck_candidate"]]
    for prop in controls:
        prior = r7_map.get((prop["dut"], prop["property_id"]))
        direct_prior = direct_map.get((1, prop["dut"], prop["property_id"]))
        if prior and direct_prior:
            result, novelty, alignment, closure, causal = _import_r7_lemma(
                prop, prior, base_map[(prop["dut"], prop["property_id"])], direct_prior
            )
            rows.append(result); all_lemmas.extend(result.get("intermediate_lemmas", []))
            novelty_rows.extend(novelty); alignment_rows.extend(alignment)
            closure_rows.append(closure); causal_rows.append(causal)
    def run_one(
        trial: int, index: int, prop: dict[str, Any],
    ) -> tuple[dict[str, Any], list[dict[str, Any]], list[dict[str, Any]], dict[str, Any], dict[str, Any]]:
        benchmark = benchmark_map[prop["dut"]]
        model_root = output_root / benchmark.slug / "model"
        base = base_map[(prop["dut"], prop["property_id"])]
        direct_row = direct_map[(trial, prop["dut"], prop["property_id"])]
        sampling_seed = seeds[(prop["dut"], prop["property_id"], trial)]
        task = _trial_task(benchmark, prop, base, output_root, sampling_seed)
        foundation = _foundation_statements(output_root, benchmark)
        root = requirement_root / "lemma_first" / "runs" / f"trial_{trial:02d}" / benchmark.slug / f"{index:03d}_{prop['property_id']}"
        saved = root / "result.json"
        digest = hashlib.sha256(prop["theorem_statement"].encode()).hexdigest()
        if resume and saved.is_file():
            prior = _read(saved)
            if (prior.get("statement_sha256") == digest
                    and prior.get("sampling_seed") == sampling_seed
                    and prior.get("novelty_policy_version") == NOVELTY_POLICY_VERSION):
                lemmas = prior.get("intermediate_lemmas", [])
                closure = _closure(
                    prop, base, direct_row, prior.get("proof_result", {}), lemmas, trial
                )
                prior["closure"] = closure
                prior["closure_policy_version"] = CLOSURE_POLICY_VERSION
                prior["causal_row"].update({
                    "SCRIPT_CAUSALLY_REQUIRED": closure["SCRIPT_CAUSALLY_REQUIRED"],
                    "delete_pass": closure["delete_pass"],
                    "restore_pass": closure["restore_pass"],
                })
                write_json(saved, prior)
                return (
                    prior, prior.get("novelty", []), prior.get("alignment", []),
                    closure, prior["causal_row"],
                )
        provider = _provider(provider_options)
        if not provider.available:
            raise RuntimeError("Codex CLI unavailable for multi_phase_proofs Lemma-First arm")
        pool_path = root / "initial_empty_pool.json"
        write_json(pool_path, {
            "schema": PersistentLocalLemmaPool.SCHEMA, "dut": benchmark.design_id,
            "lemmas": [], "metrics": {"verified_lemmas": 0, "actual_reused_lemmas": 0, "actual_reuse_hits": 0},
        })
        pool = PersistentLocalLemmaPool(pool_path, benchmark.design_id)
        proof = run_budgeted_proof_search(
            task, provider, pool, model_root, root / "proof", LEMMA_BUDGET,
            allow_pool_first=False,
            candidate_policy=lambda candidate: _candidate_policy(
                candidate, prop, foundation, benchmark, model_root, root / "novelty_policy",
            ),
        )
        _require_live_provider(proof, direct=False)
        lemmas = [asdict(row) for row in pool.lemmas
                  if row.origin == "llm" and row.source_target == prop["property_id"]]
        novelty, _ = _audit_generated_lemmas(
            lemmas, prop, foundation, proof, trial, benchmark, model_root, root / "novelty_audit",
        )
        alignment = [_alignment(prop, lemma, trial) for lemma in lemmas]
        closure = _closure(prop, base, direct_row, proof, lemmas, trial)
        causal = {
            "trial": trial, "dut": prop["dut"], "property_id": prop["property_id"],
            "experiment_class": prop["r8_experiment_class"],
            "baseline": base["status"], "direct": direct_row["status"],
            "lemma_first": "LEMMA_FIRST_SOLVED" if proof["target_kernel_pass"] else "LEMMA_FIRST_FAILED",
            "SCRIPT_CAUSALLY_REQUIRED": closure["SCRIPT_CAUSALLY_REQUIRED"],
            "delete_pass": closure["delete_pass"], "restore_pass": closure["restore_pass"],
            "same_theorem": direct_row["statement_sha256"] == digest,
            "same_task_context": direct_row["task_sha256"] == _task_hash(task),
            "same_budget": True,
            "deletion_checks": proof.get("intermediate_lemma_usage", []),
        }
        result = {
            "trial": trial, "sampling_seed": sampling_seed, "provider_rng_seed_exposed": False,
            "dut": prop["dut"], "property_id": prop["property_id"],
            "experiment_class": prop["r8_experiment_class"],
            "status": "LEMMA_FIRST_SOLVED" if proof["target_kernel_pass"] else "LEMMA_FIRST_FAILED",
            "target_kernel_pass": proof["target_kernel_pass"], "final_proof": proof.get("final_proof"),
            "llm_calls": proof["total_llm_calls"], "tokens": proof.get("total_llm_tokens", 0),
            "repair_rounds": proof["repair_rounds_used"], "lean_time_s": proof["lean_time_s"],
            "llm_time_s": proof["llm_time_s"], "Te2e": proof["lean_time_s"] + proof["llm_time_s"],
            "intermediate_lemmas": lemmas, "novelty": novelty, "alignment": alignment,
            "closure": closure, "causal_row": causal, "proof_result": proof,
            "theorem_statement": prop["theorem_statement"], "statement_sha256": digest,
            "task_sha256": _task_hash(task), "evidence_source": "multi_phase_proofs_LIVE_TRIAL",
            "novelty_policy_version": NOVELTY_POLICY_VERSION, **_context_metrics(task),
            "closure_policy_version": CLOSURE_POLICY_VERSION,
        }
        write_json(saved, result)
        return result, novelty, alignment, closure, causal

    jobs = [
        (trial, index, prop)
        for trial in range(1, trials + 1)
        for index, prop in enumerate(challenges)
    ]
    with ThreadPoolExecutor(max_workers=max(1, workers)) as executor:
        futures = {executor.submit(run_one, *job): job for job in jobs}
        for future in as_completed(futures):
            result, novelty, alignment, closure, causal = future.result()
            rows.append(result); all_lemmas.extend(result.get("intermediate_lemmas", []))
            novelty_rows.extend(novelty); alignment_rows.extend(alignment)
            closure_rows.append(closure); causal_rows.append(causal)
    rows.sort(key=lambda row: (row.get("evidence_source", ""), row["trial"], row["dut"], row["property_id"]))
    payload = {
        "schema": "rtl2lean-multi_phase_proofs-lemma-first-trials-v1", "trial_results": rows,
        "per_target": _aggregate(rows, "LEMMA_FIRST_SOLVED"),
        "budget": {
            **asdict(LEMMA_BUDGET), "provider_timeout_s": PROVIDER_TIMEOUT_S,
            "max_total_wall_time_s": MAX_TOTAL_WALL_TIME_S,
        },
        "metrics": {
            "TRIAL_TARGETS": len(rows),
            "LIVE_BOTTLENECK_TRIALS": sum(row["evidence_source"] == "multi_phase_proofs_LIVE_TRIAL" for row in rows),
            "workers": max(1, workers),
            "SOLVED": sum(row["status"] == "LEMMA_FIRST_SOLVED" for row in rows),
            "FAILED": sum(row["status"] == "LEMMA_FIRST_FAILED" for row in rows),
            "VERIFIED_INTERMEDIATE_LEMMAS": sum(
                lemma.get("kernel_verified", False) for lemma in all_lemmas
            ),
            "NOVEL_INTERMEDIATE_LEMMAS": sum(row.get("NOVEL_INTERMEDIATE_LEMMA", False) for row in novelty_rows),
            "BOTTLENECK_CLOSURE": sum(row["BOTTLENECK_CLOSURE"] for row in closure_rows),
            "LLM_CALLS": sum(row["llm_calls"] for row in rows),
            "TOKENS": sum(row["tokens"] for row in rows),
        },
    }
    write_json(requirement_root / "lemma_first" / "trials.json", payload)
    write_json(requirement_root / "lemma_first" / "intermediate_lemmas.json", {"lemmas": all_lemmas})
    write_json(requirement_root / "lemma_first" / "novelty.json", {"rows": novelty_rows})
    write_json(requirement_root / "lemma_first" / "alignment.json", {"rows": alignment_rows})
    write_json(requirement_root / "lemma_first" / "closure.json", {"rows": closure_rows})
    write_json(requirement_root / "lemma_first" / "causal_ablation.json", {"rows": causal_rows})
    return payload
