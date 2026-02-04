# Guía de Políticas - Golden Path

Este documento describe las políticas de seguridad y compliance implementadas.

## Políticas Terraform

### 1. deny_public_access.rego

**Objetivo:** Prevenir la exposición accidental de recursos a Internet.

**Reglas:**
- Prohibe S3 buckets con ACL público
- Bloquea security groups con 0.0.0.0/0 en puertos sensibles
- Prohibe RDS y Redshift públicamente accesibles

**Excepciones:**
```hcl
# checkov:skip=CKV_AWS_XX:ALB debe ser público por diseño
```

### 2. require_encryption.rego

**Objetivo:** Garantizar que todos los datos en reposo estén encriptados.

**Reglas:**
- EBS volumes deben estar encriptados
- RDS debe tener storage_encrypted = true
- S3 debe tener server-side encryption
- ElastiCache debe tener encryption at rest y in transit

### 3. require_tags.rego

**Objetivo:** Governance y tracking de costos.

**Tags requeridos:**
| Tag | Descripción | Ejemplo |
|-----|-------------|---------|
| Environment | Entorno de despliegue | dev, staging, prod |
| Team | Equipo responsable | team-payments |
| CostCenter | Centro de costos | cc-001 |
| Owner | Email del responsable | team@company.com |

### 4. deny_wildcard_iam.rego

**Objetivo:** Principio de least privilege en IAM.

**Reglas:**
- Prohibe Action: "*"
- Prohibe Resource: "*" con acciones sensibles
- Advierte sobre NotAction y NotResource

## Políticas Kubernetes

### 1. workload_security.rego

**Objetivo:** Seguridad de pods y containers.

**Reglas:**
- Prohibe containers privilegiados
- Prohibe hostNetwork, hostPID, hostIPC
- Requiere resource limits
- Prohibe tag :latest
- Requiere runAsNonRoot

### 2. required_labels.rego

**Objetivo:** Estandarización de labels.

**Labels requeridos:**
- app.kubernetes.io/name
- app.kubernetes.io/component
- app.kubernetes.io/part-of
- team
- environment

## Ejecución

### Local

```bash
# Terraform
terraform plan -out=tfplan
terraform show -json tfplan > tfplan.json
conftest test tfplan.json --policy policies/terraform/

# Kubernetes
conftest test deployment.yaml --policy policies/kubernetes/
```

### CI/CD

Las políticas se ejecutan automáticamente en los pipelines de CI/CD.

## Severidad

| Tipo | Descripción | Acción |
|------|-------------|--------|
| deny | Violación crítica | Bloquea el pipeline |
| warn | Advertencia | Muestra warning, no bloquea |

## Excepciones

Para solicitar una excepción:

1. Crear issue en el repositorio de políticas
2. Documentar la justificación técnica
3. Obtener aprobación de Security Team
4. Agregar skip comment con referencia al issue
