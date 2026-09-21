"""Generate proof-gap-aware properties from validated RTL transition seeds."""
from __future__ import annotations

import re
from pathlib import Path
from typing import Any

from rtl2lean.pipeline.io import write_json
from rtl2lean.pipeline.manifest import Benchmark
from rtl2lean.compositional_proofs.corpus import select_phase_seeds
from rtl2lean.temporal.corpus import _expected_at


def _safe(value: str) -> str:
    return re.sub(r"[^A-Za-z0-9_]", "_", value)


def _item_type(benchmark: Benchmark, seed: dict[str, Any]) -> str:
    return "EventInput" if seed.get("multi_clock_model") else f"{benchmark.top_module}Inputs"


def _state_type(benchmark: Benchmark) -> str:
    return f"{benchmark.top_module}State"


def _evidence(seeds: list[dict[str, Any]]) -> tuple[list[Any], list[Any]]:
    return ([seed.get("rtl_evidence") for seed in seeds],
            [seed.get("ir_evidence") for seed in seeds])


def _base(
    benchmark: Benchmark, seeds: list[dict[str, Any]], property_id: str,
    family: str, statement: str, proof: str, gap_spec: dict[str, Any] | None,
) -> dict[str, Any]:
    rtl, ir = _evidence(seeds)
    fields = list(dict.fromkeys(seed["destination"] for seed in seeds))
    clocks = list(dict.fromkeys(seed["clock"] for seed in seeds))
    return {
        "property_id": property_id,
        "dut": benchmark.design_id,
        "module": benchmark.top_module,
        "property_family": family,
        "property_level": "PROOF_GAP_AWARE",
        "theorem_statement": statement,
        "reference_proof": proof,
        "proof_candidates": [proof],
        "selection_seeds": [seed["seed_id"] for seed in seeds],
        "foundation_lemmas": [seed["local_lemma"] for seed in seeds],
        "referenced_state_fields": fields,
        "referenced_inputs": sorted(set(
            name for seed in seeds for name in seed.get("referenced_inputs", [])
        )),
        "source_functions": list(dict.fromkeys(seed["source_function"] for seed in seeds)),
        "clock_domains": clocks,
        "clock_domain_count": len(clocks),
        "max_signal_width": max(seed["width"] for seed in seeds),
        "aggregate_data_width": sum(seed["width"] for seed in seeds),
        "rtl_complexity": "HIGH" if len(seeds) > 1 or max(seed["width"] for seed in seeds) >= 32 else "MEDIUM",
        "rtl_evidence": rtl,
        "ir_evidence": ir,
        "gap_spec": gap_spec,
        "preproof_only_metadata": True,
        "validation_status": "PENDING",
    }


def covered_property(benchmark: Benchmark, seed: dict[str, Any]) -> dict[str, Any]:
    state, item = _state_type(benchmark), _item_type(benchmark, seed)
    statement = (
        f"∀ (s : {state}) (item : {item}), {seed['guard_name']} s item → "
        f"(r3Step s item).{seed['destination']} = {seed['local_expected']}"
    )
    return _base(
        benchmark, [seed], f"r7_covered_{benchmark.slug}_{_safe(seed['destination'])}",
        "FOUNDATION_STEP", statement,
        f"by intro s item h; exact {seed['local_lemma']} s item h", None,
    )


def symbolic_endpoint_property(benchmark: Benchmark, seed: dict[str, Any]) -> dict[str, Any]:
    state, item = _state_type(benchmark), _item_type(benchmark, seed)
    expected = _expected_at(seed, "(r3Run s pre)", "item")
    statement = (
        f"∀ (s : {state}) (pre : List {item}) (item : {item}), "
        f"R3Temporal.Along r3Step {seed['guard_name']} s (pre ++ [item]) → "
        f"(r3Run s (pre ++ [item])).{seed['destination']} = {expected}"
    )
    proof = f'''by
  intro s pre
  induction pre generalizing s with
  | nil =>
      intro item halong
      exact {seed["local_lemma"]} s item halong.1
  | cons head tail ih =>
      intro item halong
      exact ih (r3Step s head) item halong.2'''
    gap = {
        "gap_type": "SYMBOLIC_POSITION_BRIDGE",
        "missing_relation": (
            "Along on a symbolic prefix ending in one real update implies the endpoint "
            f"value of {seed['destination']} equals that last update expression"
        ),
        "relation_anchors": ["Along", "r3Run", "pre", "item", seed["destination"]],
        "required_lower_level_facts": [seed["local_lemma"], "R3Temporal.Along", "r3Run"],
        "missing_relation_derivable": True,
        "gap_depth": 2,
        "derivation_shape": "LIST_INDUCTION_PLUS_L3_LOCAL_STEP",
    }
    return _base(
        benchmark, [seed], f"r7_symbolic_endpoint_{benchmark.slug}_{_safe(seed['destination'])}",
        "SYMBOLIC_POSITION_BRIDGE", statement, proof, gap,
    )


