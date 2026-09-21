"""
优化器 - IR 优化通道
"""

from __future__ import annotations

import logging

from .ir import IRBasicBlock, IRFunction, IRInstr, IRModule, IRValue

logger = logging.getLogger(__name__)


class Optimizer:
    """IR 优化器"""

    def __init__(self, level: int = 2):
        self.level = level
        self.applied: list[str] = []
        # IR values form a DAG in elaborated medium/large designs.  Memoizing
        # by object identity prevents repeated normalization of shared terms.
        self._fold_memo: dict[int, IRValue] = {}

    @classmethod
    def optimize(cls, ir_mod: IRModule, level: int = 2) -> IRModule:
        """执行优化"""
        opt = cls(level)
        return opt._optimize_module(ir_mod)

    def _optimize_module(self, ir_mod: IRModule) -> IRModule:
        if self.level == 0:
            return ir_mod

        optimized_funcs = [self._optimize_function(f) for f in ir_mod.functions]

        if self.level >= 1:
            self.applied.extend(["constant_folding", "dead_code_elimination"])
        if self.level >= 2:
            self.applied.extend([
                "lean_short_circuit_normalization",
                "constant_phi_elimination",
                "strength_reduction",
            ])
        if self.level >= 3:
            self.applied.extend(["cse", "aggressive"])

        logger.info(f"优化完成，应用了: {', '.join(self.applied)}")

        return IRModule(
            name=ir_mod.name,
            parameters=ir_mod.parameters,
            ports=ir_mod.ports,
            signals=ir_mod.signals,
            registers=ir_mod.registers,
            functions=optimized_funcs,
            initial_blocks=ir_mod.initial_blocks,
            initial_values=getattr(ir_mod, "initial_values", {}),
            instances=ir_mod.instances,
            enum_constants=ir_mod.enum_constants,
            memories=getattr(ir_mod, "memories", []),
        )

    def _optimize_function(self, func: IRFunction) -> IRFunction:
        blocks = [self._optimize_block(b) for b in func.blocks]
        if self.level >= 1:
            blocks = self._dead_code_elimination(blocks)
        return IRFunction(
            name=func.name,
            params=func.params,
            return_type=func.return_type,
            blocks=blocks,
            entry_block=func.entry_block,
            is_sequential=func.is_sequential,
            clock_signal=func.clock_signal,
            reset_signal=func.reset_signal,
            reset_active_high=func.reset_active_high,
            reset_is_async=func.reset_is_async,
            clock_enable=func.clock_enable,
        )

    def _optimize_block(self, block: IRBasicBlock) -> IRBasicBlock:
        instrs = [self._optimize_instr(i) for i in block.instrs]
        return IRBasicBlock(
            name=block.name,
            params=block.params,
            instrs=instrs,
            predecessors=block.predecessors,
            successors=block.successors,
        )

    def _optimize_instr(self, instr: IRInstr) -> IRInstr:
        # Branches and void calls have no ``value``.  The old guard therefore
        # skipped their conditions/arguments entirely, leaving some of the
        # largest generated Lean terms unnormalised.
        return IRInstr(
            kind=instr.kind,
            dest=instr.dest,
            value=self._optimize_value(instr.value) if instr.value else None,
            label=instr.label,
            true_label=instr.true_label,
            false_label=instr.false_label,
            cond=self._optimize_value(instr.cond) if instr.cond else None,
            name=instr.name,
            args=[self._optimize_value(a) for a in instr.args],
            message=instr.message,
        )

    def _optimize_value(self, value: IRValue) -> IRValue:
        v = self._constant_folding(value, self._fold_memo)
        if self.level >= 2:
            # Constant folding may create short-lived wrapper nodes.  Scope
            # identity memoization to this root so Python cannot reuse a dead
            # wrapper's id for an unrelated later instruction.
            v = self._lean_normalize(v, {})
            v = self._strength_reduction(v)
        return v

    # ───────────── Lean-oriented, semantics-preserving normalization ─────────────

    @staticmethod
    def _constant_truth(value: IRValue) -> bool | None:
        """SystemVerilog truth value for a constant, or ``None`` otherwise."""
        raw = value.const_value
        return None if raw is None else raw != 0

    @staticmethod
    def _is_lean_bool(value: IRValue) -> bool:
        """Whether codegen represents this one-bit value directly as ``Bool``.

        This deliberately mirrors the backend representation rule without
        importing the backend (which would create a middle-end/backend cycle).
        It lets identity rewrites such as ``x && true -> x`` preserve the Lean
        type as well as the hardware value.
        """
        if value.kind == "lean_local":
            return int(value.data.get("width", 1)) == 1 and \
                value.data.get("representation", "Bool") == "Bool"
        if value.kind == "const_bool":
            return True
        if value.kind in {"const_int", "const_nat"}:
            return int(value.data.get("width", 32)) <= 1
        if value.kind == "var":
            return int(value.data["type"].width) <= 1
        if value.kind == "bit_select":
            return True
        if value.kind == "unary":
            op = value.data["op"]
            if op in {"!", "&", "|", "^", "reduce_xor", "~&", "~|", "~^"}:
                return True
            return Optimizer._is_lean_bool(value.data["operand"])
        if value.kind == "binary":
            if value.data["op"] in {"==", "!=", "<", ">", "<=", ">=", "&&", "||"}:
                return True
            return (Optimizer._is_lean_bool(value.data["left"])
                    and Optimizer._is_lean_bool(value.data["right"]))
        if value.kind == "phi":
            # The backend coerces both one-bit arms to Bool.
            return (Optimizer._is_lean_bool(value.data["then"])
                    and Optimizer._is_lean_bool(value.data["else"]))
        return False

    @staticmethod
    def _lean_normalize(value: IRValue, memo: dict[int, IRValue] | None = None) -> IRValue:
        """Reduce terms that otherwise inflate Lean elaboration/proof terms.

        Only total two-state identities are used.  In particular, arithmetic
        width-changing identities are intentionally not rewritten here.
        """
        if memo is None:
            memo = {}
        key = id(value)
        if key in memo:
            return memo[key]
        if value.kind == "binary":
            left = Optimizer._lean_normalize(value.data["left"], memo)
            right = Optimizer._lean_normalize(value.data["right"], memo)
            op = value.data["op"]
            rebuilt = IRValue.binary(op, left, right)
            if op not in {"&&", "||"}:
                result = rebuilt
                memo[key] = result
                return result
            left_truth = Optimizer._constant_truth(left)
            right_truth = Optimizer._constant_truth(right)
            if op == "&&":
                if left_truth is False or right_truth is False:
                    result = IRValue.const_bool(False)
                    memo[key] = result
                    return result
                if left_truth is True and Optimizer._is_lean_bool(right):
                    memo[key] = right
                    return right
                if right_truth is True and Optimizer._is_lean_bool(left):
                    memo[key] = left
                    return left
            else:
                if left_truth is True or right_truth is True:
                    result = IRValue.const_bool(True)
                    memo[key] = result
                    return result
                if left_truth is False and Optimizer._is_lean_bool(right):
                    memo[key] = right
                    return right
                if right_truth is False and Optimizer._is_lean_bool(left):
                    memo[key] = left
                    return left
            memo[key] = rebuilt
            return rebuilt
        if value.kind == "unary":
            result = IRValue.unary(value.data["op"],
                                   Optimizer._lean_normalize(value.data["operand"], memo))
            memo[key] = result
            return result
        if value.kind == "phi":
            cond = Optimizer._lean_normalize(value.data["cond"], memo)
            then_value = Optimizer._lean_normalize(value.data["then"], memo)
            else_value = Optimizer._lean_normalize(value.data["else"], memo)
            truth = Optimizer._constant_truth(cond)
            if truth is not None:
                result = then_value if truth else else_value
            else:
                result = IRValue.phi(cond, then_value, else_value)
            memo[key] = result
            return result
        if value.kind == "bit_select":
            result = IRValue.bit_select(
                Optimizer._lean_normalize(value.data["value"], memo),
                Optimizer._lean_normalize(value.data["index"], memo),
            )
            memo[key] = result
            return result
        if value.kind == "bit_range":
            result = IRValue.bit_range(
                Optimizer._lean_normalize(value.data["value"], memo),
                value.data["hi"], value.data["lo"],
            )
            memo[key] = result
            return result
        if value.kind == "array_select":
            result = IRValue.array_select(
                Optimizer._lean_normalize(value.data["value"], memo),
                Optimizer._lean_normalize(value.data["index"], memo),
                value.data["element_width"], value.data["depth"],
                value.data["left"], value.data["right"],
            )
            memo[key] = result
            return result
        if value.kind == "array_store":
            result = IRValue.array_store(
                Optimizer._lean_normalize(value.data["memory"], memo),
                Optimizer._lean_normalize(value.data["index"], memo),
                Optimizer._lean_normalize(value.data["value"], memo),
                value.data["element_width"], value.data["depth"],
                value.data["left"], value.data["right"],
            )
            memo[key] = result
            return result
        if value.kind == "bit_store":
            result = IRValue.bit_store(
                Optimizer._lean_normalize(value.data["base"], memo),
                Optimizer._lean_normalize(value.data["index"], memo),
                Optimizer._lean_normalize(value.data["value"], memo),
            )
            memo[key] = result
            return result
        if value.kind == "range_store":
            result = IRValue.range_store(
                Optimizer._lean_normalize(value.data["base"], memo),
                value.data["hi"], value.data["lo"],
                Optimizer._lean_normalize(value.data["value"], memo),
            )
            memo[key] = result
            return result
        if value.kind == "concat":
            result = IRValue.concat([Optimizer._lean_normalize(item, memo)
                                   for item in value.data["values"]])
            memo[key] = result
            return result
        if value.kind == "call":
            result = IRValue.call(value.data["name"], [Optimizer._lean_normalize(item, memo)
                                for item in value.data["args"]])
            memo[key] = result
            return result
        memo[key] = value
        return value

    # ───────────────────────── 常量折叠 ─────────────────────────

    @staticmethod
    def _constant_folding(value: IRValue, memo: dict[int, IRValue] | None = None) -> IRValue:
        if memo is None:
            memo = {}
        key = id(value)
        if key in memo:
            return memo[key]
        if value.kind == "binary":
            left = Optimizer._constant_folding(value.data["left"], memo)
            right = Optimizer._constant_folding(value.data["right"], memo)
            op = value.data["op"]

            if left.is_const() and right.is_const():
                lv = left.const_value
                rv = right.const_value
                if lv is not None and rv is not None:
                    width = max(left.data.get("width", 32), right.data.get("width", 32))
                    result = Optimizer._eval_binary(op, lv, rv)
                    if result is not None:
                        folded = IRValue.const_nat(width, result)
                        memo[key] = folded
                        return folded

            folded = IRValue.binary(op, left, right)
            memo[key] = folded
            return folded

        if value.kind == "unary":
            operand = Optimizer._constant_folding(value.data["operand"], memo)
            op = value.data["op"]
            if operand.is_const():
                ov = operand.const_value
                if ov is not None:
                    result = Optimizer._eval_unary(op, ov)
                    if result is not None:
                        folded = IRValue.const_nat(operand.data.get("width", 32), result)
                        memo[key] = folded
                        return folded
            folded = IRValue.unary(op, operand)
            memo[key] = folded
            return folded

        # 递归处理子表达式
        if value.kind == "bit_select":
            return IRValue.bit_select(
                Optimizer._constant_folding(value.data["value"], memo),
                Optimizer._constant_folding(value.data["index"], memo),
            )
        if value.kind == "array_select":
            return IRValue.array_select(
                Optimizer._constant_folding(value.data["value"], memo),
                Optimizer._constant_folding(value.data["index"], memo),
                value.data["element_width"], value.data["depth"],
                value.data["left"], value.data["right"],
            )
        if value.kind == "array_store":
            return IRValue.array_store(
                Optimizer._constant_folding(value.data["memory"], memo),
                Optimizer._constant_folding(value.data["index"], memo),
                Optimizer._constant_folding(value.data["value"], memo),
                value.data["element_width"], value.data["depth"],
                value.data["left"], value.data["right"],
            )
        if value.kind == "bit_store":
            return IRValue.bit_store(
                Optimizer._constant_folding(value.data["base"], memo),
                Optimizer._constant_folding(value.data["index"], memo),
                Optimizer._constant_folding(value.data["value"], memo),
            )
        if value.kind == "range_store":
            return IRValue.range_store(
                Optimizer._constant_folding(value.data["base"], memo),
                value.data["hi"], value.data["lo"],
                Optimizer._constant_folding(value.data["value"], memo),
            )
        if value.kind == "concat":
            return IRValue.concat([Optimizer._constant_folding(v, memo) for v in value.data["values"]])
        if value.kind == "call":
            return IRValue.call(
                value.data["name"],
                [Optimizer._constant_folding(a, memo) for a in value.data["args"]],
            )
        if value.kind == "phi":
            return IRValue.phi(
                Optimizer._constant_folding(value.data["cond"], memo),
                Optimizer._constant_folding(value.data["then"], memo),
                Optimizer._constant_folding(value.data["else"], memo),
            )

        return value

    @staticmethod
    def _eval_binary(op: str, left: int, right: int) -> int | None:
        ops = {
            "+": lambda a, b: a + b,
            "-": lambda a, b: a - b,
            "*": lambda a, b: a * b,
            "/": lambda a, b: a // b if b != 0 else 0,
            "%": lambda a, b: a % b if b != 0 else 0,
            "&": lambda a, b: a & b,
            "|": lambda a, b: a | b,
            "^": lambda a, b: a ^ b,
            "==": lambda a, b: 1 if a == b else 0,
            "!=": lambda a, b: 1 if a != b else 0,
            "<": lambda a, b: 1 if a < b else 0,
            ">": lambda a, b: 1 if a > b else 0,
            "<=": lambda a, b: 1 if a <= b else 0,
            ">=": lambda a, b: 1 if a >= b else 0,
            "<<": lambda a, b: a << b,
            ">>": lambda a, b: a >> b,
            "&&": lambda a, b: 1 if (a and b) else 0,
            "||": lambda a, b: 1 if (a or b) else 0,
        }
        return ops.get(op, lambda a, b: None)(left, right)

    @staticmethod
    def _eval_unary(op: str, operand: int) -> int | None:
        ops = {
            "!": lambda a: 1 if a == 0 else 0,
            "-": lambda a: -a,
            "~": lambda a: ~a,
            "&": lambda a: a,
            "|": lambda a: a,
            "^": lambda a: a,
        }
        return ops.get(op, lambda a: None)(operand)

    # ───────────────────────── 死代码消除 ─────────────────────────

    @staticmethod
    def _dead_code_elimination(blocks: list[IRBasicBlock]) -> list[IRBasicBlock]:
        result = []
        for block in blocks:
            filtered = [i for i in block.instrs if i.kind != "nop"]
            result.append(IRBasicBlock(
                name=block.name,
                params=block.params,
                instrs=filtered,
                predecessors=block.predecessors,
                successors=block.successors,
            ))
        return result

    # ───────────────────────── 强度削减 ─────────────────────────

    @staticmethod
    def _strength_reduction(value: IRValue) -> IRValue:
        if value.kind == "binary" and value.data["op"] == "*":
            right = value.data["right"]
            if right.is_const() and right.const_value is not None:
                n = right.const_value
                if n > 0 and (n & (n - 1)) == 0:  # 2 的幂
                    shift = n.bit_length() - 1
                    width = right.data.get("width", 32)
                    return IRValue.binary(
                        "<<",
                        value.data["left"],
                        IRValue.const_nat(width, shift),
                    )
        if value.kind == "binary" and value.data["op"] == "/":
            right = value.data["right"]
            if right.is_const() and right.const_value is not None:
                n = right.const_value
                if n > 0 and (n & (n - 1)) == 0:
                    shift = n.bit_length() - 1
                    width = right.data.get("width", 32)
                    return IRValue.binary(
                        ">>",
                        value.data["left"],
                        IRValue.const_nat(width, shift),
                    )
        return value
