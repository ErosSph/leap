from __future__ import annotations
import tempfile, unittest
from pathlib import Path
from experiments.hypergraph_guidance.config import load_config
from experiments.hypergraph_guidance.corpus import load_tasks, theorem_base_for, verify_tasks
from experiments.hypergraph_guidance.hypergraph import build_hypergraph
from experiments.hypergraph_guidance.schemas import fill_skeleton, generate_skeleton, select_schema, theorem_application_aligner
from experiments.hypergraph_guidance.utility import graph_utility
from experiments.foundation_first.proof_gap import extract_proof_gap, retrieve_lemmas
from experiments.bridge_discovery.prover import formal_kernel_gate

PROJECT=Path(__file__).resolve().parents[1]

def fixture():
 c=load_config(PROJECT/'configs/hypergraph_guidance.yaml');tasks,source=load_tasks(PROJECT,c);t=tasks[1];base=theorem_base_for(source,t['dut'])
 rows=retrieve_lemmas(t['statement'],base['theorems'],16)
 if not any(x['name']==t['selected_local_step'] for x in rows):
  x=next(x for x in base['theorems'] if x['name']==t['selected_local_step']);rows.insert(0,{**x,'score':100,'matched_symbols':[],'matched_state_fields':t['required_state_fields']})
 gap=extract_proof_gap(t,base['theorems'],rows,{'attempts':[]},'test');graph,frontier,missing=build_hypergraph(t,gap,rows)
 return c,tasks,source,t,base,gap,graph,frontier,missing

class HypergraphGuidanceTests(unittest.TestCase):
 def test_new_corpus_is_disjoint(self):
  c,tasks,source,*_=fixture();verify_tasks(PROJECT,tasks,source);self.assertEqual(len(tasks),10);self.assertFalse(set(source['previous_task_ids'])&{x['task_id'] for x in tasks})
 def test_tpoh_detects_temporal_lift(self):
  *_,graph,frontier,missing=fixture();self.assertTrue(graph['construction_success']);self.assertFalse(frontier['goal_reachable']);self.assertEqual(missing[0]['candidate_edge_type'],'TEMPORAL_LIFT')
 def test_graph_utility_rejects_exec_identity(self):
  c,_,_,task,base,_,graph,_,missing=fixture();bad={'lemma_name':'bad','lemma_statement':'∀ (step : σ → ι → σ) (s : σ) (xs : List ι) (x : ι), R3Temporal.exec step s (xs ++ [x]) = step (R3Temporal.exec step s xs) x','candidate_source':'trace','candidate_target':'identity','candidate_edge_type':'REWRITE','bridge_reason':'local'}
  with tempfile.TemporaryDirectory() as raw:r,_=graph_utility(PROJECT,Path(raw),task,bad,graph,missing,base['theorems'],30)
  self.assertEqual(r['classification'],'LOW_TARGET_UTILITY')
 def test_schema_skeleton_is_kernel_valid_when_holes_valid(self):
  _,_,_,task,_,_,_,_,missing=fixture();candidate={'lemma_name':'r13_test_last','lemma_statement':'∀ (step : σ → ι → σ) (guard : σ → ι → Prop) (s : σ) (pre : List ι) (item : ι), R3Temporal.Along step guard s (pre ++ [item]) → guard (R3Temporal.exec step s pre) item','candidate_edge_type':'TEMPORAL_LIFT'}
  selection=select_schema(candidate,missing[0],task);skeleton,meta=generate_skeleton(selection,candidate);proof=fill_skeleton(skeleton,{'HOLE_BASE_CASE':'exact h.1','HOLE_STEP_CASE':"exact ih (step s head) h_tail.2",'HOLE_MAIN':''})
  with tempfile.TemporaryDirectory() as raw:r=formal_kernel_gate(PROJECT,Path(raw)/'proof.lean',task,{**candidate,'proof_body':proof},30)
  self.assertTrue(r['success']);self.assertEqual(meta['generalized_state'],'s')
 def test_aligner_reports_mapping(self):
  *_,task,base,_,_,_,missing=fixture();theorem=next(x for x in base['theorems'] if x['name']==task['selected_local_step']);a=theorem_application_aligner(theorem,missing[0]['target_frontier'],task['statement'].rsplit(' → ',1)[-1]);self.assertTrue(a['possible_specialization']);self.assertTrue(a['argument_mapping'])

if __name__=='__main__':unittest.main()
