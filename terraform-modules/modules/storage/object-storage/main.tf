# Módulo Object Storage Cloud-Agnostic
# Soporta S3 (AWS), Blob Storage (Azure), GCS (GCP)

terraform {
  required_version = ">= 1.5.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0, < 6.0.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0.0, < 4.0.0"
    }
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0.0, < 6.0.0"
    }
  }
}

# ============================================
# VARIABLES
# ============================================
variable "name" {
  description = "Nombre del bucket/container"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", var.name))
    error_message = "El nombre debe ser 3-63 caracteres, lowercase alfanumérico con guiones."
  }
}

variable "environment" {
  description = "Entorno"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod", "ephemeral"], var.environment)
    error_message = "El entorno debe ser uno de: dev, staging, prod, ephemeral."
  }
}

variable "cloud_provider" {
  description = "Proveedor cloud (aws, azure, gcp)"
  type        = string

  validation {
    condition     = contains(["aws", "azure", "gcp"], var.cloud_provider)
    error_message = "El proveedor debe ser uno de: aws, azure, gcp."
  }
}

variable "versioning_enabled" {
  description = "Habilitar versionamiento"
  type        = bool
  default     = true  # Seguro por defecto
}

variable "encryption_enabled" {
  description = "Habilitar encryption at rest"
  type        = bool
  default     = true  # Seguro por defecto
}

variable "public_access_blocked" {
  description = "Bloquear acceso público"
  type        = bool
  default     = true  # Seguro por defecto
}

variable "lifecycle_rules" {
  description = "Reglas de lifecycle para el bucket"
  type = list(object({
    id                       = string
    enabled                  = bool
    prefix                   = string
    expiration_days          = number
    transition_days          = number
    transition_storage_class = string
  }))
  default = []
}

# Variables específicas Azure
variable "resource_group_name" {
  description = "Nombre del Resource Group (Azure)"
  type        = string
  default     = ""
}

variable "storage_account_name" {
  description = "Nombre de la Storage Account (Azure)"
  type        = string
  default     = ""
}

# Variables específicas GCP
variable "project_id" {
  description = "ID del proyecto (GCP)"
  type        = string
  default     = ""
}

variable "location" {
  description = "Ubicación/Región"
  type        = string
  default     = "us-east-1"
}

variable "tags" {
  description = "Tags a aplicar"
  type        = map(string)
  default     = {}

  validation {
    condition     = contains(keys(var.tags), "Team") && contains(keys(var.tags), "CostCenter")
    error_message = "Los tags deben incluir 'Team' y 'CostCenter'."
  }
}

# ============================================
# LOCALS
# ============================================
locals {
  common_tags = merge(
    var.tags,
    {
      Module      = "storage/object-storage"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  )
}

# ============================================
# AWS S3 BUCKET
# ============================================
resource "aws_s3_bucket" "this" {
  count = var.cloud_provider == "aws" ? 1 : 0

  bucket = var.name

  tags = local.common_tags

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_s3_bucket_versioning" "this" {
  count = var.cloud_provider == "aws" ? 1 : 0

  bucket = aws_s3_bucket.this[0].id

  versioning_configuration {
    status = var.versioning_enabled ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  count = var.cloud_provider == "aws" && var.encryption_enabled ? 1 : 0

  bucket = aws_s3_bucket.this[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  count = var.cloud_provider == "aws" ? 1 : 0

  bucket = aws_s3_bucket.this[0].id

  block_public_acls       = var.public_access_blocked
  block_public_policy     = var.public_access_blocked
  ignore_public_acls      = var.public_access_blocked
  restrict_public_buckets = var.public_access_blocked
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count = var.cloud_provider == "aws" && length(var.lifecycle_rules) > 0 ? 1 : 0

  bucket = aws_s3_bucket.this[0].id

  dynamic "rule" {
    for_each = var.lifecycle_rules

    content {
      id     = rule.value.id
      status = rule.value.enabled ? "Enabled" : "Disabled"

      filter {
        prefix = rule.value.prefix
      }

      expiration {
        days = rule.value.expiration_days
      }

      transition {
        days          = rule.value.transition_days
        storage_class = rule.value.transition_storage_class
      }
    }
  }
}

# ============================================
# AZURE BLOB CONTAINER
# ============================================
resource "azurerm_storage_container" "this" {
  count = var.cloud_provider == "azure" ? 1 : 0

  name                  = var.name
  storage_account_name  = var.storage_account_name
  container_access_type = var.public_access_blocked ? "private" : "blob"
}

# ============================================
# GCP CLOUD STORAGE
# ============================================
resource "google_storage_bucket" "this" {
  count = var.cloud_provider == "gcp" ? 1 : 0

  name          = var.name
  project       = var.project_id
  location      = var.location
  force_destroy = var.environment != "prod"

  uniform_bucket_level_access = true

  versioning {
    enabled = var.versioning_enabled
  }

  encryption {
    default_kms_key_name = null  # Usa encryption por defecto de Google
  }

  public_access_prevention = var.public_access_blocked ? "enforced" : "inherited"

  dynamic "lifecycle_rule" {
    for_each = var.lifecycle_rules

    content {
      action {
        type          = lifecycle_rule.value.expiration_days > 0 ? "Delete" : "SetStorageClass"
        storage_class = lifecycle_rule.value.transition_storage_class
      }

      condition {
        age        = lifecycle_rule.value.expiration_days > 0 ? lifecycle_rule.value.expiration_days : lifecycle_rule.value.transition_days
        with_state = "LIVE"
      }
    }
  }

  labels = local.common_tags
}

# ============================================
# OUTPUTS
# ============================================
output "bucket_id" {
  description = "ID del bucket/container"
  value = coalesce(
    try(aws_s3_bucket.this[0].id, null),
    try(azurerm_storage_container.this[0].id, null),
    try(google_storage_bucket.this[0].id, null)
  )
}

output "bucket_arn" {
  description = "ARN del bucket (AWS)"
  value       = try(aws_s3_bucket.this[0].arn, null)
}

output "bucket_name" {
  description = "Nombre del bucket"
  value       = var.name
}

output "bucket_url" {
  description = "URL del bucket"
  value = coalesce(
    try("s3://${aws_s3_bucket.this[0].bucket}", null),
    try("https://${var.storage_account_name}.blob.core.windows.net/${azurerm_storage_container.this[0].name}", null),
    try("gs://${google_storage_bucket.this[0].name}", null)
  )
}

output "versioning_enabled" {
  description = "Si el versionamiento está habilitado"
  value       = var.versioning_enabled
}

output "encryption_enabled" {
  description = "Si la encriptación está habilitada"
  value       = var.encryption_enabled
}
