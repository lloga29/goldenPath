# Changelog - Golden Path Platform

Todos los cambios notables en este proyecto serán documentados aquí.

## [0.2.0] - 2024-01-20 - Hardening Release

### terraform-modules/
- **fix:** Crear `docs/header.md` y `docs/footer.md` para terraform-docs
- **fix:** Crear `.secrets.baseline` para detect-secrets
- **feat:** Agregar `Makefile` con comandos estándar (fmt, validate, lint, test, docs)
- **fix:** Mejorar `scripts/validate-all.sh` con verificación de dependencias

### platform-stacks/
- **fix:** Completar estructura de cliente ACME con todos los entornos
- **feat:** Workflows de CI/CD con instalación de herramientas
- **docs:** Agregar templates para nuevos clientes/entornos

### gitops-config/
- **fix:** Crear `clusters/staging/cluster-config.yaml`
- **fix:** Completar `apps/team-payments/payment-api/overlays/staging/`
- **feat:** Crear `platform/base/*` (ingress-nginx, cert-manager, external-secrets, prometheus-stack, loki, tempo, gatekeeper)
- **feat:** Crear `platform/overlays/{dev,staging,prod}/`
- **docs:** Crear `PROMOTION_GUIDE.md` y `ROLLBACK_PROCEDURE.md`
- **fix:** Mejorar `scripts/promote.sh` con validación de :latest y soporte para yq
- **fix:** Mejorar `scripts/rollback.sh` con modo emergencia

### service-templates/
- **fix:** Completar template Go con handlers, middleware, config
- **fix:** Corregir Dockerfile (usar distroless, eliminar HEALTHCHECK roto)
- **feat:** Agregar version injection via ldflags
- **feat:** Agregar `.pre-commit-config.yaml` al template

### platform-policies/
- **feat:** Agregar `no_latest_tag.rego` - prohibir :latest
- **feat:** Agregar `security_context.rego` - runAsNonRoot, no privilegeEscalation
- **feat:** Agregar `required_resources.rego` - requests/limits obligatorios
- **feat:** Crear `policy-exceptions.yaml` para gestión de excepciones

### Documentación
- **docs:** Crear `docs/QUICKSTART.md` - guía de 15 minutos
- **docs:** Crear runbooks: drift-detected, policy-deny-pr, application-rollback
- **docs:** Crear `AUDIT_CHECKLIST.md` con gaps identificados

## [0.1.0] - 2024-01-15 - Initial Release

### Added
- Estructura inicial de todos los repositorios
- Módulos Terraform básicos (VPC, IAM, Storage)
- Configuración GitOps con ArgoCD
- Templates de servicio (Go skeleton)
- Políticas OPA/Conftest básicas
- CI/CD pipelines
- Documentación inicial
