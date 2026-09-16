# ADR-0007: Use Argo CD Native Helm Reconciliation for Platform Add-ons

- Status: Accepted

## Context

ADR-0001 establishes Argo CD as the primary Kubernetes reconciliation engine. The repository nevertheless modeled shared platform add-ons as Flux `HelmRelease` custom resources and referenced `HelmRepository` objects in `flux-system`. No Flux source-controller, helm-controller, or repository objects were part of the Golden Path bootstrap, so a fresh cluster could not reconcile that desired state from repository contents alone.

Running two reconcilers for the same platform layer would also create unnecessary ownership, upgrade, incident-response, and security boundaries.

## Decision

Argo CD is the sole authoritative reconciler for Kubernetes application and platform desired state in this repository.

Platform add-ons are represented as Helm sources in an Argo CD `ApplicationSet`. Chart configuration is stored as versioned values files in this repository and referenced through Argo CD multi-source Applications. Upstream chart repositories remain explicitly allowlisted by the platform `AppProject`.

Development and staging reconcile automatically. Production Applications intentionally omit automated sync and require an explicit operator action after the Git change is reviewed.

Flux `HelmRelease`, `HelmRepository`, `flux-system`, and Flux controller dependencies are not part of the Golden Path baseline.

## Consequences

- One reconciliation engine owns platform desired state.
- Git history captures chart pins and configuration changes.
- Helm rendering is performed by Argo CD; Helm does not become a second release-state authority.
- Root CI validates the ApplicationSet contract and renders pinned charts with repository values.
- Upstream chart availability becomes part of the supply-chain boundary and is restricted through AppProject source allowlists.
- Chart upgrades remain separate, reviewable changes with compatibility and rollback evidence.

## References

- [Argo CD Helm documentation](https://argo-cd.readthedocs.io/en/stable/user-guide/helm/)
- [Argo CD multiple sources documentation](https://argo-cd.readthedocs.io/en/stable/user-guide/multiple_sources/)
