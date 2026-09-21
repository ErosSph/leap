"""Shared PySlang elaboration and design metadata.

This is the single authority for top selection, parameter values, port widths,
signedness, clocks, resets, and process summaries.
"""
from __future__ import annotations

import re
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Any, Iterable, Optional, Sequence

import pyslang


class DesignError(RuntimeError):
    """The source set could not be elaborated into one unambiguous design."""


class DesignParseError(DesignError):
    """Syntax diagnostics rejected the source before semantic elaboration."""


@dataclass(frozen=True)
class ParameterInfo:
    name: str
    value: int | str | None
    width: int
    signed: bool
    local: bool = False


@dataclass(frozen=True)
class PortInfo:
    name: str
    direction: str
    width: int
    signed: bool
    type_text: str


@dataclass(frozen=True)
class ProcessInfo:
    kind: str
    sensitivity: tuple[tuple[str, str], ...] = ()
    clock: Optional[str] = None
    reset: Optional[str] = None
    blocking_assignments: int = 0
    nonblocking_assignments: int = 0
    if_count: int = 0
    case_count: int = 0


@dataclass(frozen=True)
class DesignInfo:
    top_module: str
    source_files: tuple[str, ...]
    parameters: tuple[ParameterInfo, ...]
    ports: tuple[PortInfo, ...]
    clock: Optional[str]
    reset: Optional[str]
    processes: tuple[ProcessInfo, ...]
    warnings: tuple[str, ...] = field(default=(), compare=False)

    @property
    def name(self) -> str:
        return self.top_module

    @property
    def inputs(self) -> tuple[PortInfo, ...]:
        return tuple(port for port in self.ports if port.direction == "input")

    @property
    def outputs(self) -> tuple[PortInfo, ...]:
        return tuple(port for port in self.ports if port.direction == "output")

    @property
    def inouts(self) -> tuple[PortInfo, ...]:
        return tuple(port for port in self.ports if port.direction == "inout")

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)


@dataclass
class ElaboratedDesign:
    info: DesignInfo
    instance: Any = field(repr=False)
    compilation: Any = field(repr=False)


def _pyslang_class(name: str, namespace: str) -> Any:
    direct = getattr(pyslang, name, None)
    if direct is not None:
        return direct
    nested = getattr(pyslang, namespace, None)
    if nested is None or not hasattr(nested, name):
        raise DesignError(f"PySlang does not expose {name}")
    return getattr(nested, name)


def _new_compilation(top_module: Optional[str], allow_use_before_declare: bool = False) -> Any:
    compilation_cls = _pyslang_class("Compilation", "ast")
    options_cls = _pyslang_class("CompilationOptions", "ast")
    options = options_cls()
    # Supply a default for compilation units lacking a directive. Explicit
    # module/unit timescales retain precedence in Slang.
    options.defaultTimeScale = pyslang.TimeScale.fromString("1ns/1ps")
    if allow_use_before_declare:
        flags = _pyslang_class("CompilationFlags", "ast")
        options.flags = flags.AllowUseBeforeDeclare
    if top_module is not None:
        options.topModules = {top_module}
    try:
        return compilation_cls(options)
    except TypeError:
        bag = pyslang.Bag()
        bag.compilationOptions = options
        return compilation_cls(bag)


def _is_error(diagnostic: Any) -> bool:
    if hasattr(diagnostic, "isError"):
        return bool(diagnostic.isError())
    severity = getattr(diagnostic, "severity", None)
    error_value = getattr(getattr(pyslang, "DiagnosticSeverity", None), "Error", None)
    return severity == error_value


def _diagnostic_text(diagnostic: Any) -> str:
    text = str(diagnostic)
    code = getattr(diagnostic, "code", None)
    location = getattr(diagnostic, "location", None)
    # PySlang 11's Diagnostic.__str__ is the default object repr and contains
    # a process-specific memory address. Keep reports and DesignInfo stable.
    if text.startswith("<pyslang."):
        text = str(code) if code is not None else type(diagnostic).__name__
    if location is not None:
        text += f" @ {location}"
    return text


def _direction_name(direction: Any) -> str:
    text = str(direction).lower()
    if "inout" in text:
        return "inout"
    if text.endswith(".out") or text == "out" or "output" in text:
        return "output"
    if text.endswith(".in") or text == "in" or "input" in text:
        return "input"
    raise DesignError(f"unsupported port direction: {direction}")


def _int_attr(obj: Any, name: str, context: str) -> int:
    value = getattr(obj, name, None)
    if callable(value):
        value = value()
    try:
        result = int(value)
    except (TypeError, ValueError):
        raise DesignError(f"cannot determine {context}") from None
    if result <= 0:
        raise DesignError(f"unsupported {context}: {result}")
    return result


def _bool_attr(obj: Any, name: str) -> bool:
    value = getattr(obj, name, False)
    return bool(value() if callable(value) else value)


