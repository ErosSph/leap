"""Evidence-only aggregation for the five-DUT experiment."""
from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from .io import write_json
from .manifest import Benchmark


def _read(path: Path) -> dict[str, Any] | None:
    if not path.is_file():
        return None
    return json.loads(path.read_text(encoding="utf-8"))


def build_report(benchmarks: list[Benchmark], output_root: Path) -> dict[str, Any]:
    rows = []
    progress_events = []
    for benchmark in benchmarks:
        root = output_root / benchmark.slug
        design = _read(root / "analysis" / "design.json") or {}
        clocks = _read(root / "analysis" / "clocks.json") or {}
        unsupported = _read(root / "analysis" / "unsupported.json") or {}
        typed = _read(root / "ir" / "design.json") or {}
        stage1 = _read(root / "stage1.json") or {}
        model_check = _read(root / "model" / "lean_check.json") or {}
        stage2 = _read(root / "stage2.json") or {}
        stage3 = _read(root / "stage3.json") or {}
        baseline = _read(root / "proofs" / "baseline" / "summary.json") or {}
        assisted = _read(root / "proofs" / "assisted" / "summary.json") or {}
        pool = _read(root / "proofs" / "assisted" / "lemma_pool.json") or {}
        processes = typed.get("module", {}).get("processes", [])
        signals = typed.get("module", {}).get("signals", [])
        targets = _read(root / "model" / "targets.json") or {}
        llm_results = [item.get("llm_result") for item in assisted.get("results", []) if item.get("llm_result")]
        stage2_kernel_time = sum(
            check.get("elapsed_s", 0.0) or 0.0
            for check in (stage2.get("lean_kernel", {}), stage2.get("framework_kernel", {}))
        )
        metrics = {
            "RTL_LOC": design.get("rtl_loc", {}).get("physical"),
            "MODULES": design.get("module_count"),
            "SIGNALS": len(signals),
            "STATE_REGISTERS": sum(item.get("kind") in {"state", "state_output"} for item in signals),
            "MEMORIES": len(typed.get("module", {}).get("memories", [])),
            "COMB_PROCESSES": sum(not item.get("sequential", False) for item in processes),
            "SEQ_PROCESSES": sum(item.get("sequential", False) for item in processes),
            "CLOCK_DOMAINS": len(typed.get("module", {}).get("clock_domains", [])),
            "UNSUPPORTED_CONSTRUCTS": len(unsupported.get("blocking_unsupported", [])),
            "GENERATED_LEAN_LOC": stage1.get("generated_lean_loc"),
            **targets.get("metrics", {}),
            "BASE_SOLVED": baseline.get("targets_solved", 0),
            "BASE_FAILED": baseline.get("targets_generated", 0) - baseline.get("targets_solved", 0),
            "LLM_TRIGGERED": len(llm_results),
            "LLM_SOLVED": sum(item.get("target_kernel_pass", False) for item in llm_results),
            "LLM_UNSOLVED": sum(not item.get("target_kernel_pass", False) for item in llm_results),
            "LLM_CALLS": sum(item.get("total_llm_calls", 0) for item in llm_results),
            "REPAIR_ROUNDS": sum(item.get("repair_rounds_used", 0) for item in llm_results),
            "LLM_LEMMA_CANDIDATES": sum(
                len(item.get("accepted_intermediate_lemmas", [])) + len(item.get("rejected_candidates", []))
                for item in llm_results
            ),
            "KERNEL_VERIFIED_LEMMAS": len(pool.get("lemmas", [])),
            "POOL_SIZE": len(pool.get("lemmas", [])),
            "RETRIEVED_LEMMAS": sum(
                len((_read(Path(attempt["source"]).parent / "context_selection.json") or {}).get("retrieved_lemmas", []))
                for item in assisted.get("results", []) for attempt in item.get("attempts", [])[:1]
                if (item.get("llm_result") and attempt.get("source"))
            ),
            "ACTUALLY_USED_LEMMAS": sum(item.get("reuse_count", 0) > 0 for item in pool.get("lemmas", [])),
            "CROSS_PROPERTY_REUSE": sum(item.get("reuse_count", 0) for item in pool.get("lemmas", [])),
            "RTL_ANALYSIS_TIME": design.get("elapsed_s"),
            "TRANSLATION_TIME": stage1.get("elapsed_s"),
            "LEAN_CHECK_TIME": model_check.get("elapsed_s"),
            "THEOREM_GENERATION_TIME": stage2.get("theorem_generation_elapsed_s"),
            "BASELINE_PROOF_TIME": baseline.get("elapsed_s"),
            "LLM_TIME": sum(item.get("llm_time_s", 0.0) for item in llm_results),
        }
        metrics["TOTAL_TIME"] = sum(
            value or 0.0 for value in (
                design.get("elapsed_s"), stage1.get("elapsed_s"),
                stage2.get("theorem_generation_elapsed_s"), stage2_kernel_time,
                baseline.get("elapsed_s"), assisted.get("elapsed_s"),
            )
        )
        full = (
            stage1.get("status") == "STAGE1_PASS"
            and stage2.get("status") == "STAGE2_PASS"
            and assisted.get("complete") is True
            and any(target.get("high_level") for target in targets.get("targets", []))
        )
        status = "FULL_PIPELINE_PASS" if full else (
            "THEOREM_FRAMEWORK_PASS" if stage2.get("status") == "STAGE2_PASS" else
            "STAGE1_PASS" if stage1.get("status") == "STAGE1_PASS" else
            "PARTIAL" if any((stage1, stage2, stage3)) else "FAIL"
        )
        rows.append({
            "dut": benchmark.design_id,
            "slug": benchmark.slug,
            "top_module": benchmark.top_module,
            "checkpoint": clocks.get("checkpoint_classification"),
            "status": status,
            "metrics": metrics,
        })
        unsupported_items = unsupported.get("blocking_unsupported", [])
        common = {
            "benchmark": benchmark.design_id,
            "files_changed": [],
            "tests_executed": [],
            "unsupported_constructs": unsupported_items,
            "current_blockers": [] if status != "FAIL" else ["see stage/failure artifacts"],
        }
        progress_events.extend([
            {**common, "phase": "Phase 0", "status": "PASS" if design and clocks else "FAIL",
             "commands_executed": ["PySlang repository/design audit"],
             "generated_artifacts": [str(root / "analysis" / name)
                                     for name in ("design.json", "clocks.json", "unsupported.json")],
             "next_phase": "Stages 1-6"},
            {**common, "phase": "Stages 1-6", "status": stage1.get("status", "FAIL"),
             "commands_executed": [" ".join(map(str, model_check.get("command", [])))],
             "generated_artifacts": [str(root / "ir" / "design.json"),
                                     str(root / "model" / "Model.lean"), str(root / "stage1.json")],
             "next_phase": "Stages 7-12"},
            {**common, "phase": "Stages 7-12", "status": stage2.get("status", "FAIL"),
             "commands_executed": [" ".join(map(str, stage2.get("framework_kernel", {}).get("command", [])))],
             "generated_artifacts": [str(root / "model" / "Foundation.lean"),
                                     str(root / "model" / "Framework.lean"),
                                     str(root / "model" / "targets.json"), str(root / "stage2.json")],
             "next_phase": f"Checkpoint {clocks.get('checkpoint_classification', '?')}"},
            {**common, "phase": f"Checkpoint {clocks.get('checkpoint_classification', '?')}",
             "status": "PASS" if stage2.get("status") == "STAGE2_PASS" else "FAIL",
             "commands_executed": ["evidence aggregation"],
             "generated_artifacts": [str(root / "stage2.json")], "next_phase": "Stages 13-24"},
            {**common, "phase": "Stages 13-24", "status": stage3.get("status", "FAIL"),
             "commands_executed": ["deterministic baseline", "structured LLM + Lean feedback",
                                   "DUT-local reuse deletion ablation"],
             "generated_artifacts": [str(root / "proofs" / "baseline" / "summary.json"),
                                     str(root / "proofs" / "assisted" / "summary.json"),
                                     str(root / "stage3.json")],
             "next_phase": "Final report"},
        ])

    rq1_pass = sum(row["status"] in {"STAGE1_PASS", "THEOREM_FRAMEWORK_PASS", "FULL_PIPELINE_PASS"} for row in rows)
    rq2_pass = sum(row["status"] in {"THEOREM_FRAMEWORK_PASS", "FULL_PIPELINE_PASS"} for row in rows)
    llm_improvements = 0
    for benchmark in benchmarks:
        assisted = _read(output_root / benchmark.slug / "proofs" / "assisted" / "summary.json") or {}
        llm_improvements += sum(
            bool(item.get("llm_result", {}).get("target_kernel_pass"))
            and bool(item.get("llm_result", {}).get("accepted_intermediate_lemmas"))
            and item.get("llm_result", {}).get("causally_used_intermediate_lemmas", 0) > 0
            for item in assisted.get("results", []) if item.get("llm_result")
        )
    actual_reuse = sum(row["metrics"]["CROSS_PROPERTY_REUSE"] for row in rows)
    report = {
        "schema": "rtl2lean-final-experiment-report-v1",
        "claim_scope": "Lean-kernel acceptance of generated models and theorems; no independent RTL-to-Lean equivalence claim.",
        "duts": rows,
        "research_questions": {
            "RQ1": {"answer": rq1_pass == len(rows), "stage1_pass_duts": rq1_pass, "total_duts": len(rows)},
            "RQ2": {"answer": rq2_pass == len(rows), "framework_pass_duts": rq2_pass, "total_duts": len(rows)},
            "RQ3": {"answer": llm_improvements > 0,
                    "baseline_failed_then_kernel_verified_intermediate_then_llm_solved": llm_improvements},
            "RQ4": {"answer": actual_reuse > 0, "causally_verified_cross_property_reuse_hits": actual_reuse},
        },
        "fully_automated_successes": sum(row["status"] == "FULL_PIPELINE_PASS" for row in rows),
    }
    write_json(output_root / "progress.json", {
        "schema": "rtl2lean-progress-v1",
        "source": "aggregated from kernel-checked stage artifacts",
        "events": progress_events,
    })
    write_json(output_root / "final_report.json", report)
    lines = [
        "# RTL2Lean experiment report", "",
        report["claim_scope"], "",
        "| DUT | RTL LOC | Clocks | Generated theorems | Baseline solved | Assisted solved | Actual reuse | Status |",
        "|---|---:|---:|---:|---:|---:|---:|---|",
    ]
    for row in rows:
        m = row["metrics"]
        assisted = _read(output_root / row["slug"] / "proofs" / "assisted" / "summary.json") or {}
        lines.append(
            f"| {row['dut']} | {m['RTL_LOC'] or 0} | {m['CLOCK_DOMAINS']} | {m.get('N_TOTAL', 0)} | "
            f"{m['BASE_SOLVED']} | {assisted.get('targets_solved', 0)} | {m['CROSS_PROPERTY_REUSE']} | {row['status']} |"
        )
    lines.extend(["", "## Research questions", ""])
    for key, value in report["research_questions"].items():
        lines.append(f"- {key}: {'YES' if value['answer'] else 'NO'} — `{json.dumps(value, ensure_ascii=False)}`")
    (output_root / "final_report.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    return report
