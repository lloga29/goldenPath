# Módulo VPC - Networking

Módulo cloud-agnostic para crear VPCs/Virtual Networks en AWS, Azure y GCP.

## Características

- Soporte multi-cloud (AWS, Azure, GCP)
- Subnets públicas y privadas
- Flow logs habilitados por defecto
- Validaciones de seguridad integradas
- Tags obligatorios para governance

## Uso

### AWS

```hcl
module "vpc" {
  source = "git::https://github.com/org/terraform-modules.git//modules/networking/vpc?ref=v1.0.0"

  name           = "mi-vpc-prod"
  cidr_block     = "10.0.0.0/16"
  environment    = "prod"
  cloud_provider = "aws"

  availability_zones   = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnet_cidrs  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_flow_logs = true

  tags = {
    Team       = "platform"
    CostCenter = "cc-001"
    Owner      = "platform@company.com"
  }
}
```

### Azure

```hcl
module "vnet" {
  source = "git::https://github.com/org/terraform-modules.git//modules/networking/vpc?ref=v1.0.0"

  name                = "mi-vnet-prod"
  cidr_block          = "10.0.0.0/16"
  environment         = "prod"
  cloud_provider      = "azure"
  location            = "eastus"
  resource_group_name = "rg-networking"

  private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnet_cidrs  = ["10.0.101.0/24", "10.0.102.0/24"]

  tags = {
    Team       = "platform"
    CostCenter = "cc-001"
  }
}
```

### GCP

```hcl
module "vpc" {
  source = "git::https://github.com/org/terraform-modules.git//modules/networking/vpc?ref=v1.0.0"

  name           = "mi-vpc-prod"
  cidr_block     = "10.0.0.0/16"
  environment    = "prod"
  cloud_provider = "gcp"
  project_id     = "mi-proyecto-gcp"

  availability_zones   = ["us-central1"]
  private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnet_cidrs  = ["10.0.101.0/24"]

  tags = {
    Team       = "platform"
    CostCenter = "cc-001"
  }
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0, < 2.0.0 |
| aws | >= 5.0.0, < 6.0.0 |
| azurerm | >= 3.0.0, < 4.0.0 |
| google | >= 5.0.0, < 6.0.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Nombre de la VPC | `string` | n/a | yes |
| cidr_block | Bloque CIDR para la VPC | `string` | n/a | yes |
| environment | Entorno (dev, staging, prod, ephemeral) | `string` | n/a | yes |
| cloud_provider | Proveedor cloud (aws, azure, gcp) | `string` | n/a | yes |
| tags | Tags obligatorios (Team, CostCenter) | `map(string)` | `{}` | yes |
| enable_flow_logs | Habilitar flow logs | `bool` | `true` | no |
| private_subnet_cidrs | CIDRs para subnets privadas | `list(string)` | `[]` | no |
| public_subnet_cidrs | CIDRs para subnets públicas | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | ID de la VPC creada |
| private_subnet_ids | IDs de las subnets privadas |
| public_subnet_ids | IDs de las subnets públicas |
<!-- END_TF_DOCS -->

## Seguridad

- Flow logs habilitados por defecto para auditoría
- DNS hostnames habilitados para resolución interna
- No se permiten CIDR blocks públicos en subnets privadas

## Testing

```bash
cd modules/networking/vpc
terraform init -backend=false
terraform test
```
