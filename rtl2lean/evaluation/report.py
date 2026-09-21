"""Artifact-only paper tables, figures, integrity audit and RQ5--RQ13."""
from __future__ import annotations

import csv
import hashlib
import json
import math
import re
import subprocess
from pathlib import Path
from typing import Any, Iterable

from rtl2lean.pipeline.compiler import find_lean
from rtl2lean.pipeline.io import sha256, write_json
from rtl2lean.pipeline.manifest import Benchmark, DEFAULT_MANIFEST


FORBIDDEN = re.compile(r"\b(?:sorry|admit|native_decide|unsafe)\b|^\s*axiom\b", re.MULTILINE)


def _text_hash(value: str) -> str:
    return hashlib.sha256(value.encode()).hexdigest()


def _read(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8")) if path.is_file() else {}


def _csv(path: Path, rows: list[dict[str, Any]], fields: list[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as stream:
        writer = csv.DictWriter(stream, fieldnames=fields)
        writer.writeheader()
        writer.writerows({field: row.get(field) for field in fields} for row in rows)


def _svg_bars(path: Path, title: str, labels: list[str], series: list[tuple[str, list[float], str]],
              ylabel: str) -> None:
    width, height = 920, 520
    left, top, plot_w, plot_h = 90, 60, 790, 370
    maximum = max([value for _, values, _ in series for value in values] or [1]) or 1
    group_w = plot_w / max(1, len(labels))
    bar_w = min(34, group_w / max(1, len(series) + 1))
    items = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}">',
             '<rect width="100%" height="100%" fill="white"/>',
             f'<text x="{width/2}" y="30" text-anchor="middle" font-size="20">{title}</text>',
             f'<text x="20" y="{top+plot_h/2}" transform="rotate(-90 20 {top+plot_h/2})" text-anchor="middle">{ylabel}</text>',
             f'<line x1="{left}" y1="{top}" x2="{left}" y2="{top+plot_h}" stroke="black"/>',
             f'<line x1="{left}" y1="{top+plot_h}" x2="{left+plot_w}" y2="{top+plot_h}" stroke="black"/>']
    for tick in range(6):
        value = maximum * tick / 5
        y = top + plot_h - plot_h * tick / 5
        items.extend([f'<line x1="{left}" y1="{y:.1f}" x2="{left+plot_w}" y2="{y:.1f}" stroke="#ddd"/>',
                      f'<text x="{left-8}" y="{y+4:.1f}" text-anchor="end" font-size="11">{value:.2g}</text>'])
    for index, label in enumerate(labels):
        center = left + group_w * (index + .5)
        items.append(f'<text x="{center:.1f}" y="{top+plot_h+25}" text-anchor="middle" font-size="12">{label}</text>')
        start = center - bar_w * len(series) / 2
        for offset, (name, values, color) in enumerate(series):
            value = values[index]
            h = plot_h * value / maximum
            x, y = start + offset * bar_w, top + plot_h - h
            items.append(f'<rect x="{x:.1f}" y="{y:.1f}" width="{bar_w-3:.1f}" height="{h:.1f}" fill="{color}"/>')
    legend_x = left
    for name, _, color in series:
        items.extend([f'<rect x="{legend_x}" y="{height-38}" width="14" height="14" fill="{color}"/>',
                      f'<text x="{legend_x+20}" y="{height-26}" font-size="12">{name}</text>'])
        legend_x += 140
    items.append('</svg>')
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(items) + "\n", encoding="utf-8")


