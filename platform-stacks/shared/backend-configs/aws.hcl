# AWS S3 backend reference.
# Replace placeholders with client/environment-specific values before initialization.
#
# Example:
# terraform {
#   backend "s3" {
#     bucket         = "client-acme-terraform-state"
#     key            = "platform/networking/dev/terraform.tfstate"
#     region         = "us-east-1"
#     encrypt        = true
#     dynamodb_table = "client-acme-terraform-locks"
#   }
# }
