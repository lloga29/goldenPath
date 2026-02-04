# Backend configuration para GCP
# Uso: terraform init -backend-config=../../shared/backend-configs/gcp.hcl

# NOTA: Las variables ${} deben ser reemplazadas al inicializar
# bucket = "client-${client_name}-terraform-state"
# prefix = "${project}/${stack}/${environment}"

# Ejemplo de uso en backend.tf:
# terraform {
#   backend "gcs" {
#     bucket = "client-acme-terraform-state"
#     prefix = "platform/networking/dev"
#   }
# }
