import json

import pyslang

from rtl2lean.syntax_check import check_text, main


def test_preserves_original_syntax_operation():
    for text in ["module m(input x, output y); assign y=x; endmodule",
                 "module m(input logic clk); logic q; always_ff @(posedge clk) q<=~q; endmodule",
                 "module m( ; broken syntax endmodule", "module m; `UNDEFINED_MACRO endmodule"]:
        tree = pyslang.syntax.SyntaxTree.fromText(text)
        result = check_text(text)
        assert result["diagnostics"] == [str(d.code) for d in tree.diagnostics]
        assert result["status"] == ("ERROR" if any(d.isError() for d in tree.diagnostics) else "PASS")


def test_batch_does_not_share_macros():
    assert check_text("`define WIDTH 8\nmodule a; logic [`WIDTH-1:0] a; endmodule")["status"] == "PASS"
    assert check_text("module b; logic [`WIDTH-1:0] b; endmodule")["status"] == "ERROR"


def test_cli_continues_after_missing_input(tmp_path, capsys):
    valid = tmp_path / "m.v"
    valid.write_text("module m; endmodule")
    assert main([str(tmp_path / "missing.v"), str(valid)]) == 1
    rows = [json.loads(line) for line in capsys.readouterr().out.splitlines()]
    assert [r["status"] for r in rows] == ["INPUT_ERROR", "PASS"]


def test_empty_cli(capsys):
    assert main([]) == 2
    assert "usage:" in capsys.readouterr().err
