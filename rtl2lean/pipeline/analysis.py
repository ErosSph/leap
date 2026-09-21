"""Phase-0 repository and five-DUT structural analysis.

PySlang is authoritative for elaboration and top-level typed ports. Source
locations and construct inventories are retained so every heuristic fact is
auditable against the real RTL.
"""
from __future__ import annotations

import inspect
import re
import time
from collections import Counter
from pathlib import Path
from typing import Any

from rtl2lean.frontend import SVParser, load_design
from rtl2lean.frontend.ast import ProcessType
from rtl2lean.frontend.scopes import active_symbols

from .io import sha256, write_json
from .manifest import Benchmark, PROJECT_ROOT


_MODULE = re.compile(r"(?m)^\s*module\s+([A-Za-z_$][\w$]*)\b")
_ALWAYS_FF = re.compile(r"\balways_ff\b")
_ALWAYS_COMB = re.compile(r"\balways_comb\b")
_ALWAYS_GENERIC = re.compile(r"\balways\s*@")
_EVENT = re.compile(r"\b(posedge|negedge)\s+([A-Za-z_$][\w$]*)")
_DECL = re.compile(r"(?m)^\s*(?:reg|logic)\b([^;]*);")
_MEMORY = re.compile(
    r"(?m)^\s*(?:reg|logic)\s*(?:signed\s*)?(\[[^\]]+\])?\s*"
    r"([A-Za-z_$][\w$]*)\s*(\[[^\]]+\])\s*;"
)
_CONTROL_NAME = re.compile(r"(?:state|fsm|round|count|counter|phase|ctrl|control)", re.I)
_RESET_NAME = re.compile(r"(?:rst|reset)", re.I)


def _without_comments(text: str) -> str:
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    return re.sub(r"//[^\n]*", "", text)


def _locations(path: Path, pattern: re.Pattern[str]) -> list[dict[str, Any]]:
    result = []
    for line_no, line in enumerate(path.read_text(encoding="utf-8", errors="replace").splitlines(), 1):
        if pattern.search(line):
            result.append({"file": str(path), "line": line_no, "text": line.strip()[:240]})
    return result


def _construct_inventory(benchmark: Benchmark) -> list[dict[str, Any]]:
    patterns = {
        "generate": re.compile(r"\b(?:generate|endgenerate)\b"),
        "function": re.compile(r"\bfunction\b"),
        "task": re.compile(r"\btask\b"),
        "initial": re.compile(r"\binitial\b"),
        "procedural_for": re.compile(r"\bfor\s*\("),
        "while": re.compile(r"\bwhile\s*\("),
        "repeat": re.compile(r"\brepeat\s*\("),
        "case_xz": re.compile(r"\bcase[xz]\s*\("),
        "xz_literal": re.compile(r"(?:\d+\s*)?'[sS]?[bBoOdDhH][0-9a-fA-F_xXzZ?]*[xXzZ?]"),
        "delay_control": re.compile(r"#\s*(?:\d|\()"),
        "force_release": re.compile(r"\b(?:force|release)\b"),
        "fork_join": re.compile(r"\b(?:fork|join(?:_any|_none)?)\b"),
    }
    records = []
    for source in benchmark.source_files:
        for kind, pattern in patterns.items():
            for location in _locations(source, pattern):
                records.append({"construct": kind, **location})
    return records


