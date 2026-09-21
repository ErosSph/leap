"""Public entry points and artifact integrity; no network calls."""
import json
import hashlib
import pytest
from pathlib import Path

from experiments.corpus_check import load_manifest
from experiments import release_runtime
from experiments.benchmark import normalize_proof, source, checked
from experiments.hypergraph_guidance.hypergraph import forward_reachability, build_hypergraph, annotate_failure
from experiments.challenge_suite.ablation import _graph


def test_complete_corpus():
    corpus = load_manifest()
    assert len(corpus['tasks']) == 177
    assert len(corpus['sources']) == 7
    for task in corpus['tasks']:
        path = release_runtime.PROJECT / 'theorems/reference' / task['dut'] / (task['task_id'] + '.lean')
        assert f'theorem {task["task_id"]} :' in path.read_text()
        assert hashlib.sha256(task['statement'].encode()).hexdigest() == task['statement_sha256']


def test_missing_key_does_not_make_request(monkeypatch):
    monkeypatch.delenv('LEAP_TEST_MISSING_API_KEY', raising=False)
    response = release_runtime.request('https://invalid.example/chat/completions', 'LEAP_TEST_MISSING_API_KEY', {})
    assert response['status'] == 'MISSING_CREDENTIAL'


def test_lean_lookup_preserves_shim_name(monkeypatch, tmp_path):
    from rtl2lean.pipeline.compiler import find_lean
    from experiments.adaptive_proving.lean import find_lean as proof_find_lean
    elan = tmp_path / 'elan'
    elan.touch()
    shim = tmp_path / 'lean'
    shim.symlink_to(elan)
    monkeypatch.setenv('RTL2LEAN_LEAN', str(shim))
    assert find_lean() == str(shim)
    assert proof_find_lean() == str(shim)


def test_redacts_configured_key(monkeypatch):
    monkeypatch.setenv('LEAP_TEST_API_KEY', 'unit-test-secret-value')
    monkeypatch.setitem(release_runtime.API, 'api_key_env', 'LEAP_TEST_API_KEY')
    assert release_runtime.redact('echo unit-test-secret-value') == 'echo [REDACTED]'


def test_api_transport_uses_env_and_scrubs_echoed_key(monkeypatch):
    monkeypatch.setenv('LEAP_TEST_API_KEY', 'test-provider-credential')
    monkeypatch.setitem(release_runtime.API, 'api_key_env', 'LEAP_TEST_API_KEY')
    seen = {}
    class Reply:
        def __enter__(self): return self
        def __exit__(self, *args): pass
        def read(self): return json.dumps({'echo': 'test-provider-credential'}).encode()
    class Opener:
        def open(self, req, timeout):
            seen['authorization'] = req.get_header('Authorization')
            return Reply()
    monkeypatch.setattr(release_runtime.urllib.request, 'build_opener', lambda *args: Opener())
    result = release_runtime.request('https://invalid.example/chat/completions', 'LEAP_TEST_API_KEY', {})
    assert seen['authorization'] == 'Bearer test-provider-credential'
    assert result['status'] == 'OK'
    assert result['body'] == {'echo': '[REDACTED]'}


def test_format_normalization():
    assert normalize_proof('```lean\nby trivial\n```') == 'by trivial'
    assert normalize_proof('exact True.intro') == 'by\n  exact True.intro'


def test_forbidden_generated_proof_rejected(tmp_path):
    result = checked({}, [], 'test', 'True', 'by sorry', tmp_path, tmp_path / 'rejected.lean')
    assert not result['success']
    assert not (tmp_path / 'rejected.lean').exists()


def test_hyperedge_requires_all_premises():
    graph = {'initial_nodes': ['a'], 'goal_node': 'g',
             'nodes': [{'node_id': n} for n in ['a','b','g']],
             'hyperedges': [{'edge_id': 'joint', 'premises': ['a','b'], 'conclusion': 'g'}]}
    assert not forward_reachability(graph)['goal_reachable']
    bridge = {'edge_id': 'bridge', 'premises': ['a'], 'conclusion': 'b'}
    result = forward_reachability(graph, [bridge])
    assert result['goal_reachable']
    assert set(result['fired_edges']) == {'joint', 'bridge'}


