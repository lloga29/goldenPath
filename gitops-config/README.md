# GitOps Config - Golden Path

Repositorio de configuración GitOps para despliegue de aplicaciones con Argo CD.

## Estructura

```
gitops-config/
├── argocd/                    # Configuración de Argo CD
│   ├── projects/              # Proyectos (RBAC por equipo)
│   └── applicationsets/       # ApplicationSets para auto-discovery
├── clusters/                  # Configuración por cluster
│   ├── dev/
│   ├── staging/
│   └── prod/
├── platform/                  # Componentes de plataforma
│   ├── base/                  # Configuración base (cert-manager, etc.)
│   └── overlays/              # Overlays por entorno
├── apps/                      # Aplicaciones por equipo
│   └── team-{name}/
│       └── {service}/
│           ├── base/
│           └── overlays/
├── policies/                  # Políticas Gatekeeper
│   ├── constraints/
│   └── constraint-templates/
├── scripts/                   # Scripts de operaciones
└── docs/                      # Documentación
```

## Flujo de Trabajo

### 1. Crear nueva aplicación

```bash
# Copiar estructura base
cp -r apps/team-payments/payment-api apps/team-{mi-equipo}/{mi-servicio}

# Editar kustomization y manifiestos
# Crear PR y esperar merge
```

### 2. Promocionar versión

```bash
./scripts/promote.sh payments payment-api dev staging v1.2.3
git commit -am "chore: promote payment-api to staging"
git push
```

### 3. Rollback

```bash
./scripts/rollback.sh payments payment-api prod
# Seguir instrucciones interactivas
```

## Entornos

| Entorno | Auto-Sync | Prune | Aprobación |
|---------|-----------|-------|------------|
| dev     | ✅        | ✅    | No         |
| staging | ✅        | ❌    | No         |
| prod    | ❌        | ❌    | Sí         |

## Políticas

Las siguientes políticas se aplican automáticamente:

- **required-labels**: Labels obligatorios en Deployments
- **container-limits**: Límites de CPU/memoria requeridos
- **no-privileged**: Containers privilegiados prohibidos

## Documentación

- [Guía de Promoción](docs/PROMOTION_GUIDE.md)
- [Procedimiento de Rollback](docs/ROLLBACK_PROCEDURE.md)
