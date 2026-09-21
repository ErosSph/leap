"""Unified autonomous entry point for the experimental specification evaluation."""
from __future__ import annotations

import argparse
import json
import time
import traceback
from pathlib import Path

from rtl2lean.evaluation.corpus import build_property_corpus
from rtl2lean.evaluation.experiment import (
    compile_configuration_bundles,
    measure_translation_phases,
    run_baseline,
    run_intermediate_ablation,
    run_pool_configuration,
    run_reuse_audit,
    summarize_assisted,
)
from rtl2lean.evaluation.report import build_paper_report
from rtl2lean.pipeline.io import sha256, write_json
from rtl2lean.pipeline.manifest import DEFAULT_MANIFEST, load_benchmarks


def _read(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="evaluation causal experimental evaluation")
    parser.add_argument("--output", type=Path, default=Path("outputs"))
    parser.add_argument("--model", default="gpt-5.6-sol")
    parser.add_argument("--reasoning-effort", default="medium")
    parser.add_argument("--phase", choices=("all", "corpus", "baseline", "official_run1",
                                             "official_run2", "fresh", "shared", "reverse", "lexical",
                                             "ablation1", "ablation2", "ablation", "report"),
                        default="all")
    parser.add_argument("--resume", action="store_true",
                        help="reuse an existing completed artifact for phases preceding the requested phase")
    return parser


def _progress(path: Path, events: list[dict], phase: str, status: str,
              artifacts: list[Path], error: str | None = None) -> None:
    events.append({"phase": phase, "status": status,
                   "artifacts": [str(item) for item in artifacts],
                   "blockers": [error] if error else [], "next": "automatic continuation"})
    write_json(path, {"schema": "rtl2lean-evaluation-progress-v1", "events": events})


