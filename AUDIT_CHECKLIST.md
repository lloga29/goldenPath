# Golden Path Audit Checklist

This checklist tracks gaps between the reference repository and an operational production Golden Path. A checked item must be supported by repository or runtime evidence, not intent. Static CI evidence must never be presented as proof that an external cloud, cluster, identity system, DNS zone, certificate authority, secret backend, or hosted runner image is operationally immutable.

## Evidence status vocabulary

Use these terms consistently when describing a capability:

- **implemented** — code or configuration exists and is structurally valid;
- **reference** — an executable repository pattern is demonstrated with deterministic repository evidence;
- **runtime-validated** — the exact capability and source state were exercised against an identified runtime and have successful runtime evidence;
- **production-validated** — the exact capability and source state were exercised against the production target and have successful production runtime evidence.

A higher evidence status must never be inferred from a lower one.

## P0 - Repository correctness and usable paved road

### Repository-wide
- [x] Establish English as the repository language.
- [x] Add authoritative architecture and operating documentation.
- [x] Enforce English-only text for tracked repository content through active root CI.
- [x] Run active repository-root CI for the consolidated repository.
- [x] Validate repository-local Markdown links in root CI.
- [x] Pin every external action used by active root workflows to a full commit SHA and validate that invariant in root CI.
- [x] Reject `*-latest` hosted-runner labels in active root workflows.
- [x] Verify SHA-256 before extracting or installing executable archives downloaded by active root CI.
- [x] Install active Python CI tooling only from committed `--require-hashes` lock files under the pinned Python/runtime assumptions.
- [x] Configure reviewable Dependabot pull requests for GitHub Actions and implemented Go-template Docker base images.
- [x] Scan the complete reachable Git history for committed secrets in root CI with a pinned, checksum-verified detector that must first pass a runtime canary.
- [ ] Validate Mermaid diagram rendering rather than only Markdown link structure.

### Assurance and evidence
- [x] Define a versioned `goldenpath.evidence/v1` Evidence Manifest schema.
- [x] Bind evidence to repository, exact source commit, policy digest, architecture digest, desired-state digest, timestamps, and capability/environment context.
- [x] Distinguish `PASS`, `FAIL`, `INFRASTRUCTURE_FAILURE`, and policy-authorized `SKIP_ALLOWED` gate outcomes.
- [x] Derive `READY` / `NOT_READY` from evidence instead of accepting a producer-selected readiness claim.
- [x] Fail closed when a required gate fails or its execution infrastructure cannot establish a trustworthy result.
- [x] Reject unauthorized skips and require an explicit reason for allowed skips.
- [x] Require runtime proof for `runtime-validated` and `production-validated` claims.
- [x] Require `production-validated` claims to target the `prod` environment.
- [x] Add positive and negative regression fixtures and execute them from active root CI.
- [x] Reject source-stale evidence through exact commit comparison with `--expected-commit`.
- [ ] Generate and retain Evidence Manifests from a real delivery repository/runtime rather than fixtures only.
- [ ] Compute and compare policy, architecture, and desired-state digests automatically at evidence-consumption time.
- [ ] Add durable retention/signing/provenance for production Evidence Manifests before using them as compliance evidence.

### terraform-modules/
- [x] Provide terraform-docs header/footer files.
- [x] Provide a detect-secrets baseline.
- [x] Provide module validation and documentation scripts.
- [x] Validate every currently implemented Terraform module/pattern with Terraform 1.16.2 and its declared provider constraints in root CI.
- [x] Run Terraform-native VPC tests with mock providers so validation does not require cloud credentials.
- [ ] Remove or implement any placeholder/empty module directories that could imply unsupported capability.
- [ ] Resolve provider-specific integration placeholders before production use.

### platform-stacks/
- [ ] Implement or remove documentation references to `scripts/init-environment.sh` if it is still absent.
- [x] Validate executable reference stack formatting and Terraform configuration in root CI.
- [ ] Validate client bootstrap and environment templates end to end in a disposable cloud account.
- [ ] Activate CI plan/apply workflows in their effective production repository location.
- [ ] Verify remote-state bootstrapping and isolation for the selected production cloud.

