# ADR-0006: Maintain a Consolidated Reference Repository

- Status: Accepted for the current project stage

## Context

The project demonstrates multiple logical repositories—Terraform modules, stacks, GitOps, policies, and templates—in one location for learning, design, and iteration.

## Decision

Keep the current project consolidated while documenting production repository boundaries explicitly.

## Consequences

Component-level workflow files are reference blueprints because GitHub executes workflows only from root `.github/workflows`. Production adoption must either split components into real repositories or add root monorepo workflows. Documentation must not claim nested workflows are active enforcement in the current repository.
