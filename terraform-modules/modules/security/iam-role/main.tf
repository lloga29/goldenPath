# AWS IAM role module.
# Creates IAM roles and policy attachments; callers remain responsible for least-privilege policy content.

terraform {
  required_version = ">= 1.5.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0, < 6.0.0"
    }
  }
}

variable "name" {
  description = "IAM role name."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-_]{2,62}[a-zA-Z0-9]$", var.name))
    error_message = "name must be 4-64 alphanumeric characters and may contain hyphens or underscores."
  }
}

variable "description" {
  description = "IAM role description."
  type        = string
  default     = ""
}

variable "assume_role_policy" {
  description = "Role trust policy as JSON."
  type        = string
}

variable "managed_policy_arns" {
  description = "Managed policy ARNs to attach to the role."
  type        = list(string)
  default     = []
}

variable "inline_policies" {
  description = "Inline policies as a map of policy name to JSON policy document."
  type        = map(string)
  default     = {}
}

variable "max_session_duration" {
  description = "Maximum session duration in seconds, from 1 to 12 hours."
  type        = number
  default     = 3600

  validation {
    condition     = var.max_session_duration >= 3600 && var.max_session_duration <= 43200
    error_message = "max_session_duration must be between 3600 and 43200 seconds."
  }
}

variable "permissions_boundary" {
  description = "Optional permissions-boundary ARN."
  type        = string
  default     = null
}

variable "tags" {
  description = "Metadata applied to the IAM role. Must include Team and CostCenter."
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
      Module    = "security/iam-role"
      ManagedBy = "terraform"
    }
  )
}

resource "aws_iam_role" "this" {
  name                 = var.name
  description          = var.description
  assume_role_policy   = var.assume_role_policy
  max_session_duration = var.max_session_duration
  permissions_boundary = var.permissions_boundary

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "managed" {
  count = length(var.managed_policy_arns)

  role       = aws_iam_role.this.name
  policy_arn = var.managed_policy_arns[count.index]
}

resource "aws_iam_role_policy" "inline" {
  for_each = var.inline_policies

  name   = each.key
  role   = aws_iam_role.this.id
  policy = each.value
}

output "role_arn" {
  description = "IAM role ARN."
  value       = aws_iam_role.this.arn
}

output "role_name" {
  description = "IAM role name."
  value       = aws_iam_role.this.name
}

output "role_id" {
  description = "IAM role unique ID."
  value       = aws_iam_role.this.unique_id
}

output "role_create_date" {
  description = "IAM role creation timestamp."
  value       = aws_iam_role.this.create_date
}
