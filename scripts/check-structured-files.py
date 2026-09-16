#!/usr/bin/env python3
"""Validate repository YAML and JSON syntax."""

from __future__ import annotations

import json
import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[1]
SKIP_PARTS = {".git", ".terraform"}


def should_skip(path: Path) -> bool:
    return any(part in SKIP_PARTS for part in path.parts)


def main() -> int:
    failures: list[str] = []

    for path in sorted(ROOT.rglob("*")):
        if not path.is_file() or should_skip(path):
            continue
        relative = path.relative_to(ROOT)
        try:
            if path.suffix.lower() in {".yaml", ".yml"}:
                with path.open(encoding="utf-8") as handle:
                    list(yaml.safe_load_all(handle))
            elif path.suffix.lower() == ".json":
                with path.open(encoding="utf-8") as handle:
                    json.load(handle)
            else:
                continue
        except (OSError, UnicodeError, ValueError, yaml.YAMLError) as exc:
            failures.append(f"{relative}: {exc}")

    if failures:
        print("Structured-file validation failed:", file=sys.stderr)
        for failure in failures:
            print(f"  {failure}", file=sys.stderr)
        return 1

    print("YAML and JSON syntax validation passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
