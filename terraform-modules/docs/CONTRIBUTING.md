# Guía de Contribución - Terraform Modules

## Requisitos Previos

- Terraform >= 1.5.0
- Pre-commit instalado
- AWS CLI configurado (para tests)

## Flujo de Trabajo

### 1. Crear rama feature

```bash
git checkout -b feat/nombre-modulo
```

### 2. Desarrollar el módulo

Cada módulo debe tener la siguiente estructura:

```
modules/categoria/nombre-modulo/
├── main.tf           # Recursos principales
├── variables.tf      # Variables con validaciones
├── outputs.tf        # Outputs
├── versions.tf       # Versiones requeridas
├── README.md         # Documentación (auto-generada)
├── CHANGELOG.md      # Historial de cambios
├── examples/
│   ├── basic/        # Ejemplo básico
│   └── advanced/     # Ejemplo avanzado
└── tests/
    └── unit/         # Tests unitarios
```

### 3. Ejecutar validaciones locales

```bash
# Instalar pre-commit hooks
pre-commit install

# Ejecutar validaciones
pre-commit run --all-files

# O manualmente:
terraform fmt -recursive
terraform validate
terraform test
```

### 4. Crear Pull Request

- Usa commits convencionales: `feat:`, `fix:`, `docs:`, etc.
- Incluye tests para nuevas funcionalidades
- Actualiza la documentación

## Estándares de Código

### Variables

```hcl
variable "name" {
  description = "Descripción clara y útil"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]+$", var.name))
    error_message = "Mensaje de error descriptivo."
  }
}
```

### Tags Obligatorios

Todos los recursos deben soportar los tags:
- `Team`
- `CostCenter`
- `Environment`
- `ManagedBy`

### Seguridad

- Encryption habilitado por defecto
- Sin secrets hardcodeados
- Principio de mínimo privilegio
- Validaciones en todas las variables

## Versionamiento

Seguimos [Semantic Versioning](https://semver.org/):

- `MAJOR`: Cambios incompatibles
- `MINOR`: Nueva funcionalidad compatible
- `PATCH`: Bug fixes

## Testing

### Tests Unitarios (terraform test)

```hcl
# tests/unit/example_test.tftest.hcl
run "test_name" {
  command = plan

  assert {
    condition     = resource.attribute == "expected"
    error_message = "Error message"
  }
}
```

### Tests de Integración

Para tests que requieren recursos reales, usar Terratest o similar.

## Revisión de Código

Todas las PRs requieren:

1. Tests pasando
2. Documentación actualizada
3. Sin issues de seguridad
4. Aprobación del equipo de plataforma
