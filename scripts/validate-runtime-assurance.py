#!/usr/bin/env python3
"""Validate GoldenPath v0.2 runtime evidence and assurance receipts."""

from __future__ import annotations

import argparse
import base64
import binascii
import hashlib
import json
import re
import subprocess
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path

RUNTIME_SCHEMA = "goldenpath.runtime-evidence/v1"
RECEIPT_SCHEMA = "goldenpath.assurance-receipt/v1"
CONTROL_RESULTS = {"PASS", "FAIL", "INFRASTRUCTURE_FAILURE", "NEEDS_HUMAN"}
DECISIONS = {"VERIFIED", "NOT_VERIFIED", "NEEDS_HUMAN"}
CLAIM_TIERS = {"repository", "runtime", "production"}
RUNTIME_TIERS = {"runtime", "production"}
ENVIRONMENT_CLASSES = {"ephemeral-lab", "non-production", "production"}
SHA_RE = re.compile(r"^[0-9a-f]{40}$")
DIGEST_RE = re.compile(r"^sha256:[0-9a-f]{64}$")
ID_RE = re.compile(r"^[a-z0-9][a-z0-9._-]{2,127}$")
REPOSITORY_RE = re.compile(r"^[^/\\s]+/[^/\\s]+$")


class ValidationError(ValueError):
    """Raised when runtime evidence or a receipt violates the contract."""


def fail(message: str) -> None:
    raise ValidationError(message)


def require_dict(value: object, path: str) -> dict[str, object]:
    if not isinstance(value, dict):
        fail(f"{path} must be an object")
    return value


def require_list(value: object, path: str) -> list[object]:
    if not isinstance(value, list):
        fail(f"{path} must be an array")
    return value


def require_string(value: object, path: str) -> str:
    if not isinstance(value, str) or not value:
        fail(f"{path} must be a non-empty string")
    return value


def require_bool(value: object, path: str) -> bool:
    if not isinstance(value, bool):
        fail(f"{path} must be a boolean")
    return value


def require_keys(obj: dict[str, object], required: set[str], path: str) -> None:
    missing = sorted(required - obj.keys())
    if missing:
        fail(f"{path} is missing required keys: {', '.join(missing)}")


def reject_unknown(obj: dict[str, object], allowed: set[str], path: str) -> None:
    unknown = sorted(obj.keys() - allowed)
    if unknown:
        fail(f"{path} contains unknown keys: {', '.join(unknown)}")


def parse_time(value: object, path: str) -> datetime:
    text = require_string(value, path)
    candidate = text[:-1] + "+00:00" if text.endswith("Z") else text
    try:
        parsed = datetime.fromisoformat(candidate)
    except ValueError as exc:
        fail(f"{path} must be RFC3339-compatible: {exc}")
    if parsed.tzinfo is None:
        fail(f"{path} must include a timezone")
    return parsed.astimezone(timezone.utc)


def require_sha(value: object, path: str) -> str:
    text = require_string(value, path)
    if not SHA_RE.fullmatch(text):
        fail(f"{path} must be a lowercase 40-character Git SHA")
    return text


def require_digest(value: object, path: str) -> str:
    text = require_string(value, path)
    if not DIGEST_RE.fullmatch(text):
        fail(f"{path} must be sha256:<64 lowercase hex>")
    return text


def require_id(value: object, path: str) -> str:
    text = require_string(value, path)
    if not ID_RE.fullmatch(text):
        fail(f"{path} has an invalid identifier format")
    return text


def require_repository(value: object, path: str) -> str:
    text = require_string(value, path)
    if not REPOSITORY_RE.fullmatch(text):
        fail(f"{path} must use owner/name form")
    return text


def canonical_bytes(value: object) -> bytes:
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode("utf-8")


def canonical_digest(value: object) -> str:
    return "sha256:" + hashlib.sha256(canonical_bytes(value)).hexdigest()


def validate_execution(value: object, path: str) -> dict[str, object]:
    obj = require_dict(value, path)
    required = {"executionId", "attempt", "collectorVersion"}
    require_keys(obj, required, path)
    reject_unknown(obj, required, path)
    require_id(obj["executionId"], f"{path}.executionId")
    attempt = obj["attempt"]
    if not isinstance(attempt, int) or isinstance(attempt, bool) or attempt < 1:
        fail(f"{path}.attempt must be an integer >= 1")
    require_string(obj["collectorVersion"], f"{path}.collectorVersion")
    return obj


