# Service Templates

Service templates are the primary self-service entry point into the Golden Path.

## Implemented template

The repository currently contains one executable Copier template:

```text
service-templates/templates/microservice-golang/
```

It generates a Go HTTP service baseline that is intentionally narrow and operationally complete rather than feature-rich scaffolding.

Python and Terraform stack templates remain roadmap items until executable templates and validation exist.

## Go paved-road contract

The Go template currently provides:

- Go {{ go_version | default('1.26') }}-line service structure using `net/http`;
- validated port/environment/log-level configuration;
- graceful SIGINT/SIGTERM shutdown;
- `/health`, `/ready`, and `/metrics` endpoints;
- structured JSON request logging and panic recovery;
- health/readiness/config unit tests;
- race-enabled tests and lint/vet/format CI gates;
- Trivy high/critical vulnerability blocking;
- non-root distroless container runtime;
- PR container builds without registry publication;
- full-Git-SHA GHCR publication from `main` only, with the build output digest treated as the promotion identity;
- BuildKit SBOM and max-level provenance attestations on published images;
- post-push retrieval and structural validation of the registry-attached SPDX SBOM by the exact immutable image digest;
- post-push retrieval and structural validation of BuildKit SLSA provenance by the same immutable image digest;
- keyless Cosign image signing plus a signed `slsaprovenance` attestation built from the validated provenance predicate;
- identity-bound verification of both the image signature and signed provenance attestation for the exact digest;
- ownership metadata and a runbook placeholder;
- explicit separation between application source and GitOps desired state.

The template does **not** pretend to provide database, cache, gRPC, or distributed-tracing implementations. Add those capabilities only with real code, tests, dependency readiness behavior, and runbook changes.

## Template validation

The repository includes:

```bash
./service-templates/scripts/render-go-template-smoke-test.sh
```

The script renders representative output, then runs Go formatting validation, vet, tests, build, container construction, immutable-base checks, and static validation of the generated release-evidence contract for SBOM, provenance, image signing, signed provenance, and identity-bound verification. Root CI executes this smoke test for template-affecting changes.

The root smoke test proves repository/reference behavior only. It does not push a generated service image to GHCR, request a live GitHub OIDC certificate, or retrieve registry attestations/signatures. Those post-push checks become runtime evidence only when an actual generated service delivery repository executes the publish path successfully.

## Artifact lifecycle

The application pipeline builds once and identifies the release artifact by the build output OCI digest. A full Git SHA tag remains useful for discovery, but GitOps promotion carries the digest and never resolves a tag again.

On a `main` publication, BuildKit attaches an SBOM and max-level provenance to the pushed image. The workflow addresses the artifact as `IMAGE_NAME@<build-output-digest>`, extracts `.SBOM.SPDX` and `.Provenance.SLSA` with `docker buildx imagetools inspect`, and fails closed unless both payloads have the expected structure. It then signs that exact digest, signs the validated SLSA provenance predicate as a Cosign attestation, and verifies both trust objects against the generated workflow identity and GitHub Actions OIDC issuer.

The matching GoldenPath GitOps promotion helper requires the same source-environment digest and verifies the image signature plus signed SLSA provenance before copying that digest to staging or production desired state. Tags are not accepted as promotion authority.

This is still a repository/reference contract until a generated service, real registry, real GitOps repository, and target runtime exercise the complete path successfully. Production health, approval, reconciliation, and rollback evidence remain separate runtime concerns.

External CI Actions remain version-tag pinned in the generated template; stronger immutable dependency pinning is a separate supply-chain concern from the release-evidence contract.

## Ownership boundary

The platform template owns safe defaults and integration contracts. Application teams own:

- business/domain code;
- downstream dependency readiness;
- service-specific metrics/traces;
- SLO selection and error-budget response;
- data migration/recovery semantics;
- service-specific incident procedures and escalation.

## Adding another template

A new template is complete only when representative generated output formats, builds, tests, passes security checks, publishes immutable artifacts, integrates with GitOps, and carries the same ownership/operability contract. A language skeleton alone is not a Golden Path.
