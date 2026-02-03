# 🚀 GOLDEN PATH - Guía de Implementación Completa para Claude Code

## INSTRUCCIONES PARA CLAUDE CODE

Este documento contiene toda la especificación necesaria para implementar un Golden Path completo para una plataforma interna de ingeniería. Tu objetivo es generar la estructura de repositorios, código, configuraciones y pipelines necesarios.

### Modo de Trabajo

1. **Lee completamente este documento antes de empezar**
2. **Crea la estructura de directorios primero**
3. **Implementa componente por componente** siguiendo el orden establecido
4. **Valida cada componente** antes de pasar al siguiente
5. **Documenta todo** con READMEs y comentarios

### Output Esperado

Debes generar los siguientes repositorios completos:
- `terraform-modules/` - Módulos oficiales de Terraform
- `platform-stacks/` - Stacks por cliente/entorno
- `gitops-config/` - Configuración GitOps con Argo CD
- `service-templates/` - Templates para nuevos servicios
- `platform-policies/` - Políticas OPA/Conftest

---

# PARTE 1: CONTEXTO Y OBJETIVOS

## 1.1 Descripción del Proyecto

### Organización Target
- **Equipos:** 10-30 equipos de producto (microservicios + data pipelines)
- **Modelo:** Consultoría enterprise multi-cliente/tenant
- **Cloud:** Agnóstico (AWS/Azure/GCP)

### Entornos
- `dev` - Desarrollo
- `staging` - Pre-producción
- `prod` - Producción
- `ephemeral` - Entornos efímeros por PR (preview environments)

### Restricciones
- Equipos trabajan en paralelo con cambios frecuentes
- El diseño debe ser replicable por cliente
- Estándares consistentes sin bloquear delivery
- Auditoría y trazabilidad end-to-end

## 1.2 Objetivos Medibles (DORA Metrics)

| Métrica | Actual (Estimado) | Objetivo 30 días | Objetivo 90 días |
|---------|-------------------|------------------|------------------|
| Deploy Frequency | 1/semana | 1/día | Múltiples/día |
| Lead Time | Días | Horas | <4 horas |
| Change Failure Rate | >20% | <15% | <10% |
| MTTR | Horas | <1 hora | <30 min |
| Adopción | 0% | 1 equipo piloto | 100% equipos |
| Policy Compliance | N/A | 80% | 95% |

## 1.3 Principios Guía

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         PRINCIPIOS DEL GOLDEN PATH                         │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  🛤️  PAVED ROADS          → Caminos pavimentados, no muros. Facilitar lo   │
│                             correcto, dificultar lo incorrecto.            │
│                                                                             │
│  🔒 SECURE BY DEFAULT     → Seguridad incorporada, no añadida después.     │
│                             Zero Trust desde el diseño.                    │
│                                                                             │
│  📦 BUILD ONCE, PROMOTE   → Artefactos inmutables. Un build, múltiples     │
│                             entornos. Reproducibilidad garantizada.        │
│                                                                             │
│  📝 EVERYTHING AS CODE    → Infra, policies, config, runbooks, docs.       │
│                             Versionado, revisable, auditable.              │
│                                                                             │
│  🔑 LEAST PRIVILEGE       → Permisos mínimos necesarios. Just-in-time      │
│                             donde sea posible.                             │
│                                                                             │
│  🔄 IDEMPOTENCY           → Operaciones repetibles con mismo resultado.    │
│                             Drift detection y reconciliación.              │
│                                                                             │
│  📊 AUDITABILITY          → Trazabilidad completa: quién, qué, cuándo,     │
│                             por qué. Evidencia para compliance.            │
│                                                                             │
│  💻 DEVELOPER EXPERIENCE  → Fricción mínima. Autoservicio. Feedback        │
│                             rápido. Documentación accesible.               │
│                                                                             │
│  📈 MEASURE & IMPROVE     → DORA metrics, SLOs, scorecards.                │
│                             Mejora continua basada en datos.               │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

# PARTE 2: ARQUITECTURA

## 2.1 Diagrama de Arquitectura General

```
                                    GOLDEN PATH ARCHITECTURE
    
    ┌─────────────────────────────────────────────────────────────────────────────┐
    │                              DEVELOPER WORKFLOW                              │
    │  ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐              │
    │  │ Feature  │───▶│Pre-commit│───▶│   Push   │───▶│    PR    │              │
    │  │ Branch   │    │  Hooks   │    │ to Remote│    │ Created  │              │
    │  └──────────┘    └──────────┘    └──────────┘    └──────────┘              │
    └─────────────────────────────────────────────────────────────────────────────┘
                                          │
                                          ▼
    ┌─────────────────────────────────────────────────────────────────────────────┐
    │                               CI PIPELINE                                    │
    │  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────────┐ │
    │  │ Lint │─▶│ Test │─▶│Scan  │─▶│Build │─▶│ Sign │─▶│Publish│─▶│Update    │ │
    │  │Format│  │ Unit │  │ Sec  │  │Image │  │Image │  │Registry│  │GitOps    │ │
    │  └──────┘  └──────┘  └──────┘  └──────┘  └──────┘  └──────┘  └──────────┘ │
    └─────────────────────────────────────────────────────────────────────────────┘
                                          │
                    ┌─────────────────────┼─────────────────────┐
                    ▼                     ▼                     ▼
    ┌─────────────────────┐  ┌─────────────────────┐  ┌─────────────────────┐
    │    POLICY GATES     │  │     COST GATES      │  │   APPROVAL GATES    │
    │  ┌───────────────┐  │  │  ┌───────────────┐  │  │  ┌───────────────┐  │
    │  │ OPA/Conftest  │  │  │  │   Infracost   │  │  │  │ PR Approvals  │  │
    │  │ Checkov/TFSec │  │  │  │ Budget Alerts │  │  │  │ Env Approvals │  │
    │  │  Gatekeeper   │  │  │  │  Tag Checks   │  │  │  │Security Review│  │
    │  └───────────────┘  │  │  └───────────────┘  │  │  └───────────────┘  │
    └─────────────────────┘  └─────────────────────┘  └─────────────────────┘
                                          │
                                          ▼
    ┌─────────────────────────────────────────────────────────────────────────────┐
    │                              GITOPS (ARGO CD)                                │
    │  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐                   │
    │  │  GitOps Repo │───▶│   Argo CD    │───▶│    Sync      │                   │
    │  │ (Config)     │    │ApplicationSet│    │  to Cluster  │                   │
    │  └──────────────┘    └──────────────┘    └──────────────┘                   │
    └─────────────────────────────────────────────────────────────────────────────┘
                                          │
                    ┌─────────────────────┼─────────────────────┐
                    ▼                     ▼                     ▼
    ┌─────────────────────┐  ┌─────────────────────┐  ┌─────────────────────┐
    │        DEV          │  │      STAGING        │  │     PRODUCTION      │
    │  ┌───────────────┐  │  │  ┌───────────────┐  │  │  ┌───────────────┐  │
    │  │  Auto Sync    │  │  │  │  Auto Sync    │  │  │  │ Manual Sync   │  │
    │  │  Auto Prune   │  │  │  │  No Prune     │  │  │  │ No Prune      │  │
    │  └───────────────┘  │  │  └───────────────┘  │  │  └───────────────┘  │
    └─────────────────────┘  └─────────────────────┘  └─────────────────────┘
                                          │
                                          ▼
    ┌─────────────────────────────────────────────────────────────────────────────┐
    │                            OBSERVABILITY STACK                               │
    │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐      │
    │  │Prometheus│  │  Grafana │  │   Loki   │  │  Tempo   │  │Alertmgr  │      │
    │  │ Metrics  │  │Dashboards│  │   Logs   │  │  Traces  │  │  Alerts  │      │
    │  └──────────┘  └──────────┘  └──────────┘  └──────────┘  └──────────┘      │
    └─────────────────────────────────────────────────────────────────────────────┘
```

