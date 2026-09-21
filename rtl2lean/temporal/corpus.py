"""Typed-IR discovery and classification for temporal temporal properties."""
from __future__ import annotations

import json
import re
from collections import defaultdict
from pathlib import Path
from typing import Any, Iterable

from rtl2lean.evaluation.corpus import (
    CONTROL_RE,
    DATAPATH_RE,
    PROTOCOL_RE,
    _assignments,
    _conditional_leaves,
    _dependencies,
    _dependency_cone,
    _evidence,
    _family,
    _node_count,
    _render,
    _safe,
    _value_uses,
    load_frozen_objects,
)
from rtl2lean.pipeline.io import write_json
from rtl2lean.pipeline.manifest import Benchmark


COUNTER_RE = re.compile(
    r"(?:^|__|_)(?:round|count|counter|ctr|index|pointer|state)(?:__|_|$)", re.I,
)


def _instantiate(expression: str, state: str, input_value: str) -> str:
    """Interpret a process expression at the full-step pre-comb state."""
    result = re.sub(r"\bs\.", f"(comb {state} {input_value}).", expression)
    return re.sub(r"\bi\.", f"({input_value}).", result)


def _clock_event(clock: str) -> str:
    return "on_" + _safe(clock)


def _branch_kind(destination: str, leaf: Any) -> str:
    return "hold" if leaf.kind == "var" and str(leaf.data.get("name")) == destination else "update"


def _semantic_tag(field: str) -> str:
    if CONTROL_RE.search(field):
        return "CONTROL"
    if PROTOCOL_RE.search(field):
        return "PROTOCOL"
    if DATAPATH_RE.search(field):
        return "DATAPATH"
    return "STATE"


def discover_transition_candidates(benchmark: Benchmark, output_root: Path) -> list[dict[str, Any]]:
    root = output_root / benchmark.slug
    design = json.loads((root / "analysis" / "design.json").read_text(encoding="utf-8"))
    _, ir, typed = load_frozen_objects(output_root, benchmark)
    framework = json.loads((root / "model" / "targets.json").read_text(encoding="utf-8"))["targets"]
    registers = set(dict(ir.registers))
    signal_map = {item.name: item for item in typed.module.signals}
    multi_clock = len(typed.module.clock_domains) > 1
    results: list[dict[str, Any]] = []
    seen: set[tuple[str, str, str]] = set()
    for function in ir.functions:
        if not function.is_sequential:
            continue
        process = next((item for item in typed.module.processes if item.name == function.name), None)
        if not process or not process.clock:
            continue
        for destination, value in _assignments(function):
            signal = signal_map.get(destination)
            if destination not in registers or not signal or value.kind != "phi":
                continue
            if signal.kind not in {"state", "state_output"} or signal.width <= 0 or signal.width > 128:
                continue
            for path, leaf in _conditional_leaves(value):
                if not path or len(path) > 6:
                    continue
                expression_size = sum(_node_count(cond) for cond, _ in path) + _node_count(leaf)
                if expression_size > 192:
                    continue
                branch = "".join("t" if polarity else "f" for _, polarity in path)
                identity = (function.name, destination, branch)
                if identity in seen:
                    continue
                seen.add(identity)
                try:
                    guards = [(_render(cond, ir), polarity) for cond, polarity in path]
                    branch_process = _render(leaf, ir)
                    next_expression_process = _render(value, ir)
                except (KeyError, TypeError, ValueError):
                    continue
                terms = [f"({text})" if polarity else f"!({text})" for text, polarity in guards]
                guard_process = " && ".join(terms)
                uses = set().union(*(_value_uses(cond) for cond, _ in path))
                branch_uses = _value_uses(leaf)
                referenced = uses | branch_uses | {destination}
                input_names = sorted(name for name in referenced
                                     if name in signal_map and signal_map[name].direction == "input")
                output_names = sorted(name for name in referenced
                                      if name in signal_map and signal_map[name].direction == "output")
                seed_id = f"r3seed_{_safe(function.name)}_{_safe(destination)}_{branch}"
                state_var = "s"
                input_var = "item.1" if multi_clock else "item"
                step_guard = _instantiate(guard_process, state_var, input_var)
                kind = _branch_kind(destination, leaf)
                local_expected = _instantiate(branch_process, state_var, input_var)
                item = {
                    "seed_id": seed_id, "dut": benchmark.design_id, "slug": benchmark.slug,
                    "module": benchmark.top_module, "source_function": function.name,
                    "destination": destination, "branch": branch, "branch_kind": kind,
                    "guard_process": guard_process, "branch_process": branch_process,
                    "next_expression_process": next_expression_process,
                    "step_guard": ((f"item.2 == .{_clock_event(process.clock)} && ({step_guard})")
                                   if multi_clock else step_guard),
                    "local_expected": local_expected,
                    "guard_name": seed_id + "_guard",
                    "projection_lemma": seed_id + "_next_value",
                    "local_lemma": seed_id + "_local_step",
                    "clock": process.clock, "clock_event": _clock_event(process.clock),
                    "multi_clock_model": multi_clock, "width": signal.width,
                    "semantic_role": _semantic_tag(destination),
                    "transition_family": _family(destination, path[-1][0]),
                    "branch_depth": len(path), "expression_size": expression_size,
                    "condition_uses": sorted(uses), "branch_uses": sorted(branch_uses),
                    "referenced_signals": sorted(referenced),
                    "referenced_inputs": input_names, "referenced_outputs": output_names,
                    "condition_is_reset_only": bool(uses) and all(
                        re.search(r"reset|rst", name, re.I) for name in uses
                    ),
                    "dependency_cone": _dependency_cone(typed, referenced, {function.name}),
                }
                item.update(_dependencies({
                    "referenced_state_fields": sorted(name for name in referenced if name in registers),
                    "source_functions": [function.name],
                }, framework))
                item.update(_evidence(benchmark, design, typed, destination, function.name,
                                      referenced, expression_size))
                item["semantic_evidence_status"] = (
                    "PASS" if item["rtl_evidence"].get("source_file")
                    and item["rtl_evidence"].get("matching_regions")
                    and item["ir_evidence"].get("process") else "NO_SEMANTIC_EVIDENCE"
                )
                results.append(item)
    return sorted(results, key=lambda item: item["seed_id"])


