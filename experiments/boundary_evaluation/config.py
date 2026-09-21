from pathlib import Path
from experiments.adaptive_proving.config import ConfigError,load_yaml
from . import EXPERIMENT_VERSION
EXPECTED=["bridge_skeleton","tpoh_no_skeleton","tpoh_skeleton_no_aligner","full_tpoh"]
def validate_config(c):
 if c.get('experiment_version')!=EXPERIMENT_VERSION:raise ConfigError('wrong version')
 if c.get('variants')!=EXPECTED:raise ConfigError('four frozen ablations required')
 if c.get('candidate_count')!=3 or c.get('candidate_calls')!=1 or c.get('proof_calls')!=1:raise ConfigError('budgets must be 3/1/1')
 if c.get('trial_ids')!=[1] or c.get('sampling',{}).get('base_seed')!=314159:raise ConfigError('frozen trial/seed policy changed')
 m=c.get('proof_model',{})
 if m.get('model')!='qwen3.8-flash' or m.get('api_key_env')!='DASHSCOPE_API_KEY':raise ConfigError('wrong model/credential source')
 if m.get('endpoint')!='https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions' or m.get('temperature')!=0.2 or m.get('enable_thinking') is not False:raise ConfigError('frozen model policy changed')
def load_config(p:Path):c=load_yaml(p.resolve());validate_config(c);return c
