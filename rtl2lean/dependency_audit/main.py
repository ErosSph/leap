"""CLI orchestration for the experimental specification dependency_audit."""
from __future__ import annotations

import argparse
import json
import time
import traceback
from pathlib import Path
from typing import Any

from rtl2lean.pipeline.io import write_json
from rtl2lean.pipeline.manifest import DEFAULT_MANIFEST, load_benchmarks
from rtl2lean.compositional_proofs.report import tree_digest
from rtl2lean.dependency_audit.analysis import analyze_paths, reevaluate_strong
from rtl2lean.dependency_audit.dependency import extract_dependencies
from rtl2lean.dependency_audit.report import build_report


def _read(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="dependency_audit recursive semantic bypass audit")
    parser.add_argument("--output", type=Path, default=Path("outputs"))
    parser.add_argument(
        "--phase", choices=("all", "dependency", "analysis", "report"), default="all",
    )
    parser.add_argument("--resume", action="store_true")
    return parser


def _progress(path: Path, events: list[dict[str, Any]], phase: str, status: str,
              artifacts: list[Path], error: str | None = None) -> None:
    events.append({
        "phase": phase, "status": status, "artifacts": [str(item) for item in artifacts],
        "blockers": [error] if error else [], "next": "automatic continuation",
    })
    write_json(path, {"schema": "rtl2lean-dependency_audit-progress-v1", "events": events})


def main(argv: list[str] | None = None) -> int:
    args = _parser().parse_args(argv)
    project = Path(__file__).resolve().parents[2]
    output_root = (args.output if args.output.is_absolute() else project / args.output).resolve()
    requirement_root = output_root / "dependency_audit"
    requirement_root.mkdir(parents=True, exist_ok=True)
    benchmarks = load_benchmarks(DEFAULT_MANIFEST)
    snapshot = requirement_root / "frozen_multi_phase_proofs.json"
    current_r8 = tree_digest(output_root / "multi_phase_proofs")
    current_models = {row.design_id: tree_digest(output_root / row.slug / "model") for row in benchmarks}
    if snapshot.is_file():
        frozen = _read(snapshot)
        frozen_r8 = frozen["multi_phase_proofs_tree_sha256"]
        frozen_models = frozen["theorem_base_tree_sha256"]
    else:
        frozen_r8, frozen_models = current_r8, current_models
        write_json(snapshot, {
            "schema": "rtl2lean-dependency_audit-frozen-r8-v1",
            "multi_phase_proofs_tree_sha256": frozen_r8,
            "theorem_base_tree_sha256": frozen_models,
            "frozen_before_dependency_audit": True,
        })
    if current_r8 != frozen_r8 or current_models != frozen_models:
        raise SystemExit("multi_phase_proofs or its theorem base changed after dependency_audit freeze")
    write_json(requirement_root / "run_manifest.json", {
        "schema": "rtl2lean-dependency_audit-run-v1", "phase": args.phase, "resume": args.resume,
        "multi_phase_proofs_rerun": False, "new_properties_generated": False,
        "baseline_reanalyzed": False, "direct_llm_rerun": False,
        "lemma_first_llm_rerun": False, "proofs_modified": False,
        "audit_scope": {"bottleneck_challenges": 10, "direct_proofs": 50, "lemma_first_proofs": 50},
        "dependency_source": "Lean elaborated proof-term ConstantInfo values",
        "simp_policy": "actual constants retained in elaborated proof terms; implicit dependencies reported",
        "classification_policy": "uniform four-way semantic classification over all 50 frozen Direct proofs",
    })
    events: list[dict[str, Any]] = []
    started = time.perf_counter()
    try:
        dependency_paths = [
            requirement_root / "dependency" / name for name in (
                "direct_dependencies.json", "lemma_first_dependencies.json", "recursive_expansion.json",
                "expanded_dependency_graph.json",
            )
        ]
        if args.resume and all(path.is_file() for path in dependency_paths[:3]):
            direct = _read(dependency_paths[0]); lemma = _read(dependency_paths[1])
            expansions = _read(dependency_paths[2])
        else:
            direct, lemma, expansions = extract_dependencies(benchmarks, output_root, requirement_root)
        _progress(requirement_root / "progress.json", events, "recursive-dependency-expansion", "PASS",
                  dependency_paths)
        if args.phase == "dependency":
            return 0

        analysis_paths = [
            requirement_root / "normalized_paths" / "direct_paths.json",
            requirement_root / "normalized_paths" / "lemma_first_paths.json",
            requirement_root / "normalized_paths" / "path_overlap.json",
            requirement_root / "bypass" / "classification.json",
            requirement_root / "strong_bottleneck" / "reevaluation.json",
        ]
        if args.resume and all(path.is_file() for path in analysis_paths):
            dpaths, lpaths, overlaps, classification, strong = map(_read, analysis_paths)
        else:
            dpaths, lpaths, overlaps, classification = analyze_paths(
                output_root, requirement_root, direct, lemma, expansions,
            )
            strong = reevaluate_strong(output_root, requirement_root, classification)
        _progress(requirement_root / "progress.json", events, "normalize-and-classify", "PASS",
                  analysis_paths)
        if args.phase == "analysis":
            return 0

        report = build_report(
            benchmarks, output_root, requirement_root, direct, lemma, expansions,
            dpaths, lpaths, overlaps, classification, strong, frozen_r8, frozen_models,
        )
        _progress(requirement_root / "progress.json", events, "report", report["status"], [
            requirement_root / "tables", requirement_root / "case_studies",
            requirement_root / "final_report.md", requirement_root / "final_report.json",
        ])
        write_json(requirement_root / "run_summary.json", {
            "schema": "rtl2lean-dependency_audit-summary-v1", "status": report["status"],
            "invocation_elapsed_s": time.perf_counter() - started,
            "multi_phase_proofs_tree_sha256": frozen_r8, "failures": [],
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