def validate_source(value: object, path: str) -> dict[str, object]:
    obj = require_dict(value, path)
    required = {"repository", "revision"}
    require_keys(obj, required, path)
    reject_unknown(obj, required, path)
    require_repository(obj["repository"], f"{path}.repository")
    require_sha(obj["revision"], f"{path}.revision")
    return obj


def validate_artifact(value: object, path: str) -> dict[str, object]:
    obj = require_dict(value, path)
    required = {"identity", "digest"}
    require_keys(obj, required, path)
    reject_unknown(obj, required, path)
    require_string(obj["identity"], f"{path}.identity")
    require_digest(obj["digest"], f"{path}.digest")
    return obj


def validate_gitops(value: object, path: str) -> dict[str, object]:
    obj = require_dict(value, path)
    required = {"repository", "desiredStateRevision", "desiredStateDigest"}
    require_keys(obj, required, path)
    reject_unknown(obj, required, path)
    require_repository(obj["repository"], f"{path}.repository")
    require_sha(obj["desiredStateRevision"], f"{path}.desiredStateRevision")
    require_digest(obj["desiredStateDigest"], f"{path}.desiredStateDigest")
    return obj


def validate_policy(value: object, path: str) -> dict[str, object]:
    obj = require_dict(value, path)
    required = {"assurancePlanDigest", "policyBundleDigest"}
    require_keys(obj, required, path)
    reject_unknown(obj, required, path)
    require_digest(obj["assurancePlanDigest"], f"{path}.assurancePlanDigest")
    require_digest(obj["policyBundleDigest"], f"{path}.policyBundleDigest")
    return obj


def validate_controls(value: object, path: str) -> tuple[list[dict[str, object]], str]:
    items = require_list(value, path)
    if not items:
        fail(f"{path} must contain at least one control")
    seen: set[str] = set()
    validated: list[dict[str, object]] = []
    required_results: list[str] = []
    allowed = {"id", "required", "result", "observedAt", "reason"}
    required_keys = {"id", "required", "result", "observedAt"}
    for index, raw in enumerate(items):
        item_path = f"{path}[{index}]"
        item = require_dict(raw, item_path)
        require_keys(item, required_keys, item_path)
        reject_unknown(item, allowed, item_path)
        control_id = require_string(item["id"], f"{item_path}.id")
        if control_id in seen:
            fail(f"{path} contains duplicate control id {control_id}")
        seen.add(control_id)
        required = require_bool(item["required"], f"{item_path}.required")
        result = require_string(item["result"], f"{item_path}.result")
        if result not in CONTROL_RESULTS:
            fail(f"{item_path}.result must be one of {sorted(CONTROL_RESULTS)}")
        parse_time(item["observedAt"], f"{item_path}.observedAt")
        if result != "PASS" and "reason" not in item:
            fail(f"{item_path}.reason is required for {result}")
        if "reason" in item:
            require_string(item["reason"], f"{item_path}.reason")
        if required:
            required_results.append(result)
        validated.append(item)
    if "NEEDS_HUMAN" in required_results:
        decision = "NEEDS_HUMAN"
    elif any(result != "PASS" for result in required_results):
        decision = "NOT_VERIFIED"
    else:
        decision = "VERIFIED"
    return validated, decision


