"""Stage-2/3 orchestration: theorem generation, baseline, LLM and reuse."""
from __future__ import annotations

import json
import re
import time
from dataclasses import asdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from rtl2lean.pipeline.compiler import Compilation, kernel_check
from rtl2lean.pipeline.io import sha256, write_json
from rtl2lean.proving.context import select_context
from rtl2lean.proving.llm_prover import (
    AutonomousProofTask,
    CodexCLIProvider,
    PersistentLocalLemmaPool,
    ProvingBudget,
    VerifiedLemmaRecord,
    run_budgeted_proof_search,
)
from rtl2lean.theorems.generator import GeneratedTheorem, TheoremBundle, generate_theorem_bundle


FORBIDDEN = re.compile(r"\b(?:sorry|admit|native_decide)\b|\baxiom\b|\bunsafe\b")


def generate_and_check(compilation: Compilation) -> tuple[TheoremBundle, dict[str, Any]]:
    """Generate the common theorem universe and kernel-check its definitions."""
    stage_started = time.perf_counter()
    model_dir = compilation.model_path.parent
    generation_started = time.perf_counter()
    bundle = generate_theorem_bundle(compilation.ir, compilation.typed_ir, model_dir)
    generation_elapsed = time.perf_counter() - generation_started
    check = kernel_check(bundle.foundation_path)
    write_json(model_dir / "foundation_check.json", check)
    framework_targets = [target for target in bundle.theorems if target.layer in {"L1", "L2", "L3", "L4"}]
    framework_lines = [
        "import Foundation", "", "set_option maxRecDepth 100000",
        "set_option maxHeartbeats 8000000", "", f"namespace {bundle.namespace}",
        f"open {compilation.ir.name}", "",
    ]
    for target in framework_targets:
        framework_lines.extend([
            f"theorem {target.name} : {target.statement} := {target.proof_candidates[0]}", "",
        ])
    framework_lines.extend([f"end {bundle.namespace}", ""])
    framework_path = model_dir / "Framework.lean"
    framework_path.write_text("\n".join(framework_lines), encoding="utf-8")
    framework_check = kernel_check(framework_path) if check["success"] else {
        "success": False, "returncode": None, "stdout": "", "stderr": "foundation failed",
    }
    write_json(model_dir / "framework_check.json", framework_check)
    result = {
        "schema": "rtl2lean-stage2-result-v1",
        "status": "STAGE2_PASS" if check["success"] and framework_check["success"] else "FAIL",
        "foundation": str(bundle.foundation_path),
        "foundation_sha256": sha256(bundle.foundation_path),
        "targets": str(bundle.targets_path),
        "target_count": len(bundle.theorems),
        "theorem_generation_elapsed_s": generation_elapsed,
        "elapsed_s": time.perf_counter() - stage_started,
        "layers": {
            layer: sum(target.layer == layer for target in bundle.theorems)
            for layer in ("L1", "L2", "L3", "L4", "PROPERTY")
        },
        "lean_kernel": check,
        "framework_kernel": framework_check,
    }
    write_json(model_dir.parent / "stage2.json", result)
    if not check["success"] or not framework_check["success"]:
        failed = check if not check["success"] else framework_check
        raise RuntimeError("Lean rejected theorem framework: " + (failed["stdout"] + failed["stderr"])[-4000:])
    return bundle, result


def _pool_record(target: GeneratedTheorem, proof: str, dut: str, module: str,
                 origin: str, used: list[str] | None = None) -> VerifiedLemmaRecord:
    return VerifiedLemmaRecord(
        name=target.name,
        proposition=target.statement,
        proof_body=proof,
        source_target=target.name,
        generation_round=0,
        kernel_result="PASS",
        created_time=datetime.now(timezone.utc).isoformat(),
        origin=origin,
        property_category=target.property_family,
        state_type=f"{module}State",
        involved_functions=list(target.source_functions),
        used_lemmas=used or [],
    )


def _attempt_source(bundle: TheoremBundle, module: str, pool: PersistentLocalLemmaPool,
                    target: GeneratedTheorem, proof: str,
                    omit: str | None = None) -> str:
    declarations = []
    for lemma in pool.lemmas:
        if lemma.name == target.name or lemma.name == omit:
            continue
        declarations.append(f"theorem {lemma.name} : {lemma.proposition} := {lemma.proof_body}")
    return "\n\n".join(filter(None, [
        "import Foundation",
        "set_option maxHeartbeats 4000000\nset_option maxRecDepth 100000",
        f"namespace {bundle.namespace}\nopen {module}",
        "\n\n".join(declarations),
        f"theorem {target.name} : {target.statement} := {proof}",
        f"end {bundle.namespace}",
        "",
    ]))


