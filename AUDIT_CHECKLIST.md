# Golden Path - Checklist de Auditoría

## P0 - Rompe CI/Uso (CRÍTICO)

### terraform-modules/
- [ ] Crear `docs/header.md` y `docs/footer.md` (referenciados por .terraform-docs.yaml)
- [ ] Crear `.secrets.baseline` o ajustar pre-commit
- [ ] Completar `scripts/validate-all.sh` con verificación de dependencias
- [ ] Módulos vacíos: compute/*, storage/database, storage/cache, security/kms-key, security/waf, networking/subnets, networking/security-groups, networking/load-balancer, observability/*, data/*, patterns/data-pipeline, patterns/api-gateway-pattern

### platform-stacks/
- [ ] Crear `scripts/init-environment.sh` (referenciado en docs)
- [ ] Completar workflows con instalación de herramientas
- [ ] Directorios vacíos: foundation/security, foundation/observability, teams/*, client-beta

### gitops-config/
- [ ] Crear `clusters/staging/cluster-config.yaml`
- [ ] Completar `apps/team-payments/payment-api/overlays/staging/`
- [ ] Crear `docs/PROMOTION_GUIDE.md` y `docs/ROLLBACK_PROCEDURE.md`
- [ ] Completar `platform/base/*` (cert-manager, external-secrets, ingress-nginx, prometheus-stack, loki, tempo, gatekeeper)
- [ ] Completar `platform/overlays/*/`
- [ ] Crear `apps/team-orders/` con al menos un servicio
- [ ] Verificar scripts promote.sh y rollback.sh funcionan

### service-templates/
- [ ] Completar template microservice-golang (handlers, config, middleware)
- [ ] Completar template microservice-python
- [ ] Completar template terraform-stack
- [ ] Crear scripts y docs

### platform-policies/
- [ ] Verificar todas las políticas referenciadas existen
- [ ] Completar constraint-templates de Gatekeeper

## P1 - Seguridad/Correctitud

### Todos los repos
- [ ] Eliminar uso de `:latest` tags
- [ ] Implementar OIDC para CI/CD
- [ ] Asegurar encryption por defecto
- [ ] Validar least privilege en IAM
- [ ] Implementar build once → promote

### terraform-modules/
- [ ] Añadir prevent_destroy para prod
- [ ] Completar flow logs con storage account para Azure
- [ ] Validar tests funcionan

### gitops-config/
- [ ] AppProjects con límites de namespaces/repos
- [ ] Políticas no-latest en deployments
- [ ] Promoción por PR entre entornos

## P2 - Mejoras

- [ ] SBOM generation
- [ ] Image signing con Cosign
- [ ] ADRs completos
- [ ] Observabilidad más completa
- [ ] Makefiles en todos los repos
