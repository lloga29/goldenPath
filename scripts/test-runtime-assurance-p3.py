#!/usr/bin/env python3
"""Exercise P3 continuous-assurance, drift, recovery, and historical-receipt semantics."""

from __future__ import annotations

import copy
import json
import subprocess
import sys
import tempfile
from datetime import datetime, timedelta, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EVALUATOR = ROOT / "scripts/evaluate-continuous-assurance.py"
EXCEPTION_VALIDATOR = ROOT / "platform-policies/scripts/validate-exceptions.py"
EXPIRED_EXCEPTION = ROOT / "platform-policies/tests/exceptions/expired.yaml"


def run(command: list[str], expected: int = 0) -> subprocess.CompletedProcess[str]:
    result = subprocess.run(command, cwd=ROOT, check=False, capture_output=True, text=True)
    if result.returncode != expected:
        raise RuntimeError(
            f"command returned {result.returncode}, expected {expected}: {' '.join(command)}\n"
            f"stdout:\n{result.stdout}\nstderr:\n{result.stderr}"
        )
    return result


def iso(value: datetime) -> str:
    return value.astimezone(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def write_json(path: Path, value: object) -> None:
    path.write_text(json.dumps(value, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def control(control_id: str, result: str, observed_at: str) -> dict[str, object]:
    return {"id": control_id, "required": True, "result": result, "observedAt": observed_at}


def receipt(receipt_id: str, generated_at: str, subject: dict[str, str], decision: str = "VERIFIED") -> dict[str, object]:
    return {
        "schemaVersion": "goldenpath.assurance-receipt/v1",
        "receiptId": receipt_id,
        "generatedAt": generated_at,
        "decision": decision,
        "subject": {
            "source": {"revision": subject["sourceRevision"]},
            "artifact": {"digest": subject["artifactDigest"]},
            "gitops": {"desiredStateRevision": subject["desiredStateRevision"]},
            "runtime": {"clusterIdentity": subject["clusterIdentity"]},
        },
    }


def observations(sequence_id: str, subject: dict[str, str], events: list[dict[str, object]], *, attempted: bool, result: str) -> dict[str, object]:
    return {
        "schemaVersion": "goldenpath.continuous-observations/v1",
        "sequenceId": sequence_id,
        "evidenceTier": "runtime",
        "environmentClass": "ephemeral-lab",
        "productionValidation": "NOT_CLAIMED",
        "subject": subject,
        "events": events,
        "recovery": {"attempted": attempted, "result": result},
    }


def evaluate(root: Path, observation: dict[str, object], *, historical: dict[str, object] | None = None, current: dict[str, object] | None = None, expected: int = 0) -> tuple[subprocess.CompletedProcess[str], dict[str, object] | None]:
    obs_path = root / "observations.json"
    out_path = root / "continuous-assurance.json"
    write_json(obs_path, observation)
    command = [sys.executable, str(EVALUATOR), "--observations", str(obs_path), "--output", str(out_path)]
    if historical is not None:
        history_path = root / "historical.json"
        write_json(history_path, historical)
        command.extend(["--historical-receipt", str(history_path)])
    if current is not None:
        current_path = root / "current.json"
        write_json(current_path, current)
        command.extend(["--current-receipt", str(current_path), "--require-current-receipt"])
    result = run(command, expected=expected)
    return result, json.loads(out_path.read_text(encoding="utf-8")) if expected == 0 else None


def main() -> int:
    now = datetime.now(timezone.utc).replace(microsecond=0)
    source = "a" * 40
    subject = {
        "sourceRevision": source,
        "artifactDigest": "sha256:" + "1" * 64,
        "desiredStateRevision": source,
        "clusterIdentity": "kind:p3-contract-test",
    }
    historical = receipt("receipt-history-001", iso(now - timedelta(minutes=10)), subject)

    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)

        degraded_time = iso(now)
        degraded = observations(
            "sequence-degraded-001",
            subject,
            [{
                "id": "drift-detected",
                "observedAt": degraded_time,
                "state": "DETECTED_DEGRADED",
                "controls": [control("artifact-digest-binding", "FAIL", degraded_time)],
            }],
            attempted=False,
            result="NOT_REQUIRED",
        )
        _, degraded_output = evaluate(root, degraded, historical=historical)
        if degraded_output["currentState"] != "DETECTED_DEGRADED":
            raise RuntimeError("historical VERIFIED receipt masked a new degraded current state")
        if degraded_output["historicalReceipt"]["decision"] != "VERIFIED":
            raise RuntimeError("historical receipt metadata was not preserved as historical evidence")

        recovery_time = iso(now + timedelta(minutes=1))
        recovered = observations(
            "sequence-recovered-001",
            subject,
            [
                {
                    "id": "drift-detected",
                    "observedAt": degraded_time,
                    "state": "DETECTED_DEGRADED",
                    "controls": [control("gitops-drift", "FAIL", degraded_time)],
                },
                {
                    "id": "recovery-complete",
                    "observedAt": recovery_time,
                    "state": "RECOVERED_REVERIFIED",
                    "controls": [
                        control("gitops-drift", "PASS", recovery_time),
                        control("runtime-health", "PASS", recovery_time),
                    ],
                },
            ],
            attempted=True,
            result="RECOVERED",
        )
        current = receipt("receipt-current-002", iso(now + timedelta(minutes=2)), subject)
        _, recovered_output = evaluate(root, recovered, historical=historical, current=current)
        if recovered_output["currentState"] != "RECOVERED_REVERIFIED":
            raise RuntimeError("recovery did not derive RECOVERED_REVERIFIED")
        if recovered_output["currentReceipt"]["receiptId"] == recovered_output["historicalReceipt"]["receiptId"]:
            raise RuntimeError("recovery reused the historical receipt instead of new evidence")
        if recovered_output["evidenceDigest"] == degraded_output["evidenceDigest"]:
            raise RuntimeError("recovery did not produce distinct continuous-assurance evidence")

        failed_time = iso(now + timedelta(minutes=3))
        failed = observations(
            "sequence-failed-001",
            subject,
            [{
                "id": "rollback-failed",
                "observedAt": failed_time,
                "state": "FAILED",
                "controls": [control("controlled-rollback", "FAIL", failed_time)],
            }],
            attempted=True,
            result="FAILED",
        )
        _, failed_output = evaluate(root, failed)
        if failed_output["currentState"] != "FAILED":
            raise RuntimeError("failed recovery did not remain explicitly FAILED")

        human_time = iso(now + timedelta(minutes=4))
        human = observations(
            "sequence-human-001",
            subject,
            [{
                "id": "approval-boundary",
                "observedAt": human_time,
                "state": "NEEDS_HUMAN",
                "controls": [control("human-approval", "NEEDS_HUMAN", human_time)],
            }],
            attempted=True,
            result="NEEDS_HUMAN",
        )
        _, human_output = evaluate(root, human)
        if human_output["currentState"] != "NEEDS_HUMAN":
            raise RuntimeError("unsafe automation boundary did not remain NEEDS_HUMAN")

        mismatch_history = copy.deepcopy(historical)
        mismatch_history["subject"]["runtime"]["clusterIdentity"] = "kind:other-cluster"
        result, _ = evaluate(root, degraded, historical=mismatch_history, expected=1)
        if "subject does not match" not in (result.stdout + result.stderr):
            raise RuntimeError("mismatched historical receipt did not fail closed")

        contradiction = copy.deepcopy(degraded)
        contradiction["events"][0]["state"] = "VERIFIED_HEALTHY"
        result, _ = evaluate(root, contradiction, expected=1)
        if "contradicts derived" not in (result.stdout + result.stderr):
            raise RuntimeError("producer-selected false healthy state did not fail closed")

        expired = run([sys.executable, str(EXCEPTION_VALIDATOR), str(EXPIRED_EXCEPTION)], expected=1)
        if "expired" not in (expired.stdout + expired.stderr).lower():
            raise RuntimeError("expired policy exception was not rejected fail closed")

    print(
        "PASS: P3 continuous assurance preserves historical receipts without masking current failures, "
        "derives degraded/recovered/failed/needs-human states, requires new recovery evidence, "
        "and rejects mismatched history, false state claims, and expired exceptions"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