def _check_attempt(bundle: TheoremBundle, module: str, pool: PersistentLocalLemmaPool,
                   target: GeneratedTheorem, proof: str, path: Path,
                   omit: str | None = None) -> dict[str, Any]:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(_attempt_source(bundle, module, pool, target, proof, omit), encoding="utf-8")
    check = kernel_check(path, timeout_s=600, build_olean=False)
    return {**check, "source": str(path), "proof": proof, "omitted_pool_lemma": omit}


def _reuse_proofs(target: GeneratedTheorem, pool: PersistentLocalLemmaPool) -> list[tuple[str, str]]:
    """Produce only proposition-preserving applications of earlier verified facts."""
    candidates: list[tuple[str, str]] = []
    for lemma in pool.lemmas:
        if lemma.source_target == target.name:
            continue
        if " ".join(lemma.proposition.split()) == " ".join(target.statement.split()):
            candidates.append((lemma.name, f"by exact {lemma.name}"))
        elif target.property_family == "reachable_state_invariant" and lemma.property_category == "state_safety":
            candidates.append((lemma.name, f"by intro s _h; exact {lemma.name} s"))
    return candidates


def _reset_pool(path: Path, dut: str) -> PersistentLocalLemmaPool:
    write_json(path, {
        "schema": PersistentLocalLemmaPool.SCHEMA,
        "dut": dut,
        "lemmas": [],
        "metrics": {"verified_lemmas": 0, "actual_reused_lemmas": 0, "actual_reuse_hits": 0},
    })
    return PersistentLocalLemmaPool(path, dut)


