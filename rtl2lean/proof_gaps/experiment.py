"""Freeze-first, fair three-arm experiment for proof_gaps."""
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
from rtl2lean.compositional_proofs.experiment import (
    BASELINE_PROOFS, _declaration_block, _failure_kind, _require_live_provider,
)
from rtl2lean.temporal.experiment import _novelty


MAX_LLM_CALLS = 8
MAX_TOTAL_TOKENS = 120_000
MAX_REPAIRS_PER_CANDIDATE = 1
PROVIDER_TIMEOUT_S = 300
LEMMA_BUDGET = ProvingBudget(
    max_generation_rounds=4,
    max_repair_rounds_per_candidate=MAX_REPAIRS_PER_CANDIDATE,
    max_intermediate_lemmas=3,
    max_llm_calls=MAX_LLM_CALLS,
    max_total_tokens=MAX_TOTAL_TOKENS,
)
THEOREM_RE = re.compile(
    r"(?ms)^theorem\s+([A-Za-z_][A-Za-z0-9_']*)\s+(.*?)\s*:=\s*by"
)


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
    benchmarks: list[Benchmark], analyzed: dict[str, Any], output_root: Path,
    requirement_root: Path,
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
            _source(benchmark, f"def {prop['property_id']}__statement : Prop := {prop['theorem_statement']}"),
            encoding="utf-8",
        )
        statement_check = _lean_check(statement_path, output_root / benchmark.slug / "model", 1200)
        reference_path.write_text(
            _proof_source(benchmark, prop, prop["reference_proof"]), encoding="utf-8"
        )
        reference_check = (_lean_check(reference_path, output_root / benchmark.slug / "model", 1200)
                           if statement_check["success"] else None)
        valid = bool(statement_check["success"] and reference_check and reference_check["success"])
        checked = {**prop, "validation_status": "KERNEL_VALIDATED" if valid else "REJECTED_BEFORE_FREEZE"}
        if valid:
            accepted.append(checked)
        validation.append({
            "property_id": prop["property_id"], "dut": prop["dut"], "accepted": valid,
            "classification_before_proof": prop["classification"],
            "statement_check": statement_check, "reference_check": reference_check,
            "rejection_reason": None if valid else (
                "ILL_TYPED_STATEMENT" if not statement_check["success"] else "REFERENCE_PROOF_REJECTED"
            ),
        })
    final = {
        **analyzed,
        "schema": "rtl2lean-proof_gaps-frozen-corpus-v1",
        "properties": accepted,
        "frozen_before_baseline": True,
        "frozen_before_llm": True,
        "freeze_time": datetime.now(timezone.utc).isoformat(),
        "metrics": {
            **analyzed["metrics"],
            "N_VALIDATED": len(accepted),
            "N_VALIDATION_REJECTED": len(analyzed["properties"]) - len(accepted),
            "N_FOUNDATIONALLY_COVERED": sum(x["classification"] == "FOUNDATIONALLY_COVERED" for x in accepted),
            "N_INTERMEDIATE_LEMMA_CHALLENGE": sum(x["classification"] == "INTERMEDIATE_LEMMA_CHALLENGE" for x in accepted),
        },
    }
    final_path = requirement_root / "corpus" / "final_properties.json"
    write_json(final_path, final)
    write_json(requirement_root / "corpus" / "challenge_properties.json", {
        "schema": "rtl2lean-proof_gaps-challenges-v1",
        "frozen_before_proof": True,
        "properties": [x for x in accepted if x["classification"] == "INTERMEDIATE_LEMMA_CHALLENGE"],
    })
    write_json(requirement_root / "corpus" / "validation.json", {"rows": validation})
    write_json(requirement_root / "corpus" / "freeze.json", {
        "schema": "rtl2lean-proof_gaps-freeze-v1",
        "frozen_before_baseline": True,
        "final_properties_sha256": sha256(final_path),
        "property_count": len(accepted),
        "properties": [{
            "property_id": x["property_id"], "dut": x["dut"],
            "classification": x["classification"],
            "statement_sha256": hashlib.sha256(x["theorem_statement"].encode()).hexdigest(),
            "gap_analysis_sha256": hashlib.sha256(json.dumps(
                x["proof_gap_analysis"], sort_keys=True, ensure_ascii=False
            ).encode()).hexdigest(),
        } for x in accepted],
    })
    return final


