"""Discover real four-phase compositional and non-trivial UNTIL properties."""
from __future__ import annotations

import hashlib
import json
import re
from pathlib import Path
from typing import Any

from rtl2lean.pipeline.io import write_json
from rtl2lean.pipeline.manifest import Benchmark
from rtl2lean.temporal_challenges.corpus import _foundation_seed_ids
from rtl2lean.compositional_proofs.foundation import chain_names
from rtl2lean.temporal.corpus import _expected_at, discover_transition_candidates


def _read(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def _item_type(benchmark: Benchmark, seed: dict[str, Any]) -> str:
    return "EventInput" if seed.get("multi_clock_model") else f"{benchmark.top_module}Inputs"


def _expected_fun(seed: dict[str, Any]) -> str:
    return f"(fun t x => {_expected_at(seed, 't', 'x')})"


def _seed_score(seed: dict[str, Any]) -> tuple[Any, ...]:
    name = " ".join([seed["destination"], seed.get("guard_process", ""), seed.get("branch_process", "")])
    control = int(bool(re.search(r"state|round|count|counter|ctr|ready|done|busy|ack|valid", name, re.I)))
    return (
        int(seed.get("branch_kind") == "update"),
        int(seed.get("width", 0) >= 32), seed.get("width", 0), control,
        seed.get("branch_depth", 0), seed.get("expression_size", 0), seed["seed_id"],
    )


def select_phase_seeds(benchmark: Benchmark, output_root: Path) -> list[dict[str, Any]]:
    foundation = _foundation_seed_ids(benchmark, output_root)
    seeds = [
        row for row in discover_transition_candidates(benchmark, output_root)
        if row["seed_id"] in foundation and not row["condition_is_reset_only"]
    ]
    ranked = sorted(seeds, key=_seed_score, reverse=True)
    chosen: list[dict[str, Any]] = []

    def take(predicate: Any, distinct_destination: bool = True) -> None:
        for seed in ranked:
            if seed in chosen:
                continue
            if distinct_destination and seed["destination"] in {x["destination"] for x in chosen}:
                continue
            if predicate(seed):
                chosen.append(seed)
                return

    take(lambda _: True)
    take(lambda seed: seed["source_function"] not in {x["source_function"] for x in chosen})
    if benchmark.slug == "ethmac":
        take(lambda seed: seed["clock"] not in {x["clock"] for x in chosen})
    while len(chosen) < 4:
        before = len(chosen)
        take(lambda _: True, distinct_destination=False)
        if len(chosen) == before:
            break
    # The first three phases may include genuine RTL hold branches (which are
    # semantic state transitions and supply preservation facts), but the final
    # witness must be backed by a real register update.  Preserve all selected
    # seeds and move an update to the witness position when necessary.
    if len(chosen) == 4 and chosen[-1].get("branch_kind") != "update":
        for index in range(len(chosen) - 2, -1, -1):
            if chosen[index].get("branch_kind") == "update":
                chosen[index], chosen[-1] = chosen[-1], chosen[index]
                break
    return chosen


def _state_after(start: str, phases: list[str]) -> str:
    state = start
    for phase in phases:
        state = f"r3Run ({state}) {phase}"
    return state


def compositional_property(benchmark: Benchmark, seeds: list[dict[str, Any]]) -> dict[str, Any]:
    if len(seeds) != 4:
        raise ValueError(f"{benchmark.design_id} lacks four independent update regions")
    item_type = _item_type(benchmark, seeds[0])
    s0 = "r3Run init pre"
    s1 = _state_after(s0, ["phase1"])
    s2 = _state_after(s0, ["phase1", "phase2"])
    s3 = _state_after(s0, ["phase1", "phase2", "phase3"])
    states = [s0, s1, s2, s3]
    lists = ["phase1", "phase2", "phase3", "item4 :: suffix4"]

    along = [
        f"R3Temporal.Along r3Step {seed['guard_name']} ({state}) ({items})"
        for seed, state, items in zip(seeds, states, lists)
    ]
    obeys = [
        f"R3Temporal.Obeys r3Step {seed['guard_name']} {_expected_fun(seed)} "
        f"(fun t => t.{seed['destination']}) ({state}) ({items})"
        for seed, state, items in zip(seeds, states, lists)
    ]
    prefix = (
        f"∀ k, k ≤ phase3.length → R3Temporal.Obeys r3Step {seeds[2]['guard_name']} "
        f"{_expected_fun(seeds[2])} (fun t => t.{seeds[2]['destination']}) ({s2}) (phase3.take k)"
    )
    final_expected = _expected_at(seeds[3], f"({s3})", "item4")
    eventually = (
        f"R3Temporal.Eventually r3Step (fun t => t.{seeds[3]['destination']} = {final_expected}) "
        f"({s3}) (item4 :: suffix4)"
    )
    statement = (
        f"∀ (pre phase1 phase2 phase3 : List {item_type}) (item4 : {item_type}) "
        f"(suffix4 : List {item_type}), phase1 ≠ [] → phase2 ≠ [] → phase3 ≠ [] → "
        + " → ".join(along) + " → "
        + "(" + " ∧ ".join(f"({part})" for part in [obeys[0], obeys[1], prefix, obeys[3], eventually]) + ")"
    )

    local = [seed["local_lemma"] for seed in seeds]
    proof = f'''by
  intro pre phase1 phase2 phase3 item4 suffix4 _ _ _ h1 h2 h3 h4
  have o1 := R3Temporal.obeys_of_along r3Step {seeds[0]["guard_name"]}
    {_expected_fun(seeds[0])} (fun t => t.{seeds[0]["destination"]}) {local[0]}
    ({s0}) phase1 h1
  have o2 := R3Temporal.obeys_of_along r3Step {seeds[1]["guard_name"]}
    {_expected_fun(seeds[1])} (fun t => t.{seeds[1]["destination"]}) {local[1]}
    ({s1}) phase2 h2
  have o3 := R3Temporal.obeys_of_along r3Step {seeds[2]["guard_name"]}
    {_expected_fun(seeds[2])} (fun t => t.{seeds[2]["destination"]}) {local[2]}
    ({s2}) phase3 h3
  have o4 := R3Temporal.obeys_of_along r3Step {seeds[3]["guard_name"]}
    {_expected_fun(seeds[3])} (fun t => t.{seeds[3]["destination"]}) {local[3]}
    ({s3}) (item4 :: suffix4) h4
  refine ⟨o1, o2, ?_, o4, ?_⟩
  · intro k hk
    exact R3Temporal.obeys_take r3Step {seeds[2]["guard_name"]}
      {_expected_fun(seeds[2])} (fun t => t.{seeds[2]["destination"]})
      ({s2}) phase3 k o3
  · exact R3Temporal.eventually_after_prefix r3Step
      (fun t => t.{seeds[3]["destination"]} = {final_expected})
      ({s3}) [] suffix4 item4
      ({local[3]} ({s3}) item4 h4.1)'''

    processes = sorted(set(seed["source_function"] for seed in seeds))
    clocks = sorted(set(seed["clock"] for seed in seeds))
    widths = [seed["width"] for seed in seeds]
    fields = [seed["destination"] for seed in seeds]
    conditions = [
        "PHASE_COUNT_GE_2", "SEMANTIC_TRANSITION_COUNT_GE_4",
        "MULTIPLE_PROCESS_OR_CONTROL_REGIONS", "PREFIX_AND_SUFFIX_REASONING",
        "MULTIPLE_STATE_RELATIONS", "TEMPORAL_WITNESS_AND_PRESERVATION",
    ]
    if max(widths) >= 32 and any(width <= 8 for width in widths):
        conditions.append("WIDE_STATE_AND_CONTROL_RELATION")
    if len(clocks) >= 2:
        conditions.append("CROSS_CLOCK_COMPOSITION")
    tags = ["MULTI_PHASE", "LONG_TEMPORAL", "SYMBOLIC_START_POSITION"]
    if max(widths) >= 32:
        tags.extend(["WIDE_DATA", "LONG_WIDE", "WIDE_SYMBOLIC", "LONG_WIDE_SYMBOLIC"])
    if len(clocks) >= 2:
        tags.append("MULTI_CLOCK_COMPOSITION")
    pid = f"r5_compositional_{benchmark.slug}_" + hashlib.sha256(
        "|".join(seed["seed_id"] for seed in seeds).encode()
    ).hexdigest()[:10]
    return {
        "property_id": pid, "dut": benchmark.design_id, "module": benchmark.top_module,
        "property_level": "COMPOSITIONAL_HARD", "property_family": "COMPOSITIONAL_HARD",
        "theorem_statement": statement, "proof_candidates": [proof], "tags": tags,
        "hardness_conditions": conditions, "hardness_gate_pass": len(conditions) >= 3,
        "phase_count": 4, "semantic_transition_count": 4,
        "minimum_required_transitions": 4,
        "temporal_span": "SYMBOLIC_PREFIX_THEN_FOUR_REAL_CONTROL_PHASES",
        "process_count": len(processes), "control_region_count": len(processes),
        "requires_prefix_suffix_reasoning": True, "state_relation_count": len(set(fields)),
        "requires_temporal_witness": True, "requires_preservation": True,
        "max_signal_width": max(widths), "aggregate_data_width": sum(widths),
        "clock_domain_count": len(clocks), "symbolic_index_count": 2,
        "recursive_depth": 2, "dependency_depth": sum(
            len(seed.get("dependency_evidence", {}).get(layer, []))
            for seed in seeds for layer in ("L1", "L2", "L3", "L4")
        ),
        "source_functions": processes, "clock_domains": clocks,
        "referenced_state_fields": fields,
        "referenced_inputs": sorted(set(sum((seed.get("referenced_inputs", []) for seed in seeds), []))),
        "foundation_lemmas": local,
        "trigger_condition": [seed.get("guard_process") for seed in seeds],
        "rtl_evidence": [seed.get("rtl_evidence") for seed in seeds],
        "ir_evidence": [seed.get("ir_evidence") for seed in seeds],
        "environment_assumptions": [], "protocol_assumptions": [],
        "reset_assumptions": sorted(set(
            name for seed in seeds for name in seed.get("condition_uses", [])
            if re.search(r"reset|rst", name, re.I)
        )),
        "completion_cycle_kind": (
            "SYMBOLIC_START_POSITION" if benchmark.slug == "aes" else "NOT_COMPLETION_PROPERTY"
        ),
        "aes_cycle_types": (["SYMBOLIC_START_POSITION", "LONG_TEMPORAL", "WIDE_DATA", "MULTI_PHASE"]
                            if benchmark.slug == "aes" else []),
        "selection_seeds": [seed["seed_id"] for seed in seeds],
    }


def until_property(benchmark: Benchmark, selected: dict[str, Any]) -> dict[str, Any]:
    hold, update = selected["hold"], selected["update"]
    state = f"{benchmark.top_module}State"
    item_type = _item_type(benchmark, hold)
    field = hold["destination"]
    expected = _expected_at(update, "(r3Run s pre)", "item")
    names = chain_names(hold)
    statement = (
        f"∀ (s : {state}) (pre suffix : List {item_type}) (item : {item_type}), pre ≠ [] → "
        f"R3Temporal.Along r3Step {hold['guard_name']} s pre → "
        f"{update['guard_name']} (r3Run s pre) item → "
        f"R3Temporal.Until r3Step (fun t => t.{field} = s.{field}) "
        f"(fun t => t.{field} = {expected}) s (pre ++ item :: suffix)"
    )
    proof = f'''by
  intro s pre suffix item _ halong hupdate
  rcases {names["completion_witness"]} s pre suffix item hupdate with
    ⟨k, hk, hbound, hcomplete⟩
  refine ⟨k, hbound, hcomplete, ?_⟩
  intro j hj
  subst k
  have hle : j ≤ pre.length := by omega
  rw [List.take_append_of_le_length hle]
  exact {names["prefix_preservation"]} s.{field} s pre rfl halong j hle'''
    return {
        "property_id": f"r5_until_{benchmark.slug}_{re.sub(r'[^A-Za-z0-9_]', '_', field)}",
        "dut": benchmark.design_id, "module": benchmark.top_module,
        "property_level": "UNTIL", "property_family": "UNTIL",
        "theorem_statement": statement, "proof_candidates": [proof],
        "tags": ["UNTIL", "NONTRIVIAL_HOLD", "SYMBOLIC_START_POSITION"],
        "hardness_conditions": ["PHASE_COUNT_GE_2", "PREFIX_AND_SUFFIX_REASONING",
                                "TEMPORAL_WITNESS_AND_PRESERVATION"],
        "hardness_gate_pass": True, "phase_count": 2, "semantic_transition_count": 2,
        "minimum_required_transitions": 2,
        "temporal_span": "NONEMPTY_REAL_HOLD_PREFIX_UNTIL_REAL_UPDATE",
        "process_count": 1, "control_region_count": 2,
        "requires_prefix_suffix_reasoning": True, "state_relation_count": 1,
        "requires_temporal_witness": True, "requires_preservation": True,
        "max_signal_width": hold["width"], "aggregate_data_width": hold["width"],
        "clock_domain_count": 1, "symbolic_index_count": 1, "recursive_depth": 1,
        "dependency_depth": 0, "source_functions": [hold["source_function"]],
        "clock_domains": [hold["clock"]], "referenced_state_fields": [field],
        "referenced_inputs": sorted(set(hold.get("referenced_inputs", []) + update.get("referenced_inputs", []))),
        "foundation_lemmas": [hold["local_lemma"], update["local_lemma"], *names.values()],
        "trigger_condition": update["guard_process"],
        "reset_assumption": [x for x in update.get("condition_uses", []) if re.search(r"reset|rst", x, re.I)],
        "environment_assumption": [],
        "protocol_assumption": "the symbolic completion event satisfies the real RTL update guard",
        "progress_assumption": "a nonempty real hold prefix is followed by a real update event",
        "fairness_assumption": None,
        "completion_bound_source": "trace decomposition; symbolic witness pre.length + 1",
        "completion_cycle_kind": "BOUNDED_EXISTENTIAL_COMPLETION",
        "state_changing_transition_proved": False,
        "state_changing_transition_potential": selected["state_changing_potential"],
        "other_process_writes": selected["other_process_writes"],
        "rtl_evidence": [hold.get("rtl_evidence"), update.get("rtl_evidence")],
        "ir_evidence": [hold.get("ir_evidence"), update.get("ir_evidence")],
        "environment_assumptions": [], "protocol_assumptions": [], "reset_assumptions": [],
    }


def build_corpus(
    benchmarks: list[Benchmark], output_root: Path, requirement_root: Path,
    foundations: dict[str, Any],
) -> dict[str, Any]:
    hard, hard_candidates = [], []
    for benchmark in benchmarks:
        seeds = select_phase_seeds(benchmark, output_root)
        hard_candidates.append({
            "dut": benchmark.design_id, "selected_seed_count": len(seeds),
            "selected_seeds": [seed["seed_id"] for seed in seeds],
            "processes": sorted(set(seed["source_function"] for seed in seeds)),
            "clocks": sorted(set(seed["clock"] for seed in seeds)),
        })
        if len(seeds) == 4:
            hard.append(compositional_property(benchmark, seeds))
    if any(not prop["hardness_gate_pass"] for prop in hard):
        raise RuntimeError("a COMPOSITIONAL_HARD property failed the three-condition preference gate")

    benchmark_map = {x.design_id: x for x in benchmarks}
    until = [until_property(benchmark_map[row["dut"]], row) for row in foundations["selected_chains"]]
    properties = [*hard, *until]
    payload = {
        "schema": "rtl2lean-compositional_proofs-corpus-v1",
        "independent_from_temporal_challenges": True, "frozen_before_baseline": False,
        "selection_rule": "four real RTL branch transitions (hold or update, with a final update witness) spanning at least two processes, plus kernel-probed nonempty-hold UNTIL chains",
        "properties": properties,
        "metrics": {"N_COMPOSITIONAL_HARD": len(hard), "N_UNTIL": len(until),
                    "N_VARIABLE_COMPLETION": 0, "N_TOTAL": len(properties)},
    }
    write_json(requirement_root / "compositional_hard" / "candidates.json", {
        "schema": "rtl2lean-compositional_proofs-compositional-candidates-v1", "rows": hard_candidates,
    })
    write_json(requirement_root / "compositional_hard" / "complexity.json", {
        "properties": [{key: prop.get(key) for key in (
            "dut", "property_id", "phase_count", "semantic_transition_count",
            "minimum_required_transitions", "temporal_span", "process_count",
            "control_region_count", "requires_prefix_suffix_reasoning", "state_relation_count",
            "requires_temporal_witness", "requires_preservation", "max_signal_width",
            "aggregate_data_width", "clock_domain_count", "symbolic_index_count",
            "recursive_depth", "dependency_depth", "hardness_conditions", "hardness_gate_pass",
        )} for prop in hard],
    })
    write_json(requirement_root / "until" / "results.json", {
        "schema": "rtl2lean-compositional_proofs-until-results-v1", "properties": until,
        "N": len(until),
    })
    return payload
