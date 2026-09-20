# ADR-0011: Use kind for the v0.2 Disposable Runtime Lab

- Status: Accepted

## Context

P1 requires a reproducible Kubernetes runtime that exercises GoldenPath against a real Kubernetes API while remaining clearly outside production validation.

## Decision

The first supported GoldenPath v0.2 Runtime Lab will use kind.

The lifecycle is disposable: create cluster, establish the documented bootstrap boundary, hand steady-state desired state to Argo CD, exercise admission/runtime controls, collect evidence, destroy the cluster, and verify expected cleanup.

Initial installation needed to establish Argo CD and admission enforcement may be imperative when documented. Hidden steady-state mutation is not allowed and bootstrap actions are not counted as GitOps reconciliation evidence.

The lab is always classified as `ephemeral-lab` runtime evidence.

## Consequences

- P1 can run locally and in CI without claiming managed-cloud equivalence.
- Kubernetes API behavior can be exercised reproducibly.
- Cloud-provider, production identity, production networking, and production availability behavior remain out of scope.
- P1 must pin and document the supported kind/Kubernetes versions and cleanup behavior.

