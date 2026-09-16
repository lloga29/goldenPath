# Basic VPC Example

This example plans an AWS VPC reference with public and private subnets.

## Usage

```bash
terraform init
terraform plan
```

Only run `terraform apply` in a disposable/test account after reviewing the plan and cleanup path.

## Planned resources

- One VPC using `10.0.0.0/16`.
- Two private subnets.
- Two public subnets.
- One Internet Gateway.
- VPC Flow Logs when `enable_flow_logs` remains enabled.

## Requirements

- Terraform 1.5 or later within the module constraint.
- AWS provider credentials for any real plan/apply that requires provider API access.
- IAM permissions appropriate to the resources being tested.
