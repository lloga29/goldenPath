#!/usr/bin/env python3
"""Validate the governed policy exception registry without applying bypasses."""

from __future__ import annotations

import datetime as dt
import re
import sys
from pathlib import Path

import yaml

REQUIRED_FIELDS = {
    "id",
    "policy",
    "resource",
    "reason",
    "owner",
    "approved_by",
    "tracking_issue",
    "created",
    "expires",
}
EMAIL_RE = re.compile(r"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$")
ID_RE = re.compile(r"^EXC-[0-9]{4}-[0-9]{3,}$")


def fail(message: str) -> None:
    raise ValueError(message)


def parse_date(value: object, field: str, exception_id: str) -> dt.date:
    if not isinstance(value, str):
        fail(f"{exception_id}: {field} must be an ISO-8601 date string")
    try:
        return dt.date.fromisoformat(value)
    except ValueError as exc:
        raise ValueError(f"{exception_id}: {field} must use YYYY-MM-DD") from exc


def validate(path: Path) -> None:
    document = yaml.safe_load(path.read_text(encoding="utf-8"))
    if not isinstance(document, dict):
        fail("exception registry must be a YAML object")
    if document.get("version") != 1:
        fail("exception registry version must be 1")
    if "disabled_policies" in document:
        fail("disabled_policies is not allowed; global policy bypasses are prohibited")

    exceptions = document.get("exceptions", [])
    if not isinstance(exceptions, list):
        fail("exceptions must be a list")

    excluded_namespaces = document.get("excluded_namespaces", [])
    if not isinstance(excluded_namespaces, list) or not all(isinstance(item, str) and item for item in excluded_namespaces):
        fail("excluded_namespaces must be a list of non-empty strings")

    today = dt.date.today()
    seen_ids: set[str] = set()

    for index, exception in enumerate(exceptions):
        if not isinstance(exception, dict):
            fail(f"exception at index {index} must be an object")
        missing = REQUIRED_FIELDS - set(exception)
        if missing:
            fail(f"exception at index {index} is missing fields: {sorted(missing)}")

        exception_id = exception["id"]
        if not isinstance(exception_id, str) or not ID_RE.fullmatch(exception_id):
            fail(f"exception at index {index}: id must match EXC-YYYY-NNN")
        if exception_id in seen_ids:
            fail(f"duplicate exception id: {exception_id}")
        seen_ids.add(exception_id)

        for field in ("policy", "resource", "reason", "approved_by", "tracking_issue"):
            if not isinstance(exception[field], str) or not exception[field].strip():
                fail(f"{exception_id}: {field} must be a non-empty string")

        owner = exception["owner"]
        if not isinstance(owner, str) or not EMAIL_RE.fullmatch(owner):
            fail(f"{exception_id}: owner must be a valid email address")

        created = parse_date(exception["created"], "created", exception_id)
        expires = parse_date(exception["expires"], "expires", exception_id)
        if expires <= created:
            fail(f"{exception_id}: expires must be later than created")
        if expires < today:
            fail(f"{exception_id}: exception expired on {expires.isoformat()}")

    print(f"Policy exception registry is valid: {len(exceptions)} active exception(s).")


def main() -> int:
    if len(sys.argv) != 2:
        print("Usage: validate-exceptions.py <policy-exceptions.yaml>", file=sys.stderr)
        return 2
    try:
        validate(Path(sys.argv[1]))
    except (OSError, ValueError, yaml.YAMLError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
