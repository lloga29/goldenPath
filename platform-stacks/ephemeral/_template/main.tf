# Template para Entornos Efímeros (PR Preview)
# Estos entornos se crean automáticamente para cada PR

terraform {
  required_version = ">= 1.5.0, < 2.0.0"

  backend "s3" {
    # Configurado dinámicamente por CI/CD
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

variable "pr_number" {
  description = "Número del Pull Request"
  type        = string
}

variable "branch_name" {
  description = "Nombre de la rama"
  type        = string
}

variable "ttl_hours" {
  description = "Tiempo de vida en horas"
  type        = number
  default     = 24
}

# ============================================
# LOCALS
# ============================================
locals {
  environment = "ephemeral"
  name_prefix = "pr-${var.pr_number}"

  common_tags = {
    Environment   = local.environment
    ManagedBy     = "terraform"
    PRNumber      = var.pr_number
    Branch        = var.branch_name
    TTL           = var.ttl_hours
    ExpiresAt     = timeadd(timestamp(), "${var.ttl_hours}h")
    AutoCleanup   = "true"
  }
}

# ============================================
# RECURSOS EFÍMEROS
# ============================================
# Crear solo los recursos mínimos necesarios para testing

# ============================================
# OUTPUTS
# ============================================
output "environment_name" {
  value = local.name_prefix
}

output "expires_at" {
  value = local.common_tags.ExpiresAt
}
