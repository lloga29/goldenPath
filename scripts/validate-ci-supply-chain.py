#!/usr/bin/env python3
"""Validate supply-chain invariants for active repository-root GitHub Actions workflows."""

from __future__ import annotations

import re
import shlex
import sys
from pathlib import Path

WORKFLOW_DIR = Path('.github/workflows')
REQUIREMENTS_DIR = Path('.github/requirements')
ACTION_SHA_RE = re.compile(r'^[0-9a-fA-F]{40}$')
DOCKER_DIGEST_RE = re.compile(r'^docker://[^@\s]+@sha256:[0-9a-fA-F]{64}$')
USES_RE = re.compile(r'^\s*(?:-\s*)?uses:\s*([^#\s]+)')
RUN_BLOCK_RE = re.compile(r'^(\s*)(?:-\s*)?run:\s*[|>]\s*$')
RUN_INLINE_RE = re.compile(r'^\s*(?:-\s*)?run:\s*(.+?)\s*$')
RUNNER_LATEST_RE = re.compile(r'^\s*runs-on:\s*[^#\n]*latest\b', re.IGNORECASE)
DOWNLOAD_RE = re.compile(r'\b(?:curl|wget)\b')
VERIFY_RE = re.compile(r'\bsha256sum\s+-c\b')
CONSUME_RE = re.compile(r'\b(?:tar\s+[^\n]*-[^\n]*x|unzip\b|install\b|chmod\s+\+x\b)')
PIP_INSTALL_RE = re.compile(r'\b(?:python\d*(?:\.\d+)?\s+-m\s+)?pip(?:\d*(?:\.\d+)?)?\s+install\b')
LOCK_LINE_RE = re.compile(r'^[A-Za-z0-9_.-]+==[^\s]+\s+--hash=sha256:[0-9a-fA-F]{64}$')


def error(errors: list[str], path: Path, line_no: int, message: str) -> None:
    errors.append(f'{path}:{line_no}: {message}')


def collect_run_commands(lines: list[str]) -> list[tuple[int, str]]:
    commands: list[tuple[int, str]] = []
    index = 0
    while index < len(lines):
        raw = lines[index]
        block = RUN_BLOCK_RE.match(raw)
        if block:
            base_indent = len(block.group(1).replace('\t', '    '))
            start_line = index + 1
            body: list[str] = []
            index += 1
            while index < len(lines):
                candidate = lines[index]
                if candidate.strip():
                    indent = len(candidate) - len(candidate.lstrip(' '))
                    if indent <= base_indent:
                        break
                body.append(candidate)
                index += 1
            commands.append((start_line, '\n'.join(body)))
            continue

        inline = RUN_INLINE_RE.match(raw)
        if inline:
            commands.append((index + 1, inline.group(1)))
        index += 1
    return commands


def requirement_path(command: str) -> str | None:
    try:
        tokens = shlex.split(command.replace('\\\n', ' '))
    except ValueError:
        return None
    for index, token in enumerate(tokens):
        if token in {'-r', '--requirement'} and index + 1 < len(tokens):
            return tokens[index + 1]
        if token.startswith('--requirement='):
            return token.split('=', 1)[1]
        if token.startswith('-r') and token != '-r':
            return token[2:]
    return None


def validate_lock_file(path: Path, errors: list[str]) -> int:
    if not path.is_file():
        errors.append(f'{path}: referenced requirement lock does not exist')
        return 0
    entries = 0
    for line_no, raw in enumerate(path.read_text(encoding='utf-8').splitlines(), start=1):
        line = raw.strip()
        if not line or line.startswith('#'):
            continue
        entries += 1
        if not LOCK_LINE_RE.fullmatch(line):
            error(errors, path, line_no, 'lock entry must be exact package==version plus one SHA-256 hash')
    if entries == 0:
        errors.append(f'{path}: requirement lock contains no package entries')
    return entries


def validate_workflow(path: Path) -> tuple[list[str], int, int, int, set[Path]]:
    errors: list[str] = []
    text = path.read_text(encoding='utf-8')
    lines = text.splitlines()
    action_refs = 0
    verified_download_blocks = 0
    hash_locked_pip_blocks = 0
    referenced_locks: set[Path] = set()

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

    for line_no, command in collect_run_commands(lines):
        if DOWNLOAD_RE.search(command):
            verification = VERIFY_RE.search(command)
            if not verification:
                error(errors, path, line_no, 'curl/wget tool download block must verify SHA-256 before use')
            else:
                consumer = CONSUME_RE.search(command)
                if consumer and verification.start() > consumer.start():
                    error(errors, path, line_no, 'SHA-256 verification must occur before archive extraction or installation')
                else:
                    verified_download_blocks += 1

        if PIP_INSTALL_RE.search(command):
            if '--require-hashes' not in command:
                error(errors, path, line_no, 'pip install must use --require-hashes')
                continue
            requirement = requirement_path(command)
            if not requirement:
                error(errors, path, line_no, 'hash-locked pip install must use a committed requirement file')
                continue
            lock_path = Path(requirement)
            try:
                lock_path.relative_to(REQUIREMENTS_DIR)
            except ValueError:
                error(errors, path, line_no, f'pip requirement file must live under {REQUIREMENTS_DIR}')
                continue
            if lock_path.suffix != '.lock':
                error(errors, path, line_no, 'pip requirement file must use the .lock suffix')
                continue
            referenced_locks.add(lock_path)
            hash_locked_pip_blocks += 1

    return errors, action_refs, verified_download_blocks, hash_locked_pip_blocks, referenced_locks


def main() -> int:
    workflows = sorted((*WORKFLOW_DIR.glob('*.yaml'), *WORKFLOW_DIR.glob('*.yml')))
    if not workflows:
        print('ERROR: no active root workflows found', file=sys.stderr)
        return 1

    all_errors: list[str] = []
    total_actions = 0
    total_verified_downloads = 0
    total_pip_blocks = 0
    referenced_locks: set[Path] = set()

    for workflow in workflows:
        errors, actions, downloads, pip_blocks, locks = validate_workflow(workflow)
        all_errors.extend(errors)
        total_actions += actions
        total_verified_downloads += downloads
        total_pip_blocks += pip_blocks
        referenced_locks.update(locks)

    committed_locks = set(REQUIREMENTS_DIR.glob('*.lock')) if REQUIREMENTS_DIR.is_dir() else set()
    if not committed_locks:
        all_errors.append(f'{REQUIREMENTS_DIR}: no committed CI requirement locks found')

    unreferenced_locks = committed_locks - referenced_locks
    for lock in sorted(unreferenced_locks):
        all_errors.append(f'{lock}: committed CI lock is not referenced by an active root workflow')

    total_lock_entries = 0
    for lock in sorted(referenced_locks):
        total_lock_entries += validate_lock_file(lock, all_errors)

    if all_errors:
        for item in all_errors:
            print(f'ERROR: {item}', file=sys.stderr)
        return 1

    print(
        'CI supply-chain contract passed: '
        f'{len(workflows)} workflow(s), {total_actions} action reference(s), '
        f'{total_verified_downloads} verified download block(s), '
        f'{total_pip_blocks} hash-locked pip install block(s), '
        f'{total_lock_entries} hashed requirement entry/entries.'
    )
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