def select_structural_seeds(candidates: list[dict[str, Any]]) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    """Select one representative branch pair per discovered clock/semantic role.

    This is a structural coverage rule, not a per-DUT count quota.  A role is
    omitted when no non-reset-only hold/update path with evidence exists.
    """
    eligible = [item for item in candidates if item["semantic_evidence_status"] == "PASS"
                and not item["condition_is_reset_only"]]
    groups: dict[tuple[str, str], list[dict[str, Any]]] = defaultdict(list)
    for item in eligible:
        groups[(item["clock"], item["semantic_role"])].append(item)

    def score(item: dict[str, Any]) -> tuple[Any, ...]:
        return (-item["width"], item["branch_depth"], item["expression_size"],
                -len(item["referenced_signals"]), item["seed_id"])

    selected: list[dict[str, Any]] = []
    for key in sorted(groups):
        rows = groups[key]
        by_dest: dict[str, list[dict[str, Any]]] = defaultdict(list)
        for row in rows:
            by_dest[row["destination"]].append(row)
        paired = []
        for destination, items in by_dest.items():
            holds = [item for item in items if item["branch_kind"] == "hold"]
            updates = [item for item in items if item["branch_kind"] == "update"]
            if holds and updates:
                paired.append((min(holds, key=score), min(updates, key=score)))
        if paired:
            hold, update = min(paired, key=lambda pair: (score(pair[0]), score(pair[1])))
            selected.extend([hold, update])
        else:
            for branch_kind in ("hold", "update"):
                subset = [item for item in rows if item["branch_kind"] == branch_kind]
                if subset:
                    selected.append(min(subset, key=score))

    # Preserve the widest real state path even when its semantic role already
    # selected a narrower paired destination.  This is needed for honest wide
    # data discovery and is still purely structural.
    wide_holds = [item for item in eligible if item["branch_kind"] == "hold" and item["width"] >= 64]
    if wide_holds:
        selected.append(min(wide_holds, key=score))
    unique = {item["seed_id"]: item for item in selected}
    selected = [unique[name] for name in sorted(unique)]
    selected_ids = set(unique)
    rejected = [{**item, "rejection_reason": (
        "STRUCTURAL_REPRESENTATIVE_NOT_SELECTED" if item in eligible else
        "RESET_ONLY_OR_MISSING_SEMANTIC_EVIDENCE"
    )} for item in candidates if item["seed_id"] not in selected_ids]
    return selected, rejected


