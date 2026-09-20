#!/usr/bin/env python3
"""Exercise GoldenPath P2 signed runtime assurance receipts and adversarial rejection paths."""

from __future__ import annotations

import base64
import copy
import json
import subprocess
import sys
import tempfile
from datetime import datetime, timedelta, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GENERATOR = ROOT / "scripts/generate-runtime-assurance.py"
VERIFIER = ROOT / "scripts/validate-runtime-assurance.py"
RISK = ROOT / "scripts/evaluate-risk.py"
ASSURANCE_INPUT = ROOT / "runtime-lab/assurance-input.json"


def run(command: list[str], *, expected: int = 0) -> subprocess.CompletedProcess[str]:
    result = subprocess.run(command, cwd=ROOT, check=False, capture_output=True, text=True)
    if result.returncode != expected:
        raise RuntimeError(
            f"command returned {result.returncode}, expected {expected}: {' '.join(command)}\n"
            f"stdout:\n{result.stdout}\nstderr:\n{result.stderr}"
        )
    return result


def git_head() -> str:
    return run(["git", "rev-parse", "HEAD"]).stdout.strip()


def iso(value: datetime) -> str:
    return value.astimezone(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def read_json(path: Path) -> dict[str, object]:
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, value: object) -> None:
    path.write_text(json.dumps(value, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def verifier_command(
    receipt: Path,
    evidence: Path,
    public_key: Path,
    *,
    now: str,
    source: str,
    artifact: str,
    policy: str,
    cluster: str,
) -> list[str]:
    return [
        sys.executable,
        str(VERIFIER),
        str(receipt),
        "--runtime-evidence",
        str(evidence),
        "--trusted-public-key",
        str(public_key),
        "--require-signature",
        "--now",
        now,
        "--expected-source",
        source,
        "--expected-artifact-digest",
        artifact,
        "--expected-desired-state-revision",
        source,
        "--expected-policy-bundle-digest",
        policy,
        "--expected-cluster-identity",
        cluster,
    ]


def expect_failure(command: list[str], expected_message: str) -> None:
    result = run(command, expected=1)
    combined = result.stdout + result.stderr
    if expected_message not in combined:
        raise RuntimeError(
            f"expected failure containing {expected_message!r}, got:\n{combined}"
        )


def mutate_signed_receipt(
    base: dict[str, object],
    path: Path,
    mutator,
) -> None:
    value = copy.deepcopy(base)
    mutator(value)
    write_json(path, value)


def main() -> int:
    source = git_head()
    observed = datetime.now(timezone.utc) - timedelta(seconds=5)
    verify_time = observed + timedelta(seconds=30)
    stale_time = observed + timedelta(hours=2)
    artifact = "sha256:" + "1" * 64
    cluster = "kind:goldenpath-p2-test"
    workload_uid = "11111111-2222-3333-4444-555555555555"

    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        facts_path = root / "runtime-facts.json"
        plan_path = root / "assurance-plan.json"
        key_path = root / "receipt.key"
        evidence_path = root / "runtime-evidence.json"
        receipt_path = root / "assurance-receipt.json"
        public_key_path = root / "receipt-public.pem"
        summary_path = root / "assurance-summary.txt"

        run([
            sys.executable,
            str(RISK),
            str(ASSURANCE_INPUT),
            "--output",
            str(plan_path),
        ])
        run(["openssl", "genpkey", "-algorithm", "ED25519", "-out", str(key_path)])

        facts = {
            "schemaVersion": "goldenpath.runtime-lab-facts/v1",
            "evidenceTier": "runtime",
            "environmentClass": "ephemeral-lab",
            "productionValidation": "NOT_CLAIMED",
            "observedAt": iso(observed),
            "execution": {
                "labId": "p2-test-001",
                "sourceRepository": "https://github.com/lloga29/goldenPath.git",
                "sourceRevision": source,
            },
            "runtime": {
                "clusterName": "gp-p2-test-001",
                "clusterIdentity": cluster,
                "namespace": "goldenpath-p2-test-001",
                "workloadUid": workload_uid,
                "podUid": "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee",
                "podPhase": "Running",
            },
            "artifact": {
                "expectedImage": f"localhost:5001/goldenpath-runtime@{artifact}",
                "expectedDigest": artifact,
                "observedImage": f"localhost:5001/goldenpath-runtime@{artifact}",
                "observedImageId": f"docker-pullable://localhost:5001/goldenpath-runtime@{artifact}",
            },
            "gitops": {
                "policyApplication": "gp-policies-p2-test-001",
                "workloadApplication": "gp-workload-p2-test-001",
                "desiredStateRevision": source,
                "reconciledRevision": source,
                "policyReconciledRevision": source,
                "syncStatus": "Synced",
                "healthStatus": "Healthy",
            },
            "controls": {
                "admissionPolicyDenial": "PASS",
                "runtimeDigestIdentity": "PASS",
                "cleanupResidueCheck": "PASS",
            },
            "dependencies": {
                "kindNodeImage": "kindest/node:v1.37.0@sha256:" + "2" * 64,
                "argoCD": "v3.5.3",
                "gatekeeperChart": "3.23.1",
            },
        }
        write_json(facts_path, facts)

        run([
            sys.executable,
            str(GENERATOR),
            "--runtime-facts",
            str(facts_path),
            "--assurance-plan",
            str(plan_path),
            "--private-key",
            str(key_path),
            "--repository-root",
            str(ROOT),
            "--runtime-evidence-output",
            str(evidence_path),
            "--receipt-output",
            str(receipt_path),
            "--public-key-output",
            str(public_key_path),
            "--summary-output",
            str(summary_path),
        ])

        receipt = read_json(receipt_path)
        evidence = read_json(evidence_path)
        policy_digest = receipt["subject"]["policy"]["policyBundleDigest"]
        command = verifier_command(
            receipt_path,
            evidence_path,
            public_key_path,
            now=iso(verify_time),
            source=source,
            artifact=artifact,
            policy=policy_digest,
            cluster=cluster,
        )
        run(command)

        summary = summary_path.read_text(encoding="utf-8")
        if "Production validation: NOT CLAIMED" not in summary:
            raise RuntimeError("human-readable summary lost the production evidence boundary")

        receipt_mutations = [
            (
                "source",
                lambda value: value["subject"]["source"].__setitem__(
                    "revision", "a" * 40 if source != "a" * 40 else "b" * 40
                ),
            ),
            (
                "artifact",
                lambda value: value["subject"]["artifact"].__setitem__(
                    "digest", "sha256:" + "9" * 64
                ),
            ),
            (
                "desired-state",
                lambda value: value["subject"]["gitops"].__setitem__(
                    "desiredStateRevision", "c" * 40
                ),
            ),
            (
                "policy",
                lambda value: value["subject"]["policy"].__setitem__(
                    "assurancePlanDigest", "sha256:" + "8" * 64
                ),
            ),
            (
                "runtime",
                lambda value: value["subject"]["runtime"].__setitem__(
                    "clusterIdentity", "kind:wrong-cluster"
                ),
            ),
            (
                "required-control",
                lambda value: value["controls"][0].__setitem__("result", "FAIL"),
            ),
        ]
        for name, mutator in receipt_mutations:
            path = root / f"mutated-{name}.json"
            mutate_signed_receipt(receipt, path, mutator)
            mutated_command = command.copy()
            mutated_command[2] = str(path)
            expect_failure(mutated_command, "signature payload digest mismatch")

        signature_path = root / "mutated-signature.json"
        signature_receipt = copy.deepcopy(receipt)
        raw_signature = bytearray(base64.b64decode(signature_receipt["signature"]["value"]))
        raw_signature[0] ^= 0x01
        signature_receipt["signature"]["value"] = base64.b64encode(raw_signature).decode("ascii")
        write_json(signature_path, signature_receipt)
        signature_command = command.copy()
        signature_command[2] = str(signature_path)
        expect_failure(signature_command, "receipt signature verification failed")

        tampered_evidence_path = root / "tampered-runtime-evidence.json"
        tampered_evidence = copy.deepcopy(evidence)
        tampered_evidence["runtime"]["clusterIdentity"] = "kind:tampered"
        write_json(tampered_evidence_path, tampered_evidence)
        tampered_command = command.copy()
        tampered_command[4] = str(tampered_evidence_path)
        expect_failure(tampered_command, "runtime evidence digest mismatch")

        replay_command = command.copy()
        source_index = replay_command.index("--expected-source") + 1
        replay_command[source_index] = "d" * 40
        expect_failure(replay_command, "does not match --expected-source")

        stale_command = verifier_command(
            receipt_path,
            evidence_path,
            public_key_path,
            now=iso(stale_time),
            source=source,
            artifact=artifact,
            policy=policy_digest,
            cluster=cluster,
        )
        expect_failure(stale_command, "stale or expired")

        incomplete_facts = copy.deepcopy(facts)
        incomplete_facts["controls"].pop("cleanupResidueCheck")
        incomplete_path = root / "incomplete-runtime-facts.json"
        write_json(incomplete_path, incomplete_facts)
        incomplete = run([
            sys.executable,
            str(GENERATOR),
            "--runtime-facts",
            str(incomplete_path),
            "--assurance-plan",
            str(plan_path),
            "--private-key",
            str(key_path),
            "--repository-root",
            str(ROOT),
            "--runtime-evidence-output",
            str(root / "unused-evidence.json"),
            "--receipt-output",
            str(root / "unused-receipt.json"),
            "--public-key-output",
            str(root / "unused-public.pem"),
            "--summary-output",
            str(root / "unused-summary.txt"),
        ], expected=1)
        if "missing required controls" not in incomplete.stderr:
            raise RuntimeError("incomplete required-control evidence did not fail closed")

    print(
        "PASS: P2 signed runtime assurance verifies independently and rejects "
        "identity, control, signature, tamper, replay, stale, and incomplete-evidence mutations"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
