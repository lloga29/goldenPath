# GitHub Actions OIDC for AWS

Creates an AWS OIDC provider and role trust policy so GitHub Actions can obtain short-lived AWS credentials without storing AWS access keys in GitHub secrets.

## Security model

The role subject is constrained by both repository and branch. Production consumers should explicitly list trusted repositories and keep `allowed_branches` narrow. The default wildcard repository value is convenient for reference/testing but should not be used for a production role.

Terraform-state access is disabled unless exact bucket and DynamoDB lock-table ARNs are provided.

## Example

```hcl
module "github_oidc" {
  source = "git::https://github.com/example/platform-terraform-modules.git//modules/security/github-oidc?ref=v1.0.0"

  project     = "platform"
  environment = "prod"
  github_org  = "example-org"

  github_repos     = ["platform-stacks"]
  allowed_branches = ["main"]

  terraform_state_bucket_arn = "arn:aws:s3:::example-prod-terraform-state"
  terraform_lock_table_arn   = "arn:aws:dynamodb:us-east-1:123456789012:table/example-prod-terraform-locks"

  tags = {
    Team       = "platform"
    CostCenter = "cc-001"
  }
}
```

## GitHub Actions usage

```yaml
permissions:
  id-token: write
  contents: read

steps:
  - uses: aws-actions/configure-aws-credentials@v4
    with:
      role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
      aws-region: us-east-1
  - run: aws sts get-caller-identity
```

The role ARN is not a secret, although organizations may still store it as configuration. Review the AWS trust policy after every change to repository/branch scope.
