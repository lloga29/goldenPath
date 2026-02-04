# Módulo IAM Role

Crea roles IAM con configuración estándar y políticas de seguridad.

## Uso

```hcl
module "iam_role" {
  source = "git::https://github.com/org/terraform-modules.git//modules/security/iam-role?ref=v1.0.0"

  name        = "mi-servicio-role"
  description = "Rol para el servicio X"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  ]

  inline_policies = {
    custom-policy = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Effect   = "Allow"
        Action   = ["logs:*"]
        Resource = "*"
      }]
    })
  }

  tags = {
    Team       = "platform"
    CostCenter = "cc-001"
  }
}
```

## Seguridad

- Soporta permissions boundaries
- Validación de nombres
- Duración de sesión configurable
- Sin wildcards en políticas (verificar manualmente)
