"""Lightweight syntax-only RTL checking, with one runtime for multiple files.

Usage: python -m rtl2lean.syntax_check file.v [file2.sv ...]

Each file has an independent SyntaxTree, just as in the original per-module
benchmark. This is NOT elaboration, dependency resolution, or Lean generation.
No trees/results are cached and macros do not leak between input files.
"""
import json
import sys
import time

import pyslang


def check_text(text):
    started = time.perf_counter()
    tree = pyslang.syntax.SyntaxTree.fromText(text)
    elapsed = time.perf_counter() - started
    return {"parse_s": elapsed,
            "diagnostics": [str(d.code) for d in tree.diagnostics],
            "status": "ERROR" if any(d.isError() for d in tree.diagnostics) else "PASS"}


def main(paths=None):
    paths = sys.argv[1:] if paths is None else paths
    if not paths:
        print("usage: python -m rtl2lean.syntax_check file.v [file2.sv ...]", file=sys.stderr)
        return 2
    failed = False
    for path in paths:
        try:
            with open(path, encoding="utf-8") as source:
                result = check_text(source.read())
        except (OSError, UnicodeError) as error:
            result = {"status": "INPUT_ERROR", "error": str(error)}
        failed |= result["status"] != "PASS"
        print(json.dumps({"input": path, **result}))
    return int(failed)


if __name__ == "__main__":
    raise SystemExit(main())
