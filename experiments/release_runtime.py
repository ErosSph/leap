"""Portable, environment-only API and corpus configuration for the benchmark."""
from __future__ import annotations

import argparse
import concurrent.futures
import json
import os
import re
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

from .corpus_check import PROJECT, BUILD, build_model, load_manifest

API = {}


def redact(text: str) -> str:
    value = os.environ.get(API.get('api_key_env', 'LLM_API_KEY'), '')
    if value:
        text = text.replace(value, '[REDACTED]')
    return re.sub(r'sk-[A-Za-z0-9_.-]{8,}', '[REDACTED]', text)


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        raise urllib.error.HTTPError(req.full_url, code, 'API redirects are disabled', headers, fp)


def request(url, env, payload, timeout=300):
    key = os.environ.get(env)
    if not key:
        return {'status': 'MISSING_CREDENTIAL', 'credential_env': env}
    start = time.perf_counter()
    req = urllib.request.Request(url, data=json.dumps(payload).encode(), headers={
        'Authorization': 'Bearer ' + key, 'Content-Type': 'application/json'})
    try:
        with urllib.request.build_opener(NoRedirect()).open(req, timeout=timeout) as response:
            # Responses may echo inputs; scrub before writing any response log.
            body = json.loads(redact(response.read().decode()))
        return {'status': 'OK', 'body': body, 'elapsed_s': time.perf_counter() - start}
    except urllib.error.HTTPError as error:
        return {'status': 'HTTP_ERROR', 'http_status': error.code,
                'error': 'Provider rejected request; response body omitted for privacy',
                'elapsed_s': time.perf_counter() - start}
    except Exception as error:
        return {'status': 'TRANSPORT_ERROR', 'error': type(error).__name__,
                'elapsed_s': time.perf_counter() - start}


def generate(model, prompt, config):
    payload = {'model': model, 'messages': [
        {'role': 'system', 'content': 'Prove Lean 4 theorems. Return JSON containing proof_body (starting with by) and proof_idea. No sorry, admit, axiom, unsafe, native_decide, run_tac, IO, or external tools.'},
        {'role': 'user', 'content': prompt}],
        'response_format': {'type': 'json_object'}, 'max_tokens': config['max_tokens'],
        'temperature': config['temperature'], 'stream': False}
    if API.get('disable_thinking'):
        payload['enable_thinking'] = False
    return request(API['base_url'].rstrip('/') + '/chat/completions', API['api_key_env'], payload,
                   API['timeout'])


def model_directory(dut):
    return BUILD / dut


def prepare(root, config):
    manifest = load_manifest()
    target = root / 'proofs'
    target.mkdir(parents=True, exist_ok=True)
    (target / 'manifest.json').write_text(json.dumps(manifest, indent=2))
    (target / 'config.json').write_text(json.dumps(config, indent=2))
    return manifest


def main(runner):
    parser = argparse.ArgumentParser(description='Frozen 177-task graph-guided / direct proof benchmark')
    parser.add_argument('--model', default=os.environ.get('LLM_MODEL'))
    parser.add_argument('--base-url', default=os.environ.get('LLM_BASE_URL'))
    parser.add_argument('--api-key-env', default='LLM_API_KEY')
    parser.add_argument('--arm', choices=['full', 'direct', 'both'], default='full')
    parser.add_argument('--dut', nargs='+', help='Design slugs; default: all')
    parser.add_argument('--limit', type=int, help='Limit tasks per design for smoke testing')
    parser.add_argument('--max-attempts', type=int, choices=range(1,6), default=5)
    parser.add_argument('--max-tokens', type=int, default=4096)
    parser.add_argument('--workers', type=int, default=1)
    parser.add_argument('--timeout', type=int, default=300, help='API request timeout in seconds')
    parser.add_argument('--lean-timeout', type=int, default=120)
    parser.add_argument('--disable-thinking', action='store_true', help='Send provider-specific enable_thinking=false')
    parser.add_argument('--output', type=Path, default=PROJECT / 'results' / time.strftime('%Y%m%dT%H%M%S'))
    args = parser.parse_args()
    if not args.model or not args.base_url:
        parser.error('Set --model and --base-url (or LLM_MODEL and LLM_BASE_URL)')
    if not re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9_.-]*', args.model) or '..' in args.model:
        parser.error('Model identifier must be a simple provider model ID without path separators')
    url = urllib.parse.urlsplit(args.base_url)
    if url.scheme != 'https' or not url.netloc or url.username or url.password or url.query or url.fragment:
        parser.error('--base-url must be an HTTPS URL without embedded credentials, query, or fragment')
    if not os.environ.get(args.api_key_env):
        parser.error('Missing credential environment variable: ' + args.api_key_env)
    if args.workers < 1 or args.max_tokens < 1 or (args.limit is not None and args.limit < 1):
        parser.error('workers, max-tokens and limit must be positive')
    # A new directory prevents accidental cross-configuration cache reuse.
    runner.ROOT = args.output.resolve()
    if runner.ROOT.exists() and any(runner.ROOT.iterdir()):
        parser.error('Choose an empty --output directory; completed runs are never overwritten')
    manifest = load_manifest()
    duts = args.dut or list(manifest['properties_per_dut'])
    if not set(duts) <= set(manifest['properties_per_dut']):
        parser.error('Unknown design slug')
    API.update(base_url=args.base_url, api_key_env=args.api_key_env,
               timeout=args.timeout, disable_thinking=args.disable_thinking)
    runner.MODELS = [args.model]
    runner.CONFIG.update(max_attempts=args.max_attempts, max_tokens=args.max_tokens,
                         lean_timeout_s=args.lean_timeout,
                         thinking_control='disabled' if args.disable_thinking else 'provider_default')
    for dut in duts:
        build_model(dut)
    runner.prepare()
    arms = ['full', 'direct'] if args.arm == 'both' else [args.arm]
    started = time.perf_counter()
    with concurrent.futures.ThreadPoolExecutor(max_workers=args.workers) as executor:
        jobs = []
        for arm in arms:
            for row in manifest['sources']:
                if row['dut'] not in duts:
                    continue
                tasks = [t for t in manifest['tasks'] if t['dut'] == row['dut']]
                if args.limit:
                    tasks = tasks[:args.limit]
                jobs.append(executor.submit(runner.run_design, args.model, arm, row, tasks))
        for job in concurrent.futures.as_completed(jobs):
            job.result()
            runner.summarize()
    record = {'wall_s': time.perf_counter() - started, 'model': args.model,
              'base_url': args.base_url, 'api_key_env': args.api_key_env,
              'arms': arms, 'duts': duts, 'limit_per_design': args.limit, 'config': runner.CONFIG}
    (runner.ROOT / 'proofs/execution.json').write_text(json.dumps(record, indent=2))
    print('Results:', runner.ROOT / 'proofs/summary.json')
