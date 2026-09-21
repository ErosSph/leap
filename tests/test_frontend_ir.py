from pathlib import Path

from rtl2lean.frontend import SVParser
from rtl2lean.middle_end.ir import (
    IRBasicBlock, IRFunction, IRInstr, IRModule, IRType, IRValue,
    normalize_combinational_schedule,
)
from rtl2lean.middle_end.ir_converter import module_to_ir
from rtl2lean.middle_end.optimizer import Optimizer
from rtl2lean.middle_end.type_checker import TypeChecker
from rtl2lean.pipeline.schema import build_design_ir


FIXTURES = Path(__file__).parent / "fixtures"


def parsed(name: str, top: str):
    ast = SVParser().parse_files([FIXTURES / name], top)[0]
    _, errors = TypeChecker.check_module(ast)
    assert not errors
    ir = normalize_combinational_schedule(Optimizer.optimize(module_to_ir(ast), 2))
    return ast, ir, build_design_ir(top, ast, ir)


def test_width_arithmetic_concat_slice_case_and_assignment_kinds():
    _ast, ir, typed = parsed("semantic_features.v", "semantic_features")
    widths = dict(ir.registers)
    assert widths["accum"] == 16
    assert widths["state"] == 2
    kinds = {value.kind for function in ir.functions for block in function.blocks
             for instruction in block.instrs
             for value in (instruction.value, instruction.cond) if value is not None}
    rendered = repr(ir)
    assert "binary" in kinds or "binary" in rendered
    assert "concat" in rendered
    assert "bit_range" in rendered or "bit_select" in rendered
    assert any(not process.sequential and "y" in process.write_set for process in typed.module.processes)
    assert any(process.sequential and {"state", "accum"} <= set(process.write_set)
               for process in typed.module.processes)
    assert all(process.normalized_statements for process in typed.module.processes)


def test_reset_read_write_sets_and_clock_detection():
    _ast, _ir, typed = parsed("semantic_features.v", "semantic_features")
    sequential = [process for process in typed.module.processes if process.sequential]
    assert len(sequential) == 1
    assert sequential[0].clock == "clk"
    assert sequential[0].reset == "rst_n"
    assert sequential[0].reset_polarity == "active_low"
    assert "accum" in sequential[0].read_set
    assert typed.module.clock_domains[0].state_fields


def test_multiple_always_ff_are_separate_clock_domains():
    _ast, _ir, typed = parsed("two_clock.v", "two_clock")
    assert len([process for process in typed.module.processes if process.sequential]) == 2
    assert {domain.clock for domain in typed.module.clock_domains} == {"clk_a", "clk_b"}
    assert set(typed.module.clock_domains[0].state_fields).isdisjoint(
        typed.module.clock_domains[1].state_fields
    )


def test_undriven_internal_is_a_formal_binary_input_not_zero():
    source = """
module formal_choice(input wire clk, output reg q);
  reg choose;
  always @(posedge clk) q <= choose;
endmodule
"""
    ast = SVParser().parse_source(source)[0]
    ir = normalize_combinational_schedule(Optimizer.optimize(module_to_ir(ast), 2))
    typed = build_design_ir("formal_choice", ast, ir)
    assert "choose" in typed.nondeterministic_inputs
    assert any(name == "choose" and is_input for name, _typ, is_input in ir.ports)
    sequential = next(process for process in typed.module.processes if process.sequential)
    statement = next(item for item in sequential.normalized_statements if item.destination == "q")
    assert statement.expression is not None
    expression = typed.expressions[statement.expression]
    assert "choose" in repr(expression)


def test_lean_oriented_short_circuit_and_phi_normalization():
    flag = IRValue.var("flag", IRType.bool())
    nested = IRValue.binary("||", IRValue.const_bool(False),
                            IRValue.binary("&&", IRValue.const_bool(True), flag))
    optimized = Optimizer(2)._optimize_value(nested)
    assert optimized == flag

    selected = Optimizer(2)._optimize_value(
        IRValue.phi(IRValue.const_bool(False), IRValue.const_nat(8, 1), IRValue.const_nat(8, 2)))
    assert selected == IRValue.const_nat(8, 2)


def test_optimizer_reaches_branch_conditions_without_instruction_values():
    flag = IRValue.var("flag", IRType.bool())
    branch = IRInstr.branch(IRValue.binary("&&", IRValue.const_bool(False), flag), "yes", "no")
    module = IRModule(name="branch_opt", functions=[IRFunction(
        name="f", blocks=[IRBasicBlock(name="entry", instrs=[branch])],
    )])
    optimized = Optimizer.optimize(module, 2)
    condition = optimized.functions[0].blocks[0].instrs[0].cond
    assert condition == IRValue.const_bool(False)
