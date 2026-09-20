# Runtime Drift and Recovery Runbook

Use this runbook when a GoldenPath-managed workload is no longer aligned with its expected immutable artifact, GitOps desired state, admission policy, or health controls.

## Safety boundary

For the v0.2 Runtime Lab, all failure injection is limited to the unique disposable kind cluster, namespace, and Argo CD workload Application. Real-environment recovery requires its own approved operational scope.

## Detect

Check the current runtime state rather than relying on a previous passing receipt. Verify the Argo CD Application is Synced and Healthy, the workload is available at the expected replica count, and the observed image equals the expected immutable digest.

Missing, stale, mismatched, contradictory, or failed required evidence is non-passing.

## Mitigate

Prefer reconciliation to the known-good GitOps state. Do not hide drift by editing generated evidence or reusing an earlier PASS receipt.

For a bad image promotion, restore the previously verified immutable digest through the authoritative desired-state path. In the Runtime Lab, P3 restores the workload Application image override to the exact original digest.

## Verify recovery

Recovery is not complete merely because a rollback action returned successfully. Re-observe all applicable controls:

- Argo CD reports Synced.
- Argo CD reports Healthy.
- The workload is available at the expected replica count.
- The workload image equals the expected immutable digest.
- Admission denial still works.
- Governed exceptions still validate fail closed.
- A new current receipt is generated when the assurance path requires one.

The current state becomes `RECOVERED_REVERIFIED` only after those observations pass. Preserve the previous receipt as historical evidence; do not overwrite it.

## Escalate

Use `NEEDS_HUMAN` when automation cannot safely determine or execute recovery, including ambiguous desired state, approval boundaries, identity mismatches, conflicting evidence, or an unbounded recovery action.

Keep `FAILED` when recovery was attempted but required controls remain failed.

## Evidence to retain

Retain the ordered continuous observations, final continuous-assurance document, signed runtime receipt, runtime evidence, public verification key for the bounded lab execution, and relevant workflow logs.

These artifacts are runtime evidence for that execution only and are not production validation.
