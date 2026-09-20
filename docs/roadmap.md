# Adoption Roadmap

The roadmap prioritizes converting the reference implementation into an operational platform capability while keeping evidence claims conservative and identity-bound.

## Active execution cycle — v0.3.0

GoldenPath is now planning **v0.3.0 — Operational Paved Road & Real-Environment Assurance**.

The authoritative release contract and phase gates are defined in the [v0.3.0 execution plan](releases/v0.3.0-execution-plan.md), tracked by GitHub epic #111 and phases #112 through #118.

The v0.3.0 objective is to prove that GoldenPath can bootstrap, independently discover, continuously verify, deliberately degrade, recover, and re-qualify **one explicitly supported real non-production platform environment**.

The release introduces an environment evidence tier between the existing ephemeral Runtime Lab and any future production-validation claim. It intentionally does not require multi-cloud operational parity and does not claim production validation.

Execution sequence:

- #112 — P0: Environment Assurance Contract & Architecture
- #113 — P1: Governed Real-Environment Bootstrap
- #114 — P2: Observed-State Discovery & Platform Drift
- #115 — P3: Environment Graph, Explainability & Blast Radius
- #116 — P4: Bounded Resilience Exercises & Re-verification
- #117 — P5: Tamper-Evident Evidence Ledger
- #118 — P6: Control Plane, Self-Qualification, Documentation & Release

P3 and P4 may execute in parallel after P2. P5 requires both, and P6 is the final release gate.

## Completed execution cycle — v0.2.0

v0.2.0 established **Runtime Evidence & Autonomous Assurance** through:

- a reproducible ephemeral Kubernetes Runtime Lab;
- signed identity-bound assurance receipts;
- independent tamper/replay/staleness/mismatch verification;
- continuous assurance and drift/recovery semantics;
- a coherent `goldenpath` CLI;
- exact-candidate self-qualification.

That release proves repository/reference and supported ephemeral-runtime evidence only. It remains the compatibility baseline for the v0.3.0 Runtime Lab path.

## Broader adoption path

The phases below describe organizational adoption beyond the release-specific execution plan. They do not automatically convert a v0.3.0 non-production environment into production validation.

## Phase 1 — Repository truth and quality

- Complete English documentation.
- Remove stale claims about unimplemented templates.
- Translate code comments and operational messages.
- Validate Terraform, Rego, Kustomize, shell scripts, and service-template rendering.
- Maintain effective root CI and fail-closed evidence contracts.

## Phase 2 — Operational non-production paved road

- Select one target cloud and one pilot workload.
- Configure real remote state and workload/federated identity.
- Provision and identify a non-production cluster and registry.
- Install and harden Argo CD and platform add-ons.
- Integrate a real secret manager, TLS, DNS, policy, and observability path.
- Independently discover observed state.
- Detect platform drift.
- Retain runtime/environment assurance evidence.

v0.3.0 is the release intended to make this phase executable and evidence-backed for one supported lane.

## Phase 3 — End-to-end pilot

- Generate one real service from the template.
- Build an immutable artifact through active CI.
- Promote it through development and staging.
- Define an SLO and alert routing.
- Exercise rollback, secret/certificate rotation, policy-denial, and selected dependency-failure workflows.
- Use graph/explainability data to connect application state to platform dependencies.

## Phase 4 — Production

- Complete security and recovery review.
- Define a separate production evidence contract and approval boundary.
- Enable production promotion and GitOps reconciliation.
- Run disaster-recovery and incident exercises.
- Capture DORA/platform adoption baselines.
- Produce production validation only from explicitly identified production evidence.

## Phase 5 — Scale

- Add service catalog and organizational ownership workflows.
- Add additional language/workload templates based on real demand.
- Automate template/module upgrades.
- Expand multi-cluster and multi-cloud operational support.
- Mature vulnerability, FinOps, policy-exception, compliance, and capacity evidence workflows.
- Add product feedback loops and broader platform scorecards without inventing assurance percentages.
