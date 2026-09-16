# Contributing - Terraform Modules

## Prerequisites

- Terraform 1.5 or later, subject to the module's declared constraints.
- Pre-commit for local hooks.
- Provider/cloud CLI credentials only when a test explicitly requires real infrastructure.

## Workflow

Create a short-lived branch:

```bash
git checkout -b feat/<module-name>
```

A typical module layout is:

```text
modules/<category>/<module>/
├── main.tf
├── variables.tf
├── outputs.tf
├── versions.tf
├── README.md
├── CHANGELOG.md
├── examples/
└── tests/
```

Run relevant checks before review:

```bash
terraform fmt -recursive
terraform init -backend=false
terraform validate
terraform test
pre-commit run --all-files
```

Do not claim a cloud integration test passed when the required account, credentials, or provider dependency was unavailable.

## Code standards

Variables should be typed, documented, and validated when invalid values can be detected before apply. Defaults must not silently reduce security.

Required organizational metadata should be standardized centrally. The current reference commonly uses `Environment`, `Team`, `CostCenter`, `Owner`, and `ManagedBy`.

## Security

- No hard-coded credentials or secret values.
- Prefer encryption and private access defaults.
- Use least privilege for IAM policies and test identities.
- Treat Terraform state as sensitive.
- Avoid wildcard IAM permissions unless there is a documented, reviewed reason.

## Versioning

Use Semantic Versioning for published modules:

- **MAJOR** for incompatible changes;
- **MINOR** for backward-compatible functionality;
- **PATCH** for backward-compatible fixes.

## Pull requests

A module pull request should include the motivation, compatibility impact, security impact, tests, example updates, generated documentation updates, and upgrade guidance when behavior changes.
