# Variables para el módulo VPC
# Soporta configuración cloud-agnostic

variable "name" {
  description = "Nombre de la VPC. Debe ser lowercase, alfanumérico con guiones."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,28}[a-z0-9]$", var.name))
    error_message = "El nombre debe tener 4-30 caracteres, lowercase alfanumérico con guiones, comenzando con letra."
  }
}

variable "cidr_block" {
  description = "Bloque CIDR para la VPC (ej: 10.0.0.0/16)"
  type        = string

  validation {
    condition     = can(cidrhost(var.cidr_block, 0))
    error_message = "Debe ser un bloque CIDR válido (ej: 10.0.0.0/16)."
  }
}

variable "environment" {
  description = "Nombre del entorno (dev, staging, prod, ephemeral)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod", "ephemeral"], var.environment)
    error_message = "El entorno debe ser uno de: dev, staging, prod, ephemeral."
  }
}

variable "cloud_provider" {
  description = "Proveedor cloud a utilizar (aws, azure, gcp)"
  type        = string

  validation {
    condition     = contains(["aws", "azure", "gcp"], var.cloud_provider)
    error_message = "El proveedor debe ser uno de: aws, azure, gcp."
  }
}

variable "tags" {
  description = "Tags a aplicar a todos los recursos. Debe incluir 'Team' y 'CostCenter'."
  type        = map(string)
  default     = {}

  validation {
    condition     = contains(keys(var.tags), "Team") && contains(keys(var.tags), "CostCenter")
    error_message = "Los tags deben incluir 'Team' y 'CostCenter'."
  }
}

variable "enable_flow_logs" {
  description = "Habilitar flow logs para la VPC (recomendado para auditoría)"
  type        = bool
  default     = true  # Seguro por defecto
}

variable "enable_dns_hostnames" {
  description = "Habilitar hostnames DNS en la VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Habilitar soporte DNS en la VPC"
  type        = bool
  default     = true
}

# Variables específicas de Azure
variable "location" {
  description = "Ubicación de Azure (requerido si cloud_provider = azure)"
  type        = string
  default     = ""

  validation {
    condition     = var.location == "" || can(regex("^[a-z]+[0-9]*$", var.location))
    error_message = "La ubicación debe ser un nombre de región Azure válido."
  }
}

variable "resource_group_name" {
  description = "Nombre del Resource Group de Azure (requerido si cloud_provider = azure)"
  type        = string
  default     = ""
}

# Variables específicas de GCP
variable "project_id" {
  description = "ID del proyecto GCP (requerido si cloud_provider = gcp)"
  type        = string
  default     = ""
}

variable "auto_create_subnetworks" {
  description = "Crear subnets automáticamente en GCP (no recomendado)"
  type        = bool
  default     = false
}

# Variables para subnets
variable "availability_zones" {
  description = "Lista de zonas de disponibilidad para crear subnets"
  type        = list(string)
  default     = []
}

variable "private_subnet_cidrs" {
  description = "Lista de CIDRs para subnets privadas"
  type        = list(string)
  default     = []
}

variable "public_subnet_cidrs" {
  description = "Lista de CIDRs para subnets públicas"
  type        = list(string)
  default     = []
}
