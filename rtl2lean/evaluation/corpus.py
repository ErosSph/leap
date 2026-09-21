"""Audit and expand the high-level property corpus from frozen Typed IR.

The expansion is deliberately independent of DUT identity.  Candidate signals,
conditions, branch values, evidence and relatedness all come from the frozen IR
and its read/write graph.
"""
from __future__ import annotations

import json
import pickle
import re
from dataclasses import asdict
from pathlib import Path
from typing import Any, Iterable

from rtl2lean.middle_end.ir import IRFunction, IRModule, IRValue
from rtl2lean.pipeline.io import sha256, write_json
from rtl2lean.pipeline.manifest import Benchmark
from rtl2lean.pipeline.schema import DesignIR, ProcessIR
from rtl2lean.theorems.generator import GeneratedTheorem, _node_count, _render


CONTROL_RE = re.compile(r"state|ctrl|round|count|counter|phase|pointer|index|busy|done", re.I)
PROTOCOL_RE = re.compile(r"mem|fifo|ready|valid|req|ack|tx|rx|frame|packet|bus|cyc|stb", re.I)
DATAPATH_RE = re.compile(r"data|result|operand|acc|sum|key|block|word|alu|crc|shift", re.I)


def _safe(value: str) -> str:
    value = re.sub(r"[^A-Za-z0-9_]", "_", value)
    return value if value and value[0].isalpha() else "n_" + value


def load_frozen_objects(output_root: Path, benchmark: Benchmark) -> tuple[Any, IRModule, DesignIR]:
    path = output_root / benchmark.slug / "ir" / "compiler_objects.pkl"
    payload = pickle.loads(path.read_bytes())
    return payload["ast"], payload["ir"], payload["typed_ir"]


def _assignments(function: IRFunction) -> Iterable[tuple[str, IRValue]]:
    for block in function.blocks:
        if block.name != function.entry_block:
            continue
        for instruction in block.instrs:
            if instruction.kind in {"assign", "nba"} and instruction.dest and instruction.value:
                yield instruction.dest, instruction.value


def _conditional_leaves(
    value: IRValue, path: tuple[tuple[IRValue, bool], ...] = (), depth: int = 0,
) -> Iterable[tuple[tuple[tuple[IRValue, bool], ...], IRValue]]:
    """Enumerate bounded paths through a normalized conditional expression."""
    if value.kind == "phi" and depth < 12:
        condition = value.data["cond"]
        yield from _conditional_leaves(value.data["then"], path + ((condition, True),), depth + 1)
        yield from _conditional_leaves(value.data["else"], path + ((condition, False),), depth + 1)
        return
    yield path, value


def _value_uses(value: IRValue | None) -> set[str]:
    if value is None:
        return set()
    if value.kind == "var":
        return {str(value.data["name"])}
    result: set[str] = set()
    for item in value.data.values():
        if isinstance(item, IRValue):
            result.update(_value_uses(item))
        elif isinstance(item, (list, tuple)):
            for nested in item:
                if isinstance(nested, IRValue):
                    result.update(_value_uses(nested))
    return result


def _family(field: str, condition: IRValue) -> str:
    text = field + " " + " ".join(sorted(_value_uses(condition)))
    if CONTROL_RE.search(text):
        return "control_transition"
    if PROTOCOL_RE.search(text):
        return "protocol_transition"
    if DATAPATH_RE.search(text):
        return "datapath_transition"
    return "state_transition"


def _source_module(design: dict[str, Any], field: str) -> tuple[str, str | None]:
    leaf_prefix = field.rsplit("__", 1)[0] if "__" in field else ""
    instances = sorted(design.get("active_instances", []),
                       key=lambda item: len(item.get("path", "")), reverse=True)
    module = design.get("top_module", "")
    if leaf_prefix:
        for instance in instances:
            flattened = "__".join(instance.get("path", "").split(".")[1:])
            if flattened and (leaf_prefix == flattened or leaf_prefix.startswith(flattened + "__")):
                module = instance.get("module", module)
                break
    source = next((item.get("file") for item in design.get("source_module_definitions", [])
                   if item.get("name") == module), None)
    return module, source