def validate_runtime(value: object, now: datetime) -> dict[str, object]:
    root = require_dict(value, "runtimeEvidence")
    required = {
        "schemaVersion", "evidenceId", "observedAt", "validUntil", "claim",
        "execution", "source", "artifact", "gitops", "policy", "runtime", "controls",
    }
    require_keys(root, required, "runtimeEvidence")
    reject_unknown(root, required, "runtimeEvidence")
    if root["schemaVersion"] != RUNTIME_SCHEMA:
        fail(f"unsupported runtime evidence schema version: {root['schemaVersion']!r}")
    require_id(root["evidenceId"], "runtimeEvidence.evidenceId")
    observed = parse_time(root["observedAt"], "runtimeEvidence.observedAt")
    valid_until = parse_time(root["validUntil"], "runtimeEvidence.validUntil")
    if observed >= valid_until:
        fail("runtimeEvidence.validUntil must be after observedAt")
    if now < observed:
        fail("runtime evidence is from the future")
    if now > valid_until:
        fail("runtime evidence is stale or expired")

    claim = require_dict(root["claim"], "runtimeEvidence.claim")
    require_keys(claim, {"tier"}, "runtimeEvidence.claim")
    reject_unknown(claim, {"tier"}, "runtimeEvidence.claim")
    tier = require_string(claim["tier"], "runtimeEvidence.claim.tier")
    if tier not in RUNTIME_TIERS:
        fail(f"runtimeEvidence.claim.tier must be one of {sorted(RUNTIME_TIERS)}")

    execution = validate_execution(root["execution"], "runtimeEvidence.execution")
    source = validate_source(root["source"], "runtimeEvidence.source")
    artifact = validate_artifact(root["artifact"], "runtimeEvidence.artifact")
    gitops = validate_gitops(root["gitops"], "runtimeEvidence.gitops")
    policy = validate_policy(root["policy"], "runtimeEvidence.policy")

    runtime = require_dict(root["runtime"], "runtimeEvidence.runtime")
    runtime_required = {"environmentClass", "clusterIdentity", "namespace", "workload"}
    require_keys(runtime, runtime_required, "runtimeEvidence.runtime")
    reject_unknown(runtime, runtime_required, "runtimeEvidence.runtime")
    environment = require_string(runtime["environmentClass"], "runtimeEvidence.runtime.environmentClass")
    if environment not in ENVIRONMENT_CLASSES:
        fail(f"runtimeEvidence.runtime.environmentClass must be one of {sorted(ENVIRONMENT_CLASSES)}")
    require_string(runtime["clusterIdentity"], "runtimeEvidence.runtime.clusterIdentity")
    require_string(runtime["namespace"], "runtimeEvidence.runtime.namespace")
    workload = require_dict(runtime["workload"], "runtimeEvidence.runtime.workload")
    workload_required = {"kind", "name", "uid", "observedDigest"}
    require_keys(workload, workload_required, "runtimeEvidence.runtime.workload")
    reject_unknown(workload, workload_required, "runtimeEvidence.runtime.workload")
    for key in ("kind", "name", "uid"):
        require_string(workload[key], f"runtimeEvidence.runtime.workload.{key}")
    observed_digest = require_digest(workload["observedDigest"], "runtimeEvidence.runtime.workload.observedDigest")
    if observed_digest != artifact["digest"]:
        fail("runtime workload digest does not match the bound artifact digest")
    if tier == "production" and environment != "production":
        fail("production runtime evidence requires environmentClass=production")

    controls, _ = validate_controls(root["controls"], "runtimeEvidence.controls")
    for index, control in enumerate(controls):
        control_time = parse_time(control["observedAt"], f"runtimeEvidence.controls[{index}].observedAt")
        if control_time < observed or control_time > valid_until:
            fail(f"runtimeEvidence.controls[{index}].observedAt falls outside the evidence validity window")
    return {
        "root": root, "tier": tier, "execution": execution, "source": source,
        "artifact": artifact, "gitops": gitops, "policy": policy, "runtime": runtime,
        "controls": controls, "observedAt": observed, "validUntil": valid_until,
    }


def control_map(controls: list[dict[str, object]]) -> dict[str, dict[str, object]]:
    return {str(item["id"]): item for item in controls}


def require_equal(actual: object, expected: object, path: str) -> None:
    if actual != expected:
        fail(f"{path} identity mismatch")


def run_openssl(args: list[str]) -> subprocess.CompletedProcess[bytes]:
    try:
        return subprocess.run(["openssl", *args], check=False, capture_output=True)
    except FileNotFoundError:
        fail("openssl is required to verify signed assurance receipts")


def trusted_public_key_fingerprint(path: Path) -> str:
    result = run_openssl(["pkey", "-pubin", "-in", str(path), "-outform", "DER"])
    if result.returncode != 0:
        fail(f"cannot load trusted public key: {result.stderr.decode(errors='replace').strip()}")
    return "sha256:" + hashlib.sha256(result.stdout).hexdigest()


