"""
抽象语法树 (AST) 定义

表示从 SystemVerilog 提取的结构化硬件描述。
"""

from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum, auto
from typing import Optional


# ───────────────────────── 数据类型 ─────────────────────────

class DataType(Enum):
    Logic = auto()
    Wire = auto()
    Reg = auto()
    Integer = auto()
    Bit = auto()
    LogicVector = auto()   # logic [hi:lo]
    WireVector = auto()    # wire [hi:lo]
    RegVector = auto()     # reg [hi:lo]
    BitVector = auto()     # bit [hi:lo]

    def __str__(self) -> str:
        return self.name

    @property
    def is_vector(self) -> bool:
        return self in (
            DataType.LogicVector, DataType.WireVector,
            DataType.RegVector, DataType.BitVector,
        )


@dataclass
class BitWidth:
    """位宽信息 [high:low]"""
    high: int
    low: int

    @property
    def width(self) -> int:
        return max(1, self.high - self.low + 1)

    def __str__(self) -> str:
        return f"[{self.high}:{self.low}]"


# ───────────────────────── 端口方向 ─────────────────────────

class PortDirection(Enum):
    Input = auto()
    Output = auto()
    Inout = auto()

    def __str__(self) -> str:
        return self.name.lower()


# ───────────────────────── 表达式 ─────────────────────────

@dataclass
class Expr:
    """表达式基类"""
    pass


@dataclass
class IntLit(Expr):
    value: int


@dataclass
class BitLit(Expr):
    """指定位宽的字面量，如 8'hFF"""
    width: int
    value: int


@dataclass
class UnknownLit(Expr):
    """An unspecified RTL literal represented by a binary choice input.

    ``known_mask`` marks bits fixed by the source literal. Bits outside that
    mask are selected by ``choice_name`` on every semantic step.
    """
    width: int
    known_mask: int
    known_value: int
    choice_name: str


@dataclass
class Ident(Expr):
    name: str


@dataclass
class UnaryOp(Expr):
    op: str  # "!", "-", "~", "&", "|", "^"
    operand: Expr


@dataclass
class IntegralCast(Expr):
    operand: Expr
    width: int
    signed: bool


@dataclass
class ContextWidth(Expr):
    operand: Expr
    width: int


@dataclass
class BinOp(Expr):
    op: str  # "+", "-", "*", "/", "%", "&", "|", "^", "==", "!=", "<", ">", "<=", ">=", "<<", ">>", "&&", "||"
    left: Expr
    right: Expr


@dataclass
class BitSelect(Expr):
    expr: Expr
    index: Expr


@dataclass
class ArraySelect(Expr):
    """Selection from a fixed-size unpacked array.

    The bounds are retained because SystemVerilog permits both ``[0:N]`` and
    ``[N:0]`` unpacked ranges, whose logical index-to-storage mapping differs.
    """
    expr: Expr
    index: Expr
    element_width: int
    left: int
    right: int

    @property
    def depth(self) -> int:
        return abs(self.left - self.right) + 1


@dataclass
class BitRange(Expr):
    expr: Expr
    hi: Expr
    lo: Expr


@dataclass
class Concat(Expr):
    exprs: list[Expr]


@dataclass
class CondExpr(Expr):
    """三元条件表达式: cond ? then : else"""
    cond: Expr
    then_expr: Expr
    else_expr: Expr


@dataclass
class CallExpr(Expr):
    name: str
    args: list[Expr]


@dataclass
class FunctionEval(Expr):
    """A checked pure function invocation evaluated in its own local environment."""
    arguments: list[tuple[str, int, Expr]]
    local_widths: dict[str, int]
    body: Stmt
    result_name: str
    width: int


# ───────────────────────── 语句 ─────────────────────────

@dataclass
class Stmt:
    """语句基类"""
    pass


@dataclass
class LocalDecl(Stmt):
    """Procedural temporary; never a module state field."""
    name: str
    width: int
    initializer: Optional[Expr] = None


@dataclass
class BlockingAssign(Stmt):
    """阻塞赋值: target = value"""
    target: Expr
    value: Expr


@dataclass
class NonBlockingAssign(Stmt):
    """非阻塞赋值: target <= value"""
    target: Expr
    value: Expr


@dataclass
class IfStmt(Stmt):
    cond: Expr
    then_stmt: Stmt
    else_stmt: Optional[Stmt] = None


@dataclass
class CaseStmt(Stmt):
    """case 语句"""
    cond: Expr
    cases: list[tuple[Expr, Stmt]]  # (pattern, statement)
    default_stmt: Optional[Stmt] = None


@dataclass
class ForLoop(Stmt):
    init: Stmt
    cond: Expr
    update: Stmt
    body: Stmt


@dataclass
class WhileLoop(Stmt):
    cond: Expr
    body: Stmt


@dataclass
class ForeverLoop(Stmt):
    body: Stmt


@dataclass
class BeginEnd(Stmt):
    stmts: list[Stmt]


@dataclass
class NoStmt(Stmt):
    pass


@dataclass
class ExprStmt(Stmt):
    """表达式语句"""
    expr: Expr


