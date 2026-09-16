# Golden Path Audit Checklist

This checklist tracks gaps between the reference repository and an operational production Golden Path. A checked item must be supported by repository or runtime evidence, not intent. Static CI evidence must never be presented as proof that an external cloud, cluster, identity system, DNS zone, certificate authority, or secret backend is operational.

## P0 - Repository correctness and usable paved road

### Repository-wide
- [x] Establish English as the repository language.
- [x] Add authoritative architecture and operating documentation.
- [x] Enforce English-only text for tracked repository content through active root CI.
- [x] Run active repository-root CI for the consolidated repository.
- [x] Validate repository-local Markdown links in root CI.
- [ ] Validate Mermaid diagram rendering rather than only Markdown link structure.

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
- [x] Render every pinned platform Helm chart for dev/staging/prod values in root CI.
- [x] Remove ingress-nginx from the recommended new-production baseline and declare Envoy Gateway/Gateway API as the reference direction.
- [ ] Validate ApplicationSets and AppProjects against a real Argo CD control plane.
- [ ] Exercise Envoy Gateway, Gateway API routes, TLS/cert-manager integration, DNS, and rollback in a disposable target cluster.
- [ ] Verify promotion and rollback scripts with a disposable GitOps repository/branch.

### service-templates/
- [x] Implement the Go microservice template baseline.
- [x] Render the Go template non-interactively and run gofmt, `go vet`, tests, and executable build validation in root CI.
- [ ] Add Python template only when an executable template and full operational contract are ready.
- [ ] Add Terraform stack template only when an executable template and validation are ready.

### platform-policies/
- [x] Provide Terraform and Kubernetes OPA policy baselines.
- [x] Provide Gatekeeper constraint examples.
- [x] Run positive and intentionally invalid aggregate Kubernetes/Terraform policy fixtures in root CI.
- [ ] Add dedicated regression fixtures for every blocking policy rule if aggregate fixtures do not uniquely exercise each rule.
- [x] Validate policy-exception registry schema, required ownership/approval metadata, date ordering, expiry, duplicate IDs, and prohibition of global `disabled_policies` in root CI.
- [ ] Prove exception application/approval workflow against a real governed delivery path before relying on it operationally.

## P1 - Security and production correctness

- [x] Reject mutable `:latest` publication in the implemented Go template smoke contract and require immutable chart versions in the Argo platform contract.
- [ ] Configure cloud OIDC/workload federation for the selected target environments.
- [ ] Verify least privilege for CI/CD, Argo CD, Kubernetes service accounts, and cloud roles in the real target environment.
- [ ] Configure a real external secret backend and rotation process; examples/placeholders are intentionally not reconciled.
- [ ] Enable protected production change paths and required approvals in the hosting organization.
- [ ] Confirm encryption, logging, backup, and recovery for production Terraform state.
- [ ] Validate runtime admission policies in staged/audit mode before enforcement.
- [ ] Implement end-to-end build-once promotion using immutable artifact identities in a real delivery repository.
- [ ] Exercise application rollback and Git reconciliation in a disposable/production-like environment.
- [ ] Establish a current, supported platform dependency baseline and prove upgrade/rollback procedures.

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