def run_baseline(
    benchmarks: list[Benchmark], corpus: dict[str, Any], output_root: Path,
    requirement_root: Path,
) -> dict[str, Any]:
    benchmark_map = {row.design_id: row for row in benchmarks}
    results: list[dict[str, Any]] = []
    started = time.perf_counter()
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
            "property_id": prop["property_id"], "dut": prop["dut"],
            "classification": prop["classification"], "property_family": prop["property_family"],
            "status": "BASE_SOLVED" if solved else "BASE_FAILED", "proof": solved,
            "attempts": attempts, "failure_kind": None if solved else _failure_kind(attempts),
            "lean_time_s": sum(row["elapsed_s"] for row in attempts),
            "theorem_statement": prop["theorem_statement"],
            "statement_sha256": hashlib.sha256(prop["theorem_statement"].encode()).hexdigest(),
        })
    payload = {
        "schema": "rtl2lean-proof_gaps-baseline-v1", "results": results,
        "capability": {"generic_proofs": BASELINE_PROOFS, "no_llm": True,
                       "unchanged_from_compositional_proofs": True, "reference_proofs_hidden": True},
        "metrics": {
            "TARGETS": len(results),
            "BASE_SOLVED": sum(x["status"] == "BASE_SOLVED" for x in results),
            "BASE_FAILED": sum(x["status"] == "BASE_FAILED" for x in results),
            "TLean": sum(x["lean_time_s"] for x in results),
            "Te2e": time.perf_counter() - started,
        },
    }
    write_json(requirement_root / "baseline" / "results.json", payload)
    return payload


def _task(
    benchmark: Benchmark, prop: dict[str, Any], base: dict[str, Any], output_root: Path,
) -> AutonomousProofTask:
    model = output_root / benchmark.slug / "model"
    r3_base = (model / "R3Base.lean").read_text(encoding="utf-8")
    r3_foundation = (model / "R3Foundation.lean").read_text(encoding="utf-8")
    r5_foundation = (model / "R5Foundation.lean").read_text(encoding="utf-8")
    combined = r3_foundation + "\n" + r5_foundation
    snippets = [r3_base, r5_foundation, (
        "proof_gaps fair-arm policy: prove the exact target from the supplied current theorem base. "
        "No pre-proof analyzer output or predicted missing relation is supplied. Intermediate lemmas "
        "must be semantically new, kernel checked, and not wrappers around an existing theorem."
    )]
    for name in ["r3Step", "r3Run", *prop.get("foundation_lemmas", [])]:
        snippets.append(_declaration_block(combined, name))
    errors = "\n".join(
        (row.get("stdout", "") + row.get("stderr", ""))[-2500:]
        for row in base.get("attempts", []) if not row.get("success")
    )[-12000:]
    relevant = [
        _declaration_block(combined, name).split(":= by", 1)[0]
        for name in prop.get("foundation_lemmas", [])
    ]
    return AutonomousProofTask(
        dut=benchmark.design_id,
        target_name=prop["property_id"],
        target_statement=prop["theorem_statement"],
        property_type="HIGH_LEVEL_TEMPORAL",
        state_type=f"{benchmark.top_module}State",
        required_state_fields=list(prop.get("referenced_state_fields", [])),
        required_input_fields=list(prop.get("referenced_inputs", [])),
        assumptions=[],
        context_import="R5Foundation",
        context_snippets=snippets,
        relevant_foundational_lemmas=relevant,
        base_lean_error=errors,
        future_targets=[],
    )


def _task_hash(task: AutonomousProofTask) -> str:
    return hashlib.sha256(json.dumps(asdict(task), ensure_ascii=False, sort_keys=True).encode()).hexdigest()


def _provider(options: dict[str, Any]) -> CodexCLIProvider:
    return CodexCLIProvider(workdir=Path(__file__).resolve().parents[2], **options)


