# Observability

The Golden Path treats observability as part of the service contract rather than an optional dashboard added after deployment.

## Current reference stack

The GitOps baseline contains reference configuration for Prometheus/Grafana, Loki, and Tempo. These provide the foundation for metrics, logs, and traces. Production operation still requires real storage, retention, authentication, tenancy, alert routing, dashboards, resource sizing, and backup decisions.

## Required signals

Every production service should provide:

- health and readiness signals;
- request/transaction metrics appropriate to the workload;
- error and saturation metrics;
- structured logs with correlation fields;
- distributed trace propagation where useful;
- deployment/version metadata;
- ownership and environment labels.

Platform components should expose equivalent health and capacity signals.

## Correlation

Use consistent identifiers for service, environment, version, cluster, namespace, tenant/customer where permitted, and request/trace IDs. Avoid high-cardinality labels that can destabilize telemetry backends or create uncontrolled cost.

## Dashboards

A service dashboard should answer: Is the service available? Is latency acceptable? Are errors increasing? Is capacity constrained? Did a recent deployment correlate with degradation? Where is the next diagnostic step?

## Alerts

Alerts must be actionable, owned, deduplicated, and connected to an SLO or concrete failure mode. Avoid paging on raw infrastructure noise when no user or platform objective is at risk.

## Retention and security

Telemetry can contain sensitive operational or customer data. Define access control, redaction, retention, residency, and deletion requirements. Never log secret values.

## Platform telemetry

Monitor Argo CD reconciliation, admission-policy failures, certificate status, secret synchronization, cluster capacity, Terraform drift signals, registry health, and observability-stack health itself.
