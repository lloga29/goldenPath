#!/usr/bin/env python3
"""Validate and compile the governed policy exception registry fail closed."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import re
import sys
from pathlib import Path

import yaml

POLICY_TARGETS = {
    "kubernetes.images.immutable": "kubernetes",
    "kubernetes.labels.required": "kubernetes",
    "kubernetes.resources.required": "kubernetes",
    "kubernetes.security.context": "kubernetes",
    "kubernetes.workload.isolation": "kubernetes",
    "terraform.public_access": "terraform",
    "terraform.iam.no_wildcards": "terraform",
    "terraform.encryption.required": "terraform",
    "terraform.tags.required": "terraform",
}
KUBERNETES_POLICY_KINDS = {
    "kubernetes.images.immutable": {"pod", "deployment", "statefulset", "daemonset", "job", "cronjob"},
    "kubernetes.labels.required": {"pod", "deployment", "statefulset", "daemonset", "service", "ingress", "job", "cronjob"},
    "kubernetes.resources.required": {"pod", "deployment", "statefulset", "daemonset", "job", "cronjob"},
    "kubernetes.security.context": {"pod", "deployment", "statefulset", "daemonset", "job", "cronjob"},
    "kubernetes.workload.isolation": {"pod", "deployment", "statefulset", "daemonset", "job", "cronjob"},
}
REQUIRED_TOP_LEVEL = {"version", "enforcement", "exceptions"}
ALLOWED_TOP_LEVEL = REQUIRED_TOP_LEVEL
BASE_EXCEPTION_FIELDS = {
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
ALLOWED_EXCEPTION_FIELDS = BASE_EXCEPTION_FIELDS | {"namespace"}
EMAIL_RE = re.compile(r"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$")
ID_RE = re.compile(r"^EXC-[0-9]{4}-[0-9]{3,}$")
K8S_NAME_RE = re.compile(r"^[a-z0-9](?:[-a-z0-9.]*[a-z0-9])?$")
K8S_NAMESPACE_RE = re.compile(r"^[a-z0-9](?:[-a-z0-9]*[a-z0-9])?$")


def fail(message: str) -> None:
    raise ValueError(message)


def parse_date(value: object, field: str, exception_id: str) -> dt.date:
    if not isinstance(value, str):
        fail(f"{exception_id}: {field} must be an ISO-8601 date string")
    try:
        return dt.date.fromisoformat(value)
    except ValueError as exc:
        raise ValueError(f"{exception_id}: {field} must use YYYY-MM-DD") from exc


def non_empty_string(exception: dict[str, object], field: str, exception_id: str) -> str:
    value = exception[field]
    if not isinstance(value, str) or not value.strip():
        fail(f"{exception_id}: {field} must be a non-empty string")
    return value.strip()


def validate_kubernetes_scope(exception: dict[str, object], exception_id: str, policy: str) -> None:
    namespace = exception.get("namespace")
    if not isinstance(namespace, str) or not K8S_NAMESPACE_RE.fullmatch(namespace):
        fail(f"{exception_id}: Kubernetes exceptions require a valid namespace")

    resource = non_empty_string(exception, "resource", exception_id)
    parts = resource.split("/", 1)
    if len(parts) != 2:
        fail(f"{exception_id}: Kubernetes resource must use lowercase kind/name")
    kind, name = parts
    if kind not in KUBERNETES_POLICY_KINDS[policy]:
        fail(f"{exception_id}: resource kind '{kind}' is not supported by policy '{policy}'")
    if not K8S_NAME_RE.fullmatch(name):
        fail(f"{exception_id}: Kubernetes resource name is invalid")


def validate_terraform_scope(exception: dict[str, object], exception_id: str) -> None:
    if "namespace" in exception:
        fail(f"{exception_id}: Terraform exceptions must not declare namespace")
    resource = non_empty_string(exception, "resource", exception_id)
    if any(char.isspace() for char in resource) or "*" in resource or "?" in resource:
        fail(f"{exception_id}: Terraform resource must be an exact address without whitespace or wildcards")


def validate(path: Path) -> dict[str, object]:
    document = yaml.safe_load(path.read_text(encoding="utf-8"))
    if not isinstance(document, dict):
        fail("exception registry must be a YAML object")

    keys = set(document)
    missing_top = REQUIRED_TOP_LEVEL - keys
    unknown_top = keys - ALLOWED_TOP_LEVEL
    if missing_top:
        fail(f"exception registry is missing top-level fields: {sorted(missing_top)}")
    if unknown_top:
        fail(f"exception registry contains unsupported top-level fields: {sorted(unknown_top)}")
    if document.get("version") != 1:
        fail("exception registry version must be 1")

    enforcement = document.get("enforcement")
    if enforcement != {"conftest": "scoped-exceptions", "gatekeeper": "strict"}:
        fail("enforcement must be exactly conftest=scoped-exceptions and gatekeeper=strict")

    exceptions = document.get("exceptions")
    if not isinstance(exceptions, list):
        fail("exceptions must be a list")

    today = dt.date.today()
    seen_ids: set[str] = set()
    seen_scopes: set[tuple[str, str, str]] = set()
    compiled: list[dict[str, object]] = []

    for index, exception in enumerate(exceptions):
        if not isinstance(exception, dict):
            fail(f"exception at index {index} must be an object")

        fields = set(exception)
        missing = BASE_EXCEPTION_FIELDS - fields
        unknown = fields - ALLOWED_EXCEPTION_FIELDS
        if missing:
            fail(f"exception at index {index} is missing fields: {sorted(missing)}")
        if unknown:
            fail(f"exception at index {index} contains unsupported fields: {sorted(unknown)}")

        exception_id = exception["id"]
        if not isinstance(exception_id, str) or not ID_RE.fullmatch(exception_id):
            fail(f"exception at index {index}: id must match EXC-YYYY-NNN")
        if exception_id in seen_ids:
            fail(f"duplicate exception id: {exception_id}")
        seen_ids.add(exception_id)

        policy = non_empty_string(exception, "policy", exception_id)
        target = POLICY_TARGETS.get(policy)
        if target is None:
            fail(f"{exception_id}: unsupported policy identifier '{policy}'")

        for field in ("reason", "approved_by", "tracking_issue"):
            non_empty_string(exception, field, exception_id)

        owner = exception["owner"]
        if not isinstance(owner, str) or not EMAIL_RE.fullmatch(owner):
            fail(f"{exception_id}: owner must be a valid email address")

        created = parse_date(exception["created"], "created", exception_id)
        expires = parse_date(exception["expires"], "expires", exception_id)
        if created > today:
            fail(f"{exception_id}: created date cannot be in the future")
        if expires <= created:
            fail(f"{exception_id}: expires must be later than created")
        if expires < today:
            fail(f"{exception_id}: exception expired on {expires.isoformat()}")
        if exception_id.split("-")[1] != str(created.year):
            fail(f"{exception_id}: ID year must match created year {created.year}")

        if target == "kubernetes":
            validate_kubernetes_scope(exception, exception_id, policy)
            namespace = str(exception["namespace"])
        else:
            validate_terraform_scope(exception, exception_id)
            namespace = ""

        resource = str(exception["resource"])
        scope = (policy, resource, namespace)
        if scope in seen_scopes:
            fail(f"{exception_id}: duplicate active exception scope for {policy} {resource} {namespace}")
        seen_scopes.add(scope)

        compiled_exception = dict(exception)
        compiled_exception["target"] = target
        compiled.append(compiled_exception)

    return {
        "goldenpath": {
            "policy_exceptions": {
                "version": 1,
                "enforcement": enforcement,
                "exceptions": compiled,
            }
        }
    }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("registry", type=Path)
    parser.add_argument("--output", type=Path, help="Write validated Conftest data as JSON")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    try:
        compiled = validate(args.registry)
        count = len(compiled["goldenpath"]["policy_exceptions"]["exceptions"])
        if args.output:
            args.output.parent.mkdir(parents=True, exist_ok=True)
            args.output.write_text(json.dumps(compiled, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    except (OSError, ValueError, yaml.YAMLError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1
    print(f"Policy exception registry is valid: {count} active exception(s).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
