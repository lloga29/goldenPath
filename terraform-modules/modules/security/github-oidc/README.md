# Módulo GitHub OIDC

Configura autenticación OIDC para GitHub Actions en AWS, eliminando la necesidad de secretos estáticos.

## Uso

```hcl
module "github_oidc" {
  source = "git::https://github.com/org/terraform-modules.git//modules/security/github-oidc?ref=v1.0.0"

  project     = "mi-proyecto"
  environment = "prod"
  github_org  = "mi-organizacion"

  # Repositorios permitidos
  github_repos = [
    "terraform-modules",
    "platform-stacks",
    "my-app"
  ]

  # Ramas permitidas
  allowed_branches = ["main", "develop"]

  # Políticas adicionales
  iam_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
  ]

  tags = {
    Team       = "platform"
    CostCenter = "cc-001"
  }
}
```

## Uso en GitHub Actions

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read

    steps:
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          aws-region: us-east-1

      - name: Verify credentials
        run: aws sts get-caller-identity
```

## Seguridad

- Sin secretos estáticos (usa tokens efímeros)
- Restricción por repositorio y rama
- Políticas de mínimo privilegio
- Auditable en CloudTrail
