"""
前端模块 - 使用 PySlang 解析 SystemVerilog/Verilog 并提取结构化 AST
"""

from .parser import SVParser
from .design import (
    DesignError, DesignInfo, ElaboratedDesign, ParameterInfo, PortInfo,
    ProcessInfo, load_design, load_design_source, load_designs,
)
from .ast import (
    DataType, Expr, Stmt, Port, Parameter, Module,
    PortDirection, ProcessType, EventControl,
    ModuleItem, Declaration, ContinuousAssign, Process,
)

__all__ = [
    "SVParser",
    "DataType", "Expr", "Stmt", "Port", "Parameter", "Module",
    "PortDirection", "ProcessType", "EventControl",
    "ModuleItem", "Declaration", "ContinuousAssign", "Process",
    "DesignError", "DesignInfo", "ElaboratedDesign", "ParameterInfo",
    "PortInfo", "ProcessInfo", "load_design", "load_design_source",
    "load_designs",
]
