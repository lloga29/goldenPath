# Platform Dependency Baseline

This document records the support and upgrade status of shared platform Helm dependencies. A version pin proves only that the repository selects an exact chart version and that root CI can render it with the committed values. It does not prove runtime compatibility with a real cluster, cloud integration, storage backend, identity system, or production workload.

## Review rules

For each platform dependency:

1. use an upstream-maintained distribution source;
2. pin an exact chart version;
3. record important Kubernetes/runtime prerequisites and breaking changes;
4. render every supported environment in root CI before merge;
5. keep runtime-only validation gaps explicit;
6. document rollback before a breaking production migration.

## Current baseline

| Component | Chart source | Pin | Repository status | Runtime evidence |
|---|---|---:|---|---|
| cert-manager | `https://charts.jetstack.io` | `v1.14.2` | Refresh pending under #25 | Not proven in a live target cluster |
| External Secrets Operator | `https://charts.external-secrets.io` | `0.9.11` | Refresh pending under #25 | Secret backend integration not proven |
| kube-prometheus-stack | `https://prometheus-community.github.io/helm-charts` | `56.6.2` | Refresh pending under #25 | Monitoring runtime not proven |
| Loki | `https://grafana-community.github.io/helm-charts` | `18.13.1` | Migrated to the current OSS community distribution path | Helm rendering only; storage/runtime not proven |
| Tempo | `https://grafana.github.io/helm-charts` | `1.7.1` | Refresh/migration pending under #25 | Trace storage/runtime not proven |
| Gatekeeper | `https://open-policy-agent.github.io/gatekeeper/charts` | `3.14.0` | Refresh pending under #25 | Admission runtime not proven |
| Envoy Gateway | `docker.io/envoyproxy` OCI | `v1.9.1` | Requires upstream-version verification under #25 before any change | Gateway/DNS/TLS runtime not proven |

## Loki OSS migration

The Grafana Loki project moved the OSS Helm chart to the `grafana-community/helm-charts` project in 2026. GoldenPath no longer consumes the legacy Grafana Helm repository for Loki OSS.

The selected community chart `18.13.1` declares:

- Loki application version `3.7.7`;
- Kubernetes `>=1.25.0-0`;
- support for Monolithic, Simple Scalable, and Distributed modes.

GoldenPath explicitly selects `deploymentMode: Monolithic`, which matches the repository's intentionally small reference observability footprint. The chart documents Monolithic as the mode for small installations and identifies Simple Scalable as deprecated for removal in Loki 4.

The committed reference values use:

- one single-binary replica;
- TSDB schema v13;
- local filesystem storage;
- small explicit CPU/memory requests and limits.

Filesystem storage is deliberately **not** presented as a production storage recommendation. A production adopter must select and validate a durable object store, retention policy, backup/recovery model, capacity, credentials/identity path, and failure behavior before relying on Loki operationally.

### Breaking-change boundary

This migration crosses multiple community-chart major versions. Important upstream changes include deployment-mode naming/default changes, monitoring-label changes, MinIO deprecation, and other chart value changes. GoldenPath does not attempt to preserve arbitrary historical Loki customizations; it validates the narrow reference values owned by this repository.

### Rollback

For a real environment, do not perform an in-place chart downgrade after changing persisted schema/storage assumptions without a tested data rollback plan. Keep the previous desired-state commit available, validate storage compatibility before promotion, and prefer restoring traffic/queries to a proven deployment over improvising a chart downgrade during an incident.

## Remaining refresh work

Issue #25 remains open until the remaining platform dependencies have an evidence-backed current support baseline. Tempo is intentionally treated separately from Loki because current Tempo distributed deployments introduce different architecture and storage requirements; those changes must not be hidden inside the Loki migration.

## Upstream references

- [Grafana Community Helm charts - Loki](https://github.com/grafana-community/helm-charts/tree/main/charts/loki)
- [Loki Helm installation documentation](https://grafana.com/docs/loki/latest/setup/install/helm/)
- [Loki deployment modes](https://grafana.com/docs/loki/latest/get-started/deployment-modes/)
