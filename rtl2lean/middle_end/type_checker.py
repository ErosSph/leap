"""
类型检查器 - 验证 AST 的类型正确性
"""

from __future__ import annotations

import logging
from dataclasses import dataclass, field
from typing import Optional

from ..frontend.ast import (
    ArraySelect, BinOp, BitLit, BitRange, BitSelect, CallExpr, Concat, CondExpr, DataType,
    Expr, Ident, IntLit, Module, Port, Stmt, UnaryOp, UnknownLit,
    LocalDecl, FunctionEval,
)

logger = logging.getLogger(__name__)


@dataclass
class TypeError:
    line: int = 0
    column: int = 0
    message: str = ""

    def __str__(self) -> str:
        return f"@{self.line}:{self.column}: 类型错误：{self.message}"


@dataclass
class TypeCheckerState:
    env: dict[str, DataType] = field(default_factory=dict)
    parameters: dict[str, DataType] = field(default_factory=dict)
    errors: list[TypeError] = field(default_factory=list)
    current_width: int = 32


class TypeChecker:
    """类型检查器"""

    def __init__(self):
        self.state = TypeCheckerState()

    @classmethod
    def check_module(cls, mod: Module) -> tuple[Module, list[TypeError]]:
        """检查模块类型，返回 (模块, 错误列表)"""
        checker = cls()
        checker._check_module(mod)
        return mod, checker.state.errors

    def _check_module(self, mod: Module) -> None:
        # 处理参数
        for param in mod.parameters:
            self.state.parameters[param.name] = param.data_type

        # 处理端口
        for port in mod.ports:
            self._add_var(port.name, port.data_type)

        # 处理声明
        for decl in mod.declarations:
            for name in decl.names:
                self._add_var(name, decl.data_type)

        # 处理连续赋值
        for ca in mod.continuous_assigns:
            self._check_expr(ca.target)
            self._check_expr(ca.value)

        # 处理进程
        for proc in mod.processes:
            self._check_stmt(proc.body)

    def _add_var(self, name: str, typ: DataType) -> None:
        self.state.env[name] = typ

    def _lookup(self, name: str) -> Optional[DataType]:
        return self.state.env.get(name) or self.state.parameters.get(name)

    def _check_expr(self, expr: Expr) -> DataType:
        """检查表达式类型，返回推断的类型"""
        if isinstance(expr, IntLit):
            return DataType.Integer
        if isinstance(expr, BitLit):
            return DataType.LogicVector
        if isinstance(expr, UnknownLit):
            return DataType.LogicVector
        if isinstance(expr, Ident):
            t = self._lookup(expr.name)
            if t is None:
                self.state.errors.append(TypeError(message=f"未声明的变量：{expr.name}"))
                return DataType.Logic
            return t
        if isinstance(expr, UnaryOp):
            self._check_expr(expr.operand)
            return DataType.Logic
        if isinstance(expr, BinOp):
            lt = self._check_expr(expr.left)
            rt = self._check_expr(expr.right)
            return self._wider_type(lt, rt)
        if isinstance(expr, BitSelect):
            self._check_expr(expr.expr)
            self._check_expr(expr.index)
            return DataType.Logic  # 位选择结果是单比特
        if isinstance(expr, ArraySelect):
            self._check_expr(expr.expr)
            self._check_expr(expr.index)
            return DataType.LogicVector
        if isinstance(expr, BitRange):
            self._check_expr(expr.expr)
            return DataType.LogicVector
        if isinstance(expr, Concat):
            for e in expr.exprs:
                self._check_expr(e)
            return DataType.LogicVector
        if isinstance(expr, CondExpr):
            self._check_expr(expr.cond)
            lt = self._check_expr(expr.then_expr)
            rt = self._check_expr(expr.else_expr)
            return self._wider_type(lt, rt)
        if isinstance(expr, CallExpr):
            for arg in expr.args:
                self._check_expr(arg)
            return DataType.Logic
        if isinstance(expr, FunctionEval):
            saved = dict(self.state.env)
            try:
                for name, width in expr.local_widths.items():
                    self.state.env[name] = DataType.Logic if width == 1 else DataType.LogicVector
                for name, _, actual in expr.arguments:
                    self._check_expr(actual)
                self._check_stmt(expr.body)
            finally:
                self.state.env = saved
            return DataType.Logic if expr.width == 1 else DataType.LogicVector
        return DataType.Logic

    def _check_stmt(self, stmt: Stmt) -> None:
        from ..frontend.ast import (
            BeginEnd, BlockingAssign, CaseStmt, ForLoop, ForeverLoop, IfStmt,
            NoStmt, NonBlockingAssign, WaitStmt, WhileLoop,
        )

        if isinstance(stmt, (BlockingAssign, NonBlockingAssign)):
            self._check_expr(stmt.target)
            self._check_expr(stmt.value)
        elif isinstance(stmt, LocalDecl):
            self.state.env[stmt.name] = DataType.Logic if stmt.width == 1 else DataType.LogicVector
            if stmt.initializer is not None:
                self._check_expr(stmt.initializer)
        elif isinstance(stmt, IfStmt):
            self._check_expr(stmt.cond)
            self._check_stmt(stmt.then_stmt)
            if stmt.else_stmt:
                self._check_stmt(stmt.else_stmt)
        elif isinstance(stmt, CaseStmt):
            self._check_expr(stmt.cond)
            for _, s in stmt.cases:
                self._check_stmt(s)
            if stmt.default_stmt:
                self._check_stmt(stmt.default_stmt)
        elif isinstance(stmt, ForLoop):
            self._check_stmt(stmt.init)
            self._check_expr(stmt.cond)
            self._check_stmt(stmt.update)
            self._check_stmt(stmt.body)
        elif isinstance(stmt, WhileLoop):
            self._check_expr(stmt.cond)
            self._check_stmt(stmt.body)
        elif isinstance(stmt, ForeverLoop):
            self._check_stmt(stmt.body)
        elif isinstance(stmt, BeginEnd):
            for s in stmt.stmts:
                self._check_stmt(s)
        elif isinstance(stmt, WaitStmt):
            self._check_expr(stmt.cond)

    @staticmethod
    def _type_width(t: DataType) -> int:
        widths = {
            DataType.Logic: 1, DataType.Wire: 1, DataType.Reg: 1,
            DataType.Bit: 1, DataType.Integer: 32,
            DataType.LogicVector: 32, DataType.WireVector: 32,
            DataType.RegVector: 32, DataType.BitVector: 32,
        }
        return widths.get(t, 32)

    @classmethod
    def _wider_type(cls, t1: DataType, t2: DataType) -> DataType:
        w1 = cls._type_width(t1)
        w2 = cls._type_width(t2)
        return t1 if w1 >= w2 else t2
