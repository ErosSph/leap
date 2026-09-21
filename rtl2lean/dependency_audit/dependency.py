"""Lean-kernel proof-term dependency extraction for dependency_audit."""
from __future__ import annotations

import hashlib
import json
import os
import re
import subprocess
import time
from pathlib import Path
from typing import Any

from rtl2lean.pipeline.compiler import find_lean
from rtl2lean.pipeline.io import write_json
from rtl2lean.pipeline.manifest import Benchmark


TACTICS = (
    "exact", "apply", "rw", "simp", "simpa", "simp_all", "have", "show",
    "constructor", "refine", "induction", "cases", "rcases", "calc", "unfold",
)

META_COMMAND = r'''import R5Foundation
import Lean

set_option maxRecDepth 100000
set_option maxHeartbeats 8000000
set_option maxErrors 1000
set_option trace.Meta.Tactic.simp.rewrite true

open Lean Elab Command

syntax (name := r9deps) "#r9deps " ident : command
syntax (name := r9mark) "#r9mark " ident : command

elab_rules : command
  | `(#r9deps $id:ident) => do
      let name ← resolveGlobalConstNoOverload id
      let env ← getEnv
      let some ci := env.find? name
        | throwError "R9 missing declaration {name}"
      let deps := match ci with
        | .defnInfo value => value.value.getUsedConstants
        | .thmInfo value => value.value.getUsedConstants
        | .opaqueInfo value => value.value.getUsedConstants
        | _ => #[]
      logInfo m!"R9DEPS|{name}|{String.intercalate "," (deps.toList.map Name.toString)}"

elab_rules : command
  | `(#r9mark $id:ident) => logInfo m!"R9MARK|{id.getId}"
'''


