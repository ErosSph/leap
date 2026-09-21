"""CLI for model_calibration calibration freeze, run, and report phases."""
from __future__ import annotations

import argparse
import json
import traceback
from pathlib import Path
from typing import Any

from rtl2lean.pipeline.io import write_json
from rtl2lean.pipeline.manifest import DEFAULT_MANIFEST, load_benchmarks
from rtl2lean.model_calibration.analysis import build_analysis
from rtl2lean.model_calibration.runner import run_matrix
from rtl2lean.model_calibration.tasks import freeze_calibration


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="model_calibration LLM Lean capability calibration")
    parser.add_argument("--output", type=Path, default=Path("outputs"))
    parser.add_argument("--phase", choices=("freeze", "run", "analysis", "all"), default="all")
    parser.add_argument("--resume", action="store_true")
    parser.add_argument("--workers", type=int, default=3)
    return parser


def main(argv: list[str] | None = None) -> int:
    args = _parser().parse_args(argv)
    project = Path(__file__).resolve().parents[2]
    output_root = (args.output if args.output.is_absolute() else project / args.output).resolve()
    requirement_root = output_root / "model_calibration"
    requirement_root.mkdir(parents=True, exist_ok=True)
    benchmarks = load_benchmarks(DEFAULT_MANIFEST)
    try:
        if args.phase in {"freeze", "run", "all"}:
            freeze_calibration(benchmarks, output_root, requirement_root)
        if args.phase == "freeze":
            return 0
        if args.phase in {"run", "all"}:
            run_matrix(benchmarks, output_root, requirement_root, args.resume, args.workers)
        report = build_analysis(output_root, requirement_root)
        write_json(requirement_root / "run_summary.json", {
            "schema": "rtl2lean-model_calibration-summary-v1", "status": report["status"],
            "phase": args.phase, "failure": None,
        })
        (requirement_root / "failure.json").unlink(missing_ok=True)
        return 0 if report["status"] == "PASS" else 2
    except Exception as error:
        traceback.print_exc()
        write_json(requirement_root / "failure.json", {
            "schema": "rtl2lean-model_calibration-failure-v1",
            "error": repr(error), "traceback": traceback.format_exc(),
        })
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
