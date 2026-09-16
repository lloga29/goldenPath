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

## Current platform add-ons

The baseline contains reference definitions for ingress-nginx, cert-manager, External Secrets, Prometheus stack, Loki, Tempo, and Gatekeeper.

## Application model

Applications use a Kustomize base with environment overlays. The `team-payments/payment-api` path is the current reference application.

Render an overlay before review:

```bash
kustomize build apps/team-payments/payment-api/overlays/dev
```

## Promotion

Promote an immutable image reference by changing desired state:

```bash
./scripts/promote.sh payments payment-api dev staging v1.2.3
```

Production implementations should prefer digests or registry-enforced immutable tags.

## Rollback

See [Rollback Procedure](docs/ROLLBACK_PROCEDURE.md). Git is the preferred recovery source; emergency runtime mutation must be reconciled back into Git.

## Environment behavior

Reference configuration demonstrates development, staging, and production differences. Actual auto-sync, pruning, approvals, and deployment authority must be validated in the real Argo CD and Git hosting configuration.

## Workflow note

The workflows under `gitops-config/.github/workflows/` are blueprints in this consolidated repository. They are not active repository-root GitHub Actions workflows here.
