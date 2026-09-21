"""Generate L1/L2/L3/L4 and structural high-level properties from Typed IR."""
from __future__ import annotations

import json
import re
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Any

from rtl2lean.backend.codegen import CodeGenerator
from rtl2lean.middle_end.ir import IRFunction, IRModule, IRValue

from rtl2lean.pipeline.io import write_json
from rtl2lean.pipeline.schema import DesignIR


@dataclass(frozen=True)
class GeneratedTheorem:
    name: str
    layer: str
    statement: str
    property_family: str
    source_functions: tuple[str, ...]
    state_fields: tuple[str, ...]
    input_fields: tuple[str, ...]
    proof_candidates: tuple[str, ...] = ("by rfl", "by simp")
    high_level: bool = False
    reusable: bool = True


@dataclass
class TheoremBundle:
    namespace: str
    foundation_path: Path
    targets_path: Path
    theorems: list[GeneratedTheorem] = field(default_factory=list)


def _safe(value: str) -> str:
    result = re.sub(r"[^A-Za-z0-9_]", "_", value)
    if not result or not result[0].isalpha():
        result = "n_" + result
    return result


def _node_count(value: IRValue | None) -> int:
    if value is None:
        return 0
    result = 1
    for item in value.data.values():
        if isinstance(item, IRValue):
            result += _node_count(item)
        elif isinstance(item, (list, tuple)):
            result += sum(_node_count(nested) for nested in item if isinstance(nested, IRValue))
    return result


def _function_assignments(function: IRFunction) -> list[tuple[str, IRValue]]:
    result = []
    for block in function.blocks:
        if block.name != function.entry_block:
            continue
        for instruction in block.instrs:
            if instruction.kind in {"assign", "nba"} and instruction.dest and instruction.value:
                result.append((instruction.dest, instruction.value))
    return result


def _render(value: IRValue, ir: IRModule) -> str:
    generator = CodeGenerator(include_comments=False)
    rendered = generator._render_state_value(value, ir)
    if generator._pending_helpers:
        raise ValueError("expression requires private helper context")
    return rendered


def _field_type(ir: IRModule, name: str) -> tuple[int, str]:
    widths = dict(ir.registers)
    widths.update({signal: typ.width for signal, typ in ir.signals})
    width = int(widths[name])
    return width, "Bool" if width == 1 else f"BitVec {width}"


def _clock_constructor(clock: str, clocks: list[str]) -> str:
    used: set[str] = set()
    result = ""
    for candidate in clocks:
        result = CodeGenerator._clock_constructor(candidate, used)
        if candidate == clock:
            return result
    raise ValueError(clock)


def _foundation(ir: IRModule, typed: DesignIR) -> tuple[str, str | None]:
    module = ir.name
    namespace = f"{module}Verification"
    multi = len(typed.module.clock_domains) > 1
    vector_fields = [(name, width) for name, width in ir.registers if width > 1]
    invariant_field = next(
        ((name, width) for name, width in vector_fields if re.search(r"state|round|count|ctrl|phase", name, re.I)),
        vector_fields[0] if vector_fields else None,
    )
    lines = [
        "import Model", "", "set_option linter.unusedVariables false",
        "set_option maxRecDepth 100000", "set_option maxHeartbeats 8000000", "",
        f"namespace {namespace}", f"open {module}", "",
    ]
    if multi:
        lines.extend([
            f"abbrev EventInput := {module}Inputs × ClockEvent",
            f"def run (s : {module}State) (events : List EventInput) : {module}State :=",
            "  events.foldl (fun state item => step state item.1 item.2) s", "",
            f"inductive Reachable : {module}State → Prop where",
            "  | init : Reachable init",
            f"  | next {{s : {module}State}} : Reachable s → (i : {module}Inputs) →",
            "      (event : ClockEvent) → Reachable (step s i event)", "",
        ])
    else:
        lines.extend([
            f"def run (s : {module}State) (inputs : List {module}Inputs) : {module}State :=",
            "  inputs.foldl step s", "",
            f"inductive Reachable : {module}State → Prop where",
            "  | init : Reachable init",
            f"  | next {{s : {module}State}} : Reachable s → (i : {module}Inputs) → Reachable (step s i)", "",
        ])
    if invariant_field:
        field, width = invariant_field
        lines.extend([
            f"def StateWidthInvariant (s : {module}State) : Prop :=",
            f"  s.{field}.toNat < 2 ^ {width}", "",
        ])
    lines.extend([f"end {namespace}", ""])
    return "\n".join(lines), invariant_field[0] if invariant_field else None


