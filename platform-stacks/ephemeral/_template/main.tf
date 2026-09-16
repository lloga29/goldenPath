# Pull-request ephemeral environment reference template.
# CI/CD is responsible for supplying a unique backend and destroying the stack before or at TTL expiry.

terraform {
  required_version = ">= 1.5.0, < 2.0.0"

  backend "s3" {
    # Configured dynamically by the ephemeral-environment workflow.
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

variable "pr_number" {
  description = "Pull request number."
  type        = string
}

variable "branch_name" {
  description = "Source branch name."
  type        = string
}

variable "ttl_hours" {
  description = "Requested environment lifetime in hours."
  type        = number
  default     = 24
}

locals {
  environment = "ephemeral"
  name_prefix = "pr-${var.pr_number}"

  common_tags = {
    Environment = local.environment
    ManagedBy   = "terraform"
    PRNumber    = var.pr_number
    Branch      = var.branch_name
    TTL         = var.ttl_hours
    ExpiresAt   = timeadd(timestamp(), "${var.ttl_hours}h")
    AutoCleanup = "true"
  }
}

# Add only the minimum isolated resources required by the preview workload.
# A separate cleanup controller/workflow is required; tags alone do not enforce TTL deletion.

output "environment_name" {
  value = local.name_prefix
}

output "expires_at" {
  value = local.common_tags.ExpiresAt
}
