# Runbook: Failed Deployment

## Trigger

A GitOps sync or Kubernetes rollout fails, stalls, becomes unhealthy, or produces an application that does not meet readiness expectations.

## Triage

```bash
argocd app get <application>
argocd app diff <application>
kubectl get deploy,rs,pods -n <namespace>
kubectl get events -n <namespace> --sort-by=.lastTimestamp
kubectl describe pod <pod> -n <namespace>
kubectl logs <pod> -n <namespace> --all-containers --tail=200
```

## Common categories

- image not found or registry authorization;
- image architecture/runtime incompatibility;
- readiness/liveness failure;
- missing Secret/ConfigMap;
- secret synchronization failure;
- resource quota or scheduling pressure;
- admission-policy denial;
- service account/RBAC failure;
- invalid manifest or Kustomize output;
- migration/startup dependency failure;
- ingress/DNS/TLS dependency failure.

## Mitigation

If the new version is the cause and impact is significant, follow the application rollback runbook. If the failure is configuration-only, correct desired state through Git whenever time permits.

## Validation

Confirm Argo CD is synced/healthy, workload rollout completed, application health signals recovered, expected traffic succeeds, and alerts clear for the correct reason.

## Follow-up

Add missing pre-deployment validation, policy, template defaults, alerts, or documentation based on the failure mode.
