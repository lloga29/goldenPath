# Policy Exceptions

Policy exceptions provide a controlled path for legitimate cases that cannot immediately satisfy a guardrail.

## Current repository state

`platform-policies/policy-exceptions.yaml` is the authoritative reference registry and is machine-validated for structure and expiry. **It does not currently bypass Conftest or Gatekeeper decisions.** Safe integration of approved exceptions with enforcement is tracked in issue #14.

This distinction is intentional: a registry must not become an undocumented global bypass simply because an entry exists.

## Required fields

Every active exception must contain:

- stable exception identifier (`EXC-YYYY-NNN` or greater sequence width);
- exact policy identifier;
- affected resource and namespace when applicable;
- technical/business justification;
- owner email;
- approver;
- tracking issue;
- creation date;
- expiration date.

Production integrations should additionally retain risk assessment, compensating controls, and remediation evidence in the tracking issue or governance system.

## Rules

Exceptions must be narrow, time-bounded, reviewable, and discoverable. Global policy disabling is prohibited by the repository validator.

Expired exceptions fail registry validation. Renewal requires a new review before the previous expiry; silently extending expiry without reassessment is not the paved road.

## Validation

```bash
python3 platform-policies/scripts/validate-exceptions.py \
  platform-policies/policy-exceptions.yaml
```

## Lifecycle

1. Open a tracking issue and document why compliant remediation cannot meet the deadline.
2. Identify the exact policy and resource scope.
3. Document risk and compensating controls.
4. Obtain the required approval.
5. Add the time-bounded registry entry.
6. Validate the registry in CI.
7. When #14 is implemented, enforcement may apply only that exact approved exception and must emit an audit-visible reference to its ID.
8. Remediate before expiry.
9. Remove the exception and verify normal enforcement.

## Metrics

Track active exceptions, expired/blocked exceptions, average age, repeated reasons, renewals, and exceptions by policy/team. A growing backlog often indicates either an unrealistic guardrail or a missing paved-road capability.
