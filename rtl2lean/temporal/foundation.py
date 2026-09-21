"""Generate and kernel-check the pre-frozen temporal foundation.

The common temporal calculus is DUT-independent.  DUT-local declarations are
mechanically specialized from Typed IR transition branches and explicit clock
domains; no module, signal, or property name is selected in this module.
"""
from __future__ import annotations

import json
import re
import time
from pathlib import Path
from typing import Any

from rtl2lean.evaluation.experiment import _lean_check
from rtl2lean.pipeline.compiler import kernel_check
from rtl2lean.pipeline.io import write_json
from rtl2lean.pipeline.manifest import Benchmark


COMMON_TEMPORAL_SOURCE = r'''import R2Framework

set_option maxRecDepth 100000
set_option maxHeartbeats 8000000

namespace R3Temporal

def exec (step : σ → ι → σ) (s : σ) (inputs : List ι) : σ :=
  inputs.foldl step s

def Along (step : σ → ι → σ) (guard : σ → ι → Prop) : σ → List ι → Prop
  | _, [] => True
  | s, i :: is => guard s i ∧ Along step guard (step s i) is

def Eventually (step : σ → ι → σ) (p : σ → Prop) (s : σ) (inputs : List ι) : Prop :=
  ∃ k, k ≤ inputs.length ∧ p (exec step s (inputs.take k))

def BoundedEventually (step : σ → ι → σ) (p : σ → Prop) (upper : Nat)
    (s : σ) (inputs : List ι) : Prop :=
  ∃ k, k ≤ upper ∧ k ≤ inputs.length ∧ p (exec step s (inputs.take k))

def Until (step : σ → ι → σ) (p q : σ → Prop) (s : σ) (inputs : List ι) : Prop :=
  ∃ k, k ≤ inputs.length ∧ q (exec step s (inputs.take k)) ∧
    ∀ j, j < k → p (exec step s (inputs.take j))

def Obeys (step : σ → ι → σ) (guard : σ → ι → Prop)
    (expected : σ → ι → α) (obs : σ → α) : σ → List ι → Prop
  | _, [] => True
  | s, i :: is => guard s i ∧ obs (step s i) = expected s i ∧
      Obeys step guard expected obs (step s i) is

theorem exec_append (step : σ → ι → σ) (s : σ) (xs ys : List ι) :
    exec step s (xs ++ ys) = exec step (exec step s xs) ys := by
  simp [exec, List.foldl_append]

theorem along_take
    (step : σ → ι → σ) (guard : σ → ι → Prop) :
    ∀ s xs n, Along step guard s xs → Along step guard s (xs.take n) := by
  intro s xs
  induction xs generalizing s with
  | nil => simp [Along]
  | cons i is ih =>
      intro n h
      cases n with
      | zero => simp [Along]
      | succ n =>
          rcases h with ⟨hg, hs⟩
          exact ⟨hg, ih (step s i) n hs⟩

theorem observe_preserved
    (step : σ → ι → σ) (guard : σ → ι → Prop) (obs : σ → α)
    (hstep : ∀ s i, guard s i → obs (step s i) = obs s) :
    ∀ s xs, Along step guard s xs → obs (exec step s xs) = obs s := by
  intro s xs
  induction xs generalizing s with
  | nil => simp [exec]
  | cons i is ih =>
      intro h
      rcases h with ⟨hguard, halong⟩
      rw [show exec step s (i :: is) = exec step (step s i) is by rfl]
      rw [ih (step s i) halong, hstep s i hguard]

theorem prefix_observe_preserved
    (step : σ → ι → σ) (guard : σ → ι → Prop) (obs : σ → α)
    (hstep : ∀ s i, guard s i → obs (step s i) = obs s)
    (s : σ) (xs : List ι) (halong : Along step guard s xs) :
    ∀ k, k ≤ xs.length → obs (exec step s (xs.take k)) = obs s := by
  intro k _
  exact observe_preserved step guard obs hstep s (xs.take k)
    (along_take step guard s xs k halong)

theorem two_step_preserved
    (step : σ → ι → σ) (guard : σ → ι → Prop) (obs : σ → α)
    (hstep : ∀ s i, guard s i → obs (step s i) = obs s)
    (s : σ) (i1 i2 : ι) (h1 : guard s i1) (h2 : guard (step s i1) i2) :
    obs (step (step s i1) i2) = obs s := by
  rw [hstep (step s i1) i2 h2, hstep s i1 h1]

theorem obeys_of_along
    (step : σ → ι → σ) (guard : σ → ι → Prop)
    (expected : σ → ι → α) (obs : σ → α)
    (hstep : ∀ s i, guard s i → obs (step s i) = expected s i) :
    ∀ s xs, Along step guard s xs → Obeys step guard expected obs s xs := by
  intro s xs
  induction xs generalizing s with
  | nil => simp [Obeys]
  | cons i is ih =>
      intro h
      rcases h with ⟨hg, hs⟩
      exact ⟨hg, hstep s i hg, ih (step s i) hs⟩

theorem obeys_take
    (step : σ → ι → σ) (guard : σ → ι → Prop)
    (expected : σ → ι → α) (obs : σ → α) :
    ∀ s xs n, Obeys step guard expected obs s xs →
      Obeys step guard expected obs s (xs.take n) := by
  intro s xs
  induction xs generalizing s with
  | nil => simp [Obeys]
  | cons i is ih =>
      intro n h
      cases n with
      | zero => simp [Obeys]
      | succ n =>
          rcases h with ⟨hg, he, hs⟩
          exact ⟨hg, he, ih (step s i) n hs⟩

theorem eventually_after_prefix
    (step : σ → ι → σ) (p : σ → Prop) (s : σ) (pre suffix : List ι) (i : ι)
    (hp : p (step (exec step s pre) i)) :
    Eventually step p s (pre ++ i :: suffix) := by
  refine ⟨pre.length + 1, ?_, ?_⟩
  · simp
  · rw [List.take_length_add_append]
    simpa [exec_append, exec] using hp

theorem bounded_eventually_after_prefix
    (step : σ → ι → σ) (p : σ → Prop) (upper : Nat)
    (s : σ) (pre suffix : List ι) (i : ι)
    (hbound : pre.length + 1 ≤ upper)
    (hp : p (step (exec step s pre) i)) :
    BoundedEventually step p upper s (pre ++ i :: suffix) := by
  refine ⟨pre.length + 1, hbound, ?_, ?_⟩
  · simp
  · rw [List.take_length_add_append]
    simpa [exec_append, exec] using hp

theorem until_after_prefix
    (step : σ → ι → σ) (guard : σ → ι → Prop) (obs : σ → α)
    (q : σ → Prop) (s : σ) (pre suffix : List ι) (i : ι)
    (hstep : ∀ t input, guard t input → obs (step t input) = obs t)
    (halong : Along step guard s pre)
    (hq : q (step (exec step s pre) i)) :
    Until step (fun t => obs t = obs s) q s (pre ++ i :: suffix) := by
  refine ⟨pre.length + 1, by simp, ?_, ?_⟩
  · rw [List.take_length_add_append]
    simpa [exec_append, exec] using hq
  · intro j hj
    have hle : j ≤ pre.length := by omega
    rw [List.take_append_of_le_length hle]
    exact observe_preserved step guard obs hstep s (pre.take j)
      (along_take step guard s pre j halong)

end R3Temporal
'''


