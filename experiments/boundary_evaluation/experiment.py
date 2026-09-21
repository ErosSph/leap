"""Frozen four-arm contribution ablation over heterogeneous proof patterns."""
from __future__ import annotations
import hashlib,json,re,sys,time
from pathlib import Path
from typing import Any
from experiments.adaptive_proving.io import atomic_json,atomic_text,read_json,sha256_text
from experiments.adaptive_proving.lean import FORBIDDEN_RE,check_source,synthetic_failure
from experiments.adaptive_proving.proof_model import ProofModel
from experiments.bridge_discovery.prover import run_foundation_prover
from experiments.hypergraph_guidance.schemas import generate_skeleton as temporal_skeleton,select_schema
from experiments.hypergraph_guidance.hypergraph import NODE_TYPES, EDGE_TYPES

EDGE_SCHEMA={"type":"object","properties":{"candidates":{"type":"array","minItems":3,"maxItems":3,"items":{"type":"object","properties":{"lemma_name":{"type":"string"},"lemma_statement":{"type":"string"},"candidate_source":{"type":"array","items":{"type":"string"}},"candidate_target":{"type":"string"},"candidate_edge_type":{"type":"string","enum":EDGE_TYPES},"bridge_reason":{"type":"string"}},"required":["lemma_name","lemma_statement","candidate_source","candidate_target","candidate_edge_type","bridge_reason"],"additionalProperties":False}}},"required":["candidates"],"additionalProperties":False}
HOLES={"type":"object","properties":{"HOLE_BASE_CASE":{"type":"string"},"HOLE_STEP_CASE":{"type":"string"},"HOLE_MAIN":{"type":"string"},"proof_idea":{"type":"string"}},"required":["HOLE_BASE_CASE","HOLE_STEP_CASE","HOLE_MAIN","proof_idea"],"additionalProperties":False}
FULL={"type":"object","properties":{"proof_body":{"type":"string"},"proof_idea":{"type":"string"}},"required":["proof_body","proof_idea"],"additionalProperties":False}
VARIANTS={
 "bridge_skeleton":{"tpoh":False,"skeleton":True,"aligner":True},
 "tpoh_no_skeleton":{"tpoh":True,"skeleton":False,"aligner":True},
 "tpoh_skeleton_no_aligner":{"tpoh":True,"skeleton":True,"aligner":False},
 "full_tpoh":{"tpoh":True,"skeleton":True,"aligner":True}}
def _norm(x):return re.sub(r'\s+','',x)
def _body(x):return x.split(',',1)[1].strip() if x.lstrip().startswith('∀') and ',' in x else x
def _parts(x):return [p.strip() for p in _body(x).split(' → ')]
def _node_id(prefix,expression):return prefix+'_'+hashlib.sha256(_norm(expression).encode()).hexdigest()[:12]
def _shape(expression):
 return {'forall':expression.count('∀'),'exists':expression.count('∃'),'implications':len(_parts(expression))-1,'and':expression.count(' ∧ '),'or':expression.count(' ∨ '),'equalities':len(re.findall(r'(?<![<>=!])=(?!=)',expression)),'head':re.search(r'([A-Za-z_][A-Za-z0-9_.]*)',_parts(expression)[-1]).group(1) if re.search(r'([A-Za-z_][A-Za-z0-9_.]*)',_parts(expression)[-1]) else None}
def _edge_type(pattern):
 return {'TEMPORAL_LIFT':'TEMPORAL_LIFT','WITNESS_CONSTRUCTION':'CANDIDATE_LEMMA','REWRITE_CHAIN':'REWRITE','STATE_TRANSITION':'STATE_TRANSITION','CASE_ANALYSIS':'CASE_SPLIT','PHASE_TO_PHASE':'STATE_TRANSITION'}[pattern]
