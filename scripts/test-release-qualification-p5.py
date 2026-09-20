#!/usr/bin/env python3
"""Negative/adversarial tests for the GoldenPath v0.2.0 P5 release gate."""
from __future__ import annotations

import hashlib
import json
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts" / "qualify-release-candidate.py"
SOURCE = "1" * 40
OTHER = "2" * 40
DIGEST = "sha256:" + "3" * 64


def write_json(path: Path, value: object) -> None:
    path.write_text(json.dumps(value, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def digest(path: Path) -> str:
    return "sha256:" + hashlib.sha256(path.read_bytes()).hexdigest()


def run(root: Path, expected: int) -> subprocess.CompletedProcess[str]:
    result = subprocess.run(
        [
            sys.executable,
            str(SCRIPT),
            "--artifact-dir",
            str(root),
            "--expected-source",
            SOURCE,
            "--repository-root",
            str(ROOT),
            "--output",
            str(root / "release-candidate-evidence.json"),
        ],
        cwd=ROOT,
        check=False,
        capture_output=True,
        text=True,
    )
    if result.returncode != expected:
        raise RuntimeError(
            f"qualification returned {result.returncode}, expected {expected}\n"
            f"stdout:\n{result.stdout}\nstderr:\n{result.stderr}"
        )
    return result


def fixture(root: Path) -> None:
    receipt_id = "receipt-p5-negative-test"
    write_json(
        root / "repository-validation.json",
        {
            "schemaVersion": "goldenpath.repository-validation/v1",
            "status": "PASS",
            "sourceRevision": SOURCE,
            "evidenceTier": "repository",
            "productionValidation": "NOT_CLAIMED",
        },
    )
    write_json(
        root / "runtime-facts.json",
        {
            "schemaVersion": "goldenpath.runtime-lab-facts/v1",
            "evidenceTier": "runtime",
            "environmentClass": "ephemeral-lab",
            "productionValidation": "NOT_CLAIMED",
            "execution": {"sourceRevision": SOURCE},
            "gitops": {
                "desiredStateRevision": SOURCE,
                "reconciledRevision": SOURCE,
                "policyReconciledRevision": SOURCE,
            },
            "controls": {
                "admissionPolicyDenial": "PASS",
                "runtimeDigestIdentity": "PASS",
                "cleanupResidueCheck": "PASS",
            },
        },
    )
    write_json(
        root / "assurance-plan.json",
        {
            "schemaVersion": "goldenpath.assurance/v1",
            "evidenceRequirements": {"runtimeValidationRequired": True, "planDigest": DIGEST},
        },
    )
    write_json(
        root / "runtime-evidence.json",
        {
            "schemaVersion": "goldenpath.runtime-evidence/v1",
            "claim": {"tier": "runtime"},
            "source": {"revision": SOURCE},
            "gitops": {"desiredStateRevision": SOURCE},
        },
    )
    write_json(
        root / "assurance-receipt.json",
        {
            "schemaVersion": "goldenpath.assurance-receipt/v1",
            "receiptId": receipt_id,
            "decision": "VERIFIED",
            "claim": {"tier": "runtime"},
            "subject": {
                "source": {"revision": SOURCE},
                "gitops": {"desiredStateRevision": SOURCE},
            },
            "signature": {"algorithm": "ed25519"},
        },
    )
    (root / "runtime-receipt-public.pem").write_text("test-public-key\n", encoding="utf-8")
    write_json(
        root / "continuous-assurance.json",
        {
            "schemaVersion": "goldenpath.continuous-assurance/v1",
            "productionValidation": "NOT_CLAIMED",
            "currentState": "RECOVERED_REVERIFIED",
            "currentReceipt": {"receiptId": receipt_id},
        },
    )
    write_json(
        root / "platform-scorecard.json",
        {
            "schemaVersion": "goldenpath.platform-scorecard/v1",
            "decision": "VERIFIED",
            "currentState": "RECOVERED_REVERIFIED",
            "productionValidation": "NOT_CLAIMED",
            "evidence": {
                "repository": "VERIFIED",
                "runtime": "VERIFIED",
                "production": "NOT_CLAIMED",
            },
        },
    )
    (root / "assurance-report.txt").write_text(
        "Repository Evidence VERIFIED\nRuntime Evidence VERIFIED\nProduction Validation NOT CLAIMED\n",
        encoding="utf-8",
    )
    write_json(
        root / "verification-result.json",
        {
            "schemaVersion": "goldenpath.verification-result/v1",
            "status": "PASS",
            "productionValidation": "NOT_CLAIMED",
            "receiptFileDigest": digest(root / "assurance-receipt.json"),
            "runtimeEvidenceFileDigest": digest(root / "runtime-evidence.json"),
            "trustedPublicKeyFileDigest": digest(root / "runtime-receipt-public.pem"),
            "expected": {
                "sourceRevision": SOURCE,
                "desiredStateRevision": SOURCE,
            },
        },
    )


def main() -> int:
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        fixture(root)
        run(root, 0)

        facts = json.loads((root / "runtime-facts.json").read_text(encoding="utf-8"))
        facts["gitops"]["desiredStateRevision"] = OTHER
        write_json(root / "runtime-facts.json", facts)
        if "desiredStateRevision mismatch" not in run(root, 1).stderr:
            raise RuntimeError("identity mismatch did not fail closed")

        fixture(root)
        (root / "verification-result.json").unlink()
        if "missing required candidate evidence" not in run(root, 1).stderr:
            raise RuntimeError("missing verification did not fail closed")

        fixture(root)
        receipt = json.loads((root / "assurance-receipt.json").read_text(encoding="utf-8"))
        receipt["decision"] = "NOT_VERIFIED"
        write_json(root / "assurance-receipt.json", receipt)
        if "receipt decision mismatch" not in run(root, 1).stderr:
            raise RuntimeError("tampered receipt did not fail closed")

        fixture(root)
        score = json.loads((root / "platform-scorecard.json").read_text(encoding="utf-8"))
        score["evidence"]["production"] = "VERIFIED"
        write_json(root / "platform-scorecard.json", score)
        if "scorecard production evidence mismatch" not in run(root, 1).stderr:
            raise RuntimeError("production overclaim did not fail closed")

    print(
        "PASS: P5 rejects missing, identity-mismatched, tampered, and "
        "production-overclaim candidate evidence"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
