#!/usr/bin/env python3
"""Exercise bounded Runtime Lab drift, denial, rollback, and recovery scenarios."""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path


def iso_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def run(command: list[str], *, expected: int | None = 0) -> subprocess.CompletedProcess[str]:
    result = subprocess.run(command, check=False, capture_output=True, text=True)
    if expected is not None and result.returncode != expected:
        raise RuntimeError(
            f"command returned {result.returncode}, expected {expected}: {' '.join(command)}\n"
            f"stdout:\n{result.stdout}\nstderr:\n{result.stderr}"
        )
    return result


def kubectl(*args: str, expected: int | None = 0) -> subprocess.CompletedProcess[str]:
    return run(["kubectl", *args], expected=expected)


def wait_until(description: str, timeout: int, predicate) -> None:
    deadline = time.monotonic() + timeout
    last = ""
    while time.monotonic() < deadline:
        ok, last = predicate()
        if ok:
            return
        time.sleep(3)
    raise RuntimeError(f"timed out waiting for {description}: {last}")


def app_status(app: str) -> tuple[str, str]:
    sync = kubectl("-n", "argocd", "get", "application", app, "-o", "jsonpath={.status.sync.status}").stdout
    health = kubectl("-n", "argocd", "get", "application", app, "-o", "jsonpath={.status.health.status}").stdout
    return sync.strip(), health.strip()


def deployment_state(namespace: str) -> tuple[int, int, str]:
    raw = kubectl("-n", namespace, "get", "deployment", "goldenpath-runtime", "-o", "json").stdout
    obj = json.loads(raw)
    desired = int(obj.get("spec", {}).get("replicas", 0))
    available = int(obj.get("status", {}).get("availableReplicas", 0))
    containers = obj.get("spec", {}).get("template", {}).get("spec", {}).get("containers", [])
    image = containers[0].get("image", "") if containers else ""
    return desired, available, image


def control(control_id: str, result: str, reason: str | None = None) -> dict[str, object]:
    item: dict[str, object] = {
        "id": control_id,
        "required": True,
        "result": result,
        "observedAt": iso_now(),
    }
    if reason:
        item["reason"] = reason
    return item


def healthy_controls(namespace: str, app: str, expected_image: str) -> list[dict[str, object]]:
    sync, health = app_status(app)
    desired, available, image = deployment_state(namespace)
    return [
        control("gitops-sync", "PASS" if sync == "Synced" else "FAIL", f"sync={sync or 'unknown'}"),
        control("gitops-health", "PASS" if health == "Healthy" else "FAIL", f"health={health or 'unknown'}"),
        control("artifact-digest-binding", "PASS" if image == expected_image else "FAIL", f"image={image}"),
        control(
            "workload-availability",
            "PASS" if desired == 1 and available >= 1 else "FAIL",
            f"desired={desired} available={available}",
        ),
    ]


def event(event_id: str, state: str, controls: list[dict[str, object]]) -> dict[str, object]:
    return {"id": event_id, "observedAt": iso_now(), "state": state, "controls": controls}


def refresh_app(app: str) -> None:
    kubectl(
        "-n", "argocd", "annotate", "application", app,
        "argocd.argoproj.io/refresh=hard", "--overwrite",
    )


def set_app_image(app: str, image: str) -> None:
    patch = {"spec": {"source": {"kustomize": {"images": [f"goldenpath-runtime/reference={image}"]}}}}
    kubectl("-n", "argocd", "patch", "application", app, "--type=merge", "-p", json.dumps(patch))
    refresh_app(app)


