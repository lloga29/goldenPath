# Policy Guide - Golden Path

This guide describes the current policy-as-code baseline and how to operate it safely.

## Terraform controls

The executable Terraform policy bundle maps security/governance outcomes across AWS, Azure, and Google Cloud without pretending the providers are semantically identical. See [Terraform Provider Policy Coverage](TERRAFORM_PROVIDER_COVERAGE.md) for the full matrix and explicit non-parity boundaries.

### Public access

Policy ID: `terraform.public_access`.

- AWS: block public S3 ACLs, require secure S3 public-access-block companions, block public sensitive-port security-group ingress, and reject publicly accessible supported RDS/Redshift resources.
- Azure: require private Blob containers, disable public network access on Storage Accounts, and block public inbound sensitive-port NSG rules.
- Google Cloud: require Cloud Storage public-access prevention and block public sensitive-port firewall rules.

### Encryption

Policy ID: `terraform.encryption.required`.

AWS plan resources expose explicit encryption controls, so the bundle requires EBS, RDS, S3, and ElastiCache encryption where supported.

Azure Storage and Google Cloud Storage encrypt data at rest by provider guarantee. GoldenPath does not require Azure infrastructure/double encryption or Google Cloud CMEK merely to manufacture symmetry with AWS. Customer-managed keys, double encryption, HSM, and key-separation requirements belong to an explicit higher-assurance profile.

### Required metadata

Policy ID: `terraform.tags.required`.

Supported AWS/Azure resources require `Environment`, `Team`, `CostCenter`, and `Owner` tags. Supported Google Cloud resources require provider-native lowercase `environment`, `team`, `cost_center`, and `owner` labels. Environment values are constrained to `dev`, `staging`, `prod`, or `ephemeral`.

### Least-privilege identity

Policy ID: `terraform.identity.least_privilege`.

- AWS: direct attachment of AWS managed `AdministratorAccess` is blocked on supported attachment resources.
- Azure: `Owner`, `Contributor`, `User Access Administrator`, and `Role Based Access Control Administrator` are blocked at subscription/management-group scope.
- Google Cloud: project/folder/organization IAM bindings/members using `roles/owner` or `roles/editor` are blocked.

This policy maps broad identity grants; it does not claim that AWS IAM, Azure RBAC, and Google Cloud IAM role models are interchangeable.

### AWS IAM wildcard restrictions

Policy ID: `terraform.iam.no_wildcards`.

Supported AWS managed and inline IAM policy resources reject `Action: "*"` and reject sensitive IAM/KMS/secret-access actions against `Resource: "*"`. `NotAction` and `NotResource` generate review warnings.

This policy is intentionally AWS-specific. Azure/GCP least-privilege behavior is handled by `terraform.identity.least_privilege`.

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

Terraform fixtures cover AWS, Azure, and Google Cloud paved-road and deliberately invalid plans. The suite also proves exact exception matches, identity-policy exception behavior, same-resource policy isolation, resource and namespace isolation, audit-visible exception IDs, expired exceptions, unknown policy IDs, malformed entries, wildcard rejection, type-only Terraform selector rejection, global-disable rejection, and the strict Gatekeeper boundary.

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
