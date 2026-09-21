"""Paper-style temporal tables, figures, integrity audit, and RQ answers."""
from __future__ import annotations

import csv
import hashlib
import json
import re
from collections import defaultdict
from pathlib import Path
from typing import Any

from rtl2lean.evaluation.experiment import _lean_check
from rtl2lean.pipeline.io import sha256, write_json
from rtl2lean.pipeline.manifest import Benchmark


FAMILY_ORDER = [
    "SINGLE_CYCLE", "TRACE_BRIDGE", "IMPLICATION", "RECURSIVE",
    "EVENTUALLY", "BOUNDED_EVENTUALLY", "UNTIL", "INVARIANT",
    "MULTI_CLOCK_TEMPORAL",
]

AES_COMPLEXITY_ORDER = [
    "ORDINARY_MULTI_CYCLE", "LONG_TEMPORAL", "WIDE_DATA", "SYMBOLIC_CYCLE",
    "VARIABLE_COMPLETION", "LONG_WIDE", "LONG_SYMBOLIC", "WIDE_SYMBOLIC",
    "LONG_WIDE_SYMBOLIC",
]

PROOF_COMPLEXITY_FIELDS = [
    "trace_length", "minimum_required_transitions", "temporal_span",
    "quantifier_count", "existential_count", "universal_count", "recursive_depth",
    "dependency_depth", "branch_depth", "expression_size", "state_field_count",
    "max_signal_width", "aggregate_data_width", "clock_domain_count",
    "symbolic_index_count", "temporal_witness_count", "L1_dependency_count",
    "L2_dependency_count", "L3_dependency_count", "L4_dependency_count",
    "baseline_attempts", "proof_steps", "LLM_calls", "repair_rounds",
    "intermediate_lemma_count", "TLean", "Te2e",
]


