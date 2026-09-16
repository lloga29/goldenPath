# ACME production environment reference stack.
# Production controls must be implemented and validated before this example is used for real workloads.

terraform {
  required_version = ">= 1.5.0, < 2.0.0"

  backend "s3" {
    bucket         = "client-acme-terraform-state"
    key            = "environments/prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "client-acme-terraform-locks"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0, < 6.0.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

variable "aws_region" {
  description = "AWS region."
  type        = string
  default     = "us-east-1"
}

data "terraform_remote_state" "networking" {
  backend = "s3"

  config = {
    bucket = "client-acme-terraform-state"
    key    = "foundation/networking/terraform.tfstate"
    region = "us-east-1"
  }
}

locals {
  environment = "prod"
  client      = "acme"

  common_tags = {
    Environment = local.environment
    Client      = local.client
    ManagedBy   = "terraform"
    CostCenter  = "cc-acme-001"
    Team        = "platform"
    Criticality = "high"
    Compliance  = "pci-dss"
  }

  vpc_id             = data.terraform_remote_state.networking.outputs.vpc_ids.prod
  private_subnet_ids = data.terraform_remote_state.networking.outputs.private_subnet_ids.prod
  public_subnet_ids  = data.terraform_remote_state.networking.outputs.public_subnet_ids.prod
}

# Add highly available, deletion-protected production resources only through reviewed, version-pinned modules.

output "environment" {
  description = "Environment name."
  value       = local.environment
}

output "vpc_id" {
  description = "Production VPC ID."
  value       = local.vpc_id
}

output "private_subnet_ids" {
  description = "Production private subnet IDs."
  value       = local.private_subnet_ids
}
