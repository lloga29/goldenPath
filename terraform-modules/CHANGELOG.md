# Changelog

All notable changes to the Terraform module baseline are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) and uses Semantic Versioning principles.

## [Unreleased]

### Changed
- Standardized module documentation and repository text on English.
- Clarified the currently implemented module set versus original roadmap intent.

## [0.1.0] - 2024-01-15

### Added
- Initial repository structure.
- `networking/vpc` multi-provider network reference.
- `security/iam-role` AWS IAM role reference.
- `security/github-oidc` AWS GitHub Actions federation reference.
- `storage/object-storage` multi-provider object storage reference.
- `patterns/three-tier-app` reference pattern.
- CI/CD workflow blueprints for validation and releases.
- Initial documentation and contribution guidance.
- Pre-commit configuration.
- Terraform-native test examples.

### Security
- Checkov and tfsec workflow references.
- Required metadata/tag policy intent.
- Secure-default guidance for encryption and public access.

> The original roadmap also described additional compute, database, cache, KMS, WAF, observability, and data modules. Those capabilities must not be treated as implemented unless executable module code exists in the current tree.
