# Backend configuration para Azure
# Uso: terraform init -backend-config=../../shared/backend-configs/azure.hcl

# NOTA: Las variables ${} deben ser reemplazadas al inicializar
# resource_group_name  = "rg-${client_name}-terraform"
# storage_account_name = "st${client_name}tfstate"
# container_name       = "tfstate"
# key                  = "${project}/${stack}/${environment}/terraform.tfstate"

# Ejemplo de uso en backend.tf:
# terraform {
#   backend "azurerm" {
#     resource_group_name  = "rg-acme-terraform"
#     storage_account_name = "stacmetfstate"
#     container_name       = "tfstate"
#     key                  = "platform/networking/dev/terraform.tfstate"
#   }
# }
