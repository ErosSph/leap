import argparse,json,sys
from pathlib import Path
from .orchestration import validate_environment,run_new,resume,report
def main(argv=None):
 p=argparse.ArgumentParser();s=p.add_subparsers(dest='cmd',required=True)
 for x in ['validate','run']:q=s.add_parser(x);q.add_argument('--config',type=Path,required=True)
 for x in ['resume','report']:q=s.add_parser(x);q.add_argument('--run-dir',type=Path,required=True)
 a=p.parse_args(argv)
 try:
  if a.cmd=='validate':*_,r=validate_environment(a.config);out={'report':r}
  elif a.cmd=='run':d,r=run_new(a.config,[sys.executable,'-m','experiments.boundary_evaluation',*(argv or sys.argv[1:])]);out={'run_dir':str(d),'report':r}
  elif a.cmd=='resume':out={'run_dir':str(a.run_dir.resolve()),'report':resume(a.run_dir.resolve())}
  else:out={'run_dir':str(a.run_dir.resolve()),'report':report(a.run_dir.resolve())}
  print(json.dumps(out,indent=2,ensure_ascii=False));return 0
 except Exception as e:print(json.dumps({'status':'FAIL','error':str(e)},indent=2),file=sys.stderr);return 1