def _safe(value: str) -> str:
    clean = re.sub(r"[^A-Za-z0-9_]", "_", value)
    return clean if clean and clean[0].isalpha() else "n_" + clean


def _is_multiclock(seed: dict[str, Any]) -> bool:
    return bool(seed.get("multi_clock_model"))


def _step_prelude(benchmark: Benchmark, multi_clock: bool) -> list[str]:
    state = f"{benchmark.top_module}State"
    if multi_clock:
        return [
            f"def r3Step (s : {state}) (item : EventInput) : {state} :=",
            "  commitEvent (comb s item.1) item.1 item.2",
            "",
            f"def r3Run (s : {state}) (items : List EventInput) : {state} :=",
            "  R3Temporal.exec r3Step s items",
            "",
        ]
    inputs = f"{benchmark.top_module}Inputs"
    return [
        f"def r3Step (s : {state}) (i : {inputs}) : {state} := commit (comb s i) i",
        "",
        f"def r3Run (s : {state}) (items : List {inputs}) : {state} :=",
        "  R3Temporal.exec r3Step s items",
        "",
    ]


def _trace_foundation(benchmark: Benchmark, multi_clock: bool) -> tuple[list[str], list[dict[str, str]]]:
    state = f"{benchmark.top_module}State"
    item = "EventInput" if multi_clock else f"{benchmark.top_module}Inputs"
    next_pattern = "@next s hs i event ih" if multi_clock else "@next s hs i ih"
    append_item = "(i, event)" if multi_clock else "i"
    lines = [
        f"theorem r3_run_eq_exec : ∀ (s : {state}) (xs : List {item}),",
        "    r3Run s xs = R3Temporal.exec r3Step s xs := by intro s xs; rfl",
        "",
        f"theorem r3_run_append : ∀ (s : {state}) (xs ys : List {item}),",
        "    r3Run s (xs ++ ys) = r3Run (r3Run s xs) ys := by",
        "  intro s xs ys",
        "  exact R3Temporal.exec_append r3Step s xs ys",
        "",
        f"theorem r3_model_run_append : ∀ (s : {state}) (xs ys : List {item}),",
        "    run s (xs ++ ys) = run (run s xs) ys := by",
        "  intro s xs ys",
        "  unfold run",
        "  rw [List.foldl_append]",
        "",
        f"theorem r3_reachable_trace : ∀ (s : {state}), Reachable s → ∃ xs : List {item}, run init xs = s := by",
        "  intro s hs",
        "  induction hs with",
        "  | init => exact ⟨[], rfl⟩",
        f"  | {next_pattern} =>",
        "      rcases ih with ⟨xs, hxs⟩",
        f"      refine ⟨xs ++ [{append_item}], ?_⟩",
        "      rw [r3_model_run_append, hxs]",
        "      rfl",
        "",
    ]
    if multi_clock:
        lines.extend([
            f"theorem r3_reachable_extend : ∀ (s : {state}), Reachable s →",
            f"    (i : {benchmark.top_module}Inputs) → (event : ClockEvent) → Reachable (step s i event) := by",
            "  intro s hs i event; exact Reachable.next hs i event",
            "",
        ])
    else:
        lines.extend([
            f"theorem r3_reachable_extend : ∀ (s : {state}), Reachable s →",
            f"    (i : {item}) → Reachable (step s i) := by",
            "  intro s hs i; exact Reachable.next hs i",
            "",
        ])
    statements = [
        {"name": "r3_run_eq_exec", "kind": "TRACE_BRIDGE"},
        {"name": "r3_run_append", "kind": "TRACE_BRIDGE"},
        {"name": "r3_model_run_append", "kind": "TRACE_BRIDGE"},
        {"name": "r3_reachable_trace", "kind": "TRACE_BRIDGE"},
        {"name": "r3_reachable_extend", "kind": "TRACE_BRIDGE"},
    ]
    return lines, statements


