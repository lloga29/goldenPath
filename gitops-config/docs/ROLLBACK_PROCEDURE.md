# GitOps Rollback Procedure

## Principle

Prefer reverting desired state in Git so the audit trail and runtime remain aligned. Roll back to a known-good immutable artifact; do not rebuild an old release.

## Planned rollback

```bash
git checkout -b rollback/<service>-<environment>
git revert <promotion-commit-sha>
git push -u origin rollback/<service>-<environment>
```

Open an expedited pull request, review the resulting desired state, merge it, and allow Argo CD to reconcile.

## Rollback helper

The repository also contains:

```bash
./scripts/rollback.sh <team> <service> <environment>
```

Validate the script behavior in a disposable repository before relying on it for production recovery.

## Emergency runtime rollback

When the normal Git path cannot meet the incident recovery objective, an authorized operator may use a direct runtime rollback such as:

```bash
kubectl rollout undo deployment/<service> -n <namespace>
kubectl rollout status deployment/<service> -n <namespace>
```

Immediately record the action and then reconcile Git to the intended known-good state. Otherwise Argo CD may restore the failing configuration.

## Verification

Check Argo CD health/sync state, workload rollout, logs, error rate, latency, key business transactions, and dependent services. Confirm desired and runtime state are aligned before closing the incident.

## Follow-up

Document the cause, recovery time, failed artifact/version, missing guardrails, and required corrective work.