def joint_endpoint_property(
    benchmark: Benchmark, first: dict[str, Any], second: dict[str, Any],
) -> dict[str, Any]:
    state, item = _state_type(benchmark), _item_type(benchmark, first)
    phase_a = "(preA ++ [itemA])"
    start_b = f"(r3Run s {phase_a})"
    expected_a = _expected_at(first, "(r3Run s preA)", "itemA")
    expected_b = _expected_at(second, f"(r3Run {start_b} preB)", "itemB")
    statement = (
        f"∀ (s : {state}) (preA : List {item}) (itemA : {item}) "
        f"(preB : List {item}) (itemB : {item}), "
        f"R3Temporal.Along r3Step {first['guard_name']} s {phase_a} → "
        f"R3Temporal.Along r3Step {second['guard_name']} {start_b} (preB ++ [itemB]) → "
        f"((r3Run s {phase_a}).{first['destination']} = {expected_a}) ∧ "
        f"((r3Run {start_b} (preB ++ [itemB])).{second['destination']} = {expected_b})"
    )
    proof = f'''by
  intro s preA itemA preB itemB hA hB
  have bridgeA : ∀ (t : {state}) (pre : List {item}) (item : {item}),
      R3Temporal.Along r3Step {first["guard_name"]} t (pre ++ [item]) →
      (r3Run t (pre ++ [item])).{first["destination"]} = {_expected_at(first, "(r3Run t pre)", "item")} := by
    intro t pre
    induction pre generalizing t with
    | nil =>
        intro item halong
        exact {first["local_lemma"]} t item halong.1
    | cons head tail ih =>
        intro item halong
        exact ih (r3Step t head) item halong.2
  have bridgeB : ∀ (t : {state}) (pre : List {item}) (item : {item}),
      R3Temporal.Along r3Step {second["guard_name"]} t (pre ++ [item]) →
      (r3Run t (pre ++ [item])).{second["destination"]} = {_expected_at(second, "(r3Run t pre)", "item")} := by
    intro t pre
    induction pre generalizing t with
    | nil =>
        intro item halong
        exact {second["local_lemma"]} t item halong.1
    | cons head tail ih =>
        intro item halong
        exact ih (r3Step t head) item halong.2
  exact ⟨bridgeA s preA itemA hA,
    bridgeB (r3Run s (preA ++ [itemA])) preB itemB hB⟩'''
    gap_type = "MULTI_CLOCK_BRIDGE" if first["clock"] != second["clock"] else "PHASE_BRIDGE"
    gap = {
        "gap_type": gap_type,
        "secondary_gap_type": "WIDE_STATE_RELATION" if max(first["width"], second["width"]) >= 32 else "STATE_RELATION",
        "missing_relation": (
            "Two independently derived symbolic endpoint relations must be composed across "
            f"{first['destination']} and {second['destination']}"
        ),
        "relation_anchors": [
            "Along", "r3Run", "preA", "preB", first["destination"], second["destination"],
        ],
        "required_lower_level_facts": [first["local_lemma"], second["local_lemma"], "R3Temporal.Along", "r3Run"],
        "missing_relation_derivable": True,
        "gap_depth": 3,
        "derivation_shape": "TWO_LIST_INDUCTIONS_PLUS_TWO_L3_LOCAL_STEPS",
    }
    return _base(
        benchmark, [first, second],
        f"r7_joint_endpoint_{benchmark.slug}_{_safe(first['destination'])}_{_safe(second['destination'])}",
        gap_type, statement, proof, gap,
    )


def _rank(seed: dict[str, Any]) -> tuple[Any, ...]:
    control = bool(re.search(r"state|round|count|counter|ctr|ready|done|busy|ack|valid", seed["destination"], re.I))
    return (-int(control), -seed["width"], -seed.get("branch_depth", 0), seed["seed_id"])


def build_candidates(
    benchmarks: list[Benchmark], output_root: Path, requirement_root: Path,
) -> dict[str, Any]:
    properties: list[dict[str, Any]] = []
    discovery: list[dict[str, Any]] = []
    for benchmark in benchmarks:
        selected = select_phase_seeds(benchmark, output_root)
        updates = sorted([seed for seed in selected if seed["branch_kind"] == "update"], key=_rank)
        distinct: list[dict[str, Any]] = []
        for seed in updates:
            if seed["destination"] not in {row["destination"] for row in distinct}:
                distinct.append(seed)
        if len(distinct) < 2:
            discovery.append({"dut": benchmark.design_id, "status": "REJECTED", "reason": "FEWER_THAN_TWO_DISTINCT_VALIDATED_UPDATES"})
            continue
        first, second = distinct[:2]
        properties.extend([
            covered_property(benchmark, first),
            symbolic_endpoint_property(benchmark, first),
            joint_endpoint_property(benchmark, first, second),
        ])
        discovery.append({
            "dut": benchmark.design_id, "status": "SELECTED",
            "seed_ids": [first["seed_id"], second["seed_id"]],
            "fields": [first["destination"], second["destination"]],
            "clocks": [first["clock"], second["clock"]],
            "selection_rule": "top two distinct non-reset validated update regions",
        })
    payload = {
        "schema": "rtl2lean-proof_gaps-candidates-v1",
        "generated_before_proof": True,
        "properties": properties,
        "discovery": discovery,
        "metrics": {
            "N_ALL": len(properties),
            "N_EXPECTED_COVERED": sum(row["gap_spec"] is None for row in properties),
            "N_EXPECTED_CHALLENGE": sum(row["gap_spec"] is not None for row in properties),
        },
    }
    write_json(requirement_root / "corpus" / "all_candidates.json", payload)
    return payload
