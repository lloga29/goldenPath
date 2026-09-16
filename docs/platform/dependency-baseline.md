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
| kube-prometheus-stack | `https://prometheus-community.github.io/helm-charts` | `91.4.1` | Refreshed to the current chart / Prometheus Operator baseline | Helm rendering only; CRD upgrade and monitoring runtime not proven |
| Loki | `https://grafana-community.github.io/helm-charts` | `18.13.1` | Migrated to the current OSS community distribution path | Helm rendering only; storage/runtime not proven |
| Tempo | `https://grafana-community.github.io/helm-charts` | `3.0.0` | Migrated to the current community single-binary chart | Helm rendering only; trace storage/runtime not proven |
| Gatekeeper | `https://open-policy-agent.github.io/gatekeeper/charts` | `3.23.1` | Refreshed to the current stable admission-policy baseline | Helm rendering only; CRD/webhook/admission runtime not proven |
| Envoy Gateway | `docker.io/envoyproxy` OCI | `v1.9.1` | Requires upstream-version verification under #25 before any change | Gateway/DNS/TLS runtime not proven |

## cert-manager refresh

The selected cert-manager release is `v1.21.2`, published on September 11, 2026. The cert-manager project currently supports the 1.21 and 1.20 release lines; for 1.21 its published support matrix covers Kubernetes `1.33` through `1.36` and tests the same range.

The Helm chart itself declares `kubeVersion: >=1.22.0-0`. That chart constraint is broader than the project's current support policy and must not be interpreted as a production support promise. GoldenPath uses the upstream-recommended OCI distribution path `quay.io/jetstack/charts/cert-manager`, with current `crds.enabled` / `crds.keep` values instead of deprecated `installCRDs`.

Root CI proves chart/value rendering only. It does not prove ACME reachability, issuer credentials, Gateway API certificate issuance, DNS propagation, webhook availability, or certificate renewal in a real cluster.

### cert-manager upgrade and rollback boundary

cert-manager owns CRDs and admission webhooks, so a production upgrade must follow the upstream upgrade instructions and verify CRD compatibility before controller rollout. Never treat a Helm render as evidence that an in-place downgrade of CRDs is safe.

## External Secrets Operator refresh

The selected External Secrets Operator chart is `2.10.0`, released on August 28, 2026. ESO supports only its current minor; 2.10 is tested on Kubernetes `1.36`. The chart's `kubeVersion >=1.19` constraint is broader than the project's tested/support matrix and must not be interpreted as equivalent support.

ESO explicitly recommends upgrading one minor version at a time. GoldenPath's move from `0.9.11` to `2.10.0` is therefore a fresh-install/reference baseline update, not an instruction for an existing production cluster to jump directly between those versions. ESO 2.x uses `external-secrets.io/v1`; GoldenPath's non-reconciled Vault example now uses that stable API instead of v1beta1.

Root CI proves chart/value rendering and repository example syntax only. It does not prove authentication to a real secret backend, provider permissions, rotation, webhook health, secret refresh, or recovery behavior.

### ESO upgrade and rollback boundary

Existing environments should upgrade minor-by-minor in development/staging first and confirm persisted custom resources are stored and served in APIs supported by each target release. Do not rely on a chart downgrade as a CRD rollback strategy.

## kube-prometheus-stack refresh

The selected `kube-prometheus-stack` chart is `91.4.1`, published on September 16, 2026. It carries Prometheus Operator `v0.94.0` and declares Kubernetes `>=1.25.0-0`. The chart also bundles current Grafana, kube-state-metrics, node-exporter, and Prometheus Operator CRD dependencies.

GoldenPath preserves its existing repository-owned Prometheus retention/resources, ServiceMonitor/PodMonitor selection semantics, Grafana persistence, and Alertmanager resource envelope. The refresh intentionally does not add unrelated monitoring features or tune application SLOs.

This is a fresh-install/reference baseline update. The upstream chart documents that CRD changes drive major chart versions and that existing installations must explicitly upgrade Prometheus Operator CRDs. Recent chart versions provide an optional `crds.upgradeJob`, but GoldenPath does not silently enable a privileged CRD mutation job as part of a static reference refresh. A real operator must choose and validate the CRD upgrade path for the target cluster.

Root CI renders the chart with `--include-crds`; this proves template compatibility with the committed values. It does not prove that an existing Prometheus, Alertmanager, Grafana, or Prometheus Operator state can be upgraded in place, nor that dashboards, rules, storage, retention, alerts, or scrape targets behave correctly in a live cluster.

The upstream release also publishes a `.tgz.prov` provenance file. GoldenPath records that capability but does not yet claim Helm provenance verification in root CI; artifact verification remains a separate supply-chain maturity item.

### kube-prometheus-stack upgrade and rollback boundary

For an existing environment, review every relevant major-version section in upstream `UPGRADE.md`, update CRDs using the approved cluster procedure before controllers depend on new schemas, and test Prometheus/Alertmanager storage compatibility in staging. Keep a backup/recovery plan for monitoring data and configuration; a Helm downgrade is not a CRD or persisted-data rollback strategy.

## Gatekeeper refresh

The selected Gatekeeper chart is `3.23.1`, matching Gatekeeper `v3.23.1`, the latest stable release published on August 27, 2026. The official Helm source remains `https://open-policy-agent.github.io/gatekeeper/charts`.

