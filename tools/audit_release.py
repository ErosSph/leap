"""Scan Git-visible source files without printing possible secret values."""
from __future__ import annotations

import json
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PATTERNS = {
    'provider_key': re.compile(rb'\bsk-[A-Za-z0-9_.-]{16,}'),
    'github_token': re.compile(rb'\b(?:gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{30,})'),
    'aws_access_key': re.compile(rb'\bAKIA[0-9A-Z]{16}\b'),
    'private_key': re.compile(rb'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----'),
    'private_workspace': re.compile(rb'/data[0-9]?/home/[^/\s]+/'),
    'credential_in_url': re.compile(rb'https?://[^\s/]+:[^\s/@]+@'),
}


def main():
    raw = subprocess.check_output(['git', 'ls-files', '--cached', '--others', '--exclude-standard', '-z'], cwd=ROOT)
    names = sorted(set(p.decode() for p in raw.split(b'\0') if p))
    issues = []
    size = 0
    for name in names:
        path = ROOT / name
        if not path.is_file():
            continue
        data = path.read_bytes()
        size += len(data)
        if re.search(r'requirement\d', path.name, re.I) and path.suffix == '.py':
            issues.append({'path': name, 'kind': 'numbered_python_filename'})
        for label, pattern in PATTERNS.items():
            if pattern.search(data):
                issues.append({'path': name, 'kind': label})
    print(json.dumps({'files_checked': len(names), 'bytes': size, 'issues': issues}, indent=2))
    if issues:
        raise SystemExit(1)


if __name__ == '__main__':
    main()
