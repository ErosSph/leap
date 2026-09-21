from pathlib import Path

from rtl2lean.backend.codegen import CodeGenerator
from rtl2lean.frontend import SVParser
from rtl2lean.middle_end.ir import normalize_combinational_schedule
from rtl2lean.middle_end.ir_converter import module_to_ir
from rtl2lean.middle_end.optimizer import Optimizer
from rtl2lean.pipeline.compiler import kernel_check
from rtl2lean.pipeline.schema import build_design_ir
from rtl2lean.theorems.generator import generate_theorem_bundle


FIXTURES = Path(__file__).parent / "fixtures"


def test_multiclock_model_and_four_layers_compile(tmp_path: Path):
    ast = SVParser().parse_files([FIXTURES / "two_clock.v"], "two_clock")[0]
    ir = normalize_combinational_schedule(Optimizer.optimize(module_to_ir(ast), 2))
    typed = build_design_ir("two_clock", ast, ir)
    model = tmp_path / "Model.lean"
    model.write_text(CodeGenerator.generate(ir) + "\n", encoding="utf-8")
    assert kernel_check(model, timeout_s=120)["success"]
    bundle = generate_theorem_bundle(ir, typed, tmp_path)
    assert kernel_check(bundle.foundation_path, timeout_s=120)["success"]
    assert {target.layer for target in bundle.theorems} >= {"L2", "L3", "L4", "PROPERTY"}
    assert "inductive ClockEvent" in model.read_text(encoding="utf-8")
    assert typed.module.cross_clock_dependencies == ()


def test_single_clock_has_comb_commit_step_and_preservation(tmp_path: Path):
    ast = SVParser().parse_files([FIXTURES / "semantic_features.v"], "semantic_features")[0]
    ir = normalize_combinational_schedule(Optimizer.optimize(module_to_ir(ast), 2))
    model = tmp_path / "Model.lean"
    code = CodeGenerator.generate(ir)
    model.write_text(code + "\n", encoding="utf-8")
    assert "def comb " in code
    assert "def commit " in code
    assert "def step " in code
    assert kernel_check(model, timeout_s=120)["success"]
