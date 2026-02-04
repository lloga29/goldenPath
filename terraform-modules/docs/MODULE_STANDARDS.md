# Estándares de Módulos Terraform

## Estructura Obligatoria

```
module-name/
├── main.tf           # REQUERIDO - Recursos principales
├── variables.tf      # REQUERIDO - Todas las variables
├── outputs.tf        # REQUERIDO - Outputs necesarios
├── versions.tf       # REQUERIDO - Versiones de providers
├── README.md         # REQUERIDO - Documentación
└── tests/            # RECOMENDADO - Tests unitarios
```

## Variables

### Formato

```hcl
variable "nombre_variable" {
  description = "Descripción clara de la variable"
  type        = string|number|bool|list|map|object

  # Valor por defecto seguro
  default     = "valor-seguro"

  # Validación obligatoria para strings
  validation {
    condition     = # condición
    error_message = "Mensaje de error útil."
  }
}
```

### Variables Obligatorias

1. **environment**: dev|staging|prod|ephemeral
2. **tags**: map(string) con Team y CostCenter

### Naming

- Snake_case para nombres de variables
- Nombres descriptivos sin abreviaciones
- Prefijos consistentes por categoría

## Outputs

### Formato

```hcl
output "nombre_output" {
  description = "Descripción del output"
  value       = resource.name.attribute
  sensitive   = true|false
}
```

### Outputs Obligatorios

- ID/ARN del recurso principal
- Nombre del recurso
- Tags aplicados

## Seguridad

### Defaults Seguros

| Configuración | Default |
|--------------|---------|
| Encryption | Habilitado |
| Public Access | Bloqueado |
| Logging | Habilitado |
| Versioning | Habilitado |

### Validaciones de Seguridad

- CIDR blocks válidos
- No wildcards en IAM
- Nombres válidos (sin caracteres especiales)

## Cloud-Agnostic

Para módulos multi-cloud:

```hcl
variable "cloud_provider" {
  type = string
  validation {
    condition     = contains(["aws", "azure", "gcp"], var.cloud_provider)
    error_message = "Debe ser: aws, azure, gcp."
  }
}

resource "aws_resource" "this" {
  count = var.cloud_provider == "aws" ? 1 : 0
  # ...
}

resource "azurerm_resource" "this" {
  count = var.cloud_provider == "azure" ? 1 : 0
  # ...
}
```

## Documentación

El README.md debe incluir:

1. Descripción del módulo
2. Ejemplo de uso básico
3. Tabla de inputs/outputs (terraform-docs)
4. Notas de seguridad
5. Ejemplos avanzados

## Testing

### Test Unitario Mínimo

```hcl
run "resource_creates_successfully" {
  command = plan

  assert {
    condition     = # recurso existe
    error_message = "El recurso debe crearse"
  }
}

run "invalid_input_fails" {
  command = plan
  variables { invalid_var = "bad" }
  expect_failures = [var.invalid_var]
}
```
