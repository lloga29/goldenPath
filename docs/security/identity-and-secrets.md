# Identity and Secrets

Identity is the preferred control plane for authorization. Secrets are a fallback for values that cannot be represented as identity.

## Human identity

Use centralized SSO and MFA. Production roles should be separated from everyday developer permissions. Administrative access should be attributable to an individual and retained in audit logs.

## CI/CD identity

GitHub Actions should use OIDC federation to obtain short-lived cloud credentials. Trust policies should constrain the repository, organization, branch/environment, and intended audience/subject as tightly as the provider supports.

The existing Terraform module demonstrates AWS federation. Equivalent patterns are required for Azure and GCP if those providers are adopted.

## Workload identity

Applications should access cloud services through workload identity or provider-native service identity rather than embedded cloud keys. Kubernetes service accounts must not automatically imply broad cloud permissions.

## Secret management

The reference GitOps platform includes External Secrets. A production implementation must define:

- authoritative secret manager;
- authentication method;
- namespace/service access boundaries;
- rotation frequency;
- audit logging;
- emergency revocation;
- secret synchronization behavior during provider outages;
- ownership.

## Git rules

Never commit real passwords, tokens, private keys, kubeconfigs, signing keys, production certificates, or cloud credentials. Secret scanning should run locally and in CI.

## Rotation

Rotation must be testable without an outage. Prefer dual-key or overlapping-validity patterns where protocols support them. See the secret rotation runbook.

## Break glass

Emergency access should be rare, time-bounded, monitored, and followed by review. Break-glass credentials must not become the routine deployment path.