def _foundation_statements(output_root: Path, benchmark: Benchmark) -> list[dict[str, str]]:
    """Read the actual theorem base, including parameterized R3Temporal theorems.

    compositional_proofs's historical parser accepted only ``theorem name :`` and
    therefore omitted declarations such as ``exec_append (step ...) :``.  A
    proof-gap novelty audit must include those declarations or a specialized
    wrapper can be mislabeled as new.
    """
    rows: list[dict[str, str]] = []
    model = output_root / benchmark.slug / "model"
    for filename in (
        "Framework.lean", "R3Base.lean", "R3Foundation.lean",
        "R4Foundation.lean", "R5Foundation.lean",
    ):
        path = model / filename
        if not path.is_file():
            continue
        for match in THEOREM_RE.finditer(path.read_text(encoding="utf-8")):
            raw_name = match.group(1)
            name = f"R3Temporal.{raw_name}" if filename == "R3Base.lean" else raw_name
            rows.append({
                "name": name,
                "statement": re.sub(r"^:\s*", "", match.group(2).strip()),
                "source_file": str(path),
            })
    return rows


def _alpha_fingerprint(statement: str) -> str:
    """Conservatively canonicalize explicitly bound ASCII identifiers."""
    names: list[str] = []
    # Covers both ``∀ (x : T)`` and theorem parameters ``(x y : T)``.
    binder = re.compile(
        r"[({]\s*([A-Za-z_][A-Za-z0-9_']*(?:\s+[A-Za-z_][A-Za-z0-9_']*)*)\s*:"
    )
    for match in binder.finditer(statement):
        names.extend(match.group(1).split())
    mapping = {name: f"__bound_{index}" for index, name in enumerate(dict.fromkeys(names))}
    renamed = re.sub(
        r"(?<![A-Za-z0-9_'])[A-Za-z_][A-Za-z0-9_']*(?![A-Za-z0-9_'])",
        lambda match: mapping.get(match.group(0), match.group(0)), statement,
    )
    return re.sub(r"\s+", "", renamed).replace("(", "").replace(")", "")


def _known_semantic_specialization(
    lemma: dict[str, Any], prop: dict[str, Any], foundation: list[dict[str, str]],
) -> list[str]:
    """Recognize definitional instances of existing generic temporal facts."""
    statement = re.sub(
        r"\s+", "",
        lemma.get("proposition") or lemma.get("statement") or lemma.get("lemma_statement", ""),
    )
    foundation_names = {row["name"] for row in foundation}
    reasons: list[str] = []
    # r3Run is R3Temporal.exec specialized to r3Step.  Taking ys=[item] in
    # exec_append yields this exact relation after definitional reduction.
    if (
        {"R3Temporal.exec_append", "r3_run_append"} & foundation_names
        and "r3Run" in statement and "++[" in statement
        and "=r3Step" in statement and "R3Temporal.Along" not in statement
    ):
        source = "r3_run_append" if "r3_run_append" in foundation_names else "R3Temporal.exec_append"
        reasons.append(f"DEFINITIONAL_INSTANCE:{source}(ys := [item])")
    if (
        ".toNat" in statement
        and _alpha_fingerprint((
            lemma.get("proposition") or lemma.get("statement")
            or lemma.get("lemma_statement", "")
        ).replace(".toNat", ""))
        == _alpha_fingerprint(prop["theorem_statement"])
    ):
        reasons.append("CONGRUENCE_SPECIALIZATION_OF_TARGET:BitVec.toNat")
    proof = lemma.get("proof_body") or lemma.get("proof", "")
    referenced = [
        name for name in foundation_names
        if re.search(rf"(?<![A-Za-z0-9_']){re.escape(name)}\b", proof)
    ]
    body = [line.strip() for line in proof.splitlines() if line.strip()]
    if body and body[0] == "by":
        body.pop(0)
    while body and body[0].startswith("intro "):
        body.pop(0)
    if referenced and len(body) == 1 and re.match(r"^(?:rw|simpa)\b", body[0]):
        reasons.append("REWRITE_ONLY_FOUNDATION_WRAPPER:" + ",".join(sorted(referenced)))
    return reasons


