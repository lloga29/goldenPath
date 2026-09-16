# Platform Policies - Golden Path

Security, reliability, and governance policy-as-code references for Terraform and Kubernetes.

## Structure

```text
terraform/           # Terraform-plan policies evaluated with OPA/Conftest
kubernetes/          # Kubernetes manifest policies
policy-exceptions.yaml
docs/
```

## Terraform policy themes

The current repository includes examples covering public access, encryption, required metadata/tags, and wildcard IAM permissions.

## Kubernetes policy themes

The current repository includes examples covering workload security, security context, required labels, immutable image tags, and resource requests/limits.

## Local evaluation

```bash
terraform plan -out=tfplan
terraform show -json tfplan > tfplan.json
conftest test tfplan.json --policy platform-policies/terraform/
```

```bash
conftest test deployment.yaml --policy platform-policies/kubernetes/
```

## Enforcement model

Policy checks may run locally, in pull-request CI, or at Kubernetes admission time. A control is only enforced when the active pipeline/admission configuration actually blocks a violation. The nested workflow blueprints in this consolidated repository are not proof of active enforcement.

## Exceptions

Exceptions must be narrowly scoped, owned, justified, approved, and time-bounded. See [Policy Exceptions](../docs/governance/policy-exceptions.md) and the reference `policy-exceptions.yaml`.

## Policy quality

Blocking policies require positive and negative fixtures, actionable error messages, staged rollout for existing workloads, and explicit ownership.
