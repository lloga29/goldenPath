# Service Templates - Golden Path

Golden service templates provide the fastest supported path from a new repository to an operable service.

## Implemented templates

| Template | Status | Language / workload |
|---|---|---|
| `microservice-golang` | Implemented paved-road baseline | Go HTTP service |
| `microservice-python` | Roadmap | Not present in the repository |
| `terraform-stack` | Roadmap | Not present in the repository |

Documentation must not present roadmap templates as available until executable template content and validation exist.

## Generate a Go service

The template executes `go mod tidy`, so Copier requires trust and the selected Go toolchain must already be installed.

```bash
pip install copier
copier copy --trust ./service-templates/templates/microservice-golang ./my-service
```

The generated repository contains no automatic `git init`, commit, or push task. Repository creation and first publication remain explicit developer actions.

## Implemented Go contract

The generated service includes:

- validated runtime configuration;
- graceful shutdown;
- liveness/readiness handlers with tests;
- structured request logging and panic recovery;
- Prometheus metrics;
- non-root distroless runtime image;
- immutable full-SHA GHCR publication from `main`;
- BuildKit SBOM/provenance requests and keyless Cosign signing;
- pull-request quality/security/container-build gates;
- owner metadata and a production runbook placeholder;
- explicit GitOps onboarding contract.

Database, cache, and gRPC options are intentionally not exposed until the template provides working code, health/readiness integration, tests, and operations guidance for those capabilities.

## Validate the template itself

```bash
./service-templates/scripts/render-go-template-smoke-test.sh
```

The smoke test renders representative output and verifies formatting, vet, tests, build, and immutable publication semantics.

## Updating generated services

Copier can support template updates, but upgrades should be versioned, tested, and reviewed like dependency changes. Do not automatically overwrite team-specific service code.

## Adding a template

A new language template is complete only when generated output builds/tests successfully and includes the same ownership, security, observability, delivery, and support contract as the existing paved road.