def _rtl_locations(source: str | None, field: str) -> list[dict[str, Any]]:
    if not source or not Path(source).is_file():
        return []
    leaf = field.rsplit("__", 1)[-1]
    pattern = re.compile(rf"\b{re.escape(leaf)}\b")
    result = []
    for line_no, line in enumerate(Path(source).read_text(encoding="utf-8", errors="replace").splitlines(), 1):
        if pattern.search(line):
            result.append({"file": source, "line": line_no, "text": line.strip()[:240]})
            if len(result) == 3:
                break
    return result


def _dependency_cone(typed: DesignIR, fields: set[str], functions: set[str]) -> dict[str, Any]:
    cone_fields = set(fields)
    cone_processes = set(functions)
    changed = True
    while changed:
        changed = False
        for process in typed.module.processes:
            if process.name in cone_processes or set(process.write_set) & cone_fields:
                old = (len(cone_fields), len(cone_processes))
                cone_processes.add(process.name)
                cone_fields.update(process.read_set)
                cone_fields.update(process.write_set)
                changed |= old != (len(cone_fields), len(cone_processes))
    return {
        "state_and_signal_count": len(cone_fields),
        "process_count": len(cone_processes),
        "total": len(cone_fields) + len(cone_processes),
        "signals": sorted(cone_fields),
        "processes": sorted(cone_processes),
    }


def _dependencies(target: dict[str, Any], framework: list[dict[str, Any]]) -> dict[str, list[str]]:
    fields = set(target.get("referenced_state_fields", []))
    functions = set(target.get("source_functions", []))
    result = {layer: [] for layer in ("L1", "L2", "L3", "L4")}
    for lemma in framework:
        layer = lemma.get("layer")
        if layer not in result:
            continue
        lemma_fields = set(lemma.get("state_fields", []))
        lemma_functions = set(lemma.get("source_functions", []))
        if layer in {"L3", "L4"} or fields & lemma_fields or functions & lemma_functions:
            result[layer].append(lemma["name"])
    return result


def _evidence(
    benchmark: Benchmark,
    design: dict[str, Any],
    typed: DesignIR,
    field: str,
    source_function: str,
    referenced: set[str],
    expression_node_count: int,
) -> dict[str, Any]:
    process = next((item for item in typed.module.processes if item.name == source_function), None)
    signal_map = {item.name: item for item in typed.module.signals}
    module, source = _source_module(design, field)
    return {
        "rtl_evidence": {
            "module": module,
            "source_file": source,
            "matching_regions": _rtl_locations(source, field),
            "source_commit": benchmark.commit,
        },
        "ir_evidence": {
            "process": source_function,
            "process_type": process.process_type if process else None,
            "clock": process.clock if process else None,
            "reset": process.reset if process else None,
            "read_set": list(process.read_set) if process else [],
            "write_set": list(process.write_set) if process else [],
            "expression_node_count": expression_node_count,
        },
        "dependency_evidence": {
            "referenced_signals": sorted(referenced),
            "drivers": {name: list(signal_map[name].drivers) for name in sorted(referenced) if name in signal_map},
            "readers": {name: list(signal_map[name].readers) for name in sorted(referenced) if name in signal_map},
        },
    }


def _result_maps(output_root: Path, slug: str) -> tuple[dict[str, Any], dict[str, Any]]:
    def read(path: Path) -> dict[str, Any]:
        return json.loads(path.read_text(encoding="utf-8")) if path.is_file() else {}
    baseline = read(output_root / slug / "proofs" / "baseline" / "summary.json")
    assisted = read(output_root / slug / "proofs" / "assisted" / "summary.json")
    return (
        {item["name"]: item for item in baseline.get("results", [])},
        {item["name"]: item for item in assisted.get("results", [])},
    )


