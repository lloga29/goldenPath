# ADR-0001: Use GitOps with Argo CD

- Status: Accepted

## Context

The platform needs a repeatable, auditable way to deliver Kubernetes desired state across multiple environments and teams without giving every CI pipeline direct broad cluster credentials.

## Decision

Use Git as the desired-state source and Argo CD as the primary Kubernetes reconciliation engine. Use AppProjects for authorization boundaries and ApplicationSets to reduce repetitive application definitions.

## Consequences

Production changes gain Git auditability and drift reconciliation. Argo CD and Git availability become control-plane dependencies and require their own security, observability, and recovery procedures. Emergency runtime changes must later be reconciled to Git.
