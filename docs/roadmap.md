# Adoption Roadmap

The roadmap prioritizes converting the reference implementation into an operational platform capability.

## Active execution cycle — v0.2.0

GoldenPath is now planning **v0.2.0 — Runtime Evidence & Autonomous Assurance**.

The authoritative release contract and phase gates are defined in the [v0.2.0 execution plan](releases/v0.2.0-execution-plan.md), tracked by GitHub epic #91 and phases #92 through #97.

The v0.2.0 objective is to add reproducible ephemeral-runtime evidence, identity-bound assurance receipts, resilience/continuous-assurance exercises, and a coherent paved-road entry point while preserving the strict separation between repository/reference evidence, runtime evidence, and production validation.

The phases below remain the broader adoption path for real organizational rollout. They do not convert v0.2.0 Runtime Lab evidence into production validation.

## Phase 1 — Repository truth and quality

- Complete English documentation.
- Remove stale claims about unimplemented templates.
- Translate code comments and operational messages.
- Validate Terraform, Rego, Kustomize, shell scripts, and Go template rendering.
- Add effective root CI for this consolidated repository or split components into real repositories.

## Phase 2 — Production pilot foundation

- Select one target cloud and one pilot workload.
- Configure real remote state and OIDC federation.
- Provision a non-production cluster and registry.
- Install and harden Argo CD and platform add-ons.
- Integrate a real secret manager, TLS, DNS, and observability.
- Activate protected changes and required reviews.

## Phase 3 — End-to-end pilot

- Generate one real service from the template.
- Build an immutable artifact through active CI.
- Promote it through development and staging.
- Define an SLO and alert routing.
- Exercise rollback, secret rotation, and policy-denial workflows.

## Phase 4 — Production

- Complete security and recovery review.
- Enable production promotion and GitOps reconciliation.
- Run disaster-recovery and incident exercises.
- Capture DORA/platform adoption baselines.

## Phase 5 — Scale

- Add service catalog/scorecards.
- Add additional language/workload templates based on real demand.
- Automate template/module upgrades.
- Add SBOM, signing, provenance, and verification.
- Mature vulnerability, FinOps, policy-exception, and compliance evidence workflows.
