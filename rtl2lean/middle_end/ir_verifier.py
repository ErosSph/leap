"""
IR 验证器：在 CodeGenerator 之前运行，确保 IR 的寄存器/信号语义一致性。
增强版：增加变量宽度一致性校验、二元操作位宽兼容性检查。
"""
from __future__ import annotations

import logging
from typing import Set, Optional

from .ir import IRModule, IRInstr, IRValue, IRType

logger = logging.getLogger(__name__)


class IRVerificationError(Exception):
    pass


def _build_width_map(mod: IRModule) -> dict[str, int]:
    """从 IR 模块构建完整的变量→宽度映射"""
    width_map: dict[str, int] = {}
    for name, typ, _ in mod.ports:
        w = getattr(typ, 'width', None)
        if w and w > 0:
            width_map[name] = w
    for name, typ in mod.signals:
        w = getattr(typ, 'width', None)
        if w and w > 0:
            width_map[name] = w
    for name, w in mod.registers:
        if w > 0:
            width_map[name] = w
    for name, value, width in mod.enum_constants:
        if width > 0:
            width_map[name] = width
    # 参数（编译期常量，width=0 表示 Nat 类型）
    for entry in mod.parameters:
        n = entry[0]
        if len(entry) > 2 and entry[2] is not None:
            width_map[n] = 0  # Nat parameter
    return width_map


def _collect_declared_names(mod: IRModule) -> Set[str]:
    names = set()
    for n, _, _ in mod.ports:
        names.add(n)
    for n, _ in mod.signals:
        names.add(n)
    for n, _ in mod.registers:
        names.add(n)
    for n, _, _ in mod.enum_constants:
        names.add(n)
    # 参数是编译期常量，应在所有作用域中可见
    for entry in mod.parameters:
        n = entry[0]  # (name, type, value) or (name, type)
        names.add(n)
    return names


def _walk_irvalue_vars(val: IRValue, acc: Set[str]):
    if val is None:
        return
    if val.kind == "var":
        name = val.data.get("name")
        if name:
            acc.add(name)
        return
    # recursive
    for v in val.data.values():
        if isinstance(v, IRValue):
            _walk_irvalue_vars(v, acc)
        elif isinstance(v, list):
            for x in v:
                if isinstance(x, IRValue):
                    _walk_irvalue_vars(x, acc)


def _get_irvalue_width(val: IRValue) -> Optional[int]:
    """尝试从 IR 值获取其位宽"""
    if val is None:
        return None
    # 直接从 IRValue 的 data 中提取宽度
    if val.kind == "var":
        typ = val.data.get("type")
        if isinstance(typ, IRType):
            return typ.width
        if isinstance(typ, dict):
            return typ.get("width")
        return None
    if val.kind in ("const_int", "const_nat"):
        return val.data.get("width")
    if val.kind == "const_bool":
        return 1
    # 对于表达式节点，尝试从 span 获取宽度
    if val.span and isinstance(val.span, dict):
        w = val.span.get("width")
        if w is not None:
            return w
    # 从 data 中查找 width 字段
    if isinstance(val.data, dict):
        w = val.data.get("width")
        if w is not None:
            return w
    return None