def select_cross_clock_seeds(
    candidates: list[dict[str, Any]], benchmark: Benchmark, output_root: Path,
) -> list[dict[str, Any]]:
    """Retain a real reader branch for every discoverable ordered clock pair.

    The ordinary structural selection covers clock/semantic-role combinations,
    but that alone need not retain the particular reader process containing a
    cross-domain edge.  This additional rule is derived solely from Typed IR:
    one non-reset branch is selected for each ordered source/destination pair
    for which the cross-domain signal occurs in the branch guard or value.
    """
    typed = json.loads(
        (output_root / benchmark.slug / "ir" / "design.json").read_text(encoding="utf-8")
    )
    dependencies = typed["module"].get("cross_clock_dependencies", [])
    eligible = [
        item for item in candidates
        if item["semantic_evidence_status"] == "PASS" and not item["condition_is_reset_only"]
    ]
    by_process: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for item in eligible:
        by_process[item["source_function"]].append(item)

    choices: dict[tuple[str, str], tuple[tuple[Any, ...], dict[str, Any], dict[str, Any]]] = {}
    for dependency in dependencies:
        destination_clock = dependency["destination_clock"]
        for source_clock in dependency["source_clocks"]:
            if source_clock == destination_clock:
                continue
            signal = dependency["signal"]
            for item in by_process.get(dependency["reader_process"], []):
                in_value = signal in item.get("branch_uses", [])
                in_guard = signal in item.get("condition_uses", [])
                if not (in_value or in_guard):
                    continue
                # Prefer a value-propagating update.  It exposes the sampled
                # cross-domain value in the theorem conclusion instead of only
                # mentioning the dependency in a precondition.
                rank = (
                    0 if in_value and item["branch_kind"] == "update" else 1,
                    0 if item["branch_kind"] == "update" else 1,
                    item["expression_size"], item["seed_id"], signal,
                )
                key = (source_clock, destination_clock)
                if key not in choices or rank < choices[key][0]:
                    choices[key] = (rank, item, dependency)

    selected = []
    for (source_clock, destination_clock), (_, item, dependency) in sorted(choices.items()):
        copy = dict(item)
        copy["cross_clock_seed_evidence"] = {
            "source_clock": source_clock,
            "destination_clock": destination_clock,
            "signal": dependency["signal"],
            "reader_process": dependency["reader_process"],
            "signal_in_guard": dependency["signal"] in item.get("condition_uses", []),
            "signal_in_branch_value": dependency["signal"] in item.get("branch_uses", []),
        }
        selected.append(copy)
    return selected


def _item_type(benchmark: Benchmark, multi_clock: bool) -> str:
    return "EventInput" if multi_clock else f"{benchmark.top_module}Inputs"


def _state_type(benchmark: Benchmark) -> str:
    return f"{benchmark.top_module}State"


def _expected_at(seed: dict[str, Any], state: str, item: str) -> str:
    input_value = f"({item}).1" if seed["multi_clock_model"] else item
    return _instantiate(seed["branch_process"], state, input_value)


def _property_base(
    benchmark: Benchmark, seed: dict[str, Any] | None, property_id: str,
    level: str, family: str, statement: str, tags: list[str],
    proof_candidates: list[str],
) -> dict[str, Any]:
    state_fields = [seed["destination"]] if seed else []
    return {
        "property_id": property_id, "dut": benchmark.design_id,
        "module": benchmark.top_module,
        "property_level": level, "property_family": family,
        "theorem_statement": statement, "tags": sorted(set(tags)),
        "rtl_evidence": seed.get("rtl_evidence", {}) if seed else {},
        "ir_evidence": seed.get("ir_evidence", {}) if seed else {
            "process": "generated execution semantics", "clock": None,
        },
        "dependency_evidence": seed.get("dependency_evidence", {}) if seed else {},
        "dependency_cone": seed.get("dependency_cone", {"total": 0}) if seed else {"total": 0},
        "clock_domain": seed.get("clock") if seed else None,
        "referenced_state_fields": state_fields,
        "referenced_inputs": seed.get("referenced_inputs", []) if seed else [],
        "referenced_outputs": seed.get("referenced_outputs", []) if seed else [],
        "source_functions": [seed["source_function"]] if seed else ["run", "step"],
        "trace_structure": family,
        "syntactic_multi_cycle": level in {"TRACE_BRIDGE", "TRUE_MULTI_CYCLE"},
        "semantic_multi_cycle": level == "TRUE_MULTI_CYCLE",
        "semantic_transition_count": 1 if level != "TRUE_MULTI_CYCLE" else 2,
        "minimum_required_transitions": 1 if level != "TRUE_MULTI_CYCLE" else 2,
        "trace_lower_bound": 0 if level != "TRUE_MULTI_CYCLE" else 2,
        "trace_upper_bound": None,
        "max_signal_width": seed.get("width", 0) if seed else 0,
        "aggregate_data_width": seed.get("width", 0) if seed else 0,
        "wide_fields": state_fields if seed and seed.get("width", 0) >= 64 else [],
        "wide_dependency_cone": seed.get("dependency_cone", {}) if seed and seed.get("width", 0) >= 64 else {},
        "symbolic_cycle": "SYMBOLIC_CYCLE" in tags,
        "completion_cycle_kind": "NOT_APPLICABLE",
        "trigger_condition": seed.get("guard_process") if seed else None,
        "environment_assumptions": [], "protocol_assumptions": [],
        "reset_assumptions": [name for name in seed.get("condition_uses", [])
                              if re.search(r"reset|rst", name, re.I)] if seed else [],
        "bound_source": None, "proof_candidates": proof_candidates,
        "foundation_lemmas": ([seed["local_lemma"]] if seed else []),
        "seed_id": seed.get("seed_id") if seed else None,
        "validation_status": "PENDING",
    }


