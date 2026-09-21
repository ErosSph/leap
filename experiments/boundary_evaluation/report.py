from __future__ import annotations
import csv
from collections import Counter
from datetime import datetime
from pathlib import Path
from experiments.adaptive_proving.io import atomic_json,atomic_text,read_json
def rate(n,d):return {'numerator':n,'denominator':d,'rate':n/d if d else None}
def load(run,variant):return [read_json(p) for p in sorted((run/'variants'/variant/'trials').glob('R*/result.json'))]
def metrics(rows):
 tp=sum(c['formal_match']['graph_match_class']=='GRAPH_MATCH_TRUE_POSITIVE' for r in rows for c in r['candidates']);fp=sum(c['formal_match']['graph_match_class']=='GRAPH_MATCH_FALSE_POSITIVE' for r in rows for c in r['candidates']);fn=sum(c['formal_match']['graph_match_class']=='GRAPH_MATCH_FALSE_NEGATIVE' for r in rows for c in r['candidates'])
 skeleton_rows=[r for r in rows if r['skeleton_enabled']];return {'property_pass':rate(sum(r['foundation_pass'] or r['property_rescue'] for r in rows),len(rows)),'gap_rescue':rate(sum(r['property_rescue'] for r in rows),sum(not r['foundation_pass'] for r in rows)),'first_kernel_pass':rate(sum(r['first_kernel_pass'] for r in rows),sum(not r['foundation_pass'] for r in rows)),'candidate_utility_pass':rate(sum(r['candidate_utility_pass'] for r in rows),sum(not r['foundation_pass'] for r in rows)),'low_utility_rejections':sum(r['low_utility_rejections'] for r in rows),'graph_construction_success':rate(sum(r['graph_construction_success'] for r in rows),len(rows)),'missing_hyperedge_detection':rate(sum(r['missing_hyperedge_detection'] for r in rows),len(rows)),'graph_match_precision':tp/(tp+fp) if tp+fp else None,'graph_match_recall':tp/(tp+fn) if tp+fn else None,'graph_match_counts':{'true_positive':tp,'false_positive':fp,'false_negative':fn},'schema_selection_success':rate(sum(bool(r['schema_id']) for r in skeleton_rows),len(skeleton_rows)),'skeleton_success':rate(sum(r['first_kernel_pass'] for r in skeleton_rows),len(skeleton_rows)),'theorem_application_mismatch':sum(r['theorem_application_mismatch'] for r in rows),'proof_syntax_error':sum(r['proof_syntax_error'] for r in rows),'induction_failure':sum(r['induction_failure'] for r in rows),'missing_premise_count':sum(r['missing_premise_count'] for r in rows),'argument_mapping_failure':sum(r['argument_mapping_failure'] for r in rows),'alignment_type_or_equality_failure':sum(r['alignment_type_or_equality_failure'] for r in rows),'api_failures':sum(s!='API_SUCCESS' for r in rows for s in r['api_statuses']),'api_calls':sum(r['calls'] for r in rows),'physical_api_calls_attributed_to_arm':sum(r['physical_api_calls'] for r in rows),'tokens':{k:sum(r['usage'][k] for r in rows) for k in ['input_tokens','output_tokens','total_tokens','cached_tokens']},'api_wall_time_s':sum(r['api_wall_time_s'] for r in rows),'kernel_wall_time_s':sum(r['kernel_wall_time_s'] for r in rows),'total_variant_wall_time_s':sum(r['variant_wall_time_s'] for r in rows)}
def write_csv(path,headers,rows):
 path.parent.mkdir(parents=True,exist_ok=True)
 with path.open('w',newline='',encoding='utf-8') as stream:
  writer=csv.DictWriter(stream,fieldnames=headers);writer.writeheader();writer.writerows(rows)
