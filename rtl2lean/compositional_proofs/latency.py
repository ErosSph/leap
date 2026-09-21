"""Auditable variable-latency classification without fabricated bounds."""
from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any

from rtl2lean.pipeline.io import write_json
from rtl2lean.pipeline.manifest import Benchmark


HANDSHAKE = re.compile(r"ready|ack|response|resp|stall|wait|grant|fifo", re.I)
# Require token boundaries so a control signal such as ``*_ctrl_reg`` is not
# mislabeled merely because "ctrl" begins with "ctr".
COUNTER = re.compile(
    r"(?:^|_)(?:[A-Za-z0-9]*(?:count(?:er)?|cnt|ctr)[0-9]*|iteration|timeout)(?:_|$)",
    re.I,
)


def _read(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def analyze_latency(
    benchmarks: list[Benchmark], output_root: Path, requirement_root: Path,
) -> dict[str, Any]:
    r4_rows = {
        row["dut"]: row for row in _read(
            output_root / "temporal_challenges" / "variable_completion" / "dut_latency_evidence.json"
        ).get("rows", [])
    }
    evidence_rows, contracts, derivations, results = [], [], [], []
    for benchmark in benchmarks:
        typed = _read(output_root / benchmark.slug / "ir" / "design.json")["module"]
        signals = typed.get("signals", [])
        r4 = r4_rows.get(benchmark.design_id, {})
        env_signals = [
            {"signal": row["name"], "width": row.get("width"), "direction": row.get("direction")}
            for row in signals if row.get("direction") == "input" and HANDSHAKE.search(row["name"])
        ]
        internal_counters = [
            {"signal": row["name"], "width": row.get("width"), "direction": row.get("direction"),
             "domain_max": (2 ** int(row.get("width", 0)) - 1) if 0 < int(row.get("width", 0)) <= 32 else None}
            for row in signals if row.get("direction") != "input" and COUNTER.search(row["name"])
        ]
        evidence = {
            "dut": benchmark.design_id, "slug": benchmark.slug,
            "r4_variable_latency_evidence": r4.get("variable_latency_evidence", False),
            "environment_handshake_signals": env_signals,
            "internal_counter_signals": internal_counters,
            "rtl_evidence": r4.get("evidence", []),
        }
        evidence_rows.append(evidence)

        for signal in env_signals:
            contracts.append({
                "dut": benchmark.design_id, "response_signal": signal["signal"],
                "environment_assumption": f"ResponseWithin B_env via {signal['signal']}",
                "assumption_source": None,
                "protocol_source": "RTL port/control name only; no finite response contract found",
                "response_bound": None, "response_bound_source": None,
                "derived_completion_bound": None, "bound_derivation": None,
                "status": "ENVIRONMENT_UNBOUNDED",
                "admitted": False,
            })
        for signal in internal_counters:
            derivations.append({
                "dut": benchmark.design_id, "counter": signal["signal"],
                "counter_width": signal["width"], "representable_domain_max": signal["domain_max"],
                "rtl_guarantee": "finite counter value domain only",
                "completion_link_proved": False, "monotonic_progress_proved": False,
                "derived_completion_bound": None,
                "bound_derivation": (
                    "Rejected: counter width bounds values, but does not prove monotonic progress or a transition to Done"
                ),
                "status": "NO_COMPLETION_WITNESS",
                "admitted": False,
            })

        if benchmark.slug == "aes":
            latency_type = "FIXED_RELATIVE_LATENCY+SYMBOLIC_START_POSITION"
            bound_source = "RTL-controlled AES phases; no variable-latency interface was introduced"
        elif r4.get("variable_latency_evidence"):
            latency_type = "UNBOUNDED_VARIABLE_LATENCY"
            bound_source = "NONE: no RTL/protocol/environment finite response guarantee"
        else:
            latency_type = "FIXED_RELATIVE_LATENCY"
            bound_source = "no variable timing evidence"
        results.append({
            "dut": benchmark.design_id, "Latency Type": latency_type,
            "Bound Source": bound_source, "N": 0,
            "Baseline": 0, "Direct": 0, "Lemma-First": 0,
            "internally_bounded_candidates": sum(x["dut"] == benchmark.design_id for x in derivations),
            "environment_conditional_candidates": sum(x["dut"] == benchmark.design_id for x in contracts),
            "admission_reason": (
                "AES is not a variable-completion target" if benchmark.slug == "aes" else
                "No candidate has both a sourced finite bound and a kernel-provable DUT completion witness"
            ),
        })

    payloads = {
        "latency_evidence.json": {"schema": "rtl2lean-compositional_proofs-latency-evidence-v1", "rows": evidence_rows},
        "environment_contracts.json": {"schema": "rtl2lean-compositional_proofs-environment-contracts-v1", "rows": contracts},
        "bound_derivations.json": {"schema": "rtl2lean-compositional_proofs-bound-derivations-v1", "rows": derivations},
        "results.json": {
            "schema": "rtl2lean-compositional_proofs-variable-latency-results-v1",
            "properties": [], "N": 0, "rows": results,
            "classification_vocabulary": [
                "FIXED_RELATIVE_LATENCY", "SYMBOLIC_START_POSITION",
                "INTERNALLY_BOUNDED_VARIABLE_COMPLETION",
                "ENVIRONMENT_CONDITIONAL_COMPLETION", "UNBOUNDED_VARIABLE_LATENCY",
            ],
        },
    }
    for name, payload in payloads.items():
        write_json(requirement_root / "variable_latency" / name, payload)
    return payloads["results.json"]
