# Kubernetes and GitOps

Kubernetes delivery follows a GitOps model in which Git represents desired state and Argo CD performs reconciliation. Argo CD is the sole authoritative Kubernetes reconciliation engine in the Golden Path baseline; Flux controllers and Flux Helm custom resources are not required.

## Current reference structure

`gitops-config/` contains:

- Argo CD AppProjects;
- ApplicationSets for team applications, platform Helm add-ons, and Git-native platform resources;
- cluster metadata for development, staging, and production;
- Kustomize application bases and overlays;
- versioned Helm values for shared platform add-ons;
- Gateway API platform resources;
- Gatekeeper constraints and templates;
- promotion and rollback helpers;
- explicit examples that are outside reconciled paths.

## Platform add-ons

The current baseline includes reference configuration for:

- Envoy Gateway and Kubernetes Gateway API;
- cert-manager;
- External Secrets Operator;
- kube-prometheus-stack;
- Loki;
- Tempo;
- Gatekeeper.

`gitops-config/argocd/applicationsets/platform-apps.yaml` pins each chart and combines the upstream chart source with this repository as an Argo CD `$values` source. `scripts/validate-platform-helm.sh` renders every component with development, staging, and production values in root CI.

These declarations do not replace environment integration. Production adoption must configure real identity, TLS issuers, DNS, load-balancer behavior, storage, backups, alerting, upgrade ownership, and secret-management backends. The repository deliberately avoids inventing environment-specific Gateways, certificate authorities, DNS names, or secret endpoints.

## Gateway API

`gitops-config/platform/resources/gateway-class.yaml` declares the platform-owned `GatewayClass/golden-path` for Envoy Gateway. Environment owners must define real `Gateway` resources and application teams must define permitted route resources such as `HTTPRoute` according to the adopted authorization model.

The former ingress-nginx baseline is retired. Use [the ingress-nginx to Gateway API migration runbook](../operations/ingress-nginx-to-gateway-api.md) for existing workloads; do not remove a legacy controller before the replacement path is proven and rollback criteria are satisfied.

## GitOps invariants

1. Production desired state changes through reviewed Git changes.
2. Argo CD is the authoritative reconciler; another controller must not own the same desired-state boundary implicitly.
3. Production platform Applications omit automated sync in the reference model and require an explicit Argo CD sync after approval.
4. Emergency runtime changes are followed by Git reconciliation as soon as the incident allows.
5. Application images use immutable release references; `:latest` is not part of the paved road.
6. AppProjects explicitly constrain source repositories and destinations; wildcard source repositories are not permitted for the platform project.
7. Helm chart versions and values are reviewable in Git, and chart rendering is validated before merge.
8. Placeholder/example integration values remain outside active reconciled paths.

## Synchronization policy

Development is configured for automated reconciliation with pruning. Staging is automatically reconciled but does not prune by default. Production deliberately omits `syncPolicy.automated`; the operator must initiate synchronization after the Git change has passed the real organization's approvals.

This repository cannot itself prove organization-level branch protection, Argo CD SSO/RBAC, or cloud approval controls. Those require evidence from the target organization and runtime environments.

## Cluster registration

Argo CD cluster credentials should use the least privilege needed for managed namespaces/resources. Separate highly sensitive environments if one Argo CD control plane would create unacceptable shared blast radius. Placeholder cluster URLs in this reference repository must be replaced before operational adoption.

## Kustomize

Use bases for shared workload definitions and overlays for environment-specific patches. The repository uses the current `labels` transformer rather than deprecated `commonLabels`, and preserves intentional selector/template propagation explicitly with `includeSelectors` where required.

Validate rendered output in CI:

```bash
kustomize build gitops-config/apps/<team>/<service>/overlays/<environment>
```

## Runtime policy

Gatekeeper supplies admission-time enforcement for policies that must hold even if CI is bypassed. Roll out new admission policies through audit/dry-run, staged enforcement, and measured remediation when introducing them to existing workloads.

## Recovery

GitOps recovery depends on Git availability, cluster connectivity, Argo CD health, chart/source availability, and access to the artifact registry. The disaster-recovery plan must consider each dependency rather than assuming that restoring Argo CD alone restores the service.
