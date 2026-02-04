# Outputs del Bootstrap

output "state_bucket_name" {
  description = "Nombre del bucket de state"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "state_bucket_arn" {
  description = "ARN del bucket de state"
  value       = aws_s3_bucket.terraform_state.arn
}

output "locks_table_name" {
  description = "Nombre de la tabla de locks"
  value       = aws_dynamodb_table.terraform_locks.name
}

output "locks_table_arn" {
  description = "ARN de la tabla de locks"
  value       = aws_dynamodb_table.terraform_locks.arn
}

output "cicd_role_arn" {
  description = "ARN del rol de CI/CD"
  value       = aws_iam_role.terraform_cicd.arn
}

output "oidc_provider_arn" {
  description = "ARN del proveedor OIDC"
  value       = aws_iam_openid_connect_provider.github.arn
}