def _walk_and_check_widths(val: IRValue, width_map: dict[str, int],
                           errors: list[str], path: str,
                           func_name: str) -> None:
    """递归遍历 IRValue 树并检查宽度一致性"""
    if val is None:
        return

    if val.kind == "var":
        name = val.data.get("name", "")
        if name in width_map:
            declared_w = width_map[name]
            actual_w = _get_irvalue_width(val)
            if declared_w > 0 and actual_w is not None and actual_w != declared_w:
                errors.append(
                    f"Width mismatch for variable '{name}' in {func_name}{path}: "
                    f"declared={declared_w}, IR node has={actual_w}"
                )
        return

    if val.kind == "binary":
        op = val.data.get("op", "")
        left = val.data.get("left")
        right = val.data.get("right")

        # 递归检查子节点
        if left:
            _walk_and_check_widths(left, width_map, errors,
                                   f"{path}.left", func_name)
        if right:
            _walk_and_check_widths(right, width_map, errors,
                                   f"{path}.right", func_name)

        # 对比较运算符检查位宽兼容性
        if op in ("==", "!=", "<", ">", "<=", ">="):
            lw = _get_irvalue_width(left)
            rw = _get_irvalue_width(right)
            if (lw is not None and rw is not None and
                    lw > 0 and rw > 0 and lw != rw):
                # 如果其中一个是常量，允许（常量可以被拓宽）
                left_is_const = left and left.kind.startswith("const_")
                right_is_const = right and right.kind.startswith("const_")
                if not left_is_const and not right_is_const:
                    errors.append(
                        f"Comparison width mismatch in {func_name}{path}: "
                        f"'{op}' left width={lw}, right width={rw}"
                    )
        return

    if val.kind == "unary":
        operand = val.data.get("operand")
        if operand:
            _walk_and_check_widths(operand, width_map, errors,
                                   f"{path}.operand", func_name)
        return

    if val.kind == "concat":
        vals = val.data.get("values", [])
        for i, v in enumerate(vals):
            if isinstance(v, IRValue):
                _walk_and_check_widths(v, width_map, errors,
                                       f"{path}.concat[{i}]", func_name)
        return

    if val.kind == "phi":
        cond = val.data.get("cond")
        then_v = val.data.get("then")
        else_v = val.data.get("else")
        if cond:
            _walk_and_check_widths(cond, width_map, errors,
                                   f"{path}.cond", func_name)
        if then_v:
            _walk_and_check_widths(then_v, width_map, errors,
                                   f"{path}.then", func_name)
        if else_v:
            _walk_and_check_widths(else_v, width_map, errors,
                                   f"{path}.else", func_name)
        return

    if val.kind == "bit_select":
        target = val.data.get("value")
        index = val.data.get("index")
        if target:
            _walk_and_check_widths(target, width_map, errors,
                                   f"{path}.bitsel", func_name)
        if index:
            _walk_and_check_widths(index, width_map, errors,
                                   f"{path}.bitidx", func_name)
        return

    if val.kind == "bit_range":
        target = val.data.get("value")
        if target:
            _walk_and_check_widths(target, width_map, errors,
                                   f"{path}.bitrange", func_name)
        return

    if val.kind == "call":
        args = val.data.get("args", [])
        for i, a in enumerate(args):
            if isinstance(a, IRValue):
                _walk_and_check_widths(a, width_map, errors,
                                       f"{path}.arg[{i}]", func_name)
        return


def _format_span(span: dict | None) -> str:
    if not span:
        return ""
    file = span.get("file")
    line = span.get("start_line")
    col = span.get("start_column")
    if file and line is not None and col is not None:
        return f" at {file}:{line}:{col}"
    text = span.get("text", "")
    if text:
        return f" near '{text[:60]}'"
    return ""


def verify_ir_module(mod: IRModule) -> None:
    """执行验证；在检测到错误时抛出 IRVerificationError。"""
    declared = _collect_declared_names(mod)
    reg_names = {n for n, _ in mod.registers}
    width_map = _build_width_map(mod)

    errors: list[str] = []
    width_warnings: list[str] = []

    for func in mod.functions:
        is_seq = getattr(func, "is_sequential", False)
        for blk in func.blocks:
            for instr in blk.instrs:
                # Ensure referenced vars are declared
                refs: set[str] = set()
                if instr.value is not None:
                    _walk_irvalue_vars(instr.value, refs)
                if instr.cond is not None:
                    _walk_irvalue_vars(instr.cond, refs)
                for name in refs:
                    if name not in declared:
                        span_info = _format_span(instr.span)
                        errors.append(f"Undeclared signal referenced in {func.name}: {name}{span_info}")

                # Width consistency check for value expressions
                if instr.value is not None:
                    _walk_and_check_widths(
                        instr.value, width_map, width_warnings,
                        f".{instr.dest or 'expr'}", func.name
                    )

                # Width check for conditions
                if instr.cond is not None:
                    _walk_and_check_widths(
                        instr.cond, width_map, width_warnings,
                        ".cond", func.name
                    )

                # sequential NBA targets must have valid dest/value
                if is_seq and instr.kind == "nba":
                    span_info = _format_span(instr.span)
                    if not instr.dest:
                        errors.append(f"Sequential NBA missing destination in {func.name}: {instr}{span_info}")
                    if instr.value is None:
                        errors.append(f"Sequential NBA missing value for dest {instr.dest} in {func.name}{span_info}")

                    # Check NBA target width vs value width
                    if instr.dest and instr.value:
                        dest_w = width_map.get(instr.dest)
                        val_w = _get_irvalue_width(instr.value)
                        if (dest_w is not None and val_w is not None and
                                dest_w > 0 and val_w > 0 and dest_w != val_w):
                            width_warnings.append(
                                f"NBA width mismatch in {func.name}: "
                                f"dest '{instr.dest}' width={dest_w}, "
                                f"value width={val_w}{span_info}"
                            )

    # Log width warnings (not hard errors, to avoid breaking the pipeline
    # during transition — but highly visible)
    if width_warnings:
        logger.warning(f"IR width consistency issues ({len(width_warnings)} found):")
        for w in width_warnings[:20]:  # Show first 20
            logger.warning(f"  {w}")
        if len(width_warnings) > 20:
            logger.warning(f"  ... and {len(width_warnings) - 20} more")

    if errors:
        raise IRVerificationError("IR verification failed:\n" + "\n".join(errors))
