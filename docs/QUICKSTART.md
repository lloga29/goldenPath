# Golden Path - Quickstart en 15 minutos

Este documento te guía para crear y desplegar un nuevo servicio end-to-end.

## Prerequisitos

```bash
# Herramientas requeridas
terraform --version   # >= 1.5.0
kubectl version       # >= 1.28
copier --version      # >= 9.0
yq --version          # >= 4.0
```

## Paso 1: Crear Servicio desde Template (2 min)

```bash
# Crear nuevo microservicio
copier copy ./service-templates/templates/microservice-golang my-awesome-api

# Responder las preguntas:
# - project_name: my-awesome-api
# - team: payments
# - description: API for awesome things
# - port: 8080
# - has_database: false
# - has_cache: false
```

## Paso 2: Verificar Localmente (3 min)

```bash
cd my-awesome-api

# Instalar dependencias
go mod tidy

# Ejecutar tests
make test

# Ejecutar localmente
make run

# En otra terminal, verificar
curl http://localhost:8080/health
curl http://localhost:8080/ready
curl http://localhost:8080/metrics
```

## Paso 3: Configurar GitOps (5 min)

```bash
# Crear directorio en gitops-config
mkdir -p ../gitops-config/apps/team-payments/my-awesome-api/{base,overlays/{dev,staging,prod}}

# Copiar manifiestos base
cp -r ../gitops-config/apps/team-payments/payment-api/base/* \
      ../gitops-config/apps/team-payments/my-awesome-api/base/

# Actualizar nombres en los archivos
cd ../gitops-config/apps/team-payments/my-awesome-api/base
sed -i 's/payment-api/my-awesome-api/g' *.yaml

# Crear overlays (copiar de payment-api y ajustar)
```

## Paso 4: Primer Deploy a Dev (3 min)

```bash
# Construir imagen
cd my-awesome-api
make docker-build

# Push a registry (ajustar según tu registry)
docker tag my-awesome-api:dev ghcr.io/org/my-awesome-api:v0.1.0
docker push ghcr.io/org/my-awesome-api:v0.1.0

# Actualizar overlay dev con el tag
cd ../gitops-config/apps/team-payments/my-awesome-api/overlays/dev
# Editar kustomization.yaml con el tag v0.1.0

# Commit y push
git add .
git commit -m "feat(payments): add my-awesome-api to dev"
git push
```

## Paso 5: Verificar Despliegue (2 min)

```bash
# Ver estado en ArgoCD
kubectl get application my-awesome-api-dev -n argocd

# Ver pods
kubectl get pods -n payments-dev -l app.kubernetes.io/name=my-awesome-api

# Ver logs
kubectl logs -n payments-dev -l app.kubernetes.io/name=my-awesome-api
```

## Paso 6: Promocionar a Staging

```bash
cd gitops-config
./scripts/promote.sh payments my-awesome-api dev staging v0.1.0
# Crear PR, obtener aprobación, merge
```

## Resumen de Tiempos

| Paso | Tiempo |
|------|--------|
| Crear servicio | 2 min |
| Verificar local | 3 min |
| Configurar GitOps | 5 min |
| Deploy a dev | 3 min |
| Verificar | 2 min |
| **Total** | **15 min** |

## Troubleshooting

### El build falla
```bash
# Verificar sintaxis Go
go vet ./...

# Verificar formato
gofmt -d .
```

### ArgoCD no sincroniza
```bash
# Verificar manifiestos
kustomize build overlays/dev

# Ver logs de ArgoCD
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller
```

### Pod en CrashLoopBackOff
```bash
# Ver logs del pod
kubectl logs -n <namespace> <pod-name> --previous

# Verificar configuración
kubectl describe pod -n <namespace> <pod-name>
```

## Siguiente Pasos

- [ ] Agregar tests de integración
- [ ] Configurar alertas en Prometheus
- [ ] Crear dashboard en Grafana
- [ ] Documentar API
