# Terraform Modules - Golden Path

Reusable Terraform modules and infrastructure patterns for the Golden Path reference platform.

## Current implemented baseline

```text
modules/
├── networking/vpc/          # Multi-provider network/VPC reference
├── security/iam-role/       # AWS IAM role reference
├── security/github-oidc/    # AWS GitHub Actions OIDC federation reference
└── storage/object-storage/  # AWS/Azure/GCP object storage reference
patterns/
└── three-tier-app/          # Composite reference pattern
```

Other category directories may exist as placeholders from the original design. A directory name is not evidence that a module is implemented or supported.

## Usage

Consumers should pin immutable versions when these modules are published independently:

```hcl
module "vpc" {
  source = "git::https://github.com/example/platform-terraform-modules.git//modules/networking/vpc?ref=v1.0.0"

  name           = "payments-prod"
  cidr_block     = "10.20.0.0/16"
  environment    = "prod"
  cloud_provider = "aws"

  tags = {
    Team       = "platform"
    CostCenter = "cc-001"
  }
}
```

## Standards

Each production module should provide typed inputs, useful validation, secure defaults, deterministic outputs, examples, tests, generated reference documentation, ownership, and a semantic release strategy.

See [Module Standards](docs/MODULE_STANDARDS.md) and [Contributing](docs/CONTRIBUTING.md).

## Cloud-provider note

Some modules expose a multi-provider interface for learning/reference purposes. AWS, Azure, and GCP are not operationally identical. Production modules should preserve provider-specific capabilities and security controls rather than force false feature parity.

## Workflow note

The workflows under `terraform-modules/.github/workflows/` are blueprints in this consolidated repository. They execute only when moved to the root of a real Terraform-modules repository or represented by equivalent root workflows here.

## License

Internal/reference use. Apply your organization's licensing policy before external distribution.
