# Policy as Code

Policy as code turns platform expectations into reviewable and testable controls.

## Current baseline

`platform-policies/` contains OPA/Rego policies for Terraform and Kubernetes. `gitops-config/policies/` contains Gatekeeper examples for runtime admission.

The current policy areas include examples for:

- public access restrictions;
- encryption;
- required tags and labels;
- wildcard IAM restrictions;
- immutable container tags;
- workload security context;
- CPU/memory resources.

## Enforcement layers

| Layer | Purpose |
|---|---|
| Local/pre-commit | Fast developer feedback |
| Pull request | Prevent unsafe changes before merge |
| Infrastructure plan | Evaluate the real planned resources |
| Kubernetes admission | Enforce runtime invariants |
| Periodic audit | Detect legacy/non-compliant resources |

Not every rule belongs at every layer. Avoid duplicating controls when the duplicated implementation can diverge.

## Blocking vs advisory

Every check must clearly state whether it is blocking or advisory. A blocking policy must propagate a non-zero failure. Advisory controls may report findings without blocking, but their status must not be presented as enforced compliance.

## Policy design

Good policy messages identify:

- the violating resource;
- the rule;
- why it matters;
- how to remediate;
- the exception path when one exists.

## Rollout

For existing estates, introduce high-impact policies using inventory, audit mode, remediation, staged enforcement, and final blocking mode. Enabling a strict admission rule without understanding current workloads can create an availability incident.

## Exceptions

Exceptions are governed objects, not comments that permanently bypass security. See [Policy Exceptions](../governance/policy-exceptions.md).

## Testing

Each critical policy should have positive and negative test fixtures. Treat policy changes as code changes with review and regression testing.
