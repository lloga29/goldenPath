# GitOps Configuration - Golden Path

Reference Kubernetes desired state for Argo CD, Helm, Kustomize, and policy-controlled application delivery.

## Authoritative reconciler

Argo CD is the only Kubernetes reconciliation engine in the Golden Path baseline. Flux controllers and Flux `HelmRelease`/`HelmRepository` resources are intentionally not required.

Shared platform add-ons use Argo CD Helm sources. Their values remain in this Git repository so configuration changes receive the same review, history, and production approval controls as other desired state.

## Structure

```text
gitops-config/
├── argocd/
│   ├── projects/             # AppProject authorization and source boundaries
│   └── applicationsets/      # Application generation for teams and platform
├── clusters/                 # Environment/cluster metadata
├── platform/
│   ├── values/               # Versioned Helm values by platform component
│   └── resources/            # Git-native cluster resources such as GatewayClass
├── apps/                     # Team/service Kustomize desired state
├── policies/                 # Gatekeeper examples
├── examples/                 # Explicitly non-reconciled integration examples
├── scripts/                  # Promotion and rollback helpers
└── docs/                     # GitOps operating procedures
```

## Platform add-ons

`argocd/applicationsets/platform-apps.yaml` combines an explicit upstream chart source with this repository as a `$values` source. Component/chart versions are pinned in the ApplicationSet; values are loaded from `platform/values/<component>/common.yaml` plus an optional environment override.

The current compatibility pins are validated as repository state. Broad dependency refresh work, including the 2026 Grafana Community chart transition, is tracked separately in issue #25 so breaking chart migrations do not get hidden inside the control-plane correction.

Envoy Gateway replaces retired ingress-nginx as the reference Gateway API controller. The controller is installed from the upstream OCI Helm chart and `platform/resources/gateway-class.yaml` declares the platform-owned `GatewayClass`.

## Reconciliation policy

Development and staging are configured for automated reconciliation. **Production is deliberately manual**: generated production Applications omit `syncPolicy.automated` and require an explicit Argo CD sync after the Git change has been reviewed.

Pruning is enabled in development, disabled in staging, and disabled in production by default.

## Application model

Team Applications use Kustomize bases with environment overlays. The `team-payments/payment-api` path is the current reference application.

Render an overlay before review:

```bash
kustomize build gitops-config/apps/team-payments/payment-api/overlays/dev
```

## Secrets integration

The platform installs External Secrets Operator but does not declare a fake production secret backend. `examples/external-secrets/cluster-secret-store-vault.example.yaml` is deliberately outside reconciled paths and uses an `.invalid` endpoint. Adopters must provide an approved backend, authentication model, and real endpoint in environment-owned desired state.

## Promotion

Promotion follows build-once/promote-many semantics. `promote.sh` accepts only `dev -> staging` or `staging -> prod`, verifies that the requested immutable tag is already present in the source environment, requires a clean worktree, and refuses to commit unless Git is configured as:

```text
Juan Gallo <lloga29@gmail.com>
```

```bash
./gitops-config/scripts/promote.sh payments payment-api dev staging v1.2.3
```

Production implementations should prefer registry-enforced immutable tags or digests.

## Rollback

See [Rollback Procedure](docs/ROLLBACK_PROCEDURE.md). Rollbacks are performed on a dedicated branch and returned through a pull request. Direct rollback pushes to `main` are not part of the paved road.

For the ingress-nginx retirement path, see [ingress-nginx to Gateway API Migration](../docs/operations/ingress-nginx-to-gateway-api.md).

## Validation

Root CI validates Kustomize rendering, structured files, policy fixtures, the Argo CD platform contract, and pinned Helm renders. Nested workflows remain reusable blueprints rather than the authoritative CI for this consolidated repository.

## Placeholder configuration

Cluster URLs and example team repositories under `org/*` are reference placeholders. Adopters must replace them with real repository identities, cluster destinations, and GitHub teams before installation. They are kept explicit so placeholder state cannot be mistaken for a production deployment.

## Workflow note

The workflows under `gitops-config/.github/workflows/` are blueprints in this consolidated repository. They are not active repository-root GitHub Actions workflows here.
