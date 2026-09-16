# ADR-001: Organize Terraform by Reusable Modules and Composed Patterns

- Status: Accepted

## Context

Platform teams need reusable infrastructure primitives without forcing application teams to copy large Terraform stacks.

## Decision

Keep small reusable modules under `modules/<category>/<name>` and compose higher-level reference architectures under `patterns/`. Client/environment composition belongs in the separate `platform-stacks` domain.

## Consequences

Modules can be versioned and tested independently, while patterns provide opinionated composition. The platform must avoid creating deep module nesting that obscures provider behavior or makes upgrades difficult.