## 2.2 Flujo de Promoción de Artefactos

```
    ARTIFACT PROMOTION FLOW
    
    ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐
    │  Code   │───▶│  Build  │───▶│Registry │───▶│  Dev    │───▶│ Staging │
    │ Commit  │    │  Once   │    │ (Immut) │    │ Deploy  │    │ Promote │
    └─────────┘    └─────────┘    └─────────┘    └─────────┘    └─────────┘
         │              │              │              │              │
         ▼              ▼              ▼              ▼              ▼
    ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐
    │ SHA/Tag │    │ Sign &  │    │ Scan &  │    │ Auto    │    │ Manual  │
    │         │    │ Verify  │    │ Verify  │    │ Tests   │    │ Approve │
    └─────────┘    └─────────┘    └─────────┘    └─────────┘    └─────────┘
                                                                     │
                                                                     ▼
                                                               ┌─────────┐
                                                               │  Prod   │
                                                               │ Deploy  │
                                                               └─────────┘
    
    ARTIFACT NAMING: {service}-{semver}-{sha}-{timestamp}
    EXAMPLE: api-gateway-v1.2.3-abc1234-20240115T1030Z
```

---

# PARTE 3: ESTRUCTURA DE REPOSITORIOS

## 3.1 Estrategia de Repositorios (Híbrida)

```
    REPOSITORY STRATEGY
    
    CENTRALIZED (Platform Team)           DISTRIBUTED (Product Teams)
    ─────────────────────────────         ─────────────────────────────
    
    ┌─────────────────────────┐           ┌─────────────────────────┐
    │ terraform-modules       │           │ team-{name}-infra       │
    │ (Official Modules)      │           │ (Team Stacks)           │
    └─────────────────────────┘           └─────────────────────────┘
    
    ┌─────────────────────────┐           ┌─────────────────────────┐
    │ platform-policies       │           │ team-{name}-apps        │
    │ (Guardrails)            │           │ (Application Code)      │
    └─────────────────────────┘           └─────────────────────────┘
    
    ┌─────────────────────────┐           ┌─────────────────────────┐
    │ gitops-platform         │           │ team-{name}-gitops      │
    │ (Core Infra Config)     │           │ (Team App Config)       │
    └─────────────────────────┘           └─────────────────────────┘
    
    ┌─────────────────────────┐
    │ service-templates       │           CLIENTE/TENANT
    │ (Golden Templates)      │           ─────────────────────────────
    └─────────────────────────┘           
                                          ┌─────────────────────────┐
    ┌─────────────────────────┐           │ client-{name}-platform  │
    │ platform-docs           │           │ (Client-specific)       │
    │ (ADRs, Runbooks)        │           └─────────────────────────┘
    └─────────────────────────┘
```

## 3.2 Repositorio: terraform-modules

**GENERA ESTA ESTRUCTURA COMPLETA:**

```
terraform-modules/
├── .github/
│   ├── workflows/
│   │   ├── ci.yaml                    # Lint, test, validate on PR
│   │   ├── release.yaml               # SemVer release on merge
│   │   └── docs.yaml                  # Auto-generate docs
│   ├── CODEOWNERS
│   └── pull_request_template.md
├── .pre-commit-config.yaml
├── .tflint.hcl
├── .terraform-docs.yaml
│
├── modules/
│   ├── networking/
│   │   ├── vpc/
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   ├── outputs.tf
│   │   │   ├── versions.tf
│   │   │   ├── README.md              # Auto-generated
│   │   │   ├── CHANGELOG.md
│   │   │   ├── examples/
│   │   │   │   ├── basic/
│   │   │   │   │   ├── main.tf
│   │   │   │   │   └── README.md
│   │   │   │   └── advanced/
│   │   │   │       ├── main.tf
│   │   │   │       └── README.md
│   │   │   └── tests/
│   │   │       ├── unit/
│   │   │       │   └── vpc_test.tftest.hcl
│   │   │       └── integration/
│   │   │           └── vpc_integration_test.go
│   │   ├── subnets/
│   │   ├── security-groups/
│   │   └── load-balancer/
│   │
│   ├── compute/
│   │   ├── kubernetes-cluster/
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   ├── outputs.tf
│   │   │   ├── versions.tf
│   │   │   ├── providers/
│   │   │   │   ├── aws.tf             # EKS specific
│   │   │   │   ├── azure.tf           # AKS specific
│   │   │   │   └── gcp.tf             # GKE specific
│   │   │   ├── README.md
│   │   │   └── tests/
│   │   ├── vm-instance/
│   │   └── serverless-function/
│   │
│   ├── storage/
│   │   ├── object-storage/            # S3/Blob/GCS
│   │   ├── database/                  # RDS/Azure SQL/Cloud SQL
│   │   └── cache/                     # ElastiCache/Redis
│   │
│   ├── security/
│   │   ├── iam-role/
│   │   ├── kms-key/
│   │   └── waf/
│   │
│   ├── observability/
│   │   ├── logging/
│   │   ├── monitoring/
│   │   └── alerting/
│   │
│   └── data/
│       ├── data-lake/
│       ├── data-warehouse/
│       └── streaming/
│
├── patterns/                          # Composable patterns
│   ├── three-tier-app/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── README.md
│   ├── data-pipeline/
│   └── api-gateway-pattern/
│
├── docs/
│   ├── CONTRIBUTING.md
│   ├── MODULE_STANDARDS.md
│   ├── VERSIONING.md
│   ├── DEPRECATION_POLICY.md
│   └── architecture-decisions/
│       ├── ADR-001-module-structure.md
│       └── ADR-002-testing-strategy.md
│
├── scripts/
│   ├── generate-docs.sh
│   ├── validate-all.sh
│   └── release.sh
│
├── CHANGELOG.md
├── VERSION
└── README.md
```

## 3.3 Repositorio: platform-stacks

**GENERA ESTA ESTRUCTURA COMPLETA:**

