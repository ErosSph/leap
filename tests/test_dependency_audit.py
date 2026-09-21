from __future__ import annotations

from rtl2lean.dependency_audit.analysis import (
    _normalized_path, _overlap, _relation_match_kinds,
    _summary_theorem_compression,
)
from rtl2lean.dependency_audit.dependency import (
    META_COMMAND, _expand, _parse_dependency_output, _parse_simp_rewrite_output,
    _tactic_mechanisms,
)


def test_kernel_dependency_output_and_recursive_wrapper_expansion() -> None:
    parsed = _parse_dependency_output(
        "noise\nR9DEPS|root|summary,Eq.trans\nR9DEPS|summary|step_ab,step_bc\n"
    )
    inventory = {
        "summary": {"layer": "L4", "source_file": "R4Foundation.lean"},
        "step_ab": {"layer": "L2", "source_file": "Foundation.lean"},
        "step_bc": {"layer": "L3", "source_file": "R3Foundation.lean"},
    }
    graph = _expand("root", parsed, inventory, set())
    assert {edge["target"] for edge in graph["edges"]} >= {"summary", "step_ab", "step_bc"}
    assert "Eq.trans" in graph["primitive_leaves"]
    assert graph["max_depth"] == 2


def test_all_requested_tactics_are_elaboration_covered() -> None:
    proof = "by have h := by simp_all; show True; constructor <;> first | exact h | apply h"
    assert set(_tactic_mechanisms(proof)) >= {
        "have", "simp_all", "show", "constructor", "exact", "apply",
    }
    assert "getUsedConstants" in META_COMMAND
    traces = _parse_simp_rewrite_output(
        "R9MARK|proof\n"
        "[Meta.Tactic.simp.rewrite] unfold R3Temporal.exec, before ==> after\n"
        "[Meta.Tactic.simp.rewrite] List.foldl_append:1000:\n"
    )
    assert traces == {"proof": ["R3Temporal.exec", "List.foldl_append"]}


def test_semantic_bottleneck_match_detects_local_compression() -> None:
    prop = {
        "dut": "dut", "property_id": "p",
        "theorem_statement": "R3Temporal.Along step guard s xs → target s",
        "gap_spec": {"required_lower_level_facts": ["phase_a_local_step", "phase_b_local_step"]},
    }
    trial = {
        "trial": 1,
        "final_proof": """by
          have lastGuard : True := by
            induction xs with | nil => trivial | cons x xs ih => exact ih
          constructor
          exact phase_a_local_step
          exact phase_b_local_step""",
        "intermediate_lemmas": [],
    }
    dependency = {"root": "root"}
    expansion = {
        "nodes": [
            {"id": "root", "layer": "ROOT"},
            {"id": "dut.phase_a_local_step", "layer": "L3"},
            {"id": "dut.phase_b_local_step", "layer": "L3"},
            {"id": "R3Temporal.exec_append", "layer": "R3TEMPORAL"},
            {"id": "And.intro", "layer": "PRIMITIVE_DEFINITION"},
        ],
        "max_depth": 2, "primitive_dependency_count": 1,
        "primitive_leaves": ["And.intro"],
    }
    path = _normalized_path("DIRECT", prop, trial, dependency, expansion)
    assert path["bottleneck_semantically_used"]
    assert path["local_guard_summary_present"]
    assert path["semantic_match_evidence"] == "IMPLICIT_COMPOSITION_EQUIVALENT_TO_R"


def test_named_intermediate_is_ignored_for_semantic_path_overlap() -> None:
    direct = {
        "dut": "dut", "property_id": "p", "trial": 1,
        "semantic_nodes": ["ALONG_ASSUMPTIONS", "TRACE_PREFIX_RECURSION", "TARGET_CONCLUSION"],
        "expanded_theorem_dependencies": ["Dut.local_step"],
        "theorem_chain_depth": 2, "primitive_dependency_count": 3,
    }
    lemma = {
        **direct,
        "semantic_nodes": [
            "ALONG_ASSUMPTIONS", "TRACE_PREFIX_RECURSION",
            "NAMED_INTERMEDIATE_ABSTRACTION", "TARGET_CONCLUSION",
        ],
    }
    result = _overlap(direct, lemma)
    assert result["classification"] == "SAME_SEMANTIC_PATH"
    assert result["normalized_semantic_node_overlap"] == 1.0


def test_external_summary_theorem_is_distinguished_from_local_step() -> None:
    prop = {"gap_spec": {"required_lower_level_facts": [
        "phase_a_local_step", "phase_b_local_step", "R3Temporal.Along",
    ]}}
    dependency = {"first_level_theorem_dependencies": [
        "Dut.endpoint_summary", "Dut.phase_a_local_step", "R3Temporal.exec_append",
    ]}
    expansion = {
        "nodes": [
            {"id": "root", "statement": None},
            {"id": "Dut.endpoint_summary", "statement": "Along step g s xs → target s"},
            {"id": "Dut.phase_a_local_step", "statement": "A → B"},
            {"id": "Dut.phase_b_local_step", "statement": "B → C"},
            {"id": "R3Temporal.exec_append", "statement": "exec f s (a ++ b) = _"},
        ],
        "edges": [
            {"source": "root", "target": "Dut.endpoint_summary"},
            {"source": "Dut.endpoint_summary", "target": "Dut.phase_a_local_step"},
            {"source": "Dut.endpoint_summary", "target": "Dut.phase_b_local_step"},
        ],
    }
    assert _summary_theorem_compression(prop, dependency, expansion) == [
        "Dut.endpoint_summary",
    ]


def test_formal_bottleneck_relation_match_kinds_are_supported() -> None:
    prop = {"gap_spec": {
        "missing_relation_statement": "A x → B x",
        "relation_anchors": ["A", "B"],
    }}
    exact = {"nodes": [{"statement": "A x → B x"}]}
    general = {"nodes": [{"statement": "∀ x, C x → A x → B x"}]}
    special = {"nodes": [{"statement": "A → B"}]}
    assert "EXACT_R" in _relation_match_kinds(prop, exact, False)
    assert "GENERALIZATION_OF_R" in _relation_match_kinds(prop, general, False)
    assert "SPECIALIZATION_OF_R" in _relation_match_kinds(prop, special, False)
    assert "IMPLICIT_COMPOSITION_EQUIVALENT_TO_R" in _relation_match_kinds(prop, exact, True)
