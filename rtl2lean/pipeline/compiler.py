"""Fail-closed Stage-1 semantic compilation and Lean kernel check."""
from __future__ import annotations

import json
import hashlib
import os
import pickle
import re
import shutil
import subprocess
import time
from dataclasses import dataclass
from pathlib import Path

from rtl2lean.backend.codegen import CodeGenerator
from rtl2lean.frontend import SVParser
from rtl2lean.middle_end.ir import normalize_combinational_schedule
from rtl2lean.middle_end.ir_converter import module_to_ir
from rtl2lean.middle_end.optimizer import Optimizer
from rtl2lean.middle_end.type_checker import TypeChecker

from .io import sha256, write_json
from .manifest import Benchmark
from .schema import DesignIR, build_design_ir


FORBIDDEN = re.compile(r"\b(?:sorry|admit)\b|\baxiom\b")


@dataclass
class Compilation:
    benchmark: Benchmark
    ast: object
    ir: object
    typed_ir: DesignIR
    model_path: Path
    model_code: str
    lean_result: dict


def compiler_fingerprint() -> str:
    digest = hashlib.sha256()
    package = Path(__file__).resolve().parents[1]
    semantic_sources = [
        *sorted((package / "frontend").glob("*.py")),
        *sorted((package / "middle_end").glob("*.py")),
        package / "backend" / "codegen.py",
        package / "pipeline" / "schema.py",
    ]
    for source in semantic_sources:
        digest.update(str(source.relative_to(package)).encode())
        digest.update(source.read_bytes())
    return digest.hexdigest()


def _cached_compilation(benchmark: Benchmark, destination: Path) -> Compilation | None:
    stage_path = destination / "stage1.json"
    cache_path = destination / "ir" / "compiler_objects.pkl"
    model_path = destination / "model" / "Model.lean"
    check_path = destination / "model" / "lean_check.json"
    if not all(path.is_file() for path in (stage_path, cache_path, model_path,
                                            model_path.with_suffix(".olean"), check_path)):
        return None
    stage = json.loads(stage_path.read_text(encoding="utf-8"))
    check = json.loads(check_path.read_text(encoding="utf-8"))
    hashes = {str(path): sha256(path) for path in benchmark.source_files}
    if not (
        stage.get("status") == "STAGE1_PASS"
        and check.get("success") is True
        and stage.get("source_sha256") == hashes
        and stage.get("model_sha256") == sha256(model_path)
        and stage.get("compiler_fingerprint") == compiler_fingerprint()
    ):
        return None
    cached = pickle.loads(cache_path.read_bytes())
    return Compilation(
        benchmark, cached["ast"], cached["ir"], cached["typed_ir"],
        model_path, model_path.read_text(encoding="utf-8"), check,
    )


def find_lean() -> str:
    configured = os.environ.get("RTL2LEAN_LEAN")
    candidates = [
        configured,
        shutil.which("lean"),
    ]
    for candidate in candidates:
        if candidate and Path(candidate).is_file():
            # Preserve the executable name for elan's lean -> elan shim.
            return str(Path(candidate).absolute())
    raise FileNotFoundError("Lean 4 executable not found")


def kernel_check(path: Path, timeout_s: int = 1800, build_olean: bool = True) -> dict:
    path = path.resolve()
    source = path.read_text(encoding="utf-8")
    forbidden = [
        {"line": line_no, "text": line.strip()}
        for line_no, line in enumerate(source.splitlines(), 1) if FORBIDDEN.search(line)
    ]
    if forbidden:
        return {"success": False, "returncode": None, "forbidden": forbidden,
                "stdout": "", "stderr": "forbidden unchecked declaration"}
    lean = find_lean()
    started = time.perf_counter()
    # Large flattened designs can exceed Lean's default native worker stack
    # even when maxRecDepth is sufficient.  This changes only checker resource
    # capacity, not trust level or kernel semantics.
    command = [lean, "-s", "65536"]
    if build_olean:
        command.extend(["-o", str(path.with_suffix(".olean"))])
    command.append(str(path))
    env = os.environ.copy()
    import_root = path.parent
    for candidate in (path.parent, *path.parents):
        if (candidate / "Model.lean").is_file():
            import_root = candidate
            break
        if (candidate / "model" / "Model.lean").is_file():
            import_root = candidate / "model"
            break
    env["LEAN_PATH"] = str(import_root) + (":" + env["LEAN_PATH"] if env.get("LEAN_PATH") else "")
    try:
        completed = subprocess.run(
            command, cwd=path.parent, capture_output=True, text=True,
            check=False, timeout=timeout_s, env=env,
        )
    except subprocess.TimeoutExpired as error:
        return {
            "success": False, "returncode": 124, "command": command,
            "elapsed_s": time.perf_counter() - started,
            "stdout": error.stdout.decode() if isinstance(error.stdout, bytes) else (error.stdout or ""),
            "stderr": (error.stderr.decode() if isinstance(error.stderr, bytes) else (error.stderr or ""))
                      + f"\nLean kernel check timed out after {timeout_s}s",
            "forbidden": forbidden,
        }
    return {
        "success": completed.returncode == 0,
        "returncode": completed.returncode,
        "command": command,
        "elapsed_s": time.perf_counter() - started,
        "stdout": completed.stdout,
        "stderr": completed.stderr,
        "forbidden": forbidden,
    }


