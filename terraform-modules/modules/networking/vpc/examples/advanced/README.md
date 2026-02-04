# Ejemplo Avanzado - Módulo VPC

Este ejemplo muestra una configuración de producción con múltiples VPCs.

## Arquitectura

```
┌─────────────────────────────────────────────────────────────┐
│                     VPC Principal (10.100.0.0/16)           │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │ Public-1a   │  │ Public-1b   │  │ Public-1c   │         │
│  │ (ALB/NLB)   │  │ (ALB/NLB)   │  │ (ALB/NLB)   │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │ Private-1a  │  │ Private-1b  │  │ Private-1c  │         │
│  │ (Apps/EKS)  │  │ (Apps/EKS)  │  │ (Apps/EKS)  │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
└─────────────────────────────────────────────────────────────┘
                            │
                     VPC Peering
                            │
┌─────────────────────────────────────────────────────────────┐
│                     VPC Datos (10.200.0.0/16)               │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │ Private-1a  │  │ Private-1b  │  │ Private-1c  │         │
│  │ (RDS/Cache) │  │ (RDS/Cache) │  │ (RDS/Cache) │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
└─────────────────────────────────────────────────────────────┘
```

## Características

- Alta disponibilidad en 3 AZs
- Separación de cargas de trabajo (apps vs datos)
- Flow logs para auditoría
- Tags de compliance (PCI-DSS)

## Uso

```bash
terraform init
terraform plan
terraform apply
```

## Consideraciones de Seguridad

- La VPC de datos no tiene subnets públicas
- Se recomienda configurar VPC Peering entre las VPCs
- Los Security Groups deben restringir el tráfico entre VPCs
