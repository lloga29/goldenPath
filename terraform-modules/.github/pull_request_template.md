## Descripción

<!-- Describe brevemente los cambios realizados -->

## Tipo de cambio

- [ ] Nueva funcionalidad (feature)
- [ ] Corrección de bug (fix)
- [ ] Cambio que rompe compatibilidad (breaking change)
- [ ] Documentación
- [ ] Refactoring
- [ ] Otros (especificar)

## Módulo(s) afectado(s)

<!-- Lista los módulos modificados -->
- `modules/...`

## Checklist

### Código
- [ ] He seguido los estándares de código del repositorio
- [ ] He añadido/actualizado validaciones en variables
- [ ] He actualizado los outputs necesarios
- [ ] El código es compatible con AWS/Azure/GCP (si aplica)

### Tests
- [ ] He añadido/actualizado tests unitarios (`.tftest.hcl`)
- [ ] Los tests pasan localmente (`terraform test`)
- [ ] He probado los ejemplos

### Documentación
- [ ] He actualizado el README.md del módulo
- [ ] He actualizado el CHANGELOG.md
- [ ] He ejecutado `terraform-docs` para actualizar la documentación
- [ ] Los ejemplos están actualizados

### Seguridad
- [ ] No hay credenciales hardcodeadas
- [ ] Los recursos siguen el principio de least privilege
- [ ] Los checks de Checkov/TFSec pasan

## Ejemplos de uso

<!-- Proporciona un ejemplo de cómo usar los cambios -->

```hcl
module "example" {
  source = "./modules/..."

  # ...
}
```

## Notas adicionales

<!-- Cualquier información adicional relevante -->

## Screenshots (si aplica)

<!-- Añade capturas de pantalla del plan de Terraform si son relevantes -->
