# Runbook: Infrastructure Drift Detected

## Trigger

Use when Terraform plan, scheduled drift detection, cloud posture tooling, or manual review finds a difference between declared infrastructure and real infrastructure.

## Initial checks

1. Identify the exact resource and environment.
2. Determine whether the change was manual, provider-generated, another controller's responsibility, or a legitimate emergency action.
3. Review cloud audit logs and recent Git/CI changes.
4. Assess security and availability impact before applying anything.

## Terraform diagnosis

```bash
terraform init
terraform plan -refresh-only
terraform plan
```

Do not automatically apply a plan merely to eliminate drift. Confirm why the difference exists.

## Remediation paths

### Revert unauthorized runtime change

If Git represents the correct desired state and the runtime change is unsafe or unintended, use the normal reviewed apply path to restore declared state.

### Adopt a legitimate runtime change

If an emergency or external process made a valid change, update Terraform configuration or ownership boundaries so code accurately represents the accepted state, then review the resulting plan.

### Ignore provider-managed attributes intentionally

Use lifecycle ignore rules only when another authoritative controller owns the field and the ownership is documented. Broad ignore rules can hide real drift.

## Security drift

Escalate immediately when drift affects IAM, public access, encryption, networking boundaries, audit logging, secret access, or production protection settings.

## Validation

A resolved incident ends with a clean, understood Terraform plan and evidence that the runtime matches the approved ownership model.

## Follow-up

Record root cause, actor/process, detection delay, remediation, and whether prevention requires stronger IAM, policy, monitoring, or documentation.
