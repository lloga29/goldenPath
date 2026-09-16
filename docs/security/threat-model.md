# Platform Threat Model

This threat model identifies representative risks for the Golden Path control plane and paved road.

## Assets

Critical assets include source code, Terraform state, GitOps desired state, cloud identities, cluster credentials, signing material, secret-manager access, container registries, production clusters, DNS/TLS configuration, and audit evidence.

## Representative threats

### Compromised developer identity

An attacker may attempt to merge malicious infrastructure or GitOps changes. Mitigations include MFA/SSO, protected branches, review, CODEOWNERS, environment approvals, and audit logging.

### Compromised CI runner

A runner could steal credentials or alter artifacts. Use short-lived identity, isolated/ephemeral runners, minimal permissions, immutable publication, signing/provenance, and separation between build and deploy authorities.

### Malicious or vulnerable dependency

Dependencies can execute at build time or introduce runtime vulnerabilities. Pin and review dependencies, scan artifacts, generate SBOMs, and use controlled update automation.

### GitOps repository compromise

Malicious desired state can become cluster state. Protect the repository, restrict Argo CD source repositories and destinations, enforce admission policy, and require production review.

### Cluster privilege escalation

A workload may attempt privileged execution, host access, or broad Kubernetes API access. Enforce Pod Security-compatible constraints, least-privilege service accounts/RBAC, and network boundaries.

### Secret exfiltration

Secrets may leak through Git, CI logs, environment variables, or broad workload access. Keep secrets in dedicated managers, minimize scope, scan repositories, redact logs, and rotate rapidly.

### Cross-client or cross-environment impact

Shared state, credentials, networks, or clusters can cause isolation failure. Use isolation boundaries proportional to customer and regulatory risk.

## Review triggers

Update the threat model when introducing a new cloud provider, CI runner model, registry, cluster topology, secret manager, public ingress path, signing system, or customer isolation model.