def _constant_value(symbol: Any) -> int | str | None:
    value = getattr(symbol, "value", None)
    if value is None:
        return None
    if hasattr(value, "hasUnknown") and value.hasUnknown():
        return str(value)
    if hasattr(value, "convertToInt"):
        try:
            converted = value.convertToInt()
            inner = getattr(converted, "value", converted)
            return int(inner)
        except (TypeError, ValueError, RuntimeError):
            pass
    text = str(value)
    try:
        return int(text, 0)
    except ValueError:
        return text


def _extract_parameters(body: Any) -> tuple[ParameterInfo, ...]:
    result = []
    for symbol in body.parameters:
        if not _bool_attr(symbol, "isValue"):
            continue
        symbol_type = getattr(symbol, "type", None)
        result.append(ParameterInfo(
            name=str(symbol.name),
            value=_constant_value(symbol),
            width=_int_attr(symbol_type, "bitWidth", f"width of parameter {symbol.name!r}"),
            signed=_bool_attr(symbol_type, "isSigned"),
            local=_bool_attr(symbol, "isLocalParam"),
        ))
    return tuple(result)


def _extract_ports(body: Any) -> tuple[PortInfo, ...]:
    result = []
    for symbol in body.portList:
        symbol_type = getattr(symbol, "type", None)
        result.append(PortInfo(
            name=str(symbol.name),
            direction=_direction_name(symbol.direction),
            width=_int_attr(symbol_type, "bitWidth", f"width of port {symbol.name!r}"),
            signed=_bool_attr(symbol_type, "isSigned"),
            type_text=str(symbol_type),
        ))
    return tuple(result)


def _process_kind(kind_text: str) -> str:
    lower = kind_text.lower()
    if "alwaysff" in lower:
        return "always_ff"
    if "alwayscomb" in lower:
        return "always_comb"
    if "alwayslatch" in lower:
        return "always_latch"
    if "always" in lower:
        return "always"
    return "initial"


def _extract_processes(body: Any) -> tuple[ProcessInfo, ...]:
    result = []
    syntax = getattr(body, "syntax", None)
    for member in getattr(syntax, "members", ()):
        kind_text = str(getattr(member, "kind", ""))
        if "Always" not in kind_text and "Initial" not in kind_text:
            continue
        text = str(member)
        sensitivity = tuple(
            (edge.lower(), signal)
            for edge, signal in re.findall(r"\b(posedge|negedge)\s+([A-Za-z_$][\w$]*)", text)
        )
        clock = next(
            (signal for edge, signal in sensitivity if "clk" in signal.lower() or "clock" in signal.lower()),
            sensitivity[0][1] if sensitivity else None,
        )
        reset = next(
            (signal for _, signal in sensitivity if re.search(r"rst|reset", signal, re.I)),
            None,
        )
        nonblocking = len(re.findall(
            r"(?:[A-Za-z_$][\w$]*|\])\s*<=\s*(?!=)", text
        ))
        assignment_text = re.sub(r"<=", "", text)
        blocking = len(re.findall(
            r"(?:[A-Za-z_$][\w$]*|\])\s*=\s*(?!=)", assignment_text
        ))
        result.append(ProcessInfo(
            kind=_process_kind(kind_text),
            sensitivity=sensitivity,
            clock=clock,
            reset=reset,
            blocking_assignments=blocking,
            nonblocking_assignments=nonblocking,
            if_count=len(re.findall(r"\bif\s*\(", text)),
            case_count=len(re.findall(r"\b(?:case|casex|casez)\s*\(", text)),
        ))
    return tuple(result)


def _choose_instance(
    instances: Sequence[Any],
    source_names: Sequence[str],
    top_module: Optional[str],
) -> Any:
    if not instances:
        requested = f" {top_module!r}" if top_module else ""
        raise DesignError(f"no elaborated top module{requested} found")
    if top_module is not None:
        matches = [inst for inst in instances if str(inst.body.name) == top_module]
        if len(matches) != 1:
            names = sorted({str(inst.body.name) for inst in instances})
            raise DesignError(
                f"requested top module {top_module!r} not found; candidates: {names}"
            )
        return matches[0]
    if len(instances) == 1:
        return instances[0]

    stems = {Path(name).stem for name in source_names if not name.startswith("<")}
    filename_matches = [inst for inst in instances if str(inst.body.name) in stems]
    if len(filename_matches) == 1:
        return filename_matches[0]
    names = sorted({str(inst.body.name) for inst in instances})
    raise DesignError(
        "multiple top modules found; pass top_module to disambiguate: " + ", ".join(names)
    )


def _fallback_clock(ports: Iterable[PortInfo]) -> Optional[str]:
    candidates = [
        port.name for port in ports
        if port.direction == "input" and port.width == 1
        and re.search(r"(^|_)(clk|clock)($|_)", port.name, re.I)
    ]
    return candidates[0] if len(candidates) == 1 else None


def _fallback_reset(ports: Iterable[PortInfo]) -> Optional[str]:
    candidates = [
        port.name for port in ports
        if port.direction == "input" and port.width == 1
        and re.search(r"rst|reset", port.name, re.I)
    ]
    return candidates[0] if len(candidates) == 1 else None