```
platform-stacks/
├── .github/
│   ├── workflows/
│   │   ├── terraform-pr.yaml          # Plan on PR
│   │   ├── terraform-apply.yaml       # Apply on merge
│   │   └── drift-detection.yaml       # Scheduled drift check
│   └── CODEOWNERS
├── .pre-commit-config.yaml
│
├── _templates/                        # Stack templates
│   ├── client-bootstrap/
│   │   ├── main.tf.tmpl
│   │   ├── backend.tf.tmpl
│   │   └── README.md
│   └── environment/
│       ├── main.tf.tmpl
│       └── terraform.tfvars.tmpl
│
├── shared/                            # Shared configurations
│   ├── backend-configs/
│   │   ├── aws.hcl
│   │   ├── azure.hcl
│   │   └── gcp.hcl
│   ├── provider-configs/
│   │   ├── aws.tf
│   │   ├── azure.tf
│   │   └── gcp.tf
│   └── common-variables.tf
│
├── clients/
│   ├── client-acme/                   # Client: ACME Corp
│   │   ├── _client.yaml               # Client metadata
│   │   ├── bootstrap/                 # One-time setup
│   │   │   ├── main.tf                # State bucket, IAM bootstrap
│   │   │   ├── backend.tf
│   │   │   └── outputs.tf
│   │   │
│   │   ├── foundation/                # Core infrastructure
│   │   │   ├── networking/
│   │   │   │   ├── main.tf
│   │   │   │   ├── backend.tf
│   │   │   │   ├── variables.tf
│   │   │   │   └── terraform.tfvars
│   │   │   ├── security/
│   │   │   └── observability/
│   │   │
│   │   └── environments/
│   │       ├── dev/
│   │       │   ├── main.tf
│   │       │   ├── backend.tf
│   │       │   ├── variables.tf
│   │       │   ├── terraform.tfvars
│   │       │   └── _env.yaml          # Env metadata
│   │       ├── staging/
│   │       │   ├── main.tf
│   │       │   ├── backend.tf
│   │       │   └── terraform.tfvars
│   │       └── prod/
│   │           ├── main.tf
│   │           ├── backend.tf
│   │           └── terraform.tfvars
│   │
│   └── client-beta/                   # Client: Beta Inc
│       └── ...
│
├── teams/                             # Team-specific stacks
│   ├── team-payments/
│   │   ├── services/
│   │   │   ├── payment-api/
│   │   │   │   ├── dev/
│   │   │   │   ├── staging/
│   │   │   │   └── prod/
│   │   │   └── payment-processor/
│   │   └── data/
│   │       └── payment-analytics/
│   │
│   └── team-orders/
│       └── ...
│
├── ephemeral/                         # PR/Preview environments
│   ├── _template/
│   │   ├── main.tf
│   │   └── variables.tf
│   └── .gitkeep
│
├── scripts/
│   ├── init-client.sh
│   ├── init-environment.sh
│   ├── cleanup-ephemeral.sh
│   └── drift-report.sh
│
└── README.md
```

## 3.4 Repositorio: gitops-config

**GENERA ESTA ESTRUCTURA COMPLETA:**

```
gitops-config/
├── .github/
│   ├── workflows/
│   │   ├── validate.yaml              # Validate manifests
│   │   ├── promote.yaml               # Promotion workflow
│   │   └── sync-status.yaml           # Check sync status
│   └── CODEOWNERS
│
├── argocd/                            # Argo CD configuration
│   ├── projects/
│   │   ├── platform.yaml
│   │   ├── team-payments.yaml
│   │   └── team-orders.yaml
│   ├── applicationsets/
│   │   ├── platform-apps.yaml
│   │   ├── team-apps.yaml
│   │   └── preview-envs.yaml
│   └── repository-credentials.yaml
│
├── clusters/                          # Cluster-level config
│   ├── dev/
│   │   ├── cluster-config.yaml
│   │   └── namespaces.yaml
│   ├── staging/
│   │   ├── cluster-config.yaml
│   │   └── namespaces.yaml
│   └── prod/
│       ├── cluster-config.yaml
│       └── namespaces.yaml
│
├── platform/                          # Platform components
│   ├── base/
│   │   ├── cert-manager/
│   │   │   ├── kustomization.yaml
│   │   │   ├── namespace.yaml
│   │   │   └── release.yaml
│   │   ├── external-secrets/
│   │   ├── ingress-nginx/
│   │   ├── prometheus-stack/
│   │   ├── loki/
│   │   ├── tempo/
│   │   └── gatekeeper/
│   │
│   └── overlays/
│       ├── dev/
│       │   └── kustomization.yaml
│       ├── staging/
│       │   └── kustomization.yaml
│       └── prod/
│           └── kustomization.yaml
│
├── apps/                              # Application deployments
│   ├── team-payments/
│   │   ├── payment-api/
│   │   │   ├── base/
│   │   │   │   ├── kustomization.yaml
│   │   │   │   ├── deployment.yaml
│   │   │   │   ├── service.yaml
│   │   │   │   ├── hpa.yaml
│   │   │   │   ├── pdb.yaml
│   │   │   │   └── servicemonitor.yaml
│   │   │   └── overlays/
│   │   │       ├── dev/
│   │   │       │   ├── kustomization.yaml
│   │   │       │   ├── replica-patch.yaml
│   │   │       │   └── image-patch.yaml
│   │   │       ├── staging/
│   │   │       │   ├── kustomization.yaml
│   │   │       │   └── image-patch.yaml
│   │   │       └── prod/
│   │   │           ├── kustomization.yaml
│   │   │           ├── image-patch.yaml
│   │   │           └── resource-patch.yaml
│   │   └── payment-processor/
│   │
│   └── team-orders/
│       └── ...
│
├── policies/                          # OPA Gatekeeper policies
│   ├── constraints/
│   │   ├── required-labels.yaml
│   │   ├── container-limits.yaml
│   │   └── no-privileged.yaml
│   └── constraint-templates/
│       └── k8srequiredlabels.yaml
│
├── scripts/
│   ├── promote.sh                     # Promote version to env
│   ├── rollback.sh                    # Git revert rollback
│   └── validate-manifests.sh
│
├── docs/
│   ├── PROMOTION_GUIDE.md
│   └── ROLLBACK_PROCEDURE.md
│
└── README.md
```

## 3.5 Repositorio: service-templates

**GENERA ESTA ESTRUCTURA COMPLETA:**

```
service-templates/
├── .github/
│   └── workflows/
│       └── validate-templates.yaml
│
├── templates/
│   ├── microservice-golang/
│   │   ├── copier.yaml                # Template config
│   │   ├── {{project_name}}/
│   │   │   ├── .github/
│   │   │   │   └── workflows/
│   │   │   │       └── ci.yaml.jinja
│   │   │   ├── cmd/
│   │   │   │   └── main.go.jinja
│   │   │   ├── internal/
│   │   │   ├── pkg/
│   │   │   ├── Dockerfile
│   │   │   ├── go.mod.jinja
│   │   │   ├── Makefile
│   │   │   └── README.md.jinja
│   │   └── README.md
│   │
│   ├── microservice-python/
│   │   ├── copier.yaml
│   │   └── {{project_name}}/
│   │       ├── .github/workflows/
│   │       ├── src/
│   │       ├── tests/
│   │       ├── Dockerfile
│   │       ├── pyproject.toml.jinja
│   │       └── README.md.jinja
│   │
│   ├── data-pipeline/
│   │   ├── copier.yaml
│   │   └── {{project_name}}/
│   │       ├── dags/
│   │       ├── src/
│   │       ├── tests/
│   │       └── README.md.jinja
│   │
│   └── terraform-stack/
│       ├── copier.yaml
│       └── {{project_name}}/
│           ├── main.tf.jinja
│           ├── variables.tf.jinja
│           ├── backend.tf.jinja
│           └── README.md.jinja
│
├── shared/
│   ├── pre-commit-config.yaml         # Standard pre-commit
│   ├── gitignore                      # Standard gitignore
│   └── editorconfig                   # Editor config
│
├── docs/
│   ├── TEMPLATE_GUIDE.md
│   └── CUSTOMIZATION.md
│
├── scripts/
│   ├── create-service.sh              # CLI wrapper
│   └── validate-template.sh
│
└── README.md
```

---

# PARTE 4: TERRAFORM/IaC ROBUSTO

## 4.1 Backend Configuration (Cloud-Agnostic)

