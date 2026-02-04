# Platform Stacks - Golden Path

Repositorio de stacks de infraestructura por cliente y entorno.

## Estructura

```
_templates/          # Templates para nuevos clientes/entornos
shared/              # Configuraciones compartidas (backends, providers)
clients/             # Stacks por cliente
  └── client-{name}/
      ├── bootstrap/     # Setup inicial (state bucket, IAM)
      ├── foundation/    # Infraestructura base (networking, security)
      └── environments/  # Entornos (dev, staging, prod)
teams/               # Stacks específicos por equipo
ephemeral/           # Entornos efímeros para PRs
```

## Uso

### Crear nuevo cliente

```bash
./scripts/init-client.sh --name "nuevo-cliente" --cloud aws
```

### Crear nuevo entorno

```bash
./scripts/init-environment.sh --client "cliente-acme" --env staging
```

### Ejecutar Terraform

```bash
cd clients/client-acme/environments/dev
terraform init
terraform plan
terraform apply
```

## Pipeline CI/CD

1. **PR**: terraform plan automático + policy checks
2. **Merge a main**: terraform apply con aprobación requerida para prod
3. **Drift Detection**: Verificación programada de drift

## Convenciones

### Naming

- State keys: `{client}/{project}/{stack}/{environment}`
- Recursos: `{project}-{environment}-{resource}-{suffix}`

### Tags requeridos

- `Environment`
- `Team`
- `CostCenter`
- `Owner`
- `ManagedBy`

## Seguridad

- OIDC para autenticación CI/CD (sin secrets estáticos)
- State encryption habilitado
- State locking con DynamoDB/Blob/GCS