def _svg_scatter(path: Path, title: str, rows: list[dict[str, Any]], xkey: str, ykey: str) -> None:
    width, height = 800, 500
    left, top, plot_w, plot_h = 90, 60, 650, 350
    xmax = max(float(row[xkey]) for row in rows) or 1
    ymax = max(float(row[ykey]) for row in rows) or 1
    out = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}">',
           '<rect width="100%" height="100%" fill="white"/>',
           f'<text x="{width/2}" y="30" text-anchor="middle" font-size="20">{title}</text>',
           f'<line x1="{left}" y1="{top}" x2="{left}" y2="{top+plot_h}" stroke="black"/>',
           f'<line x1="{left}" y1="{top+plot_h}" x2="{left+plot_w}" y2="{top+plot_h}" stroke="black"/>']
    for row in rows:
        x = left + plot_w * float(row[xkey]) / xmax
        y = top + plot_h - plot_h * float(row[ykey]) / ymax
        out.extend([f'<circle cx="{x:.1f}" cy="{y:.1f}" r="6" fill="#2563eb"/>',
                    f'<text x="{x+8:.1f}" y="{y-8:.1f}" font-size="12">{row["Design"]}</text>'])
    out.extend([f'<text x="{left+plot_w/2}" y="{height-30}" text-anchor="middle">{xkey}</text>',
                f'<text x="20" y="{top+plot_h/2}" transform="rotate(-90 20 {top+plot_h/2})" text-anchor="middle">{ykey}</text>',
                '</svg>'])
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(out) + "\n", encoding="utf-8")


def _pearson(xs: list[float], ys: list[float]) -> float | None:
    if len(xs) < 2:
        return None
    mx, my = sum(xs) / len(xs), sum(ys) / len(ys)
    numerator = sum((x - mx) * (y - my) for x, y in zip(xs, ys))
    dx = math.sqrt(sum((x - mx) ** 2 for x in xs))
    dy = math.sqrt(sum((y - my) ** 2 for y in ys))
    return numerator / (dx * dy) if dx and dy else None


def _configuration_by_dut(config: dict[str, Any], dut: str) -> dict[str, Any]:
    rows = [item for item in config["results"] if item["dut"] == dut]
    return {
        "solved": sum(item["status"] == "PASS" for item in rows),
        "llm_calls": sum(item["llm_calls"] for item in rows),
        "proof_time_s": sum(item["proof_time_s"] for item in rows),
        "lean_time_s": sum(item["lean_time_s"] for item in rows),
    }


