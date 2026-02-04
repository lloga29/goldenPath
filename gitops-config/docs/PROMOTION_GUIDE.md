# Guía de Promoción - GitOps

## Principio: Build Once, Promote

Los artefactos se construyen **una sola vez** y se promueven entre entornos.
- NO se permite `:latest`
- Usar SHA de commit o semver
- La promoción es un cambio de configuración, NO un rebuild

## Flujo de Promoción

```
┌─────────┐    ┌─────────┐    ┌─────────┐
│   DEV   │───▶│ STAGING │───▶│  PROD   │
│ (auto)  │    │ (auto)  │    │ (manual)│
└─────────┘    └─────────┘    └─────────┘
     │              │              │
     ▼              ▼              ▼
  PR merge      PR merge      PR + Approval
```

## Proceso

### 1. Promoción Dev → Staging

```bash
# Usar script de promoción
./scripts/promote.sh <team> <service> dev staging <version>

# Ejemplo
./scripts/promote.sh payments payment-api dev staging v1.2.3
```

El script:
1. Actualiza `overlays/staging/kustomization.yaml`
2. Crea branch `promote/<service>-staging-<version>`
3. Abre PR automáticamente

### 2. Promoción Staging → Prod

```bash
./scripts/promote.sh payments payment-api staging prod v1.2.3
```

**Requisitos adicionales para Prod:**
- PR aprobado por al menos 2 revisores
- Todos los checks de CI pasando
- Sin alerts activas en staging
- Verificación manual de smoke tests

### 3. Verificación Post-Promoción

```bash
# Verificar sync en ArgoCD
kubectl get application <app-name> -n argocd -o jsonpath='{.status.sync.status}'

# Verificar health
kubectl get application <app-name> -n argocd -o jsonpath='{.status.health.status}'

# Verificar pods
kubectl get pods -n <namespace> -l app.kubernetes.io/name=<service>
```

## Rollback

Ver [ROLLBACK_PROCEDURE.md](ROLLBACK_PROCEDURE.md)

## Troubleshooting

### PR de promoción falla checks

1. Verificar que la imagen existe en el registry
2. Verificar que el tag es correcto
3. Revisar logs de CI

### ArgoCD no sincroniza

1. Verificar credenciales del repo
2. Verificar sintaxis de manifiestos: `kustomize build overlays/<env>`
3. Revisar logs de ArgoCD: `kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller`
