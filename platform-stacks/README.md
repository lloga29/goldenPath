# Platform Stacks - Golden Path

Reference Terraform compositions for client, foundation, environment, and ephemeral infrastructure.

## Structure

```text
_templates/          # Bootstrap/environment templates
shared/              # Backend/provider conventions
clients/             # Client-specific stacks
  └── client-<name>/
      ├── bootstrap/     # Remote state and CI identity bootstrap
      ├── foundation/    # Shared client foundation
      └── environments/  # dev/staging/prod compositions
ephemeral/           # Pull-request environment reference
teams/               # Reserved for team-owned stack composition
```

## Current cloud scope

Although the broader Golden Path documents AWS, Azure, and Google Cloud patterns, the executable client/bootstrap/environment templates in `platform-stacks` are currently **AWS-specific**. `scripts/init-client.sh` therefore intentionally accepts only `--cloud aws` until provider-specific templates are implemented and validated.

## Create a reference client

```bash
./scripts/init-client.sh --name example --cloud aws --region us-east-1
```

Review all generated files before applying them. The templates contain reference names and assume organization-specific identity, account, state, and module-source decisions.

## Terraform workflow

```bash
cd clients/client-acme/environments/dev
terraform init
terraform plan
```

Run `terraform apply` only through the approved environment/change process.

## CI/CD blueprints

The nested workflows demonstrate pull-request plan/security/policy/cost checks, controlled apply, and drift detection. In this consolidated repository they are reference files, not active GitHub Actions workflows. They must be moved to a repository-root `.github/workflows/` location or replaced by root monorepo workflows.

## State and identity

The AWS reference uses an encrypted/versioned S3 bucket and a DynamoDB lock table in the bootstrap stack, plus GitHub OIDC for CI identity. Production implementations must validate current Terraform/AWS backend recommendations, backup/recovery, IAM scope, and break-glass access.

## Metadata

Use consistent ownership, environment, client, cost-center, and managed-by tags. Never treat placeholder account IDs, domains, roles, or module URLs as deployable production values.
