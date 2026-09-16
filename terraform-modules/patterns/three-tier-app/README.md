# Three-Tier Network Foundation Pattern

This pattern is an **infrastructure reference**, not a complete three-tier application deployment.

## What it currently creates

- An AWS VPC through the shared network module.
- Public and private application subnet ranges.
- Dedicated database subnets.
- An application security group.
- A database security group allowing PostgreSQL from the application security group.
- An RDS DB subnet group.
- VPC Flow Logs through the network module.

## What it does not create

The current pattern does not create an ALB/NLB, EKS/ECS cluster, application compute, RDS instance, cache, NAT gateways, route tables, WAF, DNS, certificates, or application deployment. The inputs `database_engine`, `database_instance_class`, and `enable_cache` are retained as roadmap placeholders but do not currently create resources.

## Example

```hcl
module "network_foundation" {
  source = "git::https://github.com/example/platform-terraform-modules.git//patterns/three-tier-app?ref=v1.0.0"

  name        = "payments"
  environment = "prod"
  vpc_cidr    = "10.0.0.0/16"

  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

  tags = {
    Team       = "payments"
    CostCenter = "cc-001"
  }
}
```

## Security review before production

The application security-group example currently allows outbound traffic to `0.0.0.0/0` and HTTP ingress from the example public-subnet CIDRs. Production architectures should replace these broad reference rules with the actual load-balancer/security-group and egress requirements. Add deletion protection, routing/NAT, database encryption/backup, and workload controls in the higher-level stack.