def build_fingerprint(
    benchmarks: list[Benchmark], corpus_path: Path, output_root: Path,
    requirement_root: Path, configs: list[dict[str, Any]], provider_options: dict[str, Any],
    ablations: list[dict[str, Any]],
) -> dict[str, Any]:
    lean_version = subprocess.run([find_lean(), "--version"], capture_output=True, text=True, check=True).stdout.strip()
    run_signatures = []
    for config in configs:
        intermediate_records = []
        target_outcomes = []
        reuse_records = []
        for item in config["results"]:
            proof_result = item.get("proof_result", {})
            target_outcomes.append((
                item["dut"], item["property_id"], item["status"], item["llm_calls"],
                item["repair_rounds"], item["new_lemmas"],
                _text_hash(item.get("proof") or ""),
            ))
            for event in proof_result.get("attempt_history", []):
                candidate = event.get("candidate")
                if (event.get("event") == "CANDIDATE_ACCEPTED" and candidate
                        and candidate["lemma_name"] in item.get("verified_intermediate_lemmas", [])):
                    intermediate_records.append((
                        item["dut"], item["property_id"], candidate["lemma_name"],
                        _text_hash(candidate["lemma_statement"]), _text_hash(candidate["proof_body"]),
                    ))
            reuse_records.extend((
                item["dut"], event["source_target"], event["lemma"], item["property_id"],
                event["causally_necessary"],
            ) for event in item.get("actual_reuse", []))
        signature = {
            "name": config["name"], "order_rule": config["order_rule"],
            "property_status": [(item["dut"], item["property_id"], item["status"])
                                for item in config["results"]],
            "verified_intermediate_lemmas": sorted(intermediate_records),
            "target_outcomes": sorted(target_outcomes),
            "causal_intermediate": sum(item.get("causally_used_intermediate_lemmas", 0)
                                       for item in config["results"]),
            "actual_reuse": sorted(reuse_records),
            "outcome_metrics": {
                "solved": config["metrics"]["solved"],
                "llm_calls": config["metrics"]["llm_calls"],
                "repair_rounds": config["metrics"]["repair_rounds"],
                "new_lemmas": config["metrics"]["new_lemmas"],
            },
            "metrics": config["metrics"],
        }
        run_signatures.append(signature)
    repeated = [item for item in run_signatures if item["name"] in {"official_run1", "official_run2"}]
    stable = False
    comparisons: dict[str, Any] = {}
    if len(repeated) == 2:
        fields = ("property_status", "target_outcomes", "verified_intermediate_lemmas", "causal_intermediate",
                  "actual_reuse", "outcome_metrics")
        comparisons = {field: repeated[0][field] == repeated[1][field] for field in fields}
        if len(ablations) == 2:
            def ablation_signature(payload: dict[str, Any]) -> list[tuple[Any, ...]]:
                return sorted((row["dut"], row["target"], row["baseline"],
                               row["llm_no_intermediate"], row["llm_with_intermediate"],
                               row["remove_lemma"], row.get("restore_lemma"),
                               row.get("intermediate_lemma_causally_helpful_three_arm"),
                               row.get("exact_successful_proof_lemma_causally_required"))
                              for row in payload["rows"])
            comparisons["causal_ablation"] = (
                ablation_signature(ablations[0]) == ablation_signature(ablations[1])
            )
        stable = all(comparisons.values())
    payload = {
        "schema": "rtl2lean-evaluation-experiment-fingerprint-v1",
        "lean_version": lean_version, "llm_configuration": provider_options,
        "llm_budget": {"max_generation_rounds": 3, "max_repair_rounds_per_candidate": 2,
                       "max_intermediate_lemmas": 4, "max_llm_calls": 10},
        "retrieval_configuration": "DUT-local token/state-type/property-family rank, top 8",
        "property_orders": {item["name"]: item["order_rule"] for item in configs},
        "initial_pool": {
            "policy": "empty property pool; frozen L1-L4 imported through R2Framework",
            "framework_sha256": {benchmark.design_id: sha256(
                output_root / benchmark.slug / "model" / "R2Framework.lean") for benchmark in benchmarks},
        },
        "benchmark_config_sha256": sha256(DEFAULT_MANIFEST),
        "property_corpus_sha256": sha256(corpus_path),
        "baseline_results_sha256": sha256(requirement_root / "baseline" / "baseline_results.json"),
        "selected_targets_sha256": sha256(requirement_root / "baseline" / "selected_targets.json"),
        "property_ids": [(item["dut"], item["property_id"])
                         for item in _read(corpus_path).get("properties", [])],
        "implementation_sha256": {
            str(path.relative_to(Path(__file__).resolve().parents[2])): sha256(path)
            for path in sorted((Path(__file__).resolve().parents[1]).rglob("*.py"))
        },
        "rtl": {benchmark.design_id: {"commit": benchmark.commit,
                "source_sha256": {str(path): sha256(path) for path in benchmark.source_files}}
                for benchmark in benchmarks},
        "lean_models": {benchmark.design_id: {
            name: sha256(output_root / benchmark.slug / "model" / name)
            for name in ("Model.lean", "Foundation.lean", "Framework.lean", "R2Framework.lean")
        } for benchmark in benchmarks},
        "run_signatures": run_signatures,
        "reproducibility": {"stable": stable, "comparisons": comparisons},
    }
    write_json(requirement_root / "reproducibility" / "experiment_fingerprint.json", payload)
    return payload


