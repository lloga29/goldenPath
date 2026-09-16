# Service Templates - Golden Path

Golden service templates provide the fastest supported path from a new repository to an operable service.

## Implemented templates

| Template | Status | Language / workload |
|---|---|---|
| `microservice-golang` | Implemented baseline | Go HTTP service |
| `microservice-python` | Roadmap | Not present in the repository |
| `terraform-stack` | Roadmap | Not present in the repository |

Documentation must not present roadmap templates as available until executable template content and validation exist.

## Generate a Go service

```bash
pip install copier
copier copy ./templates/microservice-golang ./my-service
```

Review the generated repository, then run its local validation commands before the first commit.

## Go template baseline

The current template includes a structured Go project, health/readiness handlers, logging/configuration scaffolding, a multi-stage/distroless container build, pre-commit configuration, Makefile commands, and a GitHub Actions CI blueprint.

See [Service Templates](../docs/platform/service-templates.md) for the full template contract.

## Updating generated services

Copier can support template updates, but upgrades should be versioned, tested, and reviewed like dependency changes. Do not automatically overwrite team-specific service code.

## Adding a template

A new language template is complete only when generated output builds/tests successfully and includes the same ownership, security, observability, delivery, and support contract as the existing paved road.
