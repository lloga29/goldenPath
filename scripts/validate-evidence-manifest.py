#!/usr/bin/env python3
"""Validate GoldenPath Evidence Manifest v1 using only the Python standard library."""

from __future__ import annotations

import argparse
import json
import re
import sys
from datetime import datetime
from pathlib import Path
from urllib.parse import urlparse

SCHEMA_VERSION = "goldenpath.evidence/v1"
ASSURANCE_VERSION = "goldenpath.assurance/v1"
CLAIM_LEVELS = {
    "implemented",
    "reference",
    "runtime-validated",
    "production-validated",
}
DECISIONS = {"READY", "NOT_READY"}
GATE_RESULTS = {"PASS", "FAIL", "INFRASTRUCTURE_FAILURE", "SKIP_ALLOWED"}
RUNTIME_RESULTS = {"PASS", "FAIL", "INFRASTRUCTURE_FAILURE"}
ENVIRONMENTS = {"repository", "dev", "staging", "prod", "ephemeral"}
RUNTIME_KINDS = {"deployment", "health", "rollout", "smoke", "slo", "rollback"}
RISK_LEVELS = {"R0", "R1", "R2", "R3", "R4"}
AUTONOMY = {
    "automated",
    "policy-bounded",
    "guarded",
    "supervised",
    "human-authorized",
}
SHA_RE = re.compile(r"^[0-9a-f]{40}$")
DIGEST_RE = re.compile(r"^sha256:[0-9a-f]{64}$")
ID_RE = re.compile(r"^[a-z0-9][a-z0-9._-]{2,127}$")
GATE_ID_RE = re.compile(r"^[a-z0-9][a-z0-9._-]{1,127}$")
REPOSITORY_RE = re.compile(r"^[^/\s]+/[^/\s]+$")


class ValidationError(ValueError):
    """Raised when an evidence manifest violates the contract."""


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


def require_keys(obj: dict[str, object], keys: set[str], path: str) -> None:
    missing = sorted(keys - obj.keys())
    if missing:
        fail(f"{path} is missing required keys: {', '.join(missing)}")


def reject_unknown_keys(obj: dict[str, object], allowed: set[str], path: str) -> None:
    unknown = sorted(obj.keys() - allowed)
    if unknown:
        fail(f"{path} contains unknown keys: {', '.join(unknown)}")


def validate_timestamp(value: object, path: str) -> None:
    text = require_string(value, path)
    candidate = text[:-1] + "+00:00" if text.endswith("Z") else text
    try:
        parsed = datetime.fromisoformat(candidate)
    except ValueError as exc:
        fail(f"{path} must be an RFC3339-compatible timestamp: {exc}")
    if parsed.tzinfo is None:
        fail(f"{path} must include a timezone offset or Z")


def validate_url(value: object, path: str) -> None:
    text = require_string(value, path)
    parsed = urlparse(text)
    if parsed.scheme not in {"http", "https"} or not parsed.netloc:
        fail(f"{path} must be an absolute HTTP(S) URL")


def validate_sha(value: object, path: str) -> str:
    text = require_string(value, path)
    if not SHA_RE.fullmatch(text):
        fail(f"{path} must be a lowercase 40-character Git SHA")
    return text


def validate_digest(value: object, path: str) -> str:
    text = require_string(value, path)
    if not DIGEST_RE.fullmatch(text):
        fail(f"{path} must be a sha256:<64 lowercase hex> digest")
    return text


def validate_source(value: object) -> str:
    source = require_dict(value, "source")
    require_keys(source, {"repository", "commitSha"}, "source")
    reject_unknown_keys(
        source,
        {"repository", "commitSha", "workflowName", "workflowRunUrl"},
        "source",
    )

    repository = require_string(source["repository"], "source.repository")
    if not REPOSITORY_RE.fullmatch(repository):
        fail("source.repository must use owner/name form")
    commit_sha = validate_sha(source["commitSha"], "source.commitSha")
    if "workflowName" in source:
        require_string(source["workflowName"], "source.workflowName")
    if "workflowRunUrl" in source:
        validate_url(source["workflowRunUrl"], "source.workflowRunUrl")
    return commit_sha


