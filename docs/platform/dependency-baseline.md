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
| cert-manager | `quay.io/jetstack/charts` OCI | `v1.21.2` | Refreshed to the current supported release and recommended OCI source | Helm rendering only; issuer/Gateway/certificate runtime not proven |
| External Secrets Operator | `https://charts.external-secrets.io` | `2.10.0` | Refreshed to the current supported minor; repository examples use the stable v1 API | Helm rendering only; secret backend integration not proven |
| kube-prometheus-stack | `https://prometheus-community.github.io/helm-charts` | `56.6.2` | Refresh pending under #25 | Monitoring runtime not proven |
| Loki | `https://grafana-community.github.io/helm-charts` | `18.13.1` | Migrated to the current OSS community distribution path | Helm rendering only; storage/runtime not proven |
| Tempo | `https://grafana-community.github.io/helm-charts` | `3.0.0` | Migrated to the current community single-binary chart | Helm rendering only; trace storage/runtime not proven |
| Gatekeeper | `https://open-policy-agent.github.io/gatekeeper/charts` | `3.14.0` | Refresh pending under #25 | Admission runtime not proven |
| Envoy Gateway | `docker.io/envoyproxy` OCI | `v1.9.1` | Requires upstream-version verification under #25 before any change | Gateway/DNS/TLS runtime not proven |

## cert-manager refresh

The selected cert-manager release is `v1.21.2`, published on September 11, 2026. The cert-manager project currently supports the 1.21 and 1.20 release lines; for 1.21 its published support matrix covers Kubernetes `1.33` through `1.36` and tests the same range.

The Helm chart itself declares `kubeVersion: >=1.22.0-0`. That chart constraint is broader than the project's current support policy and must not be interpreted as a production support promise. A production adopter using cert-manager 1.21 should run a Kubernetes version in the project's supported range unless it has a separate supported/LTS arrangement.

GoldenPath uses the upstream-recommended OCI distribution path `quay.io/jetstack/charts/cert-manager`. The chart deprecates `installCRDs`; GoldenPath uses `crds.enabled: true` and `crds.keep: true` while preserving the existing replica/resource and ServiceMonitor settings.

Root CI proves chart/value rendering only. It does not prove ACME reachability, issuer credentials, Gateway API certificate issuance, DNS propagation, webhook availability, or certificate renewal in a real cluster.

### cert-manager upgrade and rollback boundary

cert-manager owns CRDs and admission webhooks, so a production upgrade must follow the upstream upgrade instructions and verify CRD compatibility before controller rollout. Never treat a Helm render as evidence that an in-place downgrade of CRDs is safe. Preserve the previous desired-state revision and validate issuer/renewal behavior before closing the rollback window.

## External Secrets Operator refresh

The selected External Secrets Operator chart is `2.10.0`, released on August 28, 2026. ESO's support policy supports only the current minor; 2.10 is tested on Kubernetes `1.36`. The chart's `kubeVersion` constraint is broader (`>=1.19.0-0`) than the project's tested/support matrix, so a successful render on an older Kubernetes version is not equivalent to supported runtime operation.

ESO explicitly recommends upgrading one minor version at a time. GoldenPath's move from the old `0.9.11` reference pin to `2.10.0` is therefore a **fresh-install/reference baseline update**, not an instruction for an existing production cluster to jump directly from 0.9 to 2.10. Existing installations must follow the upstream sequential upgrade guidance and review every intervening release for CRD/API/provider changes.

ESO 2.x uses `external-secrets.io/v1` as the stable API. Its chart no longer serves v1beta1 by default. GoldenPath's non-reconciled Vault `ClusterSecretStore` example is updated from `v1beta1` to `v1` so copied examples do not teach a deprecated API.

The existing `installCRDs`, replica/resource, and ServiceMonitor values remain valid under chart 2.10. Root CI proves chart/value rendering and example syntax only. It does not prove authentication to Vault or any cloud secret manager, provider permissions, secret rotation, webhook health, or recovery behavior.

### ESO upgrade and rollback boundary

For existing environments, upgrade minor-by-minor in development/staging first and confirm all persisted ExternalSecret, SecretStore, ClusterSecretStore, PushSecret, generator, and provider resources are stored/served in APIs supported by the target release. Do not rely on a chart downgrade as a CRD rollback strategy. Preserve the previous desired-state revision and export critical custom resources before crossing API/storage migrations.

## Loki OSS migration

The Grafana Loki project moved the OSS Helm chart to the `grafana-community/helm-charts` project in 2026. The selected community chart `18.13.1` declares Loki `3.7.7` and Kubernetes `>=1.25.0-0`. GoldenPath explicitly selects Monolithic mode, disables the Simple Scalable targets, uses TSDB schema v13, and keeps local filesystem storage explicit.

Filesystem storage is deliberately **not** presented as a production storage recommendation. A production adopter must select and validate a durable object store, retention policy, backup/recovery model, capacity, credentials/identity path, and failure behavior.

### Loki rollback

Do not perform an in-place chart downgrade after changing persisted schema/storage assumptions without a tested data rollback plan. Keep the previous desired-state commit available and validate storage compatibility before promotion.

## Tempo OSS migration

The selected Grafana Community `tempo` chart `3.0.0` declares Tempo `3.0.3` and Kubernetes `^1.25.0-0`. It remains the single-binary/monolithic chart; Kafka is not required for this deployment mode.

Tempo 3 replaces the Tempo 2.x ingester with live-store for recent traces and changes the compactor/backend path. GoldenPath's prior values did not override the removed fields, so no repository-owned configuration required translation. The chart HTTP API default is port `3200`; the repository contains no hard-coded `tempo:3100` dependency.

Local trace storage is deliberately **not** presented as production-ready. A real adopter must validate durable trace storage, retention, persistence, recovery, encryption, identity/credentials, capacity, and failure behavior.

### Tempo rollback

Tempo 3 changes persisted/runtime behavior. Test data compatibility before promotion and keep a validated trace-storage rollback/recovery path; do not assume an in-place chart downgrade is data-safe.

## Remaining refresh work

Issue #25 remains open until the remaining platform dependencies have an evidence-backed current support baseline. kube-prometheus-stack, Gatekeeper, and Envoy Gateway remain separate review units because each has different CRD/API, Kubernetes-version, or runtime migration concerns.

## Upstream references

- [cert-manager supported releases](https://cert-manager.io/docs/releases/)
- [cert-manager Helm installation](https://cert-manager.io/docs/installation/helm/)
- [cert-manager upgrade documentation](https://cert-manager.io/docs/installation/upgrade/)
- [External Secrets support policy](https://external-secrets.io/latest/introduction/stability-support/)
- [External Secrets documentation](https://external-secrets.io/)
- [Grafana Community Helm charts - Loki](https://github.com/grafana-community/helm-charts/tree/main/charts/loki)
- [Loki Helm installation documentation](https://grafana.com/docs/loki/latest/setup/install/helm/)
- [Loki deployment modes](https://grafana.com/docs/loki/latest/get-started/deployment-modes/)
- [Grafana Community Helm charts - Tempo](https://github.com/grafana-community/helm-charts/tree/main/charts/tempo)
- [Tempo 3.0 release notes](https://grafana.com/docs/tempo/latest/release-notes/v3-0/)
- [Tempo 3 migration guide](https://grafana.com/docs/tempo/latest/set-up-for-tracing/setup-tempo/migrate-to-3/)
