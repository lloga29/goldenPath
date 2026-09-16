# Terraform Platform

Terraform provides the infrastructure-as-code layer of the Golden Path.

## Repository responsibilities

`terraform-modules/` contains reusable primitives and patterns. `platform-stacks/` composes those primitives into client, foundation, environment, and ephemeral stacks.

The currently implemented module baseline includes:

- cloud-aware networking/VPC logic for AWS, Azure, and GCP;
- AWS IAM role patterns;
- GitHub Actions OIDC federation for AWS;
- object storage abstractions;
- a three-tier reference pattern.

The implementation should be treated as a reference baseline rather than a drop-in universal abstraction. Cloud providers expose different semantics, so production modules must preserve provider-specific controls instead of forcing false parity.

## Module contract

A production module should define:

- supported Terraform and provider versions;
- typed inputs and validation;
- deterministic outputs;
- secure defaults;
- examples;
- tests;
- generated reference documentation;
- ownership;
- release/change history;
- upgrade and deprecation expectations.

## State

Terraform state is sensitive operational data. Production backends should provide encryption, concurrency control or locking, versioning/backup, access logging, least privilege, and recovery procedures. State files must not be committed to Git.

Use separate state boundaries when blast radius, ownership, environment, or customer isolation requires it. Avoid monolithic state spanning unrelated teams or production domains.

## Authentication

CI/CD should use short-lived federated credentials. The repository includes an AWS GitHub OIDC module as a reference. Azure and GCP implementations should use their equivalent workload/federated identity capabilities rather than long-lived secrets.

## Plan and apply model

Pull requests should produce deterministic validation and plans. Applies should occur only after review and with environment-appropriate approval. Production apply identities must be more constrained than read/plan identities where practical.

## Policy and cost

Terraform plans can be converted to JSON and evaluated with Conftest/OPA. Static analysis can supplement this with tools such as Checkov or tfsec. Infracost can provide advisory cost feedback. A check intended to protect production must fail closed; do not hide failures with `|| true` unless the control is explicitly advisory.

## Drift

Drift detection should compare desired configuration with real infrastructure on a schedule and create actionable evidence. Remediation must decide whether the runtime change was unauthorized and should be reverted, or legitimate and should be imported into code.

## Module release policy

Consumers should pin immutable module versions. Breaking input/output changes require a major version. Security fixes should be documented with upgrade guidance and, when necessary, an explicit minimum supported version.
