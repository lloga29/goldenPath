# Golden Path - Plataforma de Ingeniería

Implementación completa de un Golden Path para plataformas internas de ingeniería enterprise multi-cliente.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         PRINCIPIOS DEL GOLDEN PATH                         │
├─────────────────────────────────────────────────────────────────────────────┤
│  🛤️  PAVED ROADS          → Caminos pavimentados, no muros                 │
│  🔒 SECURE BY DEFAULT     → Seguridad incorporada desde el diseño          │
│  📦 BUILD ONCE, PROMOTE   → Artefactos inmutables y reproducibles          │
│  📝 EVERYTHING AS CODE    → Infra, policies, config, runbooks, docs        │
│  🔑 LEAST PRIVILEGE       → Permisos mínimos necesarios                    │
│  🔄 IDEMPOTENCY           → Operaciones repetibles con mismo resultado     │
│  📊 AUDITABILITY          → Trazabilidad completa end-to-end               │
│  💻 DEVELOPER EXPERIENCE  → Fricción mínima y autoservicio                 │
│  📈 MEASURE & IMPROVE     → DORA metrics, SLOs, mejora continua            │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Arquitectura

```
                                GOLDEN PATH ARCHITECTURE

    ┌─────────────────────────────────────────────────────────────────────────────┐
    │                              DEVELOPER WORKFLOW                              │
    │  Feature Branch → Pre-commit Hooks → Push → PR Created                      │
    └─────────────────────────────────────────────────────────────────────────────┘
                                          │
                                          ▼
    ┌─────────────────────────────────────────────────────────────────────────────┐
    │                               CI PIPELINE                                    │
    │  Lint → Test → Security Scan → Build Image → Sign → Publish → Update GitOps │
    └─────────────────────────────────────────────────────────────────────────────┘
                                          │
                    ┌─────────────────────┼─────────────────────┐
                    ▼                     ▼                     ▼
             POLICY GATES           COST GATES           APPROVAL GATES
             (OPA/Conftest)         (Infracost)          (PR/Env Approvals)
                                          │
                                          ▼
    ┌─────────────────────────────────────────────────────────────────────────────┐
    │                              GITOPS (ARGO CD)                                │
    │         GitOps Repo → Argo CD ApplicationSet → Sync to Cluster              │
    └─────────────────────────────────────────────────────────────────────────────┘
                                          │
                    ┌─────────────────────┼─────────────────────┐
                    ▼                     ▼                     ▼
                   DEV                 STAGING              PRODUCTION
              (Auto Sync)           (Auto Sync)           (Manual Sync)
```

## Estructura de Repositorios

```
goldenPath/
├── terraform-modules/      # Módulos oficiales de Terraform (cloud-agnostic)
├── platform-stacks/        # Stacks de infraestructura por cliente/entorno
├── gitops-config/          # Configuración GitOps con Argo CD
├── service-templates/      # Templates para nuevos servicios (Copier)
└── platform-policies/      # Políticas OPA/Conftest para governance
```

## Repositorios

### terraform-modules/

Módulos oficiales de Terraform cloud-agnostic (AWS/Azure/GCP).

| Módulo | Descripción |
|--------|-------------|
| `networking/vpc` | VPC/VNet con subnets públicas y privadas |
| `security/iam-role` | Roles IAM con políticas |
| `security/github-oidc` | Federación OIDC para GitHub Actions |
| `storage/object-storage` | S3/Blob/GCS con encryption |
| `patterns/three-tier-app` | Arquitectura de 3 capas |

```bash
# Uso
module "vpc" {
  source = "git::https://github.com/org/terraform-modules.git//modules/networking/vpc?ref=v1.0.0"

  name           = "mi-vpc-prod"
  cidr_block     = "10.0.0.0/16"
  environment    = "prod"
  cloud_provider = "aws"

  tags = {
    Team       = "platform"
    CostCenter = "cc-001"
  }
}
```

### platform-stacks/

Stacks de infraestructura organizados por cliente y entorno.

