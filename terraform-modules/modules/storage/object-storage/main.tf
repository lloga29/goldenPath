# Multi-provider object-storage reference module.
# Supports Amazon S3, Azure Blob containers, and Google Cloud Storage buckets.

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

variable "name" {
  description = "Bucket or container name."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", var.name))
    error_message = "name must be 3-63 lowercase alphanumeric characters or hyphens."
  }
}

variable "environment" {
  description = "Deployment environment."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod", "ephemeral"], var.environment)
    error_message = "environment must be one of: dev, staging, prod, ephemeral."
  }
}

variable "cloud_provider" {
  description = "Provider implementation: aws, azure, or gcp."
  type        = string

  validation {
    condition     = contains(["aws", "azure", "gcp"], var.cloud_provider)
    error_message = "cloud_provider must be one of: aws, azure, gcp."
  }
}

variable "versioning_enabled" {
  description = "Enable provider-supported object versioning."
  type        = bool
  default     = true
}

variable "encryption_enabled" {
  description = "Enable module-managed encryption configuration where this reference implements it."
  type        = bool
  default     = true
}

variable "public_access_blocked" {
  description = "Block or prevent public access where the selected provider implementation supports the setting."
  type        = bool
  default     = true
}

variable "lifecycle_rules" {
  description = "Lifecycle rules for supported bucket implementations."
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

# Azure-specific inputs.
variable "resource_group_name" {
  description = "Azure Resource Group name. Reserved for a fuller Azure implementation."
  type        = string
  default     = ""
}

variable "storage_account_name" {
  description = "Existing Azure Storage Account name that will host the container."
  type        = string
  default     = ""
}

# Google Cloud-specific inputs.
variable "project_id" {
  description = "Google Cloud project ID."
  type        = string
  default     = ""
}

variable "location" {
  description = "Provider location/region where applicable."
  type        = string
  default     = "us-east-1"
}

variable "tags" {
  description = "Ownership/cost metadata. Must include Team and CostCenter."
  type        = map(string)
  default     = {}

  validation {
    condition     = contains(keys(var.tags), "Team") && contains(keys(var.tags), "CostCenter")
    error_message = "tags must include Team and CostCenter."
  }
}

locals {
  common_tags = merge(
    var.tags,
    {
      Module      = "storage/object-storage"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  )

  # Google Cloud labels use provider-native lowercase keys and normalized values.
  # Missing Owner remains empty so policy-as-code can fail closed instead of
  # manufacturing ownership metadata.
  gcp_labels = {
    environment = var.environment
    team        = substr(replace(lower(var.tags["Team"]), "/[^a-z0-9_-]/", "_"), 0, 63)
    cost_center = substr(replace(lower(var.tags["CostCenter"]), "/[^a-z0-9_-]/", "_"), 0, 63)
    owner       = substr(replace(lower(lookup(var.tags, "Owner", "")), "/[^a-z0-9_-]/", "_"), 0, 63)
    module      = "storage_object_storage"
    managed_by  = "terraform"
  }
}

resource "aws_s3_bucket" "this" {
  count = var.cloud_provider == "aws" ? 1 : 0

  bucket = var.name
  tags   = local.common_tags

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_s3_bucket_versioning" "this" {
  count  = var.cloud_provider == "aws" ? 1 : 0
  bucket = aws_s3_bucket.this[0].id

  versioning_configuration {
    status = var.versioning_enabled ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  count  = var.cloud_provider == "aws" && var.encryption_enabled ? 1 : 0
  bucket = aws_s3_bucket.this[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  count  = var.cloud_provider == "aws" ? 1 : 0
  bucket = aws_s3_bucket.this[0].id

  block_public_acls       = var.public_access_blocked
  block_public_policy     = var.public_access_blocked
  ignore_public_acls      = var.public_access_blocked
  restrict_public_buckets = var.public_access_blocked
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count  = var.cloud_provider == "aws" && length(var.lifecycle_rules) > 0 ? 1 : 0
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

# Azure reference creates a container inside an existing Storage Account.
resource "azurerm_storage_container" "this" {
  count = var.cloud_provider == "azure" ? 1 : 0

  name                  = var.name
  storage_account_name  = var.storage_account_name
  container_access_type = var.public_access_blocked ? "private" : "blob"
}

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

  # Google Cloud Storage uses provider-managed encryption by default. A CMEK
  # block must only be added when a non-null KMS key name is supplied.
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

  labels = local.gcp_labels
}

output "bucket_id" {
  description = "Provider-specific bucket/container ID."
  value = coalesce(
    try(aws_s3_bucket.this[0].id, null),
    try(azurerm_storage_container.this[0].id, null),
    try(google_storage_bucket.this[0].id, null)
  )
}

output "bucket_arn" {
  description = "AWS S3 bucket ARN, or null for other providers."
  value       = try(aws_s3_bucket.this[0].arn, null)
}

output "bucket_name" {
  description = "Configured bucket/container name."
  value       = var.name
}

output "bucket_url" {
  description = "Provider-specific bucket/container URL."
  value = coalesce(
    try("s3://${aws_s3_bucket.this[0].bucket}", null),
    try("https://${var.storage_account_name}.blob.core.windows.net/${azurerm_storage_container.this[0].name}", null),
    try("gs://${google_storage_bucket.this[0].name}", null)
  )
}

output "versioning_enabled" {
  description = "Requested versioning setting. Verify provider-specific behavior."
  value       = var.versioning_enabled
}

output "encryption_enabled" {
  description = "Requested module-managed encryption setting. This is not equivalent across providers."
  value       = var.encryption_enabled
}
