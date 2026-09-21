"""Build multi_phase_proofs controls, false-gap audits, and bottleneck candidates."""
from __future__ import annotations

import hashlib
import itertools
import json
import re
from pathlib import Path
from typing import Any

from rtl2lean.pipeline.io import write_json
from rtl2lean.pipeline.manifest import Benchmark
from rtl2lean.compositional_proofs.corpus import select_phase_seeds
from rtl2lean.temporal.corpus import _expected_at


def _read(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def _safe(value: str) -> str:
    return re.sub(r"[^A-Za-z0-9_]", "_", value)


def _bridge_evidence(seeds: tuple[dict[str, Any], ...] | list[dict[str, Any]]) -> dict[str, Any]:
    reads = [set((seed.get("ir_evidence") or {}).get("read_set", [])) for seed in seeds]
    dependency_links = 0
    shared_read_links = 0
    shared_process_links = 0
    for left, right in itertools.combinations(range(len(seeds)), 2):
        dependency_links += int(seeds[left]["destination"] in reads[right])
        dependency_links += int(seeds[right]["destination"] in reads[left])
        shared_read_links += int(bool(reads[left] & reads[right]))
        shared_process_links += int(
            seeds[left].get("source_function") == seeds[right].get("source_function")
        )
    control_fields = sum(bool(re.search(
        r"state|round|count|counter|ctr|ready|done|busy|ack|valid",
        seed["destination"], re.I,
    )) for seed in seeds)
    return {
        "dependency_links": dependency_links,
        "shared_read_links": shared_read_links,
        "shared_process_links": shared_process_links,
        "control_fields": control_fields,
        "distinct_processes": len({seed.get("source_function") for seed in seeds}),
        "clock_domains": sorted({seed.get("clock") for seed in seeds if seed.get("clock")}),
        "branch_depth_sum": sum(seed.get("branch_depth", 0) for seed in seeds),
    }


def _three_distinct_updates(
    benchmark: Benchmark, output_root: Path,
) -> list[dict[str, Any]]:
    # Rank complete triples by actual IR coupling. Width and raw phase count are
    # deliberately absent: multi_phase_proofs selects semantic bridges first.
    unique: dict[str, dict[str, Any]] = {}
    for seed in select_phase_seeds(benchmark, output_root):
        if seed["branch_kind"] == "update":
            unique.setdefault(seed["destination"], seed)
    triples = list(itertools.combinations(unique.values(), 3))
    if not triples:
        return []

    def rank(triple: tuple[dict[str, Any], ...]) -> tuple[Any, ...]:
        evidence = _bridge_evidence(triple)
        return (
            -evidence["dependency_links"],
            -evidence["shared_read_links"],
            -evidence["shared_process_links"],
            -evidence["control_fields"],
            -evidence["branch_depth_sum"],
            tuple(sorted(seed["seed_id"] for seed in triple)),
        )

    return list(sorted(triples, key=rank)[0])


def _copy_r7_property(prop: dict[str, Any], experiment_class: str) -> dict[str, Any]:
    copied = json.loads(json.dumps(prop))
    copied.update({
        "r8_origin": "proof_gaps_FROZEN_PROPERTY",
        "r8_experiment_class": experiment_class,
        "operational_bottleneck_candidate": experiment_class == "MEDIUM_BOTTLENECK",
        "validation_status": "PENDING_R8_VALIDATION",
    })
    # Reference proofs remain validation-only and are never included in an LLM task.
    return copied


def _strong_property(
    benchmark: Benchmark, seeds: list[dict[str, Any]],
) -> dict[str, Any]:
    first, second, third = seeds
    state = f"{benchmark.top_module}State"
    item = "EventInput" if first.get("multi_clock_model") else f"{benchmark.top_module}Inputs"
    phase_a = "(preA ++ [itemA])"
    start_b = f"(r3Run s {phase_a})"
    phase_b = "(preB ++ [itemB])"
    start_c = f"(r3Run {start_b} {phase_b})"
    expected_a = _expected_at(first, "(r3Run s preA)", "itemA")
    expected_b = _expected_at(second, f"(r3Run {start_b} preB)", "itemB")
    expected_c = _expected_at(third, f"(r3Run {start_c} preC)", "itemC")
    statement = (
        f"∀ (s : {state}) (preA : List {item}) (itemA : {item}) "
        f"(preB : List {item}) (itemB : {item}) (preC : List {item}) (itemC : {item}), "
        f"R3Temporal.Along r3Step {first['guard_name']} s {phase_a} → "
        f"R3Temporal.Along r3Step {second['guard_name']} {start_b} {phase_b} → "
        f"R3Temporal.Along r3Step {third['guard_name']} {start_c} (preC ++ [itemC]) → "
        f"((r3Run s {phase_a}).{first['destination']} = {expected_a}) ∧ "
        f"((r3Run {start_b} {phase_b}).{second['destination']} = {expected_b}) ∧ "
        f"((r3Run {start_c} (preC ++ [itemC])).{third['destination']} = {expected_c})"
    )
    proof = f'''by
  intro s preA itemA preB itemB preC itemC hA hB hC
  have lastGuard : ∀ (guard : {state} → {item} → Prop)
      (t : {state}) (pre : List {item}) (item : {item}),
      R3Temporal.Along r3Step guard t (pre ++ [item]) →
      guard (r3Run t pre) item := by
    intro guard t pre
    induction pre generalizing t with
    | nil =>
        intro item h
        exact h.1
    | cons head tail ih =>
        intro item h
        exact ih (r3Step t head) item h.2
  have hgA := lastGuard {first["guard_name"]} s preA itemA hA
  have hgB := lastGuard {second["guard_name"]}
    (r3Run s (preA ++ [itemA])) preB itemB hB
  have hgC := lastGuard {third["guard_name"]}
    (r3Run (r3Run s (preA ++ [itemA])) (preB ++ [itemB])) preC itemC hC
  constructor
  · rw [r3_run_append]
    exact {first["local_lemma"]} (r3Run s preA) itemA hgA
  · constructor
    · rw [r3_run_append]
      exact {second["local_lemma"]}
        (r3Run (r3Run s (preA ++ [itemA])) preB) itemB hgB
    · rw [r3_run_append]
      exact {third["local_lemma"]}
        (r3Run (r3Run (r3Run s (preA ++ [itemA])) (preB ++ [itemB])) preC) itemC hgC'''
    rtl = [seed.get("rtl_evidence") for seed in seeds]
    ir = [seed.get("ir_evidence") for seed in seeds]
    fields = [seed["destination"] for seed in seeds]
    clocks = list(dict.fromkeys(seed["clock"] for seed in seeds))
    gap_type = "CROSS_CLOCK_BRIDGE" if len(clocks) > 1 else "MULTI_PHASE_BRIDGE"
    semantic_evidence = _bridge_evidence(seeds)
    property_id = "r8_triple_phase_" + benchmark.slug + "_" + "_".join(_safe(x) for x in fields)
    return {
        "property_id": property_id,
        "dut": benchmark.design_id,
        "module": benchmark.top_module,
        "property_family": gap_type,
        "property_level": "OPERATIONAL_PROOF_BOTTLENECK",
        "theorem_statement": statement,
        "reference_proof": proof,
        "proof_candidates": [proof],
        "selection_seeds": [seed["seed_id"] for seed in seeds],
        "foundation_lemmas": [seed["local_lemma"] for seed in seeds] + ["r3_run_append"],
        "referenced_state_fields": fields,
        "referenced_inputs": sorted(set(
            name for seed in seeds for name in seed.get("referenced_inputs", [])
        )),
        "source_functions": list(dict.fromkeys(seed["source_function"] for seed in seeds)),
        "clock_domains": clocks,
        "clock_domain_count": len(clocks),
        "max_signal_width": max(seed["width"] for seed in seeds),
        "aggregate_data_width": sum(seed["width"] for seed in seeds),
        "rtl_complexity": "HIGH",
        "rtl_evidence": rtl,
        "ir_evidence": ir,
        "gap_spec": {
            "gap_type": gap_type,
            "missing_relation": (
                "A shared symbolic last-step guard abstraction must connect three real RTL "
                "update regions across three sequential trace phases"
            ),
            "relation_anchors": ["Along", "r3Run", "preA", "preB", "preC", *fields],
            "required_lower_level_facts": [
                seed["local_lemma"] for seed in seeds
            ] + ["r3_run_append", "R3Temporal.Along"],
            "missing_relation_derivable": True,
            "gap_depth": 4,
            "derivation_shape": "SHARED_LAST_GUARD_INDUCTION_PLUS_THREE_L3_LOCAL_STEPS",
            "selection_basis": "RTL_IR_SEMANTIC_DEPENDENCY",
            "semantic_dependency_evidence": semantic_evidence,
            "candidate_strength_evidence": {
                "real_update_regions": len(seeds),
                "required_lower_level_fact_count": len(seeds) + 1,
                "new_semantic_abstraction": "SYMBOLIC_LAST_GUARD_EXTRACTION",
            },
        },
        "r8_origin": "RTL_IR_AUTOMATIC_DISCOVERY",
        "r8_experiment_class": "STRONG_BOTTLENECK",
        "operational_bottleneck_candidate": True,
        "validation_status": "PENDING_R8_VALIDATION",
    }


def build_candidates(
    benchmarks: list[Benchmark], output_root: Path, requirement_root: Path,
) -> dict[str, Any]:
    r7_path = output_root / "proof_gaps" / "corpus" / "final_properties.json"
    r7 = _read(r7_path)
    by_dut: dict[str, list[dict[str, Any]]] = {}
    for prop in r7["properties"]:
        by_dut.setdefault(prop["dut"], []).append(prop)
    properties: list[dict[str, Any]] = []
    discovery: list[dict[str, Any]] = []
    for benchmark in benchmarks:
        prior = by_dut.get(benchmark.design_id, [])
        covered = next((row for row in prior if row["classification"] == "FOUNDATIONALLY_COVERED"), None)
        weak = next((row for row in prior if row["property_family"] == "SYMBOLIC_POSITION_BRIDGE"), None)
        medium = next((row for row in prior if row["property_family"] in {"PHASE_BRIDGE", "MULTI_CLOCK_BRIDGE"}), None)
        seeds = _three_distinct_updates(benchmark, output_root)
        if not (covered and weak and medium and len(seeds) == 3):
            discovery.append({
                "dut": benchmark.design_id, "status": "REJECTED",
                "reason": "MISSING_R7_LAYER_OR_FEWER_THAN_THREE_DISTINCT_RTL_UPDATES",
                "distinct_update_count": len(seeds),
            })
            continue
        properties.extend([
            _copy_r7_property(covered, "FOUNDATION_COVERED"),
            _copy_r7_property(weak, "WEAK_GAP"),
            _copy_r7_property(medium, "MEDIUM_BOTTLENECK"),
            _strong_property(benchmark, seeds),
        ])
        discovery.append({
            "dut": benchmark.design_id, "status": "SELECTED",
            "r7_properties": [covered["property_id"], weak["property_id"], medium["property_id"]],
            "strong_seed_ids": [row["seed_id"] for row in seeds],
            "strong_fields": [row["destination"] for row in seeds],
            "semantic_dependency_evidence": _bridge_evidence(seeds),
            "selection_rule": (
                "R7 controls plus the highest-ranked triple by RTL/IR data dependency, "
                "shared read cone, process coupling, and control relevance"
            ),
        })
    payload = {
        "schema": "rtl2lean-multi_phase_proofs-candidates-v2-semantic-ranking",
        "generated_before_proof": True,
        "proof_gaps_source_sha256": hashlib.sha256(r7_path.read_bytes()).hexdigest(),
        "properties": properties,
        "discovery": discovery,
        "metrics": {
            "N_ALL": len(properties),
            **{f"N_{name}": sum(row["r8_experiment_class"] == name for row in properties)
               for name in ("FOUNDATION_COVERED", "WEAK_GAP", "MEDIUM_BOTTLENECK", "STRONG_BOTTLENECK")},
        },
    }
    write_json(requirement_root / "corpus" / "all_candidates.json", payload)
    return payload
