# Terraform Modules - Golden Path

Repositorio central de módulos Terraform oficiales para la plataforma.

## Estructura

```
modules/
├── networking/       # Módulos de red (VPC, Subnets, Security Groups, LB)
├── compute/         # Módulos de cómputo (Kubernetes, VMs, Serverless)
├── storage/         # Módulos de almacenamiento (Object Storage, DB, Cache)
├── security/        # Módulos de seguridad (IAM, KMS, WAF)
├── observability/   # Módulos de observabilidad (Logging, Monitoring, Alerting)
└── data/           # Módulos de datos (Data Lake, Warehouse, Streaming)

patterns/            # Patrones compuestos reutilizables
```

## Uso

### Referencia desde otro repositorio

```hcl
module "vpc" {
  source  = "git::https://github.com/org/terraform-modules.git//modules/networking/vpc?ref=v1.0.0"

  name           = "my-vpc"
  cidr_block     = "10.0.0.0/16"
  environment    = "dev"
  cloud_provider = "aws"

  tags = {
    Team       = "platform"
    CostCenter = "cc-001"
  }
}
```

## Versionamiento

- Usamos [Semantic Versioning](https://semver.org/)
- Cada módulo tiene su propio CHANGELOG.md
- Los releases se crean automáticamente en merges a main

## Contribución

Ver [CONTRIBUTING.md](docs/CONTRIBUTING.md) para guías de contribución.

## Estándares

- Todos los módulos deben incluir validaciones de variables
- Tests obligatorios (unit + integration cuando aplique)
- Documentación auto-generada con terraform-docs
- Pre-commit hooks para formateo y validación

## Cloud Providers Soportados

- AWS
- Azure
- GCP

## Licencia

Uso interno - Todos los derechos reservados.
