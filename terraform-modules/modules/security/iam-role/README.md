# AWS IAM Role Module

Creates an AWS IAM role with an explicit trust policy, optional managed policy attachments, optional inline policies, an optional permissions boundary, and standard metadata.

## Security responsibility

This module does not attempt to infer least privilege from arbitrary JSON. Callers must review every trust statement and permission. Organization policy should reject wildcard permissions where they are not justified.

## Example

```hcl
module "iam_role" {
  source = "git::https://github.com/example/platform-terraform-modules.git//modules/security/iam-role?ref=v1.0.0"

  name        = "payments-log-writer"
  description = "Writes application logs to the approved log group"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  inline_policies = {
    log-writer = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:us-east-1:123456789012:log-group:/apps/payments:*"
      }]
    })
  }

  tags = {
    Team       = "payments"
    CostCenter = "cc-001"
  }
}
```

Use placeholder account IDs only in documentation; production code must reference the real authorized resources through configuration/data sources.
