#!/usr/bin/env python3
"""Consume a GoldenPath Evidence Manifest only after rebinding it to authoritative inputs."""

from __future__ import annotations

import argparse
import hashlib
import importlib.util
import sys
from pathlib import Path
from types import ModuleType

VALIDATOR_PATH = Path(__file__).with_name("validate-evidence-manifest.py")
POLICY_SCHEMA_VERSION = "goldenpath.risk-policy/v1"
ARCHITECTURE_SCHEMA_VERSION = "goldenpath.architecture/v1"


def load_validator() -> ModuleType:
    spec = importlib.util.spec_from_file_location(
        "goldenpath_evidence_validator", VALIDATOR_PATH
    )
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot load Evidence Manifest validator: {VALIDATOR_PATH}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def fail(message: str) -> None:
    raise ValueError(message)


def require_versioned_object(
    value: object, expected_version: str, path: str
) -> dict[str, object]:
    if not isinstance(value, dict):
        fail(f"{path} must contain a JSON object")
    if value.get("schemaVersion") != expected_version:
        fail(f"{path}.schemaVersion must be {expected_version}")
    return value


def architecture_document(value: object, path: str) -> dict[str, object]:
    if not isinstance(value, dict):
        fail(f"{path} must contain a JSON object")
    candidate = value.get("architecture", value)
    return require_versioned_object(candidate, ARCHITECTURE_SCHEMA_VERSION, path)


def desired_state_digest(path: Path) -> str:
    if not path.exists():
        fail(f"desired-state source does not exist: {path}")
    if path.is_symlink():
        fail(f"desired-state source must not be a symlink: {path}")

    if path.is_file():
        root = path.parent
        files = [path]
    elif path.is_dir():
        root = path
        files = []
        for candidate in sorted(path.rglob("*"), key=lambda item: item.as_posix()):
            relative = candidate.relative_to(root)
            if relative.parts and relative.parts[0] == ".git":
                continue
            if candidate.is_symlink():
                fail(f"desired-state source contains a symlink: {relative.as_posix()}")
            if candidate.is_file():
                files.append(candidate)
            elif not candidate.is_dir():
                fail(
                    "desired-state source contains an unsupported filesystem entry: "
                    f"{relative.as_posix()}"
                )
    else:
        fail(f"desired-state source is not a regular file or directory: {path}")

    if not files:
        fail("desired-state source contains no regular files")

    digest = hashlib.sha256()
    for file_path in files:
        relative = file_path.relative_to(root).as_posix()
        try:
            content = file_path.read_bytes()
        except OSError as exc:
            fail(f"cannot read desired-state source {file_path}: {exc}")
        relative_bytes = relative.encode("utf-8")
        digest.update(b"file\0")
        digest.update(len(relative_bytes).to_bytes(8, "big"))
        digest.update(relative_bytes)
        digest.update(len(content).to_bytes(8, "big"))
        digest.update(content)

    return "sha256:" + digest.hexdigest()


def compare_digest(
    validator: ModuleType,
    inputs: dict[str, object],
    field: str,
    computed: str,
    source_description: str,
) -> None:
    if field not in inputs:
        validator.fail(f"inputs is missing required key: {field}")
    claimed = validator.validate_digest(inputs[field], f"inputs.{field}")
    if claimed != computed:
        validator.fail(
            f"inputs.{field} does not match authoritative {source_description}; "
            f"manifest={claimed}, computed={computed}"
        )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("manifest", type=Path, help="Evidence Manifest to consume")
    parser.add_argument(
        "--policy-source",
        type=Path,
        required=True,
        help="Authoritative goldenpath.risk-policy/v1 JSON source",
    )
    parser.add_argument(
        "--architecture-source",
        type=Path,
        required=True,
        help=(
            "Authoritative goldenpath.architecture/v1 JSON source, or a JSON object "
            "containing it under an architecture key"
        ),
    )
    parser.add_argument(
        "--desired-state-source",
        type=Path,
        required=True,
        help="Authoritative desired-state file or directory",
    )
    parser.add_argument(
        "--expected-commit",
        help="Optional exact commit SHA that the manifest must be bound to",
    )
    parser.add_argument(
        "--expected-plan-digest",
        help="Authoritative assurance-plan digest required for assurance-bearing evidence",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    try:
        validator = load_validator()
        manifest = validator.load_json(args.manifest)
        manifest_object = validator.require_dict(manifest, "manifest")
        if "inputs" not in manifest_object:
            validator.fail("manifest is missing required key: inputs")
        inputs = validator.require_dict(manifest_object["inputs"], "inputs")

        policy = validator.load_json(args.policy_source)
        require_versioned_object(policy, POLICY_SCHEMA_VERSION, str(args.policy_source))
        policy_digest = validator.canonical_digest(policy)

        architecture_raw = validator.load_json(args.architecture_source)
        architecture = architecture_document(
            architecture_raw, str(args.architecture_source)
        )
        architecture_digest = validator.canonical_digest(architecture)

        desired_digest = desired_state_digest(args.desired_state_source)

        compare_digest(
            validator,
            inputs,
            "policyDigest",
            policy_digest,
            "policy source",
        )
        compare_digest(
            validator,
            inputs,
            "architectureDigest",
            architecture_digest,
            "architecture source",
        )
        compare_digest(
            validator,
            inputs,
            "desiredStateDigest",
            desired_digest,
            "desired-state source",
        )

        validator.validate_manifest(
            manifest,
            args.expected_commit,
            args.expected_plan_digest,
        )
    except (RuntimeError, ValueError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1

    print(
        "PASS: Evidence Manifest matches authoritative policy, architecture, "
        "desired state, and contract semantics"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
