# Glossary

**ADR** — Architecture Decision Record; a durable record of an important technical decision and its consequences.

**ApplicationSet** — Argo CD resource that generates Applications from templates and generators.

**Artifact** — Immutable build output such as a container image.

**CI/CD** — Continuous Integration and Continuous Delivery/Deployment.

**Conftest** — Tool that evaluates structured configuration using OPA policies.

**DORA metrics** — Deployment frequency, lead time for changes, change failure rate, and mean time to restore.

**Error budget** — Allowed unreliability implied by an SLO.

**External Secrets** — Kubernetes integration that synchronizes data from external secret managers.

**Golden Path / paved road** — Supported, opinionated path that makes common engineering tasks safe and easy.

**GitOps** — Operating model where Git stores desired state and an automated controller reconciles runtime state toward it.

**Gatekeeper** — Kubernetes admission policy system based on OPA.

**Kustomize** — Kubernetes configuration customization through bases and overlays.

**OIDC** — OpenID Connect; used here primarily for short-lived workload/CI identity federation.

**OPA** — Open Policy Agent.

**RPO** — Recovery Point Objective; acceptable data-loss window.

**RTO** — Recovery Time Objective; target time to restore service.

**SBOM** — Software Bill of Materials.

**SLI** — Service Level Indicator.

**SLO** — Service Level Objective.

**Supply-chain provenance** — Verifiable metadata describing how and where an artifact was built.

**Terraform state** — Terraform's mapping between declared resources and real infrastructure; sensitive and operationally critical.

**Workload identity** — Short-lived identity assigned to a workload so it can access external services without embedded long-lived credentials.
