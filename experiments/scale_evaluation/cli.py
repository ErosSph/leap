from __future__ import annotations

import argparse
from pathlib import Path

from .orchestration import rebuild_report, resume, run_new, validate_environment


def main() -> int:
    parser = argparse.ArgumentParser(description="scale_evaluation experiment")
    parser.add_argument("command", choices=["validate", "run", "resume", "report"])
    parser.add_argument("--config", type=Path, default=Path("configs/scale_evaluation.yaml"))
    parser.add_argument("--run-dir", type=Path)
    parser.add_argument("--no-api", action="store_true")
    args = parser.parse_args()
    if args.command == "validate":
        _, _, _, _, result = validate_environment(args.config, api=not args.no_api)
        print(result["status"]); return 0
    if args.command == "run":
        run_dir, report = run_new(args.config, ["scale_evaluation", "run"])
        print(run_dir); print(report["status"]); return 0
    if not args.run_dir:
        parser.error("--run-dir is required for resume/report")
    report = resume(args.run_dir) if args.command == "resume" else rebuild_report(args.run_dir)
    print(report["status"]); return 0
