# Entorno Staging para ACME
# Infraestructura de pre-producción

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

# ============================================
# RECURSOS DE STAGING
# ============================================
# Staging tiene configuración similar a producción pero con recursos más pequeños

# ============================================
# OUTPUTS
# ============================================
output "environment" {
  value = local.environment
}

output "vpc_id" {
  value = local.vpc_id
}

output "private_subnet_ids" {
  value = local.private_subnet_ids
}