def validate_context(value: object) -> str:
    context = require_dict(value, "context")
    require_keys(context, {"environment", "capability"}, "context")
    reject_unknown_keys(context, {"environment", "capability", "service"}, "context")

    environment = require_string(context["environment"], "context.environment")
    if environment not in ENVIRONMENTS:
        fail(f"context.environment must be one of {sorted(ENVIRONMENTS)}")
    require_string(context["capability"], "context.capability")
    if "service" in context:
        require_string(context["service"], "context.service")
    return environment


def validate_inputs(value: object) -> tuple[str, str, str]:
    inputs = require_dict(value, "inputs")
    required = {"sourceSha", "policyDigest", "architectureDigest", "desiredStateDigest"}
    require_keys(inputs, required, "inputs")
    reject_unknown_keys(inputs, required, "inputs")

    source_sha = validate_sha(inputs["sourceSha"], "inputs.sourceSha")
    policy_digest = validate_digest(inputs["policyDigest"], "inputs.policyDigest")
    architecture_digest = validate_digest(
        inputs["architectureDigest"], "inputs.architectureDigest"
    )
    validate_digest(inputs["desiredStateDigest"], "inputs.desiredStateDigest")
    return source_sha, policy_digest, architecture_digest


def validate_artifact(value: object) -> None:
    artifact = require_dict(value, "artifact")
    require_keys(artifact, {"type", "identity"}, "artifact")
    reject_unknown_keys(artifact, {"type", "identity", "digest"}, "artifact")
    artifact_type = require_string(artifact["type"], "artifact.type")
    if artifact_type not in {"container", "package", "bundle", "none"}:
        fail("artifact.type must be container, package, bundle, or none")
    require_string(artifact["identity"], "artifact.identity")
    if "digest" in artifact:
        validate_digest(artifact["digest"], "artifact.digest")
    if artifact_type != "none" and "digest" not in artifact:
        fail("artifact.digest is required unless artifact.type is none")


def validate_gates(
    value: object,
) -> tuple[bool, list[str], dict[str, dict[str, object]]]:
    gates = require_list(value, "gates")
    if not gates:
        fail("gates must contain at least one gate")

    seen: set[str] = set()
    blocking: list[str] = []
    by_id: dict[str, dict[str, object]] = {}
    allowed = {
        "id",
        "required",
        "skipAllowed",
        "result",
        "observedAt",
        "evidenceUrl",
        "reason",
    }
    required_keys = {"id", "required", "skipAllowed", "result", "observedAt"}

    for index, raw_gate in enumerate(gates):
        path = f"gates[{index}]"
        gate = require_dict(raw_gate, path)
        require_keys(gate, required_keys, path)
        reject_unknown_keys(gate, allowed, path)

        gate_id = require_string(gate["id"], f"{path}.id")
        if not GATE_ID_RE.fullmatch(gate_id):
            fail(f"{path}.id has an invalid format")
        if gate_id in seen:
            fail(f"duplicate gate id: {gate_id}")
        seen.add(gate_id)

        required = require_bool(gate["required"], f"{path}.required")
        skip_allowed = require_bool(gate["skipAllowed"], f"{path}.skipAllowed")
        result = require_string(gate["result"], f"{path}.result")
        if result not in GATE_RESULTS:
            fail(f"{path}.result must be one of {sorted(GATE_RESULTS)}")
        validate_timestamp(gate["observedAt"], f"{path}.observedAt")
        if "evidenceUrl" in gate:
            validate_url(gate["evidenceUrl"], f"{path}.evidenceUrl")
        if "reason" in gate:
            require_string(gate["reason"], f"{path}.reason")

        if result == "SKIP_ALLOWED":
            if not skip_allowed:
                fail(f"{path} reports SKIP_ALLOWED but skipAllowed is false")
            if "reason" not in gate:
                fail(f"{path}.reason is required for SKIP_ALLOWED")
        elif skip_allowed and result in {"FAIL", "INFRASTRUCTURE_FAILURE"}:
            # A skip-capable gate still failed when it actually ran; failure remains blocking.
            pass

        if result in {"FAIL", "INFRASTRUCTURE_FAILURE"} and "reason" not in gate:
            fail(f"{path}.reason is required for {result}")

        if required:
            satisfied = result == "PASS" or (
                result == "SKIP_ALLOWED" and skip_allowed
            )
            if not satisfied:
                blocking.append(gate_id)

        by_id[gate_id] = gate

    return not blocking, blocking, by_id