def build_report(run,tasks,variants):
 allrows={v:load(run,v) for v in variants}
 if any(len(x)!=len(tasks) for x in allrows.values()):raise RuntimeError('incomplete matrix')
 by_variant={v:{r['challenge_id']:r for r in rows} for v,rows in allrows.items()};control=[]
 for task in tasks:
  cid=task['challenge_id'];arms=[by_variant[v][cid] for v in ['tpoh_no_skeleton','tpoh_skeleton_no_aligner','full_tpoh']];same_draw=len({r['candidate_draw_id'] for r in arms})==1 and all(r['candidate_draw_shared'] for r in arms);same_payload=len({str([c['candidate'] for c in r['candidates']]) for r in arms})==1;control.append({'challenge_id':cid,'same_draw_id':same_draw,'same_candidate_payload':same_payload})
 if not all(r['same_draw_id'] and r['same_candidate_payload'] for r in control):raise RuntimeError('TPOH downstream ablations did not share the same candidate draw')
 overall={v:metrics(rows) for v,rows in allrows.items()};patterns=sorted({t['property_pattern'] for t in tasks});per={p:{v:metrics([r for r in rows if r['property_pattern']==p]) for v,rows in allrows.items()} for p in patterns}
 analysis=run/'analysis';atomic_json(analysis/'ablation_matrix.json',overall);atomic_json(analysis/'cross_property_results.json',per)
 matches=[{'variant':v,'challenge_id':r['challenge_id'],'candidates':r['candidates']} for v,rows in allrows.items() for r in rows];atomic_json(analysis/'graph_matching_audit.json',{'rows':matches,'classes':['GRAPH_MATCH_TRUE_POSITIVE','GRAPH_MATCH_FALSE_POSITIVE','GRAPH_MATCH_FALSE_NEGATIVE','GRAPH_MATCH_TRUE_NEGATIVE'],'overall':{v:{'precision':overall[v]['graph_match_precision'],'recall':overall[v]['graph_match_recall'],'counts':overall[v]['graph_match_counts']} for v in variants}})
 sourceaudit={'SOURCE_FORMAL_MATCH':Counter(),'TARGET_FORMAL_MATCH':Counter(),'BRIDGE_FORMAL_MATCH':Counter()};source_by_variant={v:{k:Counter() for k in sourceaudit} for v in variants}
 for x in matches:
  for c in x['candidates']:
   for k in sourceaudit:
    value=str(bool(c['formal_match'].get(k)));sourceaudit[k][value]+=1;source_by_variant[x['variant']][k][value]+=1
 atomic_json(analysis/'candidate_formal_binding.json',{'overall':{k:dict(v) for k,v in sourceaudit.items()},'by_variant':{variant:{k:dict(v) for k,v in rows.items()} for variant,rows in source_by_variant.items()}})
 atomic_json(analysis/'randomization_control.json',{'status':'PASS','policy':'one byte-identical candidate draw is shared by all three TPOH downstream ablations for each task','rows':control,'shared_physical_candidate_calls':len(tasks)})
 full=overall['full_tpoh'];bridge=overall['bridge_skeleton'];noskel=overall['tpoh_no_skeleton'];noalign=overall['tpoh_skeleton_no_aligner']
 def paired(left,right):
  pairs=[(by_variant[left][t['challenge_id']]['property_rescue'],by_variant[right][t['challenge_id']]['property_rescue']) for t in tasks];return {'left':left,'right':right,'left_only_wins':sum(a and not b for a,b in pairs),'right_only_wins':sum(b and not a for a,b in pairs),'both_pass':sum(a and b for a,b in pairs),'both_fail':sum(not a and not b for a,b in pairs)}
 conclusions={'hypergraph_independent_contribution':full['gap_rescue']['rate']-bridge['gap_rescue']['rate'],'skeleton_independent_contribution':full['gap_rescue']['rate']-noskel['gap_rescue']['rate'],'aligner_independent_contribution':full['gap_rescue']['rate']-noalign['gap_rescue']['rate'],'paired_outcomes':{'hypergraph':paired('full_tpoh','bridge_skeleton'),'skeleton':paired('full_tpoh','tpoh_no_skeleton'),'aligner':paired('full_tpoh','tpoh_skeleton_no_aligner')},'full_system_interaction':'NOT_IDENTIFIABLE_FROM_MINIMUM_FOUR_ARM_MATRIX','interpretation':'Attribute the main contribution only to modules supported by paired differences; zero differences do not establish necessity.','limitations':['Two examples per pattern and one shared draw give breadth but low statistical power.','Candidate targets are explicit frontier subexpressions of wrapper Properties.','Graph matcher audits AST/symbol/node references with Lean compatibility, but is not a full dependent-type unifier.']};atomic_json(analysis/'contribution_analysis.json',conclusions)
 report={'schema':'rtl2lean-boundary_evaluation-report-v2','status':'PASS','task_count':len(tasks),'patterns':patterns,'variants':variants,'candidate_randomization_control':'PASS','shared_physical_candidate_calls':len(tasks),'overall':overall,'per_property_pattern':per,'contribution_conclusions':conclusions}
 table=run/'tables';ablation=[]
 for v in variants:
  m=overall[v];ablation.append({'method':v,'rescue':f"{m['gap_rescue']['numerator']}/{m['gap_rescue']['denominator']}",'first_kernel_pass':f"{m['first_kernel_pass']['numerator']}/{m['first_kernel_pass']['denominator']}",'candidate_utility_pass':f"{m['candidate_utility_pass']['numerator']}/{m['candidate_utility_pass']['denominator']}",'calls':m['api_calls'],'input_tokens':m['tokens']['input_tokens'],'output_tokens':m['tokens']['output_tokens'],'total_tokens':m['tokens']['total_tokens'],'api_wall_time_s':m['api_wall_time_s']})
 write_csv(table/'ablation.csv',list(ablation[0]),ablation)
 cross=[]
 for p in patterns:
  m=per[p]['full_tpoh'];cross.append({'property_pattern':p,'tpoh_gap_detection':f"{m['missing_hyperedge_detection']['numerator']}/{m['missing_hyperedge_detection']['denominator']}",'kernel_pass':f"{m['first_kernel_pass']['numerator']}/{m['first_kernel_pass']['denominator']}",'property_rescue':f"{m['gap_rescue']['numerator']}/{m['gap_rescue']['denominator']}"})
 write_csv(table/'cross_property.csv',list(cross[0]),cross)
 atomic_json(run/'final_report.json',report);lines=['# boundary_evaluation Final Report','',f"Tasks: {len(tasks)}; patterns: {len(patterns)}",'','## Main ablation','']
 for v in variants:lines.append(f"- {v}: rescue {overall[v]['gap_rescue']['numerator']}/{overall[v]['gap_rescue']['denominator']}, first kernel {overall[v]['first_kernel_pass']['numerator']}/{overall[v]['first_kernel_pass']['denominator']}, calls {overall[v]['api_calls']}, tokens {overall[v]['tokens']['total_tokens']}")
 lines+=['','## Contribution conclusion','',str(conclusions)];atomic_text(run/'final_report.md','\n'.join(lines)+'\n');return report
