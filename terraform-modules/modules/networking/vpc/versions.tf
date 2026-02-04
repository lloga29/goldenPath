# Versiones requeridas de Terraform y providers
# Este módulo soporta AWS, Azure y GCP

terraform {
  required_version = ">= 1.5.0, < 2.0.0"

  required_providers {
    # AWS Provider
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0, < 6.0.0"
    }

    # Azure Provider
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0.0, < 4.0.0"
    }

    # GCP Provider
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0.0, < 6.0.0"
    }
  }
}