def validate_runtime_evidence(value: object, required: bool) -> bool:
    runtime = require_list(value, "runtimeEvidence")
    if required and not runtime:
        fail("runtimeEvidence is required by the claim or assurance plan")

    all_pass = True
    allowed = {"kind", "result", "observedAt", "evidenceUrl", "reason"}
    required_keys = {"kind", "result", "observedAt", "evidenceUrl"}

    for index, raw_item in enumerate(runtime):
        path = f"runtimeEvidence[{index}]"
        item = require_dict(raw_item, path)
        require_keys(item, required_keys, path)
        reject_unknown_keys(item, allowed, path)

        kind = require_string(item["kind"], f"{path}.kind")
        if kind not in RUNTIME_KINDS:
            fail(f"{path}.kind must be one of {sorted(RUNTIME_KINDS)}")
        result = require_string(item["result"], f"{path}.result")
        if result not in RUNTIME_RESULTS:
            fail(f"{path}.result must be one of {sorted(RUNTIME_RESULTS)}")
        validate_timestamp(item["observedAt"], f"{path}.observedAt")
        validate_url(item["evidenceUrl"], f"{path}.evidenceUrl")
        if "reason" in item:
            require_string(item["reason"], f"{path}.reason")
        if result != "PASS":
            all_pass = False
            if "reason" not in item:
                fail(f"{path}.reason is required for non-PASS runtime evidence")

    return all_pass


def validate_gate_id_list(
    value: object, path: str, *, require_nonempty: bool = False
) -> list[str]:
    items = require_list(value, path)
    if require_nonempty and not items:
        fail(f"{path} must not be empty")

    result: list[str] = []
    for index, item in enumerate(items):
        gate_id = require_string(item, f"{path}[{index}]")
        if not GATE_ID_RE.fullmatch(gate_id):
            fail(f"{path}[{index}] has an invalid gate id")
        result.append(gate_id)

    if len(result) != len(set(result)):
        fail(f"{path} must not contain duplicates")
    return result


def validate_assurance(
    value: object,
    policy_digest: str,
    architecture_digest: str,
    gates: dict[str, dict[str, object]],
) -> bool:
    assurance = require_dict(value, "assurance")
    required = {
        "schemaVersion",
        "riskLevel",
        "policyDigest",
        "planDigest",
        "architectureMetadataDigest",
        "requiredGateIds",
        "runtimeValidationRequired",
        "previewEnvironmentRequired",
        "humanApprovalGateIds",
        "autonomy",
    }
    require_keys(assurance, required, "assurance")
    reject_unknown_keys(assurance, required, "assurance")

    schema_version = require_string(assurance["schemaVersion"], "assurance.schemaVersion")
    if schema_version != ASSURANCE_VERSION:
        fail(f"assurance.schemaVersion must be {ASSURANCE_VERSION}")

    risk_level = require_string(assurance["riskLevel"], "assurance.riskLevel")
    if risk_level not in RISK_LEVELS:
        fail(f"assurance.riskLevel must be one of {sorted(RISK_LEVELS)}")

    assurance_policy_digest = validate_digest(
        assurance["policyDigest"], "assurance.policyDigest"
    )
    if assurance_policy_digest != policy_digest:
        fail("assurance.policyDigest must match inputs.policyDigest")

    validate_digest(assurance["planDigest"], "assurance.planDigest")
    assurance_architecture_digest = validate_digest(
        assurance["architectureMetadataDigest"],
        "assurance.architectureMetadataDigest",
    )
    if assurance_architecture_digest != architecture_digest:
        fail("assurance.architectureMetadataDigest must match inputs.architectureDigest")

    required_gate_ids = validate_gate_id_list(
        assurance["requiredGateIds"],
        "assurance.requiredGateIds",
        require_nonempty=True,
    )
    approval_gate_ids = validate_gate_id_list(
        assurance["humanApprovalGateIds"], "assurance.humanApprovalGateIds"
    )
    if not set(approval_gate_ids).issubset(required_gate_ids):
        fail("assurance.humanApprovalGateIds must be a subset of requiredGateIds")

    runtime_required = require_bool(
        assurance["runtimeValidationRequired"],
        "assurance.runtimeValidationRequired",
    )
    preview_required = require_bool(
        assurance["previewEnvironmentRequired"],
        "assurance.previewEnvironmentRequired",
    )
    if preview_required and "preview-environment" not in required_gate_ids:
        fail("preview assurance requires preview-environment in requiredGateIds")

    autonomy = require_string(assurance["autonomy"], "assurance.autonomy")
    if autonomy not in AUTONOMY:
        fail(f"assurance.autonomy must be one of {sorted(AUTONOMY)}")

    for gate_id in required_gate_ids:
        gate = gates.get(gate_id)
        if gate is None:
            fail(f"assurance-required gate is missing from evidence: {gate_id}")
        if gate["required"] is not True:
            fail(f"assurance-required gate must be marked required: {gate_id}")

    return runtime_required


