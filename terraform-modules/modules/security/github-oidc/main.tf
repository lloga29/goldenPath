# Módulo GitHub OIDC para AWS
# Permite autenticación sin secretos estáticos desde GitHub Actions

# ============================================
# VARIABLES
# ============================================
variable "project" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Entorno (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod", "ephemeral"], var.environment)
    error_message = "El entorno debe ser uno de: dev, staging, prod, ephemeral."
  }
}

variable "github_org" {
  description = "Organización de GitHub"
  type        = string
}

variable "github_repos" {
  description = "Lista de repositorios permitidos (formato: repo-name)"
  type        = list(string)
  default     = ["*"]
}

variable "allowed_branches" {
  description = "Ramas permitidas para asumir el rol"
  type        = list(string)
  default     = ["main", "develop"]
}

variable "iam_policy_arns" {
  description = "ARNs de políticas IAM a adjuntar al rol"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags a aplicar a los recursos"
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
      Module      = "security/github-oidc"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  )

  # Construir condiciones para repositorios
  repo_conditions = [
    for repo in var.github_repos : "repo:${var.github_org}/${repo}:*"
  ]

  # Construir condiciones para ramas
  branch_conditions = [
    for branch in var.allowed_branches : "repo:${var.github_org}/*:ref:refs/heads/${branch}"
  ]
}

# ============================================
# OIDC PROVIDER
# ============================================
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

  # Thumbprints de GitHub Actions
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]

  tags = local.common_tags
}

# ============================================
# IAM ROLE
# ============================================
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
            "token.actions.githubusercontent.com:sub" = local.repo_conditions
          }
        }
      }
    ]
  })

  tags = local.common_tags
}

# ============================================
# IAM POLICY ATTACHMENTS
# ============================================
resource "aws_iam_role_policy_attachment" "custom_policies" {
  count = length(var.iam_policy_arns)

  role       = aws_iam_role.github_actions.name
  policy_arn = var.iam_policy_arns[count.index]
}

# Política básica para Terraform State
resource "aws_iam_role_policy" "terraform_state" {
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
          "arn:aws:s3:::*-terraform-state",
          "arn:aws:s3:::*-terraform-state/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ]
        Resource = "arn:aws:dynamodb:*:*:table/*-terraform-locks"
      }
    ]
  })
}

# ============================================
# OUTPUTS
# ============================================
output "oidc_provider_arn" {
  description = "ARN del proveedor OIDC"
  value       = aws_iam_openid_connect_provider.github.arn
}

output "oidc_provider_url" {
  description = "URL del proveedor OIDC"
  value       = aws_iam_openid_connect_provider.github.url
}

output "role_arn" {
  description = "ARN del rol IAM para GitHub Actions"
  value       = aws_iam_role.github_actions.arn
}

output "role_name" {
  description = "Nombre del rol IAM"
  value       = aws_iam_role.github_actions.name
}
