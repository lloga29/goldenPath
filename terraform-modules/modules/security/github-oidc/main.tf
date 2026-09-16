# GitHub Actions OIDC federation module for AWS.
# Provides short-lived CI/CD identity without static AWS access keys.

terraform {
  required_version = ">= 1.5.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0, < 6.0.0"
    }
  }
}

variable "project" {
  description = "Project identifier used in role/policy names."
  type        = string
}

variable "environment" {
  description = "Deployment environment."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod", "ephemeral"], var.environment)
    error_message = "environment must be one of: dev, staging, prod, ephemeral."
  }
}

variable "github_org" {
  description = "GitHub organization or user that owns the trusted repositories."
  type        = string
}

variable "github_repos" {
  description = "Repository names allowed to assume the role. Use explicit names for production."
  type        = list(string)
  default     = ["*"]
}

variable "allowed_branches" {
  description = "Branches allowed to assume the role."
  type        = list(string)
  default     = ["main"]
}

variable "iam_policy_arns" {
  description = "Additional managed IAM policy ARNs to attach to the GitHub Actions role."
  type        = list(string)
  default     = []
}

variable "terraform_state_bucket_arn" {
  description = "Optional exact S3 bucket ARN for Terraform state access. When null, no built-in state policy is created."
  type        = string
  default     = null
}

variable "terraform_lock_table_arn" {
  description = "Optional exact DynamoDB lock-table ARN for Terraform state locking. Required together with terraform_state_bucket_arn."
  type        = string
  default     = null
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

locals {
  common_tags = merge(
    var.tags,
    {
      Module      = "security/github-oidc"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  )

  # GitHub's OIDC subject is constrained by both repository and branch.
  allowed_subjects = flatten([
    for repo in var.github_repos : [
      for branch in var.allowed_branches : "repo:${var.github_org}/${repo}:ref:refs/heads/${branch}"
    ]
  ])

  create_terraform_state_policy = var.terraform_state_bucket_arn != null && var.terraform_lock_table_arn != null
}

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]

  tags = local.common_tags
}

resource "aws_iam_role" "github_actions" {
  name = "${var.project}-github-actions-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = local.allowed_subjects
          }
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "custom_policies" {
  count = length(var.iam_policy_arns)

  role       = aws_iam_role.github_actions.name
  policy_arn = var.iam_policy_arns[count.index]
}

# Optional, explicitly scoped Terraform-state policy.
resource "aws_iam_role_policy" "terraform_state" {
  count = local.create_terraform_state_policy ? 1 : 0

  name = "${var.project}-terraform-state-${var.environment}"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          var.terraform_state_bucket_arn,
          "${var.terraform_state_bucket_arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ]
        Resource = var.terraform_lock_table_arn
      }
    ]
  })
}

output "oidc_provider_arn" {
  description = "GitHub OIDC provider ARN."
  value       = aws_iam_openid_connect_provider.github.arn
}

output "oidc_provider_url" {
  description = "GitHub OIDC provider URL."
  value       = aws_iam_openid_connect_provider.github.url
}

output "role_arn" {
  description = "GitHub Actions IAM role ARN."
  value       = aws_iam_role.github_actions.arn
}

output "role_name" {
  description = "GitHub Actions IAM role name."
  value       = aws_iam_role.github_actions.name
}
