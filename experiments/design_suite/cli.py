from __future__ import annotations

import argparse
from pathlib import Path

from .orchestration import run_new, validate


def main() -> int:
    parser = argparse.ArgumentParser(description="design_suite experiment")
    parser.add_argument("command", choices=["validate", "run"])
    parser.add_argument("--config", type=Path, default=Path("configs/design_suite.yaml"))
    parser.add_argument("--no-api", action="store_true")
    args = parser.parse_args()
    if args.command == "validate":
        result = validate(args.config, api=not args.no_api)
        print(result["status"]); return 0 if result["status"] == "PASS" else 1
    run_dir, report = run_new(args.config, ["design_suite", "run"])
    print(run_dir); print(report["status"])
    return 0 if report["status"] == "PASS" else 1
