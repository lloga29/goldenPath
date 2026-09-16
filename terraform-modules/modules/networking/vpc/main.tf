# Multi-provider VPC/VNet/network reference module.
# Supports AWS, Azure, and Google Cloud reference implementations.

# Common metadata applied to supported resources.
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
    # Production deletion protection must be implemented by the consuming stack/policy.
    prevent_destroy = false
  }
}

# AWS Internet Gateway.
resource "aws_internet_gateway" "this" {
  count = var.cloud_provider == "aws" ? 1 : 0

  vpc_id = aws_vpc.this[0].id

  tags = merge(local.common_tags, {
    Name = "${var.name}-igw"
  })
}

# AWS private subnets.
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

# AWS public subnets.
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

# AWS VPC Flow Logs.
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

# Azure subnets.
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

# A default NSG is created as a reference object. Association and provider-native
# flow logging remain explicit responsibilities of the consuming Azure stack.
resource "azurerm_network_security_group" "default" {
  count = var.cloud_provider == "azure" ? 1 : 0

  name                = "${var.name}-default-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = local.common_tags
}

# ============================================
# GOOGLE CLOUD VPC NETWORK
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

# Google Cloud subnets.
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

# Google Cloud Router. A production NAT design requires additional configuration.
resource "google_compute_router" "this" {
  count = var.cloud_provider == "gcp" ? 1 : 0

  name    = "${var.name}-router"
  project = var.project_id
  region  = length(var.availability_zones) > 0 ? var.availability_zones[0] : "us-central1"
  network = google_compute_network.this[0].id
}