def _r7_novelty(
    lemma: dict[str, Any], prop: dict[str, Any], foundation: list[dict[str, str]],
    target_equivalence_check: dict[str, Any] | None = None,
) -> dict[str, Any]:
    """proof_gaps novelty: alpha lookup plus specialization/duplication audit."""
    row = _novelty(lemma, prop, foundation)
    statement = (
        lemma.get("proposition") or lemma.get("statement")
        or lemma.get("lemma_statement", "")
    )
    fingerprint = _alpha_fingerprint(statement)
    alpha_matches = [
        item["name"] for item in foundation
        if _alpha_fingerprint(item["statement"]) == fingerprint
    ]
    target_equal = (
        fingerprint == _alpha_fingerprint(prop["theorem_statement"])
        or bool(target_equivalence_check and target_equivalence_check.get("success"))
    )
    simple, simple_reasons = _simple_foundation_specialization(lemma, foundation)
    semantic_reasons = _known_semantic_specialization(lemma, prop, foundation)
    duplicated = bool(target_equal or alpha_matches or simple or semantic_reasons)
    row.update({
        "alpha_equivalent_to_foundation": bool(alpha_matches),
        "alpha_equivalent_foundation_matches": alpha_matches,
        "target_equivalent": target_equal,
        "target_definitional_equivalence_check": target_equivalence_check,
        "trivial_specialization": bool(target_equal or simple or semantic_reasons),
        "foundation_specialization": bool(simple or semantic_reasons),
        "specialization_reasons": simple_reasons + semantic_reasons,
        "semantic_duplication": duplicated,
        "semantic_novelty": bool(not target_equal and not duplicated),
        "novelty_method": (
            "alpha-normalized proposition lookup; target-equivalence rejection; "
            "foundation-wrapper analysis; definitional generic-theorem specialization audit"
        ),
    })
    return row


def _target_equivalence_check(
    benchmark: Benchmark, prop: dict[str, Any], lemma: dict[str, Any],
    model_root: Path, audit_root: Path,
) -> dict[str, Any]:
    """Ask Lean whether the candidate and target Props are definitionally equal."""
    safe_name = re.sub(r"[^A-Za-z0-9_]", "_", lemma.get("name", "candidate"))
    path = audit_root / f"{safe_name}__target_defeq.lean"
    path.parent.mkdir(parents=True, exist_ok=True)
    statement = (
        lemma.get("proposition") or lemma.get("statement")
        or lemma.get("lemma_statement", "False")
    )
    declaration = (
        f"example : (({statement}) ↔ ({prop['theorem_statement']})) := by\n"
        "  rfl"
    )
    path.write_text(_source(benchmark, declaration), encoding="utf-8")
    return _lean_check(path, model_root, 600)


def _aggregate(rows: list[dict[str, Any]], solved_status: str) -> list[dict[str, Any]]:
    keys = sorted({(row["dut"], row["property_id"]) for row in rows})
    result = []
    for key in keys:
        trials = [row for row in rows if (row["dut"], row["property_id"]) == key]
        successes = sum(row["status"] == solved_status for row in trials)
        result.append({
            "dut": key[0], "property_id": key[1], "trials": len(trials),
            "successes": successes, "success_rate": successes / len(trials),
            "mean_calls": statistics.mean(row["llm_calls"] for row in trials),
            "mean_tokens": statistics.mean(row["tokens"] for row in trials),
            "mean_lean_time_s": statistics.mean(row["lean_time_s"] for row in trials),
            "mean_total_time_s": statistics.mean(row["Te2e"] for row in trials),
        })
    return result


