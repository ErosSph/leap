"""Serializable typed RTL IR view used by all downstream pipeline stages."""
from __future__ import annotations

from dataclasses import asdict, dataclass, field
from typing import Any

from rtl2lean.frontend.ast import Module
from rtl2lean.middle_end.ir import IRModule, IRType, IRValue


@dataclass(frozen=True)
class ExpressionIR:
    node_id: int
    kind: str
    width: int | None
    signed: bool
    attributes: tuple[tuple[str, Any], ...]
    children: tuple[int, ...]


@dataclass(frozen=True)
class NormalizedStatementIR:
    block: str
    kind: str
    destination: str | None
    expression: int | None
    condition: int | None


@dataclass(frozen=True)
class CrossClockDependencyIR:
    signal: str
    source_clocks: tuple[str, ...]
    destination_clock: str
    reader_process: str
    semantics: str


@dataclass(frozen=True)
class SignalIR:
    name: str
    width: int
    signed: bool
    direction: str
    kind: str
    drivers: tuple[str, ...]
    readers: tuple[str, ...]
    clock_domains: tuple[str, ...]


@dataclass(frozen=True)
class ProcessIR:
    name: str
    process_type: str
    sequential: bool
    clock: str | None
    edge: str | None
    reset: str | None
    reset_polarity: str | None
    read_set: tuple[str, ...]
    write_set: tuple[str, ...]
    normalized_statements: tuple[NormalizedStatementIR, ...]
    normalized_statement_count: int


@dataclass(frozen=True)
class ClockDomainIR:
    clock: str
    edge: str
    resets: tuple[str, ...]
    processes: tuple[str, ...]
    state_fields: tuple[str, ...]


@dataclass(frozen=True)
class MemoryIR:
    name: str
    element_width: int
    depth: int
    left: int
    right: int
    flattened_width: int


@dataclass(frozen=True)
class ModuleIR:
    name: str
    signals: tuple[SignalIR, ...]
    processes: tuple[ProcessIR, ...]
    clock_domains: tuple[ClockDomainIR, ...]
    memories: tuple[MemoryIR, ...]
    parameters: tuple[dict[str, Any], ...]
    cross_clock_dependencies: tuple[CrossClockDependencyIR, ...]


@dataclass(frozen=True)
class DesignIR:
    schema: str
    design_id: str
    top_module: str
    module: ModuleIR
    expressions: tuple[ExpressionIR, ...]
    nondeterministic_inputs: tuple[str, ...] = field(default_factory=tuple)

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)


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


def _expression_width(value: IRValue | None, cache: dict[int, int | None]) -> int | None:
    if value is None:
        return None
    if id(value) in cache:
        return cache[id(value)]
    result: int | None
    if value.kind == "var":
        result = int(value.data["type"].width)
    elif value.kind in {"const_int", "const_nat"}:
        result = int(value.data.get("width", 32))
    elif value.kind in {"const_bool", "bit_select"}:
        result = 1
    elif value.kind == "bit_range":
        result = int(value.data["hi"]) - int(value.data["lo"]) + 1
    elif value.kind == "concat":
        widths = [_expression_width(child, cache) for child in value.data.get("values", [])]
        result = sum(width for width in widths if width is not None) if all(width is not None for width in widths) else None
    elif value.kind in {"array_select"}:
        result = int(value.data["element_width"])
    else:
        children = [child for child in value.data.values() if isinstance(child, IRValue)]
        widths = [width for child in children if (width := _expression_width(child, cache)) is not None]
        result = max(widths) if widths else None
    cache[id(value)] = result
    return result


def _expression(value: IRValue | None, table: list[ExpressionIR],
                identities: dict[int, int], widths: dict[int, int | None]) -> int | None:
    if value is None:
        return None
    prior = identities.get(id(value))
    if prior is not None:
        return prior
    children = []
    attributes = []
    for key, item in value.data.items():
        if isinstance(item, IRValue):
            children.append(_expression(item, table, identities, widths))
        elif isinstance(item, (list, tuple)):
            nested = [element for element in item if isinstance(element, IRValue)]
            children.extend(_expression(element, table, identities, widths) for element in nested)
            scalars = [element for element in item if not isinstance(element, IRValue)]
            if scalars:
                attributes.append((key, scalars))
        elif isinstance(item, IRType):
            attributes.append((key, {"name": item.name, "width": item.width}))
        else:
            attributes.append((key, item))
    node_id = len(table)
    identities[id(value)] = node_id
    table.append(ExpressionIR(
        node_id=node_id, kind=value.kind, width=_expression_width(value, widths), signed=False,
        attributes=tuple(attributes), children=tuple(child for child in children if child is not None),
    ))
    return node_id


