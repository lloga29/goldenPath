# Repository Model

The current project is intentionally consolidated so the complete Golden Path can be studied in one place. A production organization may split the domains into separately governed repositories.

## Current reference layout

| Directory | Responsibility |
|---|---|
| `terraform-modules/` | Reusable infrastructure primitives and patterns |
| `platform-stacks/` | Client/environment composition and infrastructure lifecycle |
| `gitops-config/` | Kubernetes desired state, Argo CD, platform add-ons, application overlays |
| `platform-policies/` | OPA/Conftest policy library and exception metadata |
| `service-templates/` | Golden service templates and shared developer bootstrap |
| `docs/` | Platform product documentation and runbooks |

## Recommended production split

A mature organization commonly separates repositories by change authority and lifecycle:

```text
platform-terraform-modules
platform-infrastructure-stacks
platform-gitops
platform-policies
platform-service-templates
platform-docs
team-<name>-services
```

This is not mandatory. The key requirement is that ownership, review boundaries, credentials, deployment permissions, and release lifecycles remain understandable and enforceable.

## Important GitHub Actions behavior

GitHub only executes workflow files located in the repository-root `.github/workflows/` directory. The workflows currently stored inside `terraform-modules/.github/workflows/`, `platform-stacks/.github/workflows/`, and `gitops-config/.github/workflows/` are therefore **reference workflow blueprints in this consolidated repository**. They become active when those directories are promoted into standalone repositories or when equivalent workflows are created at the root.

Documentation must not claim that a nested workflow is currently enforcing a repository-wide gate.

## Versioning model

Reusable modules and templates should use explicit versions. Consumers should pin immutable versions rather than follow moving branches for production. GitOps promotion should update an immutable image tag or digest, not rebuild the artifact.

## CODEOWNERS

The repository contains CODEOWNERS examples in component directories. A production split should activate equivalent ownership rules at the actual repository root and protect sensitive paths, especially production GitOps state, identity, policy, and Terraform bootstrap code.

## Separation of concerns

Avoid a repository model in which the same automation identity can modify application code, infrastructure policy, production desired state, and runtime clusters without review. Repository boundaries are useful only when they are reinforced by identity and authorization boundaries.