def _direct_gap_audit(
    rows: list[dict[str, Any]], prop_map: dict[tuple[str, str], dict[str, Any]],
    requirement_root: Path,
) -> dict[str, Any]:
    audited = []
    for row in rows:
        proof = row.get("final_proof") or ""
        prop = prop_map[(row["dut"], row["property_id"])]
        count = lambda word: len(re.findall(rf"\b{word}\b", proof))
        markers = {
            "have": count("have"), "suffices": count("suffices"),
            "induction": count("induction"), "cases": count("cases") + count("rcases"),
            "constructor": count("constructor"), "local_fact": count("have") + count("let") + count("show"),
        }
        existing_refs = [name for name in prop.get("foundation_lemmas", []) if name in proof]
        local = sum(markers.values()) > 0
        if row["status"] != "DIRECT_SOLVED":
            classification = "UNRESOLVED"
        elif local and existing_refs:
            classification = "MIXED"
        elif local:
            classification = "INLINE_NEW_RELATION"
        elif existing_refs or "R3Temporal." in proof:
            classification = "EXISTING_CHAIN"
        else:
            classification = "OTHER"
        audited.append({
            "trial": row["trial"], "dut": row["dut"], "property_id": row["property_id"],
            "status": row["status"], "classification": classification,
            "syntax": markers, "existing_foundation_references": existing_refs,
            "predicted_gap_type": prop["proof_gap_analysis"].get("missing_relation_type"),
            "direct_autonomously_resolved_gap": row["status"] == "DIRECT_SOLVED" and local,
            "proof_ast_depth": _proof_ast_depth(proof), "proof_ast_size": _proof_ast_size(proof),
        })
    payload = {"schema": "rtl2lean-proof_gaps-direct-gap-audit-v1", "rows": audited}
    write_json(requirement_root / "direct" / "gap_resolution_audit.json", payload)
    return payload


def run_direct(
    benchmarks: list[Benchmark], corpus: dict[str, Any], baseline: dict[str, Any],
    output_root: Path, requirement_root: Path, provider_options: dict[str, Any],
    trials: int, resume: bool,
) -> dict[str, Any]:
    benchmark_map = {row.design_id: row for row in benchmarks}
    prop_map = {(row["dut"], row["property_id"]): row for row in corpus["properties"]}
    failed = [row for row in baseline["results"] if row["status"] == "BASE_FAILED"]
    rows: list[dict[str, Any]] = []
    for trial in range(1, trials + 1):
        provider = _provider(provider_options)
        if failed and not provider.available:
            raise RuntimeError("Codex CLI unavailable for proof_gaps Direct arm")
        for index, base in enumerate(failed):
            prop = prop_map[(base["dut"], base["property_id"])]
            benchmark = benchmark_map[prop["dut"]]
            task = _task(benchmark, prop, base, output_root)
            root = requirement_root / "direct" / "trials" / f"trial_{trial:02d}" / benchmark.slug / f"{index:03d}_{prop['property_id']}"
            saved = root / "result.json"
            digest = hashlib.sha256(prop["theorem_statement"].encode()).hexdigest()
            if resume and saved.is_file() and _read(saved).get("statement_sha256") == digest:
                rows.append(_read(saved)); continue
            proof = run_direct_without_intermediate(
                task, benchmark, output_root / benchmark.slug / "model", root / "proof", provider,
                budget_calls=MAX_LLM_CALLS, budget_tokens=MAX_TOTAL_TOKENS,
                max_repair_rounds_per_candidate=MAX_REPAIRS_PER_CANDIDATE,
            )
            _require_live_provider(proof, direct=True)
            result = {
                "trial": trial, "dut": prop["dut"], "property_id": prop["property_id"],
                "property_family": prop["property_family"],
                "status": "DIRECT_SOLVED" if proof["target_kernel_pass"] else "DIRECT_FAILED",
                "target_kernel_pass": proof["target_kernel_pass"], "final_proof": proof.get("final_proof"),
                "llm_calls": proof["llm_calls"], "tokens": proof.get("llm_tokens", 0),
                "repair_rounds": proof.get("repair_rounds_used", 0),
                "lean_time_s": proof["lean_time_s"], "llm_time_s": proof["llm_time_s"],
                "Te2e": proof["lean_time_s"] + proof["llm_time_s"], "proof_result": proof,
                "theorem_statement": prop["theorem_statement"], "statement_sha256": digest,
                "task_sha256": _task_hash(task), **_context_metrics(task),
            }
            write_json(saved, result); rows.append(result)
    payload = {
        "schema": "rtl2lean-proof_gaps-direct-v1", "trial_results": rows,
        "per_target": _aggregate(rows, "DIRECT_SOLVED"),
        "budget": {"max_llm_calls": MAX_LLM_CALLS, "max_total_tokens": MAX_TOTAL_TOKENS,
                   "max_repair_rounds_per_candidate": MAX_REPAIRS_PER_CANDIDATE,
                   "timeout_s": PROVIDER_TIMEOUT_S},
        "metrics": {"TRIAL_TARGETS": len(rows), "SOLVED": sum(x["status"] == "DIRECT_SOLVED" for x in rows),
                    "FAILED": sum(x["status"] == "DIRECT_FAILED" for x in rows),
                    "LLM_CALLS": sum(x["llm_calls"] for x in rows), "TOKENS": sum(x["tokens"] for x in rows)},
    }
    write_json(requirement_root / "direct" / "results.json", payload)
    _direct_gap_audit(rows, prop_map, requirement_root)
    return payload


