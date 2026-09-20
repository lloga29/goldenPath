#!/usr/bin/env python3
"""Fail-closed qualification of the exact GoldenPath v0.2.0 release candidate."""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from pathlib import Path

SCHEMA = "goldenpath.release-qualification/v1"
SHA_RE = re.compile(r"^[0-9a-f]{40}$")
HEALTHY = {"VERIFIED_HEALTHY", "RECOVERED_REVERIFIED"}
REQUIRED = (
    "repository-validation.json",
    "runtime-facts.json",
    "assurance-plan.json",
    "runtime-evidence.json",
    "assurance-receipt.json",
    "runtime-receipt-public.pem",
    "verification-result.json",
    "continuous-assurance.json",
    "platform-scorecard.json",
    "assurance-report.txt",
)
PUBLIC_DOCS = (
    "README.md",
    "docs/QUICKSTART.md",
    "docs/DEMO.md",
    "docs/architecture/overview.md",
    "docs/showcases/evidence-backed-delivery.md",
    "docs/releases/v0.2.0.md",
    "docs/releases/v0.2.0-migration.md",
    "docs/runbooks/v0.2.0-release.md",
    "docs/releases/v0.2.0-post-release-checklist.md",
)


class QualificationError(ValueError):
    pass


def fail(message: str) -> None:
    raise QualificationError(message)


def load_json(path: Path) -> dict[str, object]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        fail(f"cannot load {path}: {exc}")
    if not isinstance(value, dict):
        fail(f"{path} must contain a JSON object")
    return value


def file_digest(path: Path) -> str:
    try:
        return "sha256:" + hashlib.sha256(path.read_bytes()).hexdigest()
    except OSError as exc:
        fail(f"cannot hash {path}: {exc}")


def canonical_digest(value: object) -> str:
    raw = json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode()
    return "sha256:" + hashlib.sha256(raw).hexdigest()


def require_equal(actual: object, expected: object, label: str) -> None:
    if actual != expected:
        fail(f"{label} mismatch: expected {expected!r}, got {actual!r}")


def review_docs(root: Path) -> list[dict[str, object]]:
    forbidden = (
        "production validation: verified",
        "production validation: validated",
        "production certified",
        "certified for production",
    )
    results = []
    for relative in PUBLIC_DOCS:
        path = root / relative
        try:
            text = path.read_text(encoding="utf-8")
        except OSError as exc:
            fail(f"required release documentation is missing: {relative}: {exc}")
        lowered = text.lower()
        for phrase in forbidden:
            if phrase in lowered:
                fail(f"{relative} contains unsupported production claim: {phrase}")
        results.append({"path": relative, "result": "PASS"})
    return results


