# Blocking Policy Regression Coverage

GoldenPath uses two complementary Conftest fixture layers:

1. aggregate/provider fixtures exercise realistic paved-road and invalid plans across Kubernetes, AWS, Azure, and Google Cloud;
2. dedicated policy-ID fixtures isolate each blocking wrapper policy so one unrelated denial cannot hide the disappearance of another semantic control.

All dedicated cases are evaluated through `goldenpath.kubernetes` or `goldenpath.terraform` with the validated baseline exception registry loaded. They do not query implementation packages directly and therefore preserve the same exception boundary as supported CI enforcement.

## Policy-ID isolation matrix

| Policy ID | Dedicated negative fixture | Expected target denial |
|---|---|---|
| `kubernetes.images.immutable` | `tests/kubernetes/policy-id/image-immutable.yaml` | immutable tag or SHA-256 digest required |
| `kubernetes.labels.required` | `tests/kubernetes/policy-id/labels-required.yaml` | required labels missing |
| `kubernetes.resources.required` | `tests/kubernetes/policy-id/resources-required.yaml` | CPU limit missing |
| `kubernetes.security.context` | `tests/kubernetes/policy-id/security-context.yaml` | `allowPrivilegeEscalation=false` required |
| `kubernetes.workload.isolation` | `tests/kubernetes/policy-id/workload-isolation.yaml` | `hostNetwork` forbidden |
| `terraform.public_access` | `tests/terraform/policy-id/public-access-plan.json` | public sensitive-port ingress rejected |
| `terraform.iam.no_wildcards` | `tests/terraform/policy-id/iam-no-wildcards-plan.json` | wildcard `Action` rejected |
| `terraform.identity.least_privilege` | `tests/terraform/policy-id/identity-least-privilege-plan.json` | `AdministratorAccess` attachment rejected |
| `terraform.encryption.required` | `tests/terraform/policy-id/encryption-required-plan.json` | unencrypted EBS volume rejected |
| `terraform.tags.required` | `tests/terraform/policy-id/tags-required-plan.json` | required AWS tag missing |

The test harness requires each fixture to fail and also requires its policy-specific message fragment to appear. A failure caused only by another policy is therefore insufficient to satisfy the case.

## Coverage boundary

This matrix proves isolation of the ten public blocking **policy IDs** exposed by the supported wrappers. It is not a claim that every internal Rego branch, resource subtype, provider API variant, or Gatekeeper admission path has an individual fixture.

Internal/provider branches continue to receive complementary coverage from the aggregate AWS, Azure, and Google Cloud invalid plans and from exception-contract fixtures. When a new blocking policy ID is added to either wrapper, it must receive a dedicated negative fixture and target-message assertion in the same change. When a high-risk internal branch is added, add a branch-specific regression case where aggregate coverage would otherwise be ambiguous.

Gatekeeper remains a separate admission boundary. Passing these Conftest fixtures is repository/reference evidence and does not establish runtime admission or production validation.