def build_paper_report(
    benchmarks: list[Benchmark], corpus: dict[str, Any], baseline: dict[str, Any],
    official: dict[str, Any], run2: dict[str, Any], fresh: dict[str, Any],
    order_configs: list[dict[str, Any]], ablation: dict[str, Any],
    ablation_run2: dict[str, Any], reuse: dict[str, Any],
    translation: dict[str, Any], bundle_checks: list[dict[str, Any]],
    output_root: Path, requirement_root: Path, provider_options: dict[str, Any],
) -> dict[str, Any]:
    tables = requirement_root / "tables"
    figures = requirement_root / "figures"
    baseline_map = {(item["dut"], item["property_id"]): item for item in baseline["results"]}
    timing_map = {item["dut"]: item for item in translation["rows"]}
    table1, table2, table3, table5, table6, table7 = [], [], [], [], [], []
    reuse_events = official["retrieval_events"]
    for benchmark in benchmarks:
        design = _read(output_root / benchmark.slug / "analysis" / "design.json")
        typed = _read(output_root / benchmark.slug / "ir" / "design.json")
        targets = _read(output_root / benchmark.slug / "model" / "targets.json")["targets"]
        stage1 = _read(output_root / benchmark.slug / "stage1.json")
        stage2 = _read(output_root / benchmark.slug / "stage2.json")
        properties = [item for item in corpus["properties"] if item["dut"] == benchmark.design_id]
        base = [item for item in baseline["results"] if item["dut"] == benchmark.design_id]
        # Fresh-pool is the controlled LLM arm: identical empty initial pool
        # for every property.  `official` remains the shared-pool reuse arm.
        assisted = [item for item in fresh["results"] if item["dut"] == benchmark.design_id]
        foundational = [item for item in targets if item["layer"] in {"L1", "L2", "L3", "L4"}]
        nlemma, nproperty = len(foundational), len(properties)
        nreusable = sum(item.get("reusable", True) for item in foundational)
        nproved = nlemma + sum(item["status"] == "PASS" for item in assisted)
        table1.append({"Design": benchmark.design_id, "RTL_LOC": design["rtl_loc"]["physical"],
                       "Modules": design["module_count"],
                       "State_Registers": sum(item.get("kind") in {"state", "state_output"}
                                              for item in typed["module"]["signals"]),
                       "Clock_Domains": len(typed["module"]["clock_domains"]),
                       "High_Level_Properties": nproperty})
        table2.append({"Design": benchmark.design_id, "Nproperty": nproperty, "Nlemma": nlemma,
                       "Nreusable": nreusable, "Ntotal": nproperty + nlemma,
                       "Nproved": nproved, "Rproof": nproved / (nproperty + nlemma),
                       "Rreuse": nreusable / nlemma if nlemma else 0.0})
        table3.append({"Design": benchmark.design_id, "Targets": nproperty,
                       "BASE_SOLVED": sum(item["status"] == "BASE_SOLVED" for item in base),
                       "BASE_FAILED": sum(item["status"] == "BASE_FAILED" for item in base),
                       "LLM_TRIGGERED": sum(item["method"] == "LLM_WITH_INTERMEDIATE" for item in assisted),
                       "LLM_SOLVED": sum(item["method"] == "LLM_WITH_INTERMEDIATE" and item["status"] == "PASS"
                                         for item in assisted),
                       "LLM_UNSOLVED": sum(item["method"] == "LLM_WITH_INTERMEDIATE" and item["status"] != "PASS"
                                           for item in assisted),
                       "Verified_Intermediate_Lemmas": sum(item.get("new_lemmas", 0) for item in assisted)})
        relevant_retrieval = [item for item in reuse_events if item["dut"] == benchmark.design_id]
        relevant_used = [item for item in reuse["used"] if item["dut"] == benchmark.design_id]
        relevant_causal = [item for item in reuse["causal"] if item["dut"] == benchmark.design_id
                           and item["causally_required"]]
        available = sum(item["available"] for item in relevant_retrieval)
        retrieved = sum(len(item["retrieved"]) for item in relevant_retrieval)
        table5.append({"Design": benchmark.design_id, "Available": available,
                       "Retrieved": retrieved, "Actually_Used": len(relevant_used),
                       "Causally_Required": len(relevant_causal),
                       "Causal_Reuse_Rate": len(relevant_causal) / len(relevant_used) if relevant_used else 0.0})
        model_lean = _read(output_root / benchmark.slug / "model" / "lean_check.json").get("elapsed_s", 0.0)
        stage2_lean = sum(stage2.get(key, {}).get("elapsed_s", 0.0) for key in ("lean_kernel", "framework_kernel"))
        property_lean = sum(item.get("lean_time_s", 0.0) for item in assisted
                            if item["method"] == "LLM_WITH_INTERMEDIATE")
        tlean = model_lean + stage2_lean + sum(item["proof_time_s"] for item in base) + property_lean
        tllm = sum(item.get("llm_time_s", 0.0) for item in assisted)
        timing = timing_map[benchmark.design_id]
        te2e = (design.get("elapsed_s", 0.0) + timing["Ttranslation"] + model_lean
                + stage2.get("theorem_generation_elapsed_s", 0.0)
                + sum(item["proof_time_s"] for item in base)
                + sum(item["proof_time_s"] for item in assisted
                      if item["method"] == "LLM_WITH_INTERMEDIATE"))
        table6.append({"Design": benchmark.design_id, "Ntotal": nproperty + nlemma,
                       "Tanalysis": design.get("elapsed_s", 0.0), "Tfrontend": timing["Tfrontend"],
                       "Tir": timing["Tir"], "Translation": timing["Ttranslation"],
                       "Tlean_generation": timing["Tlean_generation"],
                       "Theorem_Gen": stage2.get("theorem_generation_elapsed_s", 0.0),
                       "Baseline": sum(item["proof_time_s"] for item in base), "LLM": tllm,
                       "Tlemma_retrieval": sum(item["retrieval_time_s"] for item in relevant_retrieval),
                       "TLean": tlean, "Te2e": te2e})
        fresh_dut, shared_dut = _configuration_by_dut(fresh, benchmark.design_id), _configuration_by_dut(official, benchmark.design_id)
        table7.append({"Design": benchmark.design_id, "Fresh_Solved": fresh_dut["solved"],
                       "Shared_Solved": shared_dut["solved"], "Fresh_LLM_Calls": fresh_dut["llm_calls"],
                       "Shared_LLM_Calls": shared_dut["llm_calls"], "Fresh_Time": fresh_dut["proof_time_s"],
                       "Shared_Time": shared_dut["proof_time_s"]})

    total2 = {"Design": "Total"}
    for field in ("Nproperty", "Nlemma", "Nreusable", "Ntotal", "Nproved"):
        total2[field] = sum(row[field] for row in table2)
    total2["Rproof"] = total2["Nproved"] / total2["Ntotal"]
    total2["Rreuse"] = total2["Nreusable"] / total2["Nlemma"]
    table2_total = table2 + [total2]
    total6 = {"Design": "Total"}
    for field in table6[0]:
        if field != "Design":
            total6[field] = sum(float(row[field]) for row in table6)
    table6_total = table6 + [total6]

    _csv(tables / "benchmark_characteristics.csv", table1, list(table1[0]))
    _csv(tables / "proof_results.csv", table2_total, list(table2_total[0]))
    _csv(tables / "baseline_vs_llm.csv", table3, list(table3[0]))
    ablation_rows = [{"DUT": row["dut"], "Target": row["target"], "Baseline": row["baseline"],
                      "LLM_No_Intermediate": row["llm_no_intermediate"],
                      "LLM_With_Intermediate": row["llm_with_intermediate"],
                      "Remove_Lemma": row["remove_lemma"], "Restore_Lemma": row.get("restore_lemma"),
                      "Three_Arm_Causal": row.get("intermediate_lemma_causally_helpful_three_arm"),
                      "Exact_Proof_Causal": row.get("exact_successful_proof_lemma_causally_required")}
                     for row in ablation["rows"]]
    _csv(tables / "lemma_ablation.csv", ablation_rows, list(ablation_rows[0]) if ablation_rows else
         ["DUT", "Target", "Baseline", "LLM_No_Intermediate", "LLM_With_Intermediate",
          "Remove_Lemma", "Restore_Lemma", "Three_Arm_Causal", "Exact_Proof_Causal"])
    _csv(tables / "reuse_results.csv", table5, list(table5[0]))
    _csv(tables / "runtime.csv", table6_total, list(table6_total[0]))
    _csv(tables / "fresh_vs_shared.csv", table7, list(table7[0]))

    labels = [benchmark.slug for benchmark in benchmarks]
    _svg_bars(figures / "baseline_vs_llm.svg", "Baseline vs LLM proof success", labels,
              [("Baseline", [row["BASE_SOLVED"] / row["Targets"] for row in table3], "#64748b"),
               ("LLM-Assisted", [(row["BASE_SOLVED"] + row["LLM_SOLVED"]) / row["Targets"] for row in table3], "#2563eb")],
              "success rate")
    layer_values = {layer: [] for layer in ("L1", "L2", "L3", "L4", "Property")}
    for benchmark in benchmarks:
        targets = _read(output_root / benchmark.slug / "model" / "targets.json")["targets"]
        for layer in ("L1", "L2", "L3", "L4"):
            layer_values[layer].append(sum(item["layer"] == layer for item in targets))
        layer_values["Property"].append(sum(item["dut"] == benchmark.design_id for item in corpus["properties"]))
    colors = ["#1d4ed8", "#0891b2", "#059669", "#65a30d", "#d97706"]
    _svg_bars(figures / "theorem_composition.svg", "Theorem composition", labels,
              [(layer, layer_values[layer], colors[index]) for index, layer in enumerate(layer_values)], "theorems")
    _svg_bars(figures / "reuse_funnel.svg", "Lemma reuse funnel", labels,
              [("Available", [row["Available"] for row in table5], "#94a3b8"),
               ("Retrieved", [row["Retrieved"] for row in table5], "#60a5fa"),
               ("Used", [row["Actually_Used"] for row in table5], "#34d399"),
               ("Causal", [row["Causally_Required"] for row in table5], "#f97316")], "events")
    _svg_scatter(figures / "lean_time_vs_theorem_count.svg", "Lean time vs theorem count", table6, "Ntotal", "TLean")
    _svg_bars(figures / "fresh_vs_shared.svg", "Fresh pool vs shared pool", labels,
              [("Fresh solved", [row["Fresh_Solved"] for row in table7], "#64748b"),
               ("Shared solved", [row["Shared_Solved"] for row in table7], "#2563eb"),
               ("Fresh calls", [row["Fresh_LLM_Calls"] for row in table7], "#f59e0b"),
               ("Shared calls", [row["Shared_LLM_Calls"] for row in table7], "#10b981")], "count")
    related = reuse["relatedness"]
    _svg_bars(figures / "relatedness_reuse.svg", "Semantic relatedness vs reuse", [row["category"] for row in related],
              [("Retrieval rate", [row["retrieval_rate"] for row in related], "#60a5fa"),
               ("Actual use rate", [row["actual_use_rate"] for row in related], "#34d399"),
               ("Causal rate", [row["causal_reuse_rate"] for row in related], "#f97316")], "rate")

    fingerprint = build_fingerprint(
        benchmarks, requirement_root / "corpus" / "property_corpus.json", output_root,
        requirement_root, [fresh, run2, *order_configs], provider_options,
        [ablation, ablation_run2],
    )
    all_lean = list(requirement_root.rglob("*.lean"))
    forbidden = [{"file": str(path), "matches": FORBIDDEN.findall(path.read_text(encoding="utf-8"))}
                 for path in all_lean if FORBIDDEN.search(path.read_text(encoding="utf-8"))]
    expected_shared = {
        (configuration["name"], benchmark.design_id, None)
        for configuration in order_configs for benchmark in benchmarks
    }
    expected_fresh = {
        (configuration["name"], item["dut"], item["property_id"])
        for configuration in (fresh, run2) for item in configuration["results"]
        if item["method"] == "LLM_WITH_INTERMEDIATE" and item["status"] == "PASS"
    }
    actual_checks = {
        (item["configuration"], item["dut"], item.get("property_id"))
        for item in bundle_checks
    }
    expected_checks = expected_shared | expected_fresh
    missing_checks = sorted(expected_checks - actual_checks,
                            key=lambda item: tuple("" if value is None else value for value in item))
    baseline_consistent = all(
        (item["status"] == "BASE_SOLVED") == any(attempt["success"] for attempt in item["attempts"])
        for item in baseline["results"]
    )
    configuration_consistent = all(
        (result["status"] == "PASS") == (
            result["method"] == "BASELINE"
            or bool(result.get("proof_result", {}).get("target_kernel_pass"))
        )
        for configuration in (fresh, run2, *order_configs)
        for result in configuration["results"]
    )
    integrity = {
        "formal_lean_files": len(all_lean), "forbidden_findings": forbidden,
        "bundle_checks": bundle_checks,
        "expected_bundle_checks": len(expected_checks),
        "missing_bundle_checks": missing_checks,
        "baseline_artifact_consistent": baseline_consistent,
        "configuration_artifact_consistent": configuration_consistent,
        "all_official_bundles_kernel_accepted": not missing_checks
                                                and all(item["success"] for item in bundle_checks),
    }
    write_json(requirement_root / "lean_integrity.json", integrity)
    base_total = sum(row["BASE_SOLVED"] for row in table3)
    assisted_total = base_total + sum(row["LLM_SOLVED"] for row in table3)
    fresh_total = sum(row["Fresh_Solved"] for row in table7)
    shared_total = sum(row["Shared_Solved"] for row in table7)
    fresh_calls = sum(row["Fresh_LLM_Calls"] for row in table7)
    shared_calls = sum(row["Shared_LLM_Calls"] for row in table7)
    strict_causal = ablation["metrics"]["N_THREE_ARM_CAUSAL"]
    actual_reuse = reuse["metrics"]["REUSE_USED"]
    causal_reuse = reuse["metrics"]["REUSE_CAUSALLY_REQUIRED"]
    semantic_related = [row for row in related
                        if row["category"] in {"CORE_RELATED", "RELATED"}]
    control_unrelated = next((row for row in related
                              if row["category"] == "CONTROL_UNRELATED"), None)
    related_targets = sum(row["targets"] for row in semantic_related)
    related_causal = sum(row["causally_required"] for row in semantic_related)
    related_causal_target_rate = related_causal / related_targets if related_targets else 0.0
    unrelated_causal_target_rate = (
        control_unrelated["causally_required"] / control_unrelated["targets"]
        if control_unrelated and control_unrelated["targets"] else 0.0
    )
    rq = {
        "RQ5": {"answer": all(item["semantic_evidence_status"] == "PASS" and
                               "TRIVIAL" not in item["classification"] for item in corpus["properties"]),
                "meaningful_properties": len(corpus["properties"])},
        "RQ6": {"answer": assisted_total > base_total, "baseline_solved": base_total,
                "assisted_solved": assisted_total},
        "RQ7": {"answer": strict_causal > 0, "strict_three_arm_causal": strict_causal,
                "exact_proof_deletion_required": ablation["metrics"]["N_LEMMA_REQUIRED"]},
        "RQ8": {"answer": actual_reuse > 0, "actual_cross_property_use": actual_reuse},
        "RQ9": {"answer": causal_reuse > 0, "causal_cross_property_reuse": causal_reuse},
        "RQ10": {"answer": "INCONCLUSIVE" if actual_reuse == 0 else
                 related_causal_target_rate > unrelated_causal_target_rate,
                 "semantic_related_causal_target_rate": related_causal_target_rate,
                 "control_unrelated_causal_target_rate": unrelated_causal_target_rate,
                 "semantic_related_causal_events": related_causal,
                 "total_causal_events": causal_reuse,
                 "by_relatedness": related},
        "RQ11": {"answer": shared_total > fresh_total or shared_calls < fresh_calls,
                 "fresh_solved": fresh_total, "shared_solved": shared_total,
                 "fresh_llm_calls": fresh_calls, "shared_llm_calls": shared_calls},
        "RQ12": {"answer": "DESCRIPTIVE", "pearson_theorem_count_vs_lean_time":
                 _pearson([row["Ntotal"] for row in table6], [row["TLean"] for row in table6])},
        "RQ13": {"answer": fingerprint["reproducibility"]["stable"],
                 **fingerprint["reproducibility"]},
    }
    final_metrics = {
        **corpus["metrics"], "Nproperty": total2["Nproperty"], "Nlemma": total2["Nlemma"],
        "Nreusable": total2["Nreusable"], "Ntotal": total2["Ntotal"], "Nproved": total2["Nproved"],
        "Rproof": total2["Rproof"], "Rreuse": total2["Rreuse"],
        "BASE_SOLVED": base_total, "BASE_FAILED": sum(row["BASE_FAILED"] for row in table3),
        "LLM_TRIGGERED": sum(row["LLM_TRIGGERED"] for row in table3),
        "LLM_SOLVED": sum(row["LLM_SOLVED"] for row in table3),
        "LLM_UNSOLVED": sum(row["LLM_UNSOLVED"] for row in table3),
        "VERIFIED_INTERMEDIATE_LEMMAS": sum(row["Verified_Intermediate_Lemmas"] for row in table3),
        "LEMMA_CAUSALLY_REQUIRED": ablation["metrics"]["N_LEMMA_REQUIRED"],
        "LEMMA_NOT_REQUIRED": ablation["metrics"]["N_LEMMA_NOT_REQUIRED"],
        "LEMMA_CAUSAL_RATE": ablation["metrics"]["LEMMA_CAUSAL_RATE"],
        **reuse["metrics"], "FRESH_POOL_SOLVED": fresh_total, "SHARED_POOL_SOLVED": shared_total,
        "FRESH_POOL_LLM_CALLS": fresh_calls, "SHARED_POOL_LLM_CALLS": shared_calls,
        "TLean": total6["TLean"], "Te2e": total6["Te2e"],
    }
    report = {
        "schema": "rtl2lean-evaluation-final-audit-v1",
        "claim_scope": "Lean-kernel-checked generated model/property experiment; no RTL-to-Lean equivalence claim.",
        "status": "PASS" if (integrity["all_official_bundles_kernel_accepted"]
                              and integrity["baseline_artifact_consistent"]
                              and integrity["configuration_artifact_consistent"]
                              and not forbidden) else "FAIL",
        "metrics": final_metrics, "research_questions": rq,
        "tables": {"benchmark_characteristics": table1, "proof_results": table2_total,
                   "baseline_vs_llm": table3, "lemma_ablation": ablation_rows,
                   "reuse_results": table5, "runtime": table6_total,
                   "fresh_vs_shared": table7},
        "property_order_experiments": [{"name": item["name"], "order": item["order_rule"],
                                         "metrics": item["metrics"]} for item in order_configs],
        "integrity": integrity,
    }
    write_json(requirement_root / "final_audit_report.json", report)
    lines = ["# evaluation experimental integrity report", "", report["claim_scope"], "",
             f"Status: **{report['status']}**", "", "## Final metrics", "",
             "```json", json.dumps(final_metrics, ensure_ascii=False, indent=2), "```", "",
             "## Research questions", ""]
    for key, value in rq.items():
        lines.append(f"- {key}: **{value['answer']}** — `{json.dumps(value, ensure_ascii=False)}`")
    lines.extend(["", "## Generated paper artifacts", "",
                  "Seven CSV tables and six SVG figures under `tables/` and `figures/` are generated only from the frozen artifacts.", ""])
    (requirement_root / "final_audit_report.md").write_text("\n".join(lines), encoding="utf-8")
    return report
