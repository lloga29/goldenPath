# Entorno Development para ACME
# Infraestructura de aplicaciones en dev

terraform {
  required_version = ">= 1.5.0, < 2.0.0"

  backend "s3" {
    bucket         = "client-acme-terraform-state"
    key            = "environments/dev/terraform.tfstate"
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

# ============================================
# VARIABLES
# ============================================
variable "aws_region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-1"
}

# ============================================
# DATA SOURCES
# ============================================
data "terraform_remote_state" "networking" {
  backend = "s3"

  config = {
    bucket = "client-acme-terraform-state"
    key    = "foundation/networking/terraform.tfstate"
    region = "us-east-1"
  }
}

# ============================================
# LOCALS
# ============================================
locals {
  environment = "dev"
  client      = "acme"

  common_tags = {
    Environment = local.environment
    Client      = local.client
    ManagedBy   = "terraform"
    CostCenter  = "cc-acme-001"
    Team        = "platform"
  }

  vpc_id             = data.terraform_remote_state.networking.outputs.vpc_ids.dev
  private_subnet_ids = data.terraform_remote_state.networking.outputs.private_subnet_ids.dev
  public_subnet_ids  = data.terraform_remote_state.networking.outputs.public_subnet_ids.dev
}

# ============================================
# EKS CLUSTER (Placeholder)
# ============================================
# module "eks" {
#   source = "git::https://github.com/org/terraform-modules.git//modules/compute/kubernetes-cluster?ref=v1.0.0"
#
#   name           = "${local.client}-${local.environment}"
#   environment    = local.environment
#   cloud_provider = "aws"
#
#   vpc_id     = local.vpc_id
#   subnet_ids = local.private_subnet_ids
#
#   tags = local.common_tags
# }

# ============================================
# OUTPUTS
# ============================================
output "environment" {
  description = "Entorno"
  value       = local.environment
}

output "vpc_id" {
  description = "ID de la VPC"
  value       = local.vpc_id
}

output "private_subnet_ids" {
  description = "IDs de subnets privadas"
  value       = local.private_subnet_ids
}
