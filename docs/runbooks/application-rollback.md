# Runbook: Application Rollback

## Trigger

Use this runbook when a recently promoted application version causes errors, latency, failed readiness, business regression, or another production-impacting condition and rollback is the safest mitigation.

## Safety principles

- Prefer GitOps rollback so desired state and runtime state remain aligned.
- Roll back to a known-good immutable image reference.
- Do not rebuild an old release.
- Check database/schema compatibility before reverting application code.
- Preserve incident evidence before destructive cleanup.

## Diagnosis

```bash
argocd app get <application>
kubectl rollout status deployment/<service> -n <namespace>
kubectl get pods -n <namespace> -l app=<service>
kubectl get events -n <namespace> --sort-by=.lastTimestamp
```

Confirm the current image:

```bash
kubectl get deployment/<service> -n <namespace> \
  -o jsonpath='{.spec.template.spec.containers[*].image}'
```

## Preferred recovery: GitOps revert

1. Identify the Git commit or image reference for the last known-good version.
2. Revert or update the target environment overlay.
3. Open/review the emergency pull request according to the incident process.
4. Merge the known-good desired state.
5. Sync or allow Argo CD to reconcile.

Validate:

```bash
argocd app wait <application> --health --sync
kubectl rollout status deployment/<service> -n <namespace>
```

## Emergency runtime rollback

If GitOps cannot meet the required recovery time, an authorized operator may use a runtime rollback such as `kubectl rollout undo`. Record the exact command and actor. As soon as impact is mitigated, update Git so Argo CD does not reapply the broken desired state.

## Validation

Verify application health, error rate, latency, key business transaction, logs, alerts, and downstream dependencies. Confirm Argo CD reports the intended state.

## Follow-up

Document the failed artifact, root cause, rollback duration, missing tests/guards, and changes required to prevent recurrence.
