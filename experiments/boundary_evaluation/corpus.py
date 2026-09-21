"""Twelve heterogeneous, kernel-valid obligations; two per proof pattern."""
from __future__ import annotations
import json,re
from pathlib import Path
from experiments.adaptive_proving.io import sha256_file,sha256_text
from experiments.hypergraph_guidance.config import load_config as load13
from experiments.hypergraph_guidance.corpus import load_tasks as load13tasks

PATTERNS=["TEMPORAL_LIFT","WITNESS_CONSTRUCTION","REWRITE_CHAIN","STATE_TRANSITION","CASE_ANALYSIS","PHASE_TO_PHASE"]

def _wrapper(candidate):return f"({candidate}) ∧ True"
def load_tasks(project:Path,config):
 c13=load13(project/'configs/hypergraph_guidance.yaml');old,source13=load13tasks(project,c13)
 bases=source13['theorem_bases']; by_dut={b['dut']:b for b in bases}; tasks=[]
 contexts=[('secworks_aes_core','aes_core','aes_coreState','aes_coreInputs','outputs/aes/model'),('yosys_picorv32','picorv32','picorv32State','picorv32Inputs','outputs/picorv32/model')]
 def add(pattern,index,ctx,candidate,proof,foundation=[]):
  dut,module,state,inp,model=ctx; cid=f"R{len(tasks)+1:02d}";tasks.append({'challenge_id':cid,'task_id':f"r14_{pattern.lower()}_{index}",'dut':dut,'module':module,'state_type':state,'input_type':inp,'model_dir':model,'context_import':'R5Foundation','property_pattern':pattern,'statement':_wrapper(candidate),'expected_candidate_statement':candidate,'reference_candidate_proof':proof,'foundation_lemmas':foundation,'reference_proof_excluded':True,'previous_set_member':False,'statement_sha256':sha256_text(_wrapper(candidate))})
 # Temporal lift: two still-unused local-step relations.
 used={t['selected_local_step'] for t in old}
 for idx,dut in enumerate(['yosys_picorv32','olofk_serv_rf_top'],1):
  b=by_dut[dut]; theorem=next(x for x in sorted(b['theorems'],key=lambda x:x['name']) if x['name'].endswith('_local_step') and x['name'] not in used);used.add(theorem['name'])
  m=re.search(r'∀ \(s : ([^)]+)\) \(item : ([^)]+)\),\s*([A-Za-z0-9_]+) s item',theorem['statement'],re.S);state,inp,guard=m.groups();ctx=(dut,b['module'],state,inp,b['model_dir'])
  cand=f"∀ (s : {state}) (pre : List {inp}) (item : {inp}), R3Temporal.Along r3Step {guard} s (pre ++ [item]) → {guard} (R3Temporal.exec r3Step s pre) item"
  proof="""by
  intro s pre item h
  induction pre generalizing s with
  | nil => simp at h ⊢; exact h.1
  | cons head tail ih =>
    have h_tail := h
    simp [List.cons_append, R3Temporal.Along] at h_tail
    exact ih (r3Step s head) h_tail.2"""
  add('TEMPORAL_LIFT',idx,ctx,cand,proof,[theorem['name']])
 for idx,ctx in enumerate(contexts,1):
  inp=ctx[3];cand=f"∀ (xs : List {inp}), ∃ ys : List {inp}, ys.reverse = xs";add('WITNESS_CONSTRUCTION',idx,ctx,cand,"by intro xs; exact ⟨xs.reverse, by simp⟩")
 for idx,ctx in enumerate(contexts,1):
  state,inp=ctx[2],ctx[3];cand=f"∀ (s : {state}) (xs ys zs : List {inp}), R3Temporal.exec r3Step s ((xs ++ ys) ++ zs) = R3Temporal.exec r3Step (R3Temporal.exec r3Step (R3Temporal.exec r3Step s xs) ys) zs"
  add('REWRITE_CHAIN',idx,ctx,cand,"by intro s xs ys zs; rw [R3Temporal.exec_append, R3Temporal.exec_append]")
 # Specialized Along -> Obeys state-transition chains.
 for idx,(ctx,dut) in enumerate(zip(contexts,['secworks_aes_core','yosys_picorv32']),1):
  b=by_dut[dut];th=next(x for x in b['theorems'] if x['name'].endswith('_local_step'));st=th['statement'];m=re.search(r'([A-Za-z0-9_]+)_local_step',th['name']);guard=th['name'][:-len('_local_step')]+'_guard';field=re.search(r'\(r3Step s item\)\.([A-Za-z0-9_]+)',st).group(1);rhs=st.split('=',1)[1].strip()
  state,inp=ctx[2],ctx[3];expected=re.sub(r"(?<![A-Za-z0-9_'])s(?![A-Za-z0-9_'])",'t',rhs);expected=re.sub(r"(?<![A-Za-z0-9_'])item(?![A-Za-z0-9_'])",'x',expected);cand=f"∀ (s : {state}) (xs : List {inp}), R3Temporal.Along r3Step {guard} s xs → R3Temporal.Obeys r3Step {guard} (fun t x => {expected}) (fun t => t.{field}) s xs"
  proof=f"by intro s xs h; exact R3Temporal.obeys_of_along r3Step {guard} (fun t x => {expected}) (fun t => t.{field}) {th['name']} s xs h"
  add('STATE_TRANSITION',idx,ctx,cand,proof,[th['name']])
 for idx,ctx in enumerate(contexts,1):
  inp=ctx[3];cand=f"∀ (xs : List {inp}), xs = [] ∨ ∃ head tail, xs = head :: tail";add('CASE_ANALYSIS',idx,ctx,cand,"by intro xs; cases xs with | nil => exact Or.inl rfl | cons h t => exact Or.inr ⟨h,t,rfl⟩")
 for idx,ctx in enumerate(contexts,1):
  state,inp=ctx[2],ctx[3];cand=f"∀ (step : {state} → {inp} → {state}) (guard : {state} → {inp} → Prop) (s : {state}) (p1 p2 : List {inp}) (i1 i2 : {inp}), R3Temporal.Along step guard s (p1 ++ [i1]) → R3Temporal.Along step guard (R3Temporal.exec step s (p1 ++ [i1])) (p2 ++ [i2]) → guard (R3Temporal.exec step s p1) i1 ∧ guard (R3Temporal.exec step (R3Temporal.exec step s (p1 ++ [i1])) p2) i2"
  proof="""by
  intro step guard s p1 p2 i1 i2 h1 h2
  have last : ∀ (s : _) (xs : List _) (i : _), R3Temporal.Along step guard s (xs ++ [i]) → guard (R3Temporal.exec step s xs) i := by
    intro t xs i h
    induction xs generalizing t with
    | nil => simp at h ⊢; exact h.1
    | cons x rest ih => have ht := h; simp [List.cons_append, R3Temporal.Along] at ht; exact ih (step t x) ht.2
  exact ⟨last s p1 i1 h1, last (R3Temporal.exec step s (p1 ++ [i1])) p2 i2 h2⟩"""
  add('PHASE_TO_PHASE',idx,ctx,cand,proof)
 if len(tasks)!=12:raise RuntimeError('expected 12 tasks')
 src={'patterns':PATTERNS,'per_pattern':2,'hypergraph_guidance_run':config['hypergraph_guidance_run'],'hypergraph_guidance_report_sha256':sha256_file(project/config['hypergraph_guidance_run']/'final_report.json'),'historical_task_ids':[t['task_id'] for t in old],'sets_disjoint':not bool({t['task_id'] for t in old}&{t['task_id'] for t in tasks}),'theorem_bases':bases}
 return tasks,src
def verify_tasks(project,tasks,source):
 if len(tasks)!=12 or any(sum(t['property_pattern']==p for t in tasks)<2 for p in PATTERNS) or not source['sets_disjoint']:raise RuntimeError('corpus invariant failed')
 if sha256_file(project/source['hypergraph_guidance_run']/'final_report.json')!=source['hypergraph_guidance_report_sha256']:raise RuntimeError('Req13 changed')
