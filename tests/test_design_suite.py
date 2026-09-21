from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from experiments.design_suite.config import CATEGORIES, DUTS, TEMPORAL_KINDS, load_config
from rtl2lean.backend.codegen import CodeGenerator
from rtl2lean.frontend import SVParser
from rtl2lean.frontend.design import load_design
from rtl2lean.middle_end.ir_converter import module_to_ir
from rtl2lean.pipeline.manifest import load_benchmarks


PROJECT = Path(__file__).resolve().parents[1]
EXPECTED_COUNTS = {"aes": 30, "picorv32": 27, "modexp": 24, "serv": 21,
                   "ethmac": 29, "zipcpu": 26, "dma_axi": 20}


class DesignSuiteTests(unittest.TestCase):
    def test_fixed_config_and_seven_real_duts(self):
        config = load_config(PROJECT / "configs/design_suite.yaml")
        self.assertEqual(config["duts"], DUTS)
        benchmarks = {b.slug: b for b in load_benchmarks()}
        self.assertEqual(set(DUTS), set(benchmarks))
        self.assertEqual(benchmarks["zipcpu"].top_module, "zipcore")
        self.assertTrue(benchmarks["dma_axi"].unified_compilation_unit)

    def test_frozen_preflight_corpus_shape_and_categories(self):
        payload = json.loads((PROJECT / "tests/fixtures/design_suite_tasks.json").read_text())
        tasks = payload["tasks"]
        self.assertEqual(len(tasks), sum(EXPECTED_COUNTS.values()))
        self.assertEqual(payload["properties_per_dut"], EXPECTED_COUNTS)
        self.assertEqual(len(set(EXPECTED_COUNTS.values())), len(DUTS))
        for dut in DUTS:
            group = [t for t in tasks if t["dut"] == dut]
            self.assertEqual(len(group), EXPECTED_COUNTS[dut])
            self.assertEqual({t["category"] for t in group}, set(CATEGORIES))
            observed_temporal = {t["subtype"] for t in group
                                 if t["category"] == "TEMPORAL_TRACE"}
            self.assertTrue(set(TEMPORAL_KINDS).issubset(observed_temporal))
            self.assertEqual(len({t["statement_sha256"] for t in group}), EXPECTED_COUNTS[dut])

    def test_static_initial_is_lowered_to_lean_init(self):
        source = """module init_demo(input logic clk, output logic q);
          initial q = 1'b1;
          always_ff @(posedge clk) q <= ~q;
        endmodule"""
        module = SVParser().parse_source(source)[0]
        ir = module_to_ir(module)
        self.assertEqual(ir.initial_values["q"].const_value, 1)
        self.assertIn("q := true", CodeGenerator.generate(ir))

    def test_unified_compilation_unit_shares_macros(self):
        with tempfile.TemporaryDirectory() as raw:
            root = Path(raw)
            (root / "defs.v").write_text("`define W 4\n")
            (root / "dut.v").write_text("module macro_demo(input [`W-1:0] x, output [`W-1:0] y); assign y=x; endmodule\n")
            design = load_design([root / "defs.v", root / "dut.v"], "macro_demo", True)
            self.assertEqual(design.info.inputs[0].width, 4)


if __name__ == "__main__":
    unittest.main()