def generate_theorem_bundle(
    ir: IRModule, typed: DesignIR, model_dir: Path,
) -> TheoremBundle:
    module = ir.name
    namespace = f"{module}Verification"
    foundation_code, invariant_field = _foundation(ir, typed)
    foundation_path = model_dir / "Foundation.lean"
    foundation_path.write_text(foundation_code, encoding="utf-8")
    theorems: list[GeneratedTheorem] = []
    registers = [name for name, _ in ir.registers]
    reg_set = set(registers)
    input_set = {name for name, _, is_input in ir.ports if is_input}

    combinational = [function for function in ir.functions if not function.is_sequential]
    sequential = [function for function in ir.functions if function.is_sequential]

    # L1: exact semantic equations plus register preservation, all derived
    # from normalized combinational IR.
    l1_count = 0
    for function in combinational:
        assignments = _function_assignments(function)
        written = {destination for destination, _ in assignments}
        for destination, value in assignments:
            if _node_count(value) > 256:
                continue
            try:
                rhs = _render(value, ir)
            except ValueError:
                continue
            name = f"l1_{_safe(function.name)}_{_safe(destination)}_semantic"
            theorems.append(GeneratedTheorem(
                name, "L1", f"∀ (s : {module}State) (i : {module}Inputs), "
                f"({function.name} s i).{destination} = {rhs}",
                "combinational_semantics", (function.name,), (destination,),
                tuple(sorted(_uses(value) & input_set)),
                (f"by intro s i; rfl", f"by intro s i; simp [{function.name}]"),
            ))
            if registers:
                preserved = next((field for field in registers if field not in written), None)
                if preserved:
                    theorems.append(GeneratedTheorem(
                        f"l1_{_safe(function.name)}_{_safe(preserved)}_preserved", "L1",
                        f"∀ (s : {module}State) (i : {module}Inputs), "
                        f"({function.name} s i).{preserved} = s.{preserved}",
                        "combinational_preservation", (function.name,), (preserved,), (),
                        ("by intro s i; rfl", f"by intro s i; simp [{function.name}]"),
                    ))
            l1_count += 1
            break
        if l1_count >= 6:
            break

    # L2: register-update and unwritten-register preservation for normalized
    # sequential processes, plus determinism.
    l2_count = 0
    writer_for: dict[str, str] = {}
    for function in sequential:
        assignments = _function_assignments(function)
        for destination, value in assignments:
            if destination in reg_set:
                writer_for[destination] = function.name
            if _node_count(value) <= 256:
                try:
                    rhs = _render(value, ir)
                except ValueError:
                    rhs = None
                if rhs is not None:
                    theorems.append(GeneratedTheorem(
                        f"l2_{_safe(function.name)}_{_safe(destination)}_update", "L2",
                        f"∀ (s : {module}State) (i : {module}Inputs), "
                        f"({function.name} s i).{destination} = {rhs}",
                        "register_update", (function.name,), (destination,),
                        tuple(sorted(_uses(value) & input_set)),
                        ("by intro s i; rfl", f"by intro s i; simp [{function.name}]"),
                    ))
                    l2_count += 1
                    break
        written = {destination for destination, _ in assignments}
        preserved = next((field for field in registers if field not in written), None)
        if preserved:
            theorems.append(GeneratedTheorem(
                f"l2_{_safe(function.name)}_{_safe(preserved)}_hold", "L2",
                f"∀ (s : {module}State) (i : {module}Inputs), "
                f"({function.name} s i).{preserved} = s.{preserved}",
                "unwritten_register_preservation", (function.name,), (preserved,), (),
                ("by intro s i; rfl", f"by intro s i; simp [{function.name}]"),
            ))
        if l2_count >= 8:
            break
    if sequential:
        function = sequential[0]
        theorems.append(GeneratedTheorem(
            f"l2_{_safe(function.name)}_deterministic", "L2",
            f"∀ (s1 s2 : {module}State) (i : {module}Inputs), s1 = s2 → "
            f"{function.name} s1 i = {function.name} s2 i",
            "transition_determinism", (function.name,), (), (),
            ("by intro s1 s2 i h; cases h; rfl",),
        ))

    multi = len(typed.module.clock_domains) > 1
    # L3: global step/commit semantics and output reflection.
    if multi:
        theorems.append(GeneratedTheorem(
            "l3_step_event_definition", "L3",
            f"∀ (s : {module}State) (i : {module}Inputs) (e : ClockEvent), "
            "step s i e = stepEvent s i e",
            "step_semantics", ("step", "stepEvent"), (), (), ("by intro s i e; rfl",),
        ))
        theorems.append(GeneratedTheorem(
            "l3_step_event_deterministic", "L3",
            f"∀ (s1 s2 : {module}State) (i : {module}Inputs) (e : ClockEvent), "
            "s1 = s2 → step s1 i e = step s2 i e",
            "step_determinism", ("step",), (), (),
            ("by intro s1 s2 i e h; cases h; rfl",),
        ))
    else:
        rhs = "comb (commit (comb s i) i) i" if combinational else "commit s i"
        theorems.append(GeneratedTheorem(
            "l3_step_definition", "L3",
            f"∀ (s : {module}State) (i : {module}Inputs), step s i = {rhs}",
            "step_semantics", ("step", "commit", "comb"), (), (),
            ("by intro s i; rfl", "by intro s i; simp [step]"),
        ))
        theorems.append(GeneratedTheorem(
            "l3_step_deterministic", "L3",
            f"∀ (s1 s2 : {module}State) (i : {module}Inputs), s1 = s2 → step s1 i = step s2 i",
            "step_determinism", ("step",), (), (),
            ("by intro s1 s2 i h; cases h; rfl",),
        ))
    output = next((name for name, _, is_input in ir.ports if not is_input), None)
    if output:
        args = "s i e" if multi else "s i"
        binder = f"(e : ClockEvent) " if multi else ""
        theorems.append(GeneratedTheorem(
            f"l3_{_safe(output)}_output_reflection", "L3",
            f"∀ (s : {module}State) (i : {module}Inputs) {binder}, "
            f"(outputs (step {args})).{output} = (step {args}).{output}",
            "output_reflection", ("outputs", "step"), (output,), (),
            (f"by intro s i {'e' if multi else ''}; rfl".replace("  ", " "),),
        ))

    # L4 finite execution and reachability closure.
    if multi:
        theorems.extend([
            GeneratedTheorem("l4_run_nil", "L4", f"∀ s : {module}State, run s [] = s",
                             "finite_execution", ("run",), (), (), ("by intro s; rfl",)),
            GeneratedTheorem("l4_run_cons", "L4",
                             f"∀ (s : {module}State) (x : EventInput) (xs : List EventInput), "
                             "run s (x :: xs) = run (step s x.1 x.2) xs",
                             "finite_execution", ("run", "step"), (), (), ("by intro s x xs; rfl",)),
            GeneratedTheorem("l4_reachable_init", "L4", "Reachable init", "reachability",
                             ("Reachable",), (), (), ("by exact Reachable.init",)),
            GeneratedTheorem("l4_reachable_step", "L4",
                             f"∀ (s : {module}State), Reachable s → (i : {module}Inputs) → "
                             "(e : ClockEvent) → Reachable (step s i e)",
                             "reachability_closure", ("Reachable", "step"), (), (),
                             ("by intro s h i e; exact Reachable.next h i e",)),
        ])
    else:
        theorems.extend([
            GeneratedTheorem("l4_run_nil", "L4", f"∀ s : {module}State, run s [] = s",
                             "finite_execution", ("run",), (), (), ("by intro s; rfl",)),
            GeneratedTheorem("l4_run_cons", "L4",
                             f"∀ (s : {module}State) (i : {module}Inputs) (xs : List {module}Inputs), "
                             "run s (i :: xs) = run (step s i) xs",
                             "finite_execution", ("run", "step"), (), (), ("by intro s i xs; rfl",)),
            GeneratedTheorem("l4_reachable_init", "L4", "Reachable init", "reachability",
                             ("Reachable",), (), (), ("by exact Reachable.init",)),
            GeneratedTheorem("l4_reachable_step", "L4",
                             f"∀ (s : {module}State), Reachable s → (i : {module}Inputs) → Reachable (step s i)",
                             "reachability_closure", ("Reachable", "step"), (), (),
                             ("by intro s h i; exact Reachable.next h i",)),
        ])

    # High-level families are selected by IR names/dependencies, never DUT id.
    control = next(
        (field for field in registers if field in writer_for and re.search(r"state|round|count|ctrl|phase", field, re.I)),
        next(iter(writer_for), None),
    )
    if control:
        writer = writer_for[control]
        writer_function = next(function for function in sequential if function.name == writer)
        if multi:
            clocks = [domain.clock for domain in typed.module.clock_domains]
            event = _clock_constructor(writer_function.clock_signal, clocks)
            commit = f"commitEvent s i .{event}"
        else:
            commit = "commit s i"
        theorems.append(GeneratedTheorem(
            f"property_{_safe(control)}_commit_progression", "PROPERTY",
            f"∀ (s : {module}State) (i : {module}Inputs), "
            f"({commit}).{control} = ({writer} s i).{control}",
            "control_state_progression", ("commitEvent" if multi else "commit", writer),
            (control,), (), ("by intro s i; rfl",),
            high_level=True,
        ))
    if invariant_field:
        width = dict(ir.registers)[invariant_field]
        range_name = f"property_{_safe(invariant_field)}_binary_range"
        theorems.append(GeneratedTheorem(
            range_name, "PROPERTY", f"∀ s : {module}State, StateWidthInvariant s",
            "state_safety", (), (invariant_field,), (),
            (f"by intro s; exact s.{invariant_field}.isLt",), high_level=True,
        ))
        theorems.append(GeneratedTheorem(
            f"property_{_safe(invariant_field)}_reachable_range", "PROPERTY",
            f"∀ s : {module}State, Reachable s → StateWidthInvariant s",
            "reachable_state_invariant", ("Reachable",), (invariant_field,), (),
            ("by intro s h; simp [StateWidthInvariant]",), high_level=True,
        ))
    if multi:
        clocks = [domain.clock for domain in typed.module.clock_domains]
        for domain in typed.module.clock_domains:
            other = next((clock for clock in clocks if clock != domain.clock), None)
            other_fields = set(next(item.state_fields for item in typed.module.clock_domains if item.clock == other)) if other else set()
            field = next((name for name in domain.state_fields if name in reg_set and name not in other_fields), None)
            if field and other:
                constructor = _clock_constructor(other, clocks)
                theorems.append(GeneratedTheorem(
                    f"property_{_safe(field)}_{_safe(other)}_domain_preservation", "PROPERTY",
                    f"∀ (s : {module}State) (i : {module}Inputs), "
                    f"(commitEvent s i .{constructor}).{field} = s.{field}",
                    "clock_domain_preservation", ("commitEvent",), (field,), (),
                    ("by intro s i; rfl",), high_level=True,
                ))
                break
        theorems.append(GeneratedTheorem(
            "property_two_event_execution", "PROPERTY",
            f"∀ (s : {module}State) (x y : EventInput), "
            "run s [x, y] = step (step s x.1 x.2) y.1 y.2",
            "bounded_temporal_relation", ("run", "step"), (), (),
            ("by intro s x y; rfl",), high_level=True,
        ))
        theorems.append(GeneratedTheorem(
            "property_reachable_has_finite_event_history", "PROPERTY",
            f"∀ s : {module}State, Reachable s → ∃ events : List EventInput, run init events = s",
            "finite_reachability_witness", ("Reachable", "run", "step"), (), (),
            ("by rfl", "by simp"), high_level=True,
        ))
    else:
        theorems.append(GeneratedTheorem(
            "property_two_cycle_execution", "PROPERTY",
            f"∀ (s : {module}State) (i1 i2 : {module}Inputs), "
            "run s [i1, i2] = step (step s i1) i2",
            "bounded_temporal_relation", ("run", "step"), (), (),
            ("by intro s i1 i2; rfl",), high_level=True,
        ))
        theorems.append(GeneratedTheorem(
            "property_reachable_has_finite_input_history", "PROPERTY",
            f"∀ s : {module}State, Reachable s → ∃ inputs : List {module}Inputs, run init inputs = s",
            "finite_reachability_witness", ("Reachable", "run", "step"), (), (),
            ("by rfl", "by simp"), high_level=True,
        ))

    targets_path = model_dir / "targets.json"
    write_json(targets_path, {
        "schema": "rtl2lean-four-layer-targets-v1",
        "namespace": namespace,
        "targets": [asdict(theorem) for theorem in theorems],
        "metrics": {
            "N_L1": sum(theorem.layer == "L1" for theorem in theorems),
            "N_L2": sum(theorem.layer == "L2" for theorem in theorems),
            "N_L3": sum(theorem.layer == "L3" for theorem in theorems),
            "N_L4": sum(theorem.layer == "L4" for theorem in theorems),
            "N_PROPERTY": sum(theorem.layer == "PROPERTY" for theorem in theorems),
            "N_TOTAL": len(theorems),
        },
    })
    return TheoremBundle(namespace, foundation_path, targets_path, theorems)


def _uses(value: IRValue | None) -> set[str]:
    if value is None:
        return set()
    if value.kind == "var":
        return {str(value.data["name"])}
    result: set[str] = set()
    for item in value.data.values():
        if isinstance(item, IRValue):
            result.update(_uses(item))
        elif isinstance(item, (list, tuple)):
            for nested in item:
                if isinstance(nested, IRValue):
                    result.update(_uses(nested))
    return result
