# GitOps Promotion Guide

## Principle: Build Once, Promote

Release artifacts are built once and promoted between environments without rebuilding.

- Never promote `:latest`.
- Prefer an immutable digest; an immutable semantic-version or commit tag is acceptable when registry immutability is enforced.
- Promotion changes desired state; it does not create a new executable artifact.

## Flow

```text
Development -> Staging -> Production
      same immutable artifact identity
```

## Development to staging

```bash
./scripts/promote.sh <team> <service> dev staging <version>
```

Review the resulting Kustomize change and render the target overlay before merge:

```bash
kustomize build apps/<team>/<service>/overlays/staging
```

## Staging to production

```bash
./scripts/promote.sh <team> <service> staging prod <version>
```

Production promotion should require the organization's configured review and environment protection rules. Do not rely on documentation alone to enforce reviewer counts or approvals.

## Pre-production checks

Confirm the artifact exists, staging is healthy, required checks passed, migrations are compatible, relevant SLOs/alerts show no active regression, and rollback is understood.

## Post-promotion verification

```bash
argocd app get <application>
argocd app wait <application> --health --sync
kubectl get pods -n <namespace> -l app.kubernetes.io/name=<service>
```

Verify service-level metrics and a representative business transaction in addition to pod health.

## Failure

If promotion causes degradation, use [Rollback Procedure](ROLLBACK_PROCEDURE.md) and the platform application rollback runbook.
