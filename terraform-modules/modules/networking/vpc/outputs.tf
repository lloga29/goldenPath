# Outputs exposed for consumers and composed patterns.

# ============================================
# COMMON OUTPUTS
# ============================================
output "vpc_id" {
  description = "ID of the created VPC, VNet, or Google Cloud network."
  value = coalesce(
    try(aws_vpc.this[0].id, null),
    try(azurerm_virtual_network.this[0].id, null),
    try(google_compute_network.this[0].id, null)
  )
}

output "vpc_name" {
  description = "Network name."
  value       = var.name
}

output "cidr_block" {
  description = "Configured network CIDR block."
  value       = var.cidr_block
}

output "environment" {
  description = "Configured environment."
  value       = var.environment
}

output "cloud_provider" {
  description = "Selected cloud provider implementation."
  value       = var.cloud_provider
}

# ============================================
# AWS OUTPUTS
# ============================================
output "aws_vpc_arn" {
  description = "AWS VPC ARN."
  value       = try(aws_vpc.this[0].arn, null)
}

output "aws_internet_gateway_id" {
  description = "AWS Internet Gateway ID."
  value       = try(aws_internet_gateway.this[0].id, null)
}

output "aws_private_subnet_ids" {
  description = "AWS private subnet IDs."
  value       = aws_subnet.private[*].id
}

output "aws_public_subnet_ids" {
  description = "AWS public subnet IDs."
  value       = aws_subnet.public[*].id
}

output "aws_flow_log_id" {
  description = "AWS VPC Flow Log ID."
  value       = try(aws_flow_log.this[0].id, null)
}

# ============================================
# AZURE OUTPUTS
# ============================================
output "azure_vnet_id" {
  description = "Azure Virtual Network ID."
  value       = try(azurerm_virtual_network.this[0].id, null)
}

output "azure_vnet_name" {
  description = "Azure Virtual Network name."
  value       = try(azurerm_virtual_network.this[0].name, null)
}

output "azure_private_subnet_ids" {
  description = "Azure private subnet IDs."
  value       = azurerm_subnet.private[*].id
}

output "azure_public_subnet_ids" {
  description = "Azure public subnet IDs."
  value       = azurerm_subnet.public[*].id
}

output "azure_nsg_id" {
  description = "Default Azure Network Security Group ID."
  value       = try(azurerm_network_security_group.default[0].id, null)
}

# ============================================
# GOOGLE CLOUD OUTPUTS
# ============================================
output "gcp_network_id" {
  description = "Google Cloud VPC network ID."
  value       = try(google_compute_network.this[0].id, null)
}

output "gcp_network_self_link" {
  description = "Google Cloud VPC network self link."
  value       = try(google_compute_network.this[0].self_link, null)
}

output "gcp_private_subnet_ids" {
  description = "Google Cloud private subnet IDs."
  value       = google_compute_subnetwork.private[*].id
}

output "gcp_public_subnet_ids" {
  description = "Google Cloud public subnet IDs."
  value       = google_compute_subnetwork.public[*].id
}

output "gcp_router_id" {
  description = "Google Cloud Router ID."
  value       = try(google_compute_router.this[0].id, null)
}

# ============================================
# PROVIDER-NEUTRAL CONSUMER OUTPUTS
# ============================================
output "private_subnet_ids" {
  description = "Private subnet IDs for the selected provider implementation."
  value = coalesce(
    length(aws_subnet.private) > 0 ? aws_subnet.private[*].id : null,
    length(azurerm_subnet.private) > 0 ? azurerm_subnet.private[*].id : null,
    length(google_compute_subnetwork.private) > 0 ? google_compute_subnetwork.private[*].id : null,
    []
  )
}

output "public_subnet_ids" {
  description = "Public subnet IDs for the selected provider implementation."
  value = coalesce(
    length(aws_subnet.public) > 0 ? aws_subnet.public[*].id : null,
    length(azurerm_subnet.public) > 0 ? azurerm_subnet.public[*].id : null,
    length(google_compute_subnetwork.public) > 0 ? google_compute_subnetwork.public[*].id : null,
    []
  )
}

output "tags" {
  description = "Common metadata applied by the module."
  value       = local.common_tags
}
