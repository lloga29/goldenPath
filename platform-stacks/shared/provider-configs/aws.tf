# AWS provider configuration reference. Copy and adapt it in an actual stack.

terraform {
  required_version = ">= 1.5.0, < 2.0.0"

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
    tags = {
      ManagedBy   = "terraform"
      Environment = var.environment
      Project     = var.project
      Client      = var.client
    }
  }

  # Cross-account role assumption belongs here when required by the target account design.
  # assume_role {
  #   role_arn = "arn:aws:iam::<account-id>:role/<scoped-terraform-role>"
  # }
}

# Secondary provider for AWS resources that must be managed from us-east-1.
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = {
      ManagedBy   = "terraform"
      Environment = var.environment
      Project     = var.project
      Client      = var.client
    }
  }
}

variable "aws_region" {
  description = "AWS region."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment."
  type        = string
}

variable "project" {
  description = "Project identifier."
  type        = string
}

variable "client" {
  description = "Client identifier."
  type        = string
}
