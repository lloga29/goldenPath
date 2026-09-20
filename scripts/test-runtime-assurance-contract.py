#!/usr/bin/env python3
"""Regression tests for GoldenPath v0.2 runtime assurance contracts."""

from __future__ import annotations

import hashlib
import json
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VALIDATOR = ROOT / "scripts" / "validate-runtime-assurance.py"
SCHEMA_DIR = ROOT / "platform-assurance" / "runtime" / "schema"
FIXTURES = ROOT / "platform-assurance" / "runtime" / "fixtures"
VALID_RECEIPT = FIXTURES / "valid-assurance-receipt.json"
VALID_RUNTIME = FIXTURES / "valid-runtime-evidence.json"
NOW = "2026-09-20T17:30:00Z"
EXPECTED_SOURCE = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
EXPECTED_ARTIFACT = "sha256:" + "1" * 64
EXPECTED_DESIRED = "b" * 40
EXPECTED_POLICY = "sha256:" + "4" * 64
EXPECTED_CLUSTER = "kind:goldenpath-v020-p0"


def canonical_digest(value: object) -> str:
    raw = json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode("utf-8")
    return "sha256:" + hashlib.sha256(raw).hexdigest()


def command(
    receipt: Path,
    runtime: Path | None = VALID_RUNTIME,
    now: str = NOW,
    *,
    include_expectations: bool = True,
) -> list[str]:
    args = [sys.executable, str(VALIDATOR), str(receipt), "--now", now]
    if runtime is not None:
        args.extend(["--runtime-evidence", str(runtime)])
    if include_expectations:
        args.extend([
            "--expected-source", EXPECTED_SOURCE,
            "--expected-artifact-digest", EXPECTED_ARTIFACT,
            "--expected-desired-state-revision", EXPECTED_DESIRED,
            "--expected-policy-bundle-digest", EXPECTED_POLICY,
            "--expected-cluster-identity", EXPECTED_CLUSTER,
        ])
    return args


def run_case(
    receipt: Path,
    expected_success: bool,
    *,
    runtime: Path | None = VALID_RUNTIME,
    now: str = NOW,
    expected_error: str | None = None,
    include_expectations: bool = True,
) -> subprocess.CompletedProcess[str]:
    result = subprocess.run(
        command(receipt, runtime=runtime, now=now, include_expectations=include_expectations),
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    success = result.returncode == 0
    if success != expected_success:
        raise RuntimeError(
            f"{receipt.name}: expected success={expected_success}, got {result.returncode}\n"
            f"stdout:\n{result.stdout}\nstderr:\n{result.stderr}"
        )
    if expected_error and expected_error.lower() not in result.stderr.lower():
        raise RuntimeError(
            f"{receipt.name}: expected error containing {expected_error!r}\n"
            f"stderr:\n{result.stderr}"
        )
    return result


def check_schema_contracts() -> None:
    runtime_schema = json.loads((SCHEMA_DIR / "goldenpath-runtime-evidence-v1.schema.json").read_text(encoding="utf-8"))
    receipt_schema = json.loads((SCHEMA_DIR / "goldenpath-assurance-receipt-v1.schema.json").read_text(encoding="utf-8"))
    if runtime_schema["properties"]["schemaVersion"]["const"] != "goldenpath.runtime-evidence/v1":
        raise RuntimeError("runtime schema version drift")
    if receipt_schema["properties"]["schemaVersion"]["const"] != "goldenpath.assurance-receipt/v1":
        raise RuntimeError("receipt schema version drift")


def check_static_fixtures() -> None:
    run_case(VALID_RECEIPT, True)
    run_case(FIXTURES / "invalid-receipt-missing-source.json", False, expected_error="missing required keys")
    run_case(
        FIXTURES / "invalid-receipt-source-mismatch.json",
        False,
        expected_error="source identity mismatch",
        include_expectations=False,
    )
    run_case(
        FIXTURES / "invalid-receipt-artifact-mismatch.json",
        False,
        expected_error="artifact identity mismatch",
        include_expectations=False,
    )
    run_case(
        FIXTURES / "invalid-receipt-desired-state-mismatch.json",
        False,
        expected_error="desired state identity mismatch",
        include_expectations=False,
    )
    run_case(FIXTURES / "invalid-receipt-unsupported-version.json", False, expected_error="unsupported assurance receipt schema version")
    run_case(
        FIXTURES / "invalid-receipt-production-from-lab.json",
        False,
        expected_error="claim tier identity mismatch",
        include_expectations=False,
    )
    run_case(FIXTURES / "invalid-receipt-contradictory-control.json", False, expected_error="contradicts required-control outcome")


def check_missing_runtime_evidence() -> None:
    run_case(VALID_RECEIPT, False, runtime=None, expected_error="requires --runtime-evidence")


def check_stale_runtime_evidence() -> None:
    receipt = json.loads(VALID_RECEIPT.read_text(encoding="utf-8"))
    runtime = json.loads(VALID_RUNTIME.read_text(encoding="utf-8"))
    runtime["validUntil"] = "2026-09-20T17:10:00Z"
    receipt["generatedAt"] = "2026-09-20T17:05:00Z"
    receipt["runtimeEvidence"]["digest"] = canonical_digest(runtime)
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        runtime_path = root / "stale-runtime.json"
        receipt_path = root / "stale-receipt.json"
        runtime_path.write_text(json.dumps(runtime, indent=2) + "\n", encoding="utf-8")
        receipt_path.write_text(json.dumps(receipt, indent=2) + "\n", encoding="utf-8")
        run_case(receipt_path, False, runtime=runtime_path, expected_error="runtime evidence is stale or expired")


def check_tamper_detection() -> None:
    runtime = json.loads(VALID_RUNTIME.read_text(encoding="utf-8"))
    runtime["policy"]["policyBundleDigest"] = "sha256:" + "9" * 64
    with tempfile.TemporaryDirectory() as tmp:
        path = Path(tmp) / "tampered-runtime.json"
        path.write_text(json.dumps(runtime, indent=2) + "\n", encoding="utf-8")
        run_case(VALID_RECEIPT, False, runtime=path, expected_error="runtime evidence digest mismatch", include_expectations=False)


def check_unsupported_runtime_schema() -> None:
    receipt = json.loads(VALID_RECEIPT.read_text(encoding="utf-8"))
    runtime = json.loads(VALID_RUNTIME.read_text(encoding="utf-8"))
    runtime["schemaVersion"] = "goldenpath.runtime-evidence/v99"
    receipt["runtimeEvidence"]["digest"] = canonical_digest(runtime)
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        runtime_path = root / "unsupported-runtime.json"
        receipt_path = root / "unsupported-receipt.json"
        runtime_path.write_text(json.dumps(runtime, indent=2) + "\n", encoding="utf-8")
        receipt_path.write_text(json.dumps(receipt, indent=2) + "\n", encoding="utf-8")
        run_case(
            receipt_path,
            False,
            runtime=runtime_path,
            expected_error="unsupported runtime evidence schema version",
            include_expectations=False,
        )


def main() -> int:
    check_schema_contracts()
    check_static_fixtures()
    check_missing_runtime_evidence()
    check_stale_runtime_evidence()
    check_tamper_detection()
    check_unsupported_runtime_schema()
    print(
        "PASS: v0.2 runtime assurance contracts reject missing, mismatched, stale, "
        "tampered, contradictory, unsupported, and tier-escalated evidence"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
