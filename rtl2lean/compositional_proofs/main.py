"""CLI orchestration for the experimental specification compositional_proofs."""
from __future__ import annotations

import argparse
import json
import time
import traceback
from pathlib import Path
from typing import Any

from rtl2lean.pipeline.io import sha256, write_json
from rtl2lean.pipeline.manifest import DEFAULT_MANIFEST, load_benchmarks
from rtl2lean.compositional_proofs.corpus import build_corpus
from rtl2lean.compositional_proofs.experiment import (
    MAX_LLM_CALLS, MAX_REPAIRS_PER_CANDIDATE, MAX_TOTAL_TOKENS, PROVIDER_TIMEOUT_S,
    run_baseline, run_direct_trials, run_lemma_trials, validate_and_freeze,
)
from rtl2lean.compositional_proofs.foundation import build_foundations, discover_until_foundations
from rtl2lean.compositional_proofs.latency import analyze_latency
from rtl2lean.compositional_proofs.report import build_report, tree_digest


def _read(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="compositional_proofs compositional temporal evaluation")
    parser.add_argument("--output", type=Path, default=Path("outputs"))
    parser.add_argument("--phase", choices=("all", "corpus", "baseline", "direct", "lemma", "report"), default="all")
    parser.add_argument("--trials", type=int, default=3)
    parser.add_argument("--resume", action="store_true")
    parser.add_argument("--model", default="gpt-5.6-sol")
    parser.add_argument("--reasoning-effort", default="medium")
    return parser


def _progress(path: Path, events: list[dict[str, Any]], phase: str, status: str,
              artifacts: list[Path], error: str | None = None) -> None:
    events.append({"phase": phase, "status": status, "artifacts": [str(x) for x in artifacts],
                   "blockers": [error] if error else [], "next": "automatic continuation"})
    write_json(path, {"schema": "rtl2lean-compositional_proofs-progress-v1", "events": events})


def main(argv: list[str] | None = None) -> int:
    args = _parser().parse_args(argv)
    if args.trials < 1:
        raise SystemExit("--trials must be >= 1")
    project = Path(__file__).resolve().parents[2]
    output_root = (args.output if args.output.is_absolute() else project / args.output).resolve()
    requirement_root = output_root / "compositional_proofs"
    requirement_root.mkdir(parents=True, exist_ok=True)
    benchmarks = load_benchmarks(DEFAULT_MANIFEST)
    r4_root = output_root / "temporal_challenges"
    current_r4_digest = tree_digest(r4_root)
    snapshot_path = requirement_root / "temporal_challenges_snapshot.json"
    if snapshot_path.is_file():
        r4_digest_before = _read(snapshot_path)["tree_sha256"]
    else:
        r4_digest_before = current_r4_digest
        write_json(snapshot_path, {"schema": "rtl2lean-compositional_proofs-r4-snapshot-v1",
                                  "tree_sha256": current_r4_digest})
    provider_options = {"model": args.model, "reasoning_effort": args.reasoning_effort,
                        "timeout_s": PROVIDER_TIMEOUT_S}
    write_json(requirement_root / "run_manifest.json", {
        "schema": "rtl2lean-compositional_proofs-run-v1", "phase": args.phase,
        "trials": args.trials, "resume": args.resume, "provider": provider_options,
        "temporal_challenges_digest_before": r4_digest_before,
        "temporal_challenges_digest_at_start": current_r4_digest,
        "freeze_then_run": True, "result_shaping": False,
        "fairness": {"same_theorem": True, "same_model": True, "same_foundation": True,
                     "same_retrieval": True, "same_max_llm_calls": MAX_LLM_CALLS,
                     "same_max_total_tokens": MAX_TOTAL_TOKENS,
                     "same_max_repairs_per_candidate": MAX_REPAIRS_PER_CANDIDATE,
                     "same_timeout_s": PROVIDER_TIMEOUT_S},
    })
    started, events = time.perf_counter(), []
    try:
        final_path = requirement_root / "compositional_hard" / "final_properties.json"
        if args.resume and final_path.is_file() and _read(final_path).get("frozen_before_baseline"):
            corpus = _read(final_path)
        else:
            discovery = discover_until_foundations(benchmarks, output_root, requirement_root)
            foundations = build_foundations(benchmarks, output_root, requirement_root, discovery)
            generated = build_corpus(benchmarks, output_root, requirement_root, foundations)
            analyze_latency(benchmarks, output_root, requirement_root)
            corpus = validate_and_freeze(benchmarks, generated, output_root, requirement_root)
        _progress(requirement_root / "progress.json", events, "discover-validate-freeze", "PASS", [
            final_path, requirement_root / "until" / "results.json",
            requirement_root / "variable_latency" / "results.json",
        ])
        write_json(requirement_root / "repeated_trials" / "plan.json", {
            "schema": "rtl2lean-compositional_proofs-trial-plan-v1", "frozen_before_llm": True,
            "trial_count": args.trials, "trial_ids": list(range(1, args.trials + 1)),
            "explicit_sampling_seed_supported": False,
            "independence_method": "fresh ephemeral provider sessions with identical task context",
            "theorem_corpus_sha256": sha256(final_path),
        })
        if args.phase == "corpus":
            return 0

        baseline_path = requirement_root / "baseline" / "results.json"
        baseline = (_read(baseline_path) if args.resume and baseline_path.is_file()
                    else run_baseline(benchmarks, corpus, output_root, requirement_root))
        _progress(requirement_root / "progress.json", events, "baseline", "PASS", [baseline_path])
        if args.phase == "baseline":
            return 0

        direct = run_direct_trials(benchmarks, corpus, baseline, output_root, requirement_root,
                                   provider_options, args.trials, args.resume)
        _progress(requirement_root / "progress.json", events, "direct", "PASS", [
            requirement_root / "direct_llm" / "results.json",
            requirement_root / "direct_llm" / "inline_decomposition.json",
        ])
        if args.phase == "direct":
            return 0

        lemma = run_lemma_trials(benchmarks, corpus, baseline, direct, output_root,
                                 requirement_root, provider_options, args.trials, args.resume)
        _progress(requirement_root / "progress.json", events, "lemma-first", "PASS", [
            requirement_root / "lemma_first" / "results.json",
            requirement_root / "lemma_first" / "abstraction_gain.json",
            requirement_root / "repeated_trials" / "summary.json",
        ])
        if args.phase == "lemma":
            return 0

        report = build_report(benchmarks, corpus, baseline, direct, lemma,
                              requirement_root, r4_digest_before)
        _progress(requirement_root / "progress.json", events, "report-integrity", report["status"], [
            requirement_root / "final_report.json", requirement_root / "final_report.md",
            requirement_root / "kernel_replay.json", requirement_root / "tables",
        ])
        write_json(requirement_root / "run_summary.json", {
            "schema": "rtl2lean-compositional_proofs-summary-v1", "status": report["status"],
            "invocation_elapsed_s": time.perf_counter() - started,
            "corpus_sha256": sha256(final_path), "failures": [],
        })
        (requirement_root / "failure.json").unlink(missing_ok=True)
        return 0 if report["status"] == "PASS" else 1
    except Exception as error:
        traceback.print_exc()
        write_json(requirement_root / "failure.json", {"error": repr(error),
                   "traceback": traceback.format_exc(), "elapsed_s": time.perf_counter() - started})
        _progress(requirement_root / "progress.json", events, args.phase, "FAIL", [], repr(error))
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
