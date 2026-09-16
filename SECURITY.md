# Security Policy

Golden Path is a security-sensitive platform reference because it defines infrastructure, identity, delivery, and Kubernetes guardrails.

## Security principles

- Prefer short-lived federated credentials over static cloud credentials.
- Apply least privilege to humans, CI/CD identities, workloads, and platform components.
- Keep secrets outside Git and synchronize them through approved secret-management integrations.
- Use immutable artifact identifiers for promotion.
- Require review and auditability for production-affecting changes.
- Enforce workload security at both CI and admission time where feasible.
- Encrypt data in transit and at rest.
- Collect security-relevant logs and preserve evidence according to organizational requirements.
- Keep exceptions explicit, owned, time-limited, and reviewable.

## Reporting a vulnerability

Do not open a public issue for a suspected vulnerability that exposes credentials, sensitive topology, exploitable configuration, or customer information. Use the private security reporting mechanism configured for the hosting organization or contact the designated security/platform owner.

A useful report includes the affected path, version or commit, reproduction steps, impact, prerequisites, and any suggested remediation.

## Secrets

Never commit real credentials, private keys, tokens, kubeconfigs, cloud access keys, database passwords, or production certificates. Example values must be clearly non-production placeholders.

## Dependency and image security

Production implementations should include dependency scanning, container scanning, SBOM generation, image signing, signature verification, and provenance verification. The current repository documents these controls as the target supply-chain baseline; not all are implemented by executable root workflows yet.

## Supported baseline

This repository is a reference implementation rather than a hosted platform service. Security support therefore applies to the repository baseline and its documentation, not to any external environment unless that environment has separately adopted and validated the controls.
