# Inputs for the multi-provider VPC/VNet/network reference module.

variable "name" {
  description = "VPC/VNet/network name. Must be lowercase alphanumeric with hyphens."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,28}[a-z0-9]$", var.name))
    error_message = "name must be 4-30 lowercase alphanumeric characters or hyphens and must start with a letter."
  }
}

variable "cidr_block" {
  description = "CIDR block for the network, for example 10.0.0.0/16."
  type        = string

  validation {
    condition     = can(cidrhost(var.cidr_block, 0))
    error_message = "cidr_block must be a valid CIDR block, for example 10.0.0.0/16."
  }
}

variable "environment" {
  description = "Deployment environment: dev, staging, prod, or ephemeral."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod", "ephemeral"], var.environment)
    error_message = "environment must be one of: dev, staging, prod, ephemeral."
  }
}

variable "cloud_provider" {
  description = "Cloud provider implementation to use: aws, azure, or gcp."
  type        = string

  validation {
    condition     = contains(["aws", "azure", "gcp"], var.cloud_provider)
    error_message = "cloud_provider must be one of: aws, azure, gcp."
  }
}

variable "tags" {
  description = "Metadata applied to supported resources. Must include Team and CostCenter."
  type        = map(string)
  default     = {}

  validation {
    condition     = contains(keys(var.tags), "Team") && contains(keys(var.tags), "CostCenter")
    error_message = "tags must include Team and CostCenter."
  }
}

variable "enable_flow_logs" {
  description = "Enable supported network flow logging. Recommended for auditability."
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames for the AWS VPC."
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support for the AWS VPC."
  type        = bool
  default     = true
}

# Azure-specific inputs.
variable "location" {
  description = "Azure location. Required when cloud_provider is azure."
  type        = string
  default     = ""

  validation {
    condition     = var.location == "" || can(regex("^[a-z]+[0-9]*$", var.location))
    error_message = "location must be a valid Azure region name."
  }
}

variable "resource_group_name" {
  description = "Azure Resource Group name. Required when cloud_provider is azure."
  type        = string
  default     = ""
}

# Google Cloud-specific inputs.
variable "project_id" {
  description = "Google Cloud project ID. Required when cloud_provider is gcp."
  type        = string
  default     = ""
}

variable "auto_create_subnetworks" {
  description = "Enable automatic Google Cloud subnet creation. Not recommended for controlled production networks."
  type        = bool
  default     = false
}

# Subnet inputs.
variable "availability_zones" {
  description = "Availability zones or regions used by the selected provider implementation."
  type        = list(string)
  default     = []
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets."
  type        = list(string)
  default     = []
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets."
  type        = list(string)
  default     = []
}
