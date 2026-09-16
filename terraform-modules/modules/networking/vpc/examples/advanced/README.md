# Advanced VPC Example

This example composes two AWS VPC instances to illustrate separation between application and data network address spaces.

## Important limitation

The example does **not** create VPC peering, route tables, NAT gateways, security groups, or firewall rules between these networks. Those controls must be designed explicitly before treating the topology as production-ready.

## Characteristics demonstrated

- Three availability zones.
- Separate application and data CIDR ranges.
- No public subnet list for the data VPC.
- VPC Flow Logs enabled.
- Ownership, cost, compliance, and data-classification metadata examples.

## Usage

```bash
terraform init
terraform plan
```

Review the plan in a disposable environment before any apply.
