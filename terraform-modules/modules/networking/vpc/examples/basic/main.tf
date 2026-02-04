# Ejemplo básico de uso del módulo VPC
# Este ejemplo crea una VPC simple en AWS

module "vpc" {
  source = "../../"

  name           = "example-vpc-dev"
  cidr_block     = "10.0.0.0/16"
  environment    = "dev"
  cloud_provider = "aws"

  # Subnets en 2 AZs
  availability_zones   = ["us-east-1a", "us-east-1b"]
  private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnet_cidrs  = ["10.0.101.0/24", "10.0.102.0/24"]

  # Flow logs habilitados (por defecto)
  enable_flow_logs = true

  # Tags obligatorios
  tags = {
    Team       = "platform"
    CostCenter = "cc-001"
    Owner      = "platform@example.com"
    Project    = "golden-path"
  }
}

# Outputs para verificar
output "vpc_id" {
  description = "ID de la VPC creada"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "IDs de las subnets privadas"
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "IDs de las subnets públicas"
  value       = module.vpc.public_subnet_ids
}
