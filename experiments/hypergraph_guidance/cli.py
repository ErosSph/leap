from __future__ import annotations
import argparse, json, sys
from pathlib import Path
from .orchestration import report_run, resume_run, run_new, validate_environment

def main(argv=None):
    parser=argparse.ArgumentParser(description="hypergraph_guidance TPOH experiment"); commands=parser.add_subparsers(dest="command",required=True)
    for name in ("validate","run"): child=commands.add_parser(name); child.add_argument("--config",type=Path,required=True)
    for name in ("resume","report"): child=commands.add_parser(name); child.add_argument("--run-dir",type=Path,required=True)
    args=parser.parse_args(argv)
    try:
        if args.command=="validate": *_rest,result=validate_environment(args.config)
        elif args.command=="run": run_dir,result=run_new(args.config,[sys.executable,"-m","experiments.hypergraph_guidance",*(argv or sys.argv[1:])])
        elif args.command=="resume": run_dir=args.run_dir.resolve();result=resume_run(run_dir)
        else: run_dir=args.run_dir.resolve();result=report_run(run_dir)
        print(json.dumps({"run_dir":str(run_dir) if 'run_dir' in locals() else None,"report":result},indent=2,ensure_ascii=False));return 0
    except Exception as error:
        print(json.dumps({"status":"FAIL","error":str(error)},indent=2,ensure_ascii=False),file=sys.stderr);return 1