def main(argv: list[str] | None = None) -> int:
    args = _parser().parse_args(argv)
    project = Path(__file__).resolve().parents[2]
    output_root = (args.output if args.output.is_absolute() else project / args.output).resolve()
    requirement_root = output_root / "evaluation"
    requirement_root.mkdir(parents=True, exist_ok=True)
    benchmarks = load_benchmarks(DEFAULT_MANIFEST)
    provider_options = {"model": args.model, "reasoning_effort": args.reasoning_effort,
                        "timeout_s": 300}
    events = []
    started = time.perf_counter()
    manifest = {
        "schema": "rtl2lean-evaluation-run-manifest-v1", "phase": args.phase,
        "benchmarks": [item.design_id for item in benchmarks],
        "provider": provider_options, "property_selection":
        "all valid BASE_FAILED properties from a corpus frozen before LLM",
        "orders": ["dependency", "reverse", "lexical"], "repetitions": 2,
        "manual_generated_proof_edits": False,
        "baseline_strategy": "uniform generic suite plus mechanically derived source-function unfolding",
        "excluded_scope": [
            "four-state RTL semantics", "X/Z comparison", "RTL simulation",
            "testbench generation", "cycle-by-cycle differential validation",
        ],
    }
    write_json(requirement_root / "run_manifest.json", manifest)

    def artifact_or(name: str, producer):
        path = requirement_root / name
        return _read(path) if args.resume and path.is_file() else producer()

    try:
        corpus = artifact_or("corpus/property_corpus.json",
                             lambda: build_property_corpus(benchmarks, output_root, requirement_root))
        _progress(requirement_root / "progress.json", events, "Phase A-B corpus/audit", "PASS",
                  [requirement_root / "corpus" / "property_corpus.json"])
        if args.phase == "corpus":
            return 0

        translation = artifact_or("runtime/translation_phases.json",
                                  lambda: measure_translation_phases(benchmarks, output_root, requirement_root))
        baseline = artifact_or("baseline/baseline_results.json",
                               lambda: run_baseline(benchmarks, corpus, output_root, requirement_root))
        _progress(requirement_root / "progress.json", events, "Phase C baseline", "PASS",
                  [requirement_root / "baseline" / "baseline_results.json",
                   requirement_root / "baseline" / "selected_targets.json"])
        if args.phase == "baseline":
            return 0

        def config(name: str, shared: bool, order: str) -> dict:
            return artifact_or(f"runs/{name}/summary.json", lambda: run_pool_configuration(
                name, benchmarks, corpus, baseline, output_root, requirement_root,
                provider_options, shared=shared, order_rule=order,
            ))

        # Independent configuration phases may be scheduled concurrently. They
        # share only frozen read-only inputs and write disjoint run directories.
        direct_configurations = {
            "shared": ("shared_pool", True, "dependency"),
            "reverse": ("order_reverse", True, "reverse"),
            "lexical": ("order_lexical", True, "lexical"),
        }
        if args.phase in direct_configurations:
            config(*direct_configurations[args.phase])
            return 0

        official = config("official_run1", False, "dependency")
        _progress(requirement_root / "progress.json", events, "Phase D official baseline-vs-LLM", "PASS",
                  [requirement_root / "runs" / "official_run1" / "summary.json"])
        if args.phase == "official_run1":
            return 0
        run2 = config("official_run2", False, "dependency")
        if args.phase == "official_run2":
            return 0
        if args.phase == "ablation1":
            run_intermediate_ablation(
                benchmarks, corpus, baseline, official, output_root, requirement_root,
                provider_options, "official_run1",
            )
            return 0
        if args.phase == "ablation2":
            run_intermediate_ablation(
                benchmarks, corpus, baseline, run2, output_root, requirement_root,
                provider_options, "official_run2",
            )
            return 0
        fresh = official
        if args.phase == "fresh":
            return 0
        shared = config("shared_pool", True, "dependency")
        reverse = config("order_reverse", True, "reverse")
        lexical = config("order_lexical", True, "lexical")
        # The fair Baseline-vs-LLM arm starts every target from the same empty
        # property pool.  Shared-pool runs are reserved for the reuse study.
        summarize_assisted(official, requirement_root)
        write_json(requirement_root / "pool_ablation" / "fresh_pool.json", fresh)
        write_json(requirement_root / "pool_ablation" / "shared_pool.json", shared)
        write_json(requirement_root / "pool_ablation" / "order_sensitivity.json", {
            "schema": "rtl2lean-evaluation-order-sensitivity-v1",
            "configurations": [{"name": item["name"], "order_rule": item["order_rule"],
                                "metrics": item["metrics"]} for item in (shared, reverse, lexical)],
        })
        ablation = artifact_or("llm/lemma_ablation.json", lambda: run_intermediate_ablation(
            benchmarks, corpus, baseline, official, output_root, requirement_root, provider_options,
            "official_run1",
        ))
        ablation_run2 = artifact_or("llm/lemma_ablation_official_run2.json",
                                    lambda: run_intermediate_ablation(
            benchmarks, corpus, baseline, run2, output_root, requirement_root, provider_options,
            "official_run2",
        ))
        reuse = run_reuse_audit(shared, benchmarks, corpus, baseline, output_root, requirement_root)
        _progress(requirement_root / "progress.json", events, "Phase E-I causal/pool/order", "PASS",
                  [requirement_root / "llm" / "lemma_ablation.json",
                   requirement_root / "reuse" / "causal_reuse.json",
                   requirement_root / "pool_ablation" / "fresh_pool.json"])
        if args.phase == "ablation":
            return 0

        checks = []
        for item in (official, run2, shared, reverse, lexical):
            checks.extend(compile_configuration_bundles(item, benchmarks, output_root, requirement_root))
        report = build_paper_report(
            benchmarks, corpus, baseline, shared, run2, official, [shared, reverse, lexical],
            ablation, ablation_run2, reuse, translation, checks, output_root, requirement_root,
            provider_options,
        )
        _progress(requirement_root / "progress.json", events, "Phase J integrity/report", report["status"],
                  [requirement_root / "final_audit_report.json", requirement_root / "tables",
                   requirement_root / "figures"])
        write_json(requirement_root / "run_summary.json", {
            "schema": "rtl2lean-evaluation-run-summary-v1", "status": report["status"],
            "elapsed_s": time.perf_counter() - started, "failures": [],
            "corpus_sha256": sha256(requirement_root / "corpus" / "property_corpus.json"),
        })
        (requirement_root / "failure.json").unlink(missing_ok=True)
        return 0 if report["status"] == "PASS" else 1
    except Exception as error:
        traceback.print_exc()
        write_json(requirement_root / "failure.json", {
            "error": repr(error), "traceback": traceback.format_exc(),
            "elapsed_s": time.perf_counter() - started,
        })
        _progress(requirement_root / "progress.json", events, args.phase, "FAIL", [], repr(error))
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
