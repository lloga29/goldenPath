# Policy Exceptions

Policy exceptions provide a controlled path for legitimate cases that cannot immediately satisfy a guardrail.

## Enforcement contract

`platform-policies/policy-exceptions.yaml` is the authoritative registry. CI validates and compiles it before Conftest receives any exception data. Raw registry content is not treated as an automatic bypass.

Conftest supports narrowly scoped exceptions. Gatekeeper intentionally remains strict and does not consume the registry. This is a deliberate fail-closed admission boundary, not an implementation gap.

## Required fields

Every active exception must contain:

- stable exception identifier (`EXC-YYYY-NNN` or greater sequence width);
- exact semantic policy identifier;
- exact affected resource;
- exact namespace for Kubernetes resources;
- technical/business justification;
- owner email;
- approver;
- tracking issue;
- creation date;
- expiration date.

Production integrations should additionally retain risk assessment, compensating controls, and remediation evidence in the tracking issue or governance system.

## Supported policy identifiers

Kubernetes:

- `kubernetes.images.immutable`
- `kubernetes.labels.required`
- `kubernetes.resources.required`
- `kubernetes.security.context`
- `kubernetes.workload.isolation`

Terraform:

- `terraform.public_access`
- `terraform.iam.no_wildcards`
- `terraform.identity.least_privilege`
- `terraform.encryption.required`
- `terraform.tags.required`

Unknown policy identifiers fail validation so a typo cannot silently create an ineffective or unexpectedly broad exception.

## Scope rules

Kubernetes resources use lowercase `kind/name` plus an exact namespace. For example:

```yaml
policy: kubernetes.images.immutable
resource: deployment/legacy-api
namespace: legacy-system
```

Terraform resources use the exact absolute Terraform resource address, including both type and logical resource name. Wildcards and type-only selectors are prohibited:

```yaml
policy: terraform.public_access
resource: aws_security_group_rule.temporary_ssh
```

Module-qualified and indexed addresses are supported when they identify one concrete Terraform resource instance, for example `module.edge[0].aws_security_group_rule.temporary_ssh[0]`.

Duplicate active scopes are rejected. An exception for one policy never suppresses another policy even when implementation packages or resource inputs overlap.

## Admission boundary

The registry must declare:

```yaml
enforcement:
  conftest: scoped-exceptions
  gatekeeper: strict
```

Gatekeeper constraints do not consume registry exceptions. A Kubernetes exception can suppress the matching Conftest deny result, but the runtime admission path remains strict. This prevents a repository exception from silently weakening cluster admission.

The admission bundle overlaps the immutable-image, required-label, resource, secure-context, and privileged-container controls, but it is not a one-to-one copy of the Conftest bundle. In particular, `kubernetes.workload.isolation` also blocks `hostNetwork`, `hostPID`, and `hostIPC` in Conftest while the current Gatekeeper isolation template covers privileged containers only. The detailed overlap matrix is maintained in `platform-policies/docs/POLICY_GUIDE.md`.

Existing Gatekeeper `excludedNamespaces` are static policy scope and are not temporary exception entries.

## Validation and compilation

```bash
python3 platform-policies/scripts/validate-exceptions.py \
  platform-policies/policy-exceptions.yaml \
  --output /tmp/goldenpath-policy-exceptions.json
```

Only the compiled JSON should be passed to Conftest. Policy evaluation must use the `goldenpath.kubernetes` or `goldenpath.terraform` wrapper namespace; direct queries of the implementation packages are not the supported exception-aware entrypoint. The validator fails on malformed fields, future creation dates, expired entries, duplicate IDs/scopes, unknown policies, invalid Kubernetes selectors, broad or wildcard Terraform selectors, unsupported top-level bypass fields, or a non-strict Gatekeeper mode.

## Audit behavior

When an exception matches, Conftest emits a warning containing the exception ID, policy ID, and exact resource scope. The deny result for that policy/resource is suppressed; unrelated policies continue evaluating normally.

CI fixtures prove successful exact-scope suppression and fail-closed behavior for wrong policy, wrong resource, wrong namespace, same-resource violations from another policy, expired entries, wildcards, unknown policies, malformed entries, global disabling, admission-boundary attempts, and provider-native identity controls.

## Lifecycle

1. Open a tracking issue and document why compliant remediation cannot meet the deadline.
2. Identify the exact semantic policy ID and resource scope.
3. Document risk and compensating controls.
4. Obtain the required approval.
5. Add the time-bounded registry entry.
6. Validate and compile the registry in CI.
7. Confirm CI output includes the exception ID when the scoped bypass is exercised.
8. For Kubernetes, remember that Gatekeeper remains strict; resolve admission separately rather than assuming the CI exception changes runtime policy.
9. Remediate before expiry.
10. Remove the exception and verify normal enforcement.

Renewal requires a new review before the previous expiry; silently extending expiry without reassessment is not the paved road.

## Metrics

Track active exceptions, expired/blocked exceptions, average age, repeated reasons, renewals, and exceptions by policy/team. A growing backlog often indicates either an unrealistic guardrail or a missing paved-road capability.
