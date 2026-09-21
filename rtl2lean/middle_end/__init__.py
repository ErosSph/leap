"""中端模块 - IR、类型检查、优化、分析"""

from .ir import IRModule, IRType, IRValue, IRInstr, IRFunction, IRBasicBlock
from .type_checker import TypeChecker, TypeError
from .optimizer import Optimizer
from .analyzer import ModuleAnalysis, Analyzer

__all__ = [
    "IRModule", "IRType", "IRValue", "IRInstr", "IRFunction", "IRBasicBlock",
    "TypeChecker", "TypeError",
    "Optimizer",
    "ModuleAnalysis", "Analyzer",
]
