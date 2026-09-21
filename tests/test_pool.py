from datetime import datetime, timezone

import pytest

from rtl2lean.proving.llm_prover import (
    CodexCLIProvider,
    PersistentLocalLemmaPool,
    VerifiedLemmaRecord,
)


def record(proof="by trivial"):
    return VerifiedLemmaRecord(
        "safe", "True", proof, "property_a", 1, "PASS",
        datetime.now(timezone.utc).isoformat(), "test", "safety", "State", [], [],
    )


def test_pool_accepts_only_kernel_marked_and_reuse_is_explicit(tmp_path):
    pool = PersistentLocalLemmaPool(tmp_path / "pool.json", "dut")
    pool.add_verified(record())
    assert len(pool.lemmas) == 1
    pool.mark_reused("safe", "property_b")
    assert pool.lemmas[0].reuse_count == 1
    with pytest.raises(ValueError):
        pool.add_verified(record("by sorry"))


def test_large_model_prompt_renders_constructor_and_foldl_guidance(tmp_path):
    provider = CodexCLIProvider(executable="codex", workdir=tmp_path)
    prompt = provider._prompt({
        "mode": "GENERATE",
        "proof_task": {
            "target_name": "finite_history",
            "target_statement": "True",
            "property_type": "finite_reachability_witness",
            "assumptions": [],
            "context_snippets": [],
            "relevant_foundational_lemmas": [],
            "future_targets": [],
        },
        "lean_feedback": "",
        "retrieved_lemmas": [],
        "attempt_history": [],
    })
    assert "next {s}" in prompt
    assert "List.foldl_append" in prompt
