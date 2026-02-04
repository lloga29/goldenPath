# Platform Policies - Golden Path

Políticas de seguridad y compliance para infraestructura y aplicaciones.

## Estructura

```
terraform/           # Políticas para Terraform (Conftest/OPA)
kubernetes/          # Políticas para Kubernetes (Gatekeeper)
docs/               # Documentación de políticas
```

## Políticas Terraform

### Seguridad

- **deny_public_access**: Prohibe buckets S3 públicos
- **deny_open_security_groups**: Bloquea 0.0.0.0/0 en puertos sensibles
- **deny_wildcard_iam**: Prohibe políticas IAM con wildcards
- **require_encryption**: Requiere encryption en EBS, RDS, etc.

### Compliance

- **require_tags**: Tags obligatorios (Environment, Team, CostCenter, Owner)
- **naming_convention**: Validación de nombres de recursos

## Políticas Kubernetes

### Workload Security

- **no_privileged_containers**: Prohibe containers privilegiados
- **no_host_network**: Prohibe uso de hostNetwork
- **require_resource_limits**: Requiere limits de CPU y memoria
- **no_latest_tag**: Prohibe uso de tag :latest
- **require_probes**: Requiere liveness y readiness probes

## Uso

### Validar Terraform localmente

```bash
# Generar plan JSON
terraform plan -out=tfplan
terraform show -json tfplan > tfplan.json

# Ejecutar políticas
conftest test tfplan.json --policy policies/terraform/
```

### Validar manifiestos Kubernetes

```bash
conftest test deployment.yaml --policy policies/kubernetes/
```

## Ejecución en CI/CD

Las políticas se ejecutan automáticamente en:
- Pre-commit (local)
- PR (CI)
- Merge (CD)
- Runtime (Gatekeeper)

## Matriz de Políticas

| Stage | Tool | Políticas | Acción |
|-------|------|-----------|--------|
| Pre-commit | conftest | básicas | Warn |
| PR | conftest, checkov | todas | Block |
| Merge | terraform plan | re-validate | Block |
| Runtime | Gatekeeper | admission | Block |

## Excepciones

Las excepciones deben ser documentadas y aprobadas:

```hcl
# En el código Terraform
#checkov:skip=CKV_AWS_XX:Justificación de la excepción
```
