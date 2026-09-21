"""Generate DUT-local preservation foundations for compositional_proofs UNTIL targets."""
from __future__ import annotations

import re
from pathlib import Path
from typing import Any

from rtl2lean.evaluation.experiment import _lean_check
from rtl2lean.pipeline.compiler import kernel_check
from rtl2lean.pipeline.io import write_json
from rtl2lean.pipeline.manifest import Benchmark
from rtl2lean.temporal_challenges.corpus import discover_pairs
from rtl2lean.temporal_challenges.foundation import _chain_source, _safe


PROBE_TIMEOUT_S = 60


def chain_names(seed: dict[str, Any]) -> dict[str, str]:
    stem = f"r5_{_safe(seed['destination'])}"
    return {
        "post_comb_hold": stem + "_post_comb_hold",
        "register_hold": stem + "_register_hold",
        "state_preservation": stem + "_state_preservation",
        "prefix_preservation": stem + "_prefix_preservation",
        "completion_witness": stem + "_completion_witness",
    }


def _r5_chain_source(benchmark: Benchmark, hold: dict[str, Any], update: dict[str, Any]) -> str:
    source = _chain_source(benchmark, hold, update)
    r4_stem = f"r4_{_safe(hold['destination'])}"
    r5_stem = f"r5_{_safe(hold['destination'])}"
    return source.replace("import R3Foundation", "import R4Foundation", 1).replace(r4_stem, r5_stem)


def _nontrivial_score(pair: dict[str, Any]) -> tuple[Any, ...]:
    hold, update = pair["hold"], pair["update"]
    writes = set((hold.get("ir_evidence") or {}).get("write_set", []))
    other_writes = len(writes - {pair["destination"]})
    return (
        int(bool(pair.get("handshake_signal_hits"))),
        int(bool(pair.get("completion_signal_hits"))),
        int(other_writes > 0), other_writes,
        int(pair.get("width", 0) >= 2),
        hold.get("branch_depth", 0) + update.get("branch_depth", 0),
        hold.get("expression_size", 0) + update.get("expression_size", 0),
        pair.get("width", 0), pair["destination"],
    )


def discover_until_foundations(
    benchmarks: list[Benchmark], output_root: Path, requirement_root: Path,
) -> dict[str, Any]:
    """Probe one structurally maximal real hold/update chain per non-AES DUT."""
    selected: list[dict[str, Any]] = []
    candidates: list[dict[str, Any]] = []
    rejected: list[dict[str, Any]] = []
    for benchmark in benchmarks:
        if benchmark.slug == "aes":
            continue
        pairs, _ = discover_pairs(benchmark, output_root)
        eligible = sorted(pairs, key=_nontrivial_score, reverse=True)
        for rank, pair in enumerate(eligible):
            row = {
                "dut": benchmark.design_id, "slug": benchmark.slug, "rank": rank,
                "destination": pair["destination"], "width": pair["width"],
                "clock": pair["clock"], "hold_seed": pair["hold"]["seed_id"],
                "update_seed": pair["update"]["seed_id"],
                "completion_signal_hits": pair.get("completion_signal_hits", []),
                "handshake_signal_hits": pair.get("handshake_signal_hits", []),
                "rtl_supported": pair.get("rtl_supported", False),
                "other_process_writes": sorted(set(
                    (pair["hold"].get("ir_evidence") or {}).get("write_set", [])
                ) - {pair["destination"]}),
                "probe_timeout_s": PROBE_TIMEOUT_S,
            }
            candidates.append(row)
            if not row["rtl_supported"]:
                rejected.append({**row, "failure_class": "PROPERTY_NOT_TRUE",
                                 "reason": "missing matching RTL source evidence"})
                continue
            if pair["width"] <= 1:
                rejected.append({**row, "failure_class": "NO_PRESERVATION",
                                 "reason": "current generic chain requires a BitVec register wider than one bit"})
                continue
            probe_path = requirement_root / "until" / "probes" / benchmark.slug / f"{_safe(pair['destination'])}.lean"
            probe_path.parent.mkdir(parents=True, exist_ok=True)
            probe_path.write_text(_r5_chain_source(benchmark, pair["hold"], pair["update"]), encoding="utf-8")
            # The probe lives below outputs/compositional_proofs, while R4Foundation is
            # DUT-local under outputs/<slug>/model.  Use the same explicit
            # model search path as the later proof experiment; kernel_check's
            # path inference cannot discover a sibling DUT model from here.
            check = _lean_check(
                probe_path, output_root / benchmark.slug / "model", PROBE_TIMEOUT_S
            )
            if not check["success"]:
                output = check.get("stdout", "") + check.get("stderr", "")
                failure = (
                    "POST_COMB_INSTABILITY"
                    if check.get("returncode") != 124 and "post_comb_hold" in output
                    else "NO_PRESERVATION"
                )
                rejected.append({**row, "failure_class": failure, "reason": output[-4000:],
                                 "kernel_check": check})
                continue
            selected.append({**row, "hold": pair["hold"], "update": pair["update"],
                             "chain_lemmas": chain_names(pair["hold"]),
                             "state_changing_potential": bool(row["other_process_writes"]),
                             "probe_check": check})
            break

    write_json(requirement_root / "until" / "candidates.json", {
        "schema": "rtl2lean-compositional_proofs-until-candidates-v1",
        "selection_rule": "one maximal completion-like, RTL-backed, kernel-probed hold/update chain per non-AES DUT",
        "candidates": candidates,
    })
    write_json(requirement_root / "until" / "rejected.json", {
        "schema": "rtl2lean-compositional_proofs-until-rejected-v1", "rejected": rejected,
        "allowed_failure_classes": [
            "NO_PRESERVATION", "NO_COMPLETION_WITNESS", "NO_FINITE_BOUND",
            "INVALID_ASSUMPTION", "POST_COMB_INSTABILITY", "ENVIRONMENT_UNBOUNDED",
            "PROPERTY_NOT_TRUE",
        ],
    })
    return {"selected": selected, "candidates": candidates, "rejected": rejected}


def build_foundations(
    benchmarks: list[Benchmark], output_root: Path, requirement_root: Path,
    discovery: dict[str, Any],
) -> dict[str, Any]:
    selected = {row["dut"]: row for row in discovery["selected"]}
    rows = []
    for benchmark in benchmarks:
        model_dir = output_root / benchmark.slug / "model"
        path = model_dir / "R5Foundation.lean"
        row = selected.get(benchmark.design_id)
        source = (_r5_chain_source(benchmark, row["hold"], row["update"])
                  if row else "import R4Foundation\n\nset_option maxRecDepth 100000\nset_option maxHeartbeats 8000000\n")
        path.write_text(source, encoding="utf-8")
        check = kernel_check(path, timeout_s=1200, build_olean=True)
        result = {
            "dut": benchmark.design_id, "path": str(path.resolve()),
            "selected_until_chain": bool(row), "kernel_check": check,
            "chain_lemmas": row.get("chain_lemmas") if row else None,
            "destination": row.get("destination") if row else None,
        }
        rows.append(result)
        if not check["success"]:
            raise RuntimeError(f"R5Foundation failed for {benchmark.design_id}: " +
                               (check.get("stdout", "") + check.get("stderr", ""))[-5000:])
    payload = {"schema": "rtl2lean-compositional_proofs-foundation-v1", "foundations": rows,
               "selected_chains": discovery["selected"]}
    write_json(requirement_root / "until" / "foundation_checks.json", payload)
    return payload
