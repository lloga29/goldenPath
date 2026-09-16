# Azure Storage backend reference.
# Replace placeholders with client/environment-specific values before initialization.
#
# Example:
# terraform {
#   backend "azurerm" {
#     resource_group_name  = "rg-acme-terraform"
#     storage_account_name = "stacmetfstate"
#     container_name       = "tfstate"
#     key                  = "platform/networking/dev/terraform.tfstate"
#   }
# }
