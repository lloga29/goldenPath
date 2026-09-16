# ADR-0004: Prefer OIDC Federation for CI/CD Identity

- Status: Accepted

## Context

Static cloud credentials in CI create rotation burden and high-impact secret leakage risk.

## Decision

Use GitHub Actions OIDC federation for supported cloud access, issuing short-lived credentials constrained by repository/environment claims. Apply equivalent federation patterns for each adopted cloud provider.

## Consequences

Trust policies become security-critical infrastructure. CI jobs need explicit token permissions and cloud roles must remain least privilege. Static keys should be treated as exceptions rather than the normal path.
