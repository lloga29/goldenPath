# Policy Guide - Golden Path

This guide describes the current policy-as-code baseline and how to operate it safely.

## Terraform controls

The executable Terraform policy bundle is currently AWS-specific. Multi-provider policy parity is tracked in issue #15.

### Public access

- Reject public S3 ACLs.
- Require a matching S3 public-access-block companion resource and all four protection flags.
- Reject public sensitive-port ingress for supported AWS security-group representations.
- Reject publicly accessible RDS and Redshift instances/clusters.

Policy ID: `terraform.public_access`.

### Encryption

- Require EBS encryption.
- Require RDS instance/cluster storage encryption.
- Require a matching S3 server-side-encryption companion resource.
- Require ElastiCache at-rest and in-transit encryption.

Policy ID: `terraform.encryption.required`.

### Required metadata

Supported taggable resources must carry `Environment`, `Team`, `CostCenter`, and `Owner`. Environment values are constrained to `dev`, `staging`, `prod`, or `ephemeral`.

Policy ID: `terraform.tags.required`.

### IAM wildcard restrictions

Managed and inline IAM policy resources reject `Action: "*"` and reject sensitive IAM/KMS/secret-access actions against `Resource: "*"`. `NotAction` and `NotResource` generate review warnings.

Policy ID: `terraform.iam.no_wildcards`.

## Kubernetes controls

The policy bundle evaluates the rendered desired state and checks:

- explicit immutable image tags or SHA-256 digests — `kubernetes.images.immutable`;
- required application/ownership/environment labels — `kubernetes.labels.required`;
- CPU and memory requests and limits — `kubernetes.resources.required`;
- non-root execution and `allowPrivilegeEscalation=false` — `kubernetes.security.context`;
- privileged container and host namespace restrictions — `kubernetes.workload.isolation`;
- advisory read-only-root-filesystem, dropped-capability, and probe guidance.

## Positive and negative fixtures

Every blocking policy change must preserve a passing fixture and at least one deliberately failing fixture. Run:

```bash
./platform-policies/scripts/test-policies.sh
```

The suite proves baseline failures, exact exception matches, same-resource policy isolation, resource and namespace isolation, audit-visible exception IDs, expired exceptions, unknown policy IDs, malformed entries, wildcard rejection, type-only Terraform selector rejection, global-disable rejection, and the strict Gatekeeper boundary.

## Exceptions

Validate and compile the registry before policy evaluation:

```bash
python3 platform-policies/scripts/validate-exceptions.py \
  platform-policies/policy-exceptions.yaml \
  --output /tmp/goldenpath-policy-exceptions.json
```

Each active exception must have a stable ID, exact policy/resource scope, technical reason, owner email, approver, tracking issue, creation date, and expiry date. Kubernetes exceptions also require an exact namespace. Terraform selectors must be absolute resource addresses that include both resource type and logical resource name, such as `aws_s3_bucket.legacy_assets`; a bare resource type is not an exact scope. The validator rejects unknown policy IDs, duplicate scopes, expired entries, wildcard selectors, malformed entries, unsupported fields, and global policy-disable attempts.

The compiled JSON is the only exception data that should be passed to Conftest. Raw registry YAML must not be supplied directly because compilation is the fail-closed validation boundary. Conftest must evaluate through the `goldenpath.kubernetes` or `goldenpath.terraform` wrapper namespace so exact-scope filtering and audit warnings remain part of the enforcement path.

A matched exception suppresses only that policy's `deny` results for that exact resource and emits an audit-visible warning containing the exception ID. It does not silence unrelated warnings or other policy IDs.

### Admission boundary

Gatekeeper remains deliberately stricter than CI: it does **not** consume `policy-exceptions.yaml`. The registry is required to declare:

```yaml
enforcement:
  conftest: scoped-exceptions
  gatekeeper: strict
```

The validator rejects any other Gatekeeper mode. Therefore a Kubernetes exception can permit a repository/reference Conftest check for its exact scope, but it does not prove the workload can be admitted by a real cluster. Admission remediation or an independently reviewed change to the Gatekeeper constraint scope is still required.

Current admission overlap is explicit rather than assumed:

| Conftest policy ID | Gatekeeper admission control | Relationship |
|---|---|---|
| `kubernetes.images.immutable` | `K8sImmutableImages` / `immutable-images` | Overlapping immutable-image control; Gatekeeper remains independently strict. |
| `kubernetes.labels.required` | `K8sRequiredLabels` / `required-labels` | Overlapping required-label control; admission scope is defined by the constraint and may differ from Conftest resource coverage. |
| `kubernetes.resources.required` | `K8sContainerResources` / `container-limits` | Overlapping CPU/memory request and limit control; do not infer identical workload-kind coverage. |
| `kubernetes.security.context` | `K8sSecureContext` / `secure-context` | Overlapping non-root and privilege-escalation control; Gatekeeper does not inherit CI exceptions. |
| `kubernetes.workload.isolation` | `K8sPSPPrivilegedContainer` / `no-privileged` | Partial overlap only: privileged containers are admission-checked, while Conftest also blocks `hostNetwork`, `hostPID`, and `hostIPC`. |

This table documents control overlap, not semantic parity. In particular, no Gatekeeper constraint consumes the exception registry, and Conftest-only checks must never be represented as admission coverage.

## Gatekeeper

Gatekeeper templates/constraints under `gitops-config/policies/` provide admission-time defense in depth for selected Kubernetes controls. CI remains responsible for the full policy bundle. Admission resources must be validated together with their `ConstraintTemplate`; a constraint without its template is an invalid baseline.

Static `excludedNamespaces` in Gatekeeper constraints are part of the admission policy's declared base scope. They are not generated from the exception registry and must not be presented as temporary policy exceptions.

## Rollout

For a new blocking rule on an existing estate:

1. inventory violations;
2. add positive/negative fixtures;
3. run advisory/audit evaluation;
4. remediate the paved road and existing workloads;
5. enable blocking enforcement;
6. monitor denial volume and rollback criteria;
7. use a governed exception only when remediation cannot meet the required deadline.
