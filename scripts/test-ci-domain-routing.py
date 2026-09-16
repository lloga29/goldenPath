#!/usr/bin/env python3
"""Regression tests for root CI domain routing."""

from __future__ import annotations

import importlib.util
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DETECTOR = ROOT / "scripts" / "detect-ci-domains.py"

spec = importlib.util.spec_from_file_location("detect_ci_domains", DETECTOR)
if spec is None or spec.loader is None:
    raise RuntimeError(f"Unable to load {DETECTOR}")
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


def assert_flags(paths: list[str], **expected: bool) -> None:
    actual = module.classify(paths)
    for domain, value in expected.items():
        if actual[domain] != value:
            raise AssertionError(f"{paths}: expected {domain}={value}, got {actual[domain]}")


def main() -> int:
    assert_flags(
        ["terraform-modules/modules/storage/object-storage/main.tf"],
        terraform=True,
        policies=True,
    )
    assert_flags(
        ["platform-stacks/clients/client-acme/environments/prod/main.tf"],
        terraform=True,
        policies=True,
    )
    assert_flags(
        ["platform-policies/terraform/deny_public_access.rego"],
        policies=True,
        terraform=False,
    )
    assert_flags(
        ["docs/architecture/overview.md"],
        docs=True,
        terraform=False,
        policies=False,
    )
    assert_flags(
        ["service-templates/go-service/template/Dockerfile"],
        templates=True,
        policies=False,
    )

    all_domains = module.classify(["scripts/validate-platform-stacks.sh"])
    if not all(all_domains.values()):
        raise AssertionError(f"Root validation scripts must route every domain, got {all_domains}")

    print("CI domain routing semantics passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
