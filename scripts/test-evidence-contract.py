#!/usr/bin/env python3
"""Regression-test the GoldenPath Evidence Manifest contract and fail-closed semantics."""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VALIDATOR = ROOT / "scripts" / "validate-evidence-manifest.py"
SCHEMA = ROOT / "platform-assurance" / "evidence" / "schema" / "goldenpath-evidence-v1.schema.json"
FIXTURES = ROOT / "platform-assurance" / "evidence" / "fixtures"

CASES = {
    "valid-reference.json": 0,
    "valid-runtime.json": 0,
    "valid-risk-adaptive.json": 0,
    "invalid-required-gate-ready.json": 1,
    "invalid-runtime-without-proof.json": 1,
    "invalid-skip-not-allowed.json": 1,
    "invalid-source-drift.json": 1,
    "invalid-risk-missing-gate.json": 1,
}


def check_schema_contract() -> None:
    schema = json.loads(SCHEMA.read_text(encoding="utf-8"))
    if schema.get("$schema") != "https://json-schema.org/draft/2020-12/schema":
        raise RuntimeError("Evidence schema must declare JSON Schema draft 2020-12")
    if schema.get("properties", {}).get("schemaVersion", {}).get("const") != "goldenpath.evidence/v1":
        raise RuntimeError("Evidence schema version does not match goldenpath.evidence/v1")

    gate_results = (
        schema.get("$defs", {})
        .get("gateEvidence", {})
        .get("properties", {})
        .get("result", {})
        .get("enum", [])
    )
    expected = {"PASS", "FAIL", "INFRASTRUCTURE_FAILURE", "SKIP_ALLOWED"}
    if set(gate_results) != expected:
        raise RuntimeError(f"Gate result taxonomy drifted: expected {sorted(expected)}, got {gate_results}")

    assurance_version = (
        schema.get("$defs", {})
        .get("assuranceSnapshot", {})
        .get("properties", {})
        .get("schemaVersion", {})
        .get("const")
    )
    if assurance_version != "goldenpath.assurance/v1":
        raise RuntimeError("Evidence schema must bind goldenpath.assurance/v1")


def run_case(filename: str, expected_status: int) -> None:
    command = [sys.executable, str(VALIDATOR), str(FIXTURES / filename)]
    result = subprocess.run(command, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    actual = 0 if result.returncode == 0 else 1
    if actual != expected_status:
        raise RuntimeError(
            f"{filename}: expected normalized exit {expected_status}, got {result.returncode}\n"
            f"stdout:\n{result.stdout}\nstderr:\n{result.stderr}"
        )


def check_expected_commit_invalidation() -> None:
    manifest = FIXTURES / "valid-reference.json"
    valid_sha = "1111111111111111111111111111111111111111"
    stale_sha = "9999999999999999999999999999999999999999"

    fresh = subprocess.run(
        [sys.executable, str(VALIDATOR), str(manifest), "--expected-commit", valid_sha],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    if fresh.returncode != 0:
        raise RuntimeError(f"Expected-commit positive test failed: {fresh.stderr}")

    stale = subprocess.run(
        [sys.executable, str(VALIDATOR), str(manifest), "--expected-commit", stale_sha],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    if stale.returncode == 0:
        raise RuntimeError("Stale evidence unexpectedly passed --expected-commit validation")


def main() -> int:
    check_schema_contract()
    for filename, expected_status in CASES.items():
        run_case(filename, expected_status)
    check_expected_commit_invalidation()
    print(f"PASS: evidence contract regression suite ({len(CASES)} fixtures + stale-commit check)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
