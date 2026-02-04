# Variables comunes para todos los stacks
# Importar en cada stack con: locals { common = file("../../shared/common-variables.tf") }

variable "environment" {
  description = "Entorno de deployment"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod", "ephemeral"], var.environment)
    error_message = "El entorno debe ser: dev, staging, prod, ephemeral."
  }
}

variable "client" {
  description = "Nombre del cliente"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,28}[a-z0-9]$", var.client))
    error_message = "El nombre del cliente debe ser lowercase, alfanumérico con guiones."
  }
}

variable "project" {
  description = "Nombre del proyecto"
  type        = string
  default     = "platform"
}

variable "owner" {
  description = "Email del owner/equipo responsable"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.owner))
    error_message = "Debe ser un email válido."
  }
}

variable "cost_center" {
  description = "Centro de costos para billing"
  type        = string

  validation {
    condition     = can(regex("^cc-[a-z0-9-]+$", var.cost_center))
    error_message = "El cost center debe seguir el formato: cc-XXX."
  }
}

variable "team" {
  description = "Equipo responsable"
  type        = string
}

# Tags comunes calculados
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
