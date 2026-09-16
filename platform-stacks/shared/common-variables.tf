# Common variable and metadata conventions for composed stacks.
# Terraform does not import this file automatically; reuse these declarations deliberately in each stack or package them as a module.

variable "environment" {
  description = "Deployment environment."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod", "ephemeral"], var.environment)
    error_message = "environment must be one of: dev, staging, prod, ephemeral."
  }
}

variable "client" {
  description = "Client identifier."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,28}[a-z0-9]$", var.client))
    error_message = "client must be lowercase alphanumeric with hyphens and start with a letter."
  }
}

variable "project" {
  description = "Project identifier."
  type        = string
  default     = "platform"
}

variable "owner" {
  description = "Owner/team contact email."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.owner))
    error_message = "owner must be a valid email address."
  }
}

variable "cost_center" {
  description = "Cost-center identifier used for allocation/billing."
  type        = string

  validation {
    condition     = can(regex("^cc-[a-z0-9-]+$", var.cost_center))
    error_message = "cost_center must use the cc-<identifier> format."
  }
}

variable "team" {
  description = "Owning team identifier."
  type        = string
}

locals {
  common_tags = {
    Environment = var.environment
    Client      = var.client
    Project     = var.project
    Owner       = var.owner
    CostCenter  = var.cost_center
    Team        = var.team
    ManagedBy   = "terraform"
  }
}