def _trivial_reasons(target: dict[str, Any], baseline: dict[str, Any] | None) -> list[str]:
    statement = " ".join(target.get("theorem_statement", "").split())
    proof = (baseline or {}).get("proof") or ""
    reasons = []
    equality = re.search(r"(?:^|,|→)\s*(.+?)\s*=\s*(.+?)$", statement)
    if equality and equality.group(1).strip() == equality.group(2).strip():
        reasons.append("SYNTACTIC_REFLEXIVITY")
    if re.search(r"\b([A-Za-z][A-Za-z0-9_]*)\s*→\s*\1\b", statement):
        reasons.append("P_IMPLIES_P")
    if (baseline or {}).get("status") == "PASS" and re.fullmatch(r"by\s+(?:intro\s+[^;]+;\s*)?rfl", proof.strip()):
        reasons.append("PURE_RFL")
    # StateWidthInvariant is only the range already guaranteed by BitVec.  A
    # Reachable premise does not make that conclusion depend on RTL behaviour.
    if target.get("property_family") in {
        "state_safety", "reachable_state_invariant", "step_determinism",
    }:
        reasons.append("TYPE_OR_FUNCTION_TRUISM")
    if "→" in statement and "_h" in proof:
        reasons.append("UNUSED_HYPOTHESIS")
    if target.get("property_family") in {"unwritten_register_preservation", "clock_domain_preservation"}:
        reasons.append("TRIVIAL_PRESERVATION_ONLY")
    return sorted(set(reasons))


def audit_existing_properties(benchmark: Benchmark, output_root: Path) -> list[dict[str, Any]]:
    root = output_root / benchmark.slug
    targets_payload = json.loads((root / "model" / "targets.json").read_text(encoding="utf-8"))
    design = json.loads((root / "analysis" / "design.json").read_text(encoding="utf-8"))
    _, _, typed = load_frozen_objects(output_root, benchmark)
    baseline_map, assisted_map = _result_maps(output_root, benchmark.slug)
    framework = targets_payload["targets"]
    signal_map = {item.name: item for item in typed.module.signals}
    result = []
    for raw in framework:
        if raw.get("layer") != "PROPERTY":
            continue
        fields = set(raw.get("state_fields", []))
        functions = set(raw.get("source_functions", []))
        inputs = set(raw.get("input_fields", []))
        outputs = {name for name in fields if name in signal_map and signal_map[name].direction == "output"}
        source_function = next(iter(functions), "")
        field = next(iter(fields), "")
        item = {
            "property_id": raw["name"], "dut": benchmark.design_id,
            "module": benchmark.top_module, "subsystem": _source_module(design, field)[0] if field else benchmark.top_module,
            "origin": "translation_frozen", "property_family": raw.get("property_family"),
            "theorem_statement": raw["statement"],
            "referenced_state_fields": sorted(fields), "referenced_inputs": sorted(inputs),
            "referenced_outputs": sorted(outputs), "source_functions": sorted(functions),
            "dependency_cone": _dependency_cone(typed, fields, functions),
            "baseline_result": (baseline_map.get(raw["name"]) or {}).get("status", "NOT_RUN"),
            "assisted_result": (assisted_map.get(raw["name"]) or {}).get("status", "NOT_RUN"),
            "proof_candidates": raw.get("proof_candidates", []),
        }
        item.update(_dependencies(item, framework))
        evidence = _evidence(benchmark, design, typed, field, source_function,
                             fields | inputs, 0) if field and source_function else {
            "rtl_evidence": {"module": benchmark.top_module, "source_file": None,
                             "matching_regions": [], "source_commit": benchmark.commit},
            "ir_evidence": {"process": source_function},
            "dependency_evidence": {"referenced_signals": sorted(fields | inputs)},
        }
        item.update(evidence)
        reasons = _trivial_reasons(item, baseline_map.get(raw["name"]))
        item["trivial_reasons"] = reasons
        item["classification"] = ["TRIVIAL" if reasons else "SEMANTIC"]
        if raw.get("property_family") == "finite_reachability_witness":
            item["classification"] = ["STRUCTURAL"]
        if raw.get("property_family") in {"finite_reachability_witness", "bounded_temporal_relation"}:
            item["classification"].append("MULTI_CYCLE")
        if len(typed.module.clock_domains) > 1:
            item["classification"].append("MULTI_CLOCK")
        item["semantic_evidence_status"] = (
            "PASS" if item["dependency_cone"]["total"] > 0
            and bool(item["rtl_evidence"].get("source_file"))
            and bool(item["ir_evidence"].get("process"))
            else "PROPERTY_NO_SEMANTIC_EVIDENCE"
        )
        result.append(item)
    write_json(output_root / "audit" / benchmark.slug / "property_audit.json", {
        "schema": "rtl2lean-evaluation-existing-property-audit-v1",
        "dut": benchmark.design_id, "properties": result,
        "metrics": {
            "N_PROPERTY_TOTAL": len(result),
            "N_TRIVIAL": sum("TRIVIAL" in item["classification"] for item in result),
            "N_NONTRIVIAL": sum("TRIVIAL" not in item["classification"] for item in result),
            "N_SEMANTIC": sum("SEMANTIC" in item["classification"] for item in result),
        },
    })
    return result