def _run_arm(compilation: Compilation, bundle: TheoremBundle, arm: str,
             use_llm: bool, enable_reuse: bool,
             llm_model: str, reasoning_effort: str) -> dict[str, Any]:
    dut_dir = compilation.model_path.parent.parent
    arm_dir = dut_dir / "proofs" / arm
    arm_dir.mkdir(parents=True, exist_ok=True)
    pool = _reset_pool(arm_dir / "lemma_pool.json", compilation.benchmark.design_id)
    provider = CodexCLIProvider(
        model=llm_model, reasoning_effort=reasoning_effort,
        workdir=Path(__file__).resolve().parents[2],
    ) if use_llm else None
    results = []
    started = time.perf_counter()

    for index, target in enumerate(bundle.theorems):
        target_dir = arm_dir / "targets" / f"{index:03d}_{target.name}"
        attempts: list[dict[str, Any]] = []
        solved_proof: str | None = None
        method: str | None = None
        reused_lemma: str | None = None
        actual_reuse: list[dict[str, Any]] = []

        for candidate_index, proof in enumerate(target.proof_candidates):
            check = _check_attempt(
                bundle, compilation.ir.name, pool, target, proof,
                target_dir / f"baseline_{candidate_index:02d}.lean",
            )
            attempts.append({"kind": "deterministic", **check})
            if check["success"]:
                solved_proof, method = proof, "DETERMINISTIC"
                break

        if solved_proof is None and enable_reuse:
            for candidate_index, (lemma_name, proof) in enumerate(_reuse_proofs(target, pool)):
                check = _check_attempt(
                    bundle, compilation.ir.name, pool, target, proof,
                    target_dir / f"reuse_{candidate_index:02d}.lean",
                )
                attempts.append({"kind": "verified-lemma-reuse", "lemma": lemma_name, **check})
                if not check["success"]:
                    continue
                ablation = _check_attempt(
                    bundle, compilation.ir.name, pool, target, proof,
                    target_dir / "reuse_ablation" / f"without_{lemma_name}.lean", omit=lemma_name,
                )
                necessary = not ablation["success"]
                actual_reuse.append({
                    "lemma": lemma_name,
                    "source_target": next(item.source_target for item in pool.lemmas if item.name == lemma_name),
                    "reused_by": target.name,
                    "syntactically_referenced": True,
                    "kernel_ablation_without_lemma_pass": ablation["success"],
                    "causally_necessary": necessary,
                    "ablation_check": ablation,
                })
                if necessary:
                    pool.mark_reused(lemma_name, target.name)
                solved_proof, method, reused_lemma = proof, "LEMMA_REUSE", lemma_name
                break

        llm_result = None
        if solved_proof is None and provider is not None and provider.available:
            context_artifact = target_dir / "context_selection.json"
            prior = [
                {**asdict(item), "statement": item.proposition,
                 "state_fields": list(target.state_fields)}
                for item in pool.lemmas
            ]
            selected = select_context(
                target, compilation.typed_ir, compilation.model_path, prior, context_artifact,
            )
            foundation = bundle.foundation_path.read_text(encoding="utf-8")
            task = AutonomousProofTask(
                dut=compilation.benchmark.design_id,
                target_name=target.name,
                target_statement=target.statement,
                property_type=target.property_family,
                state_type=f"{compilation.ir.name}State",
                required_state_fields=list(target.state_fields),
                required_input_fields=list(target.input_fields),
                assumptions=[],
                context_import="Foundation",
                context_snippets=[foundation, *selected["model_snippets"]],
                relevant_foundational_lemmas=[
                    f"{item.name} : {item.proposition}" for item in pool.lemmas
                ],
                base_lean_error="\n".join(
                    (attempt.get("stdout", "") + attempt.get("stderr", ""))[-4000:]
                    for attempt in attempts if not attempt.get("success")
                ),
                future_targets=[
                    {"name": future.name, "statement": future.statement}
                    for future in bundle.theorems[index + 1:index + 5]
                ],
            )
            llm_result = run_budgeted_proof_search(
                task, provider, pool, compilation.model_path.parent,
                target_dir / "llm",
                ProvingBudget(max_generation_rounds=3, max_repair_rounds_per_candidate=2,
                              max_intermediate_lemmas=4, max_llm_calls=10),
            )
            if llm_result["target_kernel_pass"]:
                solved_proof = llm_result["final_proof"]
                method = "LLM"
                actual_reuse.extend(llm_result["actual_reuse"])

        if solved_proof is not None and not any(item.name == target.name for item in pool.lemmas):
            pool.add_verified(_pool_record(
                target, solved_proof, compilation.benchmark.design_id,
                compilation.ir.name, method or "unknown",
                [reused_lemma] if reused_lemma else [],
            ))
        target_result = {
            "name": target.name,
            "layer": target.layer,
            "property_family": target.property_family,
            "statement": target.statement,
            "status": "PASS" if solved_proof is not None else "UNSOLVED",
            "method": method,
            "proof": solved_proof,
            "attempts": attempts,
            "llm_result": llm_result,
            "reused_lemma": reused_lemma,
            "actual_reuse": actual_reuse,
        }
        write_json(target_dir / "result.json", target_result)
        results.append(target_result)

    solved = [item for item in results if item["status"] == "PASS"]
    final_lines = [
        "import Foundation", "", "set_option maxHeartbeats 8000000",
        "set_option maxRecDepth 100000", "", f"namespace {bundle.namespace}",
        f"open {compilation.ir.name}", "",
    ]
    # Pool order is dependency order and may include independently checked LLM
    # intermediate lemmas that later target proofs reference.
    for lemma in pool.lemmas:
        final_lines.extend([f"theorem {lemma.name} : {lemma.proposition} := {lemma.proof_body}", ""])
    final_lines.extend([f"end {bundle.namespace}", ""])
    final_path = arm_dir / "Theorems.lean"
    final_path.write_text("\n".join(final_lines), encoding="utf-8")
    final_check = kernel_check(final_path)
    write_json(arm_dir / "theorems_check.json", final_check)
    actual_hits = sum(
        item["causally_necessary"] for result in results for item in result["actual_reuse"]
    )
    summary = {
        "schema": "rtl2lean-proof-arm-result-v1",
        "dut": compilation.benchmark.design_id,
        "arm": arm,
        "llm_enabled": use_llm,
        "reuse_enabled": enable_reuse,
        "targets_generated": len(results),
        "targets_attempted": len(results),
        "targets_solved": len(solved),
        "target_pass_rate": len(solved) / len(results) if results else 0.0,
        "llm_solved": sum(item["method"] == "LLM" for item in results),
        "reuse_solved": sum(item["method"] == "LEMMA_REUSE" for item in results),
        "actual_reuse_hits": actual_hits,
        "kernel_final_pass": final_check["success"],
        "complete": len(solved) == len(results) and final_check["success"],
        "elapsed_s": time.perf_counter() - started,
        "results": results,
    }
    write_json(arm_dir / "summary.json", summary)
    return summary


def run_proving_experiment(compilation: Compilation, bundle: TheoremBundle,
                           use_llm: bool = True, enable_reuse: bool = True,
                           llm_model: str = "gpt-5.6-sol",
                           reasoning_effort: str = "medium") -> dict[str, Any]:
    """Run fair baseline and assisted arms over the exact same target set."""
    baseline = _run_arm(
        compilation, bundle, "baseline", False, False, llm_model, reasoning_effort,
    )
    assisted = _run_arm(
        compilation, bundle, "assisted", use_llm, enable_reuse, llm_model, reasoning_effort,
    )
    result = {
        "schema": "rtl2lean-stage3-result-v1",
        "dut": compilation.benchmark.design_id,
        "same_target_set": True,
        "target_manifest_sha256": sha256(bundle.targets_path),
        "baseline": {key: value for key, value in baseline.items() if key != "results"},
        "assisted": {key: value for key, value in assisted.items() if key != "results"},
        "delta_solved": assisted["targets_solved"] - baseline["targets_solved"],
        "status": "STAGE3_PASS" if assisted["complete"] else "PARTIAL",
    }
    write_json(compilation.model_path.parent.parent / "stage3.json", result)
    return result
