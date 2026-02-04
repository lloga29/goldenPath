# Backend configuration para AWS
# Uso: terraform init -backend-config=../../shared/backend-configs/aws.hcl

# NOTA: Las variables ${} deben ser reemplazadas al inicializar
# bucket         = "client-${client_name}-terraform-state"
# key            = "${project}/${stack}/${environment}/terraform.tfstate"
# region         = "us-east-1"
# encrypt        = true
# dynamodb_table = "client-${client_name}-terraform-locks"

# Ejemplo de uso en backend.tf:
# terraform {
#   backend "s3" {
#     bucket         = "client-acme-terraform-state"
#     key            = "platform/networking/dev/terraform.tfstate"
#     region         = "us-east-1"
#     encrypt        = true
#     dynamodb_table = "client-acme-terraform-locks"
#   }
# }
