# Golden Path Implementation Guide

This guide describes how to turn the reference repository into an operational internal developer platform.

## 1. Define the platform product

Before provisioning infrastructure, define the consumers, supported workload types, service levels, cloud boundaries, regulatory constraints, support model, and the problems the paved road is expected to solve. Treat developer experience as a product surface rather than a collection of scripts.

## 2. Establish identity first

Prefer federated identity for CI/CD and workload access. GitHub Actions should obtain short-lived cloud credentials through OIDC where supported. Kubernetes workloads should use the provider's workload identity mechanism or another short-lived identity integration. Human production access should be least privilege and independently auditable.

The repository includes a GitHub OIDC Terraform module as a reference. Production trust policies must be narrowed to the real organization, repository, branch/environment, and workload requirements.

## 3. Bootstrap remote Terraform state

Create remote state storage outside the ordinary application stacks. Required controls include encryption, access logging, locking or concurrency protection, backup/versioning, least privilege, break-glass recovery, and documented ownership. Never store production state files in Git.

Use a bootstrap layer per client or isolation boundary, then configure foundation and environment stacks to consume that backend.

## 4. Provision the foundation

A typical foundation includes:

- network topology and egress design;
- DNS and certificate ownership;
- cluster or compute substrate;
- registry;
- secret-management integration;
- workload identity;
- observability backends;
- policy engine;
- backup and recovery dependencies.

The Terraform code in this repository is a reference baseline and contains provider-specific assumptions and placeholders that must be reviewed before use.

## 5. Install Kubernetes platform add-ons

`gitops-config/platform/base/` contains reference definitions for:

- ingress-nginx;
- cert-manager;
- External Secrets;
- Prometheus stack;
- Loki;
- Tempo;
- Gatekeeper.

Pin chart versions, define resource budgets, harden RBAC, configure network policy where supported, and integrate each component with real storage, identity, TLS, alerting, and backup requirements.

## 6. Configure Argo CD

Register clusters using the minimum permissions required. Use AppProjects to constrain repositories, destinations, and resource kinds. Use ApplicationSets to reduce repetitive application definitions while keeping environment behavior explicit.

Production Argo CD should be protected with SSO, least-privilege RBAC, audit logging, HA appropriate to business criticality, and backup/recovery procedures for configuration and repository dependencies.

## 7. Establish the service contract

Every paved-road service should define at least:

- owner/team;
- service name and purpose;
- environment and criticality;
- health/readiness endpoints;
- resource requests and limits;
- application version;
- immutable image reference;
- logs, metrics, and traces;
- SLO and alert ownership;
- runbook and repository links;
- data classification and external dependencies where applicable.

The Go template is the implemented starting point. Additional templates should be added only after their operational contract is equivalent.

## 8. Build a real CI pipeline

The reference subdirectories contain CI workflow blueprints. In a production repository, activate equivalent root workflows that perform the controls appropriate to the component. A service pipeline normally includes:

1. formatting and linting;
2. unit tests;
3. dependency and secret scanning;
4. SAST where appropriate;
5. container build;
6. container vulnerability scan;
7. SBOM generation;
8. signing and provenance generation;
9. immutable publication;
10. promotion request into GitOps.

Infrastructure pipelines should add Terraform validation, policy checks, cost feedback, plan review, and controlled apply.

## 9. Enforce policy in layers

Use fast policy checks in pull requests and runtime admission controls for rules that must remain enforceable even if CI is bypassed. Avoid silent `|| true` behavior for controls intended to block unsafe changes. Advisory checks must be labeled as advisory.

Policy exceptions must have an owner, justification, scope, approval, expiration date, and remediation plan.

## 10. Implement build-once promotion

A release artifact should be built once and referenced immutably. Promotion changes environment desired state; it does not create a new binary. Prefer image digests for high-assurance promotion and tags only when registry immutability is guaranteed.

## 11. Operationalize observability

Collect the four signal families needed for platform operation:

- metrics;
- logs;
- traces;
- events/audit data.

Define SLOs for the platform and for critical services. Alerts should be actionable, owned, and linked to runbooks.

## 12. Operationalize security

The minimum production program should cover identity, secrets, network boundaries, vulnerability management, artifact provenance, policy enforcement, patching, dependency updates, Kubernetes hardening, cloud posture, incident response, and evidence retention.

## 13. Test recovery

Documenting rollback is not enough. Exercise application rollback, GitOps recovery, secret rotation, certificate renewal, Terraform-state recovery, cluster recovery, and restoration of critical observability/security dependencies.

## 14. Measure the platform

Track adoption and outcomes rather than only infrastructure availability. Useful metrics include:

- deployment frequency;
- lead time for changes;
- change failure rate;
- mean time to restore;
- template adoption;
- policy compliance and exception age;
- platform ticket volume;
- failed deployment rate;
- GitOps drift duration;
- developer onboarding time;
- infrastructure cost by owner/environment.

## 15. Evolve through maturity levels

Use [the maturity model](docs/maturity-model.md) and [roadmap](docs/roadmap.md) to sequence improvements. Do not attempt to deploy every possible platform capability before a real team uses the paved road; establish a safe minimum, pilot it, measure friction, and iterate.

## Production exit criteria

A Golden Path can be treated as an operational platform capability when:

- identity boundaries are implemented and tested;
- production changes are reviewable and protected;
- artifact promotion is immutable;
- policy enforcement cannot be trivially bypassed;
- secrets remain outside Git;
- observability and alert ownership are live;
- SLOs and incident processes exist;
- backup and recovery have been tested;
- ownership is explicit;
- platform documentation matches actual behavior;
- at least one real service has completed the full lifecycle through the paved road.