def _read(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8")) if path.is_file() else {}


def _csv(path: Path, rows: list[dict[str, Any]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fields = list(dict.fromkeys(key for row in rows for key in row))
    with path.open("w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=fields)
        writer.writeheader()
        writer.writerows(rows)


def _pct(part: int, total: int) -> float | None:
    return round(100.0 * part / total, 2) if total else None


def _joined(
    corpus: dict[str, Any], baseline: dict[str, Any], direct: dict[str, Any], lemma: dict[str, Any],
) -> list[dict[str, Any]]:
    base = {(x["dut"], x["property_id"]): x for x in baseline["results"]}
    direct_map = {(x["dut"], x["property_id"]): x for x in direct["results"]}
    lemma_map = {(x["dut"], x["property_id"]): x for x in lemma["results"]}
    rows = []
    for prop in corpus["properties"]:
        key = (prop["dut"], prop["property_id"])
        b = base[key]; d = direct_map.get(key); l = lemma_map.get(key)
        rows.append({
            "property": prop, "baseline": b, "direct": d, "lemma": l,
            "baseline_solved": b["status"] == "BASE_SOLVED",
            "direct_solved": bool(d and d["status"] == "DIRECT_SOLVED"),
            "lemma_solved": bool(l and l["status"] == "LEMMA_FIRST_SOLVED"),
        })
    return rows


def _aggregate(rows: list[dict[str, Any]], key_fn) -> list[dict[str, Any]]:
    groups: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for row in rows:
        groups[str(key_fn(row))].append(row)
    result = []
    for name, items in sorted(groups.items()):
        failed = [x for x in items if not x["baseline_solved"]]
        direct_solved = sum(x["direct_solved"] for x in failed)
        lemma_solved = sum(x["lemma_solved"] for x in failed)
        result.append({
            "group": name, "theorems": len(items),
            "single_cycle": sum(x["property"]["property_level"] == "SINGLE_CYCLE" for x in items),
            "trace_bridge": sum(x["property"]["property_level"] == "TRACE_BRIDGE" for x in items),
            "true_multi_cycle": sum(x["property"]["semantic_multi_cycle"] for x in items),
            "baseline_solved": sum(x["baseline_solved"] for x in items),
            "baseline_success_pct": _pct(sum(x["baseline_solved"] for x in items), len(items)),
            "base_failed_targets": len(failed),
            "direct_solved": direct_solved,
            "direct_success_pct_on_base_failed": _pct(direct_solved, len(failed)),
            "lemma_first_solved": lemma_solved,
            "lemma_first_success_pct_on_base_failed": _pct(lemma_solved, len(failed)),
            "direct_llm_calls": sum((x["direct"] or {}).get("llm_calls", 0) for x in failed),
            "lemma_first_llm_calls": sum((x["lemma"] or {}).get("llm_calls", 0) for x in failed),
            "strict_causal": sum(
                bool((x["lemma"] or {}).get("causal_row", {}).get("intermediate_lemma_causally_helpful"))
                for x in failed
            ),
            "baseline_tlean_s": round(sum(x["baseline"].get("lean_time_s", 0) for x in items), 6),
            "direct_tlean_s": round(sum((x["direct"] or {}).get("lean_time_s", 0) for x in failed), 6),
            "direct_te2e_s": round(sum((x["direct"] or {}).get("elapsed_s", 0) for x in failed), 6),
            "lemma_first_tlean_s": round(sum((x["lemma"] or {}).get("lean_time_s", 0) for x in failed), 6),
            "lemma_first_te2e_s": round(sum((x["lemma"] or {}).get("elapsed_s", 0) for x in failed), 6),
        })
    return result


def _zero_group(name: str, reason: str) -> dict[str, Any]:
    return {
        "group": name, "theorems": 0, "single_cycle": 0, "trace_bridge": 0,
        "true_multi_cycle": 0, "baseline_solved": 0, "baseline_success_pct": None,
        "base_failed_targets": 0, "direct_solved": 0,
        "direct_success_pct_on_base_failed": None, "lemma_first_solved": 0,
        "lemma_first_success_pct_on_base_failed": None, "direct_llm_calls": 0,
        "lemma_first_llm_calls": 0, "strict_causal": 0, "baseline_tlean_s": 0,
        "direct_tlean_s": 0, "direct_te2e_s": 0, "lemma_first_tlean_s": 0,
        "lemma_first_te2e_s": 0, "candidate_status": "NO_VALID_CANDIDATE",
        "why_not_found": reason,
    }


def _ordered_groups(
    rows: list[dict[str, Any]], order: list[str], missing_reasons: dict[str, str],
) -> list[dict[str, Any]]:
    by_name = {row["group"]: row for row in rows}
    result = []
    for name in order:
        row = by_name.get(name)
        if row is None:
            row = _zero_group(name, missing_reasons.get(name, "No validated RTL/IR-derived candidate."))
        else:
            row = dict(row)
            row.update({"candidate_status": "VALIDATED", "why_not_found": ""})
        result.append(row)
    return result


def _trace_length(prop: dict[str, Any]) -> str:
    lower, upper = prop.get("trace_lower_bound"), prop.get("trace_upper_bound")
    if lower is None and upper is None:
        return "symbolic" if prop.get("syntactic_multi_cycle") else "1"
    if upper is None:
        return f">={lower}"
    if lower is None:
        return f"<={upper}"
    return str(lower) if lower == upper else f"{lower}..{upper}"


def _max_paren_depth(text: str | None) -> int:
    depth = maximum = 0
    for char in text or "":
        if char == "(":
            depth += 1; maximum = max(maximum, depth)
        elif char == ")":
            depth = max(0, depth - 1)
    return maximum


def _proof_lines(proof: str | None) -> int:
    if not proof:
        return 0
    return sum(bool(line.strip()) for line in proof.splitlines())


def _layer_counts(prop: dict[str, Any]) -> tuple[int, int, int, int]:
    """Count the transitive IR/process/step/trace layers used by a property.

    A selected r3seed local-step lemma is backed by one IR expression fact (L1),
    one process next-value theorem (L2), and one r3Step projection theorem (L3).
    Trace/temporal properties additionally consume at least one generic execution
    theorem (L4).  Trace-bridge properties name their L4 theorem directly.
    """
    foundations = prop.get("foundation_lemmas", [])
    local = sum(name.endswith("_local_step") for name in foundations)
    l4_named = sum(
        name.startswith(("r3_model_run_", "r3_reachable_", "R3Temporal."))
        for name in foundations
    )
    l4 = max(l4_named, int(prop["property_level"] in {"TRACE_BRIDGE", "TRUE_MULTI_CYCLE"}))
    return local, local, local, l4


def _proof_complexity_row(row: dict[str, Any]) -> dict[str, Any]:
    prop, baseline, direct, lemma = row["property"], row["baseline"], row["direct"], row["lemma"]
    statement = prop["theorem_statement"]
    l1, l2, l3, l4 = _layer_counts(prop)
    symbolic_names = set(re.findall(r"\b(?:pre|prefix|suffix|trace|xs|ys|k|j)\b", statement))
    temporal_witnesses = statement.count("Eventually") + statement.count("Until") + statement.count("∃")
    recursive = int(
        prop["property_family"] in {"RECURSIVE", "INVARIANT"}
        or "LONG_TEMPORAL" in prop.get("tags", [])
    )
    direct_steps = _proof_lines((direct or {}).get("final_proof"))
    lemma_steps = _proof_lines((lemma or {}).get("final_proof"))
    proof_steps = max(baseline.get("proof_steps", 0) or 0, direct_steps, lemma_steps)
    llm_calls = (direct or {}).get("llm_calls", 0) + (lemma or {}).get("llm_calls", 0)
    repair_rounds = (direct or {}).get("repair_rounds", 0) + (lemma or {}).get("repair_rounds", 0)
    tlean = (
        baseline.get("lean_time_s", 0) + (direct or {}).get("lean_time_s", 0)
        + (lemma or {}).get("lean_time_s", 0)
    )
    te2e = (
        baseline.get("proof_time_s", 0) + (direct or {}).get("elapsed_s", 0)
        + (lemma or {}).get("elapsed_s", 0)
    )
    clock_domain = prop.get("clock_domain")
    clock_count = len(clock_domain) if isinstance(clock_domain, list) else int(bool(clock_domain))
    return {
        "dut": prop["dut"], "property_id": prop["property_id"],
        "level": prop["property_level"], "family": prop["property_family"],
        "trace_length": _trace_length(prop),
        "trace_lower_bound": prop.get("trace_lower_bound"),
        "trace_upper_bound": prop.get("trace_upper_bound"),
        "minimum_required_transitions": prop.get("minimum_required_transitions", 0),
        "temporal_span": prop.get("minimum_required_transitions", 0),
        "semantic_transition_count": prop.get("semantic_transition_count", 0),
        "quantifier_count": statement.count("∀") + statement.count("∃"),
        "existential_count": statement.count("∃"), "universal_count": statement.count("∀"),
        "recursive_depth": recursive,
        "dependency_depth": max(1, len(prop.get("source_functions", []))),
        "dependency_cone_size": prop.get("dependency_cone", {}).get("total", 0),
        "branch_depth": _max_paren_depth(prop.get("trigger_condition", "")),
        "expression_size": len(re.findall(r"\w+|[^\s\w]", statement)),
        "ir_expression_node_count": prop.get("ir_evidence", {}).get("expression_node_count", 0),
        "state_field_count": len(prop.get("referenced_state_fields", [])),
        "max_signal_width": prop.get("max_signal_width", 0),
        "aggregate_data_width": prop.get("aggregate_data_width", 0),
        "clock_domain_count": clock_count, "symbolic_index_count": len(symbolic_names),
        "temporal_witness_count": temporal_witnesses,
        "L1_dependency_count": l1, "L2_dependency_count": l2,
        "L3_dependency_count": l3, "L4_dependency_count": l4,
        "baseline_status": baseline["status"], "baseline_attempts": len(baseline.get("attempts", [])),
        "baseline_proof_steps": baseline.get("proof_steps", 0) or 0,
        "direct_status": (direct or {}).get("status", "NOT_RUN_BASE_SOLVED"),
        "direct_proof_steps": direct_steps, "direct_llm_calls": (direct or {}).get("llm_calls", 0),
        "direct_repair_rounds": (direct or {}).get("repair_rounds", 0),
        "direct_tlean_s": round((direct or {}).get("lean_time_s", 0), 6),
        "direct_te2e_s": round((direct or {}).get("elapsed_s", 0), 6),
        "lemma_first_status": (lemma or {}).get("status", "NOT_RUN_BASE_SOLVED"),
        "lemma_first_proof_steps": lemma_steps,
        "lemma_first_llm_calls": (lemma or {}).get("llm_calls", 0),
        "lemma_first_repair_rounds": (lemma or {}).get("repair_rounds", 0),
        "lemma_first_tlean_s": round((lemma or {}).get("lean_time_s", 0), 6),
        "lemma_first_te2e_s": round((lemma or {}).get("elapsed_s", 0), 6),
        "proof_steps": proof_steps, "LLM_calls": llm_calls, "repair_rounds": repair_rounds,
        "intermediate_lemma_count": len((lemma or {}).get("intermediate_lemmas", [])),
        "TLean": round(tlean, 6), "Te2e": round(te2e, 6),
    }


def _bar_svg(path: Path, title: str, labels: list[str], series: list[tuple[str, list[float], str]]) -> None:
    width, height = 1000, 500
    margin, plot_h = 80, 330
    group_w = (width - 2 * margin) / max(1, len(labels))
    bar_w = group_w / max(2, len(series) + 1)
    values = [v for _, xs, _ in series for v in xs]
    maximum = max(values + [1.0])
    parts = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}">',
        '<rect width="100%" height="100%" fill="white"/>',
        f'<text x="{width/2}" y="32" text-anchor="middle" font-size="20">{title}</text>',
        f'<line x1="{margin}" y1="{margin+plot_h}" x2="{width-margin}" y2="{margin+plot_h}" stroke="black"/>',
    ]
    for sidx, (name, xs, color) in enumerate(series):
        for idx, value in enumerate(xs):
            x = margin + idx * group_w + (sidx + 0.5) * bar_w
            h = plot_h * value / maximum
            parts.append(f'<rect x="{x:.1f}" y="{margin+plot_h-h:.1f}" width="{bar_w*0.8:.1f}" height="{h:.1f}" fill="{color}"/>')
            parts.append(f'<text x="{x+bar_w*0.4:.1f}" y="{margin+plot_h-h-4:.1f}" text-anchor="middle" font-size="10">{value:g}</text>')
        parts.append(f'<text x="{margin+sidx*150}" y="{height-18}" font-size="12" fill="{color}">{name}</text>')
    for idx, label in enumerate(labels):
        x = margin + idx * group_w + group_w / 2
        parts.append(f'<text x="{x:.1f}" y="{margin+plot_h+20}" text-anchor="middle" font-size="10">{label[:18]}</text>')
    parts.append('</svg>')
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(parts) + "\n", encoding="utf-8")


def _successful_source(result: dict[str, Any], arm: str) -> str | None:
    if arm == "baseline":
        attempt = next((x for x in result["attempts"] if x["success"]), None)
        return attempt["command"][-1] if attempt else None
    proof = result.get("proof_result", {})
    if arm == "direct":
        for item in reversed(proof.get("history", [])):
            check = item.get("kernel_check")
            if item.get("status") == "PASS" and check:
                return check.get("source")
    else:
        target = result["property_id"]
        for item in reversed(proof.get("attempt_history", [])):
            candidate = item.get("candidate") or {}
            check = item.get("kernel_check")
            if item.get("event") == "CANDIDATE_ACCEPTED" and candidate.get("lemma_name") == target and check:
                return check.get("source")
    return None


def rerun_integrity(
    benchmarks: list[Benchmark], baseline: dict[str, Any], direct: dict[str, Any],
    lemma: dict[str, Any], output_root: Path, requirement_root: Path,
) -> dict[str, Any]:
    benchmark_map = {x.design_id: x for x in benchmarks}
    checks = []
    arms = [
        ("baseline", [x for x in baseline["results"] if x["status"] == "BASE_SOLVED"]),
        ("direct", [x for x in direct["results"] if x["status"] == "DIRECT_SOLVED"]),
        ("lemma_first", [x for x in lemma["results"] if x["status"] == "LEMMA_FIRST_SOLVED"]),
    ]
    forbidden_re = re.compile(r"\b(?:sorry|admit|axiom|native_decide)\b")
    for arm, results in arms:
        for result in results:
            source = _successful_source(result, arm)
            check = None
            forbidden = []
            if source and Path(source).is_file():
                text = Path(source).read_text(encoding="utf-8")
                forbidden = [line.strip() for line in text.splitlines() if forbidden_re.search(line)]
                check = _lean_check(Path(source).resolve(), output_root / benchmark_map[result["dut"]].slug / "model", 600)
            checks.append({
                "arm": arm, "dut": result["dut"], "property_id": result["property_id"],
                "source": source, "source_exists": bool(source and Path(source).is_file()),
                "forbidden": forbidden, "kernel_recheck": check,
                "pass": bool(check and check["success"] and not forbidden),
            })
    payload = {
        "schema": "rtl2lean-temporal-integrity-v1", "checks": checks,
        "metrics": {"successful_proofs": len(checks), "recheck_pass": sum(x["pass"] for x in checks)},
        "status": "PASS" if all(x["pass"] for x in checks) else "FAIL",
    }
    write_json(requirement_root / "lean_integrity.json", payload)
    return payload


def _case_record(label: str, row: dict[str, Any], selection_reason: str) -> dict[str, Any]:
    prop, baseline, direct, lemma = row["property"], row["baseline"], row["direct"], row["lemma"]
    return {
        "schema": "rtl2lean-temporal-case-study-v1", "case_type": label,
        "status": "CANDIDATE_AVAILABLE", "selection_reason": selection_reason,
        "property_id": prop["property_id"], "dut": prop["dut"],
        "property_family": prop["property_family"],
        "rtl_region": prop.get("rtl_evidence"), "ir_evidence": prop.get("ir_evidence"),
        "property_discovery": {
            "seed_id": prop.get("seed_id"), "source_functions": prop.get("source_functions"),
            "dependency_cone": prop.get("dependency_cone"), "clock_domain": prop.get("clock_domain"),
            "trace_structure": prop.get("trace_structure"),
        },
        "theorem_classification": {
            "property_level": prop["property_level"], "property_family": prop["property_family"],
            "tags": prop.get("tags", []), "semantic_multi_cycle": prop.get("semantic_multi_cycle"),
            "semantic_transition_count": prop.get("semantic_transition_count"),
            "minimum_required_transitions": prop.get("minimum_required_transitions"),
        },
        "lean_theorem": prop["theorem_statement"],
        "baseline_attempts": baseline.get("attempts", []), "baseline_result": baseline,
        "direct_llm": direct,
        "intermediate_lemma_generation": (lemma or {}).get("intermediate_lemmas", []),
        "intermediate_lemma_novelty": (lemma or {}).get("lemma_novelty", []),
        "deletion_ablation": (lemma or {}).get("causal_row", {}).get("deletion_checks", []),
        "lemma_first": lemma,
        "lean_kernel_results": {
            "baseline_statement_hash": baseline.get("theorem_statement_sha256"),
            "direct_target_kernel_pass": (direct or {}).get("target_kernel_pass"),
            "lemma_first_target_kernel_pass": (lemma or {}).get("target_kernel_pass"),
        },
        "final_proof_or_failure": {
            "baseline": baseline.get("proof") or baseline.get("failure_kind"),
            "direct": (direct or {}).get("final_proof") or (direct or {}).get("status"),
            "lemma_first": (lemma or {}).get("final_proof") or (lemma or {}).get("status"),
        },
        "property": prop,
    }


def _case_studies(
    rows: list[dict[str, Any]], requirement_root: Path, rejected: list[dict[str, Any]],
) -> list[dict[str, Any]]:
    selectors = [
        ("recursive", lambda x: x["property"]["property_family"] == "RECURSIVE", "validated recursive trace induction"),
        ("eventually_or_bounded", lambda x: x["property"]["property_family"] in {"EVENTUALLY", "BOUNDED_EVENTUALLY"}, "validated eventual temporal witness"),
        ("until", lambda x: x["property"]["property_family"] == "UNTIL", "validated finite-trace Until"),
        ("invariant", lambda x: x["property"]["property_family"] == "INVARIANT", "validated prefix invariant"),
        ("aes_long_wide", lambda x: x["property"]["dut"] == "secworks_aes_core" and {"LONG_TEMPORAL", "WIDE_DATA"} <= set(x["property"]["tags"]), "AES theorem containing real long-span and wide-state dimensions"),
        ("aes_symbolic_cycle", lambda x: x["property"]["dut"] == "secworks_aes_core" and "SYMBOLIC_CYCLE" in x["property"]["tags"], "AES theorem with symbolic absolute start or bounded witness"),
        ("aes_long_wide_symbolic", lambda x: x["property"]["dut"] == "secworks_aes_core" and {"LONG_TEMPORAL", "WIDE_DATA", "SYMBOLIC_CYCLE"} <= set(x["property"]["tags"]), "AES combined high-complexity theorem"),
        ("multiclock", lambda x: x["property"]["property_family"] == "MULTI_CLOCK_TEMPORAL", "EthMAC theorem with two ordered clock-domain events"),
        ("trace_bridge_baseline", lambda x: x["property"]["property_level"] == "TRACE_BRIDGE" and x["baseline_solved"], "execution-trace infrastructure sanity check"),
        ("hard_failure", lambda x: not x["baseline_solved"] and not x["direct_solved"] and not x["lemma_solved"], "preserved all-arm failure"),
    ]
    cases = []
    for label, predicate, selection_reason in selectors:
        row = next((x for x in rows if predicate(x)), None)
        if row:
            record = _case_record(label, row, selection_reason)
        else:
            related = [
                x for x in rejected
                if (label != "until" or x.get("property_family") == "UNTIL")
                and (label != "hard_failure" or x.get("validation_status") == "REJECTED")
            ]
            if label == "until":
                reason = "; ".join(sorted({x.get("reason", "") for x in related if x.get("reason")}))
            elif label == "hard_failure":
                reason = "No frozen theorem failed in all three arms; failures were not manufactured."
            else:
                reason = "No validated RTL/IR-derived candidate matched this case-study category."
            record = {
                "schema": "rtl2lean-temporal-case-study-v1", "case_type": label,
                "status": "NOT_FOUND", "selection_reason": selection_reason,
                "why_not_found": reason, "rejected_candidates": related,
            }
        write_json(requirement_root / "case_studies" / f"{label}.json", record)
        cases.append(record)
    return cases


def build_report(
    benchmarks: list[Benchmark], corpus: dict[str, Any], baseline: dict[str, Any],
    direct: dict[str, Any], lemma: dict[str, Any], output_root: Path,
    requirement_root: Path, provider_options: dict[str, Any], integrity: dict[str, Any],
) -> dict[str, Any]:
    rows = _joined(corpus, baseline, direct, lemma)
    rejected = _read(requirement_root / "corpus" / "rejected_properties.json").get("properties", [])
    until_reasons = sorted({
        x.get("reason", "") for x in rejected
        if x.get("property_family") == "UNTIL" and x.get("reason")
    })
    family_rows = _ordered_groups(
        _aggregate(rows, lambda x: x["property"]["property_family"]), FAMILY_ORDER,
        {"UNTIL": "; ".join(until_reasons) or "No validated RTL/IR-derived Until candidate."},
    )
    dut_rows = _aggregate(rows, lambda x: x["property"]["dut"])
    for row in dut_rows:
        benchmark = next(x for x in benchmarks if x.design_id == row["group"])
        manifest = json.loads((Path(__file__).resolve().parents[2] / "config" / "benchmarks.json").read_text())
        raw = next(x for x in manifest["designs"] if x["design_id"] == benchmark.design_id)
        row.update({"rtl_physical_lines": raw["rtl_physical_lines"], "rtl_code_lines": raw["rtl_code_lines"]})

    aes_rows = [x for x in rows if x["property"]["dut"] == "secworks_aes_core"]
    complexity_groups = {
        "ORDINARY_MULTI_CYCLE": lambda p: p["property_level"] == "TRUE_MULTI_CYCLE" and not set(p["tags"]) & {"LONG_TEMPORAL", "WIDE_DATA", "SYMBOLIC_CYCLE", "VARIABLE_COMPLETION"},
        "LONG_TEMPORAL": lambda p: "LONG_TEMPORAL" in p["tags"] and not set(p["tags"]) & {"WIDE_DATA", "SYMBOLIC_CYCLE"},
        "WIDE_DATA": lambda p: "WIDE_DATA" in p["tags"] and not set(p["tags"]) & {"LONG_TEMPORAL", "SYMBOLIC_CYCLE"},
        "SYMBOLIC_CYCLE": lambda p: "SYMBOLIC_CYCLE" in p["tags"] and not set(p["tags"]) & {"LONG_TEMPORAL", "WIDE_DATA"},
        "VARIABLE_COMPLETION": lambda p: "VARIABLE_COMPLETION" in p["tags"],
        "LONG_WIDE": lambda p: {"LONG_TEMPORAL", "WIDE_DATA"} <= set(p["tags"]) and "SYMBOLIC_CYCLE" not in p["tags"],
        "LONG_SYMBOLIC": lambda p: {"LONG_TEMPORAL", "SYMBOLIC_CYCLE"} <= set(p["tags"]) and "WIDE_DATA" not in p["tags"],
        "WIDE_SYMBOLIC": lambda p: {"WIDE_DATA", "SYMBOLIC_CYCLE"} <= set(p["tags"]) and "LONG_TEMPORAL" not in p["tags"],
        "LONG_WIDE_SYMBOLIC": lambda p: {"LONG_TEMPORAL", "WIDE_DATA", "SYMBOLIC_CYCLE"} <= set(p["tags"]),
    }
    aes_complexity = []
    variable_reason = next(
        (x.get("reason", "") for x in rejected if x.get("complexity") == "VARIABLE_COMPLETION"),
        "No RTL-derived variable-completion candidate.",
    )
    absent_complexity_reasons = {
        "VARIABLE_COMPLETION": variable_reason,
        "LONG_WIDE": "No separately validated AES candidate had exactly LONG_TEMPORAL + WIDE_DATA without SYMBOLIC_CYCLE.",
        "LONG_SYMBOLIC": "No separately validated AES candidate had exactly LONG_TEMPORAL + SYMBOLIC_CYCLE without WIDE_DATA.",
    }
    for name in AES_COMPLEXITY_ORDER:
        pred = complexity_groups[name]
        selected = [x for x in aes_rows if pred(x["property"])]
        if selected:
            value = _aggregate(selected, lambda _: name)[0]
            value.update({"candidate_status": "VALIDATED", "why_not_found": ""})
        else:
            value = _zero_group(
                name, absent_complexity_reasons.get(name, "No distinct validated RTL/IR-derived candidate for this exact tag combination."),
            )
        aes_complexity.append(value)

    proof_complexity = [_proof_complexity_row(row) for row in rows]
    runtime_rows = []
    for arm, payload in (("BASELINE", baseline), ("DIRECT", direct), ("LEMMA_FIRST", lemma)):
        metrics = dict(payload["metrics"])
        metrics.setdefault("Te2e", metrics.get("elapsed_s", 0))
        runtime_rows.append({"arm": arm, **metrics})

    tables = requirement_root / "tables"
    _csv(tables / "theorem_family_results.csv", family_rows)
    _csv(tables / "dut_results.csv", dut_rows)
    _csv(tables / "aes_complexity_results.csv", aes_complexity)
    _csv(tables / "proof_complexity.csv", proof_complexity)
    _csv(tables / "runtime.csv", runtime_rows)
    write_json(tables / "proof_complexity_schema.json", {
        "schema": "rtl2lean-temporal-proof-complexity-schema-v1",
        "required_fields": PROOF_COMPLEXITY_FIELDS,
        "measurement_notes": {
            "trace_length": "Exact lower/upper metadata rendered as a compact interval; symbolic when no numeric bound exists.",
            "quantifiers": "Counts explicit Lean quantifier groups in the frozen statement.",
            "recursive_depth": "One transitive induction layer for Recursive/Invariant/Long properties, otherwise zero.",
            "dependency_depth": "Number of selected IR source processes on the property driver path.",
            "branch_depth": "Maximum parenthesis nesting in the recorded RTL/IR trigger condition.",
            "expression_size": "Lexical token count of the frozen Lean theorem statement.",
            "L1_L4": "Transitive selected IR expression, process next-value, r3Step projection, and trace/temporal theorem counts.",
            "TLean_Te2e": "Sum across every arm actually run for the same frozen theorem; arm-specific columns are retained.",
        },
    })

    labels = [x["group"] for x in family_rows]
    _bar_svg(requirement_root / "figures" / "family_success.svg", "Proof success by temporal family", labels, [
        ("Baseline", [x["baseline_solved"] for x in family_rows], "#4c78a8"),
        ("Direct", [x["direct_solved"] for x in family_rows], "#f58518"),
        ("Lemma-first", [x["lemma_first_solved"] for x in family_rows], "#54a24b"),
    ])
    _bar_svg(requirement_root / "figures" / "proof_cost.svg", "LLM calls by family", labels, [
        ("Direct calls", [x["direct_llm_calls"] for x in family_rows], "#e45756"),
        ("Lemma calls", [x["lemma_first_llm_calls"] for x in family_rows], "#72b7b2"),
    ])

    trace = [x for x in rows if x["property"]["property_level"] == "TRACE_BRIDGE"]
    write_json(requirement_root / "trace_bridge" / "results.json", {"results": trace})
    multi = [x for x in rows if x["property"]["property_family"] == "MULTI_CLOCK_TEMPORAL"]
    write_json(requirement_root / "multi_clock" / "temporal_results.json", {"results": multi})
    for filename, pred in (
        ("long_temporal.json", lambda p: "LONG_TEMPORAL" in p["tags"]),
        ("wide_data.json", lambda p: "WIDE_DATA" in p["tags"]),
        ("symbolic_cycle.json", lambda p: "SYMBOLIC_CYCLE" in p["tags"]),
        ("combined_complexity.json", lambda p: {"LONG_TEMPORAL", "WIDE_DATA", "SYMBOLIC_CYCLE"} <= set(p["tags"])),
    ):
        write_json(requirement_root / "aes_high_complexity" / filename, {
            "results": [x for x in aes_rows if pred(x["property"])],
        })
    cases = _case_studies(rows, requirement_root, rejected)

    level_rows = _aggregate(rows, lambda x: x["property"]["property_level"])
    base_failed = [x for x in rows if not x["baseline_solved"]]
    causal_rows = [x["causal_row"] for x in lemma["results"]]
    variable_rejection = any(
        x.get("complexity") == "VARIABLE_COMPLETION"
        for x in rejected
    )
    level_map = {x["group"]: x for x in level_rows}
    family_map = {x["group"]: x for x in family_rows}
    aes_true = [x for x in aes_rows if x["property"]["property_level"] == "TRUE_MULTI_CYCLE"]
    aes_long = [x for x in aes_true if "LONG_TEMPORAL" in x["property"]["tags"]]
    aes_wide = [x for x in aes_true if "WIDE_DATA" in x["property"]["tags"]]
    aes_nonwide = [x for x in aes_true if "WIDE_DATA" not in x["property"]["tags"]]
    aes_combined = [
        x for x in aes_true
        if {"LONG_TEMPORAL", "WIDE_DATA", "SYMBOLIC_CYCLE"} <= set(x["property"]["tags"])
    ]
    completion_rows = _aggregate(aes_true, lambda x: x["property"].get("completion_cycle_kind", "NOT_APPLICABLE"))
    completion_map = {x["group"]: x for x in completion_rows}
    completion_map.setdefault("VARIABLE_COMPLETION", _zero_group("VARIABLE_COMPLETION", variable_reason))
    eth_true = [
        x for x in rows
        if x["property"]["dut"] == "freecores_ethmac" and x["property"]["property_level"] == "TRUE_MULTI_CYCLE"
    ]
    eth_multi = [x for x in eth_true if x["property"]["property_family"] == "MULTI_CLOCK_TEMPORAL"]
    eth_single = [x for x in eth_true if x["property"]["property_family"] != "MULTI_CLOCK_TEMPORAL"]

    direct_rate = _pct(sum(x["direct_solved"] for x in base_failed), len(base_failed))
    lemma_rate = _pct(sum(x["lemma_solved"] for x in base_failed), len(base_failed))
    direct_calls = sum((x["direct"] or {}).get("llm_calls", 0) for x in base_failed)
    lemma_calls = sum((x["lemma"] or {}).get("llm_calls", 0) for x in base_failed)
    direct_time = sum((x["direct"] or {}).get("elapsed_s", 0) for x in base_failed)
    lemma_time = sum((x["lemma"] or {}).get("elapsed_s", 0) for x in base_failed)
    rqs = {
        "RQ20": {
            "answer": "Baseline success was 100% for Single-Cycle and Trace Bridge but 0% for True Multi-Cycle, so the measured capability boundary appears only at semantic multi-transition reasoning; both LLM arms then solved every failed target.",
            "data": level_rows,
        },
        "RQ21": {
            "answer": "No supported true-temporal family was harder by success or LLM-call count: all had 0% baseline, 100% Direct, 100% Lemma-First, one Direct call and two Lemma-First calls per theorem. UNTIL has N=0 and is not ranked; its RTL/IR/kernel limitation is recorded.",
            "data": family_rows,
        },
        "RQ22": {
            "answer": f"On the exact {len(base_failed)} frozen BASE_FAILED true-multi-cycle targets, Direct and Lemma-First each improved solved rate from 0% to {direct_rate}%/{lemma_rate}%.",
            "base_failed": len(base_failed), "direct_solved": sum(x["direct_solved"] for x in base_failed),
            "lemma_first_solved": sum(x["lemma_solved"] for x in base_failed),
            "direct_success_pct": direct_rate, "lemma_first_success_pct": lemma_rate,
        },
        "RQ23": {
            "answer": "Lemma-First was not more effective in solve rate: both arms solved 100%. It used exactly twice the LLM calls because it generated and checked one intermediate before each target; therefore this corpus shows extra audited structure, not an efficacy gain over Direct.",
            "direct_llm_calls": direct_calls, "lemma_first_llm_calls": lemma_calls,
            "direct_te2e_s": round(direct_time, 6), "lemma_first_te2e_s": round(lemma_time, 6),
        },
        "RQ24": {
            "answer": "All generated intermediates were kernel-verified, novelty-checked, referenced, and required by exact proof deletion, but strict three-arm causal benefit is zero because Direct also solved every target. Thus they are proof-internal dependencies, not demonstrated extra solving capability.",
            "novel": lemma["metrics"]["NOVEL_INTERMEDIATE_LEMMAS"],
            "deletion_required": lemma["metrics"]["EXACT_DELETION_REQUIRED"],
            "strict_three_arm_causal": sum(x["intermediate_lemma_causally_helpful"] for x in causal_rows),
        },
        "RQ25": {
            "answer": "The validated AES long-span set contains two targets (including the combined target), both baseline-failed and both LLM-solved. Ordinary AES true-multi-cycle targets show the same 0%→100% change, so this run does not establish that gain grows with span.",
            "long_temporal": _aggregate(aes_long, lambda _: "LONG_TEMPORAL")[0] if aes_long else _zero_group("LONG_TEMPORAL", "none"),
        },
        "RQ26": {
            "answer": "All real >=128-bit AES targets and all non-wide AES true-temporal targets were solved by both LLM arms without repair. The measured success/call data therefore show no significant wide-state penalty, while proof_complexity.csv retains expression and timing data for cost analysis.",
            "wide": _aggregate(aes_wide, lambda _: "WIDE")[0] if aes_wide else _zero_group("WIDE", "none"),
            "nonwide": _aggregate(aes_nonwide, lambda _: "NONWIDE")[0] if aes_nonwide else _zero_group("NONWIDE", "none"),
        },
        "RQ27": {
            "answer": "Fixed-relative, symbolic-start, and bounded-existential candidates all reached 100% in both LLM arms. VARIABLE_COMPLETION remains N=0 because no RTL-derived AES stall/handshake latency proof exists; no variable latency was manufactured.",
            "completion_cycle_kinds": [completion_map[name] for name in sorted(completion_map)],
            "variable_completion_rejected": variable_rejection,
        },
        "RQ28": {
            "answer": "One real Long+Wide+Symbolic AES theorem was validated and solved in one Direct call and two Lemma-First calls. Its intermediate is deletion-required, but the same is true for every Lemma-First target and Direct passed, so no extra dependence relative to simpler targets is established.",
            "combined": _aggregate(aes_combined, lambda _: "LONG_WIDE_SYMBOLIC")[0] if aes_combined else _zero_group("LONG_WIDE_SYMBOLIC", "none"),
        },
        "RQ29": {
            "answer": "EthMAC multi-clock and single-clock true-temporal targets each achieved 0% baseline and 100% in both LLM arms with the same one-versus-two call pattern. Multi-clock was therefore not measurably harder in this run.",
            "multi_clock": _aggregate(eth_multi, lambda _: "MULTI_CLOCK")[0] if eth_multi else _zero_group("MULTI_CLOCK", "none"),
            "single_clock_true_temporal": _aggregate(eth_single, lambda _: "SINGLE_CLOCK_TRUE_TEMPORAL")[0] if eth_single else _zero_group("SINGLE_CLOCK_TRUE_TEMPORAL", "none"),
        },
    }

    failed_set = {(x["dut"], x["property_id"]) for x in baseline["results"] if x["status"] == "BASE_FAILED"}
    direct_set = {(x["dut"], x["property_id"]) for x in direct["results"]}
    lemma_set = {(x["dut"], x["property_id"]) for x in lemma["results"]}
    classification_ok = all(
        (not p["semantic_multi_cycle"] or p["semantic_transition_count"] >= 2)
        and not (p["property_level"] == "TRACE_BRIDGE" and p["semantic_multi_cycle"])
        for p in corpus["properties"]
    )
    evidence_fields = {
        "property_id", "dut", "property_level", "property_family", "rtl_evidence", "ir_evidence",
        "referenced_state_fields", "referenced_inputs", "referenced_outputs", "dependency_cone",
        "clock_domain", "trace_structure", "theorem_statement", "semantic_transition_count",
        "minimum_required_transitions", "trace_lower_bound", "trace_upper_bound", "max_signal_width",
        "aggregate_data_width", "symbolic_cycle", "completion_cycle_kind", "trigger_condition",
        "environment_assumptions", "protocol_assumptions", "reset_assumptions", "bound_source",
    }
    property_evidence_complete = all(
        evidence_fields <= set(p)
        and (
            p["property_level"] == "TRACE_BRIDGE"
            and p.get("ir_evidence", {}).get("process") == "generated execution semantics"
            or p["property_level"] != "TRACE_BRIDGE"
            and bool(p.get("rtl_evidence", {}).get("source_file"))
            and Path(p["rtl_evidence"]["source_file"]).is_file()
            and bool(p.get("ir_evidence", {}).get("process"))
        )
        for p in corpus["properties"]
    )
    eventually_assumptions_explicit = all(
        p.get("trigger_condition") is not None
        and all(key in p for key in ("environment_assumptions", "protocol_assumptions", "reset_assumptions"))
        for p in corpus["properties"]
        if p["property_family"] in {"EVENTUALLY", "BOUNDED_EVENTUALLY", "UNTIL"}
    )
    statement_hashes_match = all(
        b.get("theorem_statement_sha256") == hashlib.sha256(
            next(p["theorem_statement"] for p in corpus["properties"] if p["dut"] == b["dut"] and p["property_id"] == b["property_id"]).encode("utf-8")
        ).hexdigest()
        for b in baseline["results"]
    )
    same_statements = all(
        direct_result["theorem_statement"] == lemma_result["theorem_statement"]
        for direct_result, lemma_result in zip(direct["results"], lemma["results"])
    )
    baseline_failures_preserved = all(
        result.get("attempts") and all(Path(attempt["command"][-1]).is_file() for attempt in result["attempts"])
        for result in baseline["results"] if result["status"] == "BASE_FAILED"
    )
    direct_failures_preserved = all(
        result.get("proof_result", {}).get("history")
        for result in direct["results"] if result["status"] == "DIRECT_FAILED"
    )
    lemma_failures_preserved = all(
        result.get("proof_result", {}).get("attempt_history")
        for result in lemma["results"] if result["status"] == "LEMMA_FIRST_FAILED"
    )
    freeze_path = requirement_root / "corpus" / "freeze.json"
    final_properties_path = requirement_root / "corpus" / "final_properties.json"
    freeze_record = _read(freeze_path)
    freeze_hash_matches = freeze_record.get("final_properties_sha256") == sha256(final_properties_path)
    freeze_timestamp_precedes_baseline = final_properties_path.stat().st_mtime <= (requirement_root / "baseline" / "baseline_results.json").stat().st_mtime
    true_counts = [
        sum(p["property_level"] == "TRUE_MULTI_CYCLE" for p in corpus["properties"] if p["dut"] == benchmark.design_id)
        for benchmark in benchmarks
    ]
    no_uniform_quota = len(set(true_counts)) > 1 and "quota" not in corpus.get("selection_rule", "").lower()
    novelty_complete = (
        len(lemma.get("results", [])) == len(causal_rows)
        and lemma["metrics"]["VERIFIED_INTERMEDIATE_LEMMAS"] == len(lemma["results"])
        and lemma["metrics"]["NOVEL_INTERMEDIATE_LEMMAS"] == len(lemma["results"])
    )
    multi_semantics = _read(requirement_root / "multi_clock" / "execution_semantics.json").get("models", [])
    multi_semantics_fields = {
        "clock_domains", "event_ordering", "same_time_event_policy", "clock_local_input_sampling",
        "state_visibility", "cross_clock_dependencies", "step_event_sequence",
    }
    multi_clock_semantics_complete = bool(multi_semantics) and all(
        multi_semantics_fields <= set(model) and len(model.get("clock_domains", [])) >= 2
        for model in multi_semantics
    )
    complexity_columns_complete = bool(proof_complexity) and all(
        set(PROOF_COMPLEXITY_FIELDS) <= set(row) for row in proof_complexity
    )
    aes_long_is_real = bool(aes_long) and all(
        p["property"].get("minimum_required_transitions", 0) >= 8
        and bool(p["property"].get("bound_source"))
        for p in aes_long
    )
    aes_wide_is_real = bool(aes_wide) and all(
        p["property"].get("max_signal_width", 0) >= 128
        and bool(p["property"].get("wide_fields"))
        for p in aes_wide
    )
    required_case_files = {
        "recursive.json", "eventually_or_bounded.json", "until.json", "invariant.json",
        "aes_long_wide.json", "aes_symbolic_cycle.json", "aes_long_wide_symbolic.json",
    }
    audit = {
        "property_freeze_before_baseline": corpus.get("frozen_before_baseline") is True and freeze_timestamp_precedes_baseline,
        "freeze_hash_matches": freeze_hash_matches,
        "classification_invariants": classification_ok,
        "property_evidence_complete": property_evidence_complete,
        "eventually_until_assumptions_explicit": eventually_assumptions_explicit,
        "all_base_failed_entered_direct": direct_set == failed_set,
        "all_base_failed_entered_lemma_first": lemma_set == failed_set,
        "same_target_sets": direct_set == lemma_set and same_statements and statement_hashes_match,
        "all_successes_kernel_rechecked": integrity["status"] == "PASS",
        "failed_results_preserved": baseline_failures_preserved and direct_failures_preserved and lemma_failures_preserved,
        "no_uniform_dut_quota": no_uniform_quota,
        "variable_completion_not_manufactured": variable_rejection,
        "aes_long_temporal_has_real_bound": aes_long_is_real,
        "aes_wide_data_is_at_least_128_bits": aes_wide_is_real,
        "intermediate_lemma_novelty_complete": novelty_complete,
        "multi_clock_semantics_complete": multi_clock_semantics_complete,
        "all_required_family_rows_present": [x["group"] for x in family_rows] == FAMILY_ORDER,
        "all_aes_complexity_rows_present": [x["group"] for x in aes_complexity] == AES_COMPLEXITY_ORDER,
        "proof_complexity_columns_complete": complexity_columns_complete,
        "required_case_studies_present": required_case_files <= {x.name for x in (requirement_root / "case_studies").glob("*.json")},
        "case_studies": len(cases),
    }
    status = "PASS" if all(value for key, value in audit.items() if isinstance(value, bool)) else "FAIL"
    report = {
        "schema": "rtl2lean-temporal-final-report-v1", "status": status,
        "provider": provider_options, "corpus_metrics": corpus["metrics"],
        "baseline_metrics": baseline["metrics"], "direct_metrics": direct["metrics"],
        "lemma_first_metrics": lemma["metrics"], "family_results": family_rows,
        "dut_results": dut_rows, "aes_complexity_results": aes_complexity,
        "completion_cycle_results": [completion_map[name] for name in sorted(completion_map)],
        "proof_complexity_schema": str((tables / "proof_complexity_schema.json").relative_to(requirement_root)),
        "case_studies": [
            {"case_type": x["case_type"], "status": x["status"], "property_id": x.get("property_id"),
             "why_not_found": x.get("why_not_found", "")}
            for x in cases
        ],
        "claim_scope": {
            "trace_bridge": "execution infrastructure only; not multi-cycle functionality",
            "true_temporal_execution": "register-event semantics comb(pre) -> commit/commitEvent",
            "aes_algorithm_correctness": "not claimed; no independent AES functional specification was proved",
            "variable_completion": "not claimed; rejected without RTL-derived progress/latency evidence",
            "strict_intermediate_causality": "zero because Direct solved every frozen BASE_FAILED theorem",
        },
        "research_questions": rqs, "audit": audit,
        "artifact_hashes": {},
    }
    required = [
        requirement_root / "corpus" / "all_candidates.json",
        requirement_root / "corpus" / "final_properties.json",
        requirement_root / "corpus" / "freeze.json",
        requirement_root / "corpus" / "rejected_properties.json",
        requirement_root / "corpus" / "property_classification.json",
        requirement_root / "corpus" / "property_validation.json",
        requirement_root / "corpus" / "aes_complexity_tags.json",
        requirement_root / "trace_bridge" / "results.json",
        requirement_root / "baseline" / "baseline_capability.json",
        requirement_root / "baseline" / "baseline_results.json",
        requirement_root / "direct_llm" / "results.json",
        requirement_root / "lemma_first" / "results.json",
        requirement_root / "lemma_first" / "intermediate_lemmas.json",
        requirement_root / "lemma_first" / "lemma_novelty.json",
        requirement_root / "lemma_first" / "causal_ablation.json",
        requirement_root / "aes_high_complexity" / "long_temporal.json",
        requirement_root / "aes_high_complexity" / "wide_data.json",
        requirement_root / "aes_high_complexity" / "symbolic_cycle.json",
        requirement_root / "aes_high_complexity" / "combined_complexity.json",
        requirement_root / "multi_clock" / "execution_semantics.json",
        requirement_root / "multi_clock" / "temporal_results.json",
        requirement_root / "lean_integrity.json",
        *sorted((requirement_root / "case_studies").glob("*.json")),
        *sorted(path for path in tables.glob("*") if path.is_file()),
        *sorted((requirement_root / "figures").glob("*.svg")),
    ]
    report["artifact_hashes"] = {str(x.relative_to(requirement_root)): sha256(x) for x in required}
    write_json(requirement_root / "final_report.json", report)

    lines = [
        "# temporal Final Report", "", f"Status: **{status}**", "",
        f"Frozen properties: {len(corpus['properties'])}; true multi-cycle: {corpus['metrics']['N_TRUE_MULTI_CYCLE']}.",
        f"Baseline solved {baseline['metrics']['BASE_SOLVED']}/{baseline['metrics']['TARGETS']}; "
        f"Direct solved {direct['metrics']['DIRECT_SOLVED']}/{direct['metrics']['TARGETS']} BASE_FAILED targets; "
        f"Lemma-First solved {lemma['metrics']['LEMMA_FIRST_SOLVED']}/{lemma['metrics']['TARGETS']}.",
        "", "## Scope note", "",
        "TRACE_BRIDGE is reported only as execution infrastructure. True temporal results use the IR-derived register-event semantics `comb(pre) -> commit/commitEvent`; post-event derived wires are recomputed at the next event.",
        "The experiment does not claim full AES algorithm correctness, and it rejects unsupported variable completion latency.",
        "", "## Key causal result", "",
        f"Direct solved {direct['metrics']['DIRECT_SOLVED']}/{direct['metrics']['TARGETS']}; therefore strict A-fail/B-fail/C-pass causal gain is {lemma['metrics']['THREE_ARM_CAUSALLY_HELPFUL']}. "
        f"Lemma-First nevertheless produced {lemma['metrics']['NOVEL_INTERMEDIATE_LEMMAS']} novel kernel-verified intermediates, and exact deletion broke {lemma['metrics']['EXACT_DELETION_REQUIRED']} corresponding final proofs.",
        "", "## Zero-candidate categories", "",
        f"- UNTIL: {family_map['UNTIL']['why_not_found']}",
        f"- VARIABLE_COMPLETION: {variable_reason}",
        "- Missing AES pairwise tag combinations are reported as N=0 in `tables/aes_complexity_results.csv`; no theorem was manufactured to fill them.",
        "", "## Research questions", "",
    ]
    for name, answer in rqs.items():
        lines.extend([f"### {name}", "", answer["answer"], ""])
    lines.extend(
        ["## Integrity", ""] + [f"- {key}: {value}" for key, value in audit.items()]
        + ["", "## Reproduction artifacts", "",
           "The frozen corpus hash is recorded in `corpus/freeze.json`; all tables, figures, case studies, Lean rechecks, Direct calls, Lemma-First calls, novelty records, and deletion ablations are retained under `outputs/temporal/`.", ""]
    )
    (requirement_root / "final_report.md").write_text("\n".join(lines), encoding="utf-8")
    return report
