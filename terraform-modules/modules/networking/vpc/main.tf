# Módulo VPC Cloud-Agnostic
# Soporta AWS, Azure y GCP

# Tags comunes para todos los recursos
locals {
  common_tags = merge(
    var.tags,
    {
      Module      = "networking/vpc"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  )
}

# ============================================
# AWS VPC
# ============================================
resource "aws_vpc" "this" {
  count = var.cloud_provider == "aws" ? 1 : 0

  cidr_block           = var.cidr_block
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = merge(local.common_tags, {
    Name = var.name
  })

  lifecycle {
    # Proteger VPCs de producción contra eliminación accidental
    prevent_destroy = false  # Se sobreescribe en producción
  }
}

# Internet Gateway para AWS
resource "aws_internet_gateway" "this" {
  count = var.cloud_provider == "aws" ? 1 : 0

  vpc_id = aws_vpc.this[0].id

  tags = merge(local.common_tags, {
    Name = "${var.name}-igw"
  })
}

# Subnets privadas para AWS
resource "aws_subnet" "private" {
  count = var.cloud_provider == "aws" ? length(var.private_subnet_cidrs) : 0

  vpc_id            = aws_vpc.this[0].id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = length(var.availability_zones) > 0 ? var.availability_zones[count.index % length(var.availability_zones)] : null

  tags = merge(local.common_tags, {
    Name = "${var.name}-private-${count.index + 1}"
    Type = "private"
  })
}

# Subnets públicas para AWS
resource "aws_subnet" "public" {
  count = var.cloud_provider == "aws" ? length(var.public_subnet_cidrs) : 0

  vpc_id                  = aws_vpc.this[0].id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = length(var.availability_zones) > 0 ? var.availability_zones[count.index % length(var.availability_zones)] : null
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${var.name}-public-${count.index + 1}"
    Type = "public"
  })
}

# Flow Logs para AWS
resource "aws_flow_log" "this" {
  count = var.cloud_provider == "aws" && var.enable_flow_logs ? 1 : 0

  vpc_id               = aws_vpc.this[0].id
  traffic_type         = "ALL"
  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_cloudwatch_log_group.flow_logs[0].arn
  iam_role_arn         = aws_iam_role.flow_logs[0].arn

  tags = merge(local.common_tags, {
    Name = "${var.name}-flow-logs"
  })
}

resource "aws_cloudwatch_log_group" "flow_logs" {
  count = var.cloud_provider == "aws" && var.enable_flow_logs ? 1 : 0

  name              = "/aws/vpc/${var.name}/flow-logs"
  retention_in_days = 30

  tags = local.common_tags
}

resource "aws_iam_role" "flow_logs" {
  count = var.cloud_provider == "aws" && var.enable_flow_logs ? 1 : 0

  name = "${var.name}-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "flow_logs" {
  count = var.cloud_provider == "aws" && var.enable_flow_logs ? 1 : 0

  name = "${var.name}-flow-logs-policy"
  role = aws_iam_role.flow_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      }
    ]
  })
}

# ============================================
# AZURE VIRTUAL NETWORK
# ============================================
resource "azurerm_virtual_network" "this" {
  count = var.cloud_provider == "azure" ? 1 : 0

  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = [var.cidr_block]

  tags = local.common_tags

  lifecycle {
    prevent_destroy = false
  }
}

# Subnets para Azure
resource "azurerm_subnet" "private" {
  count = var.cloud_provider == "azure" ? length(var.private_subnet_cidrs) : 0

  name                 = "${var.name}-private-${count.index + 1}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this[0].name
  address_prefixes     = [var.private_subnet_cidrs[count.index]]
}

resource "azurerm_subnet" "public" {
  count = var.cloud_provider == "azure" ? length(var.public_subnet_cidrs) : 0

  name                 = "${var.name}-public-${count.index + 1}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this[0].name
  address_prefixes     = [var.public_subnet_cidrs[count.index]]
}

# Network Watcher Flow Logs para Azure
resource "azurerm_network_watcher_flow_log" "this" {
  count = var.cloud_provider == "azure" && var.enable_flow_logs ? 1 : 0

  name                 = "${var.name}-flow-logs"
  network_watcher_name = "NetworkWatcher_${var.location}"
  resource_group_name  = "NetworkWatcherRG"

  network_security_group_id = azurerm_network_security_group.default[0].id
  storage_account_id        = "" # Se debe proporcionar externamente

  enabled = true

  retention_policy {
    enabled = true
    days    = 30
  }

  tags = local.common_tags
}

resource "azurerm_network_security_group" "default" {
  count = var.cloud_provider == "azure" ? 1 : 0

  name                = "${var.name}-default-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = local.common_tags
}

# ============================================
# GCP VPC NETWORK
# ============================================
resource "google_compute_network" "this" {
  count = var.cloud_provider == "gcp" ? 1 : 0

  name                    = var.name
  project                 = var.project_id
  auto_create_subnetworks = var.auto_create_subnetworks

  lifecycle {
    prevent_destroy = false
  }
}

# Subnets para GCP
resource "google_compute_subnetwork" "private" {
  count = var.cloud_provider == "gcp" ? length(var.private_subnet_cidrs) : 0

  name          = "${var.name}-private-${count.index + 1}"
  project       = var.project_id
  region        = length(var.availability_zones) > 0 ? var.availability_zones[count.index % length(var.availability_zones)] : "us-central1"
  network       = google_compute_network.this[0].id
  ip_cidr_range = var.private_subnet_cidrs[count.index]

  private_ip_google_access = true

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_subnetwork" "public" {
  count = var.cloud_provider == "gcp" ? length(var.public_subnet_cidrs) : 0

  name          = "${var.name}-public-${count.index + 1}"
  project       = var.project_id
  region        = length(var.availability_zones) > 0 ? var.availability_zones[count.index % length(var.availability_zones)] : "us-central1"
  network       = google_compute_network.this[0].id
  ip_cidr_range = var.public_subnet_cidrs[count.index]

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# Cloud Router para GCP (necesario para NAT)
resource "google_compute_router" "this" {
  count = var.cloud_provider == "gcp" ? 1 : 0

  name    = "${var.name}-router"
  project = var.project_id
  region  = length(var.availability_zones) > 0 ? var.availability_zones[0] : "us-central1"
  network = google_compute_network.this[0].id
}
