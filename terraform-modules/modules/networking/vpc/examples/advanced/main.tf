# Ejemplo avanzado de uso del módulo VPC
# Este ejemplo crea una VPC con configuración completa para producción

# VPC Principal
module "vpc_prod" {
  source = "../../"

  name           = "prod-vpc"
  cidr_block     = "10.100.0.0/16"
  environment    = "prod"
  cloud_provider = "aws"

  # Multi-AZ para alta disponibilidad
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

  # Subnets privadas - una por AZ
  private_subnet_cidrs = [
    "10.100.1.0/24",   # AZ-a: Aplicaciones
    "10.100.2.0/24",   # AZ-b: Aplicaciones
    "10.100.3.0/24",   # AZ-c: Aplicaciones
  ]

  # Subnets públicas - una por AZ
  public_subnet_cidrs = [
    "10.100.101.0/24", # AZ-a: Load Balancers
    "10.100.102.0/24", # AZ-b: Load Balancers
    "10.100.103.0/24", # AZ-c: Load Balancers
  ]

  # Seguridad
  enable_flow_logs     = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Tags para governance y cost allocation
  tags = {
    Team        = "platform"
    CostCenter  = "cc-prod-001"
    Owner       = "platform@example.com"
    Project     = "golden-path"
    Compliance  = "pci-dss"
    DataClass   = "confidential"
  }
}

# VPC Secundaria para Datos
module "vpc_data" {
  source = "../../"

  name           = "prod-data-vpc"
  cidr_block     = "10.200.0.0/16"
  environment    = "prod"
  cloud_provider = "aws"

  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

  # Solo subnets privadas para bases de datos
  private_subnet_cidrs = [
    "10.200.1.0/24",
    "10.200.2.0/24",
    "10.200.3.0/24",
  ]

  public_subnet_cidrs = []  # Sin subnets públicas

  enable_flow_logs = true

  tags = {
    Team       = "data"
    CostCenter = "cc-data-001"
    Owner      = "data@example.com"
    Project    = "golden-path"
    Compliance = "pci-dss"
    DataClass  = "highly-confidential"
  }
}

# Outputs
output "main_vpc_id" {
  value = module.vpc_prod.vpc_id
}

output "data_vpc_id" {
  value = module.vpc_data.vpc_id
}

output "main_vpc_private_subnets" {
  value = module.vpc_prod.private_subnet_ids
}

output "data_vpc_private_subnets" {
  value = module.vpc_data.private_subnet_ids
}
