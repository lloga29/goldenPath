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
TRUSTED_CONSUMER = ROOT / "scripts" / "verify-evidence-input-digests.py"
RISK_EVALUATOR = ROOT / "scripts" / "evaluate-risk.py"
RISK_INPUT = ROOT / "platform-assurance" / "risk" / "examples" / "r2-change.json"
RISK_POLICY = ROOT / "platform-assurance" / "risk" / "policy" / "r0-r4-policy.json"
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

DESIRED_STATE_DIGEST = (
    "sha256:10335a01c45e545486a5c4f3cecae555ff73966504c0b1809a75c86c6562ed15"
)


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


def run_trusted_consumer(
    manifest: Path,
    desired_state: Path,
    expected_status: int,
    *,
    policy: Path = RISK_POLICY,
    architecture: Path = RISK_INPUT,
) -> subprocess.CompletedProcess[str]:
    command = [
        sys.executable,
        str(TRUSTED_CONSUMER),
        str(manifest),
        "--policy-source",
        str(policy),
        "--architecture-source",
        str(architecture),
        "--desired-state-source",
        str(desired_state),
        "--expected-commit",
        "2222222222222222222222222222222222222222",
        "--expected-plan-digest",
        authoritative_plan_digest(),
    ]
    result = subprocess.run(command, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    actual = 0 if result.returncode == 0 else 1
    if actual != expected_status:
        raise RuntimeError(
            f"trusted consumer expected normalized exit {expected_status}, got {result.returncode}\n"
            f"stdout:\n{result.stdout}\nstderr:\n{result.stderr}"
        )
    return result


def check_authoritative_input_binding() -> None:
    source_manifest = json.loads(
        (FIXTURES / "valid-risk-adaptive.json").read_text(encoding="utf-8")
    )
    source_manifest["inputs"]["desiredStateDigest"] = DESIRED_STATE_DIGEST

    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        manifest = root / "evidence.json"
        manifest.write_text(json.dumps(source_manifest, indent=2) + "\n", encoding="utf-8")

        desired_state = root / "desired-state"
        desired_state.mkdir()
        (desired_state / "app.yaml").write_text(
            "apiVersion: v1\nkind: ConfigMap\nmetadata:\n  name: orders-api\n",
            encoding="utf-8",
        )
        nested = desired_state / "nested"
        nested.mkdir()
        (nested / "values.json").write_text('{"replicas":2}\n', encoding="utf-8")

        run_trusted_consumer(manifest, desired_state, 0)

        (desired_state / "app.yaml").write_text(
            "apiVersion: v1\nkind: ConfigMap\nmetadata:\n  name: drifted-orders-api\n",
            encoding="utf-8",
        )
        drift = run_trusted_consumer(manifest, desired_state, 1)
        if "desiredStateDigest" not in drift.stderr:
            raise RuntimeError("Desired-state drift did not identify desiredStateDigest")

        (desired_state / "app.yaml").write_text(
            "apiVersion: v1\nkind: ConfigMap\nmetadata:\n  name: orders-api\n",
            encoding="utf-8",
        )

        policy = root / "policy.json"
        policy_data = json.loads(RISK_POLICY.read_text(encoding="utf-8"))
        policy_data["levels"]["R2"]["requiredReviewerRoles"].append("audit")
        policy.write_text(json.dumps(policy_data, indent=2) + "\n", encoding="utf-8")
        policy_drift = run_trusted_consumer(
            manifest,
            desired_state,
            1,
            policy=policy,
        )
        if "policyDigest" not in policy_drift.stderr:
            raise RuntimeError("Policy drift did not identify policyDigest")

        architecture = root / "architecture.json"
        architecture_data = json.loads(RISK_INPUT.read_text(encoding="utf-8"))
        architecture_data["architecture"]["service"]["owner"] = "drifted-owner"
        architecture.write_text(
            json.dumps(architecture_data, indent=2) + "\n", encoding="utf-8"
        )
        architecture_drift = run_trusted_consumer(
            manifest,
            desired_state,
            1,
            architecture=architecture,
        )
        if "architectureDigest" not in architecture_drift.stderr:
            raise RuntimeError("Architecture drift did not identify architectureDigest")

        symlink_root = root / "symlinked-state"
        symlink_root.mkdir()
        target = root / "target.yaml"
        target.write_text("kind: ConfigMap\n", encoding="utf-8")
        (symlink_root / "linked.yaml").symlink_to(target)
        symlink_result = run_trusted_consumer(manifest, symlink_root, 1)
        if "symlink" not in symlink_result.stderr:
            raise RuntimeError("Symlinked desired state did not fail closed")

        empty_state = root / "empty-state"
        empty_state.mkdir()
        empty_result = run_trusted_consumer(manifest, empty_state, 1)
        if "no regular files" not in empty_result.stderr:
            raise RuntimeError("Empty desired state did not fail closed")

        missing_source = subprocess.run(
            [
                sys.executable,
                str(TRUSTED_CONSUMER),
                str(manifest),
                "--policy-source",
                str(RISK_POLICY),
                "--architecture-source",
                str(RISK_INPUT),
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        if missing_source.returncode == 0:
            raise RuntimeError("Trusted consumption unexpectedly accepted missing desired-state source")


def main() -> int:
    check_schema_contract()
    for filename, expected_status in BASE_CASES.items():
        run_case(FIXTURES / filename, expected_status)
    check_assurance_binding()
    check_expected_commit_invalidation()
    check_authoritative_input_binding()
    print(
        "PASS: evidence contract regression suite with trusted assurance-plan and "
        "authoritative-input binding"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