def _candidate_policy(
    candidate: Any, prop: dict[str, Any], foundation: list[dict[str, str]],
    benchmark: Benchmark, model_root: Path, audit_root: Path,
) -> None:
    if candidate.lemma_name == prop["property_id"]:
        return
    lemma = asdict(candidate)
    defeq = _target_equivalence_check(
        benchmark, prop, lemma, model_root, audit_root
    )
    novelty = _r7_novelty(lemma, prop, foundation, defeq)
    if not novelty["semantic_novelty"]:
        reasons = novelty.get("specialization_reasons", [])
        suffix = ": " + ",".join(reasons) if reasons else ""
        raise ValueError(
            "proof_gaps rejects alpha-equivalent, target-equal, or existing intermediate lemma" + suffix
        )


def _gap_alignment(prop: dict[str, Any], lemma: dict[str, Any]) -> dict[str, Any]:
    statement = lemma.get("proposition", "")
    gap = prop["gap_spec"]
    if gap is None:
        return {
            "dut": prop["dut"], "property_id": prop["property_id"],
            "lemma": lemma.get("name"), "predicted_gap_type": None,
            "predicted_missing_relation": None,
            "classification": "NO_PREDICTED_GAP",
            "anchor_score": 0.0, "matched_anchors": [],
            "required_anchors": [], "matched_state_fields": [],
        }
    anchors = gap.get("relation_anchors", [])
    matched = [anchor for anchor in anchors if anchor in statement]
    score = len(matched) / len(anchors) if anchors else 0.0
    fields = prop.get("referenced_state_fields", [])
    matched_fields = [field for field in fields if field in statement]
    expected_statement = gap.get("missing_relation_statement")
    if expected_statement and _alpha_fingerprint(statement) == _alpha_fingerprint(expected_statement):
        classification = "EXACT_MATCH"
    elif score == 1.0 and len(matched_fields) == len(fields):
        classification = "SEMANTIC_MATCH"
    elif score >= 0.6 or matched_fields:
        classification = "PARTIAL_MATCH"
    elif re.search(r"Along|r3Run|induction|prefix|phase", statement, re.I):
        classification = "DIFFERENT_VALID_DECOMPOSITION"
    else:
        classification = "NO_MATCH"
    return {
        "dut": prop["dut"], "property_id": prop["property_id"], "lemma": lemma.get("name"),
        "predicted_gap_type": gap["gap_type"], "predicted_missing_relation": gap["missing_relation"],
        "classification": classification, "anchor_score": round(score, 4),
        "matched_anchors": matched, "required_anchors": anchors,
        "matched_state_fields": matched_fields,
    }


def _audit_generated_lemmas(
    lemmas: list[dict[str, Any]], prop: dict[str, Any],
    foundation: list[dict[str, str]], proof: dict[str, Any], trial: int,
    benchmark: Benchmark, model_root: Path, audit_root: Path,
) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    """Recompute novelty/alignment so resumed runs use the current audit rules."""
    novelty_rows: list[dict[str, Any]] = []
    alignment_rows: list[dict[str, Any]] = []
    usage = {row["lemma"]: row for row in proof.get("intermediate_lemma_usage", [])}
    for lemma in lemmas:
        defeq = _target_equivalence_check(
            benchmark, prop, lemma, model_root, audit_root
        )
        novelty = _r7_novelty(lemma, prop, foundation, defeq)
        novelty.update({
            "trial": trial,
            "kernel_verified": lemma.get("kernel_verified", False),
            "NOVEL_INTERMEDIATE_LEMMA": bool(
                novelty["semantic_novelty"] and lemma.get("kernel_verified")
            ),
            "actually_used": lemma["name"] in usage,
            "causally_required": bool(
                usage.get(lemma["name"], {}).get("causally_necessary")
            ),
        })
        novelty_rows.append(novelty)
        alignment_rows.append({"trial": trial, **_gap_alignment(prop, lemma)})
    return novelty_rows, alignment_rows