### AWS Backend (shared/backend-configs/aws.hcl)
```hcl
bucket         = "client-${client_name}-terraform-state"
key            = "${project}/${stack}/${environment}/terraform.tfstate"
region         = "us-east-1"
encrypt        = true
dynamodb_table = "client-${client_name}-terraform-locks"
```

### Azure Backend (shared/backend-configs/azure.hcl)
```hcl
resource_group_name  = "rg-${client_name}-terraform"
storage_account_name = "st${client_name}tfstate"
container_name       = "tfstate"
key                  = "${project}/${stack}/${environment}/terraform.tfstate"
```

### GCP Backend (shared/backend-configs/gcp.hcl)
```hcl
bucket = "client-${client_name}-terraform-state"
prefix = "${project}/${stack}/${environment}"
```

## 4.2 Module Standard Template

### versions.tf
```hcl
terraform {
  required_version = ">= 1.5.0, < 2.0.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0, < 6.0.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0.0, < 4.0.0"
    }
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0.0, < 6.0.0"
    }
  }
}
```

### variables.tf (Example for VPC module)
```hcl
variable "name" {
  description = "Name of the VPC"
  type        = string
  
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,28}[a-z0-9]$", var.name))
    error_message = "Name must be 4-30 chars, lowercase alphanumeric with hyphens."
  }
}

variable "cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  
  validation {
    condition     = can(cidrhost(var.cidr_block, 0))
    error_message = "Must be a valid CIDR block."
  }
}

variable "environment" {
  description = "Environment name"
  type        = string
  
  validation {
    condition     = contains(["dev", "staging", "prod", "ephemeral"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod, ephemeral."
  }
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
  
  validation {
    condition     = contains(keys(var.tags), "Team") && contains(keys(var.tags), "CostCenter")
    error_message = "Tags must include 'Team' and 'CostCenter'."
  }
}

variable "enable_flow_logs" {
  description = "Enable VPC flow logs"
  type        = bool
  default     = true  # Secure by default
}

variable "cloud_provider" {
  description = "Cloud provider to use"
  type        = string
  
  validation {
    condition     = contains(["aws", "azure", "gcp"], var.cloud_provider)
    error_message = "Cloud provider must be one of: aws, azure, gcp."
  }
}
```

### main.tf (Cloud-Agnostic VPC Example)
```hcl
locals {
  common_tags = merge(
    var.tags,
    {
      Module      = "networking/vpc"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  )
}

# AWS Implementation
resource "aws_vpc" "this" {
  count = var.cloud_provider == "aws" ? 1 : 0
  
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = merge(local.common_tags, { Name = var.name })
  
  lifecycle {
    prevent_destroy = var.environment == "prod"
  }
}

# Azure Implementation
resource "azurerm_virtual_network" "this" {
  count = var.cloud_provider == "azure" ? 1 : 0
  
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = [var.cidr_block]
  
  tags = local.common_tags
  
  lifecycle {
    prevent_destroy = var.environment == "prod"
  }
}

# GCP Implementation
resource "google_compute_network" "this" {
  count = var.cloud_provider == "gcp" ? 1 : 0
  
  name                    = var.name
  auto_create_subnetworks = false
  
  lifecycle {
    prevent_destroy = var.environment == "prod"
  }
}
```

## 4.3 Native Terraform Testing

### vpc_test.tftest.hcl
```hcl
variables {
  name           = "test-vpc"
  cidr_block     = "10.0.0.0/16"
  environment    = "dev"
  cloud_provider = "aws"
  tags = {
    Team       = "platform"
    CostCenter = "cc-001"
  }
}

run "vpc_creates_successfully" {
  command = plan
  
  assert {
    condition     = aws_vpc.this[0].cidr_block == "10.0.0.0/16"
    error_message = "VPC CIDR block does not match expected value"
  }
  
  assert {
    condition     = aws_vpc.this[0].enable_dns_hostnames == true
    error_message = "DNS hostnames should be enabled"
  }
}

run "vpc_has_required_tags" {
  command = plan
  
  assert {
    condition     = contains(keys(aws_vpc.this[0].tags), "Environment")
    error_message = "VPC must have Environment tag"
  }
  
  assert {
    condition     = contains(keys(aws_vpc.this[0].tags), "ManagedBy")
    error_message = "VPC must have ManagedBy tag"
  }
}

run "invalid_name_fails_validation" {
  command = plan
  
  variables {
    name = "INVALID_NAME"  # Uppercase not allowed
  }
  
  expect_failures = [var.name]
}
```

---

# PARTE 5: PIPELINE CI/CD ESTÁNDAR

## 5.1 Terraform Pipeline (GitHub Actions)