```
platform-stacks/
├── clients/
│   └── client-acme/
│       ├── bootstrap/          # State bucket, IAM inicial
│       ├── foundation/         # Networking, security base
│       └── environments/
│           ├── dev/
│           ├── staging/
│           └── prod/
└── teams/
    └── team-payments/
        └── services/
```

### gitops-config/

Configuración GitOps para Argo CD con Kustomize.

| Componente | Descripción |
|------------|-------------|
| `argocd/applicationsets/` | ApplicationSets para auto-discovery |
| `clusters/` | Configuración por cluster |
| `platform/` | Componentes de plataforma (cert-manager, etc.) |
| `apps/` | Aplicaciones por equipo |
| `policies/` | Políticas Gatekeeper |

```bash
# Promocionar versión
./scripts/promote.sh payments payment-api dev staging v1.2.3

# Rollback
./scripts/rollback.sh payments payment-api prod
```

### service-templates/

Templates Copier para crear nuevos servicios.

```bash
# Crear nuevo microservicio Go
copier copy gh:org/service-templates/templates/microservice-golang my-service

# Actualizar servicio existente
copier update my-existing-service
```

**Templates disponibles:**
- `microservice-golang` - Microservicio HTTP/gRPC en Go
- `microservice-python` - Microservicio FastAPI
- `terraform-stack` - Stack de Terraform

### platform-policies/

Políticas OPA/Conftest para Terraform y Kubernetes.

**Políticas Terraform:**
- `deny_public_access` - Prohibe recursos públicos
- `require_encryption` - Requiere encryption en todos los recursos
- `require_tags` - Tags obligatorios (Environment, Team, CostCenter, Owner)
- `deny_wildcard_iam` - Prohibe políticas IAM con wildcards

**Políticas Kubernetes:**
- `workload_security` - Seguridad de pods y containers
- `required_labels` - Labels estándar obligatorios

```bash
# Validar Terraform
terraform plan -out=tfplan
terraform show -json tfplan > tfplan.json
conftest test tfplan.json --policy policies/terraform/

# Validar Kubernetes
conftest test deployment.yaml --policy policies/kubernetes/
```

## Objetivos DORA Metrics

| Métrica | Actual | Objetivo 30 días | Objetivo 90 días |
|---------|--------|------------------|------------------|
| Deploy Frequency | 1/semana | 1/día | Múltiples/día |
| Lead Time | Días | Horas | <4 horas |
| Change Failure Rate | >20% | <15% | <10% |
| MTTR | Horas | <1 hora | <30 min |

## Quick Start

### 1. Nuevo Cliente

```bash
cd platform-stacks
./scripts/init-client.sh nuevo-cliente aws us-east-1
```

### 2. Nuevo Servicio

```bash
copier copy ./service-templates/templates/microservice-golang mi-servicio
cd mi-servicio
git init && git add . && git commit -m "Initial commit"
```

### 3. Desplegar a Dev

```bash
# El CI/CD automáticamente:
# 1. Ejecuta tests y security scans
# 2. Construye y publica imagen
# 3. Actualiza gitops-config
# 4. Argo CD sincroniza a dev
```

## Entornos

| Entorno | Auto-Sync | Auto-Prune | Aprobación |
|---------|-----------|------------|------------|
| dev | ✅ | ✅ | No |
| staging | ✅ | ❌ | No |
| prod | ❌ | ❌ | Sí |
| ephemeral | ✅ | ✅ | No (TTL) |

## Documentación

- [Guía de Implementación](golden-path-implementation-guide.md)
- [Estándares de Módulos](terraform-modules/docs/MODULE_STANDARDS.md)
- [Guía de Contribución](terraform-modules/docs/CONTRIBUTING.md)
- [Guía de Políticas](platform-policies/docs/POLICY_GUIDE.md)
- [Procedimiento de Promoción](gitops-config/docs/PROMOTION_GUIDE.md)
- [Procedimiento de Rollback](gitops-config/docs/ROLLBACK_PROCEDURE.md)

## Licencia

Uso interno - Propiedad de la organización.
