# Procedimiento de Rollback

## Principio

El rollback es un **git revert**, no un cambio manual. Esto garantiza:
- Trazabilidad completa
- Reproducibilidad
- Audit trail

## Rollback Rápido (Emergencia)

### Opción A: Via Script (Recomendado)

```bash
./scripts/rollback.sh <team> <service> <environment>

# Ejemplo
./scripts/rollback.sh payments payment-api prod
```

El script:
1. Identifica el último commit de promoción
2. Crea un git revert
3. Crea PR automáticamente (o push directo en emergencia)

### Opción B: Via kubectl (Solo emergencias)

```bash
# Rollback inmediato del Deployment
kubectl rollout undo deployment/<service> -n <namespace>

# Verificar
kubectl rollout status deployment/<service> -n <namespace>
```

**IMPORTANTE:** Después de kubectl rollout undo, crear PR para sincronizar GitOps.

### Opción C: Via ArgoCD UI

1. Ir a ArgoCD UI
2. Seleccionar la aplicación
3. Click "History and Rollback"
4. Seleccionar revisión anterior
5. Click "Rollback"

**IMPORTANTE:** Crear PR después para sincronizar el repo.

## Rollback Planificado

Para rollbacks no urgentes:

```bash
# 1. Crear branch
git checkout -b rollback/<service>-<env>

# 2. Revertir el commit de promoción
git revert <commit-sha>

# 3. Push y crear PR
git push -u origin rollback/<service>-<env>
gh pr create --title "Rollback: <service> en <env>" --body "Razón: ..."
```

## Verificación Post-Rollback

```bash
# 1. Verificar sync status
kubectl get application <app> -n argocd

# 2. Verificar pods
kubectl get pods -n <namespace> -l app=<service>

# 3. Verificar logs
kubectl logs -n <namespace> -l app=<service> --tail=100

# 4. Verificar métricas
# Revisar dashboard de Grafana para error rate y latencia
```

## Comunicación

1. **Slack:** Notificar en #incidents
2. **PagerDuty:** Actualizar incidente si aplica
3. **Post-mortem:** Documentar causa raíz

## Checklist Post-Rollback

- [ ] Servicio funcionando correctamente
- [ ] Métricas normales (error rate, latencia)
- [ ] GitOps repo sincronizado
- [ ] Equipo notificado
- [ ] Incidente documentado
