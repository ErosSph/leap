from __future__ import annotations
import os,re,sys,tempfile
from datetime import datetime,timezone
from pathlib import Path
from experiments.adaptive_proving.config import canonical_json,digest,load_yaml
from experiments.adaptive_proving.io import atomic_json,atomic_text,read_json,sha256_file
from experiments.adaptive_proving.lean import check_source,lean_version
from experiments.adaptive_proving.proof_model import HEALTH_SCHEMA,create_proof_model
from experiments.bridge_discovery.prover import run_foundation_prover
from experiments.hypergraph_guidance.hypergraph import EDGE_TYPES,NODE_TYPES
from . import EXPERIMENT_VERSION
from .config import load_config,validate_config
from .corpus import load_tasks,verify_tasks
from .experiment import run_all,representation,VARIANTS
from .report import build_report
def root():return Path(__file__).resolve().parents[2]
def validation_source(t):return '\n'.join([f"import {t['context_import']}",f"namespace {t['module']}Verification",f"open {t['module']}",f"theorem candidate : {t['expected_candidate_statement']} := {t['reference_candidate_proof']}",f"theorem target : {t['statement']} := by exact ⟨candidate, trivial⟩",f"end {t['module']}Verification"])
def validate_environment(path,api=True,persist=True):
 p=root();c=load_config(path)
 if re.search(r'sk-[A-Za-z0-9_.-]{12,}',canonical_json(c)):raise RuntimeError('secret in config')
 tasks,source=load_tasks(p,c);verify_tasks(p,tasks,source);checks=[]
 with tempfile.TemporaryDirectory(prefix='r14-val-') as raw:
  for t in tasks:
   ref=check_source(validation_source(t),p/t['model_dir'],Path(raw)/f"{t['challenge_id']}.lean",c['lean_timeout_seconds']);checks.append({'challenge_id':t['challenge_id'],'pattern':t['property_pattern'],'reference_kernel_pass':ref['success'],'error':None if ref['success'] else (ref['stdout']+ref['stderr'])[-3000:]})
   foundation=run_foundation_prover(p,Path(raw)/'foundation'/t['challenge_id'],t,c['lean_timeout_seconds']);checks[-1]['foundation_gap_confirmed']=not foundation['success']
   graph=representation(t,True);checks[-1]['unified_taxonomy']=graph.get('node_taxonomy')==NODE_TYPES and graph.get('edge_taxonomy')==EDGE_TYPES;checks[-1]['missing_hyperedge_count']=len(graph.get('missing_hyperedges',[]))
 if not all(x['reference_kernel_pass'] for x in checks):raise RuntimeError('reference validation failed')
 if not all(x['foundation_gap_confirmed'] for x in checks):raise RuntimeError('task is not a foundation proof gap')
 if not all(x['unified_taxonomy'] and x['missing_hyperedge_count'] for x in checks):raise RuntimeError('TPOH validation failed')
 health={'checked':False}
 if api:
  r=create_proof_model({**c['proof_model'],'timeout_seconds':90,'max_completion_tokens':256}).generate('Return a JSON object whose status field is exactly ok.',HEALTH_SCHEMA,14);health={'checked':True,'success':r.status=='API_SUCCESS' and r.candidate=={'status':'ok'},'status':r.status,'error':r.error,'usage':r.usage}
  if not health['success']:raise RuntimeError('API health failed')
 out={'schema':'rtl2lean-boundary_evaluation-validation-v2','status':'PASS','checks':checks,'patterns':source['patterns'],'per_pattern':source['per_pattern'],'api':health,'lean_version':lean_version(),'reference_proofs_excluded':True,'direct_arm_present':False,'shared_tpoh_candidate_draw_control':True}
 if persist:atomic_json(p/c['output_root']/'validation'/'latest.json',out)
 formal=[{k:v for k,v in t.items() if k!='reference_candidate_proof'} for t in tasks];return c,tasks,formal,source,out
def create(path,argv):
 p=root();c,private,tasks,source,val=validate_environment(path,True);rid=datetime.now(timezone.utc).strftime('r14_%Y%m%dT%H%M%S%fZ_')+digest(c)[:10];run=p/c['output_root']/rid;m=run/'manifests';m.mkdir(parents=True);atomic_text(m/'config.yaml',path.resolve().read_text());atomic_json(m/'tasks.json',{'tasks':tasks,'source':source,'reference_proofs_excluded':True})
 files=[Path(__file__).parent/x for x in ['config.py','corpus.py','experiment.py','report.py','orchestration.py']]+[p/'experiments/hypergraph_guidance/hypergraph.py',p/'experiments/hypergraph_guidance/schemas.py',p/'experiments/bridge_discovery/prover.py',p/'experiments/adaptive_proving/proof_model.py',p/'experiments/adaptive_proving/lean.py'];pol={str(f.relative_to(p)):sha256_file(f) for f in files};atomic_json(m/'implementation_hashes.json',pol);manifest={'experiment_version':EXPERIMENT_VERSION,'run_id':rid,'timestamp':datetime.now(timezone.utc).isoformat(),'variants':c['variants'],'variant_modules':VARIANTS,'same_model_seed_property_budget':True,'common_candidate_prompt_template':True,'same_skeleton_between_skeleton_arms':True,'shared_tpoh_candidate_draw':True,'direct_arm_present':False,'reference_proofs_hidden':True,'foundation_gaps_confirmed':True,'implementation_hashes':pol};atomic_json(m/'run_manifest.json',manifest);return run,c,tasks,source
def security(run,env):
 secret=os.environ.get(env,'');pat=re.compile(rb'sk-[A-Za-z0-9_.-]{20,}');find=[]
 for p in run.rglob('*'):
  if p.is_file() and p.name!='security_scan.json' and ((secret and secret.encode() in p.read_bytes()) or pat.search(p.read_bytes())):find.append(str(p.relative_to(run)))
 out={'status':'PASS' if not find else 'FAIL','findings':find,'credential_recorded':False};atomic_json(run/'security_scan.json',out)
 if find:raise RuntimeError('secret leak')
def run_new(path,argv):
 run,c,tasks,source=create(path,argv);model=create_proof_model(c['proof_model']);run_all(root(),run,tasks,c,source,sha256_file(run/'manifests/run_manifest.json'),model);r=build_report(run,tasks,c['variants']);security(run,c['proof_model']['api_key_env']);return run,r
def load_run(run):
 c=load_yaml(run/'manifests/config.yaml');validate_config(c);x=read_json(run/'manifests/tasks.json');return c,x['tasks'],x['source']
def resume(run):
 c,t,s=load_run(run);model=create_proof_model(c['proof_model']);run_all(root(),run,t,c,s,sha256_file(run/'manifests/run_manifest.json'),model);r=build_report(run,t,c['variants']);security(run,c['proof_model']['api_key_env']);return r
def report(run):c,t,s=load_run(run);r=build_report(run,t,c['variants']);security(run,c['proof_model']['api_key_env']);return r
