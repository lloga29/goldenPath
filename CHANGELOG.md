# Changelog - GoldenPath

All notable repository changes are documented here. This changelog describes repository evolution and must not be interpreted as runtime or production validation.

Tagged releases below describe repository/reference baselines only. Earlier pre-publication iterations remain documented as an untagged baseline because no historical release tags exist for them.

## [Unreleased]

No changes yet.

## [0.2.0] - 2026-09-20 - Runtime Evidence & Autonomous Assurance

### Added

- Versioned runtime evidence and assurance-receipt contracts with explicit repository, runtime, and production claim tiers.
- Reproducible ephemeral Kubernetes Runtime Lab with Argo CD reconciliation, policy denial, immutable workload-digest observation, cleanup, and residue verification.
- Ed25519-signed runtime assurance receipts and independent identity/signature verification.
- Continuous-assurance drift, degradation, recovery, and historical-vs-current evidence semantics.
- Official GoldenPath CLI with machine-readable output, human reports, dependency diagnostics, and evidence-backed scorecards.
- Exact P5 release-candidate qualification binding repository validation, Runtime Lab facts, receipt, independent verification, current-state assurance, scorecard, and documentation review.

### Changed

- The supported v0.2.0 path now self-qualifies the exact release candidate instead of treating prior green runs as release evidence.
- Runtime and production claims are separated more explicitly across the public quickstart, demo, showcase, architecture, and release documentation.

### Security

- Missing, stale, tampered, identity-mismatched, or production-overclaim candidate evidence fails closed.
- Release qualification verifies the exact receipt/evidence/public-key file digests recorded by independent verification before accepting the candidate.

**Evidence boundary:** repository/reference and supported ephemeral-runtime evidence. **Production validation is not claimed.**

## [0.1.0] - 2026-09-18 - Public Reference Baseline

### Added

- Active root-level repository validation for English-only content, structured files, shell syntax, Markdown links, Terraform modules/tests/stacks, GitOps/policy contracts, and the Go service template.
- A stable `Repository validation gate` that aggregates required/applicable validation domains for branch-protection use.
- Full reachable-history secret scanning with pinned, checksum-verified Gitleaks and a fail-closed runtime canary.
- Versioned `goldenpath.evidence/v1` Evidence Manifest semantics with explicit `PASS`, `FAIL`, `INFRASTRUCTURE_FAILURE`, and `SKIP_ALLOWED` outcomes.
- Versioned Architecture as Code and `goldenpath.assurance/v1` R0-R4 risk-adaptive assurance semantics.
- Fail-closed policy-exception validation and exact-scope exception application for Terraform/Conftest paths while Gatekeeper remains independently strict.
- Multi-provider Terraform policy coverage for mapped AWS, Azure, and Google Cloud public-access, metadata, and least-privilege outcomes.
- Argo CD-native multi-source Helm reconciliation for shared platform add-ons.
- Exact platform chart/environment rendering in root CI for the supported reference matrix.
- Envoy Gateway and a platform-owned `GatewayClass/golden-path` as the Gateway API reference baseline.
- ADRs, runbooks, architecture documentation, security guidance, maturity model, public-release runbook, and an evidence-aware audit checklist.
- A working Go paved-road service template with non-interactive rendering, format/vet/test/build validation, immutable base-image digests, and a Distroless non-root runtime.
- Reviewable Dependabot configuration for active GitHub Actions and implemented Go-template container dependencies.
- Public landing improvements with a dedicated GoldenPath delivery architecture visual and a clearer evidence-first README.
- A zero-cloud public assurance demo (`./scripts/demo.sh`) that derives an R0-R4 plan, validates matching evidence, and proves fail-closed rejection of incomplete required-gate evidence.
- Digest-bound GitOps promotion that verifies an exact immutable image identity, keyless signature, and signed SLSA provenance before mutating desired state.

### Changed

- Standardized repository documentation and contribution content on English and enforced the convention in CI.
- Reframed GoldenPath as a production-oriented reference implementation whose claims are bounded by available evidence.
- Established Argo CD as the sole authoritative Kubernetes reconciler for the reference platform layer.
- Removed active Flux reconciliation dependencies from platform desired state.
- Migrated the executable Conftest policy bundle to Rego v1 semantics and Conftest 0.70.0 without a v0 compatibility flag.
- Replaced deprecated Kustomize `commonLabels` usage while preserving explicit selector behavior.
- Removed ingress-nginx from the recommended new-production baseline and documented controlled migration to Gateway API / Envoy Gateway.
- Migrated Loki, Tempo, cert-manager, External Secrets, kube-prometheus-stack, and Gatekeeper reference definitions to maintained/current chart baselines tracked by repository validation.
- Normalized Google Cloud object-storage labels to provider-native constraints while preserving fail-closed ownership policy behavior.
- Routed Terraform module/platform-stack changes through policy validation as well as Terraform validation.
- Kept provider encryption differences explicit instead of claiming false AWS/Azure/GCP configuration symmetry.
- Pinned active external GitHub Actions to immutable commit SHAs and replaced mutable hosted-runner aliases with the explicit `ubuntu-24.04` family.
- Added checksum verification for downloaded CI executables and hash-locked active Python CI dependencies.
- Bound the implemented Go release path to immutable image digests and identity-constrained signature/provenance verification.
- Reworked the public quick-entry path around evidence-backed delivery while preserving explicit repository, runtime, and production evidence boundaries.

### Security

- The complete reachable Git history is scanned for secrets on every active root validation run.
- Secret scanning is trusted only after a canary secret is detected with the expected fail-closed exit behavior.
- Repository evidence, runtime evidence, and production validation are explicitly separated throughout documentation and machine-readable assurance contracts.
- Production/runtime claims require evidence bound to exact source, target, and relevant artifact/desired-state identities.

## Pre-publication baseline (untagged)

Before the current public-reference baseline, the repository established the initial consolidated structure and core patterns that were later hardened and corrected. This work included:

- reusable Terraform networking, IAM/OIDC, and object-storage module references;
- dev/staging/prod GitOps and Kustomize layout;
- initial Argo CD delivery structure;
- initial OPA/Conftest and Gatekeeper policy examples;
- the first Go service-template implementation;
- promotion and rollback scripts/runbooks;
- initial observability, security, operations, and developer-experience documentation.

These entries describe pre-publication repository evolution only. They are intentionally not assigned release dates or version tags here because the current GitHub repository does not contain corresponding release tags. The current tree, exact commit history, active CI, and evidence documentation are authoritative for capabilities that exist today.