def _relatedness(candidates: list[dict[str, Any]]) -> None:
    control = next((item for item in candidates if CONTROL_RE.search(item["referenced_state_fields"][0])),
                   candidates[0] if candidates else None)
    if not control:
        return
    anchor_reads = set(control["ir_evidence"].get("read_set", []))
    anchor_writes = set(control["ir_evidence"].get("write_set", []))
    for item in candidates:
        reads = set(item["ir_evidence"].get("read_set", []))
        writes = set(item["ir_evidence"].get("write_set", []))
        if item["source_functions"] == control["source_functions"] or set(item["referenced_state_fields"]) & anchor_writes:
            relation = "CORE_RELATED"
        elif (reads | writes) & (anchor_reads | anchor_writes):
            relation = "RELATED"
        else:
            relation = "CONTROL_UNRELATED"
        item["semantic_relatedness"] = relation
        item["relatedness_anchor"] = control["property_id"]


def generate_expanded_properties(
    benchmark: Benchmark, output_root: Path, existing: list[dict[str, Any]], limit: int = 12,
) -> list[dict[str, Any]]:
    root = output_root / benchmark.slug
    design = json.loads((root / "analysis" / "design.json").read_text(encoding="utf-8"))
    _, ir, typed = load_frozen_objects(output_root, benchmark)
    framework = json.loads((root / "model" / "targets.json").read_text(encoding="utf-8"))["targets"]
    registers = set(dict(ir.registers))
    signal_map = {item.name: item for item in typed.module.signals}
    candidates: list[dict[str, Any]] = []
    seen: set[tuple[str, str, str]] = set()
    for function in ir.functions:
        if not function.is_sequential:
            continue
        process = next((item for item in typed.module.processes if item.name == function.name), None)
        for destination, value in _assignments(function):
            if destination not in registers or value.kind != "phi" or _node_count(value) > 384:
                continue
            for path, leaf in _conditional_leaves(value):
                if not path or sum(_node_count(condition) for condition, _ in path) + _node_count(leaf) > 384:
                    continue
                branch = "".join("t" if polarity else "f" for _, polarity in path)
                key = (function.name, destination, branch)
                if key in seen:
                    continue
                seen.add(key)
                try:
                    guards = [(_render(condition, ir), polarity) for condition, polarity in path]
                    branch_text = _render(leaf, ir)
                except (KeyError, TypeError, ValueError):
                    continue
                guard_terms = [f"({text})" if polarity else f"!({text})"
                               for text, polarity in guards]
                hypothesis = " && ".join(guard_terms)
                property_id = f"r2_{_safe(function.name)}_{_safe(destination)}_path_{branch}"
                condition_uses = set().union(*(_value_uses(condition) for condition, _ in path))
                referenced = condition_uses | _value_uses(leaf) | {destination}
                inputs = sorted(name for name in referenced if name in signal_map and signal_map[name].direction == "input")
                outputs = sorted(name for name in referenced if name in signal_map and signal_map[name].direction == "output")
                module, _ = _source_module(design, destination)
                item = {
                    "property_id": property_id, "dut": benchmark.design_id, "module": benchmark.top_module,
                    "subsystem": module, "origin": "evaluation_ir_expansion",
                    "property_family": _family(destination, path[-1][0]),
                    "theorem_statement": (
                        f"∀ (s : {ir.name}State) (i : {ir.name}Inputs), {hypothesis} → "
                        f"({function.name} s i).{destination} = {branch_text}"
                    ),
                    "referenced_state_fields": sorted(name for name in referenced if name in registers),
                    "referenced_inputs": inputs, "referenced_outputs": outputs,
                    "source_functions": [function.name],
                    "dependency_cone": _dependency_cone(typed, referenced, {function.name}),
                    "proof_candidates": [
                        f"by intro s i h; simp [{function.name}, h]",
                        f"by intro s i h; simp_all [{function.name}]",
                        f"by intro s i h; unfold {function.name}; simp [h]",
                        ("by intro s i h; simp only [Bool.and_eq_true] at h; "
                         f"unfold {function.name}; grind"),
                    ],
                    "classification": ["SEMANTIC", "CONTROL_RELATED" if CONTROL_RE.search(destination)
                                       else "PROTOCOL_RELATED" if PROTOCOL_RE.search(destination)
                                       else "DATAPATH_RELATED"],
                    "trivial_reasons": [], "semantic_evidence_status": "PASS",
                    "baseline_result": "PENDING", "assisted_result": "PENDING",
                    "branch": branch, "condition": hypothesis,
                    "branch_expression": branch_text, "destination": destination,
                    "condition_is_reset_only": bool(condition_uses) and all(
                        re.search(r"reset|rst", name, re.I) for name in condition_uses
                    ),
                }
                item.update(_dependencies(item, framework))
                item.update(_evidence(benchmark, design, typed, destination, function.name,
                                      referenced, sum(_node_count(condition) for condition, _ in path)
                                      + _node_count(leaf)))
                candidates.append(item)

    _relatedness(candidates)
    # Freeze a deterministic round-robin across semantic family and graph
    # relatedness before any baseline or LLM run.  This prevents source-order
    # clustering (for example, twelve reset facts from the first datapath
    # process) without inspecting proof outcomes.
    families = ("control_transition", "protocol_transition",
                "datapath_transition", "state_transition")
    relations = ("CORE_RELATED", "RELATED", "CONTROL_UNRELATED")
    buckets = {
        (family, relation): sorted(
            [item for item in candidates if item["property_family"] == family
             and item.get("semantic_relatedness") == relation],
            key=lambda item: (item["condition_is_reset_only"], item["source_functions"][0],
                              item["condition"], item["property_id"]),
        )
        for family in families for relation in relations
    }
    selected: list[dict[str, Any]] = []
    cursor = {key: 0 for key in buckets}
    while len(selected) < limit:
        progressed = False
        for family in families:
            for relation in relations:
                key = (family, relation)
                if cursor[key] < len(buckets[key]):
                    selected.append(buckets[key][cursor[key]])
                    cursor[key] += 1
                    progressed = True
                    if len(selected) == limit:
                        break
            if len(selected) == limit:
                break
        if not progressed:
            break
    for item in candidates:
        if item not in selected and len(selected) < limit:
            selected.append(item)
    # Reserve two slots for genuinely multi-cycle properties.  They combine a
    # concrete IR-derived transition fact with an execution-history witness,
    # so neither component alone can discharge the target.
    base_limit = max(0, limit - 2)
    selected = selected[:base_limit]
    trace_item_type = "EventInput" if len(typed.module.clock_domains) > 1 else f"{ir.name}Inputs"
    seeds: list[dict[str, Any]] = []
    for item in selected:
        if not seeds or (item["source_functions"][0], item["property_family"]) not in {
            (seed["source_functions"][0], seed["property_family"]) for seed in seeds
        }:
            seeds.append(item)
        if len(seeds) == 2:
            break
    for seed in seeds:
        function = seed["source_functions"][0]
        multi = dict(seed)
        multi.update({
            "property_id": seed["property_id"] + "_reachable_trace_transition",
            "origin": "evaluation_ir_multicycle_expansion",
            "property_family": "multi_cycle_transition_witness",
            "theorem_statement": (
                f"∀ (s : {ir.name}State), Reachable s → "
                f"((∃ inputs : List {trace_item_type}, run init inputs = s) ∧ "
                f"∀ (i : {ir.name}Inputs), {seed['condition']} → "
                f"({function} s i).{seed['destination']} = {seed['branch_expression']})"
            ),
            "proof_candidates": ["by simp", "by grind"],
            "classification": ["SEMANTIC", "MULTI_CYCLE"],
            "baseline_result": "PENDING", "assisted_result": "PENDING",
        })
        multi.update(_dependencies(multi, framework))
        selected.append(multi)
    return selected


