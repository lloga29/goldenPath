# Basic AWS usage example for the network reference module.

module "vpc" {
  source = "../../"

  name           = "example-vpc-dev"
  cidr_block     = "10.0.0.0/16"
  environment    = "dev"
  cloud_provider = "aws"

  # Subnets across two availability zones.
  availability_zones   = ["us-east-1a", "us-east-1b"]
  private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnet_cidrs  = ["10.0.101.0/24", "10.0.102.0/24"]

  # Enabled by default; repeated here for clarity.
  enable_flow_logs = true

  # Required ownership/cost metadata.
  tags = {
    Team       = "platform"
    CostCenter = "cc-001"
    Owner      = "platform@example.com"
    Project    = "golden-path"
  }
}

output "vpc_id" {
  description = "Created AWS VPC ID."
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "Created private subnet IDs."
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "Created public subnet IDs."
  value       = module.vpc.public_subnet_ids
}