def wait_healthy(namespace: str, app: str, expected_image: str, timeout: int) -> None:
    def predicate() -> tuple[bool, str]:
        sync, health = app_status(app)
        desired, available, image = deployment_state(namespace)
        ok = sync == "Synced" and health == "Healthy" and desired == 1 and available >= 1 and image == expected_image
        return ok, f"sync={sync} health={health} desired={desired} available={available} image={image}"
    wait_until("healthy reconciled workload", timeout, predicate)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--namespace", required=True)
    parser.add_argument("--workload-app", required=True)
    parser.add_argument("--image-ref", required=True)
    parser.add_argument("--image-digest", required=True)
    parser.add_argument("--source-revision", required=True)
    parser.add_argument("--cluster-identity", required=True)
    parser.add_argument("--artifact-dir", required=True, type=Path)
    parser.add_argument("--timeout-seconds", type=int, default=180)
    args = parser.parse_args()

    sequence_id = f"continuous-{args.workload_app}".lower().replace("_", "-")[:120]
    events: list[dict[str, object]] = []
    bad_image = args.image_ref.split("@", 1)[0] + "@sha256:" + "0" * 64
    app_mutated = False

    try:
        wait_healthy(args.namespace, args.workload_app, args.image_ref, args.timeout_seconds)
        events.append(event("initial-healthy", "VERIFIED_HEALTHY", healthy_controls(args.namespace, args.workload_app, args.image_ref)))

        patched = kubectl(
            "-n", args.namespace, "patch", "deployment", "goldenpath-runtime",
            "--type=merge", "-p", '{"spec":{"replicas":2}}',
            "-o", "jsonpath={.spec.replicas}",
        ).stdout.strip()
        if patched != "2":
            raise RuntimeError(f"runtime drift injection did not set replicas=2, got {patched!r}")
        events.append(event(
            "runtime-drift-detected",
            "DETECTED_DEGRADED",
            [control("runtime-replica-drift", "FAIL", "deployment replicas changed from GitOps desired value 1 to 2")],
        ))
        refresh_app(args.workload_app)
        wait_healthy(args.namespace, args.workload_app, args.image_ref, args.timeout_seconds)
        events.append(event(
            "runtime-drift-recovered",
            "VERIFIED_HEALTHY",
            [control("runtime-replica-drift", "PASS", "Argo CD self-healed deployment replicas back to 1")],
        ))

        set_app_image(args.workload_app, bad_image)
        app_mutated = True

        def bad_applied() -> tuple[bool, str]:
            _, _, image = deployment_state(args.namespace)
            return image == bad_image, f"deployment image={image}"

        wait_until("controlled bad deployment to become desired runtime state", args.timeout_seconds, bad_applied)
        events.append(event(
            "bad-deployment-detected",
            "DETECTED_DEGRADED",
            [control("artifact-digest-binding", "FAIL", f"controlled bad image became desired: {bad_image}")],
        ))

        bypass_manifest = {
            "apiVersion": "v1",
            "kind": "Pod",
            "metadata": {
                "name": "p3-policy-bypass-attempt",
                "namespace": args.namespace,
                "annotations": {
                    "goldenpath.dev/policy-exception": "EXC-2020-999",
                    "goldenpath.dev/bypass": "true",
                },
                "labels": {
                    "app.kubernetes.io/name": "p3-policy-bypass-attempt",
                    "app.kubernetes.io/component": "test",
                    "app.kubernetes.io/part-of": "goldenpath-runtime-lab",
                    "team": "platform",
                    "environment": "ephemeral",
                },
            },
            "spec": {
                "securityContext": {"runAsNonRoot": True},
                "containers": [{
                    "name": "denied",
                    "image": args.image_ref,
                    "resources": {
                        "requests": {"cpu": "10m", "memory": "8Mi"},
                        "limits": {"cpu": "20m", "memory": "16Mi"},
                    },
                    "securityContext": {"privileged": True},
                }],
            },
        }
        denial = subprocess.run(
            ["kubectl", "apply", "--dry-run=server", "-f", "-"],
            input=json.dumps(bypass_manifest),
            check=False,
            capture_output=True,
            text=True,
        )
        denial_output = denial.stdout + denial.stderr
        if denial.returncode == 0 or "deny-privileged-containers" not in denial_output:
            raise RuntimeError(f"policy bypass attempt was not denied by Gatekeeper:\n{denial_output}")

        root = Path(__file__).resolve().parents[1]
        expired = subprocess.run(
            [sys.executable, str(root / "platform-policies/scripts/validate-exceptions.py"), str(root / "platform-policies/tests/exceptions/expired.yaml")],
            check=False,
            capture_output=True,
            text=True,
        )
        if expired.returncode == 0 or "expired" not in (expired.stdout + expired.stderr).lower():
            raise RuntimeError("expired policy exception fixture did not fail closed")

        set_app_image(args.workload_app, args.image_ref)
        app_mutated = False
        wait_healthy(args.namespace, args.workload_app, args.image_ref, args.timeout_seconds)
        final_controls = healthy_controls(args.namespace, args.workload_app, args.image_ref)
        final_controls.extend([
            control("runtime-drift-recovery", "PASS", "replica drift was detected and reconciled to desired state"),
            control("controlled-rollback", "PASS", "bad image override was rolled back to the exact original digest"),
            control("policy-bypass-denial", "PASS", "privileged bypass attempt with fake exception annotation was denied"),
            control("expired-exception-rejection", "PASS", "expired exception registry failed closed"),
        ])
        events.append(event("recovery-complete", "RECOVERED_REVERIFIED", final_controls))

        output = {
            "schemaVersion": "goldenpath.continuous-observations/v1",
            "sequenceId": sequence_id,
            "evidenceTier": "runtime",
            "environmentClass": "ephemeral-lab",
            "productionValidation": "NOT_CLAIMED",
            "subject": {
                "sourceRevision": args.source_revision,
                "artifactDigest": args.image_digest,
                "desiredStateRevision": args.source_revision,
                "clusterIdentity": args.cluster_identity,
            },
            "events": events,
            "recovery": {"attempted": True, "result": "RECOVERED"},
        }
        args.artifact_dir.mkdir(parents=True, exist_ok=True)
        target = args.artifact_dir / "continuous-observations.json"
        target.write_text(json.dumps(output, indent=2, sort_keys=True) + "\n", encoding="utf-8")
        print(f"PASS: P3 bounded drift/recovery scenarios completed; observations: {target}")
        return 0
    except Exception as exc:
        print(f"ERROR: P3 continuous assurance scenario failed: {exc}", file=sys.stderr)
        return 1
    finally:
        if app_mutated:
            try:
                set_app_image(args.workload_app, args.image_ref)
            except Exception:
                pass
        try:
            kubectl("-n", args.namespace, "scale", "deployment/goldenpath-runtime", "--replicas=1", expected=None)
        except Exception:
            pass


if __name__ == "__main__":
    raise SystemExit(main())
