# End-to-end evidence-backed delivery showcase

This P2 showcase connects GoldenPath's existing assurance and GitOps contracts into one coherent repository/reference journey. It is intentionally executable without cloud credentials or a live Kubernetes platform, and it does not upgrade simulated or static proof into runtime or production claims.

## Run it

From the repository root:

```bash
./scripts/showcase-delivery.sh
```

Prerequisites:

- Bash;
- Python 3;
- Git.

No cloud credentials, container registry, Kubernetes cluster, Argo CD instance, `yq`, or Cosign installation is required.

## Scenario

The showcase follows one logical delivery story.

### 1. Derive risk-adaptive controls

The existing zero-cloud assurance path evaluates `platform-assurance/risk/examples/r2-change.json` with `scripts/evaluate-risk.py`.

GoldenPath derives rather than self-declares:

- the R0-R4 risk level;
- the allowed autonomy mode;
- required assurance gates;
- the authoritative plan digest.

### 2. Bind evidence to the authoritative plan

`scripts/validate-evidence-manifest.py` validates the known-good risk-adaptive evidence fixture against the derived plan digest.

This demonstrates that downstream evidence must match the assurance decision that produced its requirements.

### 3. Prove fail-closed evidence semantics

The same validator receives an intentionally incomplete fixture that omits required-gate evidence.

The showcase succeeds only when that invalid evidence is rejected. Acceptance of incomplete evidence is treated as a showcase failure.

### 4. Reject unsafe promotion inputs before mutation

The showcase then executes `gitops-config/scripts/test-promotion-contract.sh`.

The regression harness creates an isolated temporary Git repository and proves that the promotion helper rejects:

- mutable tag input;
- malformed digests;
- a digest that differs from the source environment;
- failed release-trust verification.

A failed trust check must occur before a promotion branch is created or target desired state is changed.

### 5. Promote one exact digest from development to staging

The harness promotes a synthetic immutable digest from `dev` to `staging`.

It verifies that:

- the source digest is preserved exactly;
- tag-based desired state is not reintroduced;
- image-signature verification is bound to the exact digest and expected workflow identity;
- signed SLSA provenance verification is bound to the same digest and identity.

The harness uses an isolated fake `cosign` executable to test command ordering, identity binding, and fail-closed control flow. It does not contact a real registry or transparency service.

### 6. Preserve that digest from staging to production

The same digest is promoted from `staging` to `prod`.

The test fails if production receives a different digest or if a mutable tag is reintroduced.

The result demonstrates the repository's build-once/promote-many desired-state contract.

## Evidence map

| Stage | What the showcase demonstrates | Evidence level |
|---|---|---|
| Risk evaluation | Deterministic inputs derive R0-R4 controls | Repository/reference |
| Evidence validation | Evidence is bound to the authoritative plan digest | Repository/reference |
| Negative assurance path | Missing required evidence is rejected | Repository/reference |
| Promotion input validation | Tags, malformed digests, and source mismatches are rejected | Repository/reference |
| Trust-before-mutation | Verification failure prevents desired-state mutation | Repository/reference |
| Dev -> staging -> prod | One exact digest is preserved across target overlays | Repository/reference |

## What is simulated

The promotion regression harness intentionally uses temporary local state plus fake `yq` and `cosign` executables. That design makes the control-flow contract deterministic and safe to exercise in root CI.

It proves the repository implementation calls the expected verification operations before mutation and preserves immutable identity. It does **not** prove that a real signature, SLSA attestation, registry, GitOps controller, or cluster accepted an artifact.

## What still requires runtime evidence

A runtime evaluation must separately exercise and retain evidence for at least:

1. a real generated service publishing an immutable image digest;
2. registry-attached SPDX SBOM retrieval and validation;
3. real SLSA provenance retrieval, signing, and identity-bound verification;
4. real Cosign image-signature verification;
5. promotion against a disposable GitOps repository or branch;
6. Argo CD reconciliation against a target cluster;
7. running workload image-ID verification against the promoted digest;
8. health, SLO, rollback, and representative business-transaction validation.

Production validation additionally requires the target organization's real identities, approval rules, secrets, DNS, certificates, observability, incident controls, and operational ownership.

## Related evidence

- [Zero-cloud assurance demo](../DEMO.md)
- [Risk-adaptive assurance](../assurance/risk-adaptive-assurance.md)
- [Evidence contract](../assurance/evidence-contract.md)
- [Software supply chain](../security/software-supply-chain.md)
- [GitOps promotion guide](../../gitops-config/docs/PROMOTION_GUIDE.md)

## Why this exists

The zero-cloud demo intentionally focuses on assurance. The GitOps regression harness intentionally focuses on immutable promotion. This showcase composes those existing contracts so a new evaluator can understand the delivery story in one run without confusing repository proof with runtime or production validation.
