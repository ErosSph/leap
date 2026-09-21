"""Separate archived-run integration checks from self-contained release tests."""
import pytest


def pytest_addoption(parser):
    parser.addoption('--run-legacy', action='store_true', default=False,
                     help='Also run checks requiring historical outputs/ snapshots (not released)')


def pytest_collection_modifyitems(config, items):
    historical_modules = {
        'test_boundary_evaluation.py', 'test_bridge_discovery.py',
        'test_hypergraph_guidance.py', 'test_scale_evaluation.py',
    }
    historical_functions = {
        'test_config_is_foundation_first_and_has_no_direct_arm',
        'test_frozen_tasks_exclude_answer_bearing_metadata',
        'test_proof_gap_is_generic_and_complete',
        'test_kernel_gate_and_generic_property_rescue',
        'test_three_phase_manifest_filters_nonlocal_foundation_theorem',
        'test_failed_first_candidate_feedback_repairs_and_rescues',
        'test_frozen_corpus_is_balanced_distinct_and_kernel_validated',
        'test_frozen_prompts_are_model_neutral_and_within_budget',
        'test_authorized_transport_amendment_preserves_frozen_inputs',
        'test_freeze_reuses_exact_direct_tasks_models_and_seeds',
        'test_lemma_first_prompts_are_paired_and_model_neutral',
    }
    for item in items:
        if item.path.name in historical_modules or item.name in historical_functions:
            item.add_marker(pytest.mark.legacy_artifacts)
            if not config.getoption('--run-legacy'):
                item.add_marker(pytest.mark.skip(reason='Requires archived experiment outputs, not included in the source release; opt in with --run-legacy'))
