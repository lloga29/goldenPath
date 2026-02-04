# Runbook: Policy Deny en PR

## Alerta
**Nombre:** Policy Check Failed
**Severidad:** Blocking

## Descripción
Una política de Conftest/OPA ha bloqueado un PR por violación de reglas.

## Diagnóstico

### 1. Identificar la política violada
Revisar el output del CI job "Policy Check":
```
FAIL - tfplan.json - terraform.security - S3 bucket 'module.storage.aws_s3_bucket.data' must not be public
```

### 2. Entender la regla
```bash
# Ver el código de la política
cat platform-policies/terraform/<policy-name>.rego
```

## Resolución

### Si el deny es legítimo (lo común)
1. Corregir el código para cumplir la política
2. Push y re-ejecutar CI

Ejemplo para "S3 must not be public":
```hcl
# Antes (viola política)
resource "aws_s3_bucket" "data" {
  acl = "public-read"  # NO!
}

# Después (cumple política)
resource "aws_s3_bucket" "data" {
  # Sin ACL público
}

resource "aws_s3_bucket_public_access_block" "data" {
  bucket = aws_s3_bucket.data.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

### Si necesita excepción (raro)
1. Documentar justificación técnica
2. Crear issue de excepción
3. Agregar a `policy-exceptions.yaml`:
```yaml
exceptions:
  - policy: deny_public_access
    resource: module.storage.aws_s3_bucket.data
    reason: "Bucket para assets públicos del CDN. JIRA-5678"
    owner: "team@company.com"
    expires: "2024-12-31"
    approved_by: "security-team"
```
4. Obtener aprobación de Security Team
5. Merge de la excepción primero, luego el PR original

## Políticas Comunes

| Política | Causa común | Solución |
|----------|-------------|----------|
| deny_public_access | S3/RDS público | Bloquear acceso público |
| require_encryption | Sin encryption | Habilitar encryption |
| require_tags | Tags faltantes | Agregar tags requeridos |
| deny_wildcard_iam | Action: "*" | Permisos específicos |

## Escalación
- Si no está claro cómo resolver: #platform-engineering
- Si necesita excepción urgente: On-call de Security
