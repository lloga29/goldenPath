# Runbook: Drift Detectado en Terraform

## Alerta
**Nombre:** Terraform Drift Detected
**Severidad:** Warning/High (dependiendo del recurso)

## Descripción
Se ha detectado una diferencia entre el estado deseado (código) y el estado actual (cloud).

## Diagnóstico

### 1. Verificar el drift
```bash
cd platform-stacks/clients/<client>/environments/<env>
terraform init
terraform plan -detailed-exitcode
```

Exit codes:
- `0`: Sin cambios
- `1`: Error
- `2`: Hay cambios (drift)

### 2. Identificar recursos afectados
```bash
terraform plan -out=drift.plan
terraform show -json drift.plan | jq '.resource_changes[] | select(.change.actions != ["no-op"]) | {address, actions: .change.actions}'
```

### 3. Determinar causa
- **Cambio manual:** Alguien modificó el recurso directamente en la consola/CLI
- **Recurso externo:** Otro proceso/servicio modificó el recurso
- **Drift natural:** Algunos recursos cambian automáticamente (ej: ASG instances)

## Remediación

### Opción A: Reconciliar hacia el código (recomendado)
```bash
# Esto revertirá los cambios manuales
terraform apply drift.plan
```

### Opción B: Importar el cambio al código
1. Actualizar el código Terraform para reflejar el nuevo estado
2. Verificar con `terraform plan` que no hay diff
3. Crear PR con la actualización

### Opción C: Refresh del estado (solo si es drift natural)
```bash
terraform refresh
# Luego actualizar código si es necesario
```

## Prevención
- No hacer cambios manuales en recursos gestionados por Terraform
- Usar tags `ManagedBy: terraform` para identificar recursos
- Configurar alertas de CloudTrail/Activity Log para detectar cambios

## Escalación
- Si el drift afecta producción: Escalar a on-call de Platform
- Si es cambio no autorizado: Reportar a Security
