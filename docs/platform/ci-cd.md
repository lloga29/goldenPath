# CI/CD Model

The Golden Path separates **continuous integration** from **environment promotion** and **GitOps reconciliation**.

## Important repository behavior

The workflows under component directories are reference blueprints. In this consolidated repository they are not automatically executed because GitHub only loads workflow definitions from the repository-root `.github/workflows/` directory.

A production split should activate the appropriate workflow in each real repository, or this monorepo should add root workflows that dispatch based on changed paths.

## Application CI

A mature application pipeline normally includes:

1. formatting and linting;
2. unit tests;
3. dependency and secret scanning;
4. SAST where appropriate;
5. deterministic build;
6. container build;
7. vulnerability scan;
8. SBOM generation;
9. artifact signing and provenance;
10. immutable registry publication.

The artifact identity created in CI is the identity promoted through environments.

## Infrastructure CI

Terraform changes should include formatting, initialization without state mutation, validation, lint/static analysis, policy checks, cost feedback, and a plan based on the target environment. Plans containing sensitive values require controlled handling and retention.

## Delivery

Delivery should update GitOps desired state with a trusted artifact reference. Argo CD then reconciles the target cluster. This separates build credentials from deployment credentials and provides a Git audit trail.

## Production approvals

Approval controls belong at the actual authority boundary: protected branches, GitHub environments, Argo CD RBAC/sync policy, cloud IAM, and Kubernetes authorization. A workflow comment saying "approval required" does not implement approval.

## Failure behavior

Security and correctness gates should fail closed. `continue-on-error`, `|| true`, or swallowed exit codes are acceptable only for explicitly advisory feedback such as optional cost estimates.

## Runners

Prefer ephemeral or tightly managed runners. Self-hosted runners require patching, isolation, secret hygiene, workspace cleanup, capacity management, network controls, and an explicit trust model for untrusted pull requests.

## Evidence

Retain enough evidence to reconstruct what code, checks, artifact digest, approvals, and GitOps change produced a production deployment.
