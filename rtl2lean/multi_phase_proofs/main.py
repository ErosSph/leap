"""CLI orchestration for the experimental specification multi_phase_proofs."""
from __future__ import annotations

import argparse
import json
import time
import traceback
from pathlib import Path
from typing import Any

from rtl2lean.pipeline.io import sha256, write_json
from rtl2lean.pipeline.manifest import DEFAULT_MANIFEST, load_benchmarks
from rtl2lean.compositional_proofs.report import tree_digest
from rtl2lean.multi_phase_proofs.corpus import build_candidates
from rtl2lean.multi_phase_proofs.experiment import (
    MAX_LLM_CALLS, MAX_REPAIRS_PER_CANDIDATE, MAX_TOTAL_TOKENS,
    MAX_TOTAL_WALL_TIME_S, PROVIDER_TIMEOUT_S, run_baseline, run_direct,
    run_lemma_first, validate_and_freeze,
)
from rtl2lean.multi_phase_proofs.proof_graph import analyze_targets, build_theorem_dependency_graph
from rtl2lean.multi_phase_proofs.report import build_report


def _read(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="multi_phase_proofs operational bottleneck evaluation")
    parser.add_argument("--output", type=Path, default=Path("outputs"))
    parser.add_argument(
        "--phase", choices=("all", "corpus", "baseline", "direct", "lemma", "report"),
        default="all",
    )
    parser.add_argument("--trials", type=int, default=5)
    parser.add_argument("--workers", type=int, default=4)
    parser.add_argument("--resume", action="store_true")
    parser.add_argument("--model", default="gpt-5.6-sol")
    parser.add_argument("--reasoning-effort", default="medium")
    return parser


def _progress(
    path: Path, events: list[dict[str, Any]], phase: str, status: str,
    artifacts: list[Path], error: str | None = None,
) -> None:
    events.append({
        "phase": phase, "status": status,
        "artifacts": [str(path) for path in artifacts],
        "blockers": [error] if error else [], "next": "automatic continuation",
    })
    write_json(path, {"schema": "rtl2lean-multi_phase_proofs-progress-v1", "events": events})