def _read(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def _safe(value: str) -> str:
    return re.sub(r"[^A-Za-z0-9_]", "_", value)


def _full_theorem_name(benchmark: Benchmark, name: str) -> str:
    if "." in name and name.startswith(("R3Temporal.", "List.", "BitVec.")):
        return name
    return f"{benchmark.top_module}Verification.{name}"


def _tactic_mechanisms(proof: str) -> list[str]:
    return [name for name in TACTICS if re.search(rf"\b{re.escape(name)}\b", proof)]


def _explicit_identifiers(proof: str) -> set[str]:
    # Comments and string literals do not occur in the frozen generated proofs.
    return set(re.findall(r"\b[A-Za-z_][A-Za-z0-9_'.]*(?:\.[A-Za-z_][A-Za-z0-9_']*)*\b", proof))


def _proof_block(
    benchmark: Benchmark, row: dict[str, Any], arm: str, index: int,
) -> tuple[str, str, dict[str, str], dict[str, str]]:
    namespace = f"R9{arm.title().replace('_', '')}_T{row['trial']:02d}_{index:02d}"
    root = f"{benchmark.top_module}Verification.{namespace}.target"
    lines = [
        f"namespace {benchmark.top_module}Verification",
        f"open {benchmark.top_module}",
        f"namespace {namespace}",
    ]
    generated: dict[str, str] = {}
    marks: dict[str, str] = {}
    if arm == "lemma_first":
        for lemma_index, lemma in enumerate(row.get("intermediate_lemmas", [])):
            name = lemma["name"]
            statement = lemma.get("proposition") or lemma.get("statement")
            proof = lemma.get("proof_body") or lemma.get("proof")
            full = f"{benchmark.top_module}Verification.{namespace}.{name}"
            mark = f"{namespace}__lemma_{lemma_index:02d}_{_safe(name)}"
            lines.extend([f"#r9mark {mark}", f"theorem {name} : {statement} := {proof}", f"#r9deps {name}"])
            generated[name] = full
            marks[full] = mark
    root_mark = f"{namespace}__target"
    lines.extend([
        f"#r9mark {root_mark}",
        f"theorem target : {row['theorem_statement']} := {row['final_proof']}",
        "#r9deps target", "end " + namespace,
        f"end {benchmark.top_module}Verification", "",
    ])
    marks[root] = root_mark
    return "\n\n".join(lines), root, generated, marks


def _parse_dependency_output(output: str) -> dict[str, list[str]]:
    result: dict[str, list[str]] = {}
    for line in output.splitlines():
        if not line.startswith("R9DEPS|"):
            continue
        _, name, encoded = line.split("|", 2)
        result[name] = [item for item in encoded.split(",") if item]
    return result


def _parse_simp_rewrite_output(output: str) -> dict[str, list[str]]:
    result: dict[str, list[str]] = {}
    current: str | None = None
    for line in output.splitlines():
        if line.startswith("R9MARK|"):
            current = line.split("|", 1)[1]
            result.setdefault(current, [])
            continue
        if current is None or not line.startswith("[Meta.Tactic.simp.rewrite]"):
            continue
        body = line.split("]", 1)[1].strip()
        match = re.match(r"unfold\s+([A-Za-z_][A-Za-z0-9_'.]*)", body)
        if not match:
            match = re.match(r"([A-Za-z_][A-Za-z0-9_'.]*):\d+:", body)
        if match and match.group(1) not in result[current]:
            result[current].append(match.group(1))
    return result


def _layer(name: str, inventory: dict[str, dict[str, Any]]) -> str:
    if name in inventory:
        return inventory[name]["layer"]
    if name.startswith("R3Temporal."):
        return "R3TEMPORAL"
    if re.search(r"(^|\.)l1_", name):
        return "L1"
    if re.search(r"(^|\.)l2_", name):
        return "L2"
    if re.search(r"(^|\.)(r3|r3seed)_", name):
        return "L3"
    if re.search(r"(^|\.)r4_", name):
        return "L4"
    return "PRIMITIVE_DEFINITION"


def _expand(
    root: str, dependency_index: dict[str, list[str]],
    inventory: dict[str, dict[str, Any]], generated: set[str],
) -> dict[str, Any]:
    nodes: dict[str, dict[str, Any]] = {}
    edges: list[dict[str, Any]] = []
    expanded: set[str] = set()
    active: set[str] = set()
    cycles: list[list[str]] = []
    max_depth = 0

    def visit(name: str, depth: int, trail: list[str]) -> None:
        nonlocal max_depth
        max_depth = max(max_depth, depth)
        expandable = name in dependency_index and (name == root or name in inventory or name in generated)
        nodes.setdefault(name, {
            "id": name,
            "layer": "LOCAL_GENERATED_LEMMA" if name in generated else _layer(name, inventory),
            "terminal": not expandable,
            "source_file": inventory.get(name, {}).get("source_file"),
            "statement": inventory.get(name, {}).get("statement"),
        })
        if not expandable or name in expanded:
            return
        if name in active:
            cycles.append([*trail, name])
            return
        active.add(name)
        for dep in dependency_index.get(name, []):
            edges.append({"source": name, "target": dep, "depth": depth + 1})
            visit(dep, depth + 1, [*trail, name])
        active.remove(name)
        expanded.add(name)

    visit(root, 0, [])
    leaves = sorted(name for name, node in nodes.items() if node["terminal"])
    return {
        "root": root,
        "nodes": sorted(nodes.values(), key=lambda row: row["id"]),
        "edges": edges,
        "max_depth": max_depth,
        "primitive_leaves": leaves,
        "primitive_dependency_count": len(leaves),
        "theorem_dependency_count": sum(node["layer"] != "PRIMITIVE_DEFINITION" for node in nodes.values()),
        "cycles": cycles,
        "fully_expanded_to_declared_foundation_or_primitive": not cycles,
    }


def extract_dependencies(
    benchmarks: list[Benchmark], output_root: Path, requirement_root: Path,
) -> tuple[dict[str, Any], dict[str, Any], dict[str, Any]]:
    """Re-elaborate frozen proofs and recursively expand their actual proof terms."""
    graph = _read(output_root / "multi_phase_proofs" / "proof_graph" / "theorem_dependency_graph.json")
    direct_payload = _read(output_root / "multi_phase_proofs" / "direct" / "trials.json")
    lemma_payload = _read(output_root / "multi_phase_proofs" / "lemma_first" / "trials.json")
    direct_live = [row for row in direct_payload["trial_results"]
                   if row.get("evidence_source") == "multi_phase_proofs_LIVE_TRIAL"]
    lemma_live = [row for row in lemma_payload["trial_results"]
                  if row.get("evidence_source") == "multi_phase_proofs_LIVE_TRIAL"]
    benchmark_map = {row.design_id: row for row in benchmarks}
    direct_by_dut: dict[str, list[dict[str, Any]]] = {}
    lemma_by_dut: dict[str, list[dict[str, Any]]] = {}
    for row in direct_live:
        direct_by_dut.setdefault(row["dut"], []).append(row)
    for row in lemma_live:
        lemma_by_dut.setdefault(row["dut"], []).append(row)

    inventory_by_dut: dict[str, dict[str, dict[str, Any]]] = {}
    for node in graph["nodes"]:
        if node["kind"] != "THEOREM":
            continue
        benchmark = benchmark_map[node["dut"]]
        full = _full_theorem_name(benchmark, node["name"])
        inventory_by_dut.setdefault(node["dut"], {})[full] = {
            "name": node["name"], "layer": node["layer"],
            "statement": node["statement"], "source_file": node["source_file"],
        }

    direct_rows: list[dict[str, Any]] = []
    lemma_rows: list[dict[str, Any]] = []
    expansion_rows: list[dict[str, Any]] = []
    audit_root = requirement_root / "dependency" / "kernel_audit"
    for dut in sorted(direct_by_dut):
        benchmark = benchmark_map[dut]
        inventory = inventory_by_dut[dut]
        direct_selected = sorted(direct_by_dut[dut], key=lambda row: (row["trial"], row["property_id"]))
        lemma_selected = sorted(lemma_by_dut[dut], key=lambda row: (row["trial"], row["property_id"]))
        blocks = [META_COMMAND]
        roots: list[tuple[str, dict[str, Any], str, dict[str, str], dict[str, str]]] = []
        for arm, rows in (("direct", direct_selected), ("lemma_first", lemma_selected)):
            for index, row in enumerate(rows):
                block, root, generated, marks = _proof_block(benchmark, row, arm, index)
                blocks.append(block)
                roots.append((arm, row, root, generated, marks))
        for name in sorted(inventory):
            blocks.append(f"#r9deps {name}")
        source = audit_root / benchmark.slug / "proof_term_dependencies.lean"
        source.parent.mkdir(parents=True, exist_ok=True)
        source.write_text("\n\n".join(blocks) + "\n", encoding="utf-8")
        env = os.environ.copy()
        model_root = output_root / benchmark.slug / "model"
        env["LEAN_PATH"] = str(model_root) + (":" + env["LEAN_PATH"] if env.get("LEAN_PATH") else "")
        started = time.perf_counter()
        proc = subprocess.run(
            [find_lean(), "-s", "65536", str(source)], cwd=str(requirement_root.parents[1]),
            env=env, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=1200,
            check=False,
        )
        elapsed = time.perf_counter() - started
        combined = proc.stdout + proc.stderr
        check = {
            "command": [find_lean(), "-s", "65536", str(source)],
            "returncode": proc.returncode, "stdout": proc.stdout, "stderr": proc.stderr,
            "elapsed_s": elapsed, "success": proc.returncode == 0,
        }
        write_json(source.with_suffix(".result.json"), check)
        if proc.returncode != 0:
            raise RuntimeError(f"dependency_audit proof-term audit failed for {dut}: {combined[-8000:]}")
        dependency_index = _parse_dependency_output(combined)
        simp_rewrites = _parse_simp_rewrite_output(combined)
        missing_inventory = sorted(set(inventory) - set(dependency_index))
        if missing_inventory:
            raise RuntimeError(f"dependency_audit could not inspect {dut} declarations: {missing_inventory[:10]}")
        for arm, row, root, generated_map, marks in roots:
            if root not in dependency_index:
                raise RuntimeError(f"dependency_audit missing generated root {root}")
            generated_names = set(generated_map.values())
            expansion = _expand(root, dependency_index, inventory, generated_names)
            proof = row.get("final_proof") or ""
            explicit = _explicit_identifiers(proof)
            first = dependency_index[root]
            inferred = sorted(dep for dep in first if dep.rsplit(".", 1)[-1] not in explicit and dep not in explicit)
            record = {
                "arm": arm.upper(), "dut": dut, "property_id": row["property_id"],
                "trial": row["trial"], "root": root,
                "statement_sha256": row["statement_sha256"],
                "proof_sha256": hashlib.sha256(proof.encode()).hexdigest(),
                "kernel_reelaboration_pass": True,
                "first_level_dependencies": first,
                "first_level_theorem_dependencies": [dep for dep in first if dep in inventory],
                "first_level_primitive_dependencies": [dep for dep in first if dep not in inventory],
                "tactic_mechanisms": _tactic_mechanisms(proof),
                "explicit_identifiers": sorted(explicit),
                "proof_term_inferred_dependencies": inferred,
                "simp_actual_dependency_candidates": inferred
                    if re.search(r"\bsimp(?:a|_all)?\b", proof) else [],
                "simp_actual_rewrite_lemmas": simp_rewrites.get(marks[root], []),
                "simp_trace_enabled": True,
                "generated_lemma_declarations": generated_map,
                "audit_source": str(source),
            }
            if arm == "direct":
                direct_rows.append(record)
            else:
                record["intermediate_lemma_dependencies"] = {
                    short: dependency_index.get(full, []) for short, full in generated_map.items()
                }
                record["intermediate_lemma_simp_rewrites"] = {
                    short: simp_rewrites.get(marks[full], []) for short, full in generated_map.items()
                }
                lemma_rows.append(record)
            expansion_rows.append({
                "arm": arm.upper(), "dut": dut, "property_id": row["property_id"],
                "trial": row["trial"], **expansion,
            })

    direct_result = {"schema": "rtl2lean-dependency_audit-direct-dependencies-v1", "rows": direct_rows}
    lemma_result = {"schema": "rtl2lean-dependency_audit-lemma-dependencies-v1", "rows": lemma_rows}
    expansions = {"schema": "rtl2lean-dependency_audit-recursive-expansion-v1", "rows": expansion_rows}
    dependency_root = requirement_root / "dependency"
    write_json(dependency_root / "direct_dependencies.json", direct_result)
    write_json(dependency_root / "lemma_first_dependencies.json", lemma_result)
    write_json(dependency_root / "recursive_expansion.json", expansions)
    write_json(dependency_root / "expanded_dependency_graph.json", expansions)
    return direct_result, lemma_result, expansions
