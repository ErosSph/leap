"""
中间表示 (IR) - RTL 的中间表示形式

IR 是 AST 和 Lean 代码生成之间的桥梁。
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Optional


# ───────────────────────── IR 类型 ─────────────────────────

@dataclass
class IRType:
    name: str
    width: int = 32

    @classmethod
    def void(cls) -> IRType:
        return cls("void", 0)

    @classmethod
    def bool(cls) -> IRType:
        return cls("bool", 1)

    @classmethod
    def uint(cls, width: int = 32) -> IRType:
        return cls("uint", width)

    @classmethod
    def int(cls, width: int = 32) -> IRType:
        return cls("int", width)

    @classmethod
    def clock(cls) -> IRType:
        return cls("clock", 1)

    @classmethod
    def reset(cls) -> IRType:
        return cls("reset", 1)

    @classmethod
    def wire(cls, width: int = 32) -> IRType:
        return cls("wire", width)

    @classmethod
    def reg(cls, width: int = 32) -> IRType:
        return cls("reg", width)

    def __str__(self) -> str:
        if self.name == "void":
            return "void"
        if self.name == "bool":
            return "Bool"
        if self.name in ("uint", "reg", "wire"):
            return f"UInt{self.width}"
        if self.name == "int":
            return f"Int{self.width}"
        if self.name == "clock":
            return "Bool"
        if self.name == "reset":
            return "Bool"
        return self.name

    @property
    def lean_type(self) -> str:
        """转换为 Lean 类型字符串"""
        return str(self)


# ───────────────────────── IR 值 ─────────────────────────

@dataclass
class IRValue:
    """IR 值表示"""
    kind: str  # "const_bool", "const_int", "const_nat", "var", "unary", "binary", "bit_select", "bit_range", "concat", "call", "phi"
    data: dict = field(default_factory=dict)

    @classmethod
    def const_bool(cls, value: bool) -> IRValue:
        return cls("const_bool", {"value": value})

    @classmethod
    def const_int(cls, width: int, value: int) -> IRValue:
        return cls("const_int", {"width": width, "value": value})

    @classmethod
    def const_nat(cls, width: int, value: int) -> IRValue:
        return cls("const_nat", {"width": width, "value": value})

    @classmethod
    def var(cls, name: str, typ: IRType) -> IRValue:
        return cls("var", {"name": name, "type": typ})

    @classmethod
    def unary(cls, op: str, operand: IRValue) -> IRValue:
        return cls("unary", {"op": op, "operand": operand})

    @classmethod
    def binary(cls, op: str, left: IRValue, right: IRValue) -> IRValue:
        return cls("binary", {"op": op, "left": left, "right": right})

    @classmethod
    def bit_select(cls, value: IRValue, index: IRValue) -> IRValue:
        return cls("bit_select", {"value": value, "index": index})

    @classmethod
    def array_select(
        cls, value: IRValue, index: IRValue, element_width: int,
        depth: int, left: int, right: int,
    ) -> IRValue:
        return cls("array_select", {
            "value": value, "index": index, "element_width": element_width,
            "depth": depth, "left": left, "right": right,
        })

    @classmethod
    def array_store(
        cls, memory: IRValue, index: IRValue, value: IRValue,
        element_width: int, depth: int, left: int, right: int,
    ) -> IRValue:
        return cls("array_store", {
            "memory": memory, "index": index, "value": value,
            "element_width": element_width, "depth": depth,
            "left": left, "right": right,
        })

    @classmethod
    def bit_store(cls, base: IRValue, index: IRValue, value: IRValue) -> IRValue:
        return cls("bit_store", {"base": base, "index": index, "value": value})

    @classmethod
    def range_store(
        cls, base: IRValue, hi: int, lo: int, value: IRValue,
    ) -> IRValue:
        return cls("range_store", {
            "base": base, "hi": hi, "lo": lo, "value": value,
        })

    @classmethod
    def bit_range(cls, value: IRValue, hi: int, lo: int) -> IRValue:
        return cls("bit_range", {"value": value, "hi": hi, "lo": lo})

    @classmethod
    def concat(cls, values: list[IRValue]) -> IRValue:
        return cls("concat", {"values": values})

    @classmethod
    def call(cls, name: str, args: list[IRValue]) -> IRValue:
        return cls("call", {"name": name, "args": args})

    @classmethod
    def phi(cls, cond: IRValue, then_value: IRValue, else_value: IRValue) -> IRValue:
        return cls("phi", {
            "cond": cond,
            "then": then_value,
            "else": else_value,
        })

    def is_const(self) -> bool:
        return self.kind.startswith("const_")

    @property
    def const_value(self) -> Optional[int]:
        if self.kind in ("const_int", "const_nat"):
            return self.data.get("value")
        if self.kind == "const_bool":
            return 1 if self.data.get("value") else 0
        return None


# ───────────────────────── IR 指令 ─────────────────────────

@dataclass
class IRInstr:
    """IR 指令"""
    kind: str  # "assign", "nba", "branch", "jump", "label", "return", "call", "load", "store", "assert", "nop"
    dest: Optional[str] = None
    value: Optional[IRValue] = None
    label: Optional[str] = None
    true_label: Optional[str] = None
    false_label: Optional[str] = None
    cond: Optional[IRValue] = None
    name: Optional[str] = None
    args: list[IRValue] = field(default_factory=list)
    message: str = ""

    @classmethod
    def assign(cls, dest: str, value: IRValue) -> IRInstr:
        return cls("assign", dest=dest, value=value)

    @classmethod
    def nba(cls, dest: str, value: IRValue) -> IRInstr:
        """非阻塞赋值"""
        return cls("nba", dest=dest, value=value)

    @classmethod
    def branch(cls, cond: IRValue, true_label: str, false_label: str) -> IRInstr:
        return cls("branch", cond=cond, true_label=true_label, false_label=false_label)

    @classmethod
    def jump(cls, label: str) -> IRInstr:
        return cls("jump", label=label)

    @classmethod
    def label(cls, name: str) -> IRInstr:
        return cls("label", label=name)

    @classmethod
    def ret(cls, value: Optional[IRValue] = None) -> IRInstr:
        return cls("return", value=value)

    @classmethod
    def call(cls, dest: Optional[str], name: str, args: list[IRValue]) -> IRInstr:
        return cls("call", dest=dest, name=name, args=args)

    @classmethod
    def assert_(cls, cond: IRValue, message: str = "") -> IRInstr:
        return cls("assert", cond=cond, message=message)

    @classmethod
    def nop(cls) -> IRInstr:
        return cls("nop")


# ───────────────────────── 基本块 ─────────────────────────

@dataclass
class IRBasicBlock:
    """基本块"""
    name: str
    params: list[tuple[str, IRType]] = field(default_factory=list)
    instrs: list[IRInstr] = field(default_factory=list)
    predecessors: list[str] = field(default_factory=list)
    successors: list[str] = field(default_factory=list)


# ───────────────────────── 函数 ─────────────────────────

@dataclass
class IRFunction:
    """函数/过程"""
    name: str
    params: list[tuple[str, IRType]] = field(default_factory=list)
    return_type: IRType = field(default_factory=IRType.void)
    blocks: list[IRBasicBlock] = field(default_factory=list)
    entry_block: str = "entry"
    is_sequential: bool = False
    clock_signal: Optional[str] = None
    reset_signal: Optional[str] = None
    reset_active_high: bool = True
    reset_is_async: bool = False
    clock_enable: Optional[str] = None


# ───────────────────────── IR 模块 ─────────────────────────

@dataclass
class IRModule:
    """IR 模块"""
    name: str
    parameters: list[tuple[str, IRType]] = field(default_factory=list)
    ports: list[tuple[str, IRType, bool]] = field(default_factory=list)  # (name, type, is_input)
    signals: list[tuple[str, IRType]] = field(default_factory=list)
    registers: list[tuple[str, int]] = field(default_factory=list)  # (name, width)
    functions: list[IRFunction] = field(default_factory=list)
    initial_blocks: list[IRBasicBlock] = field(default_factory=list)
    # Final statically evaluated values from synthesizable initial processes.
    initial_values: dict[str, IRValue] = field(default_factory=dict)
    instances: list[tuple[str, str, list[tuple[str, str]]]] = field(default_factory=list)
    enum_constants: list[tuple[str, int, int]] = field(default_factory=list)  # (name, value, width)
    memories: list[tuple[str, int, int, int, int]] = field(default_factory=list)
    # (name, element_width, depth, left, right); represented as one flat BitVec

    def __str__(self) -> str:
        lines = [f"module {self.name}"]
        if self.parameters:
            params = ", ".join(f"{n}: {t}" for n, t in self.parameters)
            lines.append(f"  #({params})")
        if self.ports:
            lines.append("  ports:")
            for name, typ, is_in in self.ports:
                direction = "input" if is_in else "output"
                lines.append(f"    {direction} {typ} {name}")
        if self.registers:
            lines.append("  registers:")
            for name, w in self.registers:
                lines.append(f"    reg [{w-1}:0] {name}")
        if self.signals:
            lines.append("  signals:")
            for name, typ in self.signals:
                lines.append(f"    wire {typ} {name}")
        if self.functions:
            lines.append(f"  functions: {len(self.functions)}")
        return "\n".join(lines)


class CombinationalDependencyError(RuntimeError):
    """Combinational functions cannot be placed in a sound evaluation order."""


def _ir_value_variables(value: IRValue | None) -> set[str]:
    """Collect variable names recursively referenced by an IR value."""
    if value is None:
        return set()
    if value.kind == "var":
        return {str(value.data["name"])}
    variables: set[str] = set()
    pending = list(value.data.values())
    while pending:
        item = pending.pop()
        if isinstance(item, IRValue):
            if item.kind == "var":
                variables.add(str(item.data["name"]))
            else:
                pending.extend(item.data.values())
        elif isinstance(item, (list, tuple)):
            pending.extend(item)
        elif isinstance(item, dict):
            pending.extend(item.values())
    return variables


def order_combinational_functions(
    functions: list[IRFunction],
) -> list[IRFunction]:
    """Stable topological order for acyclic combinational signal dependencies.

    Continuous assignments are concurrent in RTL.  The Lean model represents
    them as a state-transformer chain, so a producer must precede every
    consumer regardless of source order.  Reject multiple drivers and cycles
    instead of silently emitting an order-dependent model.
    """
    if len(functions) < 2:
        return list(functions)

    writes: list[set[str]] = []
    reads: list[set[str]] = []
    writer_by_signal: dict[str, int] = {}
    for index, function in enumerate(functions):
        function_writes: set[str] = set()
        function_reads: set[str] = set()
        for block in function.blocks:
            for instruction in block.instrs:
                if instruction.kind in {"assign", "nba"} and instruction.dest:
                    function_writes.add(instruction.dest)
                    function_reads.update(_ir_value_variables(instruction.value))
        for signal in function_writes:
            prior = writer_by_signal.get(signal)
            if prior is not None and prior != index:
                raise CombinationalDependencyError(
                    f"multiple combinational writers for {signal}: "
                    f"{functions[prior].name}, {function.name}"
                )
            writer_by_signal[signal] = index
        writes.append(function_writes)
        reads.append(function_reads)

    dependencies: list[set[int]] = []
    for index, function_reads in enumerate(reads):
        dependencies.append({
            writer_by_signal[name]
            for name in function_reads
            if name in writer_by_signal and writer_by_signal[name] != index
        })

    ordered_indices: list[int] = []
    remaining = set(range(len(functions)))
    while remaining:
        ready = [
            index for index in range(len(functions))
            if index in remaining
            and dependencies[index].isdisjoint(remaining)
        ]
        if not ready:
            names = ", ".join(functions[index].name for index in sorted(remaining))
            raise CombinationalDependencyError(
                f"combinational dependency cycle among: {names}"
            )
        for index in ready:
            ordered_indices.append(index)
            remaining.remove(index)

    return [functions[index] for index in ordered_indices]


def normalize_combinational_schedule(module: IRModule) -> IRModule:
    """Resolve only false multi-output block cycles in final-assignment IR.

    Existing acyclic schedules keep their function names and structure. A
    fallback is allowed only for pure single-block assignments with unique
    drivers, and must itself pass the ordinary acyclicity check.
    """
    from dataclasses import replace
    comb = [f for f in module.functions if not f.is_sequential]
    try:
        order_combinational_functions(comb)
        return module
    except CombinationalDependencyError as error:
        original_error = error
    seen = set()
    replacements = {}
    used_names = {f.name for f in module.functions}
    for f in comb:
        if len(f.blocks)!=1 or f.blocks[0].name!=f.entry_block:
            raise original_error
        assignments = []
        for ins in f.blocks[0].instrs:
            if ins.kind == "return" and ins.value is None:
                continue
            if ins.kind != "assign" or not ins.dest or ins.value is None or ins.dest in seen:
                raise original_error
            seen.add(ins.dest)
            assignments.append(ins)
        if len(assignments)<=1:
            replacements[f.name] = [f]
            continue
        split = []
        for index,ins in enumerate(assignments):
            name=f"{f.name}__assignment_{index}"
            while name in used_names:
                name += "_"
            used_names.add(name)
            split.append(replace(f,name=name,blocks=[IRBasicBlock(name=f.entry_block,instrs=[ins,IRInstr.ret()])]))
        replacements[f.name] = split
    flattened = [piece for f in comb for piece in replacements[f.name]]
    order_combinational_functions(flattened)  # genuine cycles still fail
    functions = [piece for f in module.functions for piece in
                 ([f] if f.is_sequential else replacements[f.name])]
    return replace(module,functions=functions)
