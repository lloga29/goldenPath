# Golden Path Documentation

This directory is the authoritative documentation entry point for the Golden Path platform.

The repository implements an opinionated internal developer platform baseline built around reusable Terraform modules, environment stacks, GitHub Actions, Argo CD, Kustomize, Kubernetes policy enforcement, service templates, and operational runbooks.

All repository documentation, code comments, workflow labels, examples, operational messages, and contribution guidance must be written in English.

## Documentation map

- [Quickstart](QUICKSTART.md)
- [Architecture overview](architecture/overview.md)
- [Repository model](architecture/repository-model.md)
- [Developer onboarding](developer-experience/onboarding.md)
- [Service lifecycle](developer-experience/service-lifecycle.md)
- [Self-service workflow](developer-experience/self-service.md)
- [Terraform platform](platform/terraform.md)
- [Kubernetes and GitOps](platform/kubernetes-gitops.md)
- [Service templates](platform/service-templates.md)
- [Policy as code](platform/policy-as-code.md)
- [Security model](security/security-model.md)
- [Identity and secrets](security/identity-and-secrets.md)
- [Software supply chain](security/software-supply-chain.md)
- [Observability](operations/observability.md)
- [SLOs and SLIs](operations/slo-sli.md)
- [Disaster recovery](operations/disaster-recovery.md)
- [Capacity and cost management](operations/capacity-and-cost.md)
- [Ownership and RBAC](governance/ownership-and-rbac.md)
- [Change management](governance/change-management.md)
- [Policy exceptions](governance/policy-exceptions.md)
- [Public portfolio release](governance/public-release.md)
- [Branching and releases](standards/branching-and-releases.md)
- [Naming and metadata](standards/naming-and-metadata.md)
- [Documentation standard](standards/documentation.md)
- [Architecture Decision Records](adr/README.md)
- [Platform maturity model](maturity-model.md)
- [Adoption roadmap](roadmap.md)
- [v0.2.0 execution plan](releases/v0.2.0-execution-plan.md)
- [v0.2.0 release notes](releases/v0.2.0.md)
- [v0.2.0 migration notes](releases/v0.2.0-migration.md)
- [v0.2.0 release runbook](runbooks/v0.2.0-release.md)
- [v0.2.0 post-release checklist](releases/v0.2.0-post-release-checklist.md)
- [Glossary](glossary.md)

## Documentation principles

1. Document implemented behavior before recommendations.
2. Keep platform defaults separate from client- and environment-specific configuration.
3. Prefer executable examples and runbooks.
4. Treat Git as the review and audit source for infrastructure, policy, and deployment configuration.
5. Build once and promote immutable artifacts through environments.
6. Make security controls explicit about whether they are blocking or advisory.
7. Record significant architectural choices as ADRs.