def compile_benchmark(benchmark: Benchmark, output_root: Path) -> Compilation:
    destination = output_root / benchmark.slug
    cached = _cached_compilation(benchmark, destination)
    if cached is not None:
        return cached
    stage = destination / "model"
    stage.mkdir(parents=True, exist_ok=True)
    started = time.perf_counter()
    record = {
        "schema": "rtl2lean-stage1-result-v1",
        "design_id": benchmark.design_id,
        "top_module": benchmark.top_module,
        "compiler_fingerprint": compiler_fingerprint(),
        "stages": {},
    }
    try:
        parser = SVParser()
        ast = parser.parse_files(list(benchmark.source_files), benchmark.top_module,
                                 benchmark.unified_compilation_unit)[0]
        record["stages"]["parser"] = "PASS"
        _, errors = TypeChecker.check_module(ast)
        if errors:
            raise ValueError("typed AST check failed: " + "; ".join(map(str, errors)))
        record["stages"]["typed_ast"] = "PASS"
        ir = module_to_ir(ast)
        ir = Optimizer.optimize(ir, 2)
        ir = normalize_combinational_schedule(ir)
        record["stages"]["typed_ir"] = "PASS"
        typed = build_design_ir(benchmark.design_id, ast, ir)
        write_json(destination / "ir" / "design.json", typed.to_dict())
        cache_path = destination / "ir" / "compiler_objects.pkl"
        cache_path.write_bytes(pickle.dumps({"ast": ast, "ir": ir, "typed_ir": typed}))
        # ``ir`` was normalized immediately above.  Re-running dependency
        # scheduling inside codegen is deterministic but expensive on large
        # combinational designs, so pass the verified phase invariant through.
        model = CodeGenerator.generate(ir, already_normalized=True)
        model_path = stage / "Model.lean"
        model_path.write_text(model + "\n", encoding="utf-8")
        record["stages"]["lean_generation"] = "PASS"
        lean_result = kernel_check(model_path)
        write_json(stage / "lean_check.json", lean_result)
        record["stages"]["lean_kernel"] = "PASS" if lean_result["success"] else "FAIL"
        record.update({
            "status": "STAGE1_PASS" if lean_result["success"] else "FAIL",
            "source_sha256": {str(path): sha256(path) for path in benchmark.source_files},
            "model_sha256": sha256(model_path),
            "generated_lean_loc": len(model.splitlines()),
            "nondeterministic_inputs": list(typed.nondeterministic_inputs),
            "elapsed_s": time.perf_counter() - started,
        })
        write_json(destination / "stage1.json", record)
        if not lean_result["success"]:
            raise RuntimeError("Lean model rejected: " + lean_result["stderr"][-4000:])
        return Compilation(benchmark, ast, ir, typed, model_path, model, lean_result)
    except Exception as error:
        record.update({
            "status": "FAIL",
            "error_type": type(error).__name__,
            "error": str(error),
            "elapsed_s": time.perf_counter() - started,
        })
        write_json(destination / "stage1.json", record)
        unsupported_path = destination / "analysis" / "unsupported.json"
        if unsupported_path.is_file():
            payload = json.loads(unsupported_path.read_text(encoding="utf-8"))
            payload["blocking_unsupported"] = [{
                "dut": benchmark.design_id, "module": benchmark.top_module,
                "file": None, "line": None, "construct": type(error).__name__,
                "reason": str(error), "severity": "blocking",
                "dependency_relevance": "whole-model compilation",
            }]
            write_json(unsupported_path, payload)
        raise
