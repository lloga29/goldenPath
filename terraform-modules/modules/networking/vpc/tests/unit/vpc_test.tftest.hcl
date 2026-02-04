# Tests unitarios para el módulo VPC
# Ejecutar con: terraform test

# Variables de prueba
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

# ============================================
# TEST: VPC se crea correctamente
# ============================================
run "vpc_creates_successfully" {
  command = plan

  assert {
    condition     = aws_vpc.this[0].cidr_block == "10.0.0.0/16"
    error_message = "El bloque CIDR de la VPC no coincide con el valor esperado"
  }

  assert {
    condition     = aws_vpc.this[0].enable_dns_hostnames == true
    error_message = "DNS hostnames debería estar habilitado"
  }

  assert {
    condition     = aws_vpc.this[0].enable_dns_support == true
    error_message = "DNS support debería estar habilitado"
  }
}

# ============================================
# TEST: VPC tiene tags requeridos
# ============================================
run "vpc_has_required_tags" {
  command = plan

  assert {
    condition     = contains(keys(aws_vpc.this[0].tags), "Environment")
    error_message = "La VPC debe tener el tag Environment"
  }

  assert {
    condition     = contains(keys(aws_vpc.this[0].tags), "ManagedBy")
    error_message = "La VPC debe tener el tag ManagedBy"
  }

  assert {
    condition     = contains(keys(aws_vpc.this[0].tags), "Team")
    error_message = "La VPC debe tener el tag Team"
  }

  assert {
    condition     = contains(keys(aws_vpc.this[0].tags), "CostCenter")
    error_message = "La VPC debe tener el tag CostCenter"
  }
}

# ============================================
# TEST: Subnets se crean correctamente
# ============================================
run "subnets_created_correctly" {
  command = plan

  assert {
    condition     = length(aws_subnet.private) == 2
    error_message = "Deberían crearse 2 subnets privadas"
  }

  assert {
    condition     = length(aws_subnet.public) == 2
    error_message = "Deberían crearse 2 subnets públicas"
  }
}

# ============================================
# TEST: Flow logs habilitados por defecto
# ============================================
run "flow_logs_enabled_by_default" {
  command = plan

  assert {
    condition     = length(aws_flow_log.this) == 1
    error_message = "Flow logs deberían estar habilitados por defecto"
  }
}

# ============================================
# TEST: Nombre inválido falla validación
# ============================================
run "invalid_name_fails_validation" {
  command = plan

  variables {
    name = "INVALID_NAME"  # Mayúsculas no permitidas
  }

  expect_failures = [var.name]
}

# ============================================
# TEST: Entorno inválido falla validación
# ============================================
run "invalid_environment_fails_validation" {
  command = plan

  variables {
    environment = "invalid_env"
  }

  expect_failures = [var.environment]
}

# ============================================
# TEST: CIDR inválido falla validación
# ============================================
run "invalid_cidr_fails_validation" {
  command = plan

  variables {
    cidr_block = "invalid-cidr"
  }

  expect_failures = [var.cidr_block]
}

# ============================================
# TEST: Tags sin Team falla validación
# ============================================
run "missing_team_tag_fails_validation" {
  command = plan

  variables {
    tags = {
      CostCenter = "cc-001"
      # Falta Team
    }
  }

  expect_failures = [var.tags]
}

# ============================================
# TEST: Cloud provider inválido falla
# ============================================
run "invalid_cloud_provider_fails" {
  command = plan

  variables {
    cloud_provider = "invalid"
  }

  expect_failures = [var.cloud_provider]
}
