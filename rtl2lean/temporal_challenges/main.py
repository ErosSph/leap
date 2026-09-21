"""Command-line runner for the experimental specification temporal_challenges."""
from __future__ import annotations

import argparse
import json
import time
import traceback
from pathlib import Path
from typing import Any

from rtl2lean.pipeline.io import sha256, write_json
from rtl2lean.pipeline.manifest import DEFAULT_MANIFEST, load_benchmarks
from rtl2lean.temporal_challenges.corpus import build_challenge_corpus, select_until_pair
from rtl2lean.temporal_challenges.experiment import (
    EQUAL_TOTAL_LLM_CALL_BUDGET,
    run_baseline,
    run_direct,
    run_lemma_first,
    validate_and_freeze,
)
from rtl2lean.temporal_challenges.foundation import build_temporal_challenges_foundations, chain_names
from rtl2lean.temporal_challenges.report import build_report, tree_digest


def _read(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="temporal_challenges hard temporal evaluation")
    parser.add_argument("--output", type=Path, default=Path("outputs"))
    parser.add_argument("--phase", choices=("all", "corpus", "baseline", "direct", "lemma", "report"), default="all")
    parser.add_argument("--resume", action="store_true")
    parser.add_argument("--model", default="gpt-5.6-sol")
    parser.add_argument("--reasoning-effort", default="medium")
    return parser


def _progress(path: Path, events: list[dict[str, Any]], phase: str, status: str,
              artifacts: list[Path], error: str | None = None) -> None:
    events.append({
        "phase": phase, "status": status, "artifacts": [str(x) for x in artifacts],
        "blockers": [error] if error else [], "next": "automatic continuation",
    })
    write_json(path, {"schema": "rtl2lean-temporal_challenges-progress-v1", "events": events})


def _until_artifacts(requirement_root: Path, foundations: dict[str, Any]) -> None:
    selected = next((x for x in foundations["foundations"] if x.get("selected_until_chain")), None)
    mapping = [
        ("register_hold_lemmas.json", "post_comb_hold", "register_hold"),
        ("preservation_lemmas.json", "state_preservation"),
        ("prefix_preservation.json", "prefix_preservation"),
        ("completion_witnesses.json", "completion_witness"),
    ]
    for filename, *kinds in mapping:
        rows = []
        if selected:
            for kind in kinds:
                rows.append({
                    "dut": selected["dut"], "destination": selected["destination"],
                    "kind": kind, "lemma": selected["chain_lemmas"][kind],
                    "hold_seed": selected["hold_seed"], "update_seed": selected["update_seed"],
                    "kernel_verified": selected["kernel_check"]["success"],
                    "foundation_path": selected["foundation_path"],
                    "derived_not_assumed": True,
                })
        write_json(requirement_root / "until" / filename, {
            "schema": f"rtl2lean-temporal_challenges-{filename.removesuffix('.json').replace('_', '-')}-v1",
            "rows": rows, "blocker": None if rows else "NO_KERNEL_VALIDATED_HOLD_UPDATE_CHAIN",
        })


