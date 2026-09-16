#!/usr/bin/env python3
"""Check local Markdown links without making network requests."""

from __future__ import annotations

import re
import sys
from pathlib import Path
from urllib.parse import unquote

ROOT = Path(__file__).resolve().parents[1]
LINK_RE = re.compile(r"!?\[[^\]]*\]\(([^)]+)\)")
SKIP_PREFIXES = ("http://", "https://", "mailto:", "tel:", "data:", "#")


def normalize_target(raw: str) -> str:
    target = raw.strip()
    if target.startswith("<") and target.endswith(">"):
        target = target[1:-1].strip()
    if " " in target and not target.startswith("#"):
        target = target.split(" ", 1)[0]
    target = target.split("#", 1)[0].split("?", 1)[0]
    return unquote(target)


def main() -> int:
    failures: list[str] = []

    for markdown in sorted(ROOT.rglob("*.md")):
        if ".git" in markdown.parts:
            continue
        relative_source = markdown.relative_to(ROOT)
        text = markdown.read_text(encoding="utf-8")
        for line_number, line in enumerate(text.splitlines(), start=1):
            for match in LINK_RE.finditer(line):
                raw = match.group(1).strip()
                if raw.startswith(SKIP_PREFIXES):
                    continue
                target = normalize_target(raw)
                if not target:
                    continue
                candidate = (ROOT / target.lstrip("/")) if target.startswith("/") else (markdown.parent / target)
                if not candidate.resolve().exists():
                    failures.append(f"{relative_source}:{line_number}: missing local target: {raw}")

    if failures:
        print("Markdown local-link validation failed:", file=sys.stderr)
        for failure in failures:
            print(f"  {failure}", file=sys.stderr)
        return 1

    print("Markdown local-link validation passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
