# Signed provenance: trust the immutable artifact, not the release label

A release tag can identify intent, but it does not identify immutable artifact bytes. A build can also produce provenance or an SBOM without proving that a consumer is inspecting evidence for the exact artifact it intends to promote.

GoldenPath's implemented Go paved-road reference contract centers release evidence on one immutable OCI digest.

## Start with the build output digest

The generated publish workflow obtains the immutable build output digest and re-addresses the image as:

```text
IMAGE_NAME@sha256:<digest>
```

Attached evidence is then retrieved for that exact identity.

The workflow expects:

- a registry-attached SPDX SBOM with creation metadata and a non-empty package inventory;
- SLSA provenance with the expected BuildKit build type, builder metadata, invocation metadata, materials, and build-time data.

Malformed or missing evidence fails closed.

## Sign and verify the same identity

After evidence validation, the workflow signs the exact image digest with keyless Cosign using GitHub Actions OIDC.

It then verifies the signature against the expected generated `ci.yaml` workflow identity and the GitHub Actions OIDC issuer.

The reference path also creates a signed `slsaprovenance` attestation from the validated provenance predicate and verifies that trust object.

The important detail is continuity: build evidence, signature, attestation, and later promotion all refer to the same immutable digest.

## Why identity-bound verification matters

"Signed" is incomplete as a trust claim unless the verifier also knows which signer identity is acceptable.

GoldenPath binds verification to the expected workflow identity rather than treating any valid keyless signature as sufficient.

## Inspect the implementation

Key repository evidence:

- `service-templates/templates/microservice-golang/`
- `service-templates/scripts/render-go-template-smoke-test.sh`
- `docs/security/software-supply-chain.md`
- `docs/platform/service-templates.md`

Root repository CI renders the Go template and requires the release contract to contain SBOM generation/inspection, provenance generation/inspection, digest-bound signing, and identity-bound verification.

## Release-time trust is not deployment-time trust

A release workflow proving artifact trust does not automatically prove that a deployment or admission path enforced the same trust decision.

A production delivery path should independently verify the artifact identity and required trust evidence before promotion or deployment when that assurance is required.

## What this proves

Repository/reference validation demonstrates that the generated Go release contract is structured around one immutable digest and includes the expected SBOM, provenance, signing, attestation, and identity-verification operations.

## What this does not prove

Root CI does not publish a real generated service image to GHCR or complete a live OIDC/Cosign flow for an external generated repository.

Runtime evidence requires a real generated service to publish the digest, retrieve the attached evidence, sign it, and complete identity-bound verification successfully.