def _select_family_seeds(seeds: list[dict[str, Any]]) -> dict[str, Any]:
    holds = sorted([s for s in seeds if s["branch_kind"] == "hold"],
                   key=lambda s: (-s["width"], s["expression_size"], s["seed_id"]))
    updates = sorted([s for s in seeds if s["branch_kind"] == "update"],
                     key=lambda s: (-s["width"], s["expression_size"], s["seed_id"]))
    pairs = []
    for hold in holds:
        match = next((update for update in updates
                      if update["destination"] == hold["destination"]
                      and update["clock"] == hold["clock"]), None)
        if match:
            pairs.append((hold, match))
    return {"holds": holds, "updates": updates, "pairs": pairs}


def _counter_bound(
    benchmark: Benchmark, output_root: Path, minimum_upper: int = 0,
) -> dict[str, Any] | None:
    typed = json.loads((output_root / benchmark.slug / "ir" / "design.json").read_text(encoding="utf-8"))
    candidates = [item for item in typed["module"]["signals"]
                  if item["kind"] in {"state", "state_output"}
                  and 2 <= item["width"] <= 16 and COUNTER_RE.search(item["name"])
                  and 2 ** item["width"] >= minimum_upper]
    if not candidates:
        return None
    item = min(candidates, key=lambda row: (row["width"], row["name"]))
    return {"field": item["name"], "width": item["width"],
            "upper": 2 ** item["width"],
            "source": f"typed IR range of {item['name']} : BitVec {item['width']}"}


