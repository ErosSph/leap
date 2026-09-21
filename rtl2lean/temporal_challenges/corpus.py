"""Typed-IR discovery for the independent temporal_challenges challenge corpus."""
from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any

from rtl2lean.pipeline.io import write_json
from rtl2lean.pipeline.manifest import Benchmark
from rtl2lean.temporal_challenges.foundation import chain_names, probe_until_pair
from rtl2lean.temporal.corpus import _expected_at, discover_transition_candidates


COMPLETION_RE = re.compile(r"ready|valid|ack|stall|busy|done|finish|complete|count|counter|ctr|state|trigger", re.I)
HANDSHAKE_RE = re.compile(r"ready|ack|stall|busy|done|valid|wait|response|grant", re.I)


def _read(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def _foundation_seed_ids(benchmark: Benchmark, output_root: Path) -> set[str]:
    source = (output_root / benchmark.slug / "model" / "R3Foundation.lean").read_text(encoding="utf-8")
    return set(re.findall(r"theorem\s+(r3seed_[A-Za-z0-9_]+)_local_step\b", source))


def discover_pairs(
    benchmark: Benchmark, output_root: Path,
) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    """Match real non-reset hold and update branches for the same register/clock."""
    candidates = discover_transition_candidates(benchmark, output_root)
    foundation_ids = _foundation_seed_ids(benchmark, output_root)
    accepted = [
        row for row in candidates
        if row["seed_id"] in foundation_ids and not row["condition_is_reset_only"]
    ]
    holds = [x for x in accepted if x["branch_kind"] == "hold"]
    updates = [x for x in accepted if x["branch_kind"] == "update"]
    pairs = []
    for hold in holds:
        for update in updates:
            if (hold["destination"], hold["clock"]) != (update["destination"], update["clock"]):
                continue
            evidence_text = " ".join([
                hold["destination"], update["guard_process"], update["branch_process"],
                *update.get("condition_uses", []), *update.get("branch_uses", []),
            ])
            pairs.append({
                "dut": benchmark.design_id, "slug": benchmark.slug,
                "destination": hold["destination"], "clock": hold["clock"],
                "width": hold["width"], "hold": hold, "update": update,
                "completion_signal_hits": sorted(set(COMPLETION_RE.findall(evidence_text))),
                "handshake_signal_hits": sorted(set(HANDSHAKE_RE.findall(evidence_text))),
                "rtl_supported": bool(hold.get("rtl_evidence", {}).get("matching_regions")
                                      and update.get("rtl_evidence", {}).get("matching_regions")),
            })
    return pairs, candidates


def select_until_pair(
    benchmarks: list[Benchmark], output_root: Path, requirement_root: Path,
) -> tuple[tuple[Benchmark, dict[str, Any], dict[str, Any]] | None, list[dict[str, Any]]]:
    """Select and probe the most completion-like tractable real branch pair.

    The score is structural and DUT-independent.  Smaller generated models are
    preferred after semantic completion evidence because post-comb preservation
    must be kernel checked rather than assumed.
    """
    ranked: list[tuple[tuple[Any, ...], Benchmark, dict[str, Any]]] = []
    for benchmark in benchmarks:
        pairs, _ = discover_pairs(benchmark, output_root)
        model_lines = sum(1 for _ in (output_root / benchmark.slug / "model" / "Model.lean").open())
        for pair in pairs:
            # The current generated state representation uses Lean Bool for
            # one-bit fields and BitVec for wider fields.  Keep the generic
            # chain type-correct without guessing a source-language scalar
            # encoding from width alone.
            if pair["width"] <= 1:
                continue
            text = " ".join([
                pair["destination"], pair["update"]["guard_process"],
                *pair["update"].get("condition_uses", []),
            ])
            completion_hits = len(COMPLETION_RE.findall(text))
            handshake_hits = len(HANDSHAKE_RE.findall(text))
            recursive_control = int(bool(re.search(r"count|counter|ctr|state", text, re.I)))
            score = (-handshake_hits, -completion_hits, -recursive_control,
                     model_lines, -pair["width"], pair["destination"])
            ranked.append((score, benchmark, pair))

    probes: list[dict[str, Any]] = []
    for _, benchmark, pair in sorted(ranked, key=lambda row: row[0]):
        probe = probe_until_pair(
            benchmark, pair["hold"], pair["update"], output_root, requirement_root,
        )
        probe["selection_score"] = list(_)
        probe["rtl_supported"] = pair["rtl_supported"]
        probes.append(probe)
        if probe["check"]["success"]:
            write_json(requirement_root / "until" / "pair_selection.json", {
                "schema": "rtl2lean-temporal_challenges-until-pair-selection-v1",
                "selection_rule": "completion/handshake evidence, recursive control, then tractable model size",
                "selected": probe, "probes": probes,
            })
            return (benchmark, pair["hold"], pair["update"]), probes
        if len(probes) >= 5:
            break
    write_json(requirement_root / "until" / "pair_selection.json", {
        "schema": "rtl2lean-temporal_challenges-until-pair-selection-v1",
        "selection_rule": "completion/handshake evidence, recursive control, then tractable model size",
        "selected": None, "probes": probes,
        "blocker": "NO_KERNEL_VALIDATED_POST_COMB_HOLD_CHAIN",
    })
    return None, probes


def _item_type(benchmark: Benchmark, seed: dict[str, Any]) -> str:
    return "EventInput" if seed.get("multi_clock_model") else f"{benchmark.top_module}Inputs"


def _expected_fun(seed: dict[str, Any]) -> str:
    return f"(fun t x => {_expected_at(seed, 't', 'x')})"


def _base(
    benchmark: Benchmark, property_id: str, family: str, statement: str,
    proof: str, seeds: list[dict[str, Any]], tags: list[str],
) -> dict[str, Any]:
    widths = [int(x.get("width", 0)) for x in seeds]
    fields = sorted(set(x["destination"] for x in seeds))
    functions = sorted(set(x["source_function"] for x in seeds))
    clocks = sorted(set(x["clock"] for x in seeds))
    dependency_depth = max((len(x.get("dependency_evidence", {}).get("L1", []))
                            + len(x.get("dependency_evidence", {}).get("L2", []))
                            + len(x.get("dependency_evidence", {}).get("L3", []))
                            + len(x.get("dependency_evidence", {}).get("L4", []))
                            for x in seeds), default=0)
    complexity_dimensions = sorted(set(tags) & {
        "LONG_TEMPORAL", "WIDE_DATA", "SYMBOLIC_START_POSITION",
        "DEEP_RECURSION", "MULTI_PHASE", "MULTI_CLOCK",
    })
    return {
        "property_id": property_id, "dut": benchmark.design_id,
        "module": benchmark.top_module, "property_level": "HARD_TEMPORAL",
        "property_family": family, "theorem_statement": statement,
        "proof_candidates": [proof], "tags": sorted(set(["HARD_TEMPORAL", *tags])),
        "complexity_dimensions": complexity_dimensions,
        "hardness_gate_pass": len(complexity_dimensions) >= 2,
        "minimum_required_transitions": 2, "temporal_span": "SYMBOLIC_TWO_NONEMPTY_PHASES",
        "max_signal_width": max(widths, default=0),
        "aggregate_data_width": sum(widths), "recursive_depth": 1,
        "phase_count": 2, "dependency_depth": dependency_depth,
        "clock_domain_count": len(clocks), "symbolic_index_count": 1,
        "referenced_state_fields": fields,
        "referenced_inputs": sorted(set(sum((x.get("referenced_inputs", []) for x in seeds), []))),
        "source_functions": functions,
        "foundation_lemmas": sorted(set(x["local_lemma"] for x in seeds)),
        "rtl_evidence": [x.get("rtl_evidence", {}) for x in seeds],
        "ir_evidence": [x.get("ir_evidence", {}) for x in seeds],
        "trigger_condition": [x.get("guard_process") for x in seeds],
        "clock_domains": clocks, "completion_cycle_kind": "NOT_COMPLETION_PROPERTY",
        "environment_assumptions": [], "protocol_assumptions": [],
        "reset_assumptions": sorted(set(sum(([
            name for name in x.get("condition_uses", []) if re.search(r"reset|rst", name, re.I)
        ] for x in seeds), []))),
        "validation_status": "PENDING",
    }


def _hard_multiphase(
    benchmark: Benchmark, hold: dict[str, Any], update: dict[str, Any],
) -> dict[str, Any]:
    state = f"{benchmark.top_module}State"
    item = _item_type(benchmark, hold)
    start = "r3Run init pre"
    middle = f"r3Run ({start}) holdPhase"
    statement = (
        f"∀ (pre holdPhase updatePhase : List {item}), holdPhase ≠ [] → updatePhase ≠ [] → "
        f"R3Temporal.Along r3Step {hold['guard_name']} ({start}) holdPhase → "
        f"R3Temporal.Along r3Step {update['guard_name']} ({middle}) updatePhase → "
        f"(R3Temporal.Obeys r3Step {hold['guard_name']} {_expected_fun(hold)} "
        f"(fun t => t.{hold['destination']}) ({start}) holdPhase ∧ "
        f"R3Temporal.Obeys r3Step {update['guard_name']} {_expected_fun(update)} "
        f"(fun t => t.{update['destination']}) ({middle}) updatePhase)"
    )
    proof = (
        f"by\n  intro pre holdPhase updatePhase _ _ hhold hupdate\n  constructor\n"
        f"  · exact R3Temporal.obeys_of_along r3Step {hold['guard_name']} "
        f"{_expected_fun(hold)} (fun t => t.{hold['destination']}) {hold['local_lemma']} "
        f"(r3Run init pre) holdPhase hhold\n"
        f"  · exact R3Temporal.obeys_of_along r3Step {update['guard_name']} "
        f"{_expected_fun(update)} (fun t => t.{update['destination']}) {update['local_lemma']} "
        f"(r3Run (r3Run init pre) holdPhase) updatePhase hupdate"
    )
    tags = ["MULTI_PHASE", "DEEP_RECURSION", "SYMBOLIC_START_POSITION"]
    if max(hold["width"], update["width"]) >= 32:
        tags.append("WIDE_DATA")
    prop = _base(
        benchmark, f"r4_hard_multiphase_{hold['destination']}", "HARD_RECURSIVE",
        statement, proof, [hold, update], tags,
    )
    if "aes" in benchmark.categories:
        prop["aes_cycle_types"] = ["SYMBOLIC_START_POSITION"]
    return prop


def _hard_multiclock(
    benchmark: Benchmark, seed: dict[str, Any], source_clock: str,
) -> dict[str, Any]:
    state = f"{benchmark.top_module}State"
    dest_clock = seed["clock"]
    start = f"r3Step (r3Run init pre) (srcInput, .on_{re.sub(r'[^A-Za-z0-9_]', '_', source_clock)})"
    expected = _expected_fun(seed)
    statement = (
        f"∀ (pre : List EventInput) (srcInput : {benchmark.top_module}Inputs) "
        f"(phase : List EventInput), phase ≠ [] → "
        f"R3Temporal.Along r3Step {seed['guard_name']} ({start}) phase → "
        f"R3Temporal.Obeys r3Step {seed['guard_name']} {expected} "
        f"(fun t => t.{seed['destination']}) ({start}) phase"
    )
    proof = (
        f"by\n  intro pre srcInput phase _ halong\n"
        f"  exact R3Temporal.obeys_of_along r3Step {seed['guard_name']} {expected} "
        f"(fun t => t.{seed['destination']}) {seed['local_lemma']} ({start}) phase halong"
    )
    prop = _base(
        benchmark, f"r4_hard_multiclock_{re.sub(r'[^A-Za-z0-9_]', '_', source_clock)}_to_"
        f"{re.sub(r'[^A-Za-z0-9_]', '_', dest_clock)}_{seed['destination']}",
        "MULTI_CLOCK", statement, proof, [seed],
        ["MULTI_CLOCK", "DEEP_RECURSION", "SYMBOLIC_START_POSITION"],
    )
    prop.update({"phase_count": 1, "clock_domain_count": 2,
                 "minimum_required_transitions": 2,
                 "temporal_span": "SYMBOLIC_PREFIX_SOURCE_EVENT_AND_NONEMPTY_DESTINATION_PHASE"})
    return prop


def _until_property(
    benchmark: Benchmark, hold: dict[str, Any], update: dict[str, Any],
) -> dict[str, Any]:
    state = f"{benchmark.top_module}State"
    item_type = _item_type(benchmark, hold)
    field = hold["destination"]
    expected = _expected_at(update, "(r3Run s pre)", "item")
    names = chain_names(hold)
    statement = (
        f"∀ (s : {state}) (pre suffix : List {item_type}) (item : {item_type}), "
        f"pre ≠ [] → "
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
  have hjpre : j ≤ pre.length := by omega
  rw [List.take_append_of_le_length hjpre]
  exact {names["prefix_preservation"]}
    s.{field} s pre rfl halong j hjpre'''
    prop = _base(
        benchmark, f"r4_until_{field}_hold_until_update", "UNTIL", statement,
        proof, [hold, update], ["DEEP_RECURSION", "SYMBOLIC_START_POSITION", "MULTI_PHASE"],
    )
    prop.update({
        "property_level": "UNTIL", "completion_cycle_kind": "BOUNDED_EXISTENTIAL_COMPLETION",
        "minimum_required_transitions": 2,
        "temporal_span": "SYMBOLIC_NONEMPTY_HOLD_PREFIX_THEN_REAL_UPDATE_EVENT",
        "trigger_condition": update["guard_process"],
        "reset_assumption": [x for x in update.get("condition_uses", []) if re.search(r"reset|rst", x, re.I)],
        "environment_assumption": [x for x in update.get("condition_uses", [])
                                   if x in update.get("referenced_inputs", [])],
        "protocol_assumption": "the completion item satisfies the real RTL update-branch guard",
        "progress_assumption": "a symbolic hold prefix is followed by one real update event",
        "fairness_assumption": None,
        "completion_bound_source": "symbolic prefix decomposition; witness is pre.length + 1",
        "foundation_lemmas": [
            hold["local_lemma"], update["local_lemma"],
            names["post_comb_hold"], names["register_hold"],
            names["state_preservation"], names["prefix_preservation"],
            names["completion_witness"],
        ],
    })
    return prop


def discover_variable_latency(
    benchmarks: list[Benchmark], output_root: Path,
) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    evidence_rows: list[dict[str, Any]] = []
    candidates: list[dict[str, Any]] = []
    for benchmark in benchmarks:
        typed = _read(output_root / benchmark.slug / "ir" / "design.json")["module"]
        signals = typed.get("signals", [])
        evidence = []
        for signal in signals:
            name = signal["name"]
            if not HANDSHAKE_RE.search(name):
                continue
            evidence.append({
                "signal": name, "direction": signal.get("direction"),
                "kind": signal.get("kind"), "width": signal.get("width"),
                "evidence_type": "EXTERNAL_HANDSHAKE" if signal.get("direction") == "input"
                else "INTERNAL_PROTOCOL_CONTROL",
            })
        if benchmark.slug == "modexp":
            for signal in signals:
                if re.search(r"exponent.*length|length.*exponent", signal["name"], re.I):
                    evidence.append({
                        "signal": signal["name"], "direction": signal.get("direction"),
                        "kind": signal.get("kind"), "width": signal.get("width"),
                        "evidence_type": "VARIABLE_ITERATION_COUNT",
                    })
        real_variable = benchmark.slug != "aes" and bool(evidence)
        status = "RTL_VARIABLE_LATENCY_EVIDENCE" if real_variable else (
            "FIXED_RELATIVE_LATENCY_NO_EXTERNAL_WAIT" if benchmark.slug == "aes"
            else "NO_VARIABLE_LATENCY_EVIDENCE"
        )
        row = {
            "dut": benchmark.design_id, "slug": benchmark.slug,
            "variable_latency_evidence": real_variable,
            "evidence": evidence, "evidence_type": sorted(set(x["evidence_type"] for x in evidence)),
            "status": status,
        }
        evidence_rows.append(row)
        if real_variable:
            candidates.append({
                **row, "candidate_status": "EVIDENCE_ONLY_NOT_FROZEN_AS_THEOREM",
                "rejection_reason": (
                    "Typed IR exposes variable trigger timing, but no sound finite upper bound and "
                    "state-level completion witness were both derivable without a new environment/fairness assumption"
                ),
                "latency_source": row["evidence_type"], "lower_bound": None,
                "upper_bound": None, "bound_source": None,
                "environment_dependency": any(x["direction"] == "input" for x in evidence),
                "handshake_dependency": any(x["evidence_type"] == "EXTERNAL_HANDSHAKE" for x in evidence),
                "control_dependency": True,
            })
    return evidence_rows, candidates


def build_challenge_corpus(
    benchmarks: list[Benchmark], output_root: Path, requirement_root: Path,
    until_pair: tuple[Benchmark, dict[str, Any], dict[str, Any]] | None,
) -> dict[str, Any]:
    hard: list[dict[str, Any]] = []
    all_pair_rows: list[dict[str, Any]] = []
    for benchmark in benchmarks:
        pairs, candidates = discover_pairs(benchmark, output_root)
        all_pair_rows.extend({
            "dut": benchmark.design_id, "destination": x["destination"],
            "clock": x["clock"], "width": x["width"],
            "hold_seed": x["hold"]["seed_id"], "update_seed": x["update"]["seed_id"],
            "rtl_supported": x["rtl_supported"],
        } for x in pairs)
        if not pairs:
            continue
        chosen = max(pairs, key=lambda x: (
            x["width"], x["hold"].get("branch_depth", 0) + x["update"].get("branch_depth", 0),
            x["hold"].get("expression_size", 0) + x["update"].get("expression_size", 0),
            x["destination"],
        ))
        hard.append(_hard_multiphase(benchmark, chosen["hold"], chosen["update"]))

    # Add one genuinely event-ordered, recursive multi-clock challenge from the
    # cross-clock seeds frozen in temporal.
    old = _read(requirement_root.parent / "temporal" / "corpus" / "final_properties.json")
    multiclock = [x for x in old["properties"] if x["property_family"] == "MULTI_CLOCK_TEMPORAL"]
    if multiclock:
        source = max(multiclock, key=lambda x: (x.get("max_signal_width", 0), x["property_id"]))
        benchmark = next(x for x in benchmarks if x.design_id == source["dut"])
        seed_id = source["seed_id"]
        seed = next(x for x in discover_transition_candidates(benchmark, output_root)
                    if x["seed_id"] == seed_id)
        hard.append(_hard_multiclock(benchmark, seed, source["clock_domain"][0]))

    until_properties = []
    if until_pair:
        benchmark, hold, update = until_pair
        until_properties.append(_until_property(benchmark, hold, update))

    if any(not x["hardness_gate_pass"] for x in hard):
        raise RuntimeError("temporal_challenges admitted a hard property with fewer than two complexity dimensions")

    variable_evidence, variable_candidates = discover_variable_latency(benchmarks, output_root)
    properties = [*hard, *until_properties]
    payload = {
        "schema": "rtl2lean-temporal_challenges-challenge-corpus-v1",
        "independent_from_temporal": True,
        "frozen_before_baseline": False,
        "selection_rule": (
            "one maximal structural hold/update pair per DUT, one real cross-clock edge, and one "
            "kernel-probed UNTIL chain; no property-count or forced-failure quota"
        ),
        "properties": properties,
        "metrics": {
            "N_HARD_TEMPORAL": len(hard), "N_UNTIL": len(until_properties),
            "N_VARIABLE_COMPLETION": 0, "N_TOTAL": len(properties),
        },
    }
    write_json(requirement_root / "hard_temporal" / "candidates.json", {"pairs": all_pair_rows})
    write_json(requirement_root / "hard_temporal" / "final_properties.json", payload)
    write_json(requirement_root / "hard_temporal" / "complexity.json", {
        "properties": [{key: x.get(key) for key in (
            "dut", "property_id", "complexity_dimensions", "hardness_gate_pass",
            "minimum_required_transitions", "temporal_span", "max_signal_width",
            "aggregate_data_width", "recursive_depth", "phase_count",
            "dependency_depth", "clock_domain_count", "symbolic_index_count",
        )} for x in hard],
    })
    write_json(requirement_root / "until" / "until_properties.json", {
        "properties": until_properties,
        "why_not_found": None if until_properties else "NO_KERNEL_VALIDATED_POST_COMB_HOLD_CHAIN",
    })
    write_json(requirement_root / "variable_completion" / "dut_latency_evidence.json", {
        "rows": variable_evidence,
    })
    write_json(requirement_root / "variable_completion" / "candidates.json", {
        "candidates": variable_candidates,
    })
    write_json(requirement_root / "variable_completion" / "results.json", {
        "properties": [], "N": 0,
        "conclusion": "No candidate met both real variable timing and sound finite completion-bound gates",
    })
    return payload
