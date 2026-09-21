"""Independent temporal_challenges proof foundation.

The generated ``R4Foundation`` imports, but never rewrites, the frozen
temporal foundation.  DUT-local hold chains are emitted only from a
matched hold/update pair discovered in Typed IR and already kernel-validated
as R3 local-step lemmas.
"""
from __future__ import annotations

import re
from pathlib import Path
from typing import Any

from rtl2lean.evaluation.experiment import _lean_check
from rtl2lean.pipeline.compiler import kernel_check
from rtl2lean.pipeline.io import write_json
from rtl2lean.pipeline.manifest import Benchmark


def _safe(value: str) -> str:
    value = re.sub(r"[^A-Za-z0-9_]", "_", value)
    return value if value and value[0].isalpha() else "n_" + value


def _item_type(benchmark: Benchmark, seed: dict[str, Any]) -> str:
    return "EventInput" if seed.get("multi_clock_model") else f"{benchmark.top_module}Inputs"


def _input_expr(seed: dict[str, Any], item: str = "item") -> str:
    return f"({item}).1" if seed.get("multi_clock_model") else item


def _expected_at(seed: dict[str, Any], state: str, item: str) -> str:
    expression = seed["branch_process"]
    input_value = f"({item}).1" if seed.get("multi_clock_model") else item
    expression = re.sub(r"\bs\.", f"(comb {state} {input_value}).", expression)
    return re.sub(r"\bi\.", f"({input_value}).", expression)


def chain_names(seed: dict[str, Any]) -> dict[str, str]:
    stem = f"r4_{_safe(seed['destination'])}"
    return {
        "post_comb_hold": stem + "_post_comb_hold",
        "register_hold": stem + "_register_hold",
        "state_preservation": stem + "_state_preservation",
        "prefix_preservation": stem + "_prefix_preservation",
        "completion_witness": stem + "_completion_witness",
    }


def _chain_source(benchmark: Benchmark, hold: dict[str, Any], update: dict[str, Any]) -> str:
    state = f"{benchmark.top_module}State"
    inputs = f"{benchmark.top_module}Inputs"
    item_type = _item_type(benchmark, hold)
    field = hold["destination"]
    width = hold["width"]
    names = chain_names(hold)
    expected = _expected_at(update, "(r3Run s pre)", "item")
    input_expr = _input_expr(hold)
    return f'''import R3Foundation

set_option maxRecDepth 100000
set_option maxHeartbeats 8000000

namespace {benchmark.top_module}Verification
open {benchmark.top_module}

theorem {names["post_comb_hold"]} :
    ∀ (s : {state}) (i : {inputs}),
      (comb s i).{field} = s.{field} := by
  intro s i
  rfl

theorem {names["register_hold"]} :
    ∀ (s : {state}) (item : {item_type}),
      {hold["guard_name"]} s item →
      (r3Step s item).{field} = s.{field} := by
  intro s item h
  rw [{hold["local_lemma"]} s item h]
  exact {names["post_comb_hold"]} s {input_expr}

theorem {names["state_preservation"]} :
    ∀ (anchor : BitVec {width}) (s : {state}) (item : {item_type}),
      s.{field} = anchor →
      {hold["guard_name"]} s item →
      (r3Step s item).{field} = anchor := by
  intro anchor s item hs hhold
  exact ({names["register_hold"]} s item hhold).trans hs

theorem {names["prefix_preservation"]} :
    ∀ (anchor : BitVec {width}) (s : {state}) (pre : List {item_type}),
      s.{field} = anchor →
      R3Temporal.Along r3Step {hold["guard_name"]} s pre →
      ∀ k, k ≤ pre.length →
        (r3Run s (pre.take k)).{field} = anchor := by
  intro anchor s pre hs halong k hk
  have h := R3Temporal.prefix_observe_preserved
    r3Step {hold["guard_name"]} (fun t => t.{field})
    {names["register_hold"]} s pre halong k hk
  exact h.trans hs

theorem {names["completion_witness"]} :
    ∀ (s : {state}) (pre suffix : List {item_type}) (item : {item_type}),
      {update["guard_name"]} (r3Run s pre) item →
      ∃ k,
        k = pre.length + 1 ∧
        k ≤ (pre ++ item :: suffix).length ∧
        (r3Run s ((pre ++ item :: suffix).take k)).{field} = {expected} := by
  intro s pre suffix item hupdate
  refine ⟨pre.length + 1, rfl, by simp, ?_⟩
  rw [List.take_length_add_append]
  rw [r3_run_append]
  change (r3Step (r3Run s pre) item).{field} = {expected}
  exact {update["local_lemma"]} (r3Run s pre) item hupdate

end {benchmark.top_module}Verification
'''


def build_temporal_challenges_foundations(
    benchmarks: list[Benchmark], output_root: Path, requirement_root: Path,
    until_pair: tuple[Benchmark, dict[str, Any], dict[str, Any]] | None,
) -> dict[str, Any]:
    """Build R4Foundation for every DUT and kernel-check the selected hold chain."""
    rows: list[dict[str, Any]] = []
    for benchmark in benchmarks:
        model_dir = output_root / benchmark.slug / "model"
        path = model_dir / "R4Foundation.lean"
        selected = until_pair and until_pair[0].design_id == benchmark.design_id
        if selected:
            _, hold, update = until_pair
            source = _chain_source(benchmark, hold, update)
        else:
            source = "\n".join([
                "import R3Foundation", "", "set_option maxRecDepth 100000",
                "set_option maxHeartbeats 8000000", "",
            ])
        path.write_text(source, encoding="utf-8")
        check = kernel_check(path, timeout_s=1200, build_olean=True)
        write_json(model_dir / "r4_foundation_check.json", check)
        row: dict[str, Any] = {
            "dut": benchmark.design_id,
            "foundation_path": str(path.resolve()),
            "kernel_check": check,
            "selected_until_chain": bool(selected),
            "source_import": "R3Foundation",
        }
        if selected:
            row.update({
                "hold_seed": hold["seed_id"], "update_seed": update["seed_id"],
                "destination": hold["destination"], "chain_lemmas": chain_names(hold),
            })
        rows.append(row)
        if not check["success"]:
            raise RuntimeError(
                f"temporal_challenges foundation rejected for {benchmark.design_id}: "
                + (check.get("stdout", "") + check.get("stderr", ""))[-6000:]
            )
    payload = {"schema": "rtl2lean-temporal_challenges-foundation-v1", "foundations": rows}
    write_json(requirement_root / "until" / "foundation_checks.json", payload)
    return payload


def probe_until_pair(
    benchmark: Benchmark, hold: dict[str, Any], update: dict[str, Any],
    output_root: Path, requirement_root: Path,
) -> dict[str, Any]:
    """Kernel-check one automatically selected real hold/update chain before freeze."""
    path = requirement_root / "until" / "probes" / benchmark.slug / f"{_safe(hold['destination'])}.lean"
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(_chain_source(benchmark, hold, update), encoding="utf-8")
    check = _lean_check(path, output_root / benchmark.slug / "model", timeout_s=1200)
    return {
        "dut": benchmark.design_id, "hold_seed": hold["seed_id"],
        "update_seed": update["seed_id"], "destination": hold["destination"],
        "source": str(path.resolve()), "check": check,
    }