### .github/workflows/terraform-pipeline.yaml
```yaml
name: Terraform Pipeline

on:
  pull_request:
    branches: [main]
    paths:
      - 'clients/**'
      - 'teams/**'
  push:
    branches: [main]
    paths:
      - 'clients/**'
      - 'teams/**'

concurrency:
  group: terraform-${{ github.event.pull_request.number || github.ref }}
  cancel-in-progress: false

env:
  TF_VERSION: "1.6.0"
  TF_IN_AUTOMATION: "true"
  
permissions:
  id-token: write      # OIDC
  contents: read
  pull-requests: write
  issues: write

jobs:
  # ============================================
  # DETECT CHANGES
  # ============================================
  detect-changes:
    runs-on: ubuntu-latest
    outputs:
      stacks: ${{ steps.changes.outputs.stacks }}
      has_changes: ${{ steps.changes.outputs.has_changes }}
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      
      - name: Detect Changed Stacks
        id: changes
        run: |
          if [ "${{ github.event_name }}" == "pull_request" ]; then
            CHANGED_FILES=$(git diff --name-only origin/main..HEAD)
          else
            CHANGED_FILES=$(git diff --name-only HEAD~1..HEAD)
          fi
          
          STACKS=$(echo "$CHANGED_FILES" | \
            grep -E "^(clients|teams)/" | \
            xargs -I {} dirname {} | \
            sort -u | \
            jq -R -s -c 'split("\n") | map(select(length > 0))')
          
          echo "stacks=$STACKS" >> $GITHUB_OUTPUT
          echo "has_changes=$([ -n "$STACKS" ] && echo 'true' || echo 'false')" >> $GITHUB_OUTPUT

  # ============================================
  # LINT & VALIDATE
  # ============================================
  lint-validate:
    needs: detect-changes
    if: needs.detect-changes.outputs.has_changes == 'true'
    runs-on: ubuntu-latest
    strategy:
      matrix:
        stack: ${{ fromJson(needs.detect-changes.outputs.stacks) }}
      fail-fast: false
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TF_VERSION }}
      
      - name: Terraform Format Check
        run: terraform fmt -check -recursive -diff
        working-directory: ${{ matrix.stack }}
      
      - name: TFLint
        uses: terraform-linters/setup-tflint@v4
      - run: |
          tflint --init
          tflint --recursive
        working-directory: ${{ matrix.stack }}
      
      - name: Terraform Validate
        run: |
          terraform init -backend=false
          terraform validate
        working-directory: ${{ matrix.stack }}

  # ============================================
  # SECURITY SCAN
  # ============================================
  security-scan:
    needs: [detect-changes, lint-validate]
    runs-on: ubuntu-latest
    strategy:
      matrix:
        stack: ${{ fromJson(needs.detect-changes.outputs.stacks) }}
    steps:
      - uses: actions/checkout@v4
      
      - name: Checkov Scan
        uses: bridgecrewio/checkov-action@v12
        with:
          directory: ${{ matrix.stack }}
          framework: terraform
          output_format: sarif
          output_file_path: checkov-results.sarif
          soft_fail: false
      
      - name: TFSec Scan
        uses: aquasecurity/tfsec-action@v1.0.3
        with:
          working_directory: ${{ matrix.stack }}
          soft_fail: false

  # ============================================
  # POLICY CHECK (OPA)
  # ============================================
  policy-check:
    needs: [detect-changes, security-scan]
    runs-on: ubuntu-latest
    strategy:
      matrix:
        stack: ${{ fromJson(needs.detect-changes.outputs.stacks) }}
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Conftest
        run: |
          wget -q https://github.com/open-policy-agent/conftest/releases/download/v0.45.0/conftest_0.45.0_Linux_x86_64.tar.gz
          tar xzf conftest_0.45.0_Linux_x86_64.tar.gz
          sudo mv conftest /usr/local/bin/
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TF_VERSION }}
          terraform_wrapper: false
      
      - name: Generate Plan JSON
        run: |
          terraform init
          terraform plan -out=tfplan
          terraform show -json tfplan > tfplan.json
        working-directory: ${{ matrix.stack }}
      
      - name: Run Policy Checks
        run: |
          conftest test ${{ matrix.stack }}/tfplan.json \
            --policy policies/ \
            --output json \
            --all-namespaces

  # ============================================
  # COST ESTIMATION
  # ============================================
  cost-estimate:
    needs: [detect-changes, policy-check]
    runs-on: ubuntu-latest
    strategy:
      matrix:
        stack: ${{ fromJson(needs.detect-changes.outputs.stacks) }}
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Infracost
        uses: infracost/actions/setup@v3
        with:
          api-key: ${{ secrets.INFRACOST_API_KEY }}
      
      - name: Generate Cost Estimate
        run: |
          infracost breakdown --path ${{ matrix.stack }} \
            --format json \
            --out-file infracost.json
      
      - name: Post Cost Comment
        if: github.event_name == 'pull_request'
        run: |
          infracost comment github \
            --path infracost.json \
            --repo ${{ github.repository }} \
            --github-token ${{ secrets.GITHUB_TOKEN }} \
            --pull-request ${{ github.event.pull_request.number }} \
            --behavior update

  # ============================================
  # TERRAFORM PLAN (PR)
  # ============================================
  terraform-plan:
    needs: [detect-changes, cost-estimate]
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    strategy:
      matrix:
        stack: ${{ fromJson(needs.detect-changes.outputs.stacks) }}
      max-parallel: 1
    steps:
      - uses: actions/checkout@v4
      
      - name: Configure Cloud Credentials (OIDC)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          aws-region: us-east-1
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TF_VERSION }}
      
      - name: Terraform Init
        run: terraform init
        working-directory: ${{ matrix.stack }}
      
      - name: Terraform Plan
        id: plan
        run: |
          terraform plan -no-color -out=tfplan 2>&1 | tee plan.txt
        working-directory: ${{ matrix.stack }}
        continue-on-error: true
      
      - name: Upload Plan Artifact
        uses: actions/upload-artifact@v4
        with:
          name: tfplan-${{ hashFiles(matrix.stack) }}
          path: ${{ matrix.stack }}/tfplan
          retention-days: 5

  # ============================================
  # TERRAFORM APPLY (Main Branch)
  # ============================================
  terraform-apply:
    needs: [detect-changes, cost-estimate]
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment: 
      name: ${{ contains(matrix.stack, 'prod') && 'production' || 'staging' }}
    strategy:
      matrix:
        stack: ${{ fromJson(needs.detect-changes.outputs.stacks) }}
      max-parallel: 1
    steps:
      - uses: actions/checkout@v4
      
      - name: Configure Cloud Credentials (OIDC)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          aws-region: us-east-1
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TF_VERSION }}
      
      - name: Terraform Init
        run: terraform init
        working-directory: ${{ matrix.stack }}
      
      - name: Terraform Apply
        run: terraform apply -auto-approve -input=false
        working-directory: ${{ matrix.stack }}
        timeout-minutes: 30
```

## 5.2 Application CI/CD Pipeline

### .github/workflows/application-pipeline.yaml
```yaml
name: Application Pipeline

on:
  push:
    branches: [main, 'release/**']
  pull_request:
    branches: [main]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

permissions:
  contents: read
  packages: write
  id-token: write
  security-events: write

jobs:
  build-test:
    runs-on: ubuntu-latest
    outputs:
      version: ${{ steps.version.outputs.version }}
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      
      - name: Calculate Version
        id: version
        run: |
          if [[ "${{ github.ref }}" == refs/tags/* ]]; then
            VERSION=${GITHUB_REF#refs/tags/v}
          else
            VERSION=$(git describe --tags --always --dirty)-${{ github.sha }}
          fi
          echo "version=$VERSION" >> $GITHUB_OUTPUT
      
      - name: Setup Go
        uses: actions/setup-go@v5
        with:
          go-version-file: 'go.mod'
          cache: true
      
      - name: Lint
        uses: golangci/golangci-lint-action@v4
      
      - name: Test
        run: |
          go test -v -race -coverprofile=coverage.out ./...

  security-scan:
    needs: build-test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: SAST - Semgrep
        uses: returntocorp/semgrep-action@v1
        with:
          config: p/golang
      
      - name: Dependency Scan
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'fs'
          format: 'sarif'
          output: 'trivy-results.sarif'

  build-image:
    needs: [build-test, security-scan]
    runs-on: ubuntu-latest
    outputs:
      digest: ${{ steps.build.outputs.digest }}
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Docker Buildx
        uses: docker/setup-buildx-action@v3
      
      - name: Login to Registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Build and Push
        id: build
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ needs.build-test.outputs.version }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
      
      - name: Sign Image (Cosign)
        if: github.event_name != 'pull_request'
        env:
          COSIGN_EXPERIMENTAL: 1
        run: |
          cosign sign --yes ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}@${{ steps.build.outputs.digest }}

  update-gitops:
    needs: [build-image]
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - name: Checkout GitOps Repo
        uses: actions/checkout@v4
        with:
          repository: org/gitops-config
          token: ${{ secrets.GITOPS_TOKEN }}
          path: gitops
      
      - name: Update Image Tag
        run: |
          SERVICE_NAME=$(echo ${{ github.repository }} | cut -d'/' -f2)
          IMAGE_DIGEST=${{ needs.build-image.outputs.digest }}
          
          cd gitops/apps/team-${{ github.repository_owner }}/$SERVICE_NAME/overlays/dev
          
          cat > kustomization.yaml << EOF
          apiVersion: kustomize.config.k8s.io/v1beta1
          kind: Kustomization
          resources:
            - ../../base
          images:
            - name: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
              digest: $IMAGE_DIGEST
          EOF
      
      - name: Commit and Push
        run: |
          cd gitops
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git add .
          git commit -m "chore: update ${{ github.repository }} to ${{ github.sha }}"
          git push
```

---

# PARTE 6: GITOPS Y PROMOCIÓN

## 6.1 Argo CD ApplicationSet