### gitops-config/
- [x] Provide dev/staging/prod cluster configuration references.
- [x] Provide a staging application overlay reference.
- [x] Provide promotion and rollback documentation.
- [x] Establish Argo CD as the sole authoritative Kubernetes reconciler for the reference platform layer.
- [x] Remove active Flux HelmRelease/HelmRepository dependencies from platform desired state.
- [x] Validate every Kustomize target with Kustomize 5.8.1 in root CI.
- [x] Replace deprecated `commonLabels` usage while preserving explicit selector behavior.
- [x] Validate the Argo CD platform contract, source allowlists, environment sync semantics, and GatewayClass ownership in root CI.
- [x] Require exact semantic-style chart version pins and render every platform Helm chart for dev/staging/prod values in root CI.
- [x] Remove ingress-nginx from the recommended new-production baseline and declare Envoy Gateway/Gateway API as the reference direction.
- [ ] Add provenance/digest verification for upstream platform chart artifacts where the upstream distribution supports it.
- [ ] Validate ApplicationSets and AppProjects against a real Argo CD control plane.
- [ ] Exercise Envoy Gateway, Gateway API routes, TLS/cert-manager integration, DNS, and rollback in a disposable target cluster.
- [ ] Verify promotion and rollback scripts with a disposable GitOps repository/branch.

### service-templates/
- [x] Implement the Go microservice template baseline.
- [x] Pin the root smoke-test runtime to Go 1.26.8.
- [x] Render the Go template non-interactively and run gofmt, `go vet`, tests, and executable build validation in root CI.
- [x] Pin Go-template builder and runtime base images to OCI digests and enforce that invariant in the smoke test.
- [x] Use the supported Distroless Debian 13 nonroot runtime for the implemented Go template and build the generated image in root CI.
- [ ] Add Python template only when an executable template and full operational contract are ready.
- [ ] Add Terraform stack template only when an executable template and validation are ready.

### platform-policies/
- [x] Provide Terraform and Kubernetes OPA policy baselines.
- [x] Provide Gatekeeper constraint examples.
- [x] Run positive and intentionally invalid aggregate Kubernetes/Terraform policy fixtures in root CI.
- [x] Evaluate the executable policy bundle under Conftest 0.70.0 with its default Rego v1 parser and no v0 compatibility flag.
- [x] Use Rego v1 syntax throughout the executable Conftest Kubernetes and Terraform policy modules (issue #30).
- [ ] Add dedicated regression fixtures for every blocking policy rule if aggregate fixtures do not uniquely exercise each rule.
- [x] Validate policy-exception registry schema, required ownership/approval metadata, date ordering, expiry, duplicate IDs, and prohibition of global `disabled_policies` in root CI.
- [ ] Prove exception application/approval workflow against a real governed delivery path before relying on it operationally.

## P1 - Security and production correctness

- [x] Reject mutable `:latest` publication in the implemented Go template smoke contract and require exact platform chart version pins.
- [x] Pin the active root CI language/tool baseline where controlled: CPython 3.13.15, Go 1.26.8, Terraform 1.16.2, Kustomize 5.8.1, Helm 4.3.0, and Conftest 0.70.0.
- [ ] Use a separately versioned/attested runner image if bit-for-bit CI environment reproducibility becomes a requirement; `ubuntu-24.04` fixes the OS family but not the hosted image build.
- [ ] Configure cloud OIDC/workload federation for the selected target environments.
- [ ] Verify least privilege for CI/CD, Argo CD, Kubernetes service accounts, and cloud roles in the real target environment.
- [ ] Configure a real external secret backend and rotation process; examples/placeholders are intentionally not reconciled.
- [ ] Enable protected production change paths and required approvals in the hosting organization.
- [ ] Confirm encryption, logging, backup, and recovery for production Terraform state.
- [ ] Validate runtime admission policies in staged/audit mode before enforcement.
- [ ] Implement end-to-end build-once promotion using immutable artifact identities in a real delivery repository.
- [ ] Exercise application rollback and Git reconciliation in a disposable/production-like environment.
- [ ] Establish a current, supported platform dependency baseline and prove upgrade/rollback procedures.
- [ ] Introduce R0-R4 change-risk classification to select additional gates, reviewers, previews, and approvals without weakening global minimum controls.

## P2 - Platform maturity

- [ ] Generate SBOMs for release artifacts.
- [ ] Sign artifacts and publish provenance.
- [ ] Verify signatures/provenance before production deployment.
- [ ] Implement a service catalog and scorecards.
- [ ] Add automated template/module upgrade workflows.
- [ ] Operationalize platform and service SLOs.
- [ ] Run disaster-recovery exercises and record measured RTO/RPO.
- [ ] Add vulnerability-management automation and remediation SLAs.
- [ ] Add cost allocation and capacity dashboards.
- [ ] Collect DORA and platform-adoption metrics.
