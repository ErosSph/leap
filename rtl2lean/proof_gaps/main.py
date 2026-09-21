"""CLI orchestration for the experimental specification proof_gaps."""
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
from rtl2lean.proof_gaps.corpus import build_candidates
from rtl2lean.proof_gaps.experiment import (
    MAX_LLM_CALLS, MAX_REPAIRS_PER_CANDIDATE, MAX_TOTAL_TOKENS, PROVIDER_TIMEOUT_S,
    run_baseline, run_direct, run_lemma_first, validate_and_freeze,
)
from rtl2lean.proof_gaps.proof_gap import analyze_candidates, theorem_base_inventory
from rtl2lean.proof_gaps.report import build_report


def _read(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="proof_gaps proof-gap-aware evaluation")
    parser.add_argument("--output", type=Path, default=Path("outputs"))
    parser.add_argument("--phase", choices=("all", "corpus", "baseline", "direct", "lemma", "report"), default="all")
    parser.add_argument("--trials", type=int, default=1)
    parser.add_argument("--resume", action="store_true")
    parser.add_argument("--model", default="gpt-5.6-sol")
    parser.add_argument("--reasoning-effort", default="medium")
    return parser


def _progress(path: Path, events: list[dict[str, Any]], phase: str, status: str,
              artifacts: list[Path], error: str | None = None) -> None:
    events.append({
        "phase": phase, "status": status, "artifacts": [str(item) for item in artifacts],
        "blockers": [error] if error else [], "next": "automatic continuation",
    })
    write_json(path, {"schema": "rtl2lean-proof_gaps-progress-v1", "events": events})


def main(argv: list[str] | None = None) -> int:
    args = _parser().parse_args(argv)
    if args.trials < 1:
        raise SystemExit("--trials must be >= 1")
    project = Path(__file__).resolve().parents[2]
    output_root = (args.output if args.output.is_absolute() else project / args.output).resolve()
    requirement_root = output_root / "proof_gaps"
    requirement_root.mkdir(parents=True, exist_ok=True)
    benchmarks = load_benchmarks(DEFAULT_MANIFEST)
    snapshot_path = requirement_root / "frozen_prior_requirements.json"
    current = {
        "compositional_proofs": tree_digest(output_root / "compositional_proofs"),
        "proof_audit": tree_digest(output_root / "proof_audit"),
    }
    if snapshot_path.is_file():
        frozen = _read(snapshot_path)["tree_sha256"]
    else:
        frozen = current
        write_json(snapshot_path, {
            "schema": "rtl2lean-proof_gaps-prior-snapshot-v1", "tree_sha256": frozen,
        })
    provider_options = {
        "model": args.model, "reasoning_effort": args.reasoning_effort,
        "timeout_s": PROVIDER_TIMEOUT_S,
    }
    write_json(requirement_root / "run_manifest.json", {
        "schema": "rtl2lean-proof_gaps-run-v1", "phase": args.phase,
        "trials": args.trials, "resume": args.resume, "provider": provider_options,
        "prior_requirements_frozen": frozen, "prior_requirements_at_start": current,
        "order": ["DISCOVER", "GAP_ANALYZE", "FREEZE", "BASELINE", "DIRECT", "LEMMA_FIRST", "ANALYZE"],
        "gap_information_hidden_from_both_llm_arms": True,
        "reference_proofs_hidden_from_all_arms": True,
        "result_shaping": False,
        "fairness": {
            "same_theorem": True, "same_model": True, "same_foundation": True,
            "same_retrieval": True, "same_max_llm_calls": MAX_LLM_CALLS,
            "same_max_total_tokens": MAX_TOTAL_TOKENS,
            "same_max_repairs_per_candidate": MAX_REPAIRS_PER_CANDIDATE,
            "same_timeout_s": PROVIDER_TIMEOUT_S,
        },
    })
    events: list[dict[str, Any]] = []
    started = time.perf_counter()
    try:
        final_path = requirement_root / "corpus" / "final_properties.json"
        if args.resume and final_path.is_file() and _read(final_path).get("frozen_before_llm"):
            corpus = _read(final_path)
        else:
            candidates = build_candidates(benchmarks, output_root, requirement_root)
            inventory = theorem_base_inventory(benchmarks, output_root, requirement_root)
            analyzed = analyze_candidates(candidates, inventory, requirement_root)
            corpus = validate_and_freeze(benchmarks, analyzed, output_root, requirement_root)
        _progress(requirement_root / "progress.json", events, "discover-gap-analyze-freeze", "PASS", [
            requirement_root / "corpus" / "all_candidates.json",
            requirement_root / "proof_gap" / "theorem_base_inventory.json",
            requirement_root / "proof_gap" / "proof_gap_analysis.json",
            requirement_root / "proof_gap" / "coverage_analysis.json",
            requirement_root / "proof_gap" / "missing_relations.json",
            requirement_root / "proof_gap" / "proof_gap_depth.json",
            final_path, requirement_root / "corpus" / "challenge_properties.json",
        ])
        if args.phase == "corpus":
            return 0

        baseline_path = requirement_root / "baseline" / "results.json"
        baseline = (_read(baseline_path) if args.resume and baseline_path.is_file()
                    else run_baseline(benchmarks, corpus, output_root, requirement_root))
        _progress(requirement_root / "progress.json", events, "baseline", "PASS", [baseline_path])
        if args.phase == "baseline":
            return 0

        direct_path = requirement_root / "direct" / "results.json"
        direct = run_direct(benchmarks, corpus, baseline, output_root, requirement_root,
                            provider_options, args.trials, args.resume)
        _progress(requirement_root / "progress.json", events, "direct", "PASS", [
            direct_path, requirement_root / "direct" / "gap_resolution_audit.json",
        ])
        if args.phase == "direct":
            return 0

        lemma_path = requirement_root / "lemma_first" / "results.json"
        lemma = run_lemma_first(benchmarks, corpus, baseline, direct, output_root,
                                requirement_root, provider_options, args.trials, args.resume)
        _progress(requirement_root / "progress.json", events, "lemma-first", "PASS", [
            lemma_path, requirement_root / "lemma_first" / "intermediate_lemmas.json",
            requirement_root / "lemma_first" / "novelty.json",
            requirement_root / "lemma_first" / "gap_alignment.json",
            requirement_root / "lemma_first" / "causal_ablation.json",
        ])
        if args.phase == "lemma":
            return 0

        current_end = {
            "compositional_proofs": tree_digest(output_root / "compositional_proofs"),
            "proof_audit": tree_digest(output_root / "proof_audit"),
        }
        report = build_report(benchmarks, corpus, baseline, direct, lemma,
                              requirement_root, frozen, current_end, args.trials)
        _progress(requirement_root / "progress.json", events, "report", report["status"], [
            requirement_root / "final_report.json", requirement_root / "final_report.md",
            requirement_root / "tables", requirement_root / "case_studies",
        ])
        write_json(requirement_root / "run_summary.json", {
            "schema": "rtl2lean-proof_gaps-summary-v1", "status": report["status"],
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
