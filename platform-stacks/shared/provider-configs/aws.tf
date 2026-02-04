# Configuración de provider AWS
# Copiar y ajustar según el entorno

terraform {
  required_version = ">= 1.5.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0, < 6.0.0"
    }
  }
}

# Provider principal
provider "aws" {
  region = var.aws_region

  # Tags por defecto para todos los recursos
  default_tags {
    tags = {
      ManagedBy   = "terraform"
      Environment = var.environment
      Project     = var.project
      Client      = var.client
    }
  }

  # Asumir rol (para cross-account)
  # assume_role {
  #   role_arn = "arn:aws:iam::${var.target_account_id}:role/TerraformRole"
  # }
}

# Provider secundario (para recursos globales como CloudFront)
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

# Variables requeridas
variable "aws_region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Entorno"
  type        = string
}

variable "project" {
  description = "Nombre del proyecto"
  type        = string
}

variable "client" {
  description = "Nombre del cliente"
  type        = string
}
