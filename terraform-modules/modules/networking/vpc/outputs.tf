# Outputs del módulo VPC
# Expone IDs y atributos necesarios para otros módulos

# ============================================
# OUTPUTS COMUNES (Cloud-Agnostic)
# ============================================
output "vpc_id" {
  description = "ID de la VPC/VNet/Network creada"
  value = coalesce(
    try(aws_vpc.this[0].id, null),
    try(azurerm_virtual_network.this[0].id, null),
    try(google_compute_network.this[0].id, null)
  )
}

output "vpc_name" {
  description = "Nombre de la VPC"
  value       = var.name
}

output "cidr_block" {
  description = "Bloque CIDR de la VPC"
  value       = var.cidr_block
}

output "environment" {
  description = "Entorno de la VPC"
  value       = var.environment
}

output "cloud_provider" {
  description = "Proveedor cloud utilizado"
  value       = var.cloud_provider
}

# ============================================
# OUTPUTS AWS
# ============================================
output "aws_vpc_arn" {
  description = "ARN de la VPC de AWS"
  value       = try(aws_vpc.this[0].arn, null)
}

output "aws_internet_gateway_id" {
  description = "ID del Internet Gateway de AWS"
  value       = try(aws_internet_gateway.this[0].id, null)
}

output "aws_private_subnet_ids" {
  description = "IDs de las subnets privadas de AWS"
  value       = aws_subnet.private[*].id
}

output "aws_public_subnet_ids" {
  description = "IDs de las subnets públicas de AWS"
  value       = aws_subnet.public[*].id
}

output "aws_flow_log_id" {
  description = "ID del Flow Log de AWS"
  value       = try(aws_flow_log.this[0].id, null)
}

# ============================================
# OUTPUTS AZURE
# ============================================
output "azure_vnet_id" {
  description = "ID de la Virtual Network de Azure"
  value       = try(azurerm_virtual_network.this[0].id, null)
}

output "azure_vnet_name" {
  description = "Nombre de la Virtual Network de Azure"
  value       = try(azurerm_virtual_network.this[0].name, null)
}

output "azure_private_subnet_ids" {
  description = "IDs de las subnets privadas de Azure"
  value       = azurerm_subnet.private[*].id
}

output "azure_public_subnet_ids" {
  description = "IDs de las subnets públicas de Azure"
  value       = azurerm_subnet.public[*].id
}

output "azure_nsg_id" {
  description = "ID del Network Security Group por defecto"
  value       = try(azurerm_network_security_group.default[0].id, null)
}

# ============================================
# OUTPUTS GCP
# ============================================
output "gcp_network_id" {
  description = "ID de la VPC Network de GCP"
  value       = try(google_compute_network.this[0].id, null)
}

output "gcp_network_self_link" {
  description = "Self link de la VPC Network de GCP"
  value       = try(google_compute_network.this[0].self_link, null)
}

output "gcp_private_subnet_ids" {
  description = "IDs de las subnets privadas de GCP"
  value       = google_compute_subnetwork.private[*].id
}

output "gcp_public_subnet_ids" {
  description = "IDs de las subnets públicas de GCP"
  value       = google_compute_subnetwork.public[*].id
}

output "gcp_router_id" {
  description = "ID del Cloud Router de GCP"
  value       = try(google_compute_router.this[0].id, null)
}

# ============================================
# OUTPUTS PARA OTROS MÓDULOS
# ============================================
output "private_subnet_ids" {
  description = "IDs de subnets privadas (cloud-agnostic)"
  value = coalesce(
    length(aws_subnet.private) > 0 ? aws_subnet.private[*].id : null,
    length(azurerm_subnet.private) > 0 ? azurerm_subnet.private[*].id : null,
    length(google_compute_subnetwork.private) > 0 ? google_compute_subnetwork.private[*].id : null,
    []
  )
}

output "public_subnet_ids" {
  description = "IDs de subnets públicas (cloud-agnostic)"
  value = coalesce(
    length(aws_subnet.public) > 0 ? aws_subnet.public[*].id : null,
    length(azurerm_subnet.public) > 0 ? azurerm_subnet.public[*].id : null,
    length(google_compute_subnetwork.public) > 0 ? google_compute_subnetwork.public[*].id : null,
    []
  )
}

output "tags" {
  description = "Tags aplicados a los recursos"
  value       = local.common_tags
}