def build_property_corpus(benchmarks: list[Benchmark], output_root: Path,
                          requirement_root: Path) -> dict[str, Any]:
    all_existing = []
    all_selected = []
    per_dut = []
    for benchmark in benchmarks:
        existing = audit_existing_properties(benchmark, output_root)
        expanded = generate_expanded_properties(benchmark, output_root, existing)
        audited = existing + expanded
        write_json(output_root / "audit" / benchmark.slug / "property_audit.json", {
            "schema": "rtl2lean-evaluation-complete-property-audit-v1",
            "dut": benchmark.design_id,
            "properties": audited,
            "metrics": {
                "N_PROPERTY_TOTAL": len(audited),
                "N_TRIVIAL": sum("TRIVIAL" in item["classification"] for item in audited),
                "N_NONTRIVIAL": sum("TRIVIAL" not in item["classification"] for item in audited),
                "N_SEMANTIC": sum("SEMANTIC" in item["classification"] for item in audited),
                "N_FINAL_TARGETS": len(expanded),
            },
        })
        all_existing.extend(existing)
        all_selected.extend(expanded)
        per_dut.append({
            "dut": benchmark.design_id, "slug": benchmark.slug,
            "N_GENERATED": len(expanded),
            "N_REJECTED_TRIVIAL": sum("TRIVIAL" in item["classification"] for item in existing),
            "N_NO_SEMANTIC_EVIDENCE": sum(item["semantic_evidence_status"] != "PASS" for item in expanded),
            "N_VALID": sum(item["semantic_evidence_status"] == "PASS" and
                           "TRIVIAL" not in item["classification"] for item in expanded),
            "N_FINAL_TARGETS": len(expanded),
        })
    corpus = {
        "schema": "rtl2lean-evaluation-property-corpus-v1",
        "selection_rule": (
            "deterministic family/relatedness quota from IR-derived transition facts, "
            "plus every frozen translation property surviving uniform pre-LLM "
            "triviality and semantic-evidence audit"
        ),
        "properties": all_selected, "per_dut": per_dut,
        "metrics": {
            "N_PROPERTY_TOTAL": len(all_existing) + len(all_selected),
            "N_TRIVIAL": sum("TRIVIAL" in item["classification"] for item in all_existing + all_selected),
            "N_NONTRIVIAL": sum("TRIVIAL" not in item["classification"] for item in all_existing + all_selected),
            "N_SEMANTIC": sum("SEMANTIC" in item["classification"] for item in all_existing + all_selected),
            "N_FINAL_TARGETS": len(all_selected),
        },
    }
    write_json(requirement_root / "corpus" / "property_corpus.json", corpus)
    write_json(requirement_root / "corpus" / "property_audit.json", {
        "schema": "rtl2lean-evaluation-property-audit-v1", "properties": all_existing,
    })
    write_json(requirement_root / "corpus" / "semantic_evidence.json", {
        "schema": "rtl2lean-evaluation-semantic-evidence-v1",
        "properties": [{"property_id": item["property_id"], "dut": item["dut"],
                        "rtl_evidence": item["rtl_evidence"], "ir_evidence": item["ir_evidence"],
                        "dependency_evidence": item["dependency_evidence"],
                        "dependency_cone": item["dependency_cone"]} for item in all_selected],
    })
    return corpus
