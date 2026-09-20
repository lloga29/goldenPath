# Continuous Assurance, Drift, and Recovery

GoldenPath v0.2 P3 extends the Runtime Lab from one-time deployment proof to bounded continuous-assurance exercises. The supported implementation remains ephemeral runtime evidence and does not claim production validation.

## Current state is authoritative

A signed `goldenpath.assurance-receipt/v1` is immutable evidence for the execution that produced it. It is not permanent proof of health and it is never rewritten.

P3 adds `goldenpath.continuous-assurance/v1`. Its `currentState` is derived from the newest required controls and recovery outcome. A historical `VERIFIED` receipt may be retained as history, but it cannot override a newer failed control. A recovered state must be re-observed and, when a current receipt is required, must bind a newly generated receipt rather than reuse historical evidence.

Supported states are:

- `VERIFIED_HEALTHY`: all required current controls pass and no recovery is pending.
- `DETECTED_DEGRADED`: a required current control fails and recovery has not completed.
- `RECOVERED_REVERIFIED`: recovery was attempted, required controls pass again, and the recovered state was observed.
- `FAILED`: a required control has an infrastructure failure or attempted recovery failed.
- `NEEDS_HUMAN`: automation reached a boundary it must not cross safely.

`scripts/evaluate-continuous-assurance.py` derives these states and rejects producer-selected states that contradict the controls.

## Runtime Lab scenarios

`runtime-lab/continuous-assurance.py` runs in the isolated kind lab after the initial workload is healthy and before teardown. Its blast radius is limited to the unique lab namespace, workload Application, and disposable cluster.

The live sequence proves:

1. the reference workload begins Synced, Healthy, available, and bound to the expected immutable image;
2. replica drift is detected and Argo CD restores the GitOps desired value;
3. a deliberately invalid image digest creates a controlled degraded state;
4. a privileged policy-bypass attempt carrying fake exception annotations is denied by Gatekeeper;
5. an expired governed exception is rejected;
6. the exact original image digest is restored;
7. the workload returns to Synced, Healthy, available state;
8. ordered `goldenpath.continuous-observations/v1` evidence is emitted;
9. the normal P2 signed receipt is generated and independently verified from the final recovered runtime;
10. `goldenpath.continuous-assurance/v1` binds that new current receipt to the recovered state.

## Historical receipt semantics

P3 enforces that a referenced historical receipt matches the same source, artifact, desired-state, and runtime subject and predates the current observation. A historical VERIFIED result never changes a degraded, failed, or needs-human current result.

For a recovered current state, a supplied current receipt must be VERIFIED, match the exact subject, be generated at or after the final recovery observation, and use a different receipt ID from historical evidence.

## Contract tests

`scripts/test-runtime-assurance-p3.py` proves that historical PASS evidence cannot mask a new failure, recovery produces distinct evidence, failed recovery remains FAILED, unsafe automation boundaries remain NEEDS_HUMAN, mismatched history fails closed, false producer state claims fail closed, and expired exceptions fail closed.

The live kind workflow adds runtime proof for drift, denial, rollback, and re-verification.

## Evidence boundary

P3 does not prove production recovery time, production rollback safety, managed-cloud behavior, organization-specific approval controls, or compliance certification. Those require separately scoped evidence from the actual target environment.
