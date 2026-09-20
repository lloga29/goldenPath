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
cosign
yq v4
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

For plan-based policy validation, run from the repository root or adjust the paths consistently:

```bash
terraform plan -out=tfplan
terraform show -json tfplan > tfplan.json
python3 platform-policies/scripts/validate-exceptions.py \
  platform-policies/policy-exceptions.yaml \
  --output /tmp/goldenpath-policy-exceptions.json
conftest test tfplan.json \
  --policy platform-policies/terraform/ \
  --policy platform-policies/lib/ \
  --policy platform-policies/wrappers/ \
  --data /tmp/goldenpath-policy-exceptions.json \
  --namespace goldenpath.terraform
```

The wrapper namespace is part of the policy contract; direct evaluation of implementation packages is not the supported exception-aware path.

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

Create a team/service path, set the Kustomize image `digest` to the exact signed OCI `sha256` release identity, and validate the rendered output:

```bash
kustomize build gitops-config/apps/<team>/<service>/overlays/dev
```

Do not use `newTag` as the authoritative promotion identity.

## 6. Promote a verified immutable digest

The repository contains a promotion helper:

```bash
cd gitops-config
./scripts/promote.sh \
  <team> <service> dev staging \
  sha256:<64-hex-digest>
```

The digest must already match the source environment. Before creating a promotion branch, the helper verifies the keyless Cosign image signature and signed SLSA provenance attestation for that exact digest against the trusted GitHub Actions workflow identity. The same digest is then written to the target desired state; no tag is resolved and no artifact is rebuilt.

For non-standard image/workflow layouts, set `TRUSTED_WORKFLOW_IDENTITY` explicitly before promotion.

## 7. Observe deployment state

In a connected environment, validate both GitOps and Kubernetes state:

```bash
argocd app get <application>
kubectl get deploy,pods,svc -n <namespace>
kubectl rollout status deployment/<service> -n <namespace>
```

Confirm the running container image ID matches the promoted digest rather than only checking a tag.

## 8. Production-readiness checklist

Before using the paved road for production, confirm at minimum:

- cloud workload identity is configured with least privilege;
- remote Terraform state is encrypted, locked, backed up, and access controlled;
- real clusters and Argo CD destinations are registered securely;
- registry retention and access controls are configured;
- generated releases successfully publish signatures and signed provenance in the real registry;
- the real GitOps promotion path successfully verifies those artifacts by digest;
- secret management is integrated;
- TLS and DNS ownership are operationalized;
- policy enforcement mode has been tested;
- metrics, logs, traces, alerts, SLOs, and ownership are configured;
- backup and recovery procedures have been tested;
- production approvals and branch protections are enabled;
- rollback and incident runbooks have been exercised.

Continue with the [architecture overview](architecture/overview.md) and [implementation guide](../golden-path-implementation-guide.md).


## 9. Run the v0.2.0 assurance path

For the supported ephemeral-runtime path, first verify dependencies:

```bash
python3 goldenpath doctor --scope all
```

Then execute the exact checkout through the official CLI:

```bash
ARTIFACT_DIR=/tmp/goldenpath-runtime-lab
SOURCE_REVISION="$(git rev-parse HEAD)"

python3 goldenpath validate --artifact-dir "$ARTIFACT_DIR"
python3 goldenpath lab up --artifact-dir "$ARTIFACT_DIR" --lab-id local-v020 --source-revision "$SOURCE_REVISION"
python3 goldenpath assure --artifact-dir "$ARTIFACT_DIR"
python3 goldenpath verify --artifact-dir "$ARTIFACT_DIR"
python3 goldenpath evidence show --artifact-dir "$ARTIFACT_DIR"
```

This path creates **runtime evidence** from the supported disposable Kubernetes lab. It does not convert that evidence into production validation. Production validation remains **NOT CLAIMED** until a separately identified real production environment is exercised and evidenced.
