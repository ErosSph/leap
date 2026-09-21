import argparse
from pathlib import Path

from .config import load_config
from .orchestration import refresh_run, resume_run, run_new


def main() -> int:
    parser = argparse.ArgumentParser(description="challenge_suite experiments")
    parser.add_argument("command", choices=["validate", "run", "resume", "refresh"])
    parser.add_argument("--config", type=Path, default=Path("configs/challenge_suite.yaml"))
    parser.add_argument("--run-dir", type=Path)
    args = parser.parse_args()
    if args.command == "validate":
        config = load_config(args.config)
        source = Path(__file__).resolve().parents[2] / config["source_design_suite_run"]
        ok = (source / "final_report.json").is_file()
        print("PASS" if ok else "FAIL"); return 0 if ok else 1
    if args.command in {"resume", "refresh"}:
        if args.run_dir is None:
            parser.error(f"--run-dir is required with {args.command}")
        root, report = (resume_run(args.run_dir) if args.command == "resume"
                        else refresh_run(args.run_dir))
    else:
        root, report = run_new(args.config)
    print(root); print(report["status"])
    return 0 if report["status"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