def generate_temporal_properties(
    benchmark: Benchmark,
    accepted_seeds: list[dict[str, Any]],
    output_root: Path,
    aes_mode: bool,
) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    """Generate family coverage from validated branches without a count quota."""
    state = _state_type(benchmark)
    multi_clock = bool(accepted_seeds and accepted_seeds[0]["multi_clock_model"])
    item_type = _item_type(benchmark, multi_clock)
    selected = _select_family_seeds(accepted_seeds)
    holds, updates, pairs = selected["holds"], selected["updates"], selected["pairs"]
    properties: list[dict[str, Any]] = []
    rejected: list[dict[str, Any]] = []

    if aes_mode:
        for seed in accepted_seeds:
            pid = f"r3_single_{seed['seed_id']}"
            statement = (f"∀ (s : {state}) (item : {item_type}), {seed['guard_name']} s item → "
                         f"(r3Step s item).{seed['destination']} = {seed['local_expected']}")
            proof = f"by intro s item h; exact {seed['local_lemma']} s item h"
            properties.append(_property_base(benchmark, seed, pid, "SINGLE_CYCLE", "SINGLE_CYCLE",
                                               statement, ["SINGLE_CYCLE"], [proof]))

        trace_specs = [
            ("r3_trace_run_append", "∀ (s : %s) (xs ys : List %s), run s (xs ++ ys) = run (run s xs) ys" %
             (state, item_type), "r3_model_run_append"),
            ("r3_trace_reachable_extraction", "∀ (s : %s), Reachable s → ∃ xs : List %s, run init xs = s" %
             (state, item_type), "r3_reachable_trace"),
        ]
        if multi_clock:
            trace_specs.append(("r3_trace_reachable_extension",
                f"∀ (s : {state}), Reachable s → (i : {benchmark.top_module}Inputs) → "
                "(event : ClockEvent) → Reachable (step s i event)", "r3_reachable_extend"))
        else:
            trace_specs.append(("r3_trace_reachable_extension",
                f"∀ (s : {state}), Reachable s → (i : {item_type}) → Reachable (step s i)",
                "r3_reachable_extend"))
        for pid, statement, lemma in trace_specs:
            item = _property_base(benchmark, None, pid, "TRACE_BRIDGE", "TRACE_BRIDGE",
                                  statement, ["TRACE_BRIDGE"], [f"by exact {lemma}"])
            item["foundation_lemmas"] = [lemma]
            item["trace_bridge_trivial"] = pid == "r3_trace_reachable_extraction"
            properties.append(item)

    if updates:
        seed = updates[0]
        field, guard, local = seed["destination"], seed["guard_name"], seed["local_lemma"]
        expected1 = _expected_at(seed, "s", "i1")
        expected2 = _expected_at(seed, "(r3Step s i1)", "i2")
        pid = f"r3_implication_two_step_{_safe(field)}"
        statement = (f"∀ (s : {state}) (i1 i2 : {item_type}), {guard} s i1 → "
                     f"{guard} (r3Step s i1) i2 → "
                     f"((r3Step s i1).{field} = {expected1} ∧ "
                     f"(r3Step (r3Step s i1) i2).{field} = {expected2})")
        proof = (f"by intro s i1 i2 h1 h2; exact ⟨{local} s i1 h1, "
                 f"{local} (r3Step s i1) i2 h2⟩")
        properties.append(_property_base(benchmark, seed, pid, "TRUE_MULTI_CYCLE", "IMPLICATION",
                                           statement, ["TRUE_MULTI_CYCLE"], [proof]))

    if updates:
        seed = updates[min(1, len(updates) - 1)]
        field, guard, local = seed["destination"], seed["guard_name"], seed["local_lemma"]
        expected = f"(fun t x => {_expected_at(seed, 't', 'x')})"
        obs = f"(fun t => t.{field})"
        pid = f"r3_recursive_preservation_{_safe(field)}"
        statement = (f"∀ (s : {state}) (xs : List {item_type}), 2 ≤ xs.length → "
                     f"R3Temporal.Along r3Step {guard} s xs → "
                     f"R3Temporal.Obeys r3Step {guard} {expected} {obs} s xs")
        proof = (f"by intro s xs _ h; exact R3Temporal.obeys_of_along r3Step {guard} "
                 f"{expected} {obs} {local} s xs h")
        properties.append(_property_base(benchmark, seed, pid, "TRUE_MULTI_CYCLE", "RECURSIVE",
                                           statement, ["TRUE_MULTI_CYCLE"], [proof]))

    if updates:
        seed = updates[min(2, len(updates) - 1)]
        field, guard, local = seed["destination"], seed["guard_name"], seed["local_lemma"]
        expected = f"(fun t x => {_expected_at(seed, 't', 'x')})"
        obs = f"(fun t => t.{field})"
        pid = f"r3_invariant_prefix_{_safe(field)}"
        statement = (f"∀ (s : {state}) (xs : List {item_type}), 2 ≤ xs.length → "
                     f"R3Temporal.Along r3Step {guard} s xs → ∀ k, k ≤ xs.length → "
                     f"R3Temporal.Obeys r3Step {guard} {expected} {obs} s (xs.take k)")
        proof = (f"by intro s xs _ h k hk; exact R3Temporal.obeys_take r3Step {guard} "
                 f"{expected} {obs} s xs k "
                 f"(R3Temporal.obeys_of_along r3Step {guard} {expected} {obs} {local} s xs h)")
        properties.append(_property_base(benchmark, seed, pid, "TRUE_MULTI_CYCLE", "INVARIANT",
                                           statement, ["TRUE_MULTI_CYCLE"], [proof]))

    if updates:
        seed = updates[0]
        field, guard, local = seed["destination"], seed["guard_name"], seed["local_lemma"]
        trigger_state = "(r3Run s pre)"
        expected = _expected_at(seed, trigger_state, "item")
        predicate = f"(fun t => t.{field} = {expected})"
        pid = f"r3_eventually_update_{_safe(field)}"
        statement = (f"∀ (s : {state}) (pre suffix : List {item_type}) (item : {item_type}), "
                     f"1 ≤ pre.length → {guard} {trigger_state} item → "
                     f"R3Temporal.Eventually r3Step {predicate} s (pre ++ item :: suffix)")
        proof = (f"by intro s pre suffix item _ h; simpa [r3Run] using "
                 f"(R3Temporal.eventually_after_prefix r3Step {predicate} s pre suffix item "
                 f"({local} {trigger_state} item h))")
        prop = _property_base(benchmark, seed, pid, "TRUE_MULTI_CYCLE", "EVENTUALLY",
                              statement, ["TRUE_MULTI_CYCLE", "SYMBOLIC_CYCLE"], [proof])
        prop.update({"symbolic_cycle": True, "completion_cycle_kind": "SYMBOLIC_START_POSITION",
                     "environment_assumptions": ["the IR-derived update trigger occurs after a nonempty prefix"]})
        properties.append(prop)

        bound = _counter_bound(benchmark, output_root)
        if bound:
            pid = f"r3_bounded_eventually_update_{_safe(field)}"
            statement = (f"∀ (s : {state}) (pre suffix : List {item_type}) (item : {item_type}), "
                         f"1 ≤ pre.length → pre.length + 1 ≤ {bound['upper']} → "
                         f"{guard} {trigger_state} item → "
                         f"R3Temporal.BoundedEventually r3Step {predicate} {bound['upper']} s "
                         f"(pre ++ item :: suffix)")
            proof = (f"by intro s pre suffix item _ hb h; simpa [r3Run] using "
                     f"(R3Temporal.bounded_eventually_after_prefix r3Step {predicate} "
                     f"{bound['upper']} s pre suffix item hb ({local} {trigger_state} item h))")
            prop = _property_base(benchmark, seed, pid, "TRUE_MULTI_CYCLE", "BOUNDED_EVENTUALLY",
                                  statement, ["TRUE_MULTI_CYCLE", "BOUNDED_EVENTUALLY", "SYMBOLIC_CYCLE"], [proof])
            prop.update({"trace_upper_bound": bound["upper"], "bound_source": bound["source"],
                         "symbolic_cycle": True,
                         "completion_cycle_kind": "BOUNDED_EXISTENTIAL_COMPLETION",
                         "environment_assumptions": [
                             "the IR-derived trigger occurs within the counter-representable bound"
                         ]})
            properties.append(prop)
        else:
            rejected.append({"dut": benchmark.design_id, "property_family": "BOUNDED_EVENTUALLY",
                             "reason": "NO_RTL_COUNTER_OR_CONTROL_BOUND"})

    rejected.append({"dut": benchmark.design_id, "property_family": "UNTIL",
                     "reason": (
                         "POST_COMB_REGISTER_PRESERVATION_NOT_AVAILABLE_AS_A_TRACTABLE_KERNEL_LEMMA; "
                         "no artificial state-stability assumption was added"
                     )})

    return properties, rejected


