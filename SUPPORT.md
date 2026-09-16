# Support Model

Golden Path should be operated as a platform product with explicit ownership and escalation paths.

## Support tiers

### Developer self-service

Developers should first use the documentation, templates, policy messages, and runbooks in this repository. The paved road should make routine service creation, validation, promotion, and rollback understandable without a platform ticket.

### Platform support

The platform team owns issues involving shared Terraform modules, GitOps reconciliation, platform add-ons, cluster-level policy, service templates, platform CI/CD patterns, observability integration, and platform documentation.

### Security escalation

Escalate suspected credential exposure, privilege escalation, policy bypass, supply-chain compromise, unauthorized production change, or exploitable platform configuration through the organization's security incident process.

### Cloud or cluster escalation

Provider outages, account-level limits, control-plane failures, networking incidents, registry failures, and managed-service degradation may require escalation to cloud or managed-service support.

## Required context for support requests

Include the repository path, environment, service/team, commit SHA, relevant workflow or Argo CD application, timestamps, error output, recent changes, and whether a rollback has already been attempted.

## Ownership metadata

A production implementation should keep service ownership, escalation contacts, criticality, SLOs, and runbook links in a service catalog or equivalent metadata source. The reference repository documents that contract but does not contain an organization-specific catalog backend.
