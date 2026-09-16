# Adoption Roadmap

The roadmap prioritizes converting the reference implementation into an operational platform capability.

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
