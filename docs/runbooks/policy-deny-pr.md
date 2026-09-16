# Runbook: Policy Denied a Pull Request

## Trigger

A Conftest/OPA, Checkov, tfsec, admission-policy test, or equivalent required gate blocks a proposed change.

## Principle

A policy denial is expected platform feedback, not a CI defect by default. Understand the violation before considering an exception.

## Diagnosis

1. Read the complete policy message and identify the resource.
2. Locate the relevant policy file and documentation.
3. Reproduce the check locally when possible.
4. Determine whether the proposed configuration is incorrect, the policy has a defect, or the workload has a legitimate exceptional requirement.

Example:

```bash
conftest test tfplan.json --policy platform-policies/terraform/
conftest test deployment.yaml --policy platform-policies/kubernetes/
```

## Normal remediation

Modify the resource to satisfy the policy, rerun formatting/validation/policy tests, and push the updated change.

## Suspected policy defect

Create a minimal fixture that demonstrates incorrect policy behavior. Fix the policy and add regression tests rather than weakening the rule globally.

## Exception

Use the documented exception process only when remediation is not currently feasible and the residual risk is accepted. The exception must be narrow, owned, approved, and time-bounded.

## Escalation

Escalate to platform/security owners when the policy is ambiguous, the secure remediation conflicts with platform capabilities, or the exception affects a high-risk production control.
