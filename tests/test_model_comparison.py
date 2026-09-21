from __future__ import annotations

import json
from pathlib import Path

from rtl2lean.model_comparison.runner import (
    TARGET_TEMPLATE, _target_source, _validate_lemma_candidate,
)


PROJECT = Path(__file__).resolve().parents[1]
DIRECT = PROJECT / "outputs" / "model_calibration"
LEMMA_FIRST = PROJECT / "outputs" / "model_comparison"


def _read(path: Path):
    return json.loads(path.read_text())


def test_freeze_reuses_exact_direct_tasks_models_and_seeds() -> None:
    for name in ("tasks.json", "models.json", "seeds.json", "theorem_base.json"):
        direct = _read(DIRECT / "manifests" / name)
        lemma = _read(LEMMA_FIRST / "manifests" / name)
        direct.pop("schema", None); lemma.pop("schema", None)
        assert lemma == direct
    frozen = _read(LEMMA_FIRST / "calibration_manifest.json")
    assert frozen["frozen_before_model_calls"]
    assert frozen["expected_runs"] == 135


def test_lemma_first_prompts_are_paired_and_model_neutral() -> None:
    prompts = _read(LEMMA_FIRST / "manifests" / "prompts.json")["rows"]
    assert len(prompts) == 45
    assert len({(row["task_id"], row["trial_id"]) for row in prompts}) == 45
    assert all("stage 1 of Lemma-First" in row["prompt"] for row in prompts)
    assert all(row["lemma_name_prefix"].startswith("r10lf_") for row in prompts)
    assert all(not any(model in row["prompt"] for model in (
        "gpt-5.6-sol", "deepseek-v4-pro", "deepseek-v4-flash"
    )) for row in prompts)


def test_intermediate_must_be_distinct_safe_and_prefix_bound() -> None:
    task = {"statement": "True"}
    candidate = {
        "lemma_name": "r10lf_abc_helper", "lemma_statement": "1 = 1",
        "proof_body": "by rfl", "rationale": "helper",
    }
    assert _validate_lemma_candidate(candidate, task, "r10lf_abc_", None) is None
    assert "duplicates" in _validate_lemma_candidate(
        {**candidate, "lemma_statement": " True "}, task, "r10lf_abc_", None
    )
    assert "prefixed" in _validate_lemma_candidate(
        {**candidate, "lemma_name": "wrong"}, task, "r10lf_abc_", None
    )
    assert "forbidden" in _validate_lemma_candidate(
        {**candidate, "proof_body": "by sorry"}, task, "r10lf_abc_", None
    )


def test_target_source_contains_verified_lemma_before_target() -> None:
    task = {
        "context_import": "R5Foundation", "module": "demo",
        "task_id": "target", "statement": "True",
    }
    source = _target_source(task, {
        "lemma_name": "r10lf_helper", "lemma_statement": "True", "proof_body": "by trivial",
    }, "by exact r10lf_helper")
    assert source.index("theorem r10lf_helper") < source.index("theorem target")
    assert "by exact r10lf_helper" in source


def test_verified_lemma_fields_render_in_target_prompt() -> None:
    prompt = TARGET_TEMPLATE.format(
        trial_nonce=1, context_import="R5Foundation", namespace="demoVerification",
        open_namespace="demo", task_id="target", statement="True", context="theorem base",
        lemma_name="r10lf_helper", lemma_statement="True", lemma_proof="by trivial",
    )
    assert "theorem r10lf_helper : True := by trivial" in prompt
    assert "explicitly use" in prompt
