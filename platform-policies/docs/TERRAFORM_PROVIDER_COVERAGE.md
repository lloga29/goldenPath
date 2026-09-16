# Terraform Provider Policy Coverage

This document defines the executable policy coverage for the AWS, Azure, and Google Cloud Terraform references. "Parity" means that each provider has an explicitly mapped security/governance outcome where the provider exposes a comparable control. It does **not** mean that provider APIs or security models are identical.

## Coverage matrix

| Control | Policy ID | AWS | Azure | Google Cloud | Important non-parity |
|---|---|---|---|---|---|
| Public exposure | `terraform.public_access` | S3 public ACLs/public-access-block, public sensitive-port security-group ingress, publicly accessible RDS/Redshift | Blob containers must be private; Storage Accounts must disable public network access; NSG rules must not expose sensitive inbound ports to public sources | Cloud Storage must enforce public-access prevention; firewall rules must not expose sensitive TCP ports to public CIDRs | Resource types and provider primitives differ. The policy maps outcomes rather than field names. |
| Encryption at rest | `terraform.encryption.required` | Explicit plan checks for EBS, RDS, S3 encryption companion resources, and ElastiCache at-rest/in-transit encryption | Azure Storage encryption at rest is provider-managed and always enabled; the current object-storage reference consumes an existing Storage Account, so customer-managed keys/double encryption remain an external requirement | Cloud Storage is encrypted at rest by default with Google-managed keys; CMEK is an additional requirement, not the baseline equivalent of AWS's explicit S3 companion resource | Customer-managed keys and double encryption are higher-assurance/provider-specific controls and are not forced as fake parity. |
| Ownership/environment/cost metadata | `terraform.tags.required` | Required `Environment`, `Team`, `CostCenter`, `Owner` tags on supported taggable types | Required `Environment`, `Team`, `CostCenter`, `Owner` tags on supported taggable types | Required lowercase `environment`, `team`, `cost_center`, `owner` labels on supported labelable types | Some Azure/GCP resource types do not expose equivalent metadata fields. GCP label values are normalized identifiers, so `owner` is not required to preserve email punctuation. |
| Least-privilege identity | `terraform.identity.least_privilege` | Blocks direct attachment of AWS managed `AdministratorAccess` | Blocks `Owner`, `Contributor`, `User Access Administrator`, and `Role Based Access Control Administrator` assignments at subscription or management-group scope | Blocks `roles/owner` and `roles/editor` on project/folder/organization IAM binding/member resources | Each cloud's identity hierarchy is different. The rule targets documented broad grants rather than pretending roles are interchangeable. |
| AWS IAM wildcard policy content | `terraform.iam.no_wildcards` | Blocks `Action: "*"` and sensitive actions against `Resource: "*"` in supported IAM policy documents | Not applicable to Azure RBAC role assignments | Not applicable to Google Cloud predefined/basic role bindings | This remains intentionally AWS-specific; Azure/GCP least-privilege behavior is covered by `terraform.identity.least_privilege`. |

## Public-access mapping

### AWS

The existing controls remain unchanged: S3 buckets must avoid public ACLs and have a secure `aws_s3_bucket_public_access_block`; sensitive security-group ingress cannot be public; supported RDS and Redshift resources cannot be publicly accessible.

### Azure

The executable bundle covers:

- `azurerm_storage_container`: `container_access_type` must be `private`;
- `azurerm_storage_account`: `public_network_access_enabled` must be `false`;
- `azurerm_network_security_rule`: inbound `Allow` rules from public sources may not expose the shared sensitive-port set.

The object-storage module creates a container inside an existing Storage Account. Therefore account-level networking remains a responsibility of the consuming stack even though the policy bundle can evaluate an `azurerm_storage_account` when it appears in the plan.

### Google Cloud

The executable bundle covers:

- `google_storage_bucket`: `public_access_prevention` must be `enforced`;
- `google_compute_firewall`: public source ranges may not expose the shared sensitive TCP-port set.

Uniform bucket-level access in the object-storage module is a secure module default, while public-access prevention is the blocking policy outcome.

## Encryption mapping

Encryption cannot be represented honestly as one boolean across providers.

AWS resources in the supported set expose explicit configuration that can be absent or disabled, so Conftest blocks missing/disabled encryption.

Azure Storage encrypts data at rest by default and does not expose a supported "disable storage encryption" state that would be equivalent to an unencrypted AWS disk/bucket. Google Cloud Storage likewise encrypts data at rest by default. Requiring infrastructure/double encryption or CMEK merely to make the matrix look symmetric would silently change the security baseline.

When a workload requires customer-managed keys, double encryption, HSM-backed keys, rotation guarantees, or key-separation controls, those requirements must be modeled as an explicit higher-assurance control rather than inferred from this baseline.

## Metadata mapping

AWS and Azure use tags with GoldenPath's canonical keys:

- `Environment`
- `Team`
- `CostCenter`
- `Owner`

Google Cloud uses provider-native lowercase labels:

- `environment`
- `team`
- `cost_center`
- `owner`

The object-storage reference normalizes these GCP label values instead of sending AWS/Azure-style keys to the Google provider. An absent owner remains absent/empty so policy evaluation fails closed rather than inventing ownership.

## Identity mapping

`terraform.identity.least_privilege` is intentionally separate from `terraform.iam.no_wildcards`.

For AWS, the provider-neutral least-privilege rule rejects direct attachment of the AWS managed `AdministratorAccess` policy. The existing AWS policy-document rule continues to handle wildcard actions/resources.

For Azure, privileged built-in roles are rejected when assigned at subscription or management-group scope. A resource-scoped assignment of a purpose-built/read-only role is the paved-road shape.

For Google Cloud, project/folder/organization bindings or members using the broad basic `roles/owner` or `roles/editor` roles are rejected. Prefer narrowly scoped predefined or custom roles.

## Fixture contract

The policy suite includes provider-specific positive and negative Terraform-plan fixtures:

- `tests/terraform/valid-plan.json` / `invalid-plan.json` — AWS;
- `tests/terraform/azure-valid-plan.json` / `azure-invalid-plan.json` — Azure;
- `tests/terraform/gcp-valid-plan.json` / `gcp-invalid-plan.json` — Google Cloud.

The suite also proves an exact-address exception for `terraform.identity.least_privilege`. All Terraform policy evaluation uses the exception-aware `goldenpath.terraform` wrapper.

## CI routing

Changes under `terraform-modules/` or `platform-stacks/` activate both the Terraform validation domain and the policy validation domain. This prevents a provider module from changing without re-running the multi-provider policy fixtures.

A change to the root validation scripts/workflow still activates every domain so changes to CI validate themselves.

## Evidence boundary

These checks are repository/reference evidence derived from Terraform plan fixtures and static desired state. They do not prove live cloud account configuration, organization policies, inherited IAM, effective firewall reachability, key-management state, or runtime/production compliance.

Provider-specific runtime claims require evidence from the real AWS, Azure, or Google Cloud target.