### argocd/applicationsets/team-apps.yaml
```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: team-applications
  namespace: argocd
spec:
  goTemplate: true
  goTemplateOptions: ["missingkey=error"]
  generators:
    - matrix:
        generators:
          - list:
              elements:
                - team: payments
                  repo: git@github.com:org/team-payments-gitops.git
                - team: orders
                  repo: git@github.com:org/team-orders-gitops.git
          - list:
              elements:
                - env: dev
                  cluster: https://dev-cluster.example.com
                  autoSync: true
                  prune: true
                - env: staging
                  cluster: https://staging-cluster.example.com
                  autoSync: true
                  prune: false
                - env: prod
                  cluster: https://prod-cluster.example.com
                  autoSync: false
                  prune: false
  template:
    metadata:
      name: '{{.team}}-{{.env}}'
      labels:
        team: '{{.team}}'
        environment: '{{.env}}'
    spec:
      project: '{{.team}}'
      source:
        repoURL: '{{.repo}}'
        targetRevision: HEAD
        path: 'apps/overlays/{{.env}}'
      destination:
        server: '{{.cluster}}'
        namespace: '{{.team}}-{{.env}}'
      syncPolicy:
        automated:
          prune: '{{.prune}}'
          selfHeal: true
        syncOptions:
          - CreateNamespace=true
          - PrunePropagationPolicy=foreground
        retry:
          limit: 5
          backoff:
            duration: 5s
            factor: 2
            maxDuration: 3m
```

## 6.2 Kubernetes Base Manifests

### apps/team-payments/payment-api/base/deployment.yaml
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: payment-api
  labels:
    app.kubernetes.io/name: payment-api
    app.kubernetes.io/component: api
    app.kubernetes.io/part-of: payments
spec:
  replicas: 2
  selector:
    matchLabels:
      app.kubernetes.io/name: payment-api
  template:
    metadata:
      labels:
        app.kubernetes.io/name: payment-api
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8080"
        prometheus.io/path: "/metrics"
    spec:
      serviceAccountName: payment-api
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 1000
      containers:
        - name: payment-api
          image: ghcr.io/org/payment-api:latest
          ports:
            - name: http
              containerPort: 8080
            - name: metrics
              containerPort: 9090
          env:
            - name: LOG_LEVEL
              value: "info"
            - name: OTEL_EXPORTER_OTLP_ENDPOINT
              value: "http://tempo.observability:4317"
          envFrom:
            - secretRef:
                name: payment-api-secrets
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
            limits:
              cpu: 500m
              memory: 512Mi
          securityContext:
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            capabilities:
              drop:
                - ALL
          livenessProbe:
            httpGet:
              path: /health
              port: http
            initialDelaySeconds: 10
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /ready
              port: http
            initialDelaySeconds: 5
            periodSeconds: 5
          volumeMounts:
            - name: tmp
              mountPath: /tmp
      volumes:
        - name: tmp
          emptyDir: {}
```

### apps/team-payments/payment-api/base/hpa.yaml
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: payment-api
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: payment-api
  minReplicas: 2
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 80
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
        - type: Percent
          value: 10
          periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
        - type: Percent
          value: 100
          periodSeconds: 15
        - type: Pods
          value: 4
          periodSeconds: 15
      selectPolicy: Max
```

### apps/team-payments/payment-api/base/pdb.yaml
```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: payment-api
spec:
  minAvailable: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: payment-api
```

---

# PARTE 7: SEGURIDAD BY DEFAULT

## 7.1 OIDC Federation (AWS)

### modules/security/github-oidc/main.tf
```hcl
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
  
  client_id_list = ["sts.amazonaws.com"]
  
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]
  
  tags = var.tags
}

resource "aws_iam_role" "github_actions" {
  name = "${var.project}-github-actions-${var.environment}"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/*:*"
          }
        }
      }
    ]
  })
  
  tags = var.tags
}
```

## 7.2 External Secrets Configuration

### platform/base/external-secrets/cluster-secret-store.yaml
```yaml
apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: vault-backend
spec:
  provider:
    vault:
      server: "https://vault.internal.example.com"
      path: "secret"
      version: "v2"
      auth:
        kubernetes:
          mountPath: "kubernetes"
          role: "external-secrets"
          serviceAccountRef:
            name: "external-secrets"
            namespace: "external-secrets"
---
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: api-credentials
  namespace: payments-api-prod
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: vault-backend
    kind: ClusterSecretStore
  target:
    name: api-credentials
    creationPolicy: Owner
  data:
    - secretKey: database_url
      remoteRef:
        key: payments/prod/database
        property: url
    - secretKey: api_key
      remoteRef:
        key: payments/prod/api
        property: key
```

---

# PARTE 8: GUARDRAILS Y POLICIES

## 8.1 OPA/Conftest Policies

### policies/terraform/deny_public_access.rego
```rego
package terraform.security

import future.keywords.in

# Deny public S3 buckets
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket"
    resource.change.after.acl == "public-read"
    msg := sprintf("S3 bucket '%s' must not be public", [resource.address])
}

deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket_public_access_block"
    resource.change.after.block_public_acls == false
    msg := sprintf("S3 bucket '%s' must block public ACLs", [resource.address])
}

# Deny 0.0.0.0/0 ingress on sensitive ports
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_security_group_rule"
    resource.change.after.type == "ingress"
    resource.change.after.cidr_blocks[_] == "0.0.0.0/0"
    sensitive_port(resource.change.after.from_port)
    msg := sprintf("Security group rule '%s' allows 0.0.0.0/0 on sensitive port %v", 
                   [resource.address, resource.change.after.from_port])
}

sensitive_port(port) {
    port in [22, 3389, 3306, 5432, 27017, 6379, 9200]
}

# Deny IAM policies with wildcards
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_iam_policy"
    policy := json.unmarshal(resource.change.after.policy)
    statement := policy.Statement[_]
    statement.Effect == "Allow"
    statement.Action[_] == "*"
    msg := sprintf("IAM policy '%s' contains wildcard actions", [resource.address])
}

# Deny unencrypted resources
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_ebs_volume"
    not resource.change.after.encrypted
    msg := sprintf("EBS volume '%s' must be encrypted", [resource.address])
}

deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_rds_cluster"
    not resource.change.after.storage_encrypted
    msg := sprintf("RDS cluster '%s' must have storage encryption enabled", [resource.address])
}

# Require tags
deny[msg] {
    resource := input.resource_changes[_]
    requires_tags(resource.type)
    tags := object.get(resource.change.after, "tags", {})
    required := {"Environment", "Team", "CostCenter", "Owner"}
    missing := required - {k | tags[k]}
    count(missing) > 0
    msg := sprintf("Resource '%s' is missing required tags: %v", [resource.address, missing])
}

requires_tags(type) {
    taggable_types := {
        "aws_instance", "aws_vpc", "aws_subnet", "aws_security_group",
        "aws_rds_instance", "aws_rds_cluster", "aws_s3_bucket", "aws_lambda_function"
    }
    type in taggable_types
}
```