def _guard_declaration(seed: dict[str, Any], benchmark: Benchmark) -> list[str]:
    state = f"{benchmark.top_module}State"
    item = "EventInput" if _is_multiclock(seed) else f"{benchmark.top_module}Inputs"
    return [
        f"def {seed['guard_name']} (s : {state}) (item : {item}) : Prop :=",
        f"  ({seed['step_guard']}) = true",
        "",
    ]


def _projection_lemma(seed: dict[str, Any], benchmark: Benchmark) -> list[str]:
    """Expose one register's next-value expression without simplifying a whole process."""
    state = f"{benchmark.top_module}State"
    inputs = f"{benchmark.top_module}Inputs"
    function = seed["source_function"]
    field = seed["destination"]
    expression = seed["next_expression_process"]
    return [
        f"theorem {seed['projection_lemma']} : ∀ (s : {state}) (i : {inputs}),",
        f"    ({function} s i).{field} = {expression} := by",
        "  intro s i",
        "  rfl",
        "",
    ]


def _local_lemma(seed: dict[str, Any], benchmark: Benchmark) -> list[str]:
    state = f"{benchmark.top_module}State"
    item_type = "EventInput" if _is_multiclock(seed) else f"{benchmark.top_module}Inputs"
    field = seed["destination"]
    expected = seed["local_expected"]
    function = seed["source_function"]
    input_expr = "item.1" if _is_multiclock(seed) else "item"
    lines = [
        f"theorem {seed['local_lemma']} : ∀ (s : {state}) (item : {item_type}),",
        f"    {seed['guard_name']} s item → (r3Step s item).{field} = {expected} := by",
        "  intro s item h",
    ]
    if _is_multiclock(seed):
        lines.extend([
            f"  rcases item with ⟨input, event⟩",
            f"  unfold {seed['guard_name']} at h",
            "  simp only [Bool.and_eq_true] at h",
            "  rcases h with ⟨hevent, h⟩",
            f"  have hevent' : event = .{seed['clock_event']} := by simpa using hevent",
            "  subst event",
            f"  rw [show (r3Step s (input, .{seed['clock_event']})).{field} =",
            f"      ({function} (comb s input) input).{field} by rfl]",
            f"  rw [{seed['projection_lemma']}]",
        ])
    else:
        lines.extend([
            f"  unfold {seed['guard_name']} at h",
            f"  rw [show (r3Step s item).{field} =",
            f"      ({function} (comb s item) item).{field} by rfl]",
            f"  rw [{seed['projection_lemma']}]",
        ])
    lines.extend(["  grind", ""])
    return lines


