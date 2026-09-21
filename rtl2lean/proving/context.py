"""Dependency-based context selection for large generated Lean models."""
from __future__ import annotations

import re
from dataclasses import asdict
from pathlib import Path

from rtl2lean.pipeline.io import write_json
from rtl2lean.pipeline.schema import DesignIR
from rtl2lean.theorems.generator import GeneratedTheorem


def _definition_snippet(source: str, name: str, limit: int = 180) -> str | None:
    lines = source.splitlines()
    pattern = re.compile(rf"^\s*(?:private\s+)?(?:def|inductive|structure)\s+{re.escape(name)}\b")
    start = next((index for index, line in enumerate(lines) if pattern.search(line)), None)
    if start is None:
        return None
    end = min(len(lines), start + limit)
    for index in range(start + 1, end):
        if re.match(r"^\s*(?:private\s+)?(?:def|inductive|structure)\s+[A-Za-z_]", lines[index]):
            end = index
            break
    return "\n".join(lines[start:end]).strip()


def select_context(
    target: GeneratedTheorem,
    typed: DesignIR,
    model_path: Path,
    prior_lemmas: list[dict],
    artifact_path: Path,
) -> dict:
    model = model_path.read_text(encoding="utf-8")
    required_functions = set(target.source_functions)
    required_fields = set(target.state_fields)
    required_inputs = set(target.input_fields)

    # Expand one read/write dependency hop from target fields and functions.
    changed = True
    while changed:
        changed = False
        for process in typed.module.processes:
            if process.name in required_functions or set(process.write_set) & required_fields:
                before = (len(required_functions), len(required_fields), len(required_inputs))
                required_functions.add(process.name)
                required_fields.update(name for name in process.read_set if name not in required_inputs)
                required_fields.update(process.write_set)
                required_inputs.update(name for name in process.read_set
                                       if any(signal.name == name and signal.direction == "input"
                                              for signal in typed.module.signals))
                changed |= before != (len(required_functions), len(required_fields), len(required_inputs))
        # One closure iteration is sufficient to avoid unbounded full-model expansion.
        break

    structural = [f"structure {typed.top_module}State", f"structure {typed.top_module}Inputs"]
    snippets = []
    for function in sorted(required_functions | {"step", "commit", "commitEvent", "run", "Reachable"}):
        snippet = _definition_snippet(model, function)
        if snippet:
            snippets.append(snippet)
    relevant_lemmas = []
    target_tokens = set(re.findall(r"[A-Za-z_][A-Za-z0-9_]*", target.statement))
    for lemma in prior_lemmas:
        lemma_tokens = set(re.findall(r"[A-Za-z_][A-Za-z0-9_]*", lemma["statement"]))
        score = len(target_tokens & lemma_tokens)
        if score or set(lemma.get("state_fields", ())) & required_fields:
            relevant_lemmas.append({**lemma, "relevance_score": score})
    relevant_lemmas.sort(key=lambda item: (-item["relevance_score"], item["name"]))
    payload = {
        "schema": "rtl2lean-context-selection-v1",
        "target": asdict(target),
        "required_functions": sorted(required_functions),
        "required_state_fields": sorted(required_fields),
        "required_input_fields": sorted(required_inputs),
        "model_snippets": snippets,
        "retrieved_lemmas": relevant_lemmas[:8],
        "full_model_included": False,
        "selected_model_characters": sum(len(snippet) for snippet in snippets),
        "full_model_characters": len(model),
    }
    write_json(artifact_path, payload)
    return payload
