# Networking Foundation para ACME
# VPC y subnets base para todos los entornos

terraform {
  required_version = ">= 1.5.0, < 2.0.0"

  backend "s3" {
    bucket         = "client-acme-terraform-state"
    key            = "foundation/networking/terraform.tfstate"
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
# LOCALS
# ============================================
locals {
  client = "acme"

  common_tags = {
    Client      = local.client
    ManagedBy   = "terraform"
    Project     = "foundation"
    Component   = "networking"
    CostCenter  = "cc-acme-001"
    Team        = "platform"
  }

  # CIDRs por entorno
  vpc_cidrs = {
    dev     = "10.10.0.0/16"
    staging = "10.20.0.0/16"
    prod    = "10.30.0.0/16"
  }

  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

# ============================================
# VPC POR ENTORNO
# ============================================

# VPC Development
module "vpc_dev" {
  source = "git::https://github.com/org/terraform-modules.git//modules/networking/vpc?ref=v1.0.0"

  name           = "${local.client}-dev"
  cidr_block     = local.vpc_cidrs.dev
  environment    = "dev"
  cloud_provider = "aws"

  availability_zones   = local.availability_zones
  private_subnet_cidrs = [for i in range(3) : cidrsubnet(local.vpc_cidrs.dev, 8, i + 1)]
  public_subnet_cidrs  = [for i in range(3) : cidrsubnet(local.vpc_cidrs.dev, 8, i + 101)]

  enable_flow_logs = true

  tags = merge(local.common_tags, {
    Environment = "dev"
  })
}

# VPC Staging
module "vpc_staging" {
  source = "git::https://github.com/org/terraform-modules.git//modules/networking/vpc?ref=v1.0.0"

  name           = "${local.client}-staging"
  cidr_block     = local.vpc_cidrs.staging
  environment    = "staging"
  cloud_provider = "aws"

  availability_zones   = local.availability_zones
  private_subnet_cidrs = [for i in range(3) : cidrsubnet(local.vpc_cidrs.staging, 8, i + 1)]
  public_subnet_cidrs  = [for i in range(3) : cidrsubnet(local.vpc_cidrs.staging, 8, i + 101)]

  enable_flow_logs = true

  tags = merge(local.common_tags, {
    Environment = "staging"
  })
}

# VPC Production
module "vpc_prod" {
  source = "git::https://github.com/org/terraform-modules.git//modules/networking/vpc?ref=v1.0.0"

  name           = "${local.client}-prod"
  cidr_block     = local.vpc_cidrs.prod
  environment    = "prod"
  cloud_provider = "aws"

  availability_zones   = local.availability_zones
  private_subnet_cidrs = [for i in range(3) : cidrsubnet(local.vpc_cidrs.prod, 8, i + 1)]
  public_subnet_cidrs  = [for i in range(3) : cidrsubnet(local.vpc_cidrs.prod, 8, i + 101)]

  enable_flow_logs = true

  tags = merge(local.common_tags, {
    Environment = "prod"
  })
}

# ============================================
# OUTPUTS
# ============================================
output "vpc_ids" {
  description = "IDs de las VPCs por entorno"
  value = {
    dev     = module.vpc_dev.vpc_id
    staging = module.vpc_staging.vpc_id
    prod    = module.vpc_prod.vpc_id
  }
}

output "private_subnet_ids" {
  description = "IDs de subnets privadas por entorno"
  value = {
    dev     = module.vpc_dev.private_subnet_ids
    staging = module.vpc_staging.private_subnet_ids
    prod    = module.vpc_prod.private_subnet_ids
  }
}

output "public_subnet_ids" {
  description = "IDs de subnets públicas por entorno"
  value = {
    dev     = module.vpc_dev.public_subnet_ids
    staging = module.vpc_staging.public_subnet_ids
    prod    = module.vpc_prod.public_subnet_ids
  }
}
