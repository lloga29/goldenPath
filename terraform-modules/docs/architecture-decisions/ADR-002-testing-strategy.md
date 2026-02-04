# ADR-002: Estrategia de Testing para Módulos

## Estado

Aceptado

## Contexto

Los módulos Terraform necesitan ser testeados para garantizar:
- Validaciones funcionan correctamente
- Recursos se crean con la configuración esperada
- No hay regresiones en cambios

## Decisión

### Niveles de Testing

1. **Tests Unitarios (terraform test)**
   - Validación de variables
   - Plan assertions
   - No requieren infraestructura real

2. **Tests de Integración (Terratest)**
   - Crear recursos reales
   - Validar comportamiento
   - Cleanup automático

3. **Security Scanning**
   - Checkov
   - TFSec
   - Ejecutados en CI

### Terraform Native Testing

Usamos `terraform test` (disponible desde TF 1.6) como framework principal:

```hcl
# tests/unit/example_test.tftest.hcl

variables {
  name = "test"
}

run "validates_successfully" {
  command = plan

  assert {
    condition = aws_resource.this[0].name == "test"
    error_message = "Nombre incorrecto"
  }
}

run "invalid_name_fails" {
  variables { name = "INVALID" }
  expect_failures = [var.name]
}
```

### Cobertura Mínima

Cada módulo debe tener tests para:
- Creación exitosa con valores válidos
- Fallo con valores inválidos (para cada validación)
- Tags aplicados correctamente

## Consecuencias

### Positivas
- Tests nativos sin dependencias externas
- Rápidos de ejecutar (solo plan)
- Fáciles de escribir

### Negativas
- No validan comportamiento real
- Limitados a lo que plan puede verificar

## Alternativas Consideradas

1. **Solo Terratest**: Descartado por lentitud y costo
2. **Sin tests**: Descartado por riesgo de regresiones