def run_lemma_first(
    benchmarks: list[Benchmark], corpus: dict[str, Any], baseline: dict[str, Any],
    direct: dict[str, Any], output_root: Path, requirement_root: Path,
    provider_options: dict[str, Any], trials: int, resume: bool,
) -> dict[str, Any]:
    benchmark_map = {row.design_id: row for row in benchmarks}
    prop_map = {(row["dut"], row["property_id"]): row for row in corpus["properties"]}
    direct_map = {(row["trial"], row["dut"], row["property_id"]): row for row in direct["trial_results"]}
    failed = [row for row in baseline["results"] if row["status"] == "BASE_FAILED"]
    rows: list[dict[str, Any]] = []
    all_lemmas: list[dict[str, Any]] = []
    novelty_rows: list[dict[str, Any]] = []
    alignment_rows: list[dict[str, Any]] = []
    causal_rows: list[dict[str, Any]] = []
    for trial in range(1, trials + 1):
        provider = _provider(provider_options)
        if failed and not provider.available:
            raise RuntimeError("Codex CLI unavailable for proof_gaps Lemma-First arm")
        for index, base in enumerate(failed):
            prop = prop_map[(base["dut"], base["property_id"])]
            benchmark = benchmark_map[prop["dut"]]
            task = _task(benchmark, prop, base, output_root)
            foundation = _foundation_statements(output_root, benchmark)
            root = requirement_root / "lemma_first" / "trials" / f"trial_{trial:02d}" / benchmark.slug / f"{index:03d}_{prop['property_id']}"
            saved = root / "result.json"
            digest = hashlib.sha256(prop["theorem_statement"].encode()).hexdigest()
            if resume and saved.is_file() and _read(saved).get("statement_sha256") == digest:
                prior = _read(saved)
                lemmas = prior.get("intermediate_lemmas", [])
                audited_novelty, audited_alignment = _audit_generated_lemmas(
                    lemmas, prop, foundation, prior.get("proof_result", {}), trial,
                    benchmark, output_root / benchmark.slug / "model",
                    root / "novelty_audit",
                )
                prior["novelty"] = audited_novelty
                prior["gap_alignment"] = audited_alignment
                write_json(saved, prior)
                rows.append(prior)
                all_lemmas.extend(lemmas)
                novelty_rows.extend(audited_novelty)
                alignment_rows.extend(audited_alignment)
                causal_rows.append(prior["causal_row"])
                continue
            pool_path = root / "initial_empty_pool.json"
            write_json(pool_path, {"schema": PersistentLocalLemmaPool.SCHEMA, "dut": benchmark.design_id,
                                   "lemmas": [], "metrics": {"verified_lemmas": 0,
                                   "actual_reused_lemmas": 0, "actual_reuse_hits": 0}})
            pool = PersistentLocalLemmaPool(pool_path, benchmark.design_id)
            proof = run_budgeted_proof_search(
                task, provider, pool, output_root / benchmark.slug / "model", root / "proof",
                LEMMA_BUDGET, allow_pool_first=False,
                candidate_policy=lambda candidate: _candidate_policy(
                    candidate, prop, foundation, benchmark,
                    output_root / benchmark.slug / "model", root / "novelty_policy",
                ),
            )
            _require_live_provider(proof, direct=False)
            lemmas = [asdict(row) for row in pool.lemmas
                      if row.origin == "llm" and row.source_target == prop["property_id"]]
            target_novelty, target_alignment = _audit_generated_lemmas(
                lemmas, prop, foundation, proof, trial, benchmark,
                output_root / benchmark.slug / "model", root / "novelty_audit",
            )
            direct_row = direct_map[(trial, prop["dut"], prop["property_id"])]
            causally_required = any(row.get("causally_necessary") for row in proof.get("intermediate_lemma_usage", []))
            strict = bool(direct_row["status"] == "DIRECT_FAILED" and proof["target_kernel_pass"] and causally_required)
            causal = {
                "trial": trial, "dut": prop["dut"], "property_id": prop["property_id"],
                "baseline": "FAIL", "direct": direct_row["status"],
                "lemma_first": "LEMMA_FIRST_SOLVED" if proof["target_kernel_pass"] else "LEMMA_FIRST_FAILED",
                "causally_required_intermediate": causally_required,
                "STRICT_LEMMA_CAUSAL_GAIN": strict,
                "PROOF_GAP_FILLED_BY_INTERMEDIATE_LEMMA": bool(strict and any(
                    row["classification"] in {"SEMANTIC_MATCH", "PARTIAL_MATCH"} for row in target_alignment
                )),
                "same_theorem": direct_row["theorem_statement"] == prop["theorem_statement"],
                "same_task_context": direct_row["task_sha256"] == _task_hash(task),
                "same_budget": True,
                "deletion_checks": proof.get("intermediate_lemma_usage", []),
            }
            result = {
                "trial": trial, "dut": prop["dut"], "property_id": prop["property_id"],
                "property_family": prop["property_family"],
                "status": "LEMMA_FIRST_SOLVED" if proof["target_kernel_pass"] else "LEMMA_FIRST_FAILED",
                "target_kernel_pass": proof["target_kernel_pass"], "final_proof": proof.get("final_proof"),
                "llm_calls": proof["total_llm_calls"], "tokens": proof.get("total_llm_tokens", 0),
                "repair_rounds": proof["repair_rounds_used"], "lean_time_s": proof["lean_time_s"],
                "llm_time_s": proof["llm_time_s"], "Te2e": proof["lean_time_s"] + proof["llm_time_s"],
                "intermediate_lemmas": lemmas, "novelty": target_novelty,
                "gap_alignment": target_alignment, "causal_row": causal, "proof_result": proof,
                "theorem_statement": prop["theorem_statement"], "statement_sha256": digest,
                "task_sha256": _task_hash(task), **_context_metrics(task),
            }
            write_json(saved, result); rows.append(result); all_lemmas.extend(lemmas)
            novelty_rows.extend(target_novelty); alignment_rows.extend(target_alignment); causal_rows.append(causal)
    payload = {
        "schema": "rtl2lean-proof_gaps-lemma-first-v1", "trial_results": rows,
        "per_target": _aggregate(rows, "LEMMA_FIRST_SOLVED"),
        "budget": {**asdict(LEMMA_BUDGET), "timeout_s": PROVIDER_TIMEOUT_S},
        "metrics": {
            "TRIAL_TARGETS": len(rows), "SOLVED": sum(x["status"] == "LEMMA_FIRST_SOLVED" for x in rows),
            "FAILED": sum(x["status"] == "LEMMA_FIRST_FAILED" for x in rows),
            "VERIFIED_INTERMEDIATE_LEMMAS": len(all_lemmas),
            "NOVEL_INTERMEDIATE_LEMMAS": sum(x["NOVEL_INTERMEDIATE_LEMMA"] for x in novelty_rows),
            "STRICT_LEMMA_CAUSAL_GAIN": sum(x["STRICT_LEMMA_CAUSAL_GAIN"] for x in causal_rows),
            "PROOF_GAP_FILLED": sum(x["PROOF_GAP_FILLED_BY_INTERMEDIATE_LEMMA"] for x in causal_rows),
            "LLM_CALLS": sum(x["llm_calls"] for x in rows), "TOKENS": sum(x["tokens"] for x in rows),
        },
    }
    write_json(requirement_root / "lemma_first" / "results.json", payload)
    write_json(requirement_root / "lemma_first" / "intermediate_lemmas.json", {"lemmas": all_lemmas})
    write_json(requirement_root / "lemma_first" / "novelty.json", {"rows": novelty_rows})
    write_json(requirement_root / "lemma_first" / "gap_alignment.json", {"rows": alignment_rows})
    write_json(requirement_root / "lemma_first" / "causal_ablation.json", {"rows": causal_rows})
    return payload