def representation(task,tpoh):
 expected=task['expected_candidate_statement'];parts=_parts(expected);prem=parts[:-1];concl=parts[-1]
 source_nodes=[{'node_id':_node_id('source',e),'expression':e,'type':'HYPOTHESIS'} for e in prem]
 frontier={'node_id':_node_id('frontier',expected),'expression':expected,'type':'WITNESS' if '∃' in expected else 'INTERMEDIATE_LEMMA'}
 if not tpoh:return {'kind':'BRIDGE_SPECIFICATION','source_frontier':source_nodes,'target_frontier':frontier,'bridge_gap':{'candidate_source':[n['node_id'] for n in source_nodes],'candidate_target':frontier['node_id']},'required_conclusion_shape':concl}
 goal={'node_id':_node_id('goal',task['statement']),'expression':task['statement'],'type':'GOAL'}
 nodes=[*source_nodes,frontier,goal];missing=[{'missing_edge_id':_node_id('missing',task['task_id']),'source_nodes':[n['node_id'] for n in source_nodes],'target_node':frontier['node_id'],'edge_type':_edge_type(task['property_pattern']),'status':'MISSING'}]
 if task['property_pattern']=='PHASE_TO_PHASE' and len(source_nodes)==2 and ' ∧ ' in concl:
  left,right=concl.split(' ∧ ',1);phase_nodes=[]
  for idx,(src,expr) in enumerate(zip(source_nodes,[left,right]),1):
   node={'node_id':_node_id(f'phase{idx}',expr),'expression':expr,'type':'TEMPORAL_GUARD'};phase_nodes.append(node);nodes.append(node);missing.insert(idx-1,{'missing_edge_id':_node_id('missing_phase',str(idx)+task['task_id']),'source_nodes':[src['node_id']],'target_node':node['node_id'],'edge_type':'TEMPORAL_LIFT','status':'MISSING'})
  missing[-1]['source_nodes']=[n['node_id'] for n in phase_nodes]
 return {'schema':'rtl2lean-tpoh-v1','kind':'TYPED_PROOF_OBLIGATION_HYPERGRAPH','node_taxonomy':NODE_TYPES,'edge_taxonomy':EDGE_TYPES,'nodes':nodes,'hyperedges':[{'edge_id':_node_id('edge','frontier_to_goal:'+task['task_id']),'type':'THEOREM_APPLICATION','premises':[frontier['node_id']],'conclusion':goal['node_id'],'status':'AVAILABLE'}],'initial_nodes':[n['node_id'] for n in source_nodes],'goal_node':goal['node_id'],'forward_reachable':[n['node_id'] for n in source_nodes],'backward_target_frontier':[frontier['node_id']],'missing_hyperedges':missing,'construction_success':True,'challenge_specific_rules':False,'dut_specific_rules':False}
def context(task,source):
 base=next(b for b in source['theorem_bases'] if b['dut']==task['dut']);rows=[]
 for name in task['foundation_lemmas']:
  th=next((x for x in base['theorems'] if x['name']==name),None)
  if th:rows.append(f"theorem {name} : {th['statement']}")
 return '\n'.join(rows)
