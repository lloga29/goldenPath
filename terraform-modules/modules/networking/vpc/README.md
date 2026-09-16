# VPC / Virtual Network Reference Module

A multi-provider Terraform reference module for network creation across AWS, Azure, and Google Cloud.

## Capabilities

- AWS VPC, subnets, Internet Gateway, and optional VPC Flow Logs.
- Azure Virtual Network, subnets, and a reference Network Security Group.
- Google Cloud custom VPC, subnets with flow logging, and a Cloud Router reference.
- Common environment/ownership metadata.

## Production limitations

This module demonstrates a shared interface, but it is not a complete production network foundation. Notable gaps include provider-specific NAT/egress design, route tables, private endpoints, firewalls/security rules, IPAM, DNS design, Azure provider-native flow-log integration, production deletion protection, and explicit provider-specific validation. Treat it as a reference to evolve, not a drop-in secure landing zone.

The previous Azure Network Watcher flow-log placeholder was intentionally removed because it contained an invalid empty Storage Account resource ID and did not represent an executable deployment contract. Azure logging must be implemented by the consuming platform using a supported provider-native design.

## AWS example

```hcl
module "vpc" {
  source = "git::https://github.com/example/platform-terraform-modules.git//modules/networking/vpc?ref=v1.0.0"

  name           = "payments-prod"
  cidr_block     = "10.0.0.0/16"
  environment    = "prod"
  cloud_provider = "aws"

  availability_zones   = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnet_cidrs  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  tags = {
    Team       = "platform"
    CostCenter = "cc-001"
    Owner      = "platform@example.com"
  }
}
```

## Azure example

```hcl
module "vnet" {
  source = "git::https://github.com/example/platform-terraform-modules.git//modules/networking/vpc?ref=v1.0.0"

  name                = "payments-prod"
  cidr_block          = "10.0.0.0/16"
  environment         = "prod"
  cloud_provider      = "azure"
  location            = "eastus"
  resource_group_name = "rg-networking"

  private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnet_cidrs  = ["10.0.101.0/24", "10.0.102.0/24"]

  tags = {
    Team       = "platform"
    CostCenter = "cc-001"
  }
}
```

## Google Cloud example

```hcl
module "vpc" {
  source = "git::https://github.com/example/platform-terraform-modules.git//modules/networking/vpc?ref=v1.0.0"

  name           = "payments-prod"
  cidr_block     = "10.0.0.0/16"
  environment    = "prod"
  cloud_provider = "gcp"
  project_id     = "example-platform-prod"

  availability_zones   = ["us-central1"]
  private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnet_cidrs  = ["10.0.101.0/24"]

  tags = {
    Team       = "platform"
    CostCenter = "cc-001"
  }
}
```

## Testing

```bash
terraform init -backend=false
terraform validate
terraform test
```

Use provider integration tests before production adoption.