Gatekeeper documents its minimum supported Kubernetes version as aligned with the Kubernetes Supported Versions policy. As of September 16, 2026, Kubernetes maintains the `1.35`, `1.36`, and `1.37` release branches. Gatekeeper's chart does not declare a `kubeVersion`, so a successful Helm render must not be interpreted as proof of support on an arbitrary Kubernetes version.

The previous GoldenPath pin `3.14.0` embedded OPA `v0.57.1`; Gatekeeper `3.23.1` embeds OPA `v1.17.1`. GoldenPath keeps its existing classic `targets[].rego` ConstraintTemplate examples unchanged in this dependency refresh. Repository parsing and Kustomize rendering do not prove that every admission decision is semantically identical under the newer Gatekeeper/OPA runtime.

The old GoldenPath values placed a `resources` block at chart root, where Gatekeeper did not consume it. This refresh makes the intended envelope explicit under both `controllerManager.resources` and `audit.resources` while preserving the existing replica count, audit interval, violation limit, and audit-cache choice.

This is a fresh-install/reference baseline update. Gatekeeper owns CRDs and admission webhooks, and `upgradeCRDs.enabled` is enabled by default in both the old and selected charts. Crossing from `3.14.0` to `3.23.1` spans multiple Gatekeeper and OPA minors; GoldenPath does not claim that a Helm render proves a safe direct in-place upgrade for an existing cluster.

Root CI proves the selected chart and committed values can render and that repository policy fixtures retain their expected static outcomes. It does not prove live webhook availability, CRD conversion/storage behavior, audit convergence, failure-policy behavior, constraint enforcement, mutation, external-data integration, or Kubernetes API-server admission behavior.

### Gatekeeper upgrade and rollback boundary

For an existing environment, review the intervening Gatekeeper release and upgrade notes, validate CRDs and ConstraintTemplates in a non-production cluster, and prove both allowed and denied admission paths before promotion. Export critical ConstraintTemplates/Constraints and preserve the previous desired-state revision. A chart downgrade is not a CRD rollback strategy, and rollback must not leave the API server dependent on an unavailable or incompatible webhook.

## Loki OSS migration

The selected community Loki chart `18.13.1` declares Loki `3.7.7` and Kubernetes `>=1.25.0-0`. GoldenPath explicitly selects Monolithic mode, disables the Simple Scalable targets, uses TSDB schema v13, and keeps local filesystem storage explicit.

Filesystem storage is deliberately **not** presented as a production storage recommendation. A production adopter must select and validate a durable object store, retention policy, backup/recovery model, capacity, credentials/identity path, and failure behavior.

### Loki rollback

Do not perform an in-place chart downgrade after changing persisted schema/storage assumptions without a tested data rollback plan. Keep the previous desired-state commit available and validate storage compatibility before promotion.

## Tempo OSS migration

The selected Grafana Community `tempo` chart `3.0.0` declares Tempo `3.0.3` and Kubernetes `^1.25.0-0`. It remains the single-binary/monolithic chart; Kafka is not required for this deployment mode.

Tempo 3 replaces the Tempo 2.x ingester with live-store for recent traces and changes the compactor/backend path. The chart HTTP API default is port `3200`; the repository contains no hard-coded `tempo:3100` dependency.

Local trace storage is deliberately **not** presented as production-ready. A real adopter must validate durable trace storage, retention, persistence, recovery, encryption, identity/credentials, capacity, and failure behavior.

### Tempo rollback

Tempo 3 changes persisted/runtime behavior. Test data compatibility before promotion and keep a validated trace-storage rollback/recovery path; do not assume an in-place chart downgrade is data-safe.

## Remaining refresh work

Issue #25 remains open until Envoy Gateway has an evidence-backed current support baseline. Gateway API/controller compatibility and live routing behavior require their own evidence.

## Upstream references

- [cert-manager supported releases](https://cert-manager.io/docs/releases/)
- [cert-manager Helm installation](https://cert-manager.io/docs/installation/helm/)
- [cert-manager upgrade documentation](https://cert-manager.io/docs/installation/upgrade/)
- [External Secrets support policy](https://external-secrets.io/latest/introduction/stability-support/)
- [External Secrets documentation](https://external-secrets.io/)
- [kube-prometheus-stack chart](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
- [kube-prometheus-stack upgrade guide](https://github.com/prometheus-community/helm-charts/blob/main/charts/kube-prometheus-stack/UPGRADE.md)
- [Gatekeeper installation](https://open-policy-agent.github.io/gatekeeper/website/docs/install/)
- [Gatekeeper OPA versions](https://open-policy-agent.github.io/gatekeeper/website/docs/opa-versions/)
- [Kubernetes supported releases](https://kubernetes.io/releases/)
- [Grafana Community Helm charts - Loki](https://github.com/grafana-community/helm-charts/tree/main/charts/loki)
- [Loki deployment modes](https://grafana.com/docs/loki/latest/get-started/deployment-modes/)
- [Grafana Community Helm charts - Tempo](https://github.com/grafana-community/helm-charts/tree/main/charts/tempo)
- [Tempo 3 migration guide](https://grafana.com/docs/tempo/latest/set-up-for-tracing/setup-tempo/migrate-to-3/)
