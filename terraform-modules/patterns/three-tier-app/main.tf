# Pattern: Arquitectura de 3 Capas
# Combina múltiples módulos para crear una aplicación estándar

terraform {
  required_version = ">= 1.5.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0, < 6.0.0"
    }
  }
}

# ============================================
# VARIABLES
# ============================================
variable "name" {
  description = "Nombre de la aplicación"
  type        = string
}

variable "environment" {
  description = "Entorno (dev, staging, prod)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR de la VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Zonas de disponibilidad"
  type        = list(string)
}

variable "database_engine" {
  description = "Motor de base de datos"
  type        = string
  default     = "postgres"
}

variable "database_instance_class" {
  description = "Clase de instancia de BD"
  type        = string
  default     = "db.t3.micro"
}

variable "enable_cache" {
  description = "Habilitar capa de cache"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags a aplicar"
  type        = map(string)
}

# ============================================
# LOCALS
# ============================================
locals {
  common_tags = merge(
    var.tags,
    {
      Pattern     = "three-tier-app"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  )

  # Calcular CIDRs para subnets
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

# ============================================
# CAPA 1: NETWORKING
# ============================================
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

  tags = local.common_tags
}

# Subnets para base de datos (aisladas)
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

# ============================================
# CAPA 2: APLICACIÓN (Placeholder para EKS/ECS)
# ============================================
# La capa de aplicación se despliega via GitOps
# Este pattern solo prepara la infraestructura base

# Security Group para aplicaciones
resource "aws_security_group" "app" {
  name        = "${var.name}-${var.environment}-app-sg"
  description = "Security group para capa de aplicacion"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "HTTP desde ALB"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = local.public_subnet_cidrs
  }

  egress {
    description = "Salida a internet"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.name}-${var.environment}-app-sg"
  })
}

# ============================================
# CAPA 3: DATOS
# ============================================
# Subnet group para RDS
resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-${var.environment}-db-subnet-group"
  subnet_ids = aws_subnet.database[*].id

  tags = merge(local.common_tags, {
    Name = "${var.name}-${var.environment}-db-subnet-group"
  })
}

# Security Group para base de datos
resource "aws_security_group" "database" {
  name        = "${var.name}-${var.environment}-db-sg"
  description = "Security group para capa de datos"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "PostgreSQL desde aplicaciones"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  tags = merge(local.common_tags, {
    Name = "${var.name}-${var.environment}-db-sg"
  })
}

# ============================================
# OUTPUTS
# ============================================
output "vpc_id" {
  description = "ID de la VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs de subnets públicas"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs de subnets privadas"
  value       = module.vpc.private_subnet_ids
}

output "database_subnet_ids" {
  description = "IDs de subnets de base de datos"
  value       = aws_subnet.database[*].id
}

output "app_security_group_id" {
  description = "ID del security group de aplicaciones"
  value       = aws_security_group.app.id
}

output "database_security_group_id" {
  description = "ID del security group de base de datos"
  value       = aws_security_group.database.id
}

output "db_subnet_group_name" {
  description = "Nombre del subnet group de base de datos"
  value       = aws_db_subnet_group.this.name
}
