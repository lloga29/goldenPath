# Changelog - Golden Path Platform

All notable changes to this project are documented here.

## [Unreleased] - Repository Validation, GitOps Reconciliation, and CI Supply-Chain Hardening

### Added
- Active root-level repository validation for English-only content, structured files, shell syntax, Markdown links, Terraform modules/tests/stacks, GitOps/policy contracts, and the Go service template.
- Argo CD-native multi-source Helm reconciliation for shared platform add-ons.
- Versioned platform Helm values and 21 chart/environment renders in root CI.
- Envoy Gateway and a platform-owned `GatewayClass/golden-path` as the Gateway API reference baseline.
- ADRs for Argo CD-native platform reconciliation and Gateway API/Envoy Gateway.
- ingress-nginx to Gateway API migration runbook.
- Executable GitOps contract validation that rejects active Flux dependencies, deprecated Kustomize `commonLabels`, wildcard platform source repositories, non-exact chart version expressions, and an ingress-nginx platform component.
- Executable root-CI supply-chain validation for immutable action references, explicit runner families, verified tool downloads, and hash-locked Python installs.
- CPython 3.13.15-specific hash locks for structured-file tooling and the complete Copier CI dependency graph on Ubuntu 24.04 x86_64.

### Changed
- Standardized repository documentation on English and enforced the rule in CI.
- Reframed the repository as a production-oriented Golden Path reference implementation.
- Added architecture, security, operations, governance, standards, maturity, and roadmap documentation.
- Added operational runbooks and Architecture Decision Records.
- Corrected documentation that presented roadmap templates as already implemented.
- Documented the consolidated-repository limitation for nested GitHub Actions workflows.
- Made Argo CD the sole authoritative Kubernetes reconciliation engine in the reference platform layer.
- Migrated Kustomize labels to the current transformer while preserving selector behavior.
- Moved placeholder secret-store configuration out of active desired state and into an explicit `.invalid` example.
- Removed ingress-nginx from the recommended new-production baseline; existing deployments require a controlled migration.
- Pinned every active external GitHub Action to a full commit SHA and replaced `ubuntu-latest` with the explicit `ubuntu-24.04` runner family.
- Added SHA-256 verification for Kustomize, Helm, and Conftest executable archives before extraction/installation.
- Upgraded Conftest to 0.70.0 while keeping current Rego v0 policy semantics explicit through `--rego-version v0`; Rego v1 migration is tracked in issue #30.
- Pinned the Go template smoke-test runtime to Go 1.26.8.
- Documented that exact version pins, commit SHAs, checksums, signatures, provenance, and hosted-runner labels provide different assurance properties and must not be conflated.

## [0.2.0] - 2024-01-20 - Hardening Release

### terraform-modules/
- **fix:** Added `docs/header.md` and `docs/footer.md` for terraform-docs.
- **fix:** Added `.secrets.baseline` for detect-secrets.
- **feat:** Added a `Makefile` with standard commands (`fmt`, `validate`, `lint`, `test`, `docs`).
- **fix:** Improved `scripts/validate-all.sh` with dependency checks.

### platform-stacks/
- **fix:** Completed the ACME reference client structure with environment examples.
- **feat:** Added CI/CD workflow blueprints with tool installation.
- **docs:** Added templates for new clients and environments.

### gitops-config/
- **fix:** Added `clusters/staging/cluster-config.yaml`.
- **fix:** Completed the `payment-api` staging overlay.
- **feat:** Added platform base definitions for ingress-nginx, cert-manager, External Secrets, Prometheus stack, Loki, Tempo, and Gatekeeper.
- **feat:** Added platform overlays for development, staging, and production.
- **docs:** Added promotion and rollback guidance.
- **fix:** Improved `scripts/promote.sh` with `:latest` validation and `yq` support.
- **fix:** Improved `scripts/rollback.sh` with an emergency mode.

### service-templates/
- **fix:** Completed the Go template with handlers, middleware, and configuration.
- **fix:** Updated the Dockerfile to use a distroless runtime image and removed the invalid runtime health check.
- **feat:** Added version injection through Go linker flags.
- **feat:** Added pre-commit configuration to the template.

### platform-policies/
- **feat:** Added immutable-image, security-context, and resource-requirement policies.
- **feat:** Added `policy-exceptions.yaml` as a reference exception inventory.

### Documentation
- **docs:** Added a 15-minute quickstart and operational runbooks.
- **docs:** Added an audit checklist to track remaining gaps.

## [0.1.0] - 2024-01-15 - Initial Release

### Added
- Initial consolidated repository structure.
- Initial Terraform VPC, IAM, OIDC, and storage references.
- Initial Argo CD/GitOps structure.
- Go service template skeleton.
- Initial OPA/Conftest policies.
- CI/CD workflow blueprints.
- Initial documentation.

> Historical entries describe the intent and state of the project at the time. The current repository tree and current documentation are authoritative for capabilities that exist today.
