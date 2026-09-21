"""Adapt the exact frozen multi_phase_proofs/9 challenges without regenerating them."""
from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any

from .config import resolve_path
from .io import sha256_file, sha256_text, tree_digest


class FrozenInputError(RuntimeError):
    pass


ALIASES = {
    "secworks_aes_core": "aes", "secworks_modexp_core": "modexp",
    "olofk_serv_rf_top": "serv", "yosys_picorv32": "picorv32",
    "freecores_ethmac": "ethmac",
}


THEOREM_RE = re.compile(r"(?ms)^theorem\s+([A-Za-z_][A-Za-z0-9_']*)\s+(.*?)\s*:=\s*by")


def _read(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def _declaration_block(source: str, name: str) -> str:
    pattern = re.compile(
        rf"(?ms)^(?:def|theorem|abbrev)\s+{re.escape(name)}\b.*?"
        r"(?=\n\n(?:def|theorem|abbrev|end)\b|\Z)"
    )
    match = pattern.search(source)
    return match.group(0).strip() if match else f"-- declaration {name} is imported from R3Foundation"


def _foundation_statements(model_dir: Path) -> list[dict[str, str]]:
    rows = []
    for filename in (
        "Framework.lean", "R3Base.lean", "R3Foundation.lean",
        "R4Foundation.lean", "R5Foundation.lean",
    ):
        path = model_dir / filename
        if not path.is_file():
            continue
        for match in THEOREM_RE.finditer(path.read_text(encoding="utf-8")):
            name = match.group(1)
            if filename == "R3Base.lean":
                name = f"R3Temporal.{name}"
            rows.append({
                "name": name,
                "statement": re.sub(r"^:\s*", "", match.group(2).strip()),
                "source_file": filename,
            })
    return rows


def load_frozen_tasks(project: Path, config: dict[str, Any]) -> tuple[list[dict[str, Any]], dict[str, Any]]:
    challenge_path = resolve_path(project, config["challenge_manifest"])
    baseline_path = resolve_path(project, config["baseline_manifest"])
    benchmark_path = resolve_path(project, config["benchmark_manifest"])
    challenges_payload = _read(challenge_path)
    challenge_rows = challenges_payload.get("properties") or []
    if challenges_payload.get("frozen_before_proof") is not True or len(challenge_rows) != 10:
        raise FrozenInputError("multi_phase_proofs source must contain exactly 10 pre-frozen challenges")
    if len({row["property_id"] for row in challenge_rows}) != 10:
        raise FrozenInputError("frozen challenge IDs are not unique")
    if any(row.get("validation_status") != "KERNEL_VALIDATED" for row in challenge_rows):
        raise FrozenInputError("all frozen challenges must be kernel validated")

    baseline_rows = _read(baseline_path).get("results") or []
    baseline_map = {(row["dut"], row["property_id"]): row for row in baseline_rows}
    benchmark_payload = _read(benchmark_path)
    benchmarks = benchmark_payload.get("designs") or []
    benchmark_map = {row["design_id"]: row for row in benchmarks}
    tasks: list[dict[str, Any]] = []
    theorem_bases: list[dict[str, Any]] = []
    for index, prop in enumerate(challenge_rows, 1):
        key = (prop["dut"], prop["property_id"])
        if key not in baseline_map:
            raise FrozenInputError(f"missing multi_phase_proofs baseline record: {key}")
        benchmark = benchmark_map.get(prop["dut"])
        if benchmark is None:
            raise FrozenInputError(f"frozen DUT absent from benchmark manifest: {prop['dut']}")
        slug = ALIASES.get(benchmark["design_id"], benchmark["design_id"])
        model_dir = project / "outputs" / slug / "model"
        required = [model_dir / name for name in (
            "Model.lean", "Framework.lean", "R3Base.lean", "R3Foundation.lean",
            "R4Foundation.lean", "R5Foundation.lean",
        )]
        missing = [str(path) for path in required if not path.is_file()]
        if missing:
            raise FrozenInputError("missing frozen Lean model files: " + ", ".join(missing))
        r3_base = (model_dir / "R3Base.lean").read_text(encoding="utf-8")
        r3_foundation = (model_dir / "R3Foundation.lean").read_text(encoding="utf-8")
        r5_foundation = (model_dir / "R5Foundation.lean").read_text(encoding="utf-8")
        combined = r3_foundation + "\n" + r5_foundation
        snippets = [r3_base, r5_foundation, (
            "proof_gaps fair-arm policy: prove the exact target from the supplied current theorem base. "
            "No pre-proof analyzer output or predicted missing relation is supplied. Intermediate lemmas "
            "must be semantically new, kernel checked, and not wrappers around an existing theorem."
        )]
        for name in ["r3Step", "r3Run", *prop.get("foundation_lemmas", [])]:
            snippets.append(_declaration_block(combined, name))
        baseline_error = "\n".join(
            (str(row.get("stdout") or "") + str(row.get("stderr") or ""))[-2500:]
            for row in baseline_map[key].get("attempts", []) if not row.get("success")
        )[-12000:]
        relevant = [
            _declaration_block(combined, name).split(":= by", 1)[0]
            for name in prop.get("foundation_lemmas", [])
        ]
        serialized = {
            "dut": prop["dut"], "target_name": prop["property_id"],
            "target_statement": prop["theorem_statement"], "property_type": "HIGH_LEVEL_TEMPORAL",
            "state_type": f"{benchmark['top_module']}State",
            "required_state_fields": list(prop.get("referenced_state_fields", [])),
            "required_input_fields": list(prop.get("referenced_inputs", [])),
            "assumptions": [], "context_import": "R5Foundation",
            "context_snippets": snippets, "relevant_foundational_lemmas": relevant,
            "base_lean_error": baseline_error, "future_targets": [],
        }
        context = "\n\n".join(snippets)
        task = {
            "challenge_id": f"C{index:02d}",
            "task_id": serialized["target_name"],
            "dut": serialized["dut"],
            "module": benchmark["top_module"],
            "model_dir": str(model_dir.relative_to(project)),
            "context_import": serialized["context_import"],
            "statement": serialized["target_statement"],
            "statement_sha256": sha256_text(serialized["target_statement"]),
            "property_type": serialized["property_type"],
            "state_type": serialized["state_type"],
            "required_state_fields": serialized["required_state_fields"],
            "required_input_fields": serialized["required_input_fields"],
            "assumptions": serialized["assumptions"],
            "context": context,
            "context_sha256": sha256_text(context),
            "relevant_foundational_lemmas": relevant,
            "baseline_lean_error": baseline_error,
            "baseline_error_sha256": sha256_text(baseline_error),
            "foundation_lemmas": list(prop.get("foundation_lemmas", [])),
            "L1": list(prop.get("L1", [])),
            "L2": list(prop.get("L2", [])),
            "L3": list(prop.get("L3", [])),
            "L4": list(prop.get("L4", [])),
            "source_challenge_sha256": sha256_text(json.dumps(
                prop, ensure_ascii=False, sort_keys=True, separators=(",", ":")
            )),
            "adapted_task_sha256": sha256_text(json.dumps(
                serialized, ensure_ascii=False, sort_keys=True, separators=(",", ":")
            )),
            "reference_proof_present_in_source": bool(prop.get("reference_proof")),
            "reference_proof_excluded_from_task": True,
        }
        tasks.append(task)

    for benchmark in benchmarks:
        if benchmark["design_id"] not in {row["dut"] for row in tasks}:
            continue
        slug = ALIASES.get(benchmark["design_id"], benchmark["design_id"])
        model_dir = project / "outputs" / slug / "model"
        declarations = _foundation_statements(model_dir)
        theorem_bases.append({
            "dut": benchmark["design_id"],
            "module": benchmark["top_module"],
            "model_dir": str(model_dir.relative_to(project)),
            "tree_sha256": tree_digest(model_dir),
            "files": [{
                "path": str(path.relative_to(project)), "sha256": sha256_file(path),
            } for path in sorted(model_dir.glob("*.lean"))],
            "theorems": declarations,
            "theorem_count": len(declarations),
        })

    source = {
        "challenge_manifest": str(challenge_path.relative_to(project)),
        "challenge_manifest_sha256": sha256_file(challenge_path),
        "baseline_manifest": str(baseline_path.relative_to(project)),
        "baseline_manifest_sha256": sha256_file(baseline_path),
        "benchmark_manifest": str(benchmark_path.relative_to(project)),
        "benchmark_manifest_sha256": sha256_file(benchmark_path),
        "dependency_audit_snapshot": _dependency_audit_snapshot(project),
        "theorem_bases": theorem_bases,
    }
    return tasks, source


def _dependency_audit_snapshot(project: Path) -> dict[str, Any]:
    path = project / "outputs" / "dependency_audit" / "frozen_multi_phase_proofs.json"
    if not path.is_file():
        raise FrozenInputError("dependency_audit frozen multi_phase_proofs snapshot is missing")
    return {"path": str(path.relative_to(project)), "sha256": sha256_file(path), "payload": _read(path)}


def verify_frozen_tasks(project: Path, tasks: list[dict[str, Any]], source: dict[str, Any]) -> None:
    challenge_path = project / source["challenge_manifest"]
    baseline_path = project / source["baseline_manifest"]
    benchmark_path = project / source["benchmark_manifest"]
    checks = [
        (challenge_path, source["challenge_manifest_sha256"]),
        (baseline_path, source["baseline_manifest_sha256"]),
        (benchmark_path, source["benchmark_manifest_sha256"]),
        (project / source["dependency_audit_snapshot"]["path"], source["dependency_audit_snapshot"]["sha256"]),
    ]
    for path, expected in checks:
        if not path.is_file() or sha256_file(path) != expected:
            raise FrozenInputError(f"frozen source changed: {path}")
    if len(tasks) != 10:
        raise FrozenInputError("run manifest must bind exactly 10 tasks")
    for base in source["theorem_bases"]:
        if tree_digest(project / base["model_dir"]) != base["tree_sha256"]:
            raise FrozenInputError(f"frozen theorem base changed: {base['dut']}")


def theorem_base_for(source: dict[str, Any], dut: str) -> dict[str, Any]:
    return next(row for row in source["theorem_bases"] if row["dut"] == dut)