def main(argv: list[str] | None = None) -> int:
    args = _parser().parse_args(argv)
    project = Path(__file__).resolve().parents[2]
    output_root = (args.output if args.output.is_absolute() else project / args.output).resolve()
    requirement_root = output_root / "temporal_challenges"
    requirement_root.mkdir(parents=True, exist_ok=True)
    benchmarks = load_benchmarks(DEFAULT_MANIFEST)
    r3_root = output_root / "temporal"
    current_r3_digest = tree_digest(r3_root)
    snapshot_path = requirement_root / "temporal_snapshot.json"
    if snapshot_path.is_file():
        snapshot = _read(snapshot_path)
        r3_digest_before = snapshot["tree_sha256"]
    else:
        snapshot = {
            "schema": "rtl2lean-temporal_challenges-temporal-snapshot-v1",
            "tree_sha256": current_r3_digest,
            "purpose": "Immutable pre-Requirement-4 digest of frozen temporal outputs",
        }
        write_json(snapshot_path, snapshot)
        r3_digest_before = current_r3_digest
    provider_options = {
        "model": args.model, "reasoning_effort": args.reasoning_effort, "timeout_s": 300,
    }
    started = time.perf_counter(); events: list[dict[str, Any]] = []
    write_json(requirement_root / "run_manifest.json", {
        "schema": "rtl2lean-temporal_challenges-run-manifest-v1",
        "benchmarks": [x.design_id for x in benchmarks], "phase": args.phase,
        "resume": args.resume, "provider": provider_options,
        "temporal_digest_before": r3_digest_before,
        "temporal_digest_at_run_start": current_r3_digest,
        "temporal_snapshot": str(snapshot_path),
        "independent_challenge_corpus": True, "freeze_then_run": True,
        "result_shaping": False, "direct_not_weakened": True,
        "same_theorem_model_foundation_retrieval": True,
        "equal_total_llm_call_budget": EQUAL_TOTAL_LLM_CALL_BUDGET,
        "variable_completion_requires_real_timing_and_sound_finite_bound": True,
    })

    try:
        frozen_path = requirement_root / "hard_temporal" / "final_properties.json"
        if args.resume and frozen_path.is_file() and _read(frozen_path).get("frozen_before_baseline"):
            corpus = _read(frozen_path)
            foundations = _read(requirement_root / "until" / "foundation_checks.json")
        else:
            until_pair, _ = select_until_pair(benchmarks, output_root, requirement_root)
            foundations = build_temporal_challenges_foundations(
                benchmarks, output_root, requirement_root, until_pair,
            )
            _until_artifacts(requirement_root, foundations)
            generated = build_challenge_corpus(
                benchmarks, output_root, requirement_root, until_pair,
            )
            corpus = validate_and_freeze(
                benchmarks, generated, output_root, requirement_root,
            )
            # Synchronize the UNTIL-only view with the post-validation corpus.
            write_json(requirement_root / "until" / "until_properties.json", {
                "properties": [x for x in corpus["properties"] if x["property_family"] == "UNTIL"],
                "why_not_found": None if any(x["property_family"] == "UNTIL" for x in corpus["properties"])
                else "NO_KERNEL_VALIDATED_UNTIL_PROPERTY",
            })
        _progress(requirement_root / "progress.json", events, "discover-validate-freeze", "PASS", [
            frozen_path, requirement_root / "hard_temporal" / "freeze.json",
            requirement_root / "until" / "foundation_checks.json",
        ])
        if args.phase == "corpus":
            return 0

        baseline_path = requirement_root / "baseline" / "results.json"
        baseline = (_read(baseline_path) if args.resume and baseline_path.is_file()
                    else run_baseline(benchmarks, corpus, output_root, requirement_root))
        _progress(requirement_root / "progress.json", events, "baseline", "PASS", [baseline_path])
        if args.phase == "baseline":
            return 0

        direct_path = requirement_root / "direct_llm" / "results.json"
        # Per-target resume logic distinguishes real proof outcomes from pure
        # provider failures; do not bypass that audit merely because an
        # aggregate file exists.
        direct = run_direct(
            benchmarks, corpus, baseline, output_root, requirement_root,
            provider_options, args.resume,
        )
        _progress(requirement_root / "progress.json", events, "direct", "PASS", [
            direct_path, requirement_root / "direct_llm" / "inline_decomposition_audit.json",
        ])
        if args.phase == "direct":
            return 0

        lemma_path = requirement_root / "lemma_first" / "results.json"
        lemma = run_lemma_first(
            benchmarks, corpus, baseline, direct, output_root,
            requirement_root, provider_options, args.resume,
        )
        _progress(requirement_root / "progress.json", events, "lemma-first", "PASS", [
            lemma_path, requirement_root / "lemma_first" / "novelty.json",
            requirement_root / "lemma_first" / "causal_ablation.json",
        ])
        if args.phase == "lemma":
            return 0

        report = build_report(
            benchmarks, corpus, baseline, direct, lemma, requirement_root, r3_digest_before,
        )
        _progress(requirement_root / "progress.json", events, "report-integrity", report["status"], [
            requirement_root / "final_report.json", requirement_root / "final_report.md",
            requirement_root / "lean_integrity.json", requirement_root / "tables",
        ])
        write_json(requirement_root / "run_summary.json", {
            "schema": "rtl2lean-temporal_challenges-run-summary-v1", "status": report["status"],
            "invocation_elapsed_s": time.perf_counter() - started,
            "recorded_experiment_Te2e_s": (
                baseline["metrics"]["Te2e"] + direct["metrics"]["Te2e"] + lemma["metrics"]["Te2e"]
            ),
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
