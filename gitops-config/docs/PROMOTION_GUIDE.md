# GitOps Promotion Guide

## Principle: Build Once, Promote One Digest

Release artifacts are built once and promoted between environments without rebuilding or resolving a mutable tag.

- Promotion accepts only an exact lowercase `sha256:<64-hex>` OCI digest.
- The requested digest must already be the source environment's desired-state digest.
- Before changing target desired state, the helper verifies both the image signature and a signed SLSA provenance attestation for that exact digest.
- Promotion changes desired state; it does not create a new executable artifact.

Kubernetes documents image digests as the identity that pins the exact image bytes, and Kustomize can set an image digest directly in the `images` transformer. Tags are therefore not part of the GoldenPath promotion authority.

## Trust identity

For the standard generated-service layout `ghcr.io/<owner>/<repository>`, `promote.sh` derives the expected signer identity as:

```text
https://github.com/<owner>/<repository>/.github/workflows/ci.yaml@refs/heads/main
```

The default OIDC issuer is:

```text
https://token.actions.githubusercontent.com
```

For a non-standard registry or workflow path, set `TRUSTED_WORKFLOW_IDENTITY` explicitly. `TRUSTED_OIDC_ISSUER` may be overridden only when the adopted signing infrastructure intentionally uses another trusted issuer.

## Flow

```text
Development digest -> Staging digest -> Production digest
          same verified sha256 identity
```

## Development to staging

```bash
./scripts/promote.sh \
  <team> <service> dev staging \
  sha256:<64-hex-digest>
```

The helper fails before creating a branch if the digest is malformed, differs from the source environment, the image names differ between environments, the keyless image signature is untrusted, or the signed SLSA attestation cannot be verified.

Review the resulting Kustomize change and render the target overlay before merge:

```bash
kustomize build apps/team-<team>/<service>/overlays/staging
```

## Staging to production

```bash
./scripts/promote.sh \
  <team> <service> staging prod \
  sha256:<64-hex-digest>
```

The exact staging digest is copied to production only after the same signature and signed-provenance verification succeeds again. Production promotion should additionally require the organization's configured review and environment protection rules. Do not rely on documentation alone to enforce reviewer counts or approvals.

## Pre-production checks

Artifact cryptographic verification is necessary but not sufficient. Confirm staging is healthy, required checks passed, migrations are compatible, relevant SLOs/alerts show no active regression, and rollback is understood.

## Evidence boundary

The repository regression harness exercises digest parsing, source/target continuity, fail-closed verification behavior, signer identity derivation, and desired-state mutation using isolated fake `yq` and `cosign` executables. Root CI also renders every Kustomize target.

That is repository/reference evidence. A real generated application, registry, GitOps repository, and target cluster must still execute the promotion path before it can be described as runtime-validated or production-validated.

## Post-promotion verification

```bash
argocd app get <application>
argocd app wait <application> --health --sync
kubectl get pods -n <namespace> -l app.kubernetes.io/name=<service>
```

Verify the running workload image ID matches the promoted digest, then validate service-level metrics and a representative business transaction in addition to pod health.

## Failure

If promotion causes degradation, use [Rollback Procedure](ROLLBACK_PROCEDURE.md) and the platform application rollback runbook.
