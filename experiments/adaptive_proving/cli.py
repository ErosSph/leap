"""Command line interface required by the experimental specification adaptive_proving."""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from .orchestration import report_run, resume_run, run_new, validate_environment


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="adaptive_proving reproducible experiment")
    subparsers = parser.add_subparsers(dest="command", required=True)
    for command in ("validate", "run"):
        child = subparsers.add_parser(command)
        child.add_argument("--config", type=Path, required=True)
    for command in ("resume", "report"):
        child = subparsers.add_parser(command)
        child.add_argument("--run-dir", type=Path, required=True)
    return parser


def main(argv: list[str] | None = None) -> int:
    args = _parser().parse_args(argv)
    try:
        if args.command == "validate":
            _config, _tasks, _source, result = validate_environment(args.config)
            output = result
        elif args.command == "run":
            run_dir, report = run_new(args.config, [sys.executable, "-m", "experiments.adaptive_proving", *(argv or sys.argv[1:])])
            output = {"run_dir": str(run_dir), "report": report}
        elif args.command == "resume":
            report = resume_run(args.run_dir)
            output = {"run_dir": str(args.run_dir.resolve()), "report": report}
        else:
            report = report_run(args.run_dir)
            output = {"run_dir": str(args.run_dir.resolve()), "report": report}
        print(json.dumps(output, indent=2, ensure_ascii=False))
        return 0
    except Exception as error:
        print(json.dumps({"status": "FAIL", "error": str(error)}, indent=2, ensure_ascii=False), file=sys.stderr)
        return 1
