# Módulo IAM Role
# Crea roles IAM con políticas siguiendo el principio de mínimo privilegio

terraform {
  required_version = ">= 1.5.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0, < 6.0.0"
    }
  }
}

# ============================================
# VARIABLES
# ============================================
variable "name" {
  description = "Nombre del rol IAM"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-_]{2,62}[a-zA-Z0-9]$", var.name))
    error_message = "El nombre debe tener 4-64 caracteres alfanuméricos con guiones/underscores."
  }
}

variable "description" {
  description = "Descripción del rol"
  type        = string
  default     = ""
}

variable "assume_role_policy" {
  description = "Política de asunción del rol (JSON)"
  type        = string
}

variable "managed_policy_arns" {
  description = "ARNs de políticas gestionadas a adjuntar"
  type        = list(string)
  default     = []
}

variable "inline_policies" {
  description = "Políticas inline (mapa nombre -> JSON)"
  type        = map(string)
  default     = {}
}

variable "max_session_duration" {
  description = "Duración máxima de sesión en segundos (1h-12h)"
  type        = number
  default     = 3600

  validation {
    condition     = var.max_session_duration >= 3600 && var.max_session_duration <= 43200
    error_message = "La duración debe estar entre 3600 (1h) y 43200 (12h) segundos."
  }
}

variable "permissions_boundary" {
  description = "ARN de la boundary de permisos"
  type        = string
  default     = null
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
      Module    = "security/iam-role"
      ManagedBy = "terraform"
    }
  )
}

# ============================================
# IAM ROLE
# ============================================
resource "aws_iam_role" "this" {
  name                 = var.name
  description          = var.description
  assume_role_policy   = var.assume_role_policy
  max_session_duration = var.max_session_duration
  permissions_boundary = var.permissions_boundary

  tags = local.common_tags
}

# ============================================
# MANAGED POLICIES
# ============================================
resource "aws_iam_role_policy_attachment" "managed" {
  count = length(var.managed_policy_arns)

  role       = aws_iam_role.this.name
  policy_arn = var.managed_policy_arns[count.index]
}

# ============================================
# INLINE POLICIES
# ============================================
resource "aws_iam_role_policy" "inline" {
  for_each = var.inline_policies

  name   = each.key
  role   = aws_iam_role.this.id
  policy = each.value
}

# ============================================
# OUTPUTS
# ============================================
output "role_arn" {
  description = "ARN del rol IAM"
  value       = aws_iam_role.this.arn
}

output "role_name" {
  description = "Nombre del rol IAM"
  value       = aws_iam_role.this.name
}

output "role_id" {
  description = "ID único del rol"
  value       = aws_iam_role.this.unique_id
}

output "role_create_date" {
  description = "Fecha de creación del rol"
  value       = aws_iam_role.this.create_date
}
