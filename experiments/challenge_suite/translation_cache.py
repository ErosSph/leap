"""Content-addressed reuse of already kernel-verified frozen translation artifacts."""
from __future__ import annotations

import hashlib
import json
import statistics
import time
from pathlib import Path
from typing import Any

from experiments.adaptive_proving.io import atomic_json, sha256_file
from rtl2lean.pipeline.manifest import load_benchmarks


ARTIFACTS = ["Model.lean", "Model.olean", "lean_check.json", "Framework.lean",
             "Framework.olean", "framework_check.json", "targets.json"]


def _read(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def _key(benchmark, stage1: dict[str, Any]) -> str:
    payload = {"top": benchmark.top_module, "sources": stage1["source_sha256"],
               "compiler_fingerprint": stage1["compiler_fingerprint"],
               "unified_compilation_unit": benchmark.unified_compilation_unit}
    return hashlib.sha256(json.dumps(payload, sort_keys=True).encode()).hexdigest()


def _validate(entry: dict[str, Any]) -> bool:
    return all(Path(row["path"]).is_file() and sha256_file(Path(row["path"])) == row["sha256"]
               for row in entry["artifacts"])


def benchmark(project: Path, run_dir: Path, manifest: dict[str, Any],
              config: dict[str, Any]) -> dict[str, Any]:
    benchmarks = {row.slug: row for row in load_benchmarks()}
    sources = {row["dut"]: row for row in manifest["sources"]}
    entries = {}
    for dut in config["duts"]:
        model_dir = project / sources[dut]["model_dir"]
        stage1 = _read(model_dir.parent / "stage1.json")
        benchmark_row = benchmarks[dut]
        current_sources = {str(path): sha256_file(path) for path in benchmark_row.source_files}
        if current_sources != stage1.get("source_sha256"):
            raise RuntimeError(f"source changed since frozen translation: {dut}")
        lean_check = _read(model_dir / "lean_check.json")
        framework_check = _read(model_dir / "framework_check.json")
        if not lean_check.get("success") or not framework_check.get("success"):
            raise RuntimeError(f"unverified translation artifact: {dut}")
        artifacts = [{"path": str(model_dir / name), "sha256": sha256_file(model_dir / name),
                      "bytes": (model_dir / name).stat().st_size} for name in ARTIFACTS]
        entry = {"dut": dut, "cache_key": _key(benchmark_row, stage1),
            "compiler_fingerprint": stage1["compiler_fingerprint"],
            "source_sha256": current_sources, "original_stage1_elapsed_s": stage1["elapsed_s"],
            "generated_lean_loc": stage1.get("generated_lean_loc"), "artifacts": artifacts,
            "kernel_verified_before_cache": True}
        timings = []
        for _ in range(3):
            started = time.perf_counter()
            hit = _validate(entry)
            timings.append(time.perf_counter() - started)
            if not hit:
                raise RuntimeError(f"cache validation miss: {dut}")
        entry["lookup_trials_s"] = timings
        entry["median_verified_lookup_s"] = statistics.median(timings)
        entry["speedup_vs_recorded_cold"] = (stage1["elapsed_s"] / entry["median_verified_lookup_s"]
            if entry["median_verified_lookup_s"] else None)
        entries[dut] = entry
    cold = sum(row["original_stage1_elapsed_s"] for row in entries.values())
    warm = sum(row["median_verified_lookup_s"] for row in entries.values())
    result = {"schema": "rtl2lean-challenge_suite-translation-cache-v1",
        "optimization": "CONTENT_ADDRESSED_KERNEL_VERIFIED_ARTIFACT_CACHE",
        "semantic_translation_changed": False, "cache_scope": "repeat runs of a frozen compiler fingerprint",
        "invalidation": ["RTL content hash", "top module", "unified compilation mode",
                         "compiler semantic fingerprint", "artifact content hash"],
        "cold_time_source": "recorded original Stage-1 measurements, not rerun in this experiment",
        "original_cold_total_s": cold, "median_verified_lookup_total_s": warm,
        "speedup_vs_recorded_cold": cold / warm if warm else None,
        "first_time_translation_accelerated": False,
        "repeat_translation_accelerated": True, "entries": entries}
    atomic_json(run_dir / "translation" / "cache_benchmark.json", result)
    return result
