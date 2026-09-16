# Platform Policies - Golden Path

Security, reliability, and governance policy-as-code references for Terraform and Kubernetes.

## Current enforcement scope

The Terraform policy bundle currently implements **AWS-specific** controls for public exposure, encryption, required metadata, and high-risk IAM wildcards. Azure and Google Cloud parity is tracked in issue #15 and must not be implied until those controls and fixtures exist.

The Kubernetes policy bundle evaluates Pod-style workloads, Deployments, StatefulSets, DaemonSets, Jobs, CronJobs, Services, and Ingresses where relevant. It covers immutable image references, resource requests/limits, standard labels, restrictive security context, host namespace isolation, and privileged containers.

## Structure

```text
platform-policies/
├── terraform/              # Terraform plan policies
├── kubernetes/             # Kubernetes manifest policies
├── tests/                  # Positive and negative fixtures
├── scripts/                # Policy and exception validation helpers
├── policy-exceptions.yaml  # Governed exception registry
└── docs/
```

## Local evaluation

```bash
terraform plan -out=tfplan
terraform show -json tfplan > tfplan.json
conftest test tfplan.json --policy platform-policies/terraform/
```

```bash
conftest test rendered-manifest.yaml --policy platform-policies/kubernetes/
```

Run the repository fixtures:

```bash
./platform-policies/scripts/test-policies.sh
python3 ./platform-policies/scripts/validate-exceptions.py \
  ./platform-policies/policy-exceptions.yaml
```

## Kubernetes evaluation contract

Evaluate **rendered environment manifests**, not unrendered Kustomize bases. Environment labels and promoted image references are overlay concerns and must be present in the final desired state evaluated by CI.

## Terraform companion-resource convention

Modern AWS resources often split security controls into companion resources. The current S3 rules correlate bucket, encryption configuration, and public-access-block resources by known bucket value when available, and otherwise by module/logical Terraform identity. Reference modules should use the same logical name/index for companion resources.

## Enforcement model

A `deny` result is blocking only when the active integration propagates the Conftest/Gatekeeper failure. Do not hide policy failures behind `continue-on-error`, `|| true`, or equivalent soft-failure behavior.

Gatekeeper admission templates live under `gitops-config/policies/`; Conftest remains the broader pre-merge policy bundle. The admission bundle is intentionally a defense-in-depth subset and its deployment dependency is documented separately from policy logic.

## Exceptions

`policy-exceptions.yaml` is machine-validated for identity, ownership, approval, tracking, and expiry. It does **not** automatically bypass a policy today. Safe integration of approved exceptions with Conftest and admission is tracked in issue #14. Global policy disabling is prohibited.

See [Policy Guide](docs/POLICY_GUIDE.md) and [Policy Exceptions](../docs/governance/policy-exceptions.md).
