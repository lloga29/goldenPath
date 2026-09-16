#!/usr/bin/env python3
"""Regression-test the GoldenPath Evidence Manifest contract and fail-closed semantics."""

from __future__ import annotations

import hashlib
import json
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VALIDATOR = ROOT / "scripts" / "validate-evidence-manifest.py"
RISK_EVALUATOR = ROOT / "scripts" / "evaluate-risk.py"
RISK_INPUT = ROOT / "platform-assurance" / "risk" / "examples" / "r2-change.json"
SCHEMA = ROOT / "platform-assurance" / "evidence" / "schema" / "goldenpath-evidence-v1.schema.json"
FIXTURES = ROOT / "platform-assurance" / "evidence" / "fixtures"

BASE_CASES = {
    "valid-reference.json": 0,
    "valid-runtime.json": 0,
    "invalid-required-gate-ready.json": 1,
    "invalid-runtime-without-proof.json": 1,
    "invalid-skip-not-allowed.json": 1,
    "invalid-source-drift.json": 1,
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


def run_case(
    path: Path,
    expected_status: int,
    *extra_args: str,
) -> subprocess.CompletedProcess[str]:
    command = [sys.executable, str(VALIDATOR), str(path), *extra_args]
    result = subprocess.run(command, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    actual = 0 if result.returncode == 0 else 1
    if actual != expected_status:
        raise RuntimeError(
            f"{path.name}: expected normalized exit {expected_status}, got {result.returncode}\n"
            f"stdout:\n{result.stdout}\nstderr:\n{result.stderr}"
        )
    return result


def authoritative_plan_digest() -> str:
    result = subprocess.run(
        [sys.executable, str(RISK_EVALUATOR), str(RISK_INPUT)],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if result.returncode != 0:
        raise RuntimeError(f"Risk evaluator failed while deriving trusted plan digest: {result.stderr}")
    plan = json.loads(result.stdout)
    return plan["evidenceRequirements"]["planDigest"]


def check_assurance_binding() -> None:
    plan_digest = authoritative_plan_digest()
    expected_args = ("--expected-plan-digest", plan_digest)
    valid = FIXTURES / "valid-risk-adaptive.json"
    missing_gate = FIXTURES / "invalid-risk-missing-gate.json"

    run_case(valid, 1)
    run_case(valid, 0, *expected_args)
    run_case(missing_gate, 1, *expected_args)

    source = json.loads(valid.read_text(encoding="utf-8"))
    tampered = json.loads(json.dumps(source))
    tampered["assurance"]["autonomy"] = "automated"

    with tempfile.TemporaryDirectory() as tmp:
        path = Path(tmp) / "tampered.json"
        path.write_text(json.dumps(tampered, indent=2) + "\n", encoding="utf-8")
        run_case(path, 1, *expected_args)

        snapshot = dict(tampered["assurance"])
        snapshot.pop("planDigest")
        raw = json.dumps(
            snapshot,
            sort_keys=True,
            separators=(",", ":"),
            ensure_ascii=False,
        ).encode("utf-8")
        tampered["assurance"]["planDigest"] = "sha256:" + hashlib.sha256(raw).hexdigest()
        path.write_text(json.dumps(tampered, indent=2) + "\n", encoding="utf-8")
        run_case(path, 1, *expected_args)


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
    for filename, expected_status in BASE_CASES.items():
        run_case(FIXTURES / filename, expected_status)
    check_assurance_binding()
    check_expected_commit_invalidation()
    print("PASS: evidence contract regression suite with trusted assurance-plan binding")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
