#!/usr/bin/env python3
"""Generate signed GoldenPath runtime evidence and assurance receipts from Runtime Lab facts."""

from __future__ import annotations

import argparse
import base64
import hashlib
import json
import re
import subprocess
import sys
import tempfile
from datetime import datetime, timedelta, timezone
from pathlib import Path

FACTS_SCHEMA = "goldenpath.runtime-lab-facts/v1"
RUNTIME_SCHEMA = "goldenpath.runtime-evidence/v1"
RECEIPT_SCHEMA = "goldenpath.assurance-receipt/v1"
COLLECTOR_VERSION = "0.2.0-p2"
SHA_RE = re.compile(r"^[0-9a-f]{40}$")
DIGEST_RE = re.compile(r"^sha256:[0-9a-f]{64}$")
REQUIRED_FACT_CONTROLS = {
    "admissionPolicyDenial",
    "runtimeDigestIdentity",
    "cleanupResidueCheck",
}


class GenerationError(ValueError):
    pass


def fail(message: str) -> None:
    raise GenerationError(message)


def load_json(path: Path) -> dict[str, object]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        fail(f"cannot load {path}: {exc}")
    if not isinstance(value, dict):
        fail(f"{path} must contain a JSON object")
    return value


def write_json(path: Path, value: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def canonical_bytes(value: object) -> bytes:
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode("utf-8")


def canonical_digest(value: object) -> str:
    return "sha256:" + hashlib.sha256(canonical_bytes(value)).hexdigest()


def parse_time(value: object, path: str) -> datetime:
    if not isinstance(value, str) or not value:
        fail(f"{path} must be a non-empty RFC3339 timestamp")
    candidate = value[:-1] + "+00:00" if value.endswith("Z") else value
    try:
        parsed = datetime.fromisoformat(candidate)
    except ValueError as exc:
        fail(f"{path} must be RFC3339-compatible: {exc}")
    if parsed.tzinfo is None:
        fail(f"{path} must include a timezone")
    return parsed.astimezone(timezone.utc)


def format_time(value: datetime) -> str:
    return value.astimezone(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def repository_identity(value: object) -> str:
    if not isinstance(value, str) or not value:
        fail("runtime facts source repository is missing")
    text = value.strip()
    for prefix in ("https://github.com/", "http://github.com/", "git@github.com:"):
        if text.startswith(prefix):
            text = text[len(prefix):]
            break
    if text.endswith(".git"):
        text = text[:-4]
    if text.count("/") != 1 or any(not part for part in text.split("/")):
        fail("runtime facts source repository must resolve to owner/name")
    return text


def git_tree_digest(root: Path, revision: str, path: str) -> str:
    command = ["git", "-C", str(root), "ls-tree", "-r", "--full-tree", revision, "--", path]
    result = subprocess.run(command, check=False, capture_output=True, text=False)
    if result.returncode != 0:
        fail(f"cannot read Git tree for {path} at {revision}: {result.stderr.decode(errors='replace').strip()}")
    if not result.stdout:
        fail(f"Git tree for {path} at {revision} is empty")
    return "sha256:" + hashlib.sha256(result.stdout).hexdigest()


def openssl(*args: str, input_bytes: bytes | None = None) -> subprocess.CompletedProcess[bytes]:
    try:
        return subprocess.run(["openssl", *args], input=input_bytes, check=False, capture_output=True)
    except FileNotFoundError:
        fail("openssl is required for Ed25519 receipt signing")


def public_key_fingerprint(private_key: Path) -> tuple[str, bytes]:
    public = openssl("pkey", "-in", str(private_key), "-pubout")
    if public.returncode != 0:
        fail(f"cannot derive Ed25519 public key: {public.stderr.decode(errors='replace').strip()}")
    der = openssl("pkey", "-pubin", "-outform", "DER", input_bytes=public.stdout)
    if der.returncode != 0:
        fail(f"cannot encode Ed25519 public key: {der.stderr.decode(errors='replace').strip()}")
    return "sha256:" + hashlib.sha256(der.stdout).hexdigest(), public.stdout


def sign_receipt(unsigned_receipt: dict[str, object], private_key: Path) -> tuple[dict[str, object], bytes]:
    payload = canonical_bytes(unsigned_receipt)
    payload_digest = "sha256:" + hashlib.sha256(payload).hexdigest()
    key_id, public_key = public_key_fingerprint(private_key)
    with tempfile.TemporaryDirectory() as tmp:
        payload_path = Path(tmp) / "payload.json"
        signature_path = Path(tmp) / "signature.bin"
        payload_path.write_bytes(payload)
        result = openssl(
            "pkeyutl", "-sign", "-rawin", "-inkey", str(private_key),
            "-in", str(payload_path), "-out", str(signature_path),
        )
        if result.returncode != 0:
            fail(f"Ed25519 signing failed: {result.stderr.decode(errors='replace').strip()}")
        signature_value = base64.b64encode(signature_path.read_bytes()).decode("ascii")
    signed = dict(unsigned_receipt)
    signed["signature"] = {
        "algorithm": "ed25519",
        "keyId": key_id,
        "payloadDigest": payload_digest,
        "value": signature_value,
    }
    return signed, public_key


def require_object(root: dict[str, object], key: str) -> dict[str, object]:
    value = root.get(key)
    if not isinstance(value, dict):
        fail(f"runtime facts {key} must be an object")
    return value


def require_text(root: dict[str, object], key: str, path: str) -> str:
    value = root.get(key)
    if not isinstance(value, str) or not value:
        fail(f"{path}.{key} must be a non-empty string")
    return value


def validate_facts(facts: dict[str, object]) -> dict[str, object]:
    if facts.get("schemaVersion") != FACTS_SCHEMA:
        fail(f"runtime facts schema must be {FACTS_SCHEMA}")
    if facts.get("evidenceTier") != "runtime":
        fail("Runtime Lab facts must use evidenceTier=runtime")
    if facts.get("environmentClass") != "ephemeral-lab":
        fail("P2 Runtime Lab collector only accepts environmentClass=ephemeral-lab")
    if facts.get("productionValidation") != "NOT_CLAIMED":
        fail("Runtime Lab facts must explicitly keep productionValidation=NOT_CLAIMED")

    execution = require_object(facts, "execution")
    runtime = require_object(facts, "runtime")
    artifact = require_object(facts, "artifact")
    gitops = require_object(facts, "gitops")
    controls = require_object(facts, "controls")

    source_revision = require_text(execution, "sourceRevision", "runtime facts execution")
    if not SHA_RE.fullmatch(source_revision):
        fail("runtime facts execution.sourceRevision must be an exact lowercase 40-character Git SHA")
    source_repository = repository_identity(execution.get("sourceRepository"))
    lab_id = require_text(execution, "labId", "runtime facts execution")

    expected_digest = require_text(artifact, "expectedDigest", "runtime facts artifact")
    if not DIGEST_RE.fullmatch(expected_digest):
        fail("runtime facts artifact.expectedDigest must be sha256:<64 lowercase hex>")
    expected_image = require_text(artifact, "expectedImage", "runtime facts artifact")
    observed_image = require_text(artifact, "observedImage", "runtime facts artifact")
    if not expected_image.endswith("@" + expected_digest):
        fail("runtime facts expected image does not bind the expected digest")
    if observed_image != expected_image:
        fail("runtime facts observed image does not equal the immutable expected image")

    desired_revision = require_text(gitops, "desiredStateRevision", "runtime facts gitops")
    reconciled_revision = require_text(gitops, "reconciledRevision", "runtime facts gitops")
    policy_revision = require_text(gitops, "policyReconciledRevision", "runtime facts gitops")
    if desired_revision != source_revision or reconciled_revision != source_revision or policy_revision != source_revision:
        fail("GitOps desired-state and reconciled revisions must equal the exact source revision")
    if gitops.get("syncStatus") != "Synced" or gitops.get("healthStatus") != "Healthy":
        fail("GitOps workload must be Synced and Healthy")

    if runtime.get("podPhase") != "Running":
        fail("reference workload pod must be Running")
    for key in ("clusterIdentity", "namespace", "workloadUid"):
        require_text(runtime, key, "runtime facts runtime")

    missing_controls = sorted(REQUIRED_FACT_CONTROLS - controls.keys())
    if missing_controls:
        fail("runtime facts are missing required controls: " + ", ".join(missing_controls))
    for key in sorted(REQUIRED_FACT_CONTROLS):
        if controls.get(key) != "PASS":
            fail(f"runtime facts required control {key} must be PASS")

    return {
        "sourceRevision": source_revision,
        "sourceRepository": source_repository,
        "labId": lab_id,
        "expectedDigest": expected_digest,
        "expectedImage": expected_image,
        "clusterIdentity": runtime["clusterIdentity"],
        "namespace": runtime["namespace"],
        "workloadUid": runtime["workloadUid"],
        "observedAt": parse_time(facts.get("observedAt"), "runtime facts observedAt"),
    }


def validate_plan(plan: dict[str, object]) -> str:
    if plan.get("schemaVersion") != "goldenpath.assurance/v1":
        fail("assurance plan must use goldenpath.assurance/v1")
    evidence = require_object(plan, "evidenceRequirements")
    digest = require_text(evidence, "planDigest", "assurance plan evidenceRequirements")
    if not DIGEST_RE.fullmatch(digest):
        fail("assurance plan evidenceRequirements.planDigest must be a SHA-256 digest")
    if evidence.get("runtimeValidationRequired") is not True:
        fail("applicable assurance plan must require runtime validation")
    return digest


def build_controls(observed_at: str) -> list[dict[str, object]]:
    return [
        {"id": "artifact-digest-binding", "required": True, "result": "PASS", "observedAt": observed_at},
        {"id": "gitops-reconciliation", "required": True, "result": "PASS", "observedAt": observed_at},
        {"id": "admission-policy", "required": True, "result": "PASS", "observedAt": observed_at},
        {"id": "runtime-health", "required": True, "result": "PASS", "observedAt": observed_at},
        {"id": "cleanup-residue", "required": True, "result": "PASS", "observedAt": observed_at},
    ]


def summary_text(receipt: dict[str, object]) -> str:
    subject = receipt["subject"]
    runtime = subject["runtime"]
    signature = receipt["signature"]
    controls = receipt["controls"]
    rows = [
        "GoldenPath Runtime Assurance Receipt",
        "",
        f"Decision: {receipt['decision']}",
        f"Evidence tier: {receipt['claim']['tier']}",
        "Production validation: NOT CLAIMED",
        f"Receipt ID: {receipt['receiptId']}",
        f"Source: {subject['source']['repository']}@{subject['source']['revision']}",
        f"Artifact digest: {subject['artifact']['digest']}",
        f"Desired-state revision: {subject['gitops']['desiredStateRevision']}",
        f"Assurance plan: {subject['policy']['assurancePlanDigest']}",
        f"Policy bundle: {subject['policy']['policyBundleDigest']}",
        f"Runtime cluster: {runtime['clusterIdentity']}",
        f"Runtime workload UID: {runtime['workloadUid']}",
        f"Signature: {signature['algorithm']} {signature['keyId']}",
        "",
        "Required controls:",
    ]
    rows.extend(f"- {item['id']}: {item['result']}" for item in controls)
    rows.append("")
    return "\n".join(rows)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--runtime-facts", required=True, type=Path)
    parser.add_argument("--assurance-plan", required=True, type=Path)
    parser.add_argument("--private-key", required=True, type=Path)
    parser.add_argument("--repository-root", default=Path("."), type=Path)
    parser.add_argument("--runtime-evidence-output", required=True, type=Path)
    parser.add_argument("--receipt-output", required=True, type=Path)
    parser.add_argument("--public-key-output", required=True, type=Path)
    parser.add_argument("--summary-output", required=True, type=Path)
    parser.add_argument("--ttl-seconds", type=int, default=3600)
    parser.add_argument("--attempt", type=int, default=1)
    return parser


def main() -> int:
    args = build_parser().parse_args()
    try:
        if args.ttl_seconds < 60 or args.ttl_seconds > 86400:
            fail("--ttl-seconds must be between 60 and 86400")
        if args.attempt < 1:
            fail("--attempt must be >= 1")
        facts = load_json(args.runtime_facts)
        fact = validate_facts(facts)
        plan = load_json(args.assurance_plan)
        assurance_plan_digest = validate_plan(plan)

        observed = fact["observedAt"]
        observed_text = format_time(observed)
        valid_until = format_time(observed + timedelta(seconds=args.ttl_seconds))
        source_revision = fact["sourceRevision"]
        root = args.repository_root.resolve()
        desired_state_digest = git_tree_digest(root, source_revision, "runtime-lab/gitops")
        policy_bundle_digest = git_tree_digest(root, source_revision, "gitops-config/policies")
        controls = build_controls(observed_text)
        execution_id = "runtime-" + fact["labId"]

        evidence = {
            "schemaVersion": RUNTIME_SCHEMA,
            "evidenceId": "evidence-" + fact["labId"],
            "observedAt": observed_text,
            "validUntil": valid_until,
            "claim": {"tier": "runtime"},
            "execution": {
                "executionId": execution_id,
                "attempt": args.attempt,
                "collectorVersion": COLLECTOR_VERSION,
            },
            "source": {
                "repository": fact["sourceRepository"],
                "revision": source_revision,
            },
            "artifact": {
                "identity": fact["expectedImage"].split("@", 1)[0],
                "digest": fact["expectedDigest"],
            },
            "gitops": {
                "repository": fact["sourceRepository"],
                "desiredStateRevision": source_revision,
                "desiredStateDigest": desired_state_digest,
            },
            "policy": {
                "assurancePlanDigest": assurance_plan_digest,
                "policyBundleDigest": policy_bundle_digest,
            },
            "runtime": {
                "environmentClass": "ephemeral-lab",
                "clusterIdentity": fact["clusterIdentity"],
                "namespace": fact["namespace"],
                "workload": {
                    "kind": "Deployment",
                    "name": "goldenpath-runtime",
                    "uid": fact["workloadUid"],
                    "observedDigest": fact["expectedDigest"],
                },
            },
            "controls": controls,
        }
        evidence_digest = canonical_digest(evidence)
        unsigned_receipt = {
            "schemaVersion": RECEIPT_SCHEMA,
            "receiptId": "receipt-" + fact["labId"],
            "generatedAt": observed_text,
            "validUntil": valid_until,
            "claim": {"tier": "runtime"},
            "decision": "VERIFIED",
            "execution": evidence["execution"],
            "subject": {
                "source": evidence["source"],
                "artifact": evidence["artifact"],
                "gitops": evidence["gitops"],
                "policy": evidence["policy"],
                "runtime": {
                    "environmentClass": "ephemeral-lab",
                    "clusterIdentity": fact["clusterIdentity"],
                    "namespace": fact["namespace"],
                    "workloadUid": fact["workloadUid"],
                },
            },
            "runtimeEvidence": {
                "schemaVersion": RUNTIME_SCHEMA,
                "evidenceId": evidence["evidenceId"],
                "digest": evidence_digest,
            },
            "controls": controls,
        }
        receipt, public_key = sign_receipt(unsigned_receipt, args.private_key)

        write_json(args.runtime_evidence_output, evidence)
        write_json(args.receipt_output, receipt)
        args.public_key_output.parent.mkdir(parents=True, exist_ok=True)
        args.public_key_output.write_bytes(public_key)
        args.summary_output.parent.mkdir(parents=True, exist_ok=True)
        args.summary_output.write_text(summary_text(receipt), encoding="utf-8")
    except GenerationError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1

    print(f"PASS: signed runtime assurance receipt generated at {args.receipt_output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