def _probe_source(benchmark: Benchmark, seed: dict[str, Any]) -> str:
    lines = ["import R3Base", "", "set_option maxRecDepth 100000",
             "set_option maxHeartbeats 8000000", "",
             f"namespace {benchmark.top_module}Verification", f"open {benchmark.top_module}", ""]
    lines.extend(_step_prelude(benchmark, _is_multiclock(seed)))
    lines.extend(_projection_lemma(seed, benchmark))
    lines.extend(_guard_declaration(seed, benchmark))
    lines.extend(_local_lemma(seed, benchmark))
    lines.extend([f"end {benchmark.top_module}Verification", ""])
    return "\n".join(lines)


def build_temporal_foundation(
    benchmark: Benchmark,
    seeds: list[dict[str, Any]],
    output_root: Path,
    requirement_root: Path,
) -> dict[str, Any]:
    """Validate IR-derived local steps, then freeze one DUT foundation."""
    model_dir = output_root / benchmark.slug / "model"
    base_path = model_dir / "R3Base.lean"
    base_path.write_text(COMMON_TEMPORAL_SOURCE, encoding="utf-8")
    base_check = kernel_check(base_path, timeout_s=1200, build_olean=True)
    write_json(base_path.with_name("r3_base_check.json"), base_check)
    if not base_check["success"]:
        raise RuntimeError(f"R3 temporal base rejected for {benchmark.design_id}: "
                           + (base_check["stdout"] + base_check["stderr"])[-6000:])

    accepted: list[dict[str, Any]] = []
    rejected: list[dict[str, Any]] = []
    probe_root = requirement_root / "corpus" / "local_step_validation" / benchmark.slug
    started = time.perf_counter()
    for seed in seeds:
        path = probe_root / f"{seed['seed_id']}.lean"
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(_probe_source(benchmark, seed), encoding="utf-8")
        check = _lean_check(path, model_dir, timeout_s=1200)
        write_json(path.with_suffix(".check.json"), check)
        record = {**seed, "local_step_check": check}
        if check["success"]:
            accepted.append(record)
        else:
            record["rejection_reason"] = "LOCAL_STEP_LEMMA_KERNEL_REJECTED"
            rejected.append(record)

    multi_clock = len(json.loads(
        (output_root / benchmark.slug / "ir" / "design.json").read_text(encoding="utf-8")
    )["module"]["clock_domains"]) > 1
    lines = ["import R3Base", "", "set_option maxRecDepth 100000",
             "set_option maxHeartbeats 8000000", "",
             f"namespace {benchmark.top_module}Verification", f"open {benchmark.top_module}", ""]
    lines.extend(_step_prelude(benchmark, multi_clock))
    trace_lines, declarations = _trace_foundation(benchmark, multi_clock)
    lines.extend(trace_lines)
    for seed in accepted:
        lines.extend(_projection_lemma(seed, benchmark))
        lines.extend(_guard_declaration(seed, benchmark))
        lines.extend(_local_lemma(seed, benchmark))
        declarations.extend([
            {"name": seed["projection_lemma"], "kind": "IR_NEXT_VALUE", "seed_id": seed["seed_id"]},
            {"name": seed["guard_name"], "kind": "IR_GUARD", "seed_id": seed["seed_id"]},
            {"name": seed["local_lemma"], "kind": "IR_LOCAL_STEP", "seed_id": seed["seed_id"]},
        ])
    lines.extend([f"end {benchmark.top_module}Verification", ""])
    foundation_path = model_dir / "R3Foundation.lean"
    foundation_path.write_text("\n".join(lines), encoding="utf-8")
    foundation_check = kernel_check(foundation_path, timeout_s=2400, build_olean=True)
    write_json(foundation_path.with_name("r3_foundation_check.json"), foundation_check)
    if not foundation_check["success"]:
        raise RuntimeError(f"R3 foundation rejected for {benchmark.design_id}: "
                           + (foundation_check["stdout"] + foundation_check["stderr"])[-8000:])
    payload = {
        "schema": "rtl2lean-temporal-foundation-v1",
        "dut": benchmark.design_id,
        "base_path": str(base_path), "foundation_path": str(foundation_path),
        "base_check": base_check, "foundation_check": foundation_check,
        "accepted_seeds": accepted, "rejected_seeds": rejected,
        "declarations": declarations,
        "elapsed_s": time.perf_counter() - started,
        "policy": "DUT-independent temporal calculus plus kernel-validated Typed-IR local-step specializations",
    }
    write_json(requirement_root / "corpus" / "foundations" / f"{benchmark.slug}.json", payload)
    return payload
