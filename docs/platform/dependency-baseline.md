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
| Tempo | `https://grafana-community.github.io/helm-charts` | `3.0.0` | Migrated to the current community single-binary chart | Helm rendering only; trace storage/runtime not proven |
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

## Tempo OSS migration

The selected Grafana Community `tempo` chart `3.0.0` declares Tempo `3.0.3` and Kubernetes `^1.25.0-0`. It remains the single-binary/monolithic chart; Kafka is not required for this deployment mode.

Tempo 3.0 changes the internal architecture even in monolithic mode: the live-store replaces the Tempo 2.x ingester for recent traces and backend scheduler/worker functionality replaces the old compactor path. The community chart therefore treats the jump to chart 3.x as a breaking migration.

GoldenPath's previous Tempo values only set resource requests/limits and do not override the removed `tempo.ingester`, `compactor`, memory-ballast, or metrics-generator `local_blocks` settings. The migrated reference values keep the same resource envelope and make local trace/WAL storage explicit.

The chart's HTTP API default is port `3200`; the repository contains no hard-coded `tempo:3100` dependency that requires migration.

Local trace storage is deliberately **not** presented as production-ready. A real adopter must provide and validate durable trace storage, retention, persistence, recovery, encryption, identity/credentials, capacity, and failure behavior before production use.

### Rollback

Tempo 3 changes persisted/runtime behavior. A real environment must read the Tempo 3 migration guidance and test data compatibility before promotion. Keep the previous desired-state revision and a validated trace-storage rollback/recovery path; do not assume an in-place chart downgrade is data-safe.

## Remaining refresh work

Issue #25 remains open until the remaining platform dependencies have an evidence-backed current support baseline. cert-manager, External Secrets Operator, kube-prometheus-stack, Gatekeeper, and Envoy Gateway remain separate review units because each has different CRD/API, Kubernetes-version, or runtime migration concerns.

## Upstream references

- [Grafana Community Helm charts - Loki](https://github.com/grafana-community/helm-charts/tree/main/charts/loki)
- [Loki Helm installation documentation](https://grafana.com/docs/loki/latest/setup/install/helm/)
- [Loki deployment modes](https://grafana.com/docs/loki/latest/get-started/deployment-modes/)
- [Grafana Community Helm charts - Tempo](https://github.com/grafana-community/helm-charts/tree/main/charts/tempo)
- [Tempo 3.0 release notes](https://grafana.com/docs/tempo/latest/release-notes/v3-0/)
- [Tempo 3 migration guide](https://grafana.com/docs/tempo/latest/set-up-for-tracing/setup-tempo/migrate-to-3/)
