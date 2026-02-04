# Service Templates - Golden Path

Templates oficiales para crear nuevos servicios siguiendo los estándares de la plataforma.

## Templates Disponibles

| Template | Descripción | Lenguaje |
|----------|-------------|----------|
| microservice-golang | Microservicio HTTP/gRPC | Go |
| microservice-python | Microservicio FastAPI | Python |
| terraform-stack | Stack de Terraform | HCL |

## Uso

### Crear nuevo servicio

```bash
# Instalar Copier
pip install copier

# Crear servicio desde template
copier copy gh:org/service-templates/templates/microservice-golang my-new-service

# O desde directorio local
copier copy ./templates/microservice-golang my-new-service
```

### Actualizar servicio existente

```bash
# Actualizar a última versión del template
copier update my-existing-service
```

## Características Incluidas

### microservice-golang

- Servidor HTTP con graceful shutdown
- Health checks (/health, /ready)
- Métricas Prometheus (/metrics)
- Logging estructurado (slog)
- OpenTelemetry tracing
- Dockerfile multi-stage optimizado
- CI/CD pipeline (GitHub Actions)
- Pre-commit hooks

### microservice-python

- FastAPI con async
- Health checks
- Métricas Prometheus
- Logging estructurado
- OpenTelemetry tracing
- Dockerfile optimizado
- CI/CD pipeline
- Tests con pytest

### terraform-stack

- Estructura estándar de Terraform
- Backend remoto configurado
- Variables tipadas con validaciones
- Outputs documentados

## Personalización

Ver [docs/CUSTOMIZATION.md](docs/CUSTOMIZATION.md) para guías de personalización.

## Contribuir

Ver [docs/TEMPLATE_GUIDE.md](docs/TEMPLATE_GUIDE.md) para crear nuevos templates.
