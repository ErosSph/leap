"""CLI for the same-task three-model Lemma-First experiment."""
from __future__ import annotations

import argparse
import traceback
from pathlib import Path

from rtl2lean.pipeline.io import write_json
from rtl2lean.pipeline.manifest import DEFAULT_MANIFEST, load_benchmarks
from rtl2lean.model_comparison.analysis import build_analysis
from rtl2lean.model_comparison.runner import run_matrix
from rtl2lean.model_comparison.tasks import freeze_lemma_first


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="model_comparison same-task Lemma-First calibration")
    parser.add_argument("--output", type=Path, default=Path("outputs"))
    parser.add_argument("--phase", choices=("freeze", "run", "analysis", "all"), default="all")
    parser.add_argument("--resume", action="store_true")
    parser.add_argument("--workers", type=int, default=3)
    return parser


def main(argv: list[str] | None = None) -> int:
    args = _parser().parse_args(argv)
    project = Path(__file__).resolve().parents[2]
    output_root = (args.output if args.output.is_absolute() else project / args.output).resolve()
    requirement_root = output_root / "model_comparison"
    requirement_root.mkdir(parents=True, exist_ok=True)
    benchmarks = load_benchmarks(DEFAULT_MANIFEST)
    try:
        if args.phase in {"freeze", "run", "all"}:
            freeze_lemma_first(output_root, requirement_root)
        if args.phase == "freeze":
            return 0
        if args.phase in {"run", "all"}:
            run_matrix(benchmarks, output_root, requirement_root, args.resume, args.workers)
        report = build_analysis(output_root, requirement_root)
        write_json(requirement_root / "run_summary.json", {
            "schema": "rtl2lean-model_comparison-summary-v1",
            "status": report["status"], "phase": args.phase, "failure": None,
        })
        (requirement_root / "failure.json").unlink(missing_ok=True)
        return 0 if report["status"] == "PASS" else 2
    except Exception as error:
        traceback.print_exc()
        write_json(requirement_root / "failure.json", {
            "schema": "rtl2lean-model_comparison-failure-v1",
            "error": repr(error), "traceback": traceback.format_exc(),
        })
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