def _elaborate(
    trees: Sequence[Any],
    source_names: Sequence[str],
    top_module: Optional[str],
    allow_use_before_declare: bool = False,
) -> ElaboratedDesign:
    compilation = _new_compilation(top_module, allow_use_before_declare)
    diagnostics = []
    for tree in trees:
        diagnostics.extend(list(tree.diagnostics))
        compilation.addSyntaxTree(tree)

    syntax_errors = [_diagnostic_text(diag) for diag in diagnostics if _is_error(diag)]
    if syntax_errors:
        raise DesignParseError("RTL parsing/elaboration failed:\n" + "\n".join(syntax_errors[:20]))
    root = compilation.getRoot()
    diagnostics.extend(list(compilation.getSemanticDiagnostics()))
    errors = [_diagnostic_text(diag) for diag in diagnostics if _is_error(diag)]
    warnings = [_diagnostic_text(diag) for diag in diagnostics if not _is_error(diag)]
    if errors:
        preview = "\n".join(errors[:20])
        if len(errors) > 20:
            preview += f"\n... and {len(errors) - 20} more diagnostics"
        raise DesignError(f"RTL parsing/elaboration failed:\n{preview}")

    instance = _choose_instance(list(root.topInstances), source_names, top_module)
    body = instance.body
    ports = _extract_ports(body)
    processes = _extract_processes(body)
    clock = next((process.clock for process in processes if process.clock), None)
    reset = next((process.reset for process in processes if process.reset), None)
    info = DesignInfo(
        top_module=str(body.name),
        source_files=tuple(source_names),
        parameters=_extract_parameters(body),
        ports=ports,
        clock=clock or _fallback_clock(ports),
        reset=reset or _fallback_reset(ports),
        processes=processes,
        warnings=tuple(warnings),
    )
    return ElaboratedDesign(info=info, instance=instance, compilation=compilation)


def load_designs(verilog_files: Sequence[str | Path]) -> list[ElaboratedDesign]:
    """Elaborate a source set and return every inferred root design.

    This is intended for corpus discovery. Normal compiler calls
    should use :func:`load_design`, which enforces one selected top.
    """
    if not verilog_files:
        raise DesignError("at least one RTL source file is required")
    syntax_tree_cls = _pyslang_class("SyntaxTree", "syntax")
    paths = [Path(source).resolve() for source in verilog_files]
    for path in paths:
        if not path.is_file():
            raise FileNotFoundError(f"RTL source not found: {path}")
    trees = [syntax_tree_cls.fromFile(str(path)) for path in paths]

    # Elaborate once to discover root modules, then force each root in its own
    # compilation so its parameterized interface is represented exactly as it
    # will be for compiler runs.
    discovery = _new_compilation(None)
    diagnostics = []
    for tree in trees:
        diagnostics.extend(list(tree.diagnostics))
        discovery.addSyntaxTree(tree)
    root = discovery.getRoot()
    diagnostics.extend(list(discovery.getSemanticDiagnostics()))
    errors = [_diagnostic_text(diag) for diag in diagnostics if _is_error(diag)]
    if errors:
        preview = "\n".join(errors[:20])
        raise DesignError(f"RTL parsing/elaboration failed:\n{preview}")

    top_names = sorted({str(instance.body.name) for instance in root.topInstances})
    return [
        _elaborate(trees, [str(path) for path in paths], top_name)
        for top_name in top_names
    ]


def load_design(
    verilog_files: Sequence[str | Path],
    top_module: Optional[str] = None,
    unified_compilation_unit: bool = False,
) -> ElaboratedDesign:
    """Elaborate a file set and select one top-level design."""
    if not verilog_files:
        raise DesignError("at least one RTL source file is required")
    syntax_tree_cls = _pyslang_class("SyntaxTree", "syntax")
    paths = [Path(source).resolve() for source in verilog_files]
    for path in paths:
        if not path.is_file():
            raise FileNotFoundError(f"RTL source not found: {path}")
    # A few legacy generated projects intentionally share macros across an
    # ordered source list. Preserve the frozen per-file mode by default while
    # supporting a standard single compilation unit when requested.
    trees = ([syntax_tree_cls.fromFiles([str(path) for path in paths])]
             if unified_compilation_unit else
             [syntax_tree_cls.fromFile(str(path)) for path in paths])
    return _elaborate(trees, [str(path) for path in paths], top_module,
                      allow_use_before_declare=unified_compilation_unit)


def load_design_source(
    source: str,
    source_name: str = "<source>",
    top_module: Optional[str] = None,
) -> ElaboratedDesign:
    """Elaborate one in-memory SystemVerilog source."""
    syntax_tree_cls = _pyslang_class("SyntaxTree", "syntax")
    tree = syntax_tree_cls.fromText(source, source_name)
    return _elaborate([tree], [source_name], top_module)