def generate_aes_high_complexity(
    benchmark: Benchmark, seeds: list[dict[str, Any]], output_root: Path,
) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    updates = sorted([s for s in seeds if s["branch_kind"] == "update"],
                     key=lambda s: (-s["width"], s["seed_id"]))
    rejected: list[dict[str, Any]] = []
    if not updates:
        return [], [{"complexity": "ALL", "reason": "NO_KERNEL_VALIDATED_UPDATE_PATH"}]
    widest = updates[0]
    if widest["width"] < 128:
        rejected.append({"complexity": "WIDE_DATA", "reason": "NO_VALIDATED_128_BIT_STATE_PATH",
                         "observed_max_width": widest["width"]})
    control = next((s for s in updates if s["semantic_role"] == "CONTROL"), widest)
    bound = _counter_bound(benchmark, output_root, minimum_upper=8)
    if not bound or bound["upper"] < 8:
        rejected.append({"complexity": "LONG_TEMPORAL", "reason": "NO_CONTROL_BOUND_SUPPORTING_EIGHT_STEPS"})
        return [], rejected
    minimum = 8
    state = _state_type(benchmark)
    item_type = _item_type(benchmark, False)
    properties: list[dict[str, Any]] = []

    def invariant(seed: dict[str, Any], pid: str, tags: list[str], symbolic: bool,
                  lower: int) -> dict[str, Any]:
        field, guard, local = seed["destination"], seed["guard_name"], seed["local_lemma"]
        expected = f"(fun t x => {_expected_at(seed, 't', 'x')})"
        obs = f"(fun t => t.{field})"
        if symbolic:
            statement = (f"∀ (pre trace : List {item_type}), {lower} ≤ trace.length → "
                         f"R3Temporal.Along r3Step {guard} (r3Run init pre) trace → "
                         f"R3Temporal.Obeys r3Step {guard} {expected} {obs} "
                         f"(r3Run init pre) trace")
            proof = (f"by intro pre trace _ h; exact R3Temporal.obeys_of_along r3Step "
                     f"{guard} {expected} {obs} {local} (r3Run init pre) trace h")
        else:
            statement = (f"∀ (s : {state}) (trace : List {item_type}), {lower} ≤ trace.length → "
                         f"R3Temporal.Along r3Step {guard} s trace → "
                         f"R3Temporal.Obeys r3Step {guard} {expected} {obs} s trace")
            proof = (f"by intro s trace _ h; exact R3Temporal.obeys_of_along r3Step "
                     f"{guard} {expected} {obs} {local} s trace h")
        prop = _property_base(benchmark, seed, pid, "TRUE_MULTI_CYCLE", "INVARIANT",
                              statement, ["TRUE_MULTI_CYCLE", *tags], [proof])
        prop.update({"semantic_transition_count": lower, "minimum_required_transitions": lower,
                     "trace_lower_bound": lower, "trace_upper_bound": bound["upper"],
                     "bound_source": bound["source"], "observed_temporal_span": f">={lower}",
                     "symbolic_cycle": symbolic,
                     "completion_cycle_kind": "SYMBOLIC_START_POSITION" if symbolic else "FIXED_RELATIVE_LATENCY"})
        return prop

    properties.append(invariant(control, "r3_aes_long_temporal_control", ["LONG_TEMPORAL"], False, minimum))
    if widest["width"] >= 128:
        properties.append(invariant(widest, "r3_aes_wide_data_invariant", ["WIDE_DATA"], False, 2))
        properties.append(invariant(widest, "r3_aes_symbolic_start_wide", ["WIDE_DATA", "SYMBOLIC_CYCLE"], True, 2))
        properties.append(invariant(widest, "r3_aes_long_wide_symbolic",
                                    ["LONG_TEMPORAL", "WIDE_DATA", "SYMBOLIC_CYCLE"], True, minimum))
    rejected.append({"complexity": "VARIABLE_COMPLETION", "reason": (
        "No RTL-derived stall/handshake-dependent AES completion bound was proven; "
        "symbolic absolute start is retained without claiming variable RTL latency."
    )})
    return properties, rejected


