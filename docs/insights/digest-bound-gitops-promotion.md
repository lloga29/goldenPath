# Digest-bound GitOps promotion: build once, promote one verified identity

"Build once, promote many" is easy to say and surprisingly easy to break.

If staging and production resolve a mutable tag independently, they may deploy different bytes. If every environment rebuilds the application, the artifact validated in one stage is not necessarily the artifact deployed in the next.

GoldenPath treats the OCI digest as the promotion authority.

## Promotion accepts one exact digest

The reference `promote.sh` contract accepts only an exact lowercase `sha256:<64-hex>` digest for:

- `dev -> staging`;
- `staging -> prod`.

The requested digest must already match the source environment's desired state.

Tags are not accepted as promotion authority.

## Trust before mutation

Before creating the promotion branch or changing target desired state, the helper verifies:

1. the digest format;
2. source digest continuity;
3. source/target image-name continuity;
4. the keyless image signature for the exact digest;
5. the signed SLSA provenance attestation for the exact digest;
6. the expected workflow identity and OIDC issuer.

If trust verification fails, desired state must remain unchanged.

That ordering matters. Verification after mutation would turn a trust failure into a cleanup problem instead of a blocked promotion.

## Preserve the same identity through environments

The repository regression harness proves that the synthetic digest copied from development to staging is the same digest later copied from staging to production.

It also rejects reintroduction of `newTag`-based desired state.

The intended flow is:

```text
Development digest -> Staging digest -> Production digest
          same verified sha256 identity
```

## Inspect the implementation

Key repository evidence:

- `gitops-config/scripts/promote.sh`
- `gitops-config/scripts/test-promotion-contract.sh`
- `gitops-config/docs/PROMOTION_GUIDE.md`
- `.github/workflows/repository-validation.yaml`

Run the contract locally:

```bash
./gitops-config/scripts/test-promotion-contract.sh
```

Or run it as part of the composed public showcase:

```bash
./scripts/showcase-delivery.sh
```

## Why the regression harness uses fake tools

The harness uses isolated fake `yq` and `cosign` executables so it can deterministically verify command ordering, failure handling, signer binding, and desired-state mutation without requiring external infrastructure.

That is a strength for repository regression testing, but it is also an evidence boundary.

## What this proves

Repository/reference evidence demonstrates digest-only input, source/target continuity, trust-before-mutation behavior, expected verification commands, and exact digest continuity through the reference overlays.

## What this does not prove

It does not prove that a real registry accepted the artifact, that real Cosign verification succeeded, that Argo CD reconciled the target, that Kubernetes ran the promoted digest, or that the workload was healthy.

Those stronger claims require a disposable or real runtime path with retained registry, GitOps, cluster, rollout, health, SLO, rollback, and business-transaction evidence.
