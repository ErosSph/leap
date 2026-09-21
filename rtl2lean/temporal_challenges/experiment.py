"""Freeze-first, equal-budget three-arm temporal_challenges experiment."""
from __future__ import annotations

import hashlib
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
from rtl2lean.temporal.experiment import (
    GENERIC_BASELINE_PROOFS,
    _declaration_block,
    _failure_kind,
    _foundation_statements,
    _novelty,
)


EQUAL_TOTAL_LLM_CALL_BUDGET = 8
LEMMA_FIRST_BUDGET = ProvingBudget(
    max_generation_rounds=4,
    max_repair_rounds_per_candidate=1,
    max_intermediate_lemmas=3,
    max_llm_calls=EQUAL_TOTAL_LLM_CALL_BUDGET,
)


def _read(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8")) if path.is_file() else {}


def _source(benchmark: Benchmark, declaration: str) -> str:
    return "\n".join([
        "import R4Foundation", "", "set_option maxRecDepth 100000",
        "set_option maxHeartbeats 8000000", "",
        f"namespace {benchmark.top_module}Verification", f"open {benchmark.top_module}",
        "", declaration, "", f"end {benchmark.top_module}Verification", "",
    ])


def _proof_source(benchmark: Benchmark, prop: dict[str, Any], proof: str) -> str:
    return _source(benchmark, f"theorem {prop['property_id']} : {prop['theorem_statement']} := {proof}")


def validate_and_freeze(
    benchmarks: list[Benchmark], corpus: dict[str, Any], output_root: Path,
    requirement_root: Path,
) -> dict[str, Any]:
    benchmark_map = {x.design_id: x for x in benchmarks}
    accepted, rows = [], []
    for index, prop in enumerate(corpus["properties"]):
        benchmark = benchmark_map[prop["dut"]]
        root = requirement_root / "hard_temporal" / "validation" / benchmark.slug / f"{index:03d}_{prop['property_id']}"
        statement_path = root / "statement.lean"
        statement_path.parent.mkdir(parents=True, exist_ok=True)
        statement_path.write_text(
            _source(benchmark, f"def {prop['property_id']}__statement : Prop := {prop['theorem_statement']}"),
            encoding="utf-8",
        )
        statement_check = _lean_check(statement_path, output_root / benchmark.slug / "model", 600)
        reference_path = root / "reference_proof.lean"
        reference_path.write_text(_proof_source(benchmark, prop, prop["proof_candidates"][0]), encoding="utf-8")
        reference_check = (_lean_check(reference_path, output_root / benchmark.slug / "model", 1200)
                           if statement_check["success"] else None)
        valid = bool(statement_check["success"] and reference_check and reference_check["success"])
        checked = dict(prop)
        checked["validation_status"] = "KERNEL_VALIDATED" if valid else "REJECTED_BEFORE_FREEZE"
        if valid:
            accepted.append(checked)
        else:
            checked["rejection_reason"] = (
                "ILL_TYPED_STATEMENT" if not statement_check["success"] else "REFERENCE_CERTIFICATE_REJECTED"
            )
        rows.append({
            "dut": prop["dut"], "property_id": prop["property_id"], "accepted": valid,
            "statement_check": statement_check, "reference_check": reference_check,
        })
    frozen = {
        **corpus, "properties": accepted, "frozen_before_baseline": True,
        "freeze_status": "FROZEN_AFTER_KERNEL_VALIDATION",
        "freeze_time": datetime.now(timezone.utc).isoformat(),
        "metrics": {
            **corpus["metrics"], "N_GENERATED": len(corpus["properties"]),
            "N_FINAL": len(accepted), "N_VALIDATION_REJECTED": len(corpus["properties"]) - len(accepted),
            "N_HARD_TEMPORAL": sum(x["property_level"] == "HARD_TEMPORAL" for x in accepted),
            "N_UNTIL": sum(x["property_family"] == "UNTIL" for x in accepted),
        },
    }
    path = requirement_root / "hard_temporal" / "final_properties.json"
    write_json(path, frozen)
    freeze = {
        "schema": "rtl2lean-temporal_challenges-freeze-v1", "frozen_before_baseline": True,
        "property_count": len(accepted), "validation_rows": rows,
        "final_properties_sha256": sha256(path),
        "properties": [{"dut": x["dut"], "property_id": x["property_id"],
                        "statement": x["theorem_statement"]} for x in accepted],
    }
    write_json(requirement_root / "hard_temporal" / "freeze.json", freeze)
    write_json(requirement_root / "hard_temporal" / "validation.json", {"rows": rows})
    return frozen


def run_baseline(
    benchmarks: list[Benchmark], corpus: dict[str, Any], output_root: Path,
    requirement_root: Path,
) -> dict[str, Any]:
    freeze = _read(requirement_root / "hard_temporal" / "freeze.json")
    if not freeze.get("frozen_before_baseline"):
        raise RuntimeError("temporal_challenges corpus is not frozen")
    benchmark_map = {x.design_id: x for x in benchmarks}
    results = []
    started = time.perf_counter()
    for index, prop in enumerate(corpus["properties"]):
        benchmark = benchmark_map[prop["dut"]]
        root = requirement_root / "baseline" / "attempts" / benchmark.slug / f"{index:03d}_{prop['property_id']}"
        attempts, solved = [], None
        for attempt_index, proof in enumerate(GENERIC_BASELINE_PROOFS):
            path = root / f"attempt_{attempt_index:02d}.lean"
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(_proof_source(benchmark, prop, proof), encoding="utf-8")
            check = _lean_check(path, output_root / benchmark.slug / "model", 300)
            attempts.append({"proof": proof, "proof_steps": 1, **check})
            if check["success"]:
                solved = proof
                break
        result = {
            "dut": prop["dut"], "property_id": prop["property_id"],
            "property_family": prop["property_family"], "status": "BASE_SOLVED" if solved else "BASE_FAILED",
            "proof": solved, "attempts": attempts,
            "failure_kind": None if solved else _failure_kind(attempts),
            "lean_time_s": sum(x["elapsed_s"] for x in attempts),
            "Te2e": sum(x["elapsed_s"] for x in attempts),
            "theorem_statement_sha256": hashlib.sha256(prop["theorem_statement"].encode()).hexdigest(),
        }
        write_json(root / "result.json", result)
        results.append(result)
    payload = {
        "schema": "rtl2lean-temporal_challenges-baseline-v1", "results": results,
        "capability": {
            "no_llm": True, "no_generated_lemmas": True,
            "generic_tactics": list(GENERIC_BASELINE_PROOFS),
            "reference_certificates_hidden": True, "foundation_import": "R4Foundation",
        },
        "metrics": {},
    }
    payload["metrics"] = {
        "TARGETS": len(results), "BASE_SOLVED": sum(x["status"] == "BASE_SOLVED" for x in results),
        "BASE_FAILED": sum(x["status"] == "BASE_FAILED" for x in results),
        "TLean": sum(x["lean_time_s"] for x in results), "Te2e": time.perf_counter() - started,
    }
    write_json(requirement_root / "baseline" / "results.json", payload)
    return payload


def _task(
    benchmark: Benchmark, prop: dict[str, Any], base: dict[str, Any],
    output_root: Path, future: list[dict[str, Any]],
) -> AutonomousProofTask:
    model_dir = output_root / benchmark.slug / "model"
    r3_base = (model_dir / "R3Base.lean").read_text(encoding="utf-8")
    r3_foundation = (model_dir / "R3Foundation.lean").read_text(encoding="utf-8")
    r4_foundation = (model_dir / "R4Foundation.lean").read_text(encoding="utf-8")
    snippets = [r3_base, r4_foundation, """
temporal_challenges intermediate-lemma audit policy:
- A renamed/specialized run_append, run_cons, Reachable/List induction, or existing
  L1/L2/L3/L4/foundation theorem is not a valuable intermediate lemma.
- Prefer a real phase transition, state preservation, counter progression,
  wide-state relation, prefix/suffix invariant, temporal witness,
  symbolic-position, or cross-clock bridge lemma.
""".strip()]
    for name in ["r3Step", "r3Run", *prop.get("foundation_lemmas", [])]:
        snippets.append(_declaration_block(r3_foundation + "\n" + r4_foundation, name))
    errors = "\n".join(
        (x.get("stdout", "") + x.get("stderr", ""))[-3000:]
        for x in base.get("attempts", []) if not x.get("success")
    )[-12000:]
    relevant = [
        _declaration_block(r3_foundation + "\n" + r4_foundation, name).split(":= by", 1)[0]
        for name in prop.get("foundation_lemmas", [])
    ]
    assumptions = [
        *prop.get("environment_assumptions", []), *prop.get("protocol_assumptions", []),
        *prop.get("reset_assumptions", []),
    ]
    return AutonomousProofTask(
        dut=benchmark.design_id, target_name=prop["property_id"],
        target_statement=prop["theorem_statement"], property_type=prop["property_family"],
        state_type=f"{benchmark.top_module}State",
        required_state_fields=list(prop.get("referenced_state_fields", [])),
        required_input_fields=list(prop.get("referenced_inputs", [])), assumptions=assumptions,
        context_import="R4Foundation", context_snippets=snippets,
        relevant_foundational_lemmas=relevant, base_lean_error=errors,
        future_targets=[{"name": x["property_id"], "statement": x["theorem_statement"]} for x in future[:3]],
    )


def _token_sum(proof_result: dict[str, Any]) -> int | None:
    values = []
    for item in proof_result.get("history", proof_result.get("attempt_history", [])):
        provider = item.get("provider") or item.get("provider_call") or {}
        token = provider.get("tokens")
        if isinstance(token, int):
            values.append(token)
    return sum(values) if values else None


def _metadata_token_sum(proof_root: Path, expected_calls: int) -> int | None:
    """Recover tokens from historical calls made before provider data entered history.

    A failed infrastructure run may have left older metadata in the same call
    directories.  The latest ``expected_calls`` files are the calls belonging
    to the saved proof result, so stale failed-run files are not double-counted.
    """
    paths = sorted(
        proof_root.glob("llm_calls/**/*_metadata.json"),
        key=lambda path: path.stat().st_mtime_ns,
        reverse=True,
    )[:expected_calls]
    values = []
    for path in paths:
        token = _read(path).get("tokens")
        if isinstance(token, int):
            values.append(token)
    return sum(values) if values else None


def _context_metrics(task: AutonomousProofTask) -> dict[str, int]:
    serialized = json.dumps(asdict(task), ensure_ascii=False, sort_keys=True)
    return {
        "context_chars": len(serialized),
        "context_lines": serialized.count("\n") + 1,
        "context_tokens_estimate": (len(serialized) + 3) // 4,
    }


def _all_foundation_statements(output_root: Path, benchmark: Benchmark) -> list[dict[str, str]]:
    rows = _foundation_statements(output_root, benchmark)
    r4 = output_root / benchmark.slug / "model" / "R4Foundation.lean"
    text = r4.read_text(encoding="utf-8") if r4.is_file() else ""
    for match in re.finditer(r"(?ms)^theorem\s+([A-Za-z_][A-Za-z0-9_']*)\s*:\s*(.*?)\s*:=\s*by", text):
        rows.append({"name": match.group(1), "statement": match.group(2).strip()})
    return rows


def _simple_foundation_specialization(
    lemma: dict[str, Any], foundation: list[dict[str, str]],
) -> tuple[bool, list[str]]:
    """Conservatively reject renamed/specialized foundation wrappers as novel."""
    proof = lemma.get("proof_body") or lemma.get("proof", "")
    used = set(lemma.get("used_lemmas", [])) | set(lemma.get("dependencies", []))
    foundation_names = {row["name"] for row in foundation}
    referenced = sorted(name for name in foundation_names if name in used or re.search(
        rf"(?<![A-Za-z0-9_']){re.escape(name)}\b", proof
    ))
    body_lines = [line.strip() for line in proof.splitlines() if line.strip()]
    if body_lines and body_lines[0] == "by":
        body_lines.pop(0)
    while body_lines and body_lines[0].startswith("intro "):
        body_lines.pop(0)
    structural = re.compile(r"^(?:constructor|cases|rcases|induction|have|suffices|show|rw)\b")
    exact_wrapper = (
        bool(body_lines) and body_lines[0].startswith("exact ") and bool(referenced)
        and not any(structural.match(line) for line in body_lines)
    )
    known_generic = sorted(name for name in referenced if re.search(
        r"(?:run_append|run_cons|reachable|obeys_of_along|exec_append|along_take|"
        r"observe_preserved|prefix_observe_preserved|eventually_after_prefix|"
        r"bounded_eventually_after_prefix|until_after_prefix)$", name, re.I
    ))
    # Merely mentioning a generic theorem inside a real constructor/case split
    # is not enough to reject a phase-composition lemma.  The fail-closed case
    # is a wrapper whose only substantive step is exact foundation application.
    simple = exact_wrapper
    reasons = []
    if exact_wrapper:
        reasons.append("EXACT_FOUNDATION_WRAPPER")
    if known_generic:
        reasons.append("KNOWN_GENERIC_SPECIALIZATION:" + ",".join(known_generic))
    return simple, reasons


def _audit_intermediate_novelty(
    lemmas: list[dict[str, Any]], prop: dict[str, Any], foundation: list[dict[str, str]],
    proof: dict[str, Any], direct_result: dict[str, Any],
) -> list[dict[str, Any]]:
    base_novelty = [_novelty(x, prop, foundation) for x in lemmas]
    usage_map = {x["lemma"]: x for x in proof.get("intermediate_lemma_usage", [])}
    final_lines = len([x for x in (proof.get("final_proof") or "").splitlines() if x.strip()])
    direct_lines = len([x for x in (direct_result.get("final_proof") or "").splitlines() if x.strip()])
    rows = []
    for row, lemma in zip(base_novelty, lemmas):
        use = usage_map.get(lemma.get("name"), {})
        simple_specialization, reasons = _simple_foundation_specialization(lemma, foundation)
        if simple_specialization:
            row["trivial_specialization"] = True
            row["semantic_novelty"] = False
        row.update({
            "novel": row["semantic_novelty"], "used_by_final_proof": bool(use),
            "abstraction_gain": "NONE_SIMPLE_SPECIALIZATION" if simple_specialization else (
                "TRACE_OR_PHASE_ABSTRACTION" if re.search(
                    r"Along|Obeys|Until|prefix|phase", lemma.get("proposition", ""), re.I
                ) else "LOCAL_ASSERTION"
            ),
            "specialization_reasons": reasons,
            "proof_reduction": direct_lines - final_lines,
            "proof_reduction_method": "direct final-proof lines minus lemma-first final-proof lines",
            "direct_proof_lines": direct_lines,
            "lemma_first_final_proof_lines": final_lines,
            "intermediate_proof_lines": len([
                line for line in lemma.get("proof_body", "").splitlines() if line.strip()
            ]),
            "target_specific": row["target_specific"],
        })
        rows.append(row)
    return rows


def run_direct(
    benchmarks: list[Benchmark], corpus: dict[str, Any], baseline: dict[str, Any],
    output_root: Path, requirement_root: Path, provider_options: dict[str, Any],
    resume: bool = False,
) -> dict[str, Any]:
    benchmark_map = {x.design_id: x for x in benchmarks}
    properties = {(x["dut"], x["property_id"]): x for x in corpus["properties"]}
    failed = [x for x in baseline["results"] if x["status"] == "BASE_FAILED"]
    provider = CodexCLIProvider(workdir=Path(__file__).resolve().parents[2], **provider_options)
    if failed and not provider.available:
        raise RuntimeError("Codex CLI provider unavailable for temporal_challenges Direct arm")
    results = []
    started = time.perf_counter()
    for index, base in enumerate(failed):
        prop = properties[(base["dut"], base["property_id"])]
        benchmark = benchmark_map[base["dut"]]
        root = requirement_root / "direct_llm" / "targets" / benchmark.slug / f"{index:03d}_{prop['property_id']}"
        saved = root / "result.json"
        task = _task(benchmark, prop, base, output_root, [
            properties[(x["dut"], x["property_id"])]
            for x in failed[index + 1:] if x["dut"] == base["dut"]
        ])
        if resume and saved.is_file():
            prior = _read(saved)
            history = prior.get("proof_result", {}).get("history", [])
            # A run that never reached structured-candidate or Lean checking is
            # an infrastructure failure, not a Direct proof outcome.
            if any(x.get("status") != "PROVIDER_FAILURE" for x in history):
                if prior.get("tokens") is None:
                    prior["tokens"] = _metadata_token_sum(root / "proof", prior.get("llm_calls", 0))
                prior.update(_context_metrics(task))
                write_json(saved, prior)
                results.append(prior); continue
        proof = run_direct_without_intermediate(
            task, benchmark,
            output_root / benchmark.slug / "model", root / "proof", provider,
            budget_calls=EQUAL_TOTAL_LLM_CALL_BUDGET,
        )
        token_count = _token_sum(proof)
        if token_count is None:
            token_count = _metadata_token_sum(root / "proof", proof["llm_calls"])
        result = {
            "dut": prop["dut"], "property_id": prop["property_id"],
            "property_family": prop["property_family"],
            "status": "DIRECT_SOLVED" if proof["target_kernel_pass"] else "DIRECT_FAILED",
            "target_kernel_pass": proof["target_kernel_pass"], "final_proof": proof.get("final_proof"),
            "llm_calls": proof["llm_calls"], "tokens": token_count,
            "repair_rounds": max(0, proof["llm_calls"] - 1),
            "llm_time_s": proof["llm_time_s"], "lean_time_s": proof["lean_time_s"],
            "Te2e": proof["llm_time_s"] + proof["lean_time_s"],
            "proof_result": proof, "theorem_statement": prop["theorem_statement"],
            "new_intermediate_lemmas": 0,
            **_context_metrics(task),
        }
        write_json(saved, result); results.append(result)
    payload = {
        "schema": "rtl2lean-temporal_challenges-direct-v1", "results": results,
        "budget": {"max_llm_calls": EQUAL_TOTAL_LLM_CALL_BUDGET, "same_as_lemma_first": True},
        "metrics": {
            "TARGETS": len(results), "DIRECT_SOLVED": sum(x["status"] == "DIRECT_SOLVED" for x in results),
            "DIRECT_FAILED": sum(x["status"] == "DIRECT_FAILED" for x in results),
            "LLM_CALLS": sum(x["llm_calls"] for x in results),
            "TOKENS_RECORDED": sum(x["tokens"] or 0 for x in results),
            "TLLM": sum(x["llm_time_s"] for x in results),
            "TLean": sum(x["lean_time_s"] for x in results),
            "Te2e": sum(x["Te2e"] for x in results),
            "CONTEXT_CHARS": sum(x["context_chars"] for x in results),
        },
    }
    write_json(requirement_root / "direct_llm" / "results.json", payload)
    audit_direct_inline(payload, requirement_root)
    return payload


def _proof_ast_depth(proof: str) -> int:
    depth = 1
    for line in proof.splitlines():
        spaces = len(line) - len(line.lstrip())
        depth = max(depth, spaces // 2 + 1)
    return depth


def _proof_ast_size(proof: str) -> int:
    """Deterministic lexical syntax-node proxy for comparing Lean proofs."""
    return len(re.findall(
        r"[A-Za-z_][A-Za-z0-9_'.]*|[0-9]+|:=|=>|→|∀|∧|∨|⟨|⟩|[·(){}\[\],]",
        proof,
    ))


def audit_direct_inline(direct: dict[str, Any], requirement_root: Path) -> dict[str, Any]:
    rows = []
    for result in direct["results"]:
        proof = result.get("final_proof") or ""
        count = lambda word: len(re.findall(rf"\b{word}\b", proof))
        row = {
            "dut": result["dut"], "property_id": result["property_id"],
            "inline_intermediate_count": sum(count(x) for x in ("have", "let", "suffices", "show")),
            "induction_count": count("induction"),
            "case_split_count": count("cases") + count("rcases") + count("constructor"),
            "local_have_count": count("have"), "proof_ast_depth": _proof_ast_depth(proof),
            "proof_ast_size": _proof_ast_size(proof),
            "tokens": {x: count(x) for x in (
                "have", "let", "suffices", "show", "induction", "cases", "rcases", "constructor"
            )},
            "proof_lines": len([x for x in proof.splitlines() if x.strip()]),
            "status": result["status"],
        }
        rows.append(row)
    payload = {
        "schema": "rtl2lean-temporal_challenges-inline-audit-v1",
        "proof_ast_size_method": "deterministic Lean-proof lexical syntax-node proxy",
        "rows": rows,
    }
    write_json(requirement_root / "direct_llm" / "inline_decomposition_audit.json", payload)
    return payload


def run_lemma_first(
    benchmarks: list[Benchmark], corpus: dict[str, Any], baseline: dict[str, Any],
    direct: dict[str, Any], output_root: Path, requirement_root: Path,
    provider_options: dict[str, Any], resume: bool = False,
) -> dict[str, Any]:
    benchmark_map = {x.design_id: x for x in benchmarks}
    properties = {(x["dut"], x["property_id"]): x for x in corpus["properties"]}
    direct_map = {(x["dut"], x["property_id"]): x for x in direct["results"]}
    failed = [x for x in baseline["results"] if x["status"] == "BASE_FAILED"]
    provider = CodexCLIProvider(workdir=Path(__file__).resolve().parents[2], **provider_options)
    if failed and not provider.available:
        raise RuntimeError("Codex CLI provider unavailable for temporal_challenges Lemma-First arm")
    results, intermediate, novelty, causal = [], [], [], []
    started = time.perf_counter()
    for index, base in enumerate(failed):
        prop = properties[(base["dut"], base["property_id"])]
        benchmark = benchmark_map[base["dut"]]
        root = requirement_root / "lemma_first" / "targets" / benchmark.slug / f"{index:03d}_{prop['property_id']}"
        saved = root / "result.json"
        future = [properties[(x["dut"], x["property_id"])] for x in failed[index + 1:] if x["dut"] == base["dut"]]
        task = _task(benchmark, prop, base, output_root, future)
        if resume and saved.is_file():
            prior = _read(saved)
            history = prior.get("proof_result", {}).get("attempt_history", [])
            if any(x.get("event") != "LLM_PROVIDER_FAILURE" for x in history):
                if prior.get("tokens") is None:
                    prior["tokens"] = _metadata_token_sum(root / "proof", prior.get("llm_calls", 0))
                prior.update(_context_metrics(task))
                foundation = _all_foundation_statements(output_root, benchmark)
                prior["lemma_novelty"] = _audit_intermediate_novelty(
                    prior.get("intermediate_lemmas", []), prop, foundation,
                    prior.get("proof_result", {}), direct_map[(prop["dut"], prop["property_id"])],
                )
                write_json(saved, prior)
                result = prior; results.append(result)
                intermediate.extend(result.get("intermediate_lemmas", []))
                novelty.extend(result.get("lemma_novelty", [])); causal.append(result["causal_row"])
                continue
        pool_path = root / "initial_empty_pool.json"
        write_json(pool_path, {
            "schema": PersistentLocalLemmaPool.SCHEMA, "dut": benchmark.design_id,
            "lemmas": [], "metrics": {"verified_lemmas": 0, "actual_reused_lemmas": 0, "actual_reuse_hits": 0},
        })
        pool = PersistentLocalLemmaPool(pool_path, benchmark.design_id)
        proof = run_budgeted_proof_search(
            task, provider, pool,
            output_root / benchmark.slug / "model", root / "proof", LEMMA_FIRST_BUDGET,
            allow_pool_first=False,
        )
        lemmas = [asdict(x) for x in pool.lemmas
                  if x.origin == "llm" and x.source_target == prop["property_id"]]
        foundation = _all_foundation_statements(output_root, benchmark)
        usage = proof.get("intermediate_lemma_usage", [])
        direct_result = direct_map[(prop["dut"], prop["property_id"])]
        novelty_rows = _audit_intermediate_novelty(
            lemmas, prop, foundation, proof, direct_result,
        )
        causal_row = {
            "dut": prop["dut"], "property_id": prop["property_id"],
            "arm_A_baseline": "FAIL", "arm_B_direct": direct_result["status"],
            "arm_C_lemma_first": "LEMMA_FIRST_SOLVED" if proof["target_kernel_pass"] else "LEMMA_FIRST_FAILED",
            "same_theorem": direct_result["theorem_statement"] == prop["theorem_statement"],
            "same_model": True, "same_foundation": True, "same_retrieval_policy": True,
            "same_total_llm_call_budget": True,
            "intermediate_lemma_causally_helpful": (
                direct_result["status"] == "DIRECT_FAILED" and proof["target_kernel_pass"]
            ),
            "deletion_checks": usage,
        }
        result = {
            "dut": prop["dut"], "property_id": prop["property_id"],
            "property_family": prop["property_family"],
            "status": "LEMMA_FIRST_SOLVED" if proof["target_kernel_pass"] else "LEMMA_FIRST_FAILED",
            "target_kernel_pass": proof["target_kernel_pass"], "final_proof": proof.get("final_proof"),
            "llm_calls": proof["total_llm_calls"], "tokens": (
                _token_sum(proof) if _token_sum(proof) is not None
                else _metadata_token_sum(root / "proof", proof["total_llm_calls"])
            ),
            "repair_rounds": proof["repair_rounds_used"], "llm_time_s": proof["llm_time_s"],
            "lean_time_s": proof["lean_time_s"], "Te2e": proof["llm_time_s"] + proof["lean_time_s"],
            "intermediate_lemmas": lemmas, "lemma_novelty": novelty_rows,
            "causal_row": causal_row, "proof_result": proof,
            "theorem_statement": prop["theorem_statement"],
            **_context_metrics(task),
        }
        write_json(saved, result); results.append(result)
        intermediate.extend(lemmas); novelty.extend(novelty_rows); causal.append(causal_row)
    payload = {
        "schema": "rtl2lean-temporal_challenges-lemma-first-v1", "results": results,
        "budget": {**asdict(LEMMA_FIRST_BUDGET), "same_as_direct_total_llm_calls": True},
        "metrics": {
            "TARGETS": len(results),
            "LEMMA_FIRST_SOLVED": sum(x["status"] == "LEMMA_FIRST_SOLVED" for x in results),
            "LEMMA_FIRST_FAILED": sum(x["status"] == "LEMMA_FIRST_FAILED" for x in results),
            "VERIFIED_INTERMEDIATE_LEMMAS": len(intermediate),
            "VALUABLE_INTERMEDIATE_LEMMAS": sum(
                row.get("novel") and row.get("used_by_final_proof") for row in novelty
            ),
            "STRICT_CAUSAL": sum(x["intermediate_lemma_causally_helpful"] for x in causal),
            "LLM_CALLS": sum(x["llm_calls"] for x in results),
            "TOKENS_RECORDED": sum(x["tokens"] or 0 for x in results),
            "TLLM": sum(x["llm_time_s"] for x in results),
            "TLean": sum(x["lean_time_s"] for x in results),
            "Te2e": sum(x["Te2e"] for x in results),
            "CONTEXT_CHARS": sum(x["context_chars"] for x in results),
        },
    }
    write_json(requirement_root / "lemma_first" / "results.json", payload)
    write_json(requirement_root / "lemma_first" / "intermediate_lemmas.json", {"lemmas": intermediate})
    write_json(requirement_root / "lemma_first" / "novelty.json", {"rows": novelty})
    write_json(requirement_root / "lemma_first" / "causal_ablation.json", {"rows": causal})
    return payload