def test_missing_trace_guard_is_a_frontier():
    task = {'task_id': 'endpoint', 'statement':
            '∀ (s : State) (pre : List Input) (item : Input), R3Temporal.Along step update_guard s (pre ++ [item]) → result s pre item',
            'selected_local_step': 'update_local_step', 'required_state_fields': ['crc']}
    theorem = {'name': 'update_local_step', 'statement':
               '∀ (s : State) (item : Input), update_guard s item → result_local s item'}
    gap = {'temporal_structure': {'append_singleton_occurrences': 1}}
    graph, frontier, missing = build_hypergraph(task, gap, [theorem])
    assert not frontier['goal_reachable']
    assert missing[0]['candidate_edge_type'] == 'TEMPORAL_LIFT'
    assert missing[0]['target_frontier'] == ['update_guard (r3Run s pre) item']
    hypothetical_bridge = {'edge_id': 'candidate', 'premises': missing[0]['candidate_source_nodes'],
                           'conclusion': missing[0]['candidate_target_node']}
    # Reachability is a utility check, not a proof that the candidate is valid.
    assert forward_reachability(graph, [hypothetical_bridge])['goal_reachable']


def test_repair_and_redesign_are_distinct():
    repair = annotate_failure({}, {}, {'primary_cause': 'TYPE_MISMATCH'}, {}, {})
    redesign = annotate_failure({}, {}, {'primary_cause': 'IRRELEVANT'}, {}, {})
    assert repair['repair_or_redesign'] == 'REPAIR_SCHEMA'
    assert redesign['repair_or_redesign'] == 'REDESIGN_EDGE'


def test_every_design_has_a_concrete_dependency_graph():
    corpus = load_manifest()
    for row in corpus['sources']:
        task = next(t for t in corpus['tasks'] if t['dut'] == row['dut'])
        graph = _graph(task, row['selected_predicates'])
        assert len(graph['initial_nodes']) == 4
        assert graph['proof_frontier'] == 'core'
        assert any(len(edge['from']) == 2 for edge in graph['hyperedges'])


def test_runner_checks_and_reuses_core_without_network(monkeypatch, tmp_path):
    """Use a deterministic fake model to test the real Lean gate and reuse path."""
    from experiments import benchmark
    model_dir = release_runtime.model_directory('aes')
    if not (model_dir / 'R17Support.olean').exists():
        pytest.skip('Run leap-check --dut aes first for the real-kernel runner integration test')
    corpus = load_manifest()
    row = next(r for r in corpus['sources'] if r['dut'] == 'aes')
    tasks = [t for t in corpus['tasks'] if t['dut'] == 'aes'][:2]
    proofs = [f'simpa [{r["predicate"]}] using {r["theorem"]} s i' for r in row['selected_predicates']]
    body = ('by\n  intro s i\n  change (r16Pred01 s i ∧ r16Pred02 s i) ∧ (r16Pred03 s i ∧ r16Pred04 s i)\n'
            '  constructor\n  · constructor\n    · ' + proofs[0] + '\n    · ' + proofs[1] +
            '\n  · constructor\n    · ' + proofs[2] + '\n    · ' + proofs[3])
    calls = []
    def fake_generate(model, prompt):
        calls.append(prompt)
        return {'status': 'OK', 'candidate': {'proof_body': body}, 'usage': None, 'elapsed_s': 0}
    monkeypatch.setattr(benchmark, 'ROOT', tmp_path)
    monkeypatch.setattr(benchmark, 'generate', fake_generate)
    results = benchmark.run_design('offline-test', 'full', row, tasks)
    assert all(r['success'] for r in results)
    assert len(calls) == 1
    assert results[1]['actual_reused_names'] == ['paper_core']
    assert results[1]['api_calls'] == 0