def validate_receipt_signature(root: dict[str, object], args: argparse.Namespace) -> None:
    signature_value = root.get("signature")
    if signature_value is None:
        if args.require_signature:
            fail("assurance receipt signature is required")
        return
    if args.trusted_public_key is None:
        fail("signed assurance receipt requires --trusted-public-key")

    signature = require_dict(signature_value, "receipt.signature")
    required = {"algorithm", "keyId", "payloadDigest", "value"}
    require_keys(signature, required, "receipt.signature")
    reject_unknown(signature, required, "receipt.signature")
    if signature["algorithm"] != "ed25519":
        fail("receipt.signature.algorithm must be ed25519")
    key_id = require_digest(signature["keyId"], "receipt.signature.keyId")
    payload_digest = require_digest(signature["payloadDigest"], "receipt.signature.payloadDigest")
    encoded = require_string(signature["value"], "receipt.signature.value")

    unsigned = dict(root)
    unsigned.pop("signature", None)
    payload = canonical_bytes(unsigned)
    actual_payload_digest = "sha256:" + hashlib.sha256(payload).hexdigest()
    if payload_digest != actual_payload_digest:
        fail("signature payload digest mismatch: receipt content was changed")

    actual_key_id = trusted_public_key_fingerprint(args.trusted_public_key)
    if key_id != actual_key_id:
        fail("receipt signing key does not match the independently trusted public key")

    try:
        signature_bytes = base64.b64decode(encoded, validate=True)
    except (binascii.Error, ValueError):
        fail("receipt.signature.value must be valid base64")

    with tempfile.TemporaryDirectory() as tmp:
        root_path = Path(tmp)
        payload_path = root_path / "payload.json"
        signature_path = root_path / "signature.bin"
        payload_path.write_bytes(payload)
        signature_path.write_bytes(signature_bytes)
        result = run_openssl([
            "pkeyutl", "-verify", "-rawin", "-pubin",
            "-inkey", str(args.trusted_public_key),
            "-sigfile", str(signature_path),
            "-in", str(payload_path),
        ])
    if result.returncode != 0:
        fail("receipt signature verification failed")