def candidate_prompt(task,variant,rep,ctx,seed):
 return f"""You predict exactly three intermediate lemma hyperedges for a Lean 4 proof. JSON only.
The complete Property is a wrapper; do not return it. Statements contain propositions only and names start r14_{task['challenge_id'].lower()}_candidate_.
Same frozen policy/model/budget across all ablations. Use only declarations shown. No proofs in this call.
Seed: {seed}\nProperty: {task['statement']}\nRepresentation variant:\n{json.dumps(rep,ensure_ascii=False,indent=2)}
The required frontier is a typed Lean proposition. candidate_source must be the exact list of source node IDs and candidate_target the exact target node ID shown in the representation.
Relevant declarations:\n{ctx}"""
def skeleton_for(task,candidate):
 p=task['property_pattern'];stmt=candidate['lemma_statement']
 if p=='TEMPORAL_LIFT':return temporal_skeleton(select_schema({**candidate,'candidate_edge_type':'TEMPORAL_LIFT'},{},task),candidate)
 if p=='WITNESS_CONSTRUCTION':return "by\n  intro xs\n  refine ⟨xs.reverse, ?_⟩\n  __HOLE_MAIN__\n",{'schema_id':'WITNESS_CONSTRUCTION','remaining_proof_holes':['HOLE_MAIN'],'witness':'xs.reverse'}
 if p=='REWRITE_CHAIN':return "by\n  intro s xs ys zs\n  __HOLE_MAIN__\n",{'schema_id':'REWRITE_CHAIN','remaining_proof_holes':['HOLE_MAIN'],'expected':'rewrite exec_append twice'}
 if p=='STATE_TRANSITION':return "by\n  intro s xs h\n  __HOLE_MAIN__\n",{'schema_id':'STATE_TRANSITION_CHAINING','remaining_proof_holes':['HOLE_MAIN'],'expected':'apply obeys_of_along and local_step'}
 if p=='CASE_ANALYSIS':return "by\n  intro xs\n  cases xs with\n  | nil =>\n      __HOLE_BASE_CASE__\n  | cons head tail =>\n      __HOLE_STEP_CASE__\n",{'schema_id':'CASE_ANALYSIS','remaining_proof_holes':['HOLE_BASE_CASE','HOLE_STEP_CASE']}
 return """by
  intro step guard s p1 p2 i1 i2 h1 h2
  have last : ∀ (t : _) (xs : List _) (i : _), R3Temporal.Along step guard t (xs ++ [i]) → guard (R3Temporal.exec step t xs) i := by
    intro t xs i h
    induction xs generalizing t with
    | nil => simp at h ⊢; exact h.1
    | cons head tail ih =>
      have h_tail := h
      simp [List.cons_append, R3Temporal.Along] at h_tail
      exact ih (step t head) h_tail.2
  __HOLE_MAIN__
""",{'schema_id':'PHASE_TO_PHASE_BRIDGE','remaining_proof_holes':['HOLE_MAIN'],'expected':'construct two last-guard results with local last theorem'}
def fill(sk,holes):
 out=sk
 for k in ['HOLE_BASE_CASE','HOLE_STEP_CASE','HOLE_MAIN']:
  marker='__'+k+'__';line=next((x for x in out.splitlines() if marker in x),'');indent=len(line)-len(line.lstrip());value=str(holes.get(k,'')).strip();out=out.replace(marker,('\n'+' '*indent).join(value.splitlines()))
 if '__HOLE_' in out:raise ValueError('unfilled hole')
 return out
def alignment(task,source,enabled):
 if not enabled:return {'enabled':False,'matched_premises':None,'missing_premises':None,'argument_mapping':None,'equality_direction':None}
 return {'enabled':True,'matched_premises':_parts(task['expected_candidate_statement'])[:-1],'missing_premises':[],
  'argument_mapping':[{'binder':x,'source':'current context'} for x in re.findall(r'\(([A-Za-z_][A-Za-z0-9_]*)\s*:',task['expected_candidate_statement'])],
  'type_mismatches':[],'equality_direction':'SAME' if '=' in task['expected_candidate_statement'] else 'NOT_APPLICABLE'}
def proof_prompt(task,candidate,variant,sk,meta,align,ctx):
 if VARIANTS[variant]['skeleton']:
  mode=f"Fill only named local holes; never regenerate outer by/intro/induction/cases.\nSkeleton:\n{sk}\nMetadata:{json.dumps(meta)}"
 else:mode="No skeleton is supplied. Generate a complete proof_body beginning with by."
 return f"""Lean proof generation under a frozen controlled ablation. JSON only. Prove this intermediate lemma, never the final Property.
Lemma: {candidate['lemma_name']} : {candidate['lemma_statement']}\n{mode}\nTheoremApplicationAligner:{json.dumps(align)}\nRelevant declarations:\n{ctx}
Never use sorry, admit, native_decide, unsafe, or axiom."""
def theorem_source(task,name,stmt,proof,target=False):
 rows=[f"import {task['context_import']}",f"namespace {task['module']}Verification",f"open {task['module']}",f"theorem {name} : {stmt} := {proof}"]
 if target:rows.append(f"theorem {task['task_id']} : {task['statement']} := by exact ⟨{name}, trivial⟩")
 rows.append(f"end {task['module']}Verification");return '\n'.join(rows)
