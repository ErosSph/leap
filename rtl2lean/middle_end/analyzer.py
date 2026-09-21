"""
静态分析器 - 对 IR 进行静态分析
"""

from __future__ import annotations

from dataclasses import dataclass, field

from .ir import IRFunction, IRModule, IRValue


@dataclass
class BlockAnalysis:
    """基本块分析结果"""
    block_name: str
    uses: list[str] = field(default_factory=list)
    defs: list[str] = field(default_factory=list)
    predecessors: list[str] = field(default_factory=list)
    successors: list[str] = field(default_factory=list)


@dataclass
class FunctionAnalysis:
    """函数分析结果"""
    function_name: str
    params: list[str] = field(default_factory=list)
    blocks: list[BlockAnalysis] = field(default_factory=list)
    entry_block: str = ""
    is_combinational: bool = True
    clock_signal: str | None = None
    reset_signal: str | None = None


@dataclass
class ModuleAnalysis:
    """模块分析结果"""
    module_name: str
    input_ports: list[str] = field(default_factory=list)
    output_ports: list[str] = field(default_factory=list)
    internal_signals: list[str] = field(default_factory=list)
    registers: list[str] = field(default_factory=list)
    functions: list[FunctionAnalysis] = field(default_factory=list)
    combinational_outputs: list[str] = field(default_factory=list)
    sequential_outputs: list[str] = field(default_factory=list)


def _extract_var_uses(value: IRValue) -> list[str]:
    """从 IR 值中提取变量名"""
    if value.kind == "var":
        return [value.data.get("name", "")]
    if value.kind == "unary":
        return _extract_var_uses(value.data["operand"])
    if value.kind == "binary":
        return _extract_var_uses(value.data["left"]) + _extract_var_uses(value.data["right"])
    if value.kind in {"bit_select", "array_select"}:
        return _extract_var_uses(value.data["value"]) + _extract_var_uses(value.data["index"])
    if value.kind == "array_store":
        return (
            _extract_var_uses(value.data["memory"])
            + _extract_var_uses(value.data["index"])
            + _extract_var_uses(value.data["value"])
        )
    if value.kind == "bit_store":
        return (
            _extract_var_uses(value.data["base"])
            + _extract_var_uses(value.data["index"])
            + _extract_var_uses(value.data["value"])
        )
    if value.kind == "range_store":
        return (
            _extract_var_uses(value.data["base"])
            + _extract_var_uses(value.data["value"])
        )
    if value.kind == "concat":
        result = []
        for v in value.data["values"]:
            result.extend(_extract_var_uses(v))
        return result
    if value.kind == "call":
        result = []
        for a in value.data["args"]:
            result.extend(_extract_var_uses(a))
        return result
    if value.kind == "phi":
        result = []
        for v in (value.data["cond"], value.data["then"], value.data["else"]):
            result.extend(_extract_var_uses(v))
        return result
    return []


def _extract_instr_uses(instr) -> tuple[list[str], list[str]]:
    """从指令中提取 (读变量, 写变量)"""
    reads: list[str] = []
    writes: list[str] = []

    if instr.kind in ("assign", "nba"):
        if instr.dest:
            writes.append(instr.dest)
        if instr.value:
            reads.extend(_extract_var_uses(instr.value))
    elif instr.kind == "branch" and instr.cond:
        reads.extend(_extract_var_uses(instr.cond))
    elif instr.kind == "call":
        if instr.dest:
            writes.append(instr.dest)
        for a in instr.args:
            reads.extend(_extract_var_uses(a))

    return reads, writes


class Analyzer:
    """静态分析器"""

    @classmethod
    def analyze_module(cls, ir_mod: IRModule) -> ModuleAnalysis:
        """分析 IR 模块"""
        input_ports = [name for name, _, is_in in ir_mod.ports if is_in]
        output_ports = [name for name, _, is_in in ir_mod.ports if not is_in]
        internal_signals = [name for name, _ in ir_mod.signals]
        register_names = [name for name, _ in ir_mod.registers]

        func_analyses = [cls._analyze_function(f) for f in ir_mod.functions]

        sequential_funcs = [f for f in func_analyses if not f.is_combinational]
        combinational_funcs = [f for f in func_analyses if f.is_combinational]

        sequential_outputs = []
        for f in sequential_funcs:
            for b in f.blocks:
                sequential_outputs.extend(b.defs)

        combinational_outputs = []
        for f in combinational_funcs:
            for b in f.blocks:
                combinational_outputs.extend(b.defs)

        return ModuleAnalysis(
            module_name=ir_mod.name,
            input_ports=input_ports,
            output_ports=output_ports,
            internal_signals=internal_signals,
            registers=register_names,
            functions=func_analyses,
            combinational_outputs=combinational_outputs,
            sequential_outputs=sequential_outputs,
        )

    @classmethod
    def _analyze_function(cls, func: IRFunction) -> FunctionAnalysis:
        block_analyses = []
        for block in func.blocks:
            uses = []
            defs = []
            for instr in block.instrs:
                r, w = _extract_instr_uses(instr)
                uses.extend(r)
                defs.extend(w)
            block_analyses.append(BlockAnalysis(
                block_name=block.name,
                uses=uses,
                defs=defs,
                predecessors=block.predecessors,
                successors=block.successors,
            ))

        # 分析是否为时序逻辑
        is_combinational = cls._is_combinational(func, block_analyses)
        clock_signal = func.clock_signal
        reset_signal = func.reset_signal

        return FunctionAnalysis(
            function_name=func.name,
            params=[name for name, _ in func.params],
            blocks=block_analyses,
            entry_block=func.entry_block,
            is_combinational=is_combinational,
            clock_signal=clock_signal,
            reset_signal=reset_signal,
        )

    @classmethod
    def _is_combinational(cls, func: IRFunction, block_analyses: list) -> bool:
        """判断函数是否为组合逻辑"""
        # 如果没有时钟/复位信号，则为组合逻辑
        if func.clock_signal is None and func.reset_signal is None:
            return True

        # 检查是否有循环
        for block in block_analyses:
            if block.block_name in block.successors:  # 自环
                return False

        return True

        return FunctionAnalysis(
            function_name=func.name,
            params=[name for name, _ in func.params],
            blocks=block_analyses,
            entry_block=func.entry_block,
            is_combinational=not func.is_sequential,
            clock_signal=func.clock_signal,
            reset_signal=func.reset_signal,
        )
