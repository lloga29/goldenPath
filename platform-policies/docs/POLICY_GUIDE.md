# Policy Guide - Golden Path

This guide describes the current policy-as-code baseline and how to operate it safely.

## Terraform controls

The executable Terraform policy bundle is currently AWS-specific. Multi-provider policy parity is tracked in issue #15.

### Public access

- Reject public S3 ACLs.
- Require a matching S3 public-access-block companion resource and all four protection flags.
- Reject public sensitive-port ingress for supported AWS security-group representations.
- Reject publicly accessible RDS and Redshift instances/clusters.

### Encryption

- Require EBS encryption.
- Require RDS instance/cluster storage encryption.
- Require a matching S3 server-side-encryption companion resource.
- Require ElastiCache at-rest and in-transit encryption.

### Required metadata

Supported taggable resources must carry `Environment`, `Team`, `CostCenter`, and `Owner`. Environment values are constrained to `dev`, `staging`, `prod`, or `ephemeral`.

### IAM wildcard restrictions

Managed and inline IAM policy resources reject `Action: "*"` and reject sensitive IAM/KMS/secret-access actions against `Resource: "*"`. `NotAction` and `NotResource` generate review warnings.

## Kubernetes controls

The policy bundle evaluates the rendered desired state and checks:

- explicit immutable image tags or SHA-256 digests;
- required application/ownership/environment labels;
- CPU and memory requests and limits;
- non-root execution;
- `allowPrivilegeEscalation=false`;
- privileged container and host namespace restrictions;
- advisory read-only-root-filesystem, dropped-capability, and probe guidance.

## Positive and negative fixtures

Every blocking policy change must preserve a passing fixture and at least one deliberately failing fixture. Run:

```bash
./platform-policies/scripts/test-policies.sh
```

A test suite that only proves invalid input fails is insufficient; it must also prove the paved-road input remains valid.

## Exceptions

The exception registry is validated independently:

```bash
python3 platform-policies/scripts/validate-exceptions.py \
  platform-policies/policy-exceptions.yaml
```

Each active exception must have a stable ID, policy/resource scope, technical reason, owner email, approver, tracking issue, creation date, and expiry date. Expired exceptions fail validation. The registry cannot globally disable policies.

The registry is **not yet consumed as a bypass** by Conftest/Gatekeeper. Issue #14 tracks that implementation so the bypass semantics can be designed explicitly and audited.

## Gatekeeper

Gatekeeper templates/constraints under `gitops-config/policies/` provide admission-time defense in depth for selected Kubernetes controls. CI remains responsible for the full policy bundle. Admission resources must be validated together with their `ConstraintTemplate`; a constraint without its template is an invalid baseline.

## Rollout

For a new blocking rule on an existing estate:

1. inventory violations;
2. add positive/negative fixtures;
3. run advisory/audit evaluation;
4. remediate the paved road and existing workloads;
5. enable blocking enforcement;
6. monitor denial volume and rollback criteria;
7. use a governed exception only when remediation cannot meet the required deadline.