def main(argv: list[str] | None = None) -> int:
    args = _parser().parse_args(argv)
    if args.trials < 5:
        raise SystemExit("multi_phase_proofs requires --trials >= 5")
    if args.workers < 1:
        raise SystemExit("--workers must be >= 1")
    project = Path(__file__).resolve().parents[2]
    output_root = (args.output if args.output.is_absolute() else project / args.output).resolve()
    requirement_root = output_root / "multi_phase_proofs"
    requirement_root.mkdir(parents=True, exist_ok=True)
    benchmarks = load_benchmarks(DEFAULT_MANIFEST)
    snapshot_path = requirement_root / "frozen_prior_requirements.json"
    current = {name: tree_digest(output_root / name) for name in ("compositional_proofs", "proof_audit", "proof_gaps")}
    if snapshot_path.is_file():
        frozen_digests = _read(snapshot_path)["tree_sha256"]
    else:
        frozen_digests = current
        write_json(snapshot_path, {
            "schema": "rtl2lean-multi_phase_proofs-prior-snapshot-v1", "tree_sha256": frozen_digests,
        })
    provider = {
        "model": args.model, "reasoning_effort": args.reasoning_effort,
        "timeout_s": PROVIDER_TIMEOUT_S,
    }
    write_json(requirement_root / "run_manifest.json", {
        "schema": "rtl2lean-multi_phase_proofs-run-v1", "phase": args.phase,
        "trials_per_bottleneck": args.trials, "resume": args.resume,
        "workers": args.workers,
        "provider": provider, "prior_requirements_frozen": frozen_digests,
        "prior_requirements_at_start": current,
        "order": [
            "RTL_IR_DISCOVERY", "TARGET_GENERATION", "DEPENDENCY_GRAPH",
            "ALTERNATIVE_PATH_SEARCH", "BOTTLENECK_DETECTION", "CLASSIFICATION",
            "PROPERTY_FREEZE", "BASELINE", "DIRECT_5X", "LEMMA_FIRST_5X", "ANALYZE",
        ],
        "bottleneck_scope": "OPERATIONAL_UNDER_FROZEN_ENVIRONMENT",
        "bottleneck_information_hidden_from_both_llm_arms": True,
        "reference_proofs_hidden_from_all_arms": True,
        "result_shaping": False,
        "fairness": {
            "same_theorem": True, "same_foundation": True, "same_retrieval": True,
            "paired_frozen_sampling_nonce": True,
            "provider_rng_seed_exposed": False,
            "same_max_llm_calls": MAX_LLM_CALLS,
            "same_max_total_tokens": MAX_TOTAL_TOKENS,
            "same_max_repairs": MAX_REPAIRS_PER_CANDIDATE,
            "same_provider_timeout_s": PROVIDER_TIMEOUT_S,
            "same_max_total_wall_time_s": MAX_TOTAL_WALL_TIME_S,
        },
    })
    events: list[dict[str, Any]] = []
    started = time.perf_counter()
    try:
        final_path = requirement_root / "corpus" / "final_properties.json"
        seeds_path = requirement_root / "corpus" / "trial_seeds.json"
        can_resume = (
            args.resume and final_path.is_file() and seeds_path.is_file()
            and _read(final_path).get("frozen_before_llm")
            and _read(seeds_path).get("trials_per_bottleneck") == args.trials
        )
        if can_resume:
            corpus = _read(final_path)
        else:
            candidates = build_candidates(benchmarks, output_root, requirement_root)
            graph = build_theorem_dependency_graph(benchmarks, output_root, requirement_root)
            analyzed = analyze_targets(candidates, graph, requirement_root)
            corpus = validate_and_freeze(
                benchmarks, analyzed, output_root, requirement_root, args.trials
            )
        _progress(requirement_root / "progress.json", events, "discover-graph-alternatives-freeze", "PASS", [
            requirement_root / "corpus" / "all_candidates.json", final_path,
            requirement_root / "corpus" / "bottleneck_challenges.json", seeds_path,
            requirement_root / "proof_graph" / "theorem_dependency_graph.json",
            requirement_root / "proof_graph" / "target_graphs.json",
            requirement_root / "proof_graph" / "alternative_paths.json",
            requirement_root / "bottleneck" / "candidates.json",
            requirement_root / "bottleneck" / "strength.json",
            requirement_root / "bottleneck" / "frozen_classification.json",
        ])
        if args.phase == "corpus":
            return 0

        baseline_path = requirement_root / "baseline" / "results.json"
        baseline = (
            _read(baseline_path) if args.resume and baseline_path.is_file()
            else run_baseline(benchmarks, corpus, output_root, requirement_root)
        )
        _progress(requirement_root / "progress.json", events, "baseline", "PASS", [baseline_path])
        if args.phase == "baseline":
            return 0

        direct = run_direct(
            benchmarks, corpus, baseline, output_root, requirement_root,
            provider, args.trials, args.resume, args.workers,
        )
        _progress(requirement_root / "progress.json", events, "direct-5x", "PASS", [
            requirement_root / "direct" / "trials.json",
            requirement_root / "direct" / "bypass_audit.json",
        ])
        if args.phase == "direct":
            return 0

        lemma = run_lemma_first(
            benchmarks, corpus, baseline, direct, output_root, requirement_root,
            provider, args.trials, args.resume, args.workers,
        )
        _progress(requirement_root / "progress.json", events, "lemma-first-5x", "PASS", [
            requirement_root / "lemma_first" / "trials.json",
            requirement_root / "lemma_first" / "intermediate_lemmas.json",
            requirement_root / "lemma_first" / "novelty.json",
            requirement_root / "lemma_first" / "alignment.json",
            requirement_root / "lemma_first" / "closure.json",
            requirement_root / "lemma_first" / "causal_ablation.json",
        ])
        if args.phase == "lemma":
            return 0

        current_end = {name: tree_digest(output_root / name) for name in ("compositional_proofs", "proof_audit", "proof_gaps")}
        report = build_report(
            benchmarks, corpus, baseline, direct, lemma, output_root,
            requirement_root, frozen_digests, current_end, args.trials,
        )
        _progress(requirement_root / "progress.json", events, "report", report["status"], [
            requirement_root / "tables", requirement_root / "case_studies",
            requirement_root / "final_report.md", requirement_root / "final_report.json",
        ])
        write_json(requirement_root / "run_summary.json", {
            "schema": "rtl2lean-multi_phase_proofs-summary-v1", "status": report["status"],
            "invocation_elapsed_s": time.perf_counter() - started,
            "corpus_sha256": sha256(final_path), "failures": [],
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
