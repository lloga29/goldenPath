# Golden Path Audit Checklist

This checklist tracks gaps between the reference repository and an operational production Golden Path. Checked status must be based on repository or runtime evidence, not intent.

## P0 - Repository correctness and usable paved road

### Repository-wide
- [x] Establish English as the repository language.
- [x] Add authoritative architecture and operating documentation.
- [ ] Remove remaining Spanish text from code, configuration, comments, workflows, templates, and generated messages.
- [ ] Add active repository-root CI for this consolidated repository, or split the logical components into standalone repositories.
- [ ] Validate all documentation links and rendered Mermaid diagrams.

### terraform-modules/
- [x] Provide terraform-docs header/footer files.
- [x] Provide a detect-secrets baseline.
- [x] Provide module validation and documentation scripts.
- [ ] Validate every currently implemented module with the required provider/tool versions.
- [ ] Remove or implement any placeholder/empty module directories that could imply unsupported capability.
- [ ] Resolve provider-specific placeholders in reference modules before production use.

### platform-stacks/
- [ ] Implement or remove documentation references to `scripts/init-environment.sh` if it is still absent.
- [ ] Validate client bootstrap and environment templates end to end in a disposable account.
- [ ] Activate CI plan/apply workflows in their effective repository location.
- [ ] Verify remote-state bootstrapping and isolation for the selected production cloud.

### gitops-config/
- [x] Provide dev/staging/prod cluster configuration references.
- [x] Provide a staging application overlay reference.
- [x] Provide promotion and rollback documentation.
- [x] Provide reference platform add-ons and environment overlays.
- [ ] Validate all Kustomize overlays render successfully.
- [ ] Validate all Argo CD ApplicationSets and AppProjects against a real control plane.
- [ ] Verify promotion and rollback scripts with a disposable GitOps repository/branch.

### service-templates/
- [x] Implement the Go microservice template baseline.
- [ ] Add automated template-rendering tests.
- [ ] Add Python template only when an executable template and full operational contract are ready.
- [ ] Add Terraform stack template only when an executable template and validation are ready.

### platform-policies/
- [x] Provide Terraform and Kubernetes OPA policy baselines.
- [x] Provide Gatekeeper constraint examples.
- [ ] Add/verify regression fixtures for every blocking policy.
- [ ] Validate the exception mechanism and expiry behavior.

## P1 - Security and production correctness

- [ ] Enforce immutable release references; prohibit `:latest` for production workloads.
- [ ] Configure cloud OIDC/workload federation for the selected target environments.
- [ ] Verify least privilege for CI/CD, Argo CD, Kubernetes service accounts, and cloud roles.
- [ ] Configure real external secret management and rotation.
- [ ] Enable protected production change paths and required approvals.
- [ ] Confirm encryption, logging, backup, and recovery for Terraform state.
- [ ] Validate runtime admission policies in staged/audit mode before enforcement.
- [ ] Implement build-once promotion using immutable artifact identities.
- [ ] Exercise application rollback and Git reconciliation.

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
