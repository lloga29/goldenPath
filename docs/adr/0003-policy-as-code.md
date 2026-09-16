# ADR-0003: Use OPA/Conftest and Gatekeeper for Policy as Code

- Status: Accepted

## Context

Infrastructure and Kubernetes standards need consistent automated feedback and enforcement.

## Decision

Use OPA/Rego policies with Conftest for pre-merge checks and Gatekeeper for Kubernetes admission controls where runtime enforcement is required.

## Consequences

Policies become versioned code that requires testing, ownership, rollout planning, and an exception process. Blocking policies must propagate failures rather than silently continue.
