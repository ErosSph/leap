"""
AST 到 IR 的转换器（增强版）
"""

from __future__ import annotations

import logging
from typing import Optional

from ..frontend.ast import (
    ArraySelect, BeginEnd, BinOp, BitLit, BitRange, BitSelect, BlockingAssign, CallExpr,
    CaseStmt, Concat, CondExpr, ContinuousAssign, DataType, Expr,
    ForLoop, ForeverLoop, Ident, IfStmt, IntLit, Module, NoStmt,
    NonBlockingAssign, PortDirection, Process, ProcessType, Stmt, LocalDecl, FunctionEval,
    UnaryOp, WhileLoop, IntegralCast, ContextWidth, UnknownLit,
)
from .ir import (
    IRBasicBlock, IRFunction, IRInstr, IRModule, IRType, IRValue,
)

logger = logging.getLogger(__name__)

DEFAULT_WIDTH = 32


class SemanticLoweringError(RuntimeError):
    """The AST construct cannot yet be lowered without changing semantics."""


# ───────────────────────── 参数求值 ─────────────────────────

def evaluate_parameter_expr(expr: Expr, param_env: dict | None = None) -> int | None:
    """简化版参数表达式求值"""
    param_env = param_env or {}
    if isinstance(expr, IntLit):
        return expr.value
    if isinstance(expr, BitLit):
        return expr.value
    if isinstance(expr, Ident):
        if expr.name in param_env:
            return evaluate_parameter_expr(param_env[expr.name], param_env)
        return None
    if isinstance(expr, BinOp):
        left = evaluate_parameter_expr(expr.left, param_env)
        right = evaluate_parameter_expr(expr.right, param_env)
        if left is not None and right is not None:
            ops = {"+": lambda a, b: a + b, "-": lambda a, b: a - b,
                   "*": lambda a, b: a * b, "/": lambda a, b: a // b if b else 0}
            if expr.op in ops:
                return ops[expr.op](left, right)
    if isinstance(expr, CallExpr) and "$clog2" in expr.name and len(expr.args) == 1:
        import math
        arg_val = evaluate_parameter_expr(expr.args[0], param_env)
        if arg_val is not None and arg_val > 0:
            return int(math.ceil(math.log2(arg_val)))
    return None


# ───────────────────────── 类型转换 ─────────────────────────

def ast_type_to_ir(dt: DataType, width: int | None = None) -> IRType:
    """将 AST 数据类型转换为 IR 类型"""
    if width is None:
        w = DEFAULT_WIDTH if dt == DataType.Integer else 1
    else:
        w = max(1, width)
    if dt == DataType.Logic:
        return IRType.bool() if w == 1 else IRType.uint(w)
    if dt == DataType.Bit:
        return IRType.bool() if w == 1 else IRType.uint(w)
    if dt == DataType.Integer:
        return IRType.int(w)
    if dt == DataType.Wire:
        return IRType.bool() if w == 1 else IRType.wire(w)
    if dt == DataType.Reg:
        return IRType.bool() if w == 1 else IRType.reg(w)
    if dt in (DataType.LogicVector, DataType.BitVector):
        return IRType.bool() if w == 1 else IRType.uint(w)
    if dt in (DataType.WireVector, DataType.RegVector):
        return IRType.bool() if w == 1 else IRType.uint(w)
    return IRType.uint(w)


# ───────────────────────── 表达式转换 ─────────────────────────

def _resolve_width(name: str, expected_width: int | None, symtab: dict | None) -> int:
    """解析变量宽度"""
    if symtab and name in symtab:
        w = symtab[name]
        if w > 0:
            return w
    return expected_width or DEFAULT_WIDTH


def _expr_width(expr: Expr, symtab: dict | None) -> int | None:
    if isinstance(expr, (IntegralCast, ContextWidth)):
        return expr.width
    if isinstance(expr, FunctionEval):
        return expr.width
    if isinstance(expr, BitLit):
        return expr.width
    if isinstance(expr, UnknownLit):
        return expr.width
    if isinstance(expr, IntLit):
        return DEFAULT_WIDTH
    if isinstance(expr, Ident):
        return symtab.get(expr.name) if symtab else None
    if isinstance(expr, BitSelect):
        return 1
    if isinstance(expr, ArraySelect):
        return expr.element_width
    if isinstance(expr, BitRange):
        hi = evaluate_parameter_expr(expr.hi)
        lo = evaluate_parameter_expr(expr.lo)
        return hi - lo + 1 if hi is not None and lo is not None else None
    if isinstance(expr, Concat):
        widths = [_expr_width(item, symtab) for item in expr.exprs]
        return sum(widths) if all(width is not None for width in widths) else None
    if isinstance(expr, UnaryOp):
        return _expr_width(expr.operand, symtab)
    if isinstance(expr, BinOp):
        if expr.op in {"<<", ">>", "<<<", ">>>"}:
            return _expr_width(expr.left, symtab)
        if expr.op in ("==", "!=", "<", ">", "<=", ">=", "&&", "||"):
            return 1
        widths = [_expr_width(expr.left, symtab), _expr_width(expr.right, symtab)]
        known = [width for width in widths if width is not None]
        return max(known) if known else None
    if isinstance(expr, CondExpr):
        widths = [
            _expr_width(expr.then_expr, symtab),
            _expr_width(expr.else_expr, symtab),
        ]
        known = [width for width in widths if width is not None]
        return max(known) if known else None
    return None


def expr_to_ir(
    expr: Expr,
    expected_width: int | None = None,
    symtab: dict | None = None,
    bindings: dict[str, IRValue] | None = None,
) -> IRValue:
    """将 AST 表达式转换为 IR 值"""
    if isinstance(expr, ContextWidth):
        operand = expr.operand
        width = max(expr.width, _expr_width(operand, symtab) or expr.width)
        if isinstance(operand, BinOp) and operand.op in {"+","-","*","/","%","&","|","^","~^"}:
            value = IRValue.binary(operand.op,
                expr_to_ir(ContextWidth(operand.left,width),width,symtab,bindings),
                expr_to_ir(ContextWidth(operand.right,width),width,symtab,bindings))
        elif isinstance(operand, BinOp) and operand.op in {"<<", ">>", "<<<", ">>>"}:
            value = IRValue.binary(operand.op,
                expr_to_ir(ContextWidth(operand.left,width),width,symtab,bindings),
                expr_to_ir(operand.right,None,symtab,bindings))
        elif isinstance(operand, UnaryOp) and operand.op in {"+","-","~"}:
            value = IRValue.unary(operand.op,expr_to_ir(ContextWidth(operand.operand,width),width,symtab,bindings))
        elif isinstance(operand, CondExpr):
            value = IRValue.phi(expr_to_ir(operand.cond,None,symtab,bindings),
                expr_to_ir(ContextWidth(operand.then_expr,width),width,symtab,bindings),
                expr_to_ir(ContextWidth(operand.else_expr,width),width,symtab,bindings))
        elif isinstance(operand, IntegralCast):
            value = expr_to_ir(operand,width,symtab,bindings)
        elif isinstance(operand,(BitLit,IntLit)):
            value = expr_to_ir(operand,width,symtab,bindings)
        else:
            value = expr_to_ir(IntegralCast(operand,width,False),width,symtab,bindings)
        return (IRValue.bit_select(value,IRValue.const_nat(32,0)) if expr.width == 1 else
                IRValue.bit_range(value,expr.width-1,0))
    if isinstance(expr, IntegralCast):
        source_width = _expr_width(expr.operand, symtab)
        if source_width is None or source_width <= 0:
            raise SemanticLoweringError("cannot determine integral cast source width")
        raw = expr_to_ir(expr.operand, None, symtab, bindings)
        operand = raw if source_width == 1 else IRValue.bit_range(raw, source_width-1, 0)
        target_width = max(expr.width, expected_width or expr.width)
        if target_width <= source_width:
            return (IRValue.bit_select(operand,IRValue.const_nat(32,0)) if target_width == 1 else
                    IRValue.bit_range(operand, target_width-1, 0))
        extra = target_width-source_width
        prefix = IRValue.const_nat(extra, 0)
        if expr.signed:
            prefix = IRValue.phi(IRValue.bit_select(operand, IRValue.const_nat(32, source_width-1)),
                                 IRValue.const_nat(extra, (1 << extra)-1), prefix)
        return IRValue.concat([prefix, operand])
    if isinstance(expr, FunctionEval):
        local_symtab = dict(symtab or {}, **expr.local_widths)
        env = dict(bindings or {})
        env.update({name:None for name in expr.local_widths})
        for name,width,actual in expr.arguments:
            env[name] = IRValue.bit_range(expr_to_ir(actual,width,symtab,bindings),width-1,0)
        commits = {}
        _lower_stmt(expr.body,local_symtab,env,commits,frozenset(expr.local_widths))
        if commits:
            raise SemanticLoweringError("pure function unexpectedly committed nonlocal state")
        result = env.get(expr.result_name)
        if result is None:
            raise SemanticLoweringError("function return value not definitely assigned")
        return IRValue.bit_range(result,expr.width-1,0)
    if isinstance(expr, IntLit):
        w = expected_width or DEFAULT_WIDTH
        return IRValue.const_int(w, expr.value)
    if isinstance(expr, BitLit):
        return IRValue.const_nat(expected_width or expr.width, expr.value)
    if isinstance(expr, UnknownLit):
        width = expected_width or expr.width
        choice = IRValue.var(expr.choice_name, IRType.uint(width))
        mask = (1 << width) - 1
        known_mask = expr.known_mask & mask
        known_value = expr.known_value & mask
        if known_mask == 0:
            return choice
        unknown_mask = mask ^ known_mask
        return IRValue.binary(
            "|",
            IRValue.binary("&", choice, IRValue.const_nat(width, unknown_mask)),
            IRValue.const_nat(width, known_value),
        )
    if isinstance(expr, Ident):
        name = expr.name
        if bindings and name in bindings:
            if bindings[name] is None:
                raise SemanticLoweringError(f"local temporary read before definite assignment: {name}")
            return bindings[name]
        w = _resolve_width(name, expected_width, symtab)
        if name.startswith("!") and len(name) > 1:
            inner = name[1:]
            iw = _resolve_width(inner, expected_width, symtab)
            return IRValue.unary("!", IRValue.var(inner, IRType.uint(iw)))
        return IRValue.var(name, IRType.uint(w))
    if isinstance(expr, UnaryOp):
        operand = expr_to_ir(expr.operand, expected_width, symtab, bindings)
        op = "reduce_xor" if expr.op == "^" else expr.op
        return IRValue.unary(op, operand)
    if isinstance(expr, BinOp):
        if expr.op in {"<<", ">>", "<<<", ">>>"}:
            source_width = _expr_width(expr.left, symtab) or DEFAULT_WIDTH
            width = max(source_width, expected_width or source_width)
            left_expr = ContextWidth(expr.left,width) if width > source_width else expr.left
            return IRValue.binary(expr.op,expr_to_ir(left_expr,width,symtab,bindings),
                                  expr_to_ir(expr.right,None,symtab,bindings))
        logical_or_comparison = expr.op in (
            "==", "!=", "<", ">", "<=", ">=", "&&", "||"
        )
        operand_width = None if logical_or_comparison else expected_width
        if operand_width is None and expr.op not in ("&&", "||"):
            widths = [_expr_width(expr.left, symtab), _expr_width(expr.right, symtab)]
            known = [width for width in widths if width is not None]
            operand_width = max(known) if known else None
        left = expr_to_ir(expr.left, operand_width, symtab, bindings)
        right = expr_to_ir(expr.right, operand_width, symtab, bindings)
        return IRValue.binary(expr.op, left, right)
    if isinstance(expr, BitSelect):
        # Both operands are self-determined. The one-bit selected result must
        # not narrow the source expression or its declaration-index arithmetic.
        return IRValue.bit_select(
            expr_to_ir(expr.expr, None, symtab, bindings),
            expr_to_ir(expr.index, None, symtab, bindings))
    if isinstance(expr, ArraySelect):
        return IRValue.array_select(
            expr_to_ir(expr.expr, None, symtab, bindings),
            expr_to_ir(expr.index, None, symtab, bindings),
            expr.element_width,
            expr.depth,
            expr.left,
            expr.right,
        )
    if isinstance(expr, BitRange):
        hi_raw = evaluate_parameter_expr(expr.hi) if not isinstance(expr.hi, IntLit) else expr.hi.value
        lo_raw = evaluate_parameter_expr(expr.lo) if not isinstance(expr.lo, IntLit) else expr.lo.value
        if hi_raw is None or lo_raw is None:
            raise SemanticLoweringError("dynamic packed range selection is unsupported")
        hi = hi_raw
        lo = lo_raw
        return IRValue.bit_range(
            expr_to_ir(expr.expr, expected_width, symtab, bindings), hi, lo
        )
    if isinstance(expr, Concat):
        vals = [expr_to_ir(e, None, symtab, bindings) for e in expr.exprs]
        # A legal zero replication inside a nonempty concatenation contributes
        # zero bits, not a binary zero. Preserve all other nesting unchanged.
        nonempty = [v for v in vals if not (v.kind == "concat" and not v.data["values"])]
        if len(nonempty) != len(vals):
            return nonempty[0] if len(nonempty) == 1 else IRValue.concat(nonempty)
        return IRValue.concat(vals)
    if isinstance(expr, CondExpr):
        cond = expr_to_ir(expr.cond, None, symtab, bindings)
        then_v = expr_to_ir(expr.then_expr, expected_width, symtab, bindings)
        else_v = expr_to_ir(expr.else_expr, expected_width, symtab, bindings)
        return IRValue.phi(cond, then_v, else_v)
    if isinstance(expr, CallExpr):
        return IRValue.call(
            expr.name,
            [expr_to_ir(a, expected_width, symtab, bindings) for a in expr.args],
        )
    raise SemanticLoweringError(
        f"unsupported AST expression during IR lowering: {type(expr).__name__}"
    )


# ───────────────────────── 语句转换 ─────────────────────────

def _extract_name(expr: Expr) -> str:
    if isinstance(expr, Ident):
        return expr.name
    if isinstance(expr, (BitSelect, BitRange)) and isinstance(expr.expr, Ident):
        return expr.expr.name
    if isinstance(expr, ArraySelect) and isinstance(expr.expr, Ident):
        return expr.expr.name
    raise SemanticLoweringError(
        f"unsupported assignment target: {type(expr).__name__}; "
        "slice/concat lvalues require explicit lowering"
    )


def _old_value(name: str, symtab: dict | None, env: dict[str, IRValue]) -> IRValue:
    if name in env:
        return env[name]
    width = symtab.get(name, DEFAULT_WIDTH) if symtab else DEFAULT_WIDTH
    return IRValue.var(name, IRType.uint(width))


def _target_leaves(target):
    if isinstance(target, Concat):
        for part in target.exprs:
            yield from _target_leaves(part)
    else:
        yield target


def _concat_layout(target, symtab):
    leaves = list(_target_leaves(target))
    widths = []
    occupied = {}
    for leaf in leaves:
        name = _extract_name(leaf)
        width = _expr_width(leaf, symtab)
        if width is None or width <= 0 or isinstance(leaf, ArraySelect):
            raise SemanticLoweringError("concat lvalue requires known packed widths")
        if isinstance(leaf, Ident):
            lo, hi = 0, width-1
        elif isinstance(leaf, BitRange):
            lo, hi = evaluate_parameter_expr(leaf.lo), evaluate_parameter_expr(leaf.hi)
        elif isinstance(leaf, BitSelect):
            lo = hi = evaluate_parameter_expr(leaf.index)
        else:
            raise SemanticLoweringError("unsupported concat lvalue leaf")
        if lo is None or hi is None or lo < 0 or hi < lo or hi >= symtab.get(name, 0):
            raise SemanticLoweringError("concat lvalue requires static in-range slices")
        if any(not (hi < a or lo > b) for a,b in occupied.setdefault(name, [])):
            raise SemanticLoweringError("overlapping concat lvalue slices are unsupported")
        occupied[name].append((lo,hi))
        widths.append(width)
    offset = sum(widths)
    result = []
    for leaf,width in zip(leaves,widths):
        result.append((leaf,offset-1,offset-width))
        offset -= width
    return sum(widths), result


def _lower_stmt(
    stmt: Stmt,
    symtab: dict | None,
    env: dict[str, IRValue],
    commits: dict[str, IRValue],
    local_names: frozenset[str] = frozenset(),
) -> None:
    """Symbolically execute one procedural block.

    Blocking assignments update ``env`` immediately. Non-blocking assignments
    update only ``commits``, so later RHS expressions still observe old state.
    Branches merge both environments and scheduled updates with explicit phi
    expressions.
    """
    if stmt is None or isinstance(stmt, NoStmt):
        return
    if isinstance(stmt, LocalDecl):
        env[stmt.name] = (IRValue.bit_range(expr_to_ir(stmt.initializer, stmt.width, symtab, env), stmt.width-1, 0)
                          if stmt.initializer is not None else None)
        return
    if isinstance(stmt, BeginEnd):
        for child in stmt.stmts:
            _lower_stmt(child, symtab, env, commits, local_names)
        return
    if isinstance(stmt, (BlockingAssign, NonBlockingAssign)):
        if isinstance(stmt.target, Concat):
            width, pieces = _concat_layout(stmt.target, symtab or {})
            # Snapshot the entire RHS before any destination is updated. Static
            # destination indices are checked above, so no later LHS evaluation
            # can accidentally observe an earlier blocking write.
            rhs = expr_to_ir(ContextWidth(stmt.value,width), width, symtab, env)
            temporary = "__rtl2lean_concat_rhs"
            while temporary in env or temporary in (symtab or {}):
                temporary += "_"
            extended = dict(symtab or {}, **{temporary:width})
            env[temporary] = IRValue.bit_range(rhs,width-1,0)
            try:
                for target,hi,lo in pieces:
                    value = BitSelect(Ident(temporary),IntLit(lo)) if hi == lo else BitRange(Ident(temporary),IntLit(hi),IntLit(lo))
                    part = type(stmt)(target, value)
                    _lower_stmt(part,extended,env,commits,local_names)
            finally:
                env.pop(temporary)
            return
        dest = _extract_name(stmt.target)
        if dest in local_names and isinstance(stmt, NonBlockingAssign):
            raise SemanticLoweringError("nonblocking local assignment requires persistent lifetime semantics")
        if dest in local_names and not isinstance(stmt.target, Ident):
            raise SemanticLoweringError("partial local assignment requires definite-bit assignment analysis")
        width = symtab.get(dest) if symtab else None
        if isinstance(stmt.target, ArraySelect):
            target = stmt.target
            value = expr_to_ir(stmt.value, target.element_width, symtab, env)
            old_memory = _old_value(dest, symtab, env)
            # Multiple partial NBAs to one memory must accumulate scheduled
            # writes while every RHS and index still reads the old environment.
            memory = (
                commits.get(dest, old_memory)
                if isinstance(stmt, NonBlockingAssign)
                else old_memory
            )
            value = IRValue.array_store(
                memory,
                expr_to_ir(target.index, None, symtab, env),
                value,
                target.element_width,
                target.depth,
                target.left,
                target.right,
            )
        elif isinstance(stmt.target, BitSelect):
            target = stmt.target
            value = expr_to_ir(stmt.value, 1, symtab, env)
            old_base = _old_value(dest, symtab, env)
            base = (
                commits.get(dest, old_base)
                if isinstance(stmt, NonBlockingAssign)
                else old_base
            )
            value = IRValue.bit_store(
                base,
                expr_to_ir(target.index, None, symtab, env),
                value,
            )
        elif isinstance(stmt.target, BitRange):
            target = stmt.target
            hi = evaluate_parameter_expr(target.hi)
            lo = evaluate_parameter_expr(target.lo)
            if hi is None or lo is None:
                raise SemanticLoweringError("dynamic packed range assignment is unsupported")
            slice_width = hi - lo + 1
            value = expr_to_ir(stmt.value, slice_width, symtab, env)
            old_base = _old_value(dest, symtab, env)
            base = (
                commits.get(dest, old_base)
                if isinstance(stmt, NonBlockingAssign)
                else old_base
            )
            value = IRValue.range_store(base, hi, lo, value)
        else:
            rhs = stmt.value
            # Assignment conversion must happen before a blocking write enters
            # env, not only when the final State field is printed.
            if width and _expr_width(rhs, symtab) != width:
                rhs = ContextWidth(rhs,width)
            value = expr_to_ir(rhs, width, symtab, env)
        if dest in local_names:
            value = IRValue.bit_range(value, width-1, 0)
        else:
            commits[dest] = value
        if isinstance(stmt, BlockingAssign):
            env[dest] = value
        return
    if isinstance(stmt, CaseStmt):
        nested: Stmt = stmt.default_stmt or NoStmt()
        for pattern, branch in reversed(stmt.cases):
            nested = IfStmt(BinOp("==", stmt.cond, pattern), branch, nested)
        _lower_stmt(nested, symtab, env, commits, local_names)
        return
    if isinstance(stmt, IfStmt):
        cond = expr_to_ir(stmt.cond, None, symtab, env)
        base_env = dict(env)
        base_commits = dict(commits)
        then_env, else_env = dict(env), dict(env)
        then_commits, else_commits = dict(commits), dict(commits)
        _lower_stmt(stmt.then_stmt, symtab, then_env, then_commits, local_names)
        _lower_stmt(stmt.else_stmt, symtab, else_env, else_commits, local_names)

        # A branch merge must compare each branch with the incoming value, not
        # only with the other branch.  In particular, both branches can assign
        # the same new value (common in adjacent/default case arms).  The old
        # implementation then saw equal branch maps and incorrectly retained
        # the pre-branch value.
        for name in sorted(set(then_env) | set(else_env) | set(base_env)):
            old = base_env.get(name, _old_value(name, symtab, base_env))
            then_value = then_env.get(name, old)
            else_value = else_env.get(name, old)
            if name in local_names and (then_value is None or else_value is None):
                env[name] = None
                continue
            if then_value != old or else_value != old:
                env[name] = (
                    then_value
                    if then_value == else_value
                    else IRValue.phi(cond, then_value, else_value)
                )

        for name in sorted(set(then_commits) | set(else_commits) | set(base_commits)):
            old = base_commits.get(name, _old_value(name, symtab, base_env))
            then_value = then_commits.get(name, old)
            else_value = else_commits.get(name, old)
            if then_value != old or else_value != old:
                commits[name] = (
                    then_value
                    if then_value == else_value
                    else IRValue.phi(cond, then_value, else_value)
                )
        return
    raise SemanticLoweringError(f"unsupported statement: {type(stmt).__name__}")


def collect_assigns_from_stmt(stmt: Stmt, symtab: dict | None = None) -> dict:
    def declarations(node):
        if isinstance(node, LocalDecl):
            yield node
        elif isinstance(node, BeginEnd):
            for child in node.stmts:
                yield from declarations(child)
        elif isinstance(node, IfStmt):
            yield from declarations(node.then_stmt)
            yield from declarations(node.else_stmt)
        elif isinstance(node, CaseStmt):
            for _, branch in node.cases:
                yield from declarations(branch)
            yield from declarations(node.default_stmt)
    locals_ = {d.name: d.width for d in declarations(stmt)}
    symtab = dict(symtab or {}, **locals_)
    env = {name: None for name in locals_}
    commits: dict[str, IRValue] = {}
    _lower_stmt(stmt, symtab, env, commits, frozenset(locals_))
    return commits


def stmt_to_instrs(
    stmt: Stmt,
    is_sequential: bool = False,
    symtab: dict | None = None,
) -> list[IRInstr]:
    commits = collect_assigns_from_stmt(stmt, symtab)
    kind = "nba" if is_sequential else "assign"
    return [
        IRInstr(kind=kind, dest=dest, value=value)
        for dest, value in sorted(commits.items())
    ]


def _collect_nba_targets(stmt: Stmt) -> set:
    """收集语句中所有非阻塞赋值的目标变量"""
    targets = set()
    if isinstance(stmt, NonBlockingAssign):
        targets.update(_extract_name(leaf) for leaf in _target_leaves(stmt.target))
    elif isinstance(stmt, BeginEnd):
        for s in stmt.stmts:
            targets.update(_collect_nba_targets(s))
    elif isinstance(stmt, IfStmt):
        targets.update(_collect_nba_targets(stmt.then_stmt))
        if stmt.else_stmt:
            targets.update(_collect_nba_targets(stmt.else_stmt))
    elif isinstance(stmt, CaseStmt):
        for _, case_stmt in stmt.cases:
            targets.update(_collect_nba_targets(case_stmt))
        if stmt.default_stmt:
            targets.update(_collect_nba_targets(stmt.default_stmt))
    return targets


# ───────────────────────── 模块转换 ─────────────────────────

def module_to_ir(mod: Module) -> IRModule:
    """将 AST 模块转换为 IR 模块"""
    logger.info(f"转换模块 {mod.name} 到 IR")

    # 构建参数环境
    param_env: dict[str, Expr] = {}
    for param in mod.parameters:
        param_env[param.name] = param.default_value

    # Discover explicit binary choices introduced by unspecified literals.
    # They are generated from AST occurrences, never from DUT names or signals.
    from dataclasses import fields, is_dataclass
    choices: dict[str, int] = {}

    def collect_choices(value) -> None:
        if isinstance(value, UnknownLit):
            prior = choices.setdefault(value.choice_name, value.width)
            if prior != value.width:
                raise SemanticLoweringError("nondeterministic choice width collision")
            return
        if is_dataclass(value):
            for field in fields(value):
                collect_choices(getattr(value, field.name))
        elif isinstance(value, (list, tuple)):
            for item in value:
                collect_choices(item)
        elif isinstance(value, dict):
            for item in value.values():
                collect_choices(item)

    collect_choices(mod)
    declared_names = {port.name for port in mod.ports}
    declared_names.update(name for declaration in mod.declarations for name in declaration.names)
    collision = sorted(declared_names & set(choices))
    if collision:
        raise SemanticLoweringError(f"generated nondeterministic input collision: {collision}")

    # 转换端口（使用实际位宽）
    ports = []
    for port in mod.ports:
        width = port.width
        ir_type = ast_type_to_ir(port.data_type, width)
        is_input = port.direction == PortDirection.Input
        ports.append((port.name, ir_type, is_input))
    ports.extend((name, IRType.uint(width), True) for name, width in choices.items())

    memories = []
    for declaration in mod.declarations:
        if not declaration.is_unpacked_array:
            continue
        assert declaration.unpacked_element_width is not None
        assert declaration.unpacked_left is not None
        assert declaration.unpacked_right is not None
        depth = abs(declaration.unpacked_left - declaration.unpacked_right) + 1
        for name in declaration.names:
            memories.append((
                name,
                declaration.unpacked_element_width,
                depth,
                declaration.unpacked_left,
                declaration.unpacked_right,
            ))

    # 转换信号（排除 input/output 端口名）
    port_names = {p.name for p in mod.ports}
    signals = []
    for name, w in mod.signals:
        actual_w = w if w > 1 else w
        signals.append((name, IRType.wire(actual_w)))

    # 收集 always_comb 中赋值的变量
    # 先构建临时 symtab
    temp_symtab: dict[str, int] = {}
    # Early assignment collection now performs width conversions as well;
    # include wires and flattened child inputs, not only storage declarations.
    for name, typ in signals:
        temp_symtab[name] = typ.width
    for name, typ, is_in in ports:
        w = getattr(typ, 'width', 1) or 1
        temp_symtab[name] = w
    for name, w in mod.registers:
        temp_symtab[name] = w

    comb_assigned_vars = set()
    for proc in mod.processes:
        is_comb = (proc.proc_type == ProcessType.AlwaysComb or
                   (proc.proc_type == ProcessType.Always and
                    not (proc.event_control and proc.event_control.is_sequential)))
        if is_comb and proc.body:
            assigns = collect_assigns_from_stmt(proc.body, temp_symtab)
            comb_assigned_vars.update(assigns.keys())

    # 注入 always_comb 赋值的变量到信号列表
    input_port_names = {
        port.name for port in mod.ports if port.direction == PortDirection.Input
    }
    port_widths = {port.name: port.width for port in mod.ports}
    for name in sorted(comb_assigned_vars):
        if name not in [s[0] for s in signals] and name not in input_port_names:
            width = port_widths.get(name, dict(mod.registers).get(name, 32))
            signals.append((name, IRType.uint(width)))

    # Preserve original clocked identities even after constant branch pruning.
    # The lowered commits include nonlocal blocking as well as NBA assignments.
    ff_assigned_vars = set()
    for proc in mod.processes:
        is_seq = (proc.proc_type == ProcessType.AlwaysFF or
                   (proc.proc_type == ProcessType.Always and
                    proc.event_control and proc.event_control.is_sequential))
        if is_seq and proc.body:
            ff_assigned_vars.update(target.name for target in proc.state_targets)
            ff_assigned_vars.update(collect_assigns_from_stmt(proc.body, temp_symtab))

    # A value written by a synthesizable initial block is persistent hardware
    # state even if it has no clocked writer (initialized output registers are
    # a common example).
    ff_assigned_vars.update(
        target.name
        for proc in mod.processes if proc.proc_type == ProcessType.Initial
        for target in proc.state_targets
    )

    # 寄存器提取
    registers = []
    seen = set()
    wire_names = {_extract_name(leaf) for ca in mod.continuous_assigns for leaf in _target_leaves(ca.target)}

    if ff_assigned_vars:
        # 有NBA目标信息时，精确识别
        reg_map = dict(mod.registers)
        reg_map.update({name:decl.bit_width.width if decl.bit_width else 1
                        for decl in mod.declarations for name in decl.names})
        reg_map.update(port_widths)
        for name in sorted(ff_assigned_vars):
            if name not in comb_assigned_vars and name not in seen and name not in wire_names:
                seen.add(name)
                registers.append((name, reg_map.get(name, 32)))
    else:
        # 回退：mod.registers 中的变量作为寄存器
        for name, w in mod.registers:
            if name not in comb_assigned_vars and name not in seen and name not in wire_names:
                seen.add(name)
                registers.append((name, w))
        # 补充：声明为非 wire 且不在连续赋值目标中的变量
        for decl in mod.declarations:
            is_wire_like = decl.data_type in (DataType.Wire, DataType.WireVector)
            if not is_wire_like:
                for name in decl.names:
                    if (name not in seen and name not in port_names
                            and name not in wire_names and name not in comb_assigned_vars):
                        w = decl.bit_width.width if decl.bit_width else 32
                        registers.append((name, max(w, 1)))
                        seen.add(name)

    # 过滤信号中已作为寄存器的
    reg_names = {name for name, _ in registers}
    signals = [(name, typ) for name, typ in signals if name not in reg_names]

    # A declared internal value that has no driver but is read by active RTL
    # cannot be replaced with zero.  Expose it as a formal binary input so all
    # of its possible bit patterns are quantified by the Lean transition.
    represented = {name for name, *_ in ports} | reg_names | {name for name, _ in signals}
    synthetic_undriven: set[str] = set()
    for declaration in mod.declarations:
        if declaration.is_unpacked_array:
            continue
        width = declaration.bit_width.width if declaration.bit_width else 1
        for name in declaration.names:
            if name not in represented:
                ports.append((name, IRType.uint(max(1, width)), True))
                represented.add(name)
                synthetic_undriven.add(name)

    # 构建完整 symtab
    symtab: dict[str, int] = {}
    for name, typ, is_in in ports:
        w = getattr(typ, 'width', 1) or 1
        if w:
            symtab[name] = w
    for name, typ in signals:
        w = getattr(typ, 'width', 1) or 1
        if w:
            symtab[name] = w
    for name, w in registers:
        symtab[name] = w
    for param in mod.parameters:
        val = evaluate_parameter_expr(param.default_value, param_env)
        if val is not None:
            symtab[param.name] = val

    # Statically execute initial blocks from the backend's binary-zero base.
    # Constant conditions have already been specialized by the frontend;
    # unsupported simulation actions still fail closed in build_stmt.
    initial_env: dict[str, IRValue] = {
        name: IRValue.const_nat(width, 0)
        for name, width in [*registers, *((n, t.width) for n, t in signals)]
    }
    initial_values: dict[str, IRValue] = {}
    for proc in mod.processes:
        if proc.proc_type != ProcessType.Initial:
            continue
        commits: dict[str, IRValue] = {}
        _lower_stmt(proc.body, symtab, initial_env, commits)
        for target in proc.state_targets:
            if target.name in commits:
                initial_env[target.name] = commits[target.name]
            if target.name not in initial_env:
                raise SemanticLoweringError(
                    f"initial assignment target is not representable state: {target.name}"
                )
            initial_values[target.name] = initial_env[target.name]

    # 提取枚举常量（如果 Module 支持 type_defs）
    enum_constants = []
    if hasattr(mod, 'type_defs') and mod.type_defs:
        for td in mod.type_defs:
            members = getattr(td, 'enum_members', [])
            for member in members:
                if hasattr(member, 'value') and member.value is not None:
                    w = td.bit_width.width if hasattr(td, 'bit_width') and td.bit_width else 32
                    enum_constants.append((member.name, member.value, w))
                    symtab[member.name] = w

    # 转换函数
    functions: list[IRFunction] = []
    func_name_counts: dict[str, int] = {}

    # 连续赋值 → assign_* 函数
    continuous_groups = {}
    for ca in mod.continuous_assigns:
        if isinstance(ca.target, Concat):
            width, pieces = _concat_layout(ca.target, symtab)
            for target,hi,lo in pieces:
                value = (BitSelect(ContextWidth(ca.value,width),IntLit(lo)) if hi == lo else
                         BitRange(ContextWidth(ca.value,width),IntLit(hi),IntLit(lo)))
                continuous_groups.setdefault(_extract_name(target), []).append(ContinuousAssign(target,value))
        else:
            continuous_groups.setdefault(_extract_name(ca.target), []).append(ca)
    for dest, assignments in continuous_groups.items():
        dest_w = symtab.get(dest)
        if len(assignments) == 1 and isinstance(assignments[0].target, Ident):
            rhs = assignments[0].value
            if dest_w and _expr_width(rhs, symtab) != dest_w:
                rhs = ContextWidth(rhs, dest_w)
            value = expr_to_ir(rhs, expected_width=dest_w, symtab=symtab)
        else:
            # Elaborated generate-for commonly drives one bit per instance.
            # Merge only statically disjoint, complete packed-vector drivers;
            # never turn concurrent writes into source-order overwrites.
            pieces = []
            for ca in assignments:
                if isinstance(ca.target, ArraySelect):
                    target = ca.target
                    index = evaluate_parameter_expr(target.index)
                    if index is None or not min(target.left,target.right)<=index<=max(target.left,target.right):
                        raise SemanticLoweringError(f"non-static or out-of-range continuous array driver: {dest}")
                    offset = index-target.left if target.left<=target.right else target.left-index
                    lo = offset * target.element_width
                    hi = lo + target.element_width - 1
                elif isinstance(ca.target, BitSelect):
                    lo = hi = evaluate_parameter_expr(ca.target.index)
                elif isinstance(ca.target, BitRange):
                    lo = evaluate_parameter_expr(ca.target.lo)
                    hi = evaluate_parameter_expr(ca.target.hi)
                else:
                    raise SemanticLoweringError(f"overlapping or unsupported continuous drivers: {dest}")
                if lo is None or hi is None or lo < 0 or hi < lo:
                    raise SemanticLoweringError(f"non-static continuous assignment range: {dest}")
                pieces.append((lo, hi, expr_to_ir(ca.value, hi-lo+1, symtab)))
            pieces.sort(key=lambda p: p[0])
            next_bit = 0
            for lo, hi, _ in pieces:
                if lo != next_bit:
                    raise SemanticLoweringError(f"overlapping or incomplete continuous drivers: {dest}")
                next_bit = hi + 1
            if next_bit != dest_w:
                raise SemanticLoweringError(f"incomplete continuous drivers: {dest}")
            value = IRValue.concat([piece[2] for piece in reversed(pieces)])
        instr = IRInstr.assign(dest, value)
        bb = IRBasicBlock(name="entry", instrs=[instr, IRInstr.ret()])
        func = IRFunction(
            name=f"assign_{dest}",
            params=[],
            return_type=IRType.void(),
            blocks=[bb],
            is_sequential=False,
        )
        functions.append(func)

    # always 块 → proc_* 函数
    for proc in mod.processes:
        # 根据进程类型和事件控制判断是否为时序逻辑
        if proc.proc_type == ProcessType.AlwaysFF:
            is_seq = True
        elif proc.proc_type == ProcessType.AlwaysComb:
            is_seq = False
        elif proc.proc_type == ProcessType.Always:
            # 通过 event_control 判断
            is_seq = proc.event_control.is_sequential if proc.event_control else False
        else:
            continue

        # 函数命名
        if proc.proc_type == ProcessType.AlwaysFF:
            base_name = "proc_alwaysff"
        elif proc.proc_type == ProcessType.AlwaysComb:
            base_name = "proc_alwayscomb"
        elif is_seq:
            base_name = "proc_alwaysff"
        else:
            base_name = "proc_alwayscomb"

        clock_sig = None
        reset_sig = None
        if proc.event_control:
            clock_sig = proc.event_control.clock_signal
            reset_sig = proc.event_control.reset_signal

        body_instrs = stmt_to_instrs(proc.body, is_sequential=is_seq, symtab=symtab)
        if not body_instrs:
            body_instrs = [IRInstr.ret()]

        # 去重命名
        count = func_name_counts.get(base_name, 0)
        func_name_counts[base_name] = count + 1
        unique_name = base_name if count == 0 else f"{base_name}_{count}"

        params = [(p.name, ast_type_to_ir(p.data_type, getattr(p.bit_width, 'width', None)))
                  for p in mod.ports if p.direction == PortDirection.Input]

        func = IRFunction(
            name=unique_name,
            params=params,
            return_type=IRType.void(),
            blocks=[IRBasicBlock(name="entry", instrs=body_instrs)],
            is_sequential=is_seq,
            clock_signal=clock_sig,
            reset_signal=reset_sig,
            reset_active_high=(
                proc.event_control.reset_active_high
                if proc.event_control and reset_sig else True
            ),
            reset_is_async=bool(proc.event_control and reset_sig),
        )
        functions.append(func)

    # Multiple sequential processes writing the same register have ambiguous
    # ordering in this IR. Reject them instead of silently choosing whichever
    # function happened to be visited last.
    writers: dict[str, list[str]] = {}
    for function in functions:
        if not function.is_sequential:
            continue
        for block in function.blocks:
            for instruction in block.instrs:
                if instruction.kind == "nba" and instruction.dest:
                    writers.setdefault(instruction.dest, []).append(function.name)
    conflicts = {
        register: sorted(set(functions_))
        for register, functions_ in writers.items()
        if len(set(functions_)) > 1
    }
    if conflicts:
        details = ", ".join(
            f"{register} <- {functions_}" for register, functions_ in sorted(conflicts.items())
        )
        raise SemanticLoweringError(f"multiple sequential writers: {details}")

    def ir_uses(value: IRValue | None) -> set[str]:
        if value is None:
            return set()
        if value.kind == "var":
            return {str(value.data["name"])}
        used: set[str] = set()
        for item in value.data.values():
            if isinstance(item, IRValue):
                used.update(ir_uses(item))
            elif isinstance(item, (list, tuple)):
                for nested in item:
                    if isinstance(nested, IRValue):
                        used.update(ir_uses(nested))
        return used

    active_reads = set()
    for function in functions:
        for block in function.blocks:
            for instruction in block.instrs:
                active_reads.update(ir_uses(instruction.value))
                active_reads.update(ir_uses(instruction.cond))
    unused_synthetic = synthetic_undriven - active_reads
    if unused_synthetic:
        ports = [port for port in ports if port[0] not in unused_synthetic]

    ir_mod = IRModule(
        name=mod.name,
        parameters=[(p.name, IRType.uint(DEFAULT_WIDTH),
                     evaluate_parameter_expr(p.default_value, param_env))
                    for p in mod.parameters],
        ports=ports,
        signals=signals,
        registers=registers,
        functions=functions,
        instances=[(i.instance_name, i.module_name, []) for i in mod.instances],
        enum_constants=enum_constants,
        memories=memories,
        initial_values=initial_values,
    )

    # 识别 reset/clock-enable
    _recognize_reset_and_clock_enable(ir_mod)

    return ir_mod


def _recognize_reset_and_clock_enable(ir_mod: IRModule) -> None:
    """识别并标记 reset 信号和 clock-enable 信号"""
    input_names = {n for n, t, is_in in ir_mod.ports if is_in}

    for func in ir_mod.functions:
        if not func.is_sequential:
            continue
        if not func.blocks:
            continue

        entry = None
        for b in func.blocks:
            if b.name == 'entry':
                entry = b
                break
        if entry is None:
            continue

        reset_votes = {}
        for instr in entry.instrs:
            if instr.kind not in ('assign', 'nba') or instr.value is None:
                continue
            val = instr.value
            if val.kind != 'phi':
                continue

            cond = val.data.get('cond')
            then_v = val.data.get('then')
            else_v = val.data.get('else')

            cond_name = None
            cond_inverted = False
            if cond and cond.kind == 'var':
                cond_name = cond.data.get('name')
            elif cond and cond.kind == 'unary' and cond.data.get('op') == '!':
                inner = cond.data.get('operand')
                if inner and inner.kind == 'var':
                    cond_name = inner.data.get('name')
                    cond_inverted = True

            if not cond_name or cond_name not in input_names:
                continue

            is_then_zero = (then_v and then_v.kind in ('const_int', 'const_nat') and
                            then_v.data.get('value', 1) == 0)
            is_else_zero = (else_v and else_v.kind in ('const_int', 'const_nat') and
                            else_v.data.get('value', 1) == 0)

            if is_then_zero and not is_else_zero:
                reset_votes[cond_name] = reset_votes.get(cond_name, 0) + 1
            elif is_else_zero and not is_then_zero:
                reset_votes[cond_name] = reset_votes.get(cond_name, 0) + 1

        if reset_votes and not func.reset_signal:
            best = max(reset_votes, key=reset_votes.get)
            func.reset_signal = best
            func.reset_active_high = not best.endswith('_n')