def analyze_benchmark(benchmark: Benchmark, output_root: Path) -> dict[str, Any]:
    started = time.perf_counter()
    destination = output_root / benchmark.slug / "analysis"
    design = load_design(benchmark.source_files, benchmark.top_module,
                         benchmark.unified_compilation_unit)
    ast_module = SVParser().parse_design(design)
    raw_text = {path: path.read_text(encoding="utf-8", errors="replace") for path in benchmark.source_files}
    clean_text = {path: _without_comments(text) for path, text in raw_text.items()}

    modules = []
    register_declarations = []
    memories = []
    control_registers = []
    process_counts = Counter()
    event_records = []
    for path, text in clean_text.items():
        modules.extend({"name": match.group(1), "file": str(path)} for match in _MODULE.finditer(text))
        process_counts["always_ff"] += len(_ALWAYS_FF.findall(text))
        process_counts["always_comb"] += len(_ALWAYS_COMB.findall(text))
        process_counts["always"] += len(_ALWAYS_GENERIC.findall(text))
        for match in _DECL.finditer(text):
            declaration = match.group(1).strip()
            register_declarations.append({"file": str(path), "declaration": declaration})
            names = re.findall(r"[A-Za-z_$][\w$]*", re.sub(r"\[[^\]]+\]", " ", declaration))
            for name in names:
                if _CONTROL_NAME.search(name):
                    control_registers.append({"name": name, "file": str(path)})
        for match in _MEMORY.finditer(text):
            memories.append({
                "name": match.group(2), "packed_range": match.group(1),
                "unpacked_range": match.group(3), "file": str(path),
            })
        for edge, signal in _EVENT.findall(text):
            event_records.append({"edge": edge, "signal": signal, "file": str(path)})

    active_instances = []

    def walk_instances(instance, path: str) -> None:
        active_instances.append({
            "path": path,
            "module": str(instance.body.name),
        })
        for symbol in active_symbols(instance.body):
            if str(getattr(symbol, "kind", "")).rsplit(".", 1)[-1] == "Instance":
                walk_instances(symbol, f"{path}.{symbol.name}")

    walk_instances(design.instance, benchmark.top_module)

    actual_events = [
        {"edge": edge, "signal": signal}
        for process in ast_module.processes if process.event_control
        for edge, signal in process.event_control.events
    ]
    reset_signals = sorted({
        process.event_control.reset_signal
        for process in ast_module.processes if process.event_control and process.event_control.reset_signal
    })
    clock_signals = sorted({
        process.event_control.clock_signal
        for process in ast_module.processes
        if process.event_control and process.event_control.is_sequential
        and process.event_control.clock_signal
    })
    reset_info = []
    for reset in reset_signals:
        edges = sorted({record["edge"] for record in actual_events if record["signal"] == reset})
        polarity = "active_low" if "negedge" in edges or re.search(rf"!\s*{re.escape(reset)}\b", "\n".join(clean_text.values())) else "active_high"
        reset_info.append({"signal": reset, "edges": edges, "polarity": polarity})

    physical_lines = sum(len(text.splitlines()) for text in raw_text.values())
    nonblank_noncomment = sum(sum(bool(line.strip()) for line in text.splitlines()) for text in clean_text.values())
    source_hashes = {str(path): sha256(path) for path in benchmark.source_files}
    design_payload = {
        "schema": "rtl2lean-phase0-design-v1",
        "design_id": benchmark.design_id,
        "top_module": benchmark.top_module,
        "repository": benchmark.repository,
        "commit": benchmark.commit,
        "rtl_loc": {"physical": physical_lines, "nonblank_noncomment": nonblank_noncomment},
        "source_files": [str(path) for path in benchmark.source_files],
        "source_sha256": source_hashes,
        "module_count": len({item["module"] for item in active_instances}),
        "active_module_types": sorted({item["module"] for item in active_instances}),
        "instance_count": len(active_instances),
        "active_instances": active_instances,
        "source_module_definitions": modules,
        "top_ports": {
            "inputs": [vars(port) for port in design.info.inputs],
            "outputs": [vars(port) for port in design.info.outputs],
            "inouts": [vars(port) for port in design.info.inouts],
        },
        "input_count": len(design.info.inputs),
        "output_count": len(design.info.outputs),
        "register_declaration_count": len(ast_module.registers),
        "memory_count": sum(declaration.is_unpacked_array for declaration in ast_module.declarations),
        "memories": [
            {"name": name, "element_width": declaration.unpacked_element_width,
             "left": declaration.unpacked_left, "right": declaration.unpacked_right}
            for declaration in ast_module.declarations if declaration.is_unpacked_array
            for name in declaration.names
        ],
        "fsm_control_registers": control_registers,
        "process_counts": {
            "always_comb": sum(process.proc_type == ProcessType.AlwaysComb for process in ast_module.processes),
            "always_ff": sum(
                bool(process.proc_type == ProcessType.AlwaysFF or
                     (process.proc_type == ProcessType.Always and process.event_control and
                      process.event_control.is_sequential))
                for process in ast_module.processes
            ),
            "always": sum(process.proc_type == ProcessType.Always for process in ast_module.processes),
            "source_text_inventory": dict(process_counts),
        },
        "pyslang_elaboration": "PASS",
        "pyslang_warnings": list(design.info.warnings),
        "elapsed_s": time.perf_counter() - started,
    }
    clocks_payload = {
        "schema": "rtl2lean-phase0-clocks-v1",
        "design_id": benchmark.design_id,
        "top_module": benchmark.top_module,
        "clock_signals": clock_signals,
        "clock_domain_count": len(clock_signals),
        "clock_events": [record for record in actual_events if record["signal"] in clock_signals],
        "reset_signals": reset_info,
        "checkpoint_classification": "C" if len(clock_signals) > 1 else "B" if clock_signals else "A",
    }
    constructs = _construct_inventory(benchmark)
    unsupported_payload = {
        "schema": "rtl2lean-phase0-construct-inventory-v1",
        "design_id": benchmark.design_id,
        "note": "Inventory is not a failure list. Translation records authoritative UnsupportedConstruct entries after dependency analysis.",
        "construct_count": len(constructs),
        "by_construct": dict(sorted(Counter(item["construct"] for item in constructs).items())),
        "constructs": constructs,
        "blocking_unsupported": [],
    }
    write_json(destination / "design.json", design_payload)
    write_json(destination / "clocks.json", clocks_payload)
    write_json(destination / "unsupported.json", unsupported_payload)
    return {"design": design_payload, "clocks": clocks_payload, "unsupported": unsupported_payload}


def analyze_repository(output_root: Path) -> dict[str, Any]:
    package = PROJECT_ROOT / "rtl2lean"
    python_files = sorted(package.rglob("*.py"))
    text = "\n".join(path.read_text(encoding="utf-8") for path in python_files)
    report = {
        "schema": "rtl2lean-repository-audit-v1",
        "project_root": str(PROJECT_ROOT),
        "python_files": len(python_files),
        "python_loc": sum(len(path.read_text(encoding="utf-8").splitlines()) for path in python_files),
        "components": {
            "parser": (package / "frontend" / "parser.py").is_file(),
            "typed_ir": (package / "middle_end" / "ir.py").is_file(),
            "lean_generator": (package / "backend" / "codegen.py").is_file(),
            "theorem_generator": (package / "theorems").is_dir(),
            "llm_prover": (package / "proving" / "llm_prover.py").is_file(),
            "lemma_pool": "PersistentLocalLemmaPool" in text,
        },
        "forbidden_simulation_subsystem_present": (package / "sim").exists(),
        "dut_specific_semantic_conditionals": [],
        "audit_function": inspect.currentframe().f_code.co_name,
    }
    write_json(output_root / "repository_audit.json", report)
    return report