def generate_multiclock_properties(
    benchmark: Benchmark, seeds: list[dict[str, Any]], output_root: Path,
) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    design = json.loads((output_root / benchmark.slug / "ir" / "design.json").read_text(encoding="utf-8"))
    cross = design["module"]["cross_clock_dependencies"]
    seed_by_process: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for seed in seeds:
        seed_by_process[seed["source_function"]].append(seed)
    chosen: dict[tuple[str, str], tuple[dict[str, Any], dict[str, Any]]] = {}
    rejected = []
    for dep in cross:
        for source_clock in dep["source_clocks"]:
            key = (source_clock, dep["destination_clock"])
            if source_clock == dep["destination_clock"] or key in chosen:
                continue
            matches = [
                seed for seed in seed_by_process.get(dep["reader_process"], [])
                if dep["signal"] in seed.get("condition_uses", [])
                or dep["signal"] in seed.get("branch_uses", [])
            ]
            if matches:
                chosen[key] = (min(matches, key=lambda s: (
                    0 if dep["signal"] in s.get("branch_uses", [])
                    and s["branch_kind"] == "update" else 1,
                    0 if s["branch_kind"] == "update" else 1,
                    s["expression_size"], s["seed_id"],
                )), dep)
    properties = []
    state = _state_type(benchmark)
    for (source_clock, destination_clock), (seed, dep) in sorted(chosen.items()):
        field = seed["destination"]
        src_event, dst_event = _clock_event(source_clock), _clock_event(destination_clock)
        pid = f"r3_multiclock_{_safe(source_clock)}_to_{_safe(destination_clock)}_{_safe(field)}"
        first = f"(srcInput, .{src_event})"
        second = f"(dstInput, .{dst_event})"
        after_source = f"(r3Step s {first})"
        expected = _instantiate(seed["branch_process"], after_source, "dstInput")
        statement = (f"∀ (s : {state}) (srcInput dstInput : {benchmark.top_module}Inputs), "
                     f"{seed['guard_name']} {after_source} {second} → "
                     f"(r3Step {after_source} {second}).{field} = {expected}")
        proof = (f"by intro s srcInput dstInput h; exact {seed['local_lemma']} "
                 f"{after_source} {second} h")
        prop = _property_base(benchmark, seed, pid, "TRUE_MULTI_CYCLE", "MULTI_CLOCK_TEMPORAL",
                              statement, ["TRUE_MULTI_CYCLE", "MULTI_CLOCK_TEMPORAL"], [proof])
        prop.update({
            "semantic_transition_count": 2, "minimum_required_transitions": 2,
            "clock_domain": [source_clock, destination_clock], "clock_domain_count": 2,
            "trace_structure": [first, second], "event_ordering": [source_clock, destination_clock],
            "cross_clock_dependency": dep,
            "cross_clock_signal_in_guard": dep["signal"] in seed.get("condition_uses", []),
            "cross_clock_signal_in_branch_value": dep["signal"] in seed.get("branch_uses", []),
            "environment_assumptions": [
                f"source event {source_clock} occurs before destination event {destination_clock}",
                "destination-domain IR hold guard is true after the source event",
            ],
        })
        properties.append(prop)
    observed_pairs = {(dep_clock, dst_clock) for dep_clock, dst_clock in chosen}
    all_pairs = {(src, dep["destination_clock"]) for dep in cross for src in dep["source_clocks"]
                 if src != dep["destination_clock"]}
    for pair in sorted(all_pairs - observed_pairs):
        rejected.append({"property_family": "MULTI_CLOCK_TEMPORAL", "clock_pair": pair,
                         "reason": "NO_VALIDATED_READER_HOLD_GUARD_REFERENCING_CROSS_DOMAIN_SIGNAL"})
    return properties, rejected


