"""Unified command line entry point for translation."""
from __future__ import annotations

import argparse
import json
import sys
import time
import traceback
from pathlib import Path

from rtl2lean.pipeline.analysis import analyze_benchmark, analyze_repository
from rtl2lean.pipeline.compiler import compile_benchmark, find_lean
from rtl2lean.pipeline.io import write_json
from rtl2lean.pipeline.manifest import Benchmark, DEFAULT_MANIFEST, load_benchmarks, select_benchmarks
from rtl2lean.pipeline.report import build_report
from rtl2lean.proving.runner import generate_and_check, run_proving_experiment


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="RTL-to-Lean autonomous theorem proving")
    parser.add_argument("--benchmark", default=None, help="benchmark slug/design/top, or all")
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    parser.add_argument("--rtl", type=Path, nargs="+", help="custom RTL file(s) or directories")
    parser.add_argument("--top", help="custom RTL top module")
    parser.add_argument("--design-id", default="custom_rtl")
    parser.add_argument("--output", type=Path, default=Path("outputs"))
    phases = parser.add_mutually_exclusive_group()
    phases.add_argument("--analyze-only", action="store_true")
    phases.add_argument("--translate-only", action="store_true")
    phases.add_argument("--generate-theorems", action="store_true")
    phases.add_argument("--prove", action="store_true")
    phases.add_argument("--report", action="store_true")
    phases.add_argument("--autonomous", action="store_true")
    llm = parser.add_mutually_exclusive_group()
    llm.add_argument("--llm", dest="llm", action="store_true")
    llm.add_argument("--no-llm", dest="llm", action="store_false")
    parser.set_defaults(llm=None)
    parser.add_argument("--reuse", action=argparse.BooleanOptionalAction, default=True)
    parser.add_argument("--llm-model", default="gpt-5.6-sol")
    parser.add_argument("--reasoning-effort", default="medium")
    return parser


def _custom(args: argparse.Namespace) -> Benchmark:
    if not args.top:
        raise ValueError("--top is required with --rtl")
    extensions = {".v", ".sv", ".vh", ".svh"}
    files = []
    for item in args.rtl:
        item = item.resolve()
        if item.is_dir():
            files.extend(path for path in item.rglob("*") if path.suffix.lower() in extensions)
        elif item.is_file():
            files.append(item)
        else:
            raise FileNotFoundError(item)
    if not files:
        raise ValueError("--rtl did not resolve to any Verilog/SystemVerilog files")
    return Benchmark(args.design_id, args.top, "local", "uncommitted", tuple(sorted(set(files))), ("custom",))


def _select(args: argparse.Namespace) -> list[Benchmark]:
    if args.rtl:
        return [_custom(args)]
    return select_benchmarks(args.benchmark or "all", args.manifest.resolve())


def _record_progress(output: Path, events: list[dict], phase: str, status: str,
                     benchmark: str | None, artifacts: list[str], error: str | None = None) -> None:
    events.append({
        "phase": phase, "benchmark": benchmark, "status": status,
        "files_changed": [], "commands_executed": ["current unified CLI invocation"],
        "tests_executed": [], "unsupported_constructs": [],
        "current_blockers": [error] if error else [], "generated_artifacts": artifacts,
        "next_phase": "automatic continuation",
    })
    write_json(output / "progress.json", {"schema": "rtl2lean-progress-v1", "events": events})


def _clear_stale_failure(output: Path, benchmark: Benchmark) -> None:
    """A later successful requested stage supersedes an earlier failure record."""
    (output / benchmark.slug / "failure.json").unlink(missing_ok=True)


def main(argv: list[str] | None = None) -> int:
    args = _parser().parse_args(argv)
    project = Path(__file__).resolve().parents[2]
    output = args.output if args.output.is_absolute() else project / args.output
    output.mkdir(parents=True, exist_ok=True)
    benchmarks = _select(args)
    events: list[dict] = []
    failures = []
    started = time.perf_counter()
    use_llm = args.llm if args.llm is not None else bool(args.autonomous or args.prove)
    run_all = args.autonomous or not any((args.analyze_only, args.translate_only,
                                          args.generate_theorems, args.prove, args.report))
    run_manifest = {
        "schema": "rtl2lean-run-manifest-v1", "argv": sys.argv if argv is None else argv,
        "project_root": str(project), "output_root": str(output),
        "lean": find_lean(), "benchmarks": [item.design_id for item in benchmarks],
        "llm_enabled": use_llm, "reuse_enabled": args.reuse,
        "manual_intervention": False,
    }
    write_json(output / "run_manifest.json", run_manifest)

    if args.report:
        build_report(benchmarks, output)
        return 0

    analyze_repository(output)
    analyses = {}
    for benchmark in benchmarks:
        print(f"[Phase 0] analyze {benchmark.design_id}", flush=True)
        try:
            analyses[benchmark.design_id] = analyze_benchmark(benchmark, output)
            _record_progress(output, events, "Phase 0", "PASS", benchmark.design_id,
                             [str(output / benchmark.slug / "analysis")])
        except Exception as error:
            failures.append((benchmark.design_id, "analysis", repr(error)))
            _record_progress(output, events, "Phase 0", "FAIL", benchmark.design_id, [], repr(error))
    if args.analyze_only:
        return 1 if failures else 0

    # Checkpoint B designs precede Checkpoint C; classification is derived from RTL.
    ordered = sorted(benchmarks, key=lambda item: len(
        analyses.get(item.design_id, {}).get("clocks", {}).get("clock_signals", [])))
    for benchmark in ordered:
        if benchmark.design_id not in analyses:
            continue
        print(f"[Stage 1] compile {benchmark.design_id}", flush=True)
        try:
            compilation = compile_benchmark(benchmark, output)
            _record_progress(output, events, "Stages 1-6", "PASS", benchmark.design_id,
                             [str(compilation.model_path), str(output / benchmark.slug / "ir" / "design.json")])
            if args.translate_only:
                _clear_stale_failure(output, benchmark)
                continue
            print(f"[Stage 2] generate/check L1-L4 for {benchmark.design_id}", flush=True)
            bundle, _ = generate_and_check(compilation)
            _record_progress(output, events, "Stages 7-12", "PASS", benchmark.design_id,
                             [str(bundle.foundation_path), str(bundle.targets_path)])
            if args.generate_theorems:
                _clear_stale_failure(output, benchmark)
                continue
            if args.prove or run_all:
                print(f"[Stage 3] baseline/assisted proving {benchmark.design_id}", flush=True)
                result = run_proving_experiment(
                    compilation, bundle, use_llm=use_llm, enable_reuse=args.reuse,
                    llm_model=args.llm_model, reasoning_effort=args.reasoning_effort,
                )
                _record_progress(output, events, "Stages 13-24", result["status"], benchmark.design_id,
                                 [str(output / benchmark.slug / "stage3.json")])
                if result["status"] == "STAGE3_PASS":
                    _clear_stale_failure(output, benchmark)
        except Exception as error:
            traceback.print_exc()
            failures.append((benchmark.design_id, "pipeline", repr(error)))
            write_json(output / benchmark.slug / "failure.json", {
                "dut": benchmark.design_id, "error": repr(error), "traceback": traceback.format_exc(),
            })
            _record_progress(output, events, "pipeline", "FAIL", benchmark.design_id, [], repr(error))

    report = build_report(benchmarks, output)
    write_json(output / "run_summary.json", {
        "schema": "rtl2lean-run-summary-v1", "elapsed_s": time.perf_counter() - started,
        "failures": failures, "fully_automated_successes": report["fully_automated_successes"],
    })
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