def validate_manifest(data: object, expected_commit: str | None = None) -> None:
    manifest = require_dict(data, "manifest")
    required = {
        "schemaVersion",
        "evidenceId",
        "generatedAt",
        "claimLevel",
        "decision",
        "source",
        "context",
        "inputs",
        "gates",
    }
    allowed = required | {"artifact", "runtimeEvidence", "assurance"}
    require_keys(manifest, required, "manifest")
    reject_unknown_keys(manifest, allowed, "manifest")

    schema_version = require_string(manifest["schemaVersion"], "schemaVersion")
    if schema_version != SCHEMA_VERSION:
        fail(f"schemaVersion must be {SCHEMA_VERSION}")

    evidence_id = require_string(manifest["evidenceId"], "evidenceId")
    if not ID_RE.fullmatch(evidence_id):
        fail("evidenceId has an invalid format")
    validate_timestamp(manifest["generatedAt"], "generatedAt")

    claim_level = require_string(manifest["claimLevel"], "claimLevel")
    if claim_level not in CLAIM_LEVELS:
        fail(f"claimLevel must be one of {sorted(CLAIM_LEVELS)}")
    decision = require_string(manifest["decision"], "decision")
    if decision not in DECISIONS:
        fail(f"decision must be one of {sorted(DECISIONS)}")

    commit_sha = validate_source(manifest["source"])
    environment = validate_context(manifest["context"])
    input_source_sha, policy_digest, architecture_digest = validate_inputs(
        manifest["inputs"]
    )
    if commit_sha != input_source_sha:
        fail("source.commitSha and inputs.sourceSha must match; evidence is invalidated by source drift")
    if expected_commit is not None:
        if not SHA_RE.fullmatch(expected_commit):
            fail("--expected-commit must be a lowercase 40-character Git SHA")
        if commit_sha != expected_commit:
            fail("manifest source commit does not match --expected-commit; evidence is stale")

    if "artifact" in manifest:
        validate_artifact(manifest["artifact"])

    gates_ready, blocking_gates, gates = validate_gates(manifest["gates"])

    assurance_runtime_required = False
    if "assurance" in manifest:
        assurance_runtime_required = validate_assurance(
            manifest["assurance"], policy_digest, architecture_digest, gates
        )

    runtime_required = (
        claim_level in {"runtime-validated", "production-validated"}
        or assurance_runtime_required
    )
    if runtime_required and "runtimeEvidence" not in manifest:
        fail("runtimeEvidence is required by the claim or assurance plan")
    runtime_ready = True
    if "runtimeEvidence" in manifest:
        runtime_ready = validate_runtime_evidence(
            manifest["runtimeEvidence"], runtime_required
        )

    if claim_level == "production-validated" and environment != "prod":
        fail("production-validated evidence must target context.environment=prod")

    expected_decision = (
        "READY" if gates_ready and (not runtime_required or runtime_ready) else "NOT_READY"
    )
    if decision != expected_decision:
        details = f" blocking gates={blocking_gates}" if blocking_gates else ""
        fail(f"decision must be derived from evidence: expected {expected_decision}.{details}")


def load_json(path: Path) -> object:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        fail(f"manifest does not exist: {path}")
    except json.JSONDecodeError as exc:
        fail(f"manifest is not valid JSON: {exc}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("manifest", type=Path, help="Path to a GoldenPath Evidence Manifest JSON file")
    parser.add_argument(
        "--expected-commit",
        help="Optional exact commit SHA that the manifest must be bound to",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    try:
        data = load_json(args.manifest)
        validate_manifest(data, args.expected_commit)
    except ValidationError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1

    print(f"PASS: {args.manifest} satisfies {SCHEMA_VERSION}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
