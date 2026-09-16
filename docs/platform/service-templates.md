# Service Templates

Service templates are the primary self-service entry point into the Golden Path.

## Implemented template

The repository currently contains one implemented Copier template:

```text
service-templates/templates/microservice-golang/
```

It generates a Go service baseline with application structure, build/container configuration, pre-commit configuration, and a CI workflow blueprint.

Python and Terraform stack templates were previously described in documentation but are not present in the repository. They remain roadmap items until executable templates and validation exist.

## Template contract

A golden service template should produce a repository that is usable without deleting large amounts of irrelevant scaffolding. The generated service should include, when applicable:

- application bootstrap and graceful shutdown;
- liveness and readiness behavior;
- structured logging;
- metrics and tracing integration points;
- secure container defaults;
- tests;
- dependency management;
- CI baseline;
- ownership metadata;
- deployment metadata;
- local developer commands;
- documentation and runbook placeholders.

## Template versioning

Templates are products. Version them, publish release notes, and test upgrades. Copier update support is valuable only when template changes preserve compatibility and teams can understand the resulting diff.

## Avoid hidden coupling

Do not bake real account IDs, production domains, secret values, cluster names, or customer-specific configuration into a generic template. Generate metadata fields or configuration hooks instead.

## Validation

Test both template rendering and the generated project. A template test should verify that representative answers generate a repository that formats, builds, tests, and passes the baseline security checks.

## Extending the catalog

Add a new template only when its operational contract is equivalent to existing paved-road services. A language-specific scaffold without deployment, security, observability, ownership, and support integration is not yet a Golden Path template.