### policies/kubernetes/workload_security.rego
```rego
package kubernetes.workload

import future.keywords.in

# Deny privileged containers
deny[msg] {
    input.kind == "Pod"
    container := input.spec.containers[_]
    container.securityContext.privileged
    msg := sprintf("Container '%s' must not run as privileged", [container.name])
}

# Deny hostNetwork
deny[msg] {
    input.kind == "Pod"
    input.spec.hostNetwork
    msg := "Pods must not use hostNetwork"
}

# Require resource limits
deny[msg] {
    input.kind == "Pod"
    container := input.spec.containers[_]
    not container.resources.limits.memory
    msg := sprintf("Container '%s' must have memory limits", [container.name])
}

deny[msg] {
    input.kind == "Pod"
    container := input.spec.containers[_]
    not container.resources.limits.cpu
    msg := sprintf("Container '%s' must have CPU limits", [container.name])
}

# Deny latest tag
deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    endswith(container.image, ":latest")
    msg := sprintf("Container '%s' must not use 'latest' tag", [container.name])
}

# Require probes
warn[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not container.livenessProbe
    msg := sprintf("Container '%s' should have a liveness probe", [container.name])
}

warn[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not container.readinessProbe
    msg := sprintf("Container '%s' should have a readiness probe", [container.name])
}
```

## 8.2 Policy Execution Matrix

```
    POLICY EXECUTION MATRIX
    
    STAGE              TOOL              POLICIES                  ACTION
    ─────              ────              ────────                  ──────
    
    Local/Pre-commit   pre-commit        - fmt/lint                Block
                       tflint            - syntax                  Block
                       checkov           - basic security          Warn
    
    PR (CI)            conftest          - all deny rules          Block
                       checkov           - full scan               Block
                       tfsec             - security scan           Block
                       infracost         - cost threshold          Warn
    
    Merge (CD)         terraform plan    - re-validate             Block
                       policy-bot        - approval matrix         Block
    
    Runtime            Gatekeeper        - admission control       Block
                       Falco             - runtime security        Alert
                       OPA               - authorization           Block
    
    Scheduled          drift-detector    - state drift             Alert
                       compliance-scan   - posture                 Report
```

## 8.3 Pre-commit Configuration

### .pre-commit-config.yaml
```yaml
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
        args: ['--allow-multiple-documents']
      - id: check-json
      - id: check-merge-conflict
      - id: detect-private-key
      - id: no-commit-to-branch
        args: ['--branch', 'main']

  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.86.0
    hooks:
      - id: terraform_fmt
      - id: terraform_validate
      - id: terraform_tflint
      - id: terraform_docs
      - id: terraform_checkov
        args:
          - --args=--quiet
          - --args=--compact

  - repo: https://github.com/Yelp/detect-secrets
    rev: v1.4.0
    hooks:
      - id: detect-secrets
        args: ['--baseline', '.secrets.baseline']

  - repo: https://github.com/compilerla/conventional-pre-commit
    rev: v3.1.0
    hooks:
      - id: conventional-pre-commit
        stages: [commit-msg]
```

---

# PARTE 9: OBSERVABILIDAD Y SRE

## 9.1 Prometheus Rules (SLOs)

### platform/base/prometheus-stack/slo-rules.yaml
```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: slo-rules
  labels:
    prometheus: main
spec:
  groups:
    - name: slo.rules
      interval: 30s
      rules:
        # Availability SLO: 99.9%
        - record: slo:availability:ratio
          expr: |
            sum(rate(http_requests_total{code!~"5.."}[5m])) by (service)
            /
            sum(rate(http_requests_total[5m])) by (service)
        
        - record: slo:availability:burn_rate_1h
          expr: |
            1 - (slo:availability:ratio / 0.999)
        
        # Latency SLO: p99 < 500ms
        - record: slo:latency:ratio
          expr: |
            sum(rate(http_request_duration_seconds_bucket{le="0.5"}[5m])) by (service)
            /
            sum(rate(http_request_duration_seconds_count[5m])) by (service)
        
        # Error budget remaining
        - record: slo:error_budget:remaining
          expr: |
            1 - (
              (1 - slo:availability:ratio) / (1 - 0.999)
            )

    - name: slo.alerts
      rules:
        - alert: SLOBurnRateHigh
          expr: slo:availability:burn_rate_1h > 14.4
          for: 2m
          labels:
            severity: critical
          annotations:
            summary: "High error burn rate for {{ $labels.service }}"
            description: "Service {{ $labels.service }} is burning through error budget"
            runbook: "https://runbooks.example.com/slo-burn-rate"
        
        - alert: ErrorBudgetLow
          expr: slo:error_budget:remaining < 0.1
          for: 5m
          labels:
            severity: warning
          annotations:
            summary: "Error budget low for {{ $labels.service }}"
            runbook: "https://runbooks.example.com/error-budget-low"
```

---

# PARTE 10: SERVICE TEMPLATES

## 10.1 Copier Template Configuration

### templates/microservice-golang/copier.yaml
```yaml
_min_copier_version: "9.0.0"

_envops:
  autoescape: false
  keep_trailing_newline: true

project_name:
  type: str
  help: "Service name (lowercase, hyphenated)"
  validator: "{% if not project_name | regex_search('^[a-z][a-z0-9-]{2,28}[a-z0-9]$') %}Invalid name{% endif %}"

team:
  type: str
  help: "Team name"

description:
  type: str
  help: "Short description of the service"

port:
  type: int
  default: 8080
  help: "HTTP port"

has_database:
  type: bool
  default: false
  help: "Does this service need a database?"

database_type:
  type: str
  default: "postgres"
  choices:
    - postgres
    - mysql
    - mongodb
  when: "{{ has_database }}"

has_cache:
  type: bool
  default: false
  help: "Does this service need Redis cache?"

enable_grpc:
  type: bool
  default: false
  help: "Enable gRPC server?"

owner_email:
  type: str
  help: "Team/owner email for alerts"

_tasks:
  - "git init"
  - "go mod tidy"
  - "pre-commit install"
```

---

# PARTE 11: NAMING CONVENTIONS

## 11.1 Standard Naming

```yaml
# naming-conventions.yaml

repositories:
  pattern: "{scope}-{name}"
  examples:
    - "terraform-modules"           # Central modules
    - "team-payments-infra"         # Team infrastructure
    - "client-acme-platform"        # Client-specific
    - "service-payment-api"         # Service repo

branches:
  main: "main"
  feature: "feat/{ticket}-{desc}"
  fix: "fix/{ticket}-{desc}"
  release: "release/v{semver}"

terraform:
  modules:
    pattern: "{cloud}-{category}-{resource}"
    examples:
      - "aws-networking-vpc"
      - "azure-compute-aks"
      - "gcp-storage-gcs"
  
  state_keys:
    pattern: "{client}/{project}/{stack}/{environment}"
    examples:
      - "acme/platform/networking/prod"
      - "beta/payments/api/dev"
  
  resources:
    pattern: "{project}-{environment}-{resource}-{suffix}"
    examples:
      - "payments-prod-vpc-main"
      - "orders-dev-rds-primary"

kubernetes:
  namespaces:
    pattern: "{team}-{service}-{environment}"
    examples:
      - "payments-api-prod"
      - "orders-processor-dev"
  
  labels:
    required:
      - "app.kubernetes.io/name"
      - "app.kubernetes.io/version"
      - "app.kubernetes.io/component"
      - "app.kubernetes.io/part-of"
      - "app.kubernetes.io/managed-by"
      - "team"
      - "environment"
      - "cost-center"

tags_labels:
  required:
    - key: "Environment"
      values: ["dev", "staging", "prod", "ephemeral"]
    - key: "Team"
      pattern: "team-{name}"
    - key: "Project"
      pattern: "{project-name}"
    - key: "CostCenter"
      pattern: "cc-{code}"
    - key: "ManagedBy"
      values: ["terraform", "manual"]
    - key: "Owner"
      pattern: "{email}"
```