def validate_receipt(receipt_value: object, runtime_value: object | None, now: datetime, args: argparse.Namespace) -> None:
    root = require_dict(receipt_value, "receipt")
    required = {
        "schemaVersion", "receiptId", "generatedAt", "validUntil", "claim",
        "decision", "execution", "subject", "controls",
    }
    require_keys(root, required, "receipt")
    reject_unknown(root, required | {"runtimeEvidence", "signature"}, "receipt")
    if root["schemaVersion"] != RECEIPT_SCHEMA:
        fail(f"unsupported assurance receipt schema version: {root['schemaVersion']!r}")
    validate_receipt_signature(root, args)
    require_id(root["receiptId"], "receipt.receiptId")
    generated = parse_time(root["generatedAt"], "receipt.generatedAt")
    valid_until = parse_time(root["validUntil"], "receipt.validUntil")
    if generated >= valid_until:
        fail("receipt.validUntil must be after generatedAt")
    if now < generated:
        fail("assurance receipt is from the future")
    if now > valid_until:
        fail("assurance receipt is stale or expired")

    claim = require_dict(root["claim"], "receipt.claim")
    require_keys(claim, {"tier"}, "receipt.claim")
    reject_unknown(claim, {"tier"}, "receipt.claim")
    tier = require_string(claim["tier"], "receipt.claim.tier")
    if tier not in CLAIM_TIERS:
        fail(f"receipt.claim.tier must be one of {sorted(CLAIM_TIERS)}")

    decision = require_string(root["decision"], "receipt.decision")
    if decision not in DECISIONS:
        fail(f"receipt.decision must be one of {sorted(DECISIONS)}")
    execution = validate_execution(root["execution"], "receipt.execution")

    subject = require_dict(root["subject"], "receipt.subject")
    subject_required = {"source", "artifact", "gitops", "policy"}
    require_keys(subject, subject_required, "receipt.subject")
    reject_unknown(subject, subject_required | {"runtime"}, "receipt.subject")
    source = validate_source(subject["source"], "receipt.subject.source")
    artifact = validate_artifact(subject["artifact"], "receipt.subject.artifact")
    gitops = validate_gitops(subject["gitops"], "receipt.subject.gitops")
    policy = validate_policy(subject["policy"], "receipt.subject.policy")

    controls, derived_decision = validate_controls(root["controls"], "receipt.controls")
    if decision != derived_decision:
        fail(f"receipt.decision={decision} contradicts required-control outcome; derived decision is {derived_decision}")

    if args.expected_source and source["revision"] != args.expected_source:
        fail("receipt source revision does not match --expected-source")
    if args.expected_artifact_digest and artifact["digest"] != args.expected_artifact_digest:
        fail("receipt artifact digest does not match --expected-artifact-digest")
    if args.expected_desired_state_revision and gitops["desiredStateRevision"] != args.expected_desired_state_revision:
        fail("receipt desired-state revision does not match --expected-desired-state-revision")
    if args.expected_policy_bundle_digest and policy["policyBundleDigest"] != args.expected_policy_bundle_digest:
        fail("receipt policy bundle does not match --expected-policy-bundle-digest")

    if tier == "repository":
        if runtime_value is not None or "runtimeEvidence" in root or "runtime" in subject:
            fail("repository claim must not be elevated by attached runtime evidence")
        return

    if runtime_value is None:
        fail("runtime or production receipt requires --runtime-evidence")
    if "runtimeEvidence" not in root:
        fail("runtime or production receipt is missing runtimeEvidence binding")
    if "runtime" not in subject:
        fail("runtime or production receipt is missing subject.runtime")

    runtime_info = validate_runtime(runtime_value, now)
    evidence_root = runtime_info["root"]
    evidence_ref = require_dict(root["runtimeEvidence"], "receipt.runtimeEvidence")
    evidence_ref_required = {"schemaVersion", "evidenceId", "digest"}
    require_keys(evidence_ref, evidence_ref_required, "receipt.runtimeEvidence")
    reject_unknown(evidence_ref, evidence_ref_required, "receipt.runtimeEvidence")
    if evidence_ref["schemaVersion"] != RUNTIME_SCHEMA:
        fail("receipt.runtimeEvidence.schemaVersion is unsupported")
    require_id(evidence_ref["evidenceId"], "receipt.runtimeEvidence.evidenceId")
    evidence_digest = require_digest(evidence_ref["digest"], "receipt.runtimeEvidence.digest")
    if evidence_ref["evidenceId"] != evidence_root["evidenceId"]:
        fail("receipt runtime evidence id does not match supplied evidence")
    actual_digest = canonical_digest(evidence_root)
    if evidence_digest != actual_digest:
        fail("runtime evidence digest mismatch: evidence was changed or the receipt is replayed")

    require_equal(tier, runtime_info["tier"], "claim tier")
    require_equal(execution, runtime_info["execution"], "execution")
    require_equal(source, runtime_info["source"], "source")
    require_equal(artifact, runtime_info["artifact"], "artifact")
    require_equal(gitops, runtime_info["gitops"], "desired state")
    require_equal(policy, runtime_info["policy"], "policy")

    subject_runtime = require_dict(subject["runtime"], "receipt.subject.runtime")
    runtime_required = {"environmentClass", "clusterIdentity", "namespace", "workloadUid"}
    require_keys(subject_runtime, runtime_required, "receipt.subject.runtime")
    reject_unknown(subject_runtime, runtime_required, "receipt.subject.runtime")
    expected_runtime = {
        "environmentClass": runtime_info["runtime"]["environmentClass"],
        "clusterIdentity": runtime_info["runtime"]["clusterIdentity"],
        "namespace": runtime_info["runtime"]["namespace"],
        "workloadUid": runtime_info["runtime"]["workload"]["uid"],
    }
    require_equal(subject_runtime, expected_runtime, "runtime")
    if args.expected_cluster_identity and subject_runtime["clusterIdentity"] != args.expected_cluster_identity:
        fail("receipt runtime cluster does not match --expected-cluster-identity")
    if tier == "production" and subject_runtime["environmentClass"] != "production":
        fail("ephemeral or non-production evidence cannot support a production claim")

    if generated < runtime_info["observedAt"]:
        fail("receipt.generatedAt cannot precede runtime observation")
    if generated > runtime_info["validUntil"]:
        fail("receipt was generated after runtime evidence expired")
    if valid_until > runtime_info["validUntil"]:
        fail("receipt validity cannot outlive its runtime evidence")

    receipt_controls = control_map(controls)
    evidence_controls = control_map(runtime_info["controls"])
    if receipt_controls.keys() != evidence_controls.keys():
        fail("receipt controls do not match runtime evidence controls")
    for control_id in sorted(receipt_controls):
        if receipt_controls[control_id] != evidence_controls[control_id]:
            fail(f"contradictory control outcome for {control_id}")


def load_json(path: Path) -> object:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        fail(f"cannot load {path}: {exc}")


def parse_now(value: str | None) -> datetime:
    return datetime.now(timezone.utc) if value is None else parse_time(value, "--now")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("receipt", type=Path)
    parser.add_argument("--runtime-evidence", type=Path)
    parser.add_argument("--now", help="RFC3339 verification time; defaults to current UTC time")
    parser.add_argument("--expected-source")
    parser.add_argument("--expected-artifact-digest")
    parser.add_argument("--expected-desired-state-revision")
    parser.add_argument("--expected-policy-bundle-digest")
    parser.add_argument("--expected-cluster-identity")
    parser.add_argument("--trusted-public-key", type=Path)
    parser.add_argument("--require-signature", action="store_true")
    return parser


def main() -> int:
    args = build_parser().parse_args()
    try:
        receipt = load_json(args.receipt)
        runtime = load_json(args.runtime_evidence) if args.runtime_evidence else None
        validate_receipt(receipt, runtime, parse_now(args.now), args)
    except ValidationError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1
    print("PASS: GoldenPath runtime assurance receipt verified")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
