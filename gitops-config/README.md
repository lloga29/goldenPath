# GitOps Configuration - Golden Path

Reference Kubernetes desired-state repository for Argo CD and Kustomize.

## Structure

```text
gitops-config/
├── argocd/
│   ├── projects/             # AppProject authorization boundaries
│   └── applicationsets/      # Application generation
├── clusters/                 # Environment/cluster metadata
├── platform/
│   ├── base/                 # Shared platform add-ons
│   └── overlays/             # Environment-specific platform configuration
├── apps/                     # Team/service application desired state
├── policies/                 # Gatekeeper examples
├── scripts/                  # Promotion and rollback helpers
└── docs/                     # GitOps operating procedures
```

## Reconciliation policy

Development and staging are configured for automated reconciliation in the reference ApplicationSets. **Production is deliberately manual**: the generated production Applications do not contain `syncPolicy.automated` and require an explicit Argo CD sync after the Git change has been approved.

Pruning is enabled in development, disabled in staging, and disabled in production by default.

## Application model

Applications use a Kustomize base with environment overlays. The `team-payments/payment-api` path is the current reference application.

Render an overlay before review:

```bash
kustomize build gitops-config/apps/team-payments/payment-api/overlays/dev
```

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

## Validation

The nested workflow blueprint validates Kustomize rendering, YAML syntax, rendered Kubernetes schemas, and the application policy bundle without swallowing failures. In the consolidated repository, root-level CI is tracked separately in issue #10.

## Platform add-on architecture gap

The current add-on manifests use Flux `HelmRelease` resources while the documented reconciler is Argo CD. That controller mismatch is intentionally tracked in issue #12 and must be resolved before treating the platform add-on layer as a self-contained production implementation.

## Placeholder configuration

`org/*` repositories, cluster URLs, and CODEOWNERS teams are reference placeholders. Adopters must replace them with real repository identities, cluster destinations, and GitHub teams.

## Workflow note

The workflows under `gitops-config/.github/workflows/` are blueprints in this consolidated repository. They are not active repository-root GitHub Actions workflows here.