def build_temporal_corpus(
    benchmarks: list[Benchmark], output_root: Path, requirement_root: Path,
    foundation_builder,
) -> dict[str, Any]:
    all_candidates: list[dict[str, Any]] = []
    final: list[dict[str, Any]] = []
    rejected: list[dict[str, Any]] = []
    foundations = []
    aes_tags = []
    multi_clock_semantics = []
    for benchmark in benchmarks:
        candidates = discover_transition_candidates(benchmark, output_root)
        selected, structural_rejected = select_structural_seeds(candidates)
        cross_clock_selected = select_cross_clock_seeds(candidates, benchmark, output_root)
        selected_by_id = {item["seed_id"]: item for item in selected}
        for item in cross_clock_selected:
            selected_by_id[item["seed_id"]] = item
        selected = [selected_by_id[name] for name in sorted(selected_by_id)]
        selected_ids = set(selected_by_id)
        structural_rejected = [
            item for item in structural_rejected if item["seed_id"] not in selected_ids
        ]
        foundation = foundation_builder(benchmark, selected, output_root, requirement_root)
        accepted = foundation["accepted_seeds"]
        all_candidates.extend(candidates)
        rejected.extend(structural_rejected)
        rejected.extend(foundation["rejected_seeds"])
        foundations.append({"dut": benchmark.design_id, "slug": benchmark.slug,
                            "accepted_seed_count": len(accepted),
                            "rejected_seed_count": len(candidates) - len(accepted),
                            "foundation_path": foundation["foundation_path"]})
        aes_mode = "aes" in benchmark.categories
        properties, family_rejected = generate_temporal_properties(
            benchmark, accepted, output_root, aes_mode,
        )
        final.extend(properties)
        rejected.extend(family_rejected)
        if aes_mode:
            high, high_rejected = generate_aes_high_complexity(benchmark, accepted, output_root)
            final.extend(high)
            rejected.extend({"dut": benchmark.design_id, **item} for item in high_rejected)
            aes_tags.extend({"property_id": item["property_id"], "tags": item["tags"],
                             "minimum_required_transitions": item["minimum_required_transitions"],
                             "max_signal_width": item["max_signal_width"],
                             "bound_source": item["bound_source"]} for item in high)
        if len(json.loads((output_root / benchmark.slug / "ir" / "design.json").read_text())
               ["module"]["clock_domains"]) > 1:
            multi, multi_rejected = generate_multiclock_properties(benchmark, accepted, output_root)
            final.extend(multi)
            rejected.extend({"dut": benchmark.design_id, **item} for item in multi_rejected)
            typed = json.loads((output_root / benchmark.slug / "ir" / "design.json").read_text())
            multi_clock_semantics.append({
                "dut": benchmark.design_id,
                "clock_domains": typed["module"]["clock_domains"],
                "cross_clock_dependencies": typed["module"]["cross_clock_dependencies"],
                "event_ordering": "one explicit ClockEvent per runEvents list element; list order is execution order",
                "same_time_event_policy": "simultaneous edges are represented by an explicit deterministic event order",
                "clock_local_input_sampling": "each event samples its paired Inputs value",
                "state_visibility": "later register events recompute comb and observe all registers committed by earlier events",
                "step_event_sequence": "Requirement-3 register event: comb(pre) -> commitEvent(selected domain)",
                "post_settle_policy": (
                    "derived combinational wires are not persistent temporal state; the next event recomputes comb. "
                    "The original comb->commitEvent->comb step remains available to TRACE_BRIDGE."
                ),
            })

    ids = [(item["dut"], item["property_id"]) for item in final]
    if len(ids) != len(set(ids)):
        raise RuntimeError("temporal generated duplicate property identifiers")
    payload = {
        "schema": "rtl2lean-temporal-corpus-v1",
        "selection_rule": (
            "kernel-validated non-reset Typed-IR branch representatives by discovered clock/semantic role; "
            "family generation is conditional on real hold/update pairs, counter bounds, widths, and cross-clock edges"
        ),
        "frozen_before_baseline": False,
        "freeze_status": "PENDING_KERNEL_VALIDATION",
        "properties": final, "foundations": foundations,
        "metrics": {
            "N_CANDIDATES": len(all_candidates), "N_FINAL": len(final),
            "N_REJECTED": len(rejected),
            "N_SINGLE_CYCLE": sum(item["property_level"] == "SINGLE_CYCLE" for item in final),
            "N_TRACE_BRIDGE": sum(item["property_level"] == "TRACE_BRIDGE" for item in final),
            "N_TRUE_MULTI_CYCLE": sum(item["semantic_multi_cycle"] for item in final),
        },
    }
    corpus_root = requirement_root / "corpus"
    write_json(corpus_root / "all_candidates.json", {"candidates": all_candidates})
    write_json(corpus_root / "final_properties.json", payload)
    write_json(corpus_root / "rejected_properties.json", {"properties": rejected})
    write_json(corpus_root / "property_classification.json", {
        "properties": [{"dut": item["dut"], "property_id": item["property_id"],
                        "level": item["property_level"], "family": item["property_family"],
                        "tags": item["tags"], "syntactic_multi_cycle": item["syntactic_multi_cycle"],
                        "semantic_multi_cycle": item["semantic_multi_cycle"]} for item in final],
    })
    write_json(corpus_root / "aes_complexity_tags.json", {"properties": aes_tags})
    write_json(requirement_root / "multi_clock" / "execution_semantics.json", {
        "schema": "rtl2lean-temporal-multiclock-semantics-v1",
        "models": multi_clock_semantics,
    })
    return payload
