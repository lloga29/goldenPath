# ADR-0002: Build Once and Promote Immutable Artifacts

- Status: Accepted

## Context

Rebuilding per environment can produce different binaries/images and weakens evidence that staging tested the same artifact later used in production.

## Decision

Build application artifacts once and promote the same immutable identity through environments. Environment-specific configuration may vary, but the executable artifact does not.

## Consequences

Registries must support immutable references and sufficient retention. Pipelines separate build from promotion. Rollback becomes selection of a previous known-good artifact rather than reconstruction.
