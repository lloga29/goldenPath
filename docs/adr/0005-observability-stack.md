# ADR-0005: Standardize the Core Kubernetes Observability Stack

- Status: Accepted as a reference baseline

## Context

Services need a consistent way to emit and inspect metrics, logs, and traces.

## Decision

Use Prometheus/Grafana for metrics and visualization, Loki for logs, and Tempo for traces as the reference Kubernetes observability baseline.

## Consequences

The platform gains a consistent integration target, but production environments must still define storage, retention, HA, authentication, tenancy, capacity, and cost. Organizations may substitute managed backends if they preserve the telemetry contract.
