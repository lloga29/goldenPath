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
- full-Git-SHA GHCR publication from `main` only;
- BuildKit SBOM/provenance generation requests;
- keyless Cosign image signing through GitHub OIDC;
- ownership metadata and a runbook placeholder;
- explicit separation between application source and GitOps desired state.

The template does **not** pretend to provide database, cache, gRPC, or distributed-tracing implementations. Add those capabilities only with real code, tests, dependency readiness behavior, and runbook changes.

## Template validation

The repository includes:

```bash
./service-templates/scripts/render-go-template-smoke-test.sh
```

The script renders representative output, then runs Go formatting validation, vet, tests, and build. Root CI integration is tracked in issue #10.

## Artifact lifecycle

The application pipeline builds once and identifies an image by the full Git SHA. The GitOps repository promotes that same immutable image through environments. `:latest` publication is not part of the paved road.

External CI Actions and container bases are still version-tag pinned in this phase; immutable dependency pinning is tracked in issue #17.

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
