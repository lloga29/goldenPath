# ADR-001: Estructura de Módulos Terraform

## Estado

Aceptado

## Contexto

Necesitamos definir una estructura estándar para los módulos Terraform que sea:
- Fácil de mantener
- Consistente entre equipos
- Testeable
- Documentable automáticamente

## Decisión

### Estructura de Directorios

```
modules/
├── categoria/
│   └── nombre-modulo/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── versions.tf
│       ├── README.md
│       ├── examples/
│       └── tests/
```

### Categorías

1. **networking** - VPC, subnets, load balancers
2. **compute** - EKS, VMs, serverless
3. **storage** - S3, RDS, cache
4. **security** - IAM, KMS, WAF
5. **observability** - logging, monitoring
6. **data** - data lake, streaming

### Separación de Archivos

- `main.tf`: Recursos principales
- `variables.tf`: TODAS las variables
- `outputs.tf`: TODOS los outputs
- `versions.tf`: Versiones de Terraform y providers

## Consecuencias

### Positivas
- Consistencia entre módulos
- Fácil onboarding de nuevos contribuidores
- Documentación auto-generada funciona correctamente

### Negativas
- Puede resultar en archivos variables.tf grandes
- Requiere disciplina del equipo

## Alternativas Consideradas

1. **Un archivo por recurso**: Descartado por dificultar navegación
2. **Variables inline en main.tf**: Descartado por dificultar terraform-docs
