# Advanced AWS example showing separate application and data VPC address spaces.

# Primary application VPC.
module "vpc_prod" {
  source = "../../"

  name           = "prod-vpc"
  cidr_block     = "10.100.0.0/16"
  environment    = "prod"
  cloud_provider = "aws"

  # Multi-AZ placement for the example subnet layout.
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

  # One private subnet per availability zone.
  private_subnet_cidrs = [
    "10.100.1.0/24", # AZ-a: applications
    "10.100.2.0/24", # AZ-b: applications
    "10.100.3.0/24", # AZ-c: applications
  ]

  # One public subnet per availability zone.
  public_subnet_cidrs = [
    "10.100.101.0/24", # AZ-a: load balancers
    "10.100.102.0/24", # AZ-b: load balancers
    "10.100.103.0/24", # AZ-c: load balancers
  ]

  enable_flow_logs     = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Governance and cost-allocation metadata example.
  tags = {
    Team       = "platform"
    CostCenter = "cc-prod-001"
    Owner      = "platform@example.com"
    Project    = "golden-path"
    Compliance = "pci-dss"
    DataClass  = "confidential"
  }
}

# Secondary data VPC reference.
module "vpc_data" {
  source = "../../"

  name           = "prod-data-vpc"
  cidr_block     = "10.200.0.0/16"
  environment    = "prod"
  cloud_provider = "aws"

  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

  # Private subnets only in this example.
  private_subnet_cidrs = [
    "10.200.1.0/24",
    "10.200.2.0/24",
    "10.200.3.0/24",
  ]

  public_subnet_cidrs = []

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