def qualify(artifact_dir: Path, expected_source: str, repository_root: Path) -> dict[str, object]:
    if not SHA_RE.fullmatch(expected_source):
        fail("--expected-source must be an exact lowercase 40-character Git SHA")

    missing = [name for name in REQUIRED if not (artifact_dir / name).is_file()]
    if missing:
        fail("missing required candidate evidence: " + ", ".join(missing))

    repository = load_json(artifact_dir / "repository-validation.json")
    facts = load_json(artifact_dir / "runtime-facts.json")
    plan = load_json(artifact_dir / "assurance-plan.json")
    evidence = load_json(artifact_dir / "runtime-evidence.json")
    receipt = load_json(artifact_dir / "assurance-receipt.json")
    verification = load_json(artifact_dir / "verification-result.json")
    continuous = load_json(artifact_dir / "continuous-assurance.json")
    scorecard = load_json(artifact_dir / "platform-scorecard.json")

    require_equal(repository.get("status"), "PASS", "repository validation status")
    require_equal(repository.get("sourceRevision"), expected_source, "repository source revision")
    require_equal(repository.get("productionValidation"), "NOT_CLAIMED", "repository production claim")

    execution = facts.get("execution") if isinstance(facts.get("execution"), dict) else {}
    gitops = facts.get("gitops") if isinstance(facts.get("gitops"), dict) else {}
    controls = facts.get("controls") if isinstance(facts.get("controls"), dict) else {}
    require_equal(execution.get("sourceRevision"), expected_source, "runtime facts source revision")
    for key in ("desiredStateRevision", "reconciledRevision", "policyReconciledRevision"):
        require_equal(gitops.get(key), expected_source, f"runtime facts {key}")
    require_equal(facts.get("productionValidation"), "NOT_CLAIMED", "runtime facts production claim")
    for control in ("admissionPolicyDenial", "runtimeDigestIdentity", "cleanupResidueCheck"):
        require_equal(controls.get(control), "PASS", f"runtime control {control}")

    require_equal(plan.get("schemaVersion"), "goldenpath.assurance/v1", "assurance plan schema")
    requirements = plan.get("evidenceRequirements") if isinstance(plan.get("evidenceRequirements"), dict) else {}
    require_equal(requirements.get("runtimeValidationRequired"), True, "runtime validation requirement")

    require_equal(evidence.get("schemaVersion"), "goldenpath.runtime-evidence/v1", "runtime evidence schema")
    source = evidence.get("source") if isinstance(evidence.get("source"), dict) else {}
    evidence_gitops = evidence.get("gitops") if isinstance(evidence.get("gitops"), dict) else {}
    claim = evidence.get("claim") if isinstance(evidence.get("claim"), dict) else {}
    require_equal(source.get("revision"), expected_source, "runtime evidence source")
    require_equal(evidence_gitops.get("desiredStateRevision"), expected_source, "runtime evidence desired state")
    require_equal(claim.get("tier"), "runtime", "runtime evidence tier")

    require_equal(receipt.get("schemaVersion"), "goldenpath.assurance-receipt/v1", "receipt schema")
    require_equal(receipt.get("decision"), "VERIFIED", "receipt decision")
    subject = receipt.get("subject") if isinstance(receipt.get("subject"), dict) else {}
    receipt_source = subject.get("source") if isinstance(subject.get("source"), dict) else {}
    receipt_gitops = subject.get("gitops") if isinstance(subject.get("gitops"), dict) else {}
    receipt_claim = receipt.get("claim") if isinstance(receipt.get("claim"), dict) else {}
    signature = receipt.get("signature") if isinstance(receipt.get("signature"), dict) else {}
    require_equal(receipt_source.get("revision"), expected_source, "receipt source revision")
    require_equal(receipt_gitops.get("desiredStateRevision"), expected_source, "receipt desired-state revision")
    require_equal(receipt_claim.get("tier"), "runtime", "receipt claim tier")
    require_equal(signature.get("algorithm"), "ed25519", "receipt signature algorithm")

    require_equal(verification.get("status"), "PASS", "independent verification status")
    require_equal(verification.get("productionValidation"), "NOT_CLAIMED", "verification production claim")
    expected = verification.get("expected") if isinstance(verification.get("expected"), dict) else {}
    require_equal(expected.get("sourceRevision"), expected_source, "verification expected source")
    require_equal(expected.get("desiredStateRevision"), expected_source, "verification expected desired state")
    require_equal(
        verification.get("receiptFileDigest"),
        file_digest(artifact_dir / "assurance-receipt.json"),
        "verified receipt digest",
    )
    require_equal(
        verification.get("runtimeEvidenceFileDigest"),
        file_digest(artifact_dir / "runtime-evidence.json"),
        "verified runtime evidence digest",
    )
    require_equal(
        verification.get("trustedPublicKeyFileDigest"),
        file_digest(artifact_dir / "runtime-receipt-public.pem"),
        "verified public key digest",
    )

    require_equal(continuous.get("productionValidation"), "NOT_CLAIMED", "continuous assurance production claim")
    if continuous.get("currentState") not in HEALTHY:
        fail(f"continuous assurance current state is not release-eligible: {continuous.get('currentState')!r}")
    current_receipt = continuous.get("currentReceipt") if isinstance(continuous.get("currentReceipt"), dict) else {}
    if current_receipt:
        require_equal(current_receipt.get("receiptId"), receipt.get("receiptId"), "continuous assurance current receipt")

    require_equal(scorecard.get("schemaVersion"), "goldenpath.platform-scorecard/v1", "scorecard schema")
    require_equal(scorecard.get("decision"), "VERIFIED", "scorecard decision")
    require_equal(scorecard.get("productionValidation"), "NOT_CLAIMED", "scorecard production claim")
    score_evidence = scorecard.get("evidence") if isinstance(scorecard.get("evidence"), dict) else {}
    require_equal(score_evidence.get("repository"), "VERIFIED", "scorecard repository evidence")
    require_equal(score_evidence.get("runtime"), "VERIFIED", "scorecard runtime evidence")
    require_equal(score_evidence.get("production"), "NOT_CLAIMED", "scorecard production evidence")
    if scorecard.get("currentState") not in HEALTHY:
        fail(f"scorecard current state is not release-eligible: {scorecard.get('currentState')!r}")

    manifest = []
    for name in REQUIRED:
        path = artifact_dir / name
        manifest.append({"path": name, "sha256": file_digest(path), "bytes": path.stat().st_size})

    result = {
        "schemaVersion": SCHEMA,
        "release": "v0.2.0",
        "status": "PASS",
        "sourceRevision": expected_source,
        "evidenceTier": "runtime",
        "productionValidation": "NOT_CLAIMED",
        "receiptId": receipt.get("receiptId"),
        "currentState": continuous.get("currentState"),
        "releaseArtifactModel": "source-tag-plus-identity-bound-evidence-bundle",
        "supplyChainBoundary": {
            "sourceRelease": "exact Git commit/tag identity",
            "runtimeReceiptSigning": "ed25519 VERIFIED",
            "generatedServiceOCI": "SBOM/provenance/Cosign controls are repository-reference verified and require real registry execution for runtime claims",
            "sourceArchiveSBOM": "NOT_CLAIMED",
            "sourceArchiveProvenance": "NOT_CLAIMED",
            "sourceArchiveSigning": "NOT_CLAIMED",
        },
        "artifacts": manifest,
        "documentationReview": review_docs(repository_root),
    }
    result["qualificationDigest"] = canonical_digest(result)
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--artifact-dir", type=Path, required=True)
    parser.add_argument("--expected-source", required=True)
    parser.add_argument("--repository-root", type=Path, default=Path("."))
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    try:
        result = qualify(args.artifact_dir.resolve(), args.expected_source, args.repository_root.resolve())
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    except QualificationError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1
    print(f"PASS: exact v0.2.0 candidate {args.expected_source} is release-qualified")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
