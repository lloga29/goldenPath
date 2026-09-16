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
├── lib/                    # Shared Rego libraries, including exception matching
├── wrappers/               # Exception-aware Conftest entrypoint namespaces
├── tests/                  # Positive, negative, and exception-scope fixtures
├── scripts/                # Policy and exception validation helpers
├── policy-exceptions.yaml  # Governed exception registry
└── docs/
```

## Local evaluation

Policy exceptions are never passed directly to Conftest. First validate and compile the registry into canonical data:

```bash
python3 platform-policies/scripts/validate-exceptions.py \
  platform-policies/policy-exceptions.yaml \
  --output /tmp/goldenpath-policy-exceptions.json
```

Then load both the policy bundle and the shared exception library explicitly:

```bash
terraform plan -out=tfplan
terraform show -json tfplan > tfplan.json
conftest test tfplan.json \
  --policy platform-policies/terraform/ \
  --policy platform-policies/lib/ \
  --policy platform-policies/wrappers/ \
  --data /tmp/goldenpath-policy-exceptions.json \
  --namespace goldenpath.terraform
```

```bash
conftest test rendered-manifest.yaml \
  --policy platform-policies/kubernetes/ \
  --policy platform-policies/lib/ \
  --policy platform-policies/wrappers/ \
  --data /tmp/goldenpath-policy-exceptions.json \
  --namespace goldenpath.kubernetes
```

Run the complete repository fixtures:

```bash
./platform-policies/scripts/test-policies.sh
```

## Kubernetes evaluation contract

Evaluate **rendered environment manifests**, not unrendered Kustomize bases. Environment labels and promoted image references are overlay concerns and must be present in the final desired state evaluated by CI.

## Terraform companion-resource convention

Modern AWS resources often split security controls into companion resources. The current S3 rules correlate bucket, encryption configuration, and public-access-block resources by known bucket value when available, and otherwise by module/logical Terraform identity. Reference modules should use the same logical name/index for companion resources.

## Enforcement model

A `deny` result is blocking only when the active integration propagates the Conftest/Gatekeeper failure. Do not hide policy failures behind `continue-on-error`, `|| true`, or equivalent soft-failure behavior.

Gatekeeper admission templates live under `gitops-config/policies/`; Conftest remains the broader pre-merge policy bundle. The admission bundle is intentionally a defense-in-depth subset and its deployment dependency is documented separately from policy logic.

## Exceptions

`policy-exceptions.yaml` is the authoritative exception registry. CI validates it fail closed before producing the JSON data consumed by Conftest. An exception is matched only by an approved semantic policy ID and an exact resource selector; Kubernetes entries additionally require an exact namespace. Terraform selectors must include an exact resource type and logical name, not only a resource type. Duplicate scopes, expired entries, unknown policy IDs, wildcard selectors, malformed entries, and global-disable fields are rejected.

Conftest must query the `goldenpath.kubernetes` or `goldenpath.terraform` wrapper namespace; querying the implementation packages directly bypasses the exception contract and is not the supported entrypoint. When a matching exception suppresses a deny result, the wrapper emits an audit-visible warning containing the exception ID.

The admission boundary is deliberately stricter: **Gatekeeper does not consume the exception registry and remains fail closed.** The registry declares `gatekeeper: strict`, and validation rejects attempts to turn it into a registry-driven admission bypass. Existing Gatekeeper `excludedNamespaces` are static constraint scope, not policy exceptions. Gatekeeper overlaps selected Kubernetes controls but is not claimed to be semantically identical to Conftest; the exact current overlap and known Conftest-only checks are documented in the [Policy Guide](docs/POLICY_GUIDE.md).

See [Policy Guide](docs/POLICY_GUIDE.md) and [Policy Exceptions](../docs/governance/policy-exceptions.md).
