# Runbook: Rollback de Aplicación

## Alerta
**Nombre:** Application Rollback Required
**Severidad:** High/Critical

## Síntomas
- Error rate elevado
- Latencia aumentada
- Pods en CrashLoopBackOff
- Deployment stuck

## Diagnóstico Rápido

### 1. Estado del deployment
```bash
kubectl get deployment <service> -n <namespace>
kubectl describe deployment <service> -n <namespace> | tail -30
```

### 2. Estado de pods
```bash
kubectl get pods -n <namespace> -l app=<service>
kubectl logs -n <namespace> -l app=<service> --tail=100
```

### 3. Eventos recientes
```bash
kubectl get events -n <namespace> --sort-by=.metadata.creationTimestamp | tail -20
```

## Rollback

### Opción 1: Via GitOps (Recomendado)
```bash
cd gitops-config
./scripts/rollback.sh <team> <service> <env>
# Seguir instrucciones
```

### Opción 2: Via kubectl (Emergencia)
```bash
# Rollback inmediato
kubectl rollout undo deployment/<service> -n <namespace>

# Verificar
kubectl rollout status deployment/<service> -n <namespace>

# IMPORTANTE: Crear PR para sincronizar GitOps después
```

### Opción 3: Via ArgoCD UI
1. Ir a ArgoCD: https://argocd.company.com
2. Seleccionar aplicación
3. History and Rollback
4. Seleccionar revisión anterior
5. Rollback

## Post-Rollback

### Verificación
- [ ] Pods running y healthy
- [ ] Error rate normalizado
- [ ] Latencia normalizada
- [ ] Health checks pasando

### Comunicación
- [ ] Notificar en #incidents
- [ ] Actualizar status page si aplica
- [ ] Notificar a stakeholders

### Follow-up
- [ ] Investigar causa raíz
- [ ] Crear post-mortem si afectó usuarios
- [ ] Implementar fixes

## Escalación
- Platform on-call: Ver PagerDuty
- Emergencia: Slack #incidents
