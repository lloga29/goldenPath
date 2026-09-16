# Required Terraform and provider versions for the multi-provider network reference.

terraform {
  required_version = ">= 1.5.0, < 2.0.0"

  required_providers {
    # AWS provider.
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0, < 6.0.0"
    }

    # Azure provider.
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0.0, < 4.0.0"
    }

    # Google Cloud provider.
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0.0, < 6.0.0"
    }
  }
}
