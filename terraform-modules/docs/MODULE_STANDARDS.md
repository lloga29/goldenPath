# Terraform Module Standards

## Required structure

```text
module-name/
├── main.tf
├── variables.tf
├── outputs.tf
├── versions.tf
├── README.md
└── tests/          # Strongly recommended; required for critical reusable modules
```

## Inputs

Inputs must use descriptive snake_case names and explicit types. Use validation for values whose invalidity can be determined at plan time.

```hcl
variable "environment" {
  description = "Deployment environment."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod", "ephemeral"], var.environment)
    error_message = "environment must be one of: dev, staging, prod, ephemeral."
  }
}
```

Do not expose a generic variable merely to bypass a security control. If a less-secure behavior is required, make the risk explicit and document the exception path.

## Outputs

Outputs require useful descriptions. Mark sensitive outputs as `sensitive = true`. Avoid outputting secret material when consumers can reference a resource or secret identifier instead.

## Provider and Terraform versions

`versions.tf` must declare the supported Terraform and provider constraints. Avoid unbounded provider versions for production modules. Test upgrade compatibility before widening constraints.

## Secure defaults

Where the provider semantics support them, default to encryption, private access, logging, and versioning. Defaults must be documented and verified by tests rather than assumed.

## Multi-provider modules

A common interface may be useful for simple primitives, but provider-specific security and operational capabilities must remain accessible. Do not claim feature parity where none exists.

## Documentation

Module documentation should include purpose, security/operational assumptions, basic and advanced examples, generated input/output/provider requirements, compatibility notes, and known provider-specific differences.

## Testing

Use Terraform-native tests for deterministic plan-time behavior. Use integration tests for behavior that can only be validated against real provider APIs. Keep test accounts isolated and ensure cleanup is reliable.
