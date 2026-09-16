#!/usr/bin/env python3
"""Detect repository domains changed between two Git revisions."""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

DOMAINS = ("docs", "terraform", "gitops", "policies", "templates")


def all_domains() -> dict[str, bool]:
    return {domain: True for domain in DOMAINS}


def changed_files(base: str, head: str) -> list[str]:
    if not base or set(base) == {"0"}:
        return [".github/workflows/repository-validation.yaml"]
    result = subprocess.run(
        ["git", "diff", "--name-only", f"{base}..{head}"],
        check=True,
        text=True,
        stdout=subprocess.PIPE,
    )
    return [line.strip() for line in result.stdout.splitlines() if line.strip()]


def classify(paths: list[str]) -> dict[str, bool]:
    flags = {domain: False for domain in DOMAINS}
    for raw_path in paths:
        path = Path(raw_path)
        normalized = path.as_posix()

        if normalized == ".github/workflows/repository-validation.yaml" or normalized.startswith("scripts/"):
            return all_domains()

        if path.suffix.lower() == ".md" or normalized.startswith("docs/"):
            flags["docs"] = True
        if normalized.startswith("terraform-modules/") or normalized.startswith("platform-stacks/"):
            flags["terraform"] = True
        if normalized.startswith("gitops-config/"):
            flags["gitops"] = True
        if normalized.startswith("platform-policies/") or normalized.startswith("gitops-config/policies/"):
            flags["policies"] = True
        if normalized.startswith("service-templates/"):
            flags["templates"] = True

    return flags


def main() -> int:
    if len(sys.argv) != 3:
        print("Usage: detect-ci-domains.py <base-sha> <head-sha>", file=sys.stderr)
        return 2

    try:
        paths = changed_files(sys.argv[1], sys.argv[2])
    except subprocess.CalledProcessError as exc:
        print(f"ERROR: unable to calculate changed paths: {exc}", file=sys.stderr)
        return 1

    flags = classify(paths)
    for domain in DOMAINS:
        print(f"{domain}={'true' if flags[domain] else 'false'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
