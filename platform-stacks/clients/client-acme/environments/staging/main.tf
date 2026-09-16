# ACME staging environment reference stack.

terraform {
  required_version = ">= 1.5.0, < 2.0.0"

  backend "s3" {
    bucket         = "client-acme-terraform-state"
    key            = "environments/staging/terraform.tfstate"
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
  environment = "staging"
  client      = "acme"

  common_tags = {
    Environment = local.environment
    Client      = local.client
    ManagedBy   = "terraform"
    CostCenter  = "cc-acme-001"
    Team        = "platform"
  }

  vpc_id             = data.terraform_remote_state.networking.outputs.vpc_ids.staging
  private_subnet_ids = data.terraform_remote_state.networking.outputs.private_subnet_ids.staging
  public_subnet_ids  = data.terraform_remote_state.networking.outputs.public_subnet_ids.staging
}

# Add production-like application resources only through reviewed, version-pinned modules.

output "environment" {
  description = "Environment name."
  value       = local.environment
}

output "vpc_id" {
  description = "Staging VPC ID."
  value       = local.vpc_id
}

output "private_subnet_ids" {
  description = "Staging private subnet IDs."
  value       = local.private_subnet_ids
}
