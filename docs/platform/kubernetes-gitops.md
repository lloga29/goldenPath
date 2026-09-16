# Kubernetes and GitOps

Kubernetes delivery follows a GitOps model in which Git represents desired state and Argo CD performs reconciliation.

## Current reference structure

`gitops-config/` contains:

- Argo CD AppProjects;
- ApplicationSets;
- cluster metadata for dev, staging, and production;
- Kustomize application base and overlays;
- platform add-on definitions;
- Gatekeeper constraints and templates;
- promotion and rollback helpers.

## Platform add-ons

The current baseline includes reference configuration for:

- ingress-nginx;
- cert-manager;
- External Secrets;
- Prometheus stack;
- Loki;
- Tempo;
- Gatekeeper.

These manifests do not replace environment integration. Production adoption must configure durable storage, resource limits, HA, identity, TLS, DNS, backups, upgrades, alerting, and support ownership as required.

## GitOps invariants

1. Production desired state changes through reviewed Git changes.
2. Argo CD reconciles rather than relying on persistent manual `kubectl` mutation.
3. Emergency runtime changes are followed by Git reconciliation as soon as the incident allows.
4. Application images are immutable references.
5. Environment overlays hold intentional differences; duplicated drift between environments is avoided.
6. AppProjects restrict repositories, destinations, and resource permissions.

## Synchronization policy

Development can use aggressive automated sync and pruning when blast radius is small. Staging may automate sync while applying stronger validation. Production should use the organization's chosen approval and synchronization policy; the reference repository does not by itself enforce organization-level production approvals.

## Cluster registration

Argo CD cluster credentials should use the least privilege needed for managed namespaces/resources. Separate highly sensitive environments if one Argo CD control plane would create unacceptable shared blast radius.

## Kustomize

Use bases for shared workload definitions and overlays for environment-specific patches. Validate rendered output in CI:

```bash
kustomize build gitops-config/apps/<team>/<service>/overlays/<environment>
```

## Runtime policy

Gatekeeper supplies admission-time enforcement for policies that must hold even if CI is bypassed. Roll out new admission policies through audit/dry-run, staged enforcement, and measured remediation when introducing them to existing workloads.

## Recovery

GitOps recovery depends on Git availability, cluster connectivity, Argo CD health, and access to the artifact registry. The disaster-recovery plan must consider each dependency rather than assuming that restoring Argo CD alone restores the service.