---

# PARTE 12: RUNBOOKS OPERACIONALES

## 12.1 Rollout Fallido

```markdown
# Runbook: Rollout Fallido

## Síntomas
- Pods en estado CrashLoopBackOff o Error
- Deployment stuck en Progressing
- Argo CD sync failed

## Diagnóstico Rápido

### 1. Verificar estado del deployment
kubectl get deployment $SERVICE -n $NAMESPACE
kubectl describe deployment $SERVICE -n $NAMESPACE | tail -20
kubectl get pods -n $NAMESPACE -l app=$SERVICE

### 2. Ver logs del pod fallido
POD=$(kubectl get pods -n $NAMESPACE -l app=$SERVICE --sort-by=.metadata.creationTimestamp -o jsonpath='{.items[-1].metadata.name}')
kubectl logs $POD -n $NAMESPACE --previous

## Acciones de Remediación

### Opción A: Rollback inmediato (si prod afectado)
# Via GitOps (preferido)
cd gitops-config
git revert HEAD
git push origin main

# Via kubectl (emergencia)
kubectl rollout undo deployment/$SERVICE -n $NAMESPACE

### Opción B: Fix forward
# Identificar problema y aplicar fix
kubectl apply -f deployment-fixed.yaml
```

## 12.2 Drift Detectado

```markdown
# Runbook: Drift Detectado

## Diagnóstico
cd platform-stacks/clients/$CLIENT/environments/$ENV
terraform plan -detailed-exitcode -out=drift.plan
terraform show -json drift.plan | jq '.resource_changes[] | select(.change.actions != ["no-op"])'

## Acciones

### Opción A: Revertir cambio manual
terraform apply drift.plan

### Opción B: Importar cambio válido
# 1. Actualizar código Terraform
# 2. Import si es recurso nuevo
terraform import module.example.aws_instance.new i-1234567890abcdef0
# 3. Verificar
terraform plan  # Debería mostrar "No changes"
```

## 12.3 Apply Fallido por State Lock

```markdown
# Runbook: Terraform State Lock

## Diagnóstico
# AWS (DynamoDB)
aws dynamodb get-item \
    --table-name terraform-locks \
    --key '{"LockID": {"S": "bucket/path/terraform.tfstate-md5"}}'

## Acciones

### Si hay proceso legítimo corriendo
# Esperar (timeout típico: 20-30 min)

### Si el proceso murió
# PRECAUCIÓN: Verificar que NO hay proceso activo
terraform force-unlock $LOCK_ID
```

---

# PARTE 13: PLAN DE ENTREGA 30/60/90

## Fase 1: MVP (Días 1-30)

### Semana 1-2: Fundamentos
- [ ] Crear estructura de repositorios
- [ ] Configurar backends remotos (S3/Blob/GCS)
- [ ] Implementar OIDC federation para CI/CD
- [ ] Crear módulos core: VPC, IAM básico, S3/Storage
- [ ] Pipeline CI básico: fmt, validate, plan

### Semana 3-4: CI/CD y GitOps
- [ ] Pipeline completo: lint → scan → plan → apply
- [ ] PR comments con terraform plan
- [ ] Instalar Argo CD en cluster dev
- [ ] Primer servicio deployado via GitOps
- [ ] Documentar proceso de onboarding

### Entregables MVP
- 1 cliente piloto con dev environment funcional
- 5 módulos terraform funcionando
- 1 servicio deployando end-to-end
- Documentación quickstart

## Fase 2: Escala (Días 31-60)

### Semana 5-6: Seguridad y Policies
- [ ] Implementar OPA/Conftest policies
- [ ] Security scanning en CI
- [ ] External Secrets Operator
- [ ] Gatekeeper en clusters

### Semana 7-8: Multi-entorno
- [ ] Staging y prod environments
- [ ] Workflow de promoción
- [ ] Entornos efímeros (PR preview)
- [ ] Onboarding de 3+ equipos

## Fase 3: Hardening (Días 61-90)

### Semana 9-10: Observabilidad
- [ ] Stack completo: Prometheus + Grafana + Loki + Tempo
- [ ] SLOs/SLIs para servicios críticos
- [ ] Dashboards estándar
- [ ] Alerting basado en SLOs

### Semana 11-12: DX y Optimización
- [ ] Service templates (scaffold)
- [ ] Scorecards de compliance
- [ ] Drift detection automatizado
- [ ] Cost tracking
- [ ] Training a todos los equipos

---

# PARTE 14: CHECKLIST GOLDEN PATH

## Para Equipo Nuevo

### Pre-requisitos (Platform Team)
- [ ] Namespace creado en clusters
- [ ] RBAC configurado
- [ ] Secrets path en Vault creado
- [ ] Budget alerts configurados

### Paso 1: Crear Servicio (Día 1)
- [ ] Usar template: `copier copy gh:org/service-templates/microservice-golang my-service`
- [ ] Push inicial a GitHub
- [ ] Verificar CI pipeline pasa

### Paso 2: Configurar Infraestructura (Día 1-2)
- [ ] Crear stack en `platform-stacks/teams/{team}/{service}/`
- [ ] Usar módulos oficiales
- [ ] PR con terraform plan

### Paso 3: Configurar GitOps (Día 2)
- [ ] Crear directorio en `gitops-config/apps/{team}/{service}/`
- [ ] Configurar base + overlays
- [ ] Verificar sync en Argo CD

### Paso 4: Observabilidad (Día 2-3)
- [ ] Verificar métricas exportadas
- [ ] Configurar ServiceMonitor
- [ ] Importar dashboard estándar
- [ ] Configurar alertas básicas

### Paso 5: Documentación (Día 3)
- [ ] Completar README
- [ ] Crear RUNBOOK.md
- [ ] Crear al menos 1 ADR

### Paso 6: Production Readiness (Día 5)
- [ ] Code review
- [ ] Security review (si aplica)
- [ ] Promotion a prod
- [ ] Scorecard > 70%

---

# INSTRUCCIONES FINALES PARA CLAUDE CODE

## Orden de Implementación

1. **Primero:** Crear la estructura base de directorios para todos los repositorios
2. **Segundo:** Implementar `terraform-modules/` con módulos VPC, IAM, Storage
3. **Tercero:** Implementar `platform-stacks/` con un cliente de ejemplo
4. **Cuarto:** Implementar `gitops-config/` con configuración de Argo CD
5. **Quinto:** Implementar `service-templates/` con template de Go
6. **Sexto:** Implementar `platform-policies/` con políticas OPA

## Validaciones Requeridas

Después de crear cada componente, valida:
- Terraform: `terraform fmt -check && terraform validate`
- YAML: Sintaxis válida
- Políticas OPA: `conftest verify`
- Kubernetes: `kubectl --dry-run=client`

## Archivos Críticos a Generar

1. `README.md` para cada repositorio
2. `.pre-commit-config.yaml` en cada repo
3. `.github/workflows/*.yaml` para CI/CD
4. `CONTRIBUTING.md` con guías de contribución
5. `docs/` con ADRs y runbooks

## Calidad del Código

- Comentarios en español
- Documentación inline en todos los módulos
- Ejemplos funcionales para cada módulo
- Tests para módulos Terraform

---

**FIN DEL DOCUMENTO**

Este documento contiene toda la especificación necesaria para implementar el Golden Path.
Genera el código siguiendo las estructuras y ejemplos proporcionados.
