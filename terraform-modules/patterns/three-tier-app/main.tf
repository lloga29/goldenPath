# Three-tier network-foundation reference pattern.
# Composes the network module with application/database subnet and security-group references.

terraform {
  required_version = ">= 1.5.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0, < 6.0.0"
    }
  }
}

variable "name" {
  description = "Application identifier."
  type        = string
}

variable "environment" {
  description = "Deployment environment."
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block."
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones used for subnet placement."
  type        = list(string)
}

variable "database_engine" {
  description = "Reserved roadmap input; the current pattern does not create a database resource."
  type        = string
  default     = "postgres"
}

variable "database_instance_class" {
  description = "Reserved roadmap input; the current pattern does not create a database resource."
  type        = string
  default     = "db.t3.micro"
}

variable "enable_cache" {
  description = "Reserved roadmap input; the current pattern does not create a cache resource."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Metadata applied to supported resources."
  type        = map(string)
}

locals {
  common_tags = merge(
    var.tags,
    {
      Pattern     = "three-tier-app"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  )

  # Derive example subnet CIDRs from the VPC range.
  private_subnet_cidrs = [
    cidrsubnet(var.vpc_cidr, 8, 1),
    cidrsubnet(var.vpc_cidr, 8, 2),
    cidrsubnet(var.vpc_cidr, 8, 3),
  ]

  public_subnet_cidrs = [
    cidrsubnet(var.vpc_cidr, 8, 101),
    cidrsubnet(var.vpc_cidr, 8, 102),
    cidrsubnet(var.vpc_cidr, 8, 103),
  ]

  database_subnet_cidrs = [
    cidrsubnet(var.vpc_cidr, 8, 201),
    cidrsubnet(var.vpc_cidr, 8, 202),
    cidrsubnet(var.vpc_cidr, 8, 203),
  ]
}

# Layer 1: network foundation.
module "vpc" {
  source = "../../modules/networking/vpc"

  name           = "${var.name}-${var.environment}"
  cidr_block     = var.vpc_cidr
  environment    = var.environment
  cloud_provider = "aws"

  availability_zones   = var.availability_zones
  private_subnet_cidrs = local.private_subnet_cidrs
  public_subnet_cidrs  = local.public_subnet_cidrs

  enable_flow_logs = true
  tags             = local.common_tags
}

# Database subnet references. The pattern does not create RDS itself.
resource "aws_subnet" "database" {
  count = length(local.database_subnet_cidrs)

  vpc_id            = module.vpc.vpc_id
  cidr_block        = local.database_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index % length(var.availability_zones)]

  tags = merge(local.common_tags, {
    Name = "${var.name}-${var.environment}-database-${count.index + 1}"
    Type = "database"
  })
}

# Layer 2: application network boundary. Compute is delivered separately, for example through GitOps.
resource "aws_security_group" "app" {
  name        = "${var.name}-${var.environment}-app-sg"
  description = "Application-tier security group"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Application HTTP traffic from the example public subnet ranges"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = local.public_subnet_cidrs
  }

  egress {
    description = "Outbound traffic; restrict this further for production workloads"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.name}-${var.environment}-app-sg"
  })
}

# Layer 3: data network boundary.
resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-${var.environment}-db-subnet-group"
  subnet_ids = aws_subnet.database[*].id

  tags = merge(local.common_tags, {
    Name = "${var.name}-${var.environment}-db-subnet-group"
  })
}

resource "aws_security_group" "database" {
  name        = "${var.name}-${var.environment}-db-sg"
  description = "Database-tier security group"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "PostgreSQL traffic from the application security group"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  tags = merge(local.common_tags, {
    Name = "${var.name}-${var.environment}-db-sg"
  })
}

output "vpc_id" {
  description = "VPC ID."
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs."
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private application subnet IDs."
  value       = module.vpc.private_subnet_ids
}

output "database_subnet_ids" {
  description = "Database subnet IDs."
  value       = aws_subnet.database[*].id
}

output "app_security_group_id" {
  description = "Application security group ID."
  value       = aws_security_group.app.id
}

output "database_security_group_id" {
  description = "Database security group ID."
  value       = aws_security_group.database.id
}

output "db_subnet_group_name" {
  description = "Database subnet group name."
  value       = aws_db_subnet_group.this.name
}
