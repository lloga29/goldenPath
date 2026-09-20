#!/usr/bin/env python3
"""Derive current GoldenPath continuous-assurance state from ordered runtime observations."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

OBS_SCHEMA = "goldenpath.continuous-observations/v1"
OUTPUT_SCHEMA = "goldenpath.continuous-assurance/v1"
RECEIPT_SCHEMA = "goldenpath.assurance-receipt/v1"
SHA_RE = re.compile(r"^[0-9a-f]{40}$")
DIGEST_RE = re.compile(r"^sha256:[0-9a-f]{64}$")
ID_RE = re.compile(r"^[a-z0-9][a-z0-9._-]{2,127}$")
RESULTS = {"PASS", "FAIL", "INFRASTRUCTURE_FAILURE", "NEEDS_HUMAN"}
STATES = {
    "VERIFIED_HEALTHY",
    "DETECTED_DEGRADED",
    "RECOVERED_REVERIFIED",
    "FAILED",
    "NEEDS_HUMAN",
}


class AssuranceError(ValueError):
    pass


def fail(message: str) -> None:
    raise AssuranceError(message)


def load_json(path: Path) -> dict[str, object]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        fail(f"cannot load {path}: {exc}")
    if not isinstance(value, dict):
        fail(f"{path} must contain a JSON object")
    return value


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


def canonical_digest(value: object) -> str:
    raw = json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode("utf-8")
    return "sha256:" + hashlib.sha256(raw).hexdigest()


def require_text(root: dict[str, object], key: str, path: str) -> str:
    value = root.get(key)
    if not isinstance(value, str) or not value:
        fail(f"{path}.{key} must be a non-empty string")
    return value


def validate_subject(value: object, path: str) -> dict[str, str]:
    if not isinstance(value, dict):
        fail(f"{path} must be an object")
    required = {"sourceRevision", "artifactDigest", "desiredStateRevision", "clusterIdentity"}
    if set(value) != required:
        fail(f"{path} must contain exactly {sorted(required)}")
    source = require_text(value, "sourceRevision", path)
    desired = require_text(value, "desiredStateRevision", path)
    digest = require_text(value, "artifactDigest", path)
    cluster = require_text(value, "clusterIdentity", path)
    if not SHA_RE.fullmatch(source) or not SHA_RE.fullmatch(desired):
        fail(f"{path} source and desired-state revisions must be exact lowercase 40-character Git SHAs")
    if source != desired:
        fail(f"{path} source and desired-state revisions must match for the supported Runtime Lab")
    if not DIGEST_RE.fullmatch(digest):
        fail(f"{path}.artifactDigest must be sha256:<64 lowercase hex>")
    return {
        "sourceRevision": source,
        "artifactDigest": digest,
        "desiredStateRevision": desired,
        "clusterIdentity": cluster,
    }


def derive_state(controls: list[dict[str, object]], recovery_attempted: bool, recovery_result: str) -> str:
    required_results = [str(item["result"]) for item in controls if item["required"] is True]
    if not required_results:
        fail("each observation must contain at least one required control")
    if "NEEDS_HUMAN" in required_results or recovery_result == "NEEDS_HUMAN":
        return "NEEDS_HUMAN"
    if "INFRASTRUCTURE_FAILURE" in required_results:
        return "FAILED"
    if "FAIL" in required_results:
        return "FAILED" if recovery_attempted and recovery_result == "FAILED" else "DETECTED_DEGRADED"
    if any(result != "PASS" for result in required_results):
        fail("unsupported required-control result")
    if recovery_attempted:
        if recovery_result == "RECOVERED":
            return "RECOVERED_REVERIFIED"
        if recovery_result == "FAILED":
            return "FAILED"
        if recovery_result == "NEEDS_HUMAN":
            return "NEEDS_HUMAN"
        fail("recovery.attempted=true requires RECOVERED, FAILED, or NEEDS_HUMAN")
    if recovery_result != "NOT_REQUIRED":
        fail("recovery.attempted=false requires recovery.result=NOT_REQUIRED")
    return "VERIFIED_HEALTHY"


def validate_controls(value: object, path: str) -> list[dict[str, object]]:
    if not isinstance(value, list) or not value:
        fail(f"{path} must be a non-empty array")
    seen: set[str] = set()
    controls: list[dict[str, object]] = []
    for index, item in enumerate(value):
        item_path = f"{path}[{index}]"
        if not isinstance(item, dict):
            fail(f"{item_path} must be an object")
        allowed = {"id", "required", "result", "observedAt", "reason"}
        required = {"id", "required", "result", "observedAt"}
        if not required.issubset(item) or not set(item).issubset(allowed):
            fail(f"{item_path} has missing or unsupported fields")
        control_id = require_text(item, "id", item_path)
        if not ID_RE.fullmatch(control_id):
            fail(f"{item_path}.id has an invalid format")
        if control_id in seen:
            fail(f"duplicate control id in one observation: {control_id}")
        seen.add(control_id)
        if not isinstance(item["required"], bool):
            fail(f"{item_path}.required must be boolean")
        if item["result"] not in RESULTS:
            fail(f"{item_path}.result is unsupported")
        parse_time(item["observedAt"], f"{item_path}.observedAt")
        if "reason" in item and (not isinstance(item["reason"], str) or not item["reason"].strip()):
            fail(f"{item_path}.reason must be non-empty when present")
        controls.append(dict(item))
    return controls


def validate_observations(root: dict[str, object]) -> tuple[dict[str, str], list[dict[str, object]], dict[str, object]]:
    if root.get("schemaVersion") != OBS_SCHEMA:
        fail(f"observations schema must be {OBS_SCHEMA}")
    if root.get("evidenceTier") != "runtime":
        fail("continuous observations must use evidenceTier=runtime")
    if root.get("environmentClass") != "ephemeral-lab":
        fail("P3 Runtime Lab observations must use environmentClass=ephemeral-lab")
    if root.get("productionValidation") != "NOT_CLAIMED":
        fail("continuous observations must keep productionValidation=NOT_CLAIMED")
    sequence_id = require_text(root, "sequenceId", "observations")
    if not ID_RE.fullmatch(sequence_id):
        fail("observations.sequenceId has an invalid format")
    subject = validate_subject(root.get("subject"), "observations.subject")
    recovery = root.get("recovery")
    if not isinstance(recovery, dict):
        fail("observations.recovery must be an object")
    if set(recovery) != {"attempted", "result"}:
        fail("observations.recovery must contain exactly attempted and result")
    if not isinstance(recovery["attempted"], bool):
        fail("observations.recovery.attempted must be boolean")
    if recovery["result"] not in {"NOT_REQUIRED", "RECOVERED", "FAILED", "NEEDS_HUMAN"}:
        fail("observations.recovery.result is unsupported")

    events = root.get("events")
    if not isinstance(events, list) or not events:
        fail("observations.events must be a non-empty array")
    validated: list[dict[str, object]] = []
    previous_time: datetime | None = None
    for index, event in enumerate(events):
        path = f"observations.events[{index}]"
        if not isinstance(event, dict):
            fail(f"{path} must be an object")
        if set(event) != {"id", "observedAt", "state", "controls"}:
            fail(f"{path} must contain exactly id, observedAt, state, controls")
        event_id = require_text(event, "id", path)
        if not ID_RE.fullmatch(event_id):
            fail(f"{path}.id has an invalid format")
        observed_at = parse_time(event["observedAt"], f"{path}.observedAt")
        if previous_time is not None and observed_at < previous_time:
            fail("observation events must be chronological")
        previous_time = observed_at
        controls = validate_controls(event["controls"], f"{path}.controls")
        is_final = index == len(events) - 1
        attempted = bool(recovery["attempted"]) if is_final else False
        result = str(recovery["result"]) if is_final else "NOT_REQUIRED"
        derived = derive_state(controls, attempted, result)
        if event["state"] not in STATES:
            fail(f"{path}.state is unsupported")
        if event["state"] != derived:
            fail(f"{path}.state={event['state']} contradicts derived current control state {derived}")
        validated.append({
            "id": event_id,
            "observedAt": event["observedAt"],
            "state": derived,
            "controls": controls,
        })
    return subject, validated, dict(recovery)


def receipt_ref(receipt: dict[str, object], subject: dict[str, str], label: str) -> dict[str, object]:
    if receipt.get("schemaVersion") != RECEIPT_SCHEMA:
        fail(f"{label} receipt must use {RECEIPT_SCHEMA}")
    receipt_id = require_text(receipt, "receiptId", label)
    if not ID_RE.fullmatch(receipt_id):
        fail(f"{label} receiptId has an invalid format")
    generated_at = require_text(receipt, "generatedAt", label)
    parse_time(generated_at, f"{label}.generatedAt")
    decision = receipt.get("decision")
    if decision not in {"VERIFIED", "NOT_VERIFIED", "NEEDS_HUMAN"}:
        fail(f"{label}.decision is unsupported")
    receipt_subject = receipt.get("subject")
    if not isinstance(receipt_subject, dict):
        fail(f"{label}.subject must be an object")
    try:
        actual = {
            "sourceRevision": receipt_subject["source"]["revision"],
            "artifactDigest": receipt_subject["artifact"]["digest"],
            "desiredStateRevision": receipt_subject["gitops"]["desiredStateRevision"],
            "clusterIdentity": receipt_subject["runtime"]["clusterIdentity"],
        }
    except (KeyError, TypeError):
        fail(f"{label}.subject is missing required identity bindings")
    if actual != subject:
        fail(f"{label} receipt subject does not match continuous-assurance subject")
    return {
        "receiptId": receipt_id,
        "generatedAt": generated_at,
        "decision": decision,
        "digest": canonical_digest(receipt),
    }


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--observations", required=True, type=Path)
    parser.add_argument("--historical-receipt", type=Path)
    parser.add_argument("--current-receipt", type=Path)
    parser.add_argument("--require-current-receipt", action="store_true")
    parser.add_argument("--output", required=True, type=Path)
    return parser


def main() -> int:
    args = build_parser().parse_args()
    try:
        observations = load_json(args.observations)
        subject, events, recovery = validate_observations(observations)
        current = events[-1]
        current_state = str(current["state"])

        historical_ref = None
        if args.historical_receipt:
            historical = load_json(args.historical_receipt)
            historical_ref = receipt_ref(historical, subject, "historical")
            if parse_time(historical_ref["generatedAt"], "historical.generatedAt") >= parse_time(current["observedAt"], "current.observedAt"):
                fail("historical receipt must predate the current observation")

        current_ref = None
        if args.current_receipt:
            if current_state not in {"VERIFIED_HEALTHY", "RECOVERED_REVERIFIED"}:
                fail("a current VERIFIED receipt cannot override a degraded, failed, or needs-human state")
            current_receipt = load_json(args.current_receipt)
            current_ref = receipt_ref(current_receipt, subject, "current")
            if current_ref["decision"] != "VERIFIED":
                fail("healthy or recovered current state requires a VERIFIED current receipt")
            if parse_time(current_ref["generatedAt"], "current.generatedAt") < parse_time(current["observedAt"], "current.observedAt"):
                fail("current receipt must be generated at or after the final current observation")
            if historical_ref and current_ref["receiptId"] == historical_ref["receiptId"]:
                fail("recovery must produce a new receipt instead of reusing historical evidence")
        elif args.require_current_receipt and current_state in {"VERIFIED_HEALTHY", "RECOVERED_REVERIFIED"}:
            fail("healthy or recovered state requires --current-receipt")

        output: dict[str, object] = {
            "schemaVersion": OUTPUT_SCHEMA,
            "sequenceId": observations["sequenceId"],
            "observedAt": current["observedAt"],
            "claim": {"tier": "runtime"},
            "productionValidation": "NOT_CLAIMED",
            "subject": subject,
            "currentState": current_state,
            "controls": current["controls"],
            "recovery": recovery,
            "history": [
                {"id": event["id"], "observedAt": event["observedAt"], "state": event["state"]}
                for event in events
            ],
        }
        if historical_ref:
            output["historicalReceipt"] = historical_ref
        if current_ref:
            output["currentReceipt"] = current_ref
        output["evidenceDigest"] = canonical_digest(output)

        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(json.dumps(output, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    except AssuranceError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1

    print(f"PASS: continuous assurance current state is {current_state}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