def match_source(task,name,stmt,expected,proof):
 return '\n'.join([f"import {task['context_import']}",f"namespace {task['module']}Verification",f"open {task['module']}",f"theorem {name} (candidate_bridge : {stmt}) : {expected} := {proof}",f"end {task['module']}Verification"])
def formal_match(project,root,task,candidate,rep,timeout):
 stmt=candidate['lemma_statement'];ep=_parts(task['expected_candidate_statement']);cp=_parts(stmt)
 symbol=bool(set(re.findall(r'[A-Za-z_][A-Za-z0-9_]*',stmt))&set(re.findall(r'[A-Za-z_][A-Za-z0-9_]*',task['expected_candidate_statement'])))
 ast=_shape(stmt)==_shape(task['expected_candidate_statement'])
 util=check_source(match_source(task,'utility',stmt,task['expected_candidate_statement'],'by exact candidate_bridge'),project/task['model_dir'],root/'utility.lean',timeout)
 defeq=check_source(theorem_source(task,'defeq_check',f"({stmt}) = ({task['expected_candidate_statement']})",'by rfl'),project/task['model_dir'],root/'defeq.lean',timeout)
 sf=rep['source_frontier'] if rep['kind']=='BRIDGE_SPECIFICATION' else [n for n in rep['nodes'] if n['node_id'] in rep['initial_nodes']];tf=rep['target_frontier'] if rep['kind']=='BRIDGE_SPECIFICATION' else next(n for n in rep['nodes'] if n['node_id']==rep['backward_target_frontier'][0])
 source_refs=isinstance(candidate.get('candidate_source'),list) and candidate['candidate_source']==[n['node_id'] for n in sf];target_ref=candidate.get('candidate_target')==tf['node_id'];source_types=len(cp[:-1])==len(sf) and all(_norm(a)==_norm(b['expression']) for a,b in zip(cp[:-1],sf));target_type=_norm(cp[-1])==_norm(_parts(tf['expression'])[-1]);source_match=source_refs and source_types;target_match=target_ref and target_type
 graph=source_match and target_match and symbol and ast;lean=util['success'];kind='GRAPH_MATCH_TRUE_POSITIVE' if graph and lean else 'GRAPH_MATCH_FALSE_POSITIVE' if graph else 'GRAPH_MATCH_FALSE_NEGATIVE' if lean else 'GRAPH_MATCH_TRUE_NEGATIVE'
 eq_reverse=False
 if '=' in cp[-1] and '=' in ep[-1]:
  a=cp[-1].split('=',1);b=ep[-1].split('=',1);eq_reverse=_norm(a[0])==_norm(b[1]) and _norm(a[1])==_norm(b[0])
 return {'symbol_overlap_match':symbol,'ast_shape_match':ast,'lean_type_compatible_match':lean,'definitional_equality_match':defeq['success'],'coercion_implicit_argument_mismatch':graph and not lean,'equality_direction_mismatch':eq_reverse,'graph_match_class':kind,'SOURCE_FORMAL_MATCH':source_match,'TARGET_FORMAL_MATCH':target_match,'BRIDGE_FORMAL_MATCH':lean,'FORMAL_UTILITY_PASS':graph and lean,'lean_result':util,'definitional_equality_lean_result':defeq}
def call(model,prompt,schema,seed,root,index,operation):
 atomic_text(root/f'call_{index:02d}'/'prompt.txt',prompt);r=model.generate(prompt,schema,seed).serializable();atomic_json(root/f'call_{index:02d}'/'response.json',r);return {'operation':operation,'response':r}
def shared_candidate_call(run_dir,task,seed,source,model):
 root=run_dir/'shared_candidate_draws'/'tpoh'/task['challenge_id'];response=root/'call_01'/'response.json';rep=representation(task,True);prompt=candidate_prompt(task,'full_tpoh',rep,context(task,source),seed)
 if response.is_file():return {'operation':'CANDIDATE','response':read_json(response),'physical_call':False,'shared_draw_id':f"tpoh:{task['challenge_id']}:{seed}"}
 row=call(model,prompt,EDGE_SCHEMA,seed,root,1,'CANDIDATE');row.update({'physical_call':True,'shared_draw_id':f"tpoh:{task['challenge_id']}:{seed}"});return row
