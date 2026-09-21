"""Autonomous command-line entry point for the experimental specification temporal."""
from __future__ import annotations

import argparse
import json
import time
import traceback
from pathlib import Path

from rtl2lean.pipeline.io import sha256, write_json
from rtl2lean.pipeline.manifest import DEFAULT_MANIFEST, load_benchmarks
from rtl2lean.temporal.corpus import build_temporal_corpus
from rtl2lean.temporal.experiment import (
    run_baseline,
    run_direct,
    run_lemma_first,
    validate_and_freeze_corpus,
)
from rtl2lean.temporal.foundation import build_temporal_foundation
from rtl2lean.temporal.report import build_report, rerun_integrity


def _read(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def _ensure_time_aliases(payload: dict, path: Path) -> dict:
    """Keep the specification's Te2e name alongside legacy elapsed_s fields."""
    changed = False
    for result in payload.get("results", []):
        if "Te2e" not in result:
            result["Te2e"] = result.get("elapsed_s", result.get("proof_time_s", 0))
            changed = True
    metrics = payload.get("metrics", {})
    if "Te2e" not in metrics:
        metrics["Te2e"] = metrics.get("elapsed_s", 0)
        changed = True
    if changed:
        write_json(path, payload)
    return payload


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="temporal temporal proof evaluation")
    parser.add_argument("--output", type=Path, default=Path("outputs"))
    parser.add_argument("--phase", choices=("all", "corpus", "baseline", "direct", "lemma", "report"), default="all")
    parser.add_argument("--resume", action="store_true")
    parser.add_argument("--model", default="gpt-5.6-sol")
    parser.add_argument("--reasoning-effort", default="medium")
    return parser


def _progress(path: Path, events: list[dict], phase: str, status: str, artifacts: list[Path], error: str | None = None) -> None:
    events.append({
        "phase": phase, "status": status, "artifacts": [str(x) for x in artifacts],
        "blockers": [error] if error else [], "next": "automatic continuation",
    })
    write_json(path, {"schema": "rtl2lean-temporal-progress-v1", "events": events})


def main(argv: list[str] | None = None) -> int:
    args = _parser().parse_args(argv)
    project = Path(__file__).resolve().parents[2]
    output_root = (args.output if args.output.is_absolute() else project / args.output).resolve()
    requirement_root = output_root / "temporal"
    requirement_root.mkdir(parents=True, exist_ok=True)
    benchmarks = load_benchmarks(DEFAULT_MANIFEST)
    provider_options = {
        "model": args.model, "reasoning_effort": args.reasoning_effort, "timeout_s": 300,
    }
    started = time.perf_counter(); events: list[dict] = []
    manifest = {
        "schema": "rtl2lean-temporal-run-manifest-v1",
        "benchmarks": [x.design_id for x in benchmarks],
        "phase": args.phase, "resume": args.resume, "provider": provider_options,
        "property_order": "discovery -> validation -> freeze -> baseline -> all BASE_FAILED direct -> all BASE_FAILED lemma-first -> report",
        "temporal_levels": ["SINGLE_CYCLE", "TRACE_BRIDGE", "TRUE_MULTI_CYCLE"],
        "true_temporal_families": [
            "IMPLICATION", "RECURSIVE", "EVENTUALLY", "BOUNDED_EVENTUALLY",
            "UNTIL", "INVARIANT", "MULTI_CLOCK_TEMPORAL",
        ],
        "execution_semantics": "register event: comb(pre) -> commit/commitEvent; original full run retained for TRACE_BRIDGE",
        "result_shaping": False, "manual_theorem_statements": False,
    }
    write_json(requirement_root / "run_manifest.json", manifest)

    try:
        frozen_path = requirement_root / "corpus" / "final_properties.json"
        if args.resume and frozen_path.is_file() and _read(frozen_path).get("frozen_before_baseline"):
            corpus = _read(frozen_path)
        else:
            generated = build_temporal_corpus(
                benchmarks, output_root, requirement_root, build_temporal_foundation,
            )
            corpus = validate_and_freeze_corpus(
                benchmarks, generated, output_root, requirement_root,
            )
        _progress(requirement_root / "progress.json", events, "corpus-validation-freeze", "PASS", [
            frozen_path, requirement_root / "corpus" / "freeze.json",
        ])
        if args.phase == "corpus":
            return 0

        baseline_path = requirement_root / "baseline" / "baseline_results.json"
        baseline = _read(baseline_path) if args.resume and baseline_path.is_file() else run_baseline(
            benchmarks, corpus, output_root, requirement_root,
        )
        baseline = _ensure_time_aliases(baseline, baseline_path)
        _progress(requirement_root / "progress.json", events, "baseline", "PASS", [baseline_path])
        if args.phase == "baseline":
            return 0

        direct_path = requirement_root / "direct_llm" / "results.json"
        prior_direct = _read(direct_path) if args.resume and direct_path.is_file() else {}
        direct_usable = bool(
            prior_direct
            and (
                prior_direct.get("metrics", {}).get("TARGETS", 0) == 0
                or prior_direct.get("metrics", {}).get("TLean", 0) > 0
            )
        )
        direct = prior_direct if direct_usable else run_direct(
            benchmarks, corpus, baseline, output_root, requirement_root, provider_options, args.resume,
        )
        direct = _ensure_time_aliases(direct, direct_path)
        _progress(requirement_root / "progress.json", events, "direct-llm", "PASS", [direct_path])
        if args.phase == "direct":
            return 0

        lemma_path = requirement_root / "lemma_first" / "results.json"
        lemma = _read(lemma_path) if args.resume and lemma_path.is_file() else run_lemma_first(
            benchmarks, corpus, baseline, direct, output_root, requirement_root,
            provider_options, args.resume,
        )
        lemma = _ensure_time_aliases(lemma, lemma_path)
        _progress(requirement_root / "progress.json", events, "lemma-first", "PASS", [
            lemma_path, requirement_root / "lemma_first" / "causal_ablation.json",
        ])
        if args.phase == "lemma":
            return 0

        integrity = rerun_integrity(
            benchmarks, baseline, direct, lemma, output_root, requirement_root,
        )
        report = build_report(
            benchmarks, corpus, baseline, direct, lemma, output_root, requirement_root,
            provider_options, integrity,
        )
        _progress(requirement_root / "progress.json", events, "integrity-report", report["status"], [
            requirement_root / "lean_integrity.json", requirement_root / "final_report.json",
            requirement_root / "final_report.md", requirement_root / "tables", requirement_root / "figures",
        ])
        write_json(requirement_root / "run_summary.json", {
            "schema": "rtl2lean-temporal-run-summary-v1", "status": report["status"],
            "elapsed_s": time.perf_counter() - started,
            "property_corpus_sha256": sha256(frozen_path), "failures": [],
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
