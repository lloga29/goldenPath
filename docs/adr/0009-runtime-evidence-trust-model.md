# ADR-0009: Treat Runtime Evidence as Identity-Bound, Expiring Evidence

- Status: Accepted

## Context

GoldenPath v0.1 distinguishes repository/reference evidence from runtime and production claims, but v0.2 needs a stronger contract for facts collected from a live Kubernetes API.

Runtime facts are unsafe to trust when detached from the exact source, artifact, desired state, policy, execution context, and target runtime that produced them.

## Decision

GoldenPath will represent v0.2 runtime observations with `goldenpath.runtime-evidence/v1`.

Runtime evidence binds exact source, artifact, GitOps, policy, execution, cluster, namespace, workload UID, observed workload digest, control outcomes, and an explicit validity window.

An observed workload digest must equal the artifact digest under assessment. Evidence is invalid after its `validUntil` timestamp and must be re-collected when any authoritative identity changes.

## Consequences

- Runtime evidence can be rejected independently of the workflow that produced it.
- Stale or replayed evidence has an explicit rejection path.
- P1/P2 collectors must obtain real runtime identities instead of copying desired-state values.
- Additional identity collection creates implementation work, but prevents stronger claims from being built on ambiguous evidence.