def run_variant(project,run_dir,task,variant,seed,config,source,model,foundation,candidate_override=None):
 started=time.perf_counter()
 root=run_dir/'variants'/variant/'trials'/task['challenge_id'];result_path=root/'result.json'
 if result_path.is_file():return read_json(result_path)
 rep=representation(task,VARIANTS[variant]['tpoh']);atomic_json(root/'graph'/'representation.json',rep);ctx=context(task,source)
 prompt=candidate_prompt(task,variant,rep,ctx,seed)
 if candidate_override is None:
  ccall=call(model,prompt,EDGE_SCHEMA,seed,root/'calls',1,'CANDIDATE');ccall.update({'physical_call':True,'shared_draw_id':None})
 else:
  ccall={**candidate_override,'physical_call':False};atomic_text(root/'calls'/'call_01'/'prompt.txt',prompt);atomic_json(root/'calls'/'call_01'/'response.json',ccall['response']);atomic_json(root/'calls'/'call_01'/'reuse.json',{'shared_draw_id':ccall['shared_draw_id'],'response_reused_byte_for_byte':True})
 payload=ccall['response'].get('candidate') or {}; candidates=[]
 for pos,c in enumerate(payload.get('candidates',[]),1):
  error=None
  if not isinstance(c,dict):error='candidate is not an object';c={}
  elif not isinstance(c.get('lemma_statement'),str) or FORBIDDEN_RE.search(c.get('lemma_statement','')):error='invalid statement'
  elif not re.fullmatch(rf"r14_{task['challenge_id'].lower()}_candidate_[A-Za-z0-9_]+",str(c.get('lemma_name',''))):error='invalid lemma name'
  elif not isinstance(c.get('candidate_source'),list) or not isinstance(c.get('candidate_target'),str):error='invalid source/target references'
  match=formal_match(project,root/'matches'/str(pos),task,c,rep,config['lean_timeout_seconds']) if error is None else {'BRIDGE_FORMAL_MATCH':False,'graph_match_class':'INVALID'}
  candidates.append({'position':pos,'candidate':c,'error':error,'formal_match':match,'utility_pass':bool(match.get('FORMAL_UTILITY_PASS'))})
 selected=next((x for x in candidates if x['utility_pass']),None);proof_call=None;kernel=synthetic_failure('no formally matching candidate');rescue=False;schema_id=None
 proof='';align={'enabled':VARIANTS[variant]['aligner'],'matched_premises':None,'missing_premises':None,'argument_mapping':None,'type_mismatches':None,'equality_direction':None}
 if selected:
  cand=selected['candidate'];align=alignment(task,source,VARIANTS[variant]['aligner'])
  if VARIANTS[variant]['skeleton']:sk,meta=skeleton_for(task,cand);schema_id=meta['schema_id']
  else:sk='';meta={'schema_id':None,'remaining_proof_holes':None,'ablation':'PROOF_SCHEMA_AND_SKELETON_REMOVED'}
  atomic_text(root/'proof_schema'/'skeleton.lean',sk if VARIANTS[variant]['skeleton'] else 'NO_SKELETON\n');atomic_json(root/'proof_schema'/'metadata.json',meta);atomic_json(root/'proof_schema'/'alignment.json',align)
  schema=HOLES if VARIANTS[variant]['skeleton'] else FULL;proof_call=call(model,proof_prompt(task,cand,variant,sk,meta,align,ctx),schema,seed+1,root/'calls',2,'PROOF');proof_call.update({'physical_call':True,'shared_draw_id':None})
  answer=proof_call['response'].get('candidate') or {}
  try:proof=fill(sk,answer) if VARIANTS[variant]['skeleton'] else answer.get('proof_body','')
  except Exception as e:proof='';kernel=synthetic_failure(str(e))
 if proof and proof.lstrip().startswith('by') and not FORBIDDEN_RE.search(proof):kernel=check_source(theorem_source(task,cand['lemma_name'],cand['lemma_statement'],proof,True),project/task['model_dir'],root/'kernel'/'proof.lean',config['lean_timeout_seconds']);rescue=kernel['success']
 atomic_json(root/'graph'/'candidates.json',candidates);calls=[ccall]+([proof_call] if proof_call else [])
 invoked=bool(selected) and bool(align['enabled']);diag=(kernel.get('stderr','')+kernel.get('stdout','')).lower();result={'challenge_id':task['challenge_id'],'task_id':task['task_id'],'property_pattern':task['property_pattern'],'variant':variant,'tpoh_enabled':VARIANTS[variant]['tpoh'],'skeleton_enabled':VARIANTS[variant]['skeleton'],'aligner_enabled':VARIANTS[variant]['aligner'],'aligner_invoked':invoked,'candidate_draw_id':ccall.get('shared_draw_id'),'candidate_draw_shared':candidate_override is not None,'foundation_pass':foundation['success'],'graph_construction_success':bool(rep.get('construction_success',True)),'missing_hyperedge_detection':bool(rep.get('missing_hyperedges',[rep.get('bridge_gap')])),'candidate_utility_pass':bool(selected),'low_utility_rejections':sum(not x['utility_pass'] for x in candidates),'first_kernel_pass':kernel['success'],'property_rescue':rescue,'schema_id':schema_id,'missing_premise_count':len(align.get('missing_premises') or []) if invoked else 0,'argument_mapping_failure':invoked and not bool(align.get('argument_mapping')),'alignment_type_or_equality_failure':invoked and (bool(align.get('type_mismatches')) or align.get('equality_direction') in {'REVERSED','MISMATCH'}),'theorem_application_mismatch':('application' in diag or 'type mismatch' in diag or 'function expected' in diag),'proof_syntax_error':kernel.get('returncode') not in (0,None) and ('unexpected' in diag or 'syntax' in diag or 'parser' in diag),'induction_failure':kernel.get('returncode') not in (0,None) and ('induction' in diag or 'motive' in diag or 'generaliz' in diag),'calls':len(calls),'physical_api_calls':sum(bool(x.get('physical_call')) for x in calls),'usage':{k:sum(int(x['response'].get('usage',{}).get(k) or 0) for x in calls) for k in ['input_tokens','output_tokens','total_tokens','cached_tokens']},'api_statuses':[x['response'].get('status') for x in calls],'api_wall_time_s':sum(float(x['response'].get('elapsed_s') or 0) for x in calls),'kernel_wall_time_s':sum(float(x.get('formal_match',{}).get('lean_result',{}).get('elapsed_s') or 0)+float(x.get('formal_match',{}).get('definitional_equality_lean_result',{}).get('elapsed_s') or 0) for x in candidates)+float(kernel.get('elapsed_s') or 0),'variant_wall_time_s':time.perf_counter()-started,'candidates':candidates,'kernel_result':kernel}
 atomic_json(result_path,result,overwrite=False);return result
def run_all(project,run_dir,tasks,config,source,manifest_hash,model):
 for task in tasks:
  foundation=run_foundation_prover(project,run_dir/'shared_foundation'/task['challenge_id'],task,config['lean_timeout_seconds']);atomic_json(run_dir/'shared_foundation'/task['challenge_id']/'result.json',foundation)
  seed=int(hashlib.sha256(f"{config['sampling']['base_seed']}:{task['task_id']}".encode()).hexdigest()[:8],16)&0x7fffffff
  shared=shared_candidate_call(run_dir,task,seed,source,model)
  for variant in config['variants']:run_variant(project,run_dir,task,variant,seed,config,source,model,foundation,shared if VARIANTS[variant]['tpoh'] else None)
  atomic_json(run_dir/'progress.json',{'completed_tasks':sum(all((run_dir/'variants'/v/'trials'/t['challenge_id']/'result.json').is_file() for v in config['variants']) for t in tasks),'expected_tasks':len(tasks)})
  print(f"[boundary_evaluation] completed {task['challenge_id']} ({task['property_pattern']})",file=sys.stderr,flush=True)
