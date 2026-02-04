# Pattern: Arquitectura de 3 Capas

Este pattern crea la infraestructura base para una aplicación de 3 capas.

## Arquitectura

```
┌─────────────────────────────────────────────────────────────────┐
│                           INTERNET                               │
└─────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                    CAPA 1: PRESENTACIÓN                          │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │
│  │ Public-1a   │  │ Public-1b   │  │ Public-1c   │             │
│  │ (ALB/NLB)   │  │ (ALB/NLB)   │  │ (ALB/NLB)   │             │
│  └─────────────┘  └─────────────┘  └─────────────┘             │
└─────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                    CAPA 2: APLICACIÓN                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │
│  │ Private-1a  │  │ Private-1b  │  │ Private-1c  │             │
│  │ (EKS/ECS)   │  │ (EKS/ECS)   │  │ (EKS/ECS)   │             │
│  └─────────────┘  └─────────────┘  └─────────────┘             │
└─────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                    CAPA 3: DATOS                                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │
│  │ Database-1a │  │ Database-1b │  │ Database-1c │             │
│  │ (RDS/Cache) │  │ (RDS/Cache) │  │ (RDS/Cache) │             │
│  └─────────────┘  └─────────────┘  └─────────────┘             │
└─────────────────────────────────────────────────────────────────┘
```

## Uso

```hcl
module "my_app" {
  source = "git::https://github.com/org/terraform-modules.git//patterns/three-tier-app?ref=v1.0.0"

  name        = "mi-aplicacion"
  environment = "prod"
  vpc_cidr    = "10.0.0.0/16"

  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

  database_engine         = "postgres"
  database_instance_class = "db.t3.medium"
  enable_cache           = true

  tags = {
    Team       = "product"
    CostCenter = "cc-001"
  }
}
```

## Recursos Creados

- VPC con subnets públicas, privadas y de base de datos
- Internet Gateway
- Security Groups para cada capa
- DB Subnet Group
- Flow Logs habilitados

## Seguridad

- Subnets de BD aisladas (sin acceso a internet)
- Security Groups restrictivos
- Flow logs para auditoría
- Sin IPs públicas en capas privadas
