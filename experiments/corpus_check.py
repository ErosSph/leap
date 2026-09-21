"""Offline rebuild and replay of the released, fixed 177-theorem corpus."""
from __future__ import annotations

import argparse
import concurrent.futures
import hashlib
import json
import os
import re
import shutil
import subprocess
import time
from pathlib import Path

from rtl2lean.pipeline.compiler import find_lean

PROJECT = Path(__file__).resolve().parents[1]
BUILD = PROJECT / '.build' / 'models'
MODULES = ('Model', 'Foundation', 'Framework', 'R16Support', 'R17Support')


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def load_manifest() -> dict:
    manifest = json.loads((PROJECT / 'theorems/tasks.json').read_text())
    tasks = manifest['tasks']
    if len(tasks) != 177 or len({t['task_id'] for t in tasks}) != 177:
        raise ValueError('Expected 177 unique frozen theorem tasks')
    for t in tasks:
        if hashlib.sha256(t['statement'].encode()).hexdigest() != t['statement_sha256']:
            raise ValueError('Changed theorem statement: ' + t['task_id'])
    expected = manifest['properties_per_dut']
    if {d: sum(t['dut'] == d for t in tasks) for d in expected} != expected:
        raise ValueError('Per-design task counts do not match')
    for name, sha in json.loads((PROJECT / 'theorems/source_hashes.json').read_text()).items():
        if digest(PROJECT / name) != sha:
            raise ValueError('Changed frozen source: ' + name)
    for row in manifest['sources']:
        for module, field in [('R16Support.lean', 'support_sha256'),
                              ('R17Support.lean', 'hard_support_sha256')]:
            if digest(PROJECT / row['model_dir'] / module) != row[field]:
                raise ValueError('Context differs from the original manifest: ' + row['dut'])
    return manifest


def lean_version() -> str:
    version = subprocess.check_output([find_lean(), '--version'], text=True).strip()
    if not re.search(r'\b4\.26\.0\b', version):
        raise RuntimeError('This corpus requires Lean 4.26.0; found ' + version)
    return version


def safe_environment(model_dir: Path) -> dict:
    # Lean compilation does not need API credentials.
    env = {k: v for k, v in os.environ.items()
           if not any(s in k.upper() for s in ('API_KEY', 'TOKEN', 'SECRET', 'PASSWORD'))}
    env['LEAN_PATH'] = str(model_dir)
    return env


def compile_file(path: Path, model_dir: Path, timeout: int, emit: bool = False) -> dict:
    command = [find_lean(), '-s', '65536']
    if emit:
        command += ['-o', str(path.with_suffix('.olean'))]
    command.append(str(path))
    start = time.perf_counter()
    try:
        p = subprocess.run(command, cwd=path.parent, env=safe_environment(model_dir),
                           capture_output=True, text=True, timeout=timeout)
        output = p.stdout + p.stderr
        ok = p.returncode == 0 and 'sorryAx' not in output and "declaration uses 'sorry'" not in output
        return {'success': ok, 'elapsed_s': time.perf_counter() - start,
                'returncode': p.returncode, 'diagnostics': output[-12000:]}
    except subprocess.TimeoutExpired:
        return {'success': False, 'elapsed_s': time.perf_counter() - start,
                'returncode': 124, 'diagnostics': 'Lean compilation timeout'}


def build_model(dut: str, timeout: int = 1800, fresh: bool = False) -> Path:
    source = PROJECT / 'theorems/models' / dut
    if not source.is_dir():
        raise ValueError('Unknown design: ' + dut)
    destination = BUILD / dut
    destination.mkdir(parents=True, exist_ok=True)
    stamp = destination / 'build.json'
    identity = {'lean': lean_version(), 'sources': {p.name: digest(p) for p in source.glob('*.lean')}}
    old = json.loads(stamp.read_text()) if stamp.exists() else {}
    products = all((destination / (m + '.olean')).exists() for m in MODULES)
    if not fresh and old.get('identity') == identity and old.get('success') and products:
        return destination
    rows = []
    for module in MODULES:
        target = destination / (module + '.lean')
        shutil.copy2(source / target.name, target)
        result = compile_file(target, destination, timeout, emit=True)
        rows.append({'module': module, **result})
        print(f'build {dut}/{module}: {"PASS" if result["success"] else "FAIL"} ({result["elapsed_s"]:.2f}s)', flush=True)
        stamp.write_text(json.dumps({'identity': identity, 'success': False, 'modules': rows}, indent=2))
        if not result['success']:
            raise RuntimeError(f'Cannot build {dut}/{module}: {result["diagnostics"]}')
    stamp.write_text(json.dumps({'identity': identity, 'success': True, 'modules': rows}, indent=2))
    return destination


def check_design(dut: str, tasks: list[dict], timeout: int, fresh: bool, build_only: bool) -> dict:
    directory = build_model(dut, timeout, fresh)
    rows = []
    if not build_only:
        for task in tasks:
            name = task['task_id']
            source = PROJECT / 'theorems/reference' / dut / (name + '.lean')
            text = source.read_text()
            if re.search(r'\b(sorry|admit|axiom|native_decide|unsafe)\b', text):
                raise ValueError('Unchecked reference proof: ' + name)
            # Checking the reported axioms makes the reference gate explicit.
            target = directory / (name + '.lean')
            target.write_text(text + f'\n#print axioms {task["module"]}Verification.{name}\n')
            result = compile_file(target, directory, timeout)
            rows.append({'task_id': name, **result})
            print(f'check {dut}/{name}: {"PASS" if result["success"] else "FAIL"}', flush=True)
    return {'dut': dut, 'built': True, 'checked': len(rows),
            'passed': sum(r['success'] for r in rows), 'results': rows}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--dut', nargs='+', help='Design slugs (default: all seven)')
    parser.add_argument('--workers', type=int, default=2)
    parser.add_argument('--timeout', type=int, default=1800, help='Seconds per Lean process')
    parser.add_argument('--fresh', action='store_true', help='Rebuild even if sources and toolchain match')
    parser.add_argument('--build-only', action='store_true')
    parser.add_argument('--manifest-only', action='store_true', help='Check counts and hashes without Lean')
    args = parser.parse_args()
    manifest = load_manifest()
    if args.manifest_only:
        print(json.dumps({'theorems': len(manifest['tasks']), 'per_design': manifest['properties_per_dut'], 'hashes': 'PASS'}, indent=2))
        return
    duts = args.dut or list(manifest['properties_per_dut'])
    if not set(duts) <= set(manifest['properties_per_dut']):
        parser.error('Unknown design slug')
    rows = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=args.workers) as pool:
        jobs = [pool.submit(check_design, d, [t for t in manifest['tasks'] if t['dut'] == d],
                            args.timeout, args.fresh, args.build_only) for d in duts]
        for job in concurrent.futures.as_completed(jobs):
            rows.append(job.result())
    result = {'lean': lean_version(), 'designs': rows,
              'checked': sum(r['checked'] for r in rows), 'passed': sum(r['passed'] for r in rows)}
    path = PROJECT / '.build/reference_check.json'
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(result, indent=2))
    print(f'Reference proofs: {result["passed"]}/{result["checked"]}; report: {path}')
    if result['passed'] != result['checked']:
        raise SystemExit(1)


if __name__ == '__main__':
    main()
