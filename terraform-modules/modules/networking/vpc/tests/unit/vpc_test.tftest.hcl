# Terraform-native tests for the AWS branch of the VPC reference module.
# Run with: terraform test

mock_provider "aws" {}
mock_provider "azurerm" {}
mock_provider "google" {}

variables {
  name           = "test-vpc"
  cidr_block     = "10.0.0.0/16"
  environment    = "dev"
  cloud_provider = "aws"
  tags = {
    Team       = "platform"
    CostCenter = "cc-001"
  }
  availability_zones   = ["us-east-1a", "us-east-1b"]
  private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnet_cidrs  = ["10.0.101.0/24", "10.0.102.0/24"]
}

run "vpc_creates_successfully" {
  command = plan

  assert {
    condition     = aws_vpc.this[0].cidr_block == "10.0.0.0/16"
    error_message = "The AWS VPC CIDR block does not match the expected value."
  }

  assert {
    condition     = aws_vpc.this[0].enable_dns_hostnames == true
    error_message = "DNS hostnames must be enabled for this test fixture."
  }

  assert {
    condition     = aws_vpc.this[0].enable_dns_support == true
    error_message = "DNS support must be enabled for this test fixture."
  }
}

run "vpc_has_required_tags" {
  command = plan

  assert {
    condition     = contains(keys(aws_vpc.this[0].tags), "Environment")
    error_message = "The VPC must contain the Environment tag."
  }

  assert {
    condition     = contains(keys(aws_vpc.this[0].tags), "ManagedBy")
    error_message = "The VPC must contain the ManagedBy tag."
  }

  assert {
    condition     = contains(keys(aws_vpc.this[0].tags), "Team")
    error_message = "The VPC must contain the Team tag."
  }

  assert {
    condition     = contains(keys(aws_vpc.this[0].tags), "CostCenter")
    error_message = "The VPC must contain the CostCenter tag."
  }
}

run "subnets_created_correctly" {
  command = plan

  assert {
    condition     = length(aws_subnet.private) == 2
    error_message = "The fixture must create two private subnets."
  }

  assert {
    condition     = length(aws_subnet.public) == 2
    error_message = "The fixture must create two public subnets."
  }
}

run "flow_logs_enabled_by_default" {
  command = plan

  assert {
    condition     = length(aws_flow_log.this) == 1
    error_message = "VPC Flow Logs must be enabled by default for this fixture."
  }
}

run "invalid_name_fails_validation" {
  command = plan

  variables {
    name = "INVALID_NAME" # Uppercase and underscore are intentionally invalid.
  }

  expect_failures = [var.name]
}

run "invalid_environment_fails_validation" {
  command = plan

  variables {
    environment = "invalid_env"
  }

  expect_failures = [var.environment]
}

run "invalid_cidr_fails_validation" {
  command = plan

  variables {
    cidr_block = "invalid-cidr"
  }

  expect_failures = [var.cidr_block]
}

run "missing_team_tag_fails_validation" {
  command = plan

  variables {
    tags = {
      CostCenter = "cc-001"
      # Team is intentionally missing.
    }
  }

  expect_failures = [var.tags]
}

run "invalid_cloud_provider_fails" {
  command = plan

  variables {
    cloud_provider = "invalid"
  }

  expect_failures = [var.cloud_provider]
}