@dataclass
class WaitStmt(Stmt):
    cond: Expr


# ───────────────────────── 端口与参数 ─────────────────────────

@dataclass
class Port:
    direction: PortDirection
    data_type: DataType
    name: str
    bit_width: Optional[BitWidth] = None
    signed: bool = False

    @property
    def width(self) -> int:
        if self.bit_width:
            return self.bit_width.width
        return 1

    def __str__(self) -> str:
        bw = f" {self.bit_width}" if self.bit_width else ""
        return f"{self.direction} {self.data_type}{bw} {self.name}"


@dataclass
class Parameter:
    name: str
    default_value: Expr
    data_type: DataType = DataType.Integer


# ───────────────────────── 进程类型 ─────────────────────────

class ProcessType(Enum):
    Initial = auto()
    Always = auto()
    AlwaysComb = auto()
    AlwaysLatch = auto()
    AlwaysFF = auto()


@dataclass
class EventControl:
    """事件控制: @(posedge clk) 等"""
    events: list[tuple[str, str]]  # [("posedge", "clk"), ("negedge", "rst"), ...]

    @property
    def is_sequential(self) -> bool:
        """是否时序逻辑（包含边沿触发）"""
        return any(kind in ("posedge", "negedge") for kind, _ in self.events)

    @property
    def clock_signal(self) -> Optional[str]:
        for _, sig in self.events:
            if "clk" in sig.lower() or "clock" in sig.lower():
                return sig
        for kind, sig in self.events:
            if kind in ("posedge", "negedge"):
                return sig
        return None

    @property
    def reset_signal(self) -> Optional[str]:
        for _, sig in self.events:
            if "rst" in sig.lower() or "reset" in sig.lower():
                return sig
        return None

    @property
    def reset_active_high(self) -> bool:
        reset = self.reset_signal
        if reset is None:
            return True
        for edge, sig in self.events:
            if sig == reset:
                return edge != "negedge"
        return not reset.lower().endswith("_n")


@dataclass
class Process:
    """进程: always / initial 块"""
    proc_type: ProcessType
    event_control: Optional[EventControl]
    body: Stmt
    # Original nonlocal clocked assignment identities, before branch pruning.
    # Ident nodes participate in the same hierarchy renaming as expressions.
    state_targets: list[Ident] = field(default_factory=list)


@dataclass
class ContinuousAssign:
    """连续赋值: assign target = value;"""
    target: Expr
    value: Expr


# ───────────────────────── 声明 ─────────────────────────

@dataclass
class Declaration:
    """变量声明"""
    kind: str  # "wire", "reg", "logic", etc.
    data_type: DataType
    names: list[str]
    bit_width: Optional[BitWidth] = None
    unpacked_element_width: Optional[int] = None
    unpacked_left: Optional[int] = None
    unpacked_right: Optional[int] = None
    signed: bool = False

    @property
    def is_unpacked_array(self) -> bool:
        return self.unpacked_element_width is not None


# ───────────────────────── 模块项 ─────────────────────────

@dataclass
class ModuleItem:
    """模块项基类"""
    pass


@dataclass
class ModuleInstance(ModuleItem):
    """模块实例化"""
    instance_name: str
    module_name: str
    port_connections: list[tuple[str, Expr]]  # (port_name, connected_expr)


# ───────────────────────── 模块 ─────────────────────────

@dataclass
class Module:
    """Verilog 模块"""
    name: str
    parameters: list[Parameter] = field(default_factory=list)
    ports: list[Port] = field(default_factory=list)
    declarations: list[Declaration] = field(default_factory=list)
    continuous_assigns: list[ContinuousAssign] = field(default_factory=list)
    processes: list[Process] = field(default_factory=list)
    instances: list[ModuleInstance] = field(default_factory=list)

    @property
    def input_ports(self) -> list[Port]:
        return [p for p in self.ports if p.direction == PortDirection.Input]

    @property
    def output_ports(self) -> list[Port]:
        return [p for p in self.ports if p.direction == PortDirection.Output]

    @property
    def registers(self) -> list[tuple[str, int]]:
        """返回 (名称, 位宽) 列表"""
        regs = []
        for decl in self.declarations:
            if decl.kind in ("reg", "RegVector"):
                w = decl.bit_width.width if decl.bit_width else 1
                for name in decl.names:
                    regs.append((name, w))
        # 也检查 output reg 端口
        for port in self.ports:
            if port.direction == PortDirection.Output and port.data_type in (DataType.Reg, DataType.RegVector):
                regs.append((port.name, port.width))
        return regs

    @property
    def signals(self) -> list[tuple[str, int]]:
        """返回 (名称, 位宽) 列表"""
        sigs = []
        for decl in self.declarations:
            if decl.kind in ("wire", "WireVector", "logic", "LogicVector"):
                w = decl.bit_width.width if decl.bit_width else 1
                for name in decl.names:
                    sigs.append((name, w))
        # 也检查 output wire 端口（非 reg 类型）
        for port in self.ports:
            if port.direction == PortDirection.Output and port.data_type not in (DataType.Reg, DataType.RegVector):
                sigs.append((port.name, port.width))
        return sigs