def build_design_ir(design_id: str, ast: Module, ir: IRModule) -> DesignIR:
    expression_table: list[ExpressionIR] = []
    expression_identities: dict[int, int] = {}
    expression_widths: dict[int, int | None] = {}
    processes = []
    drivers: dict[str, set[str]] = {}
    readers: dict[str, set[str]] = {}
    clock_writes: dict[str, set[str]] = {}
    ast_seq = [
        process for process in ast.processes
        if process.event_control and process.event_control.is_sequential
    ]
    seq_index = 0
    for function in ir.functions:
        reads: set[str] = set()
        writes: set[str] = set()
        statement_count = 0
        normalized_statements = []
        for block in function.blocks:
            for instruction in block.instrs:
                if instruction.kind in {"assign", "nba"} and instruction.dest:
                    writes.add(instruction.dest)
                reads.update(_uses(instruction.value))
                reads.update(_uses(instruction.cond))
                statement_count += instruction.kind not in {"return", "label", "jump"}
                normalized_statements.append(NormalizedStatementIR(
                    block=block.name, kind=instruction.kind, destination=instruction.dest,
                    expression=_expression(instruction.value, expression_table, expression_identities, expression_widths),
                    condition=_expression(instruction.cond, expression_table, expression_identities, expression_widths),
                ))
        for name in writes:
            drivers.setdefault(name, set()).add(function.name)
        for name in reads:
            readers.setdefault(name, set()).add(function.name)
        edge = None
        if function.is_sequential:
            source_process = ast_seq[seq_index] if seq_index < len(ast_seq) else None
            seq_index += 1
            if source_process and source_process.event_control:
                edge = next((event_edge for event_edge, signal in source_process.event_control.events
                             if signal == function.clock_signal), None)
            if function.clock_signal:
                clock_writes.setdefault(function.clock_signal, set()).update(writes)
        processes.append(ProcessIR(
            name=function.name,
            process_type="sequential" if function.is_sequential else "combinational",
            sequential=function.is_sequential,
            clock=function.clock_signal,
            edge=edge,
            reset=function.reset_signal,
            reset_polarity=(
                "active_high" if function.reset_active_high else "active_low"
            ) if function.reset_signal else None,
            read_set=tuple(sorted(reads)),
            write_set=tuple(sorted(writes)),
            normalized_statements=tuple(normalized_statements),
            normalized_statement_count=statement_count,
        ))

    ast_signed = {port.name: port.signed for port in ast.ports}
    ast_signed.update({name: declaration.signed for declaration in ast.declarations for name in declaration.names})
    port_map = {name: (typ, is_input) for name, typ, is_input in ir.ports}
    source_input_names = {port.name for port in ast.ports if str(port.direction) == "input"}
    register_map = dict(ir.registers)
    signal_map = dict(ir.signals)
    memory_names = {name for name, *_ in ir.memories}
    all_names = sorted(set(port_map) | set(register_map) | set(signal_map))
    signal_domains: dict[str, set[str]] = {
        name: set(clocks) for name, clocks in
        ((name, [clock for clock, names in clock_writes.items() if name in names])
         for name in all_names)
    }
    # Carry clock provenance through combinational processes to identify a
    # source-domain register sampled through one or more combinational wires.
    for _ in range(len(processes) + 1):
        changed = False
        for process in processes:
            if process.sequential:
                continue
            inherited = set().union(*(signal_domains.get(name, set()) for name in process.read_set))
            for name in process.write_set:
                before = len(signal_domains.setdefault(name, set()))
                signal_domains[name].update(inherited)
                changed |= len(signal_domains[name]) != before
        if not changed:
            break
    signals = []
    for name in all_names:
        if name in port_map:
            typ, is_input = port_map[name]
            direction = "input" if is_input else "output"
            kind = (
                "nondeterministic_input" if (name.startswith("__rtl_nondet_") or
                                               (is_input and name not in source_input_names)) else
                "state_output" if name in register_map and not is_input else
                "port"
            )
            width = typ.width
        elif name in register_map:
            direction, kind, width = "internal", "memory" if name in memory_names else "state", register_map[name]
        else:
            direction, kind, width = "internal", "wire", signal_map[name].width
        domains = tuple(sorted(signal_domains.get(name, ())))
        signals.append(SignalIR(
            name=name, width=int(width), signed=bool(ast_signed.get(name, False)),
            direction=direction, kind=kind,
            drivers=tuple(sorted(drivers.get(name, ()))),
            readers=tuple(sorted(readers.get(name, ()))),
            clock_domains=domains,
        ))

    domains = []
    for clock in sorted(clock_writes):
        domain_processes = [process for process in processes if process.clock == clock]
        edges = {process.edge for process in domain_processes if process.edge}
        domains.append(ClockDomainIR(
            clock=clock,
            edge=next(iter(edges)) if len(edges) == 1 else "mixed",
            resets=tuple(sorted({process.reset for process in domain_processes if process.reset})),
            processes=tuple(process.name for process in domain_processes),
            state_fields=tuple(sorted(clock_writes[clock])),
        ))
    memories = tuple(MemoryIR(
        name=name, element_width=element_width, depth=depth, left=left, right=right,
        flattened_width=element_width * depth,
    ) for name, element_width, depth, left, right in ir.memories)
    parameters = tuple({"name": name, "width": typ.width, "value": value}
                       for name, typ, value in ir.parameters)
    cross_clock = []
    for process in processes:
        if not process.sequential or not process.clock:
            continue
        for name in process.read_set:
            sources = tuple(sorted(clock for clock in signal_domains.get(name, ()) if clock != process.clock))
            if sources:
                cross_clock.append(CrossClockDependencyIR(
                    signal=name, source_clocks=sources, destination_clock=process.clock,
                    reader_process=process.name,
                    semantics="sample source-domain value from pre-event state",
                ))
    return DesignIR(
        schema="rtl2lean-typed-design-ir-v1",
        design_id=design_id,
        top_module=ir.name,
        module=ModuleIR(
            ir.name, tuple(signals), tuple(processes), tuple(domains), memories,
            parameters, tuple(cross_clock),
        ),
        expressions=tuple(expression_table),
        nondeterministic_inputs=tuple(sorted(
            name for name, (_, is_input) in port_map.items()
            if is_input and (name.startswith("__rtl_nondet_") or name not in source_input_names)
        )),
    )
