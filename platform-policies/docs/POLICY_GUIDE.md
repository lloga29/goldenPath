# Policy Guide - Golden Path

This guide describes the current policy-as-code baseline and how to operate it safely.

## Terraform policies

### Public access

Prevent unintended Internet exposure for supported resource types. Review any intentionally public endpoint through an explicit architecture/security decision rather than a permanent broad bypass.

### Encryption

Require encryption for supported storage/database resource types where the provider exposes the setting. Prefer organization-managed key policy when compliance requires it.

### Required metadata

Require ownership/environment/cost metadata so findings and spend can be routed to responsible teams.

### IAM wildcard restrictions

Reject broad wildcard permissions when more specific actions/resources can be used. Treat identity policies as code that requires review and tests.

## Kubernetes policies

The current baseline checks workload security properties, required labels, resource requests/limits, security context, and immutable image-tag behavior.

## Local execution

```bash
conftest test tfplan.json --policy platform-policies/terraform/
conftest test deployment.yaml --policy platform-policies/kubernetes/
```

## Severity and enforcement

- `deny`: intended to block when the active integration propagates the failure.
- `warn`: advisory feedback that does not block.

Do not describe a policy as enforced when its workflow uses `continue-on-error` or suppresses the command's exit code.

## Exceptions

Use the governed exception model instead of undocumented skip comments. If an external scanner requires an inline suppression, include a tracked exception identifier and expiry/owner in the authoritative exception process.

## Rollout

For new blocking rules on existing estates, inventory violations first, run in audit/advisory mode, remediate, then enable enforcement with rollback and owner communication.
