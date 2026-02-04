# Ejemplo Básico - Módulo VPC

Este ejemplo muestra cómo crear una VPC básica en AWS con subnets públicas y privadas.

## Uso

```bash
terraform init
terraform plan
terraform apply
```

## Recursos Creados

- 1 VPC con CIDR 10.0.0.0/16
- 2 Subnets privadas
- 2 Subnets públicas
- 1 Internet Gateway
- Flow Logs habilitados

## Requisitos

- Terraform >= 1.5.0
- AWS Provider configurado
- Credenciales AWS con permisos para crear VPCs
