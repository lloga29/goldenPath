# Disaster Recovery

Disaster recovery covers the dependencies required to recreate or restore the platform and its managed workloads after a severe failure.

## Recovery objectives

Each production adoption should define RTO and RPO for application data, Terraform state, Git repositories, registries, clusters, secret management, DNS, certificates, and critical telemetry/security evidence.

## Recoverable sources

Git should contain declarative infrastructure and desired state, but Git alone is not a complete backup. Critical non-Git state includes Terraform state, application databases, secret-manager contents, registry artifacts, signing material, DNS/provider configuration, and observability/security data.

## Recovery order

A typical sequence is:

1. restore identity and administrative access;
2. restore remote Terraform state and bootstrap dependencies;
3. restore network/DNS/registry/secret-manager dependencies;
4. recreate or recover clusters;
5. restore Argo CD and cluster registration;
6. reconcile platform add-ons;
7. reconcile applications;
8. restore application data;
9. validate telemetry, alerts, certificates, and external integrations.

The exact sequence depends on architecture and must be tested.

## Backups

Backups require encryption, access control, retention, geographic strategy, immutability where appropriate, and restore testing. A successful backup job is not evidence of a successful restore.

## Exercises

Run scheduled recovery exercises. Capture actual recovery time, missing dependencies, undocumented credentials, manual steps, and changes required to meet objectives.

## GitOps caution

If a bad desired state caused the incident, blind reconciliation can reproduce the failure. Recovery procedures must identify a known-good Git state before restoring automated sync.
