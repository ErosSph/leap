"""Unified foundation_first command-line interface."""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from .orchestration import report_run, resume_run, run_new, validate_environment


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="foundation_first foundation-first experiment")
    commands = parser.add_subparsers(dest="command", required=True)
    for command in ("validate", "run"):
        child = commands.add_parser(command); child.add_argument("--config", type=Path, required=True)
    for command in ("resume", "report"):
        child = commands.add_parser(command); child.add_argument("--run-dir", type=Path, required=True)
    return parser


def main(argv: list[str] | None = None) -> int:
    args = _parser().parse_args(argv)
    try:
        if args.command == "validate":
            *_unused, output = validate_environment(args.config)
        elif args.command == "run":
            run_dir, report = run_new(args.config, [sys.executable, "-m", "experiments.foundation_first", *(argv or sys.argv[1:])])
            output = {"run_dir": str(run_dir), "report": report}
        elif args.command == "resume":
            output = {"run_dir": str(args.run_dir.resolve()), "report": resume_run(args.run_dir)}
        else:
            output = {"run_dir": str(args.run_dir.resolve()), "report": report_run(args.run_dir)}
        print(json.dumps(output, indent=2, ensure_ascii=False)); return 0
    except Exception as error:
        print(json.dumps({"status": "FAIL", "error": str(error)}, indent=2, ensure_ascii=False), file=sys.stderr)
        return 1
