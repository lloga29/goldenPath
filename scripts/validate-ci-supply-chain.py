#!/usr/bin/env python3
"""Validate supply-chain invariants for active repository-root GitHub Actions workflows."""

from __future__ import annotations

import re
import sys
from pathlib import Path

WORKFLOW_DIR = Path('.github/workflows')
ACTION_SHA_RE = re.compile(r'^[0-9a-fA-F]{40}$')
DOCKER_DIGEST_RE = re.compile(r'^docker://[^@\s]+@sha256:[0-9a-fA-F]{64}$')
USES_RE = re.compile(r'^\s*(?:-\s*)?uses:\s*([^#\s]+)')
RUN_RE = re.compile(r'^(\s*)(?:-\s*)?run:\s*[|>]')
RUNNER_LATEST_RE = re.compile(r'^\s*runs-on:\s*[^#\n]*latest\b', re.IGNORECASE)
DOWNLOAD_RE = re.compile(r'\b(?:curl|wget)\b')
VERIFY_RE = re.compile(r'\bsha256sum\s+-c\b')
CONSUME_RE = re.compile(r'\b(?:tar\s+[^\n]*-[^\n]*x|unzip\b|install\b|chmod\s+\+x\b)')


def error(errors: list[str], path: Path, line_no: int, message: str) -> None:
    errors.append(f'{path}:{line_no}: {message}')


def collect_run_blocks(lines: list[str]) -> list[tuple[int, list[tuple[int, str]]]]:
    blocks: list[tuple[int, list[tuple[int, str]]]] = []
    index = 0
    while index < len(lines):
        match = RUN_RE.match(lines[index])
        if not match:
            index += 1
            continue
        base_indent = len(match.group(1).replace('\t', '    '))
        start = index + 1
        body: list[tuple[int, str]] = []
        index += 1
        while index < len(lines):
            raw = lines[index]
            if raw.strip():
                indent = len(raw) - len(raw.lstrip(' '))
                if indent <= base_indent:
                    break
            body.append((index + 1, raw))
            index += 1
        blocks.append((start, body))
    return blocks


def validate_workflow(path: Path) -> tuple[list[str], int, int]:
    errors: list[str] = []
    text = path.read_text(encoding='utf-8')
    lines = text.splitlines()
    action_refs = 0
    verified_download_blocks = 0

    for line_no, line in enumerate(lines, start=1):
        if RUNNER_LATEST_RE.match(line):
            error(errors, path, line_no, 'hosted runner must use an explicit OS label, not *-latest')

        match = USES_RE.match(line)
        if not match:
            continue
        action_refs += 1
        ref = match.group(1)
        if ref.startswith('./'):
            continue
        if ref.startswith('docker://'):
            if not DOCKER_DIGEST_RE.fullmatch(ref):
                error(errors, path, line_no, 'docker action must be pinned by sha256 digest')
            continue
        if '@' not in ref:
            error(errors, path, line_no, 'external action reference must contain @<commit-sha>')
            continue
        _, revision = ref.rsplit('@', 1)
        if not ACTION_SHA_RE.fullmatch(revision):
            error(errors, path, line_no, 'external action must be pinned to a full 40-character commit SHA')

    for _, body in collect_run_blocks(lines):
        body_text = '\n'.join(line for _, line in body)
        if not DOWNLOAD_RE.search(body_text):
            continue
        download_lines = [line_no for line_no, line in body if DOWNLOAD_RE.search(line)]
        verification_lines = [line_no for line_no, line in body if VERIFY_RE.search(line)]
        if not verification_lines:
            error(errors, path, download_lines[0], 'curl/wget tool download block must verify SHA-256 before use')
            continue
        first_verify = min(verification_lines)
        consumers = [line_no for line_no, line in body if CONSUME_RE.search(line)]
        if consumers and first_verify > min(consumers):
            error(errors, path, first_verify, 'SHA-256 verification must occur before archive extraction or installation')
            continue
        verified_download_blocks += 1

    return errors, action_refs, verified_download_blocks


def main() -> int:
    workflows = sorted((*WORKFLOW_DIR.glob('*.yaml'), *WORKFLOW_DIR.glob('*.yml')))
    if not workflows:
        print('ERROR: no active root workflows found', file=sys.stderr)
        return 1

    all_errors: list[str] = []
    total_actions = 0
    total_verified_downloads = 0
    for workflow in workflows:
        errors, actions, downloads = validate_workflow(workflow)
        all_errors.extend(errors)
        total_actions += actions
        total_verified_downloads += downloads

    if all_errors:
        for item in all_errors:
            print(f'ERROR: {item}', file=sys.stderr)
        return 1

    print(
        'CI supply-chain contract passed: '
        f'{len(workflows)} workflow(s), {total_actions} action reference(s), '
        f'{total_verified_downloads} verified download block(s).'
    )
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
