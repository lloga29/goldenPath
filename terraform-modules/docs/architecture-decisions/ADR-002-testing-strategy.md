# ADR-002: Layer Terraform Validation and Testing

- Status: Accepted

## Context

Static validation alone cannot prove provider behavior, while full integration tests for every change are expensive and require cloud credentials.

## Decision

Use layered testing: formatting and `terraform validate`, lint/static/security analysis, Terraform-native tests for deterministic plan behavior, and targeted integration tests for provider behavior that cannot be validated locally.

## Consequences

Fast tests run frequently; integration tests are isolated and intentionally scoped. Test reports must distinguish validation performed without a backend/provider account from tests that created real infrastructure.
