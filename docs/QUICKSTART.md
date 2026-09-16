# Golden Path Quickstart

This quickstart demonstrates the reference paved road using the capabilities that are actually present in this repository.

## Prerequisites

Recommended local tools:

```text
git
terraform >= 1.5
kubectl
kustomize
conftest
copier
Go (for the Go service template)
```

Optional tools depend on the workflow being tested: `gh`, cloud CLIs, Checkov, tfsec, Infracost, and Argo CD CLI.

## 1. Generate a Go service

The repository currently implements one service template: `microservice-golang`.

```bash
copier copy ./service-templates/templates/microservice-golang ./my-service
cd my-service
```

Answer the Copier prompts, then inspect the generated repository before committing it.

## 2. Validate the generated service

Typical local validation:

```bash
go test ./...
go vet ./...
docker build -t my-service:local .
```

The generated template also contains its own CI workflow blueprint and pre-commit configuration.

## 3. Create or initialize an infrastructure client

From `platform-stacks/`:

```bash
./scripts/init-client.sh --name example --cloud aws --region us-east-1
```

Review every generated file before applying infrastructure. The reference templates contain placeholders and assume that real backends, cloud identity, account boundaries, and organization-specific values will be configured before production use.

## 4. Validate Terraform

For an existing stack:

```bash
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
```

For plan-based policy validation:

```bash
terraform plan -out=tfplan
terraform show -json tfplan > tfplan.json
conftest test tfplan.json --policy ../../../platform-policies/terraform/
```

Adjust the policy path for the stack location.

## 5. Register an application in GitOps

Use the existing `payment-api` layout as a reference:

```text
gitops-config/apps/team-payments/payment-api/
├── base/
└── overlays/
    ├── dev/
    ├── staging/
    └── prod/
```

Create a team/service path, update the Kustomize resources and image reference, and validate the rendered output:

```bash
kustomize build gitops-config/apps/<team>/<service>/overlays/dev
```

## 6. Promote an immutable version

The repository contains a promotion helper:

```bash
cd gitops-config
./scripts/promote.sh <team> <service> dev staging <immutable-tag>
```

Do not promote `:latest`. Promotion should change desired state in Git; Argo CD then reconciles that state to the target cluster.

## 7. Observe deployment state

In a connected environment, validate both GitOps and Kubernetes state:

```bash
argocd app get <application>
kubectl get deploy,pods,svc -n <namespace>
kubectl rollout status deployment/<service> -n <namespace>
```

## 8. Production-readiness checklist

Before using the paved road for production, confirm at minimum:

- cloud workload identity is configured with least privilege;
- remote Terraform state is encrypted, locked, backed up, and access controlled;
- real clusters and Argo CD destinations are registered securely;
- registry immutability and retention are configured;
- secret management is integrated;
- TLS and DNS ownership are operationalized;
- policy enforcement mode has been tested;
- metrics, logs, traces, alerts, SLOs, and ownership are configured;
- backup and recovery procedures have been tested;
- production approvals and branch protections are enabled;
- rollback and incident runbooks have been exercised.

Continue with the [architecture overview](architecture/overview.md) and [implementation guide](../golden-path-implementation-guide.md).
