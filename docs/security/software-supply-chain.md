# Software Supply Chain

The Golden Path target is a traceable path from reviewed source to a verified production artifact.

## Required chain of evidence

A mature release should be able to answer:

- which source commit produced the artifact;
- which workflow and runner built it;
- which tests and scans passed;
- which dependencies were included;
- what SBOM describes it;
- whether the artifact was signed;
- whether provenance was generated;
- which immutable digest was promoted;
- who approved the production desired-state change.

## Build rules

- Build from reviewed source.
- Use pinned or controlled build dependencies.
- Minimize runner trust and persistence.
- Avoid injecting broad production credentials into build jobs.
- Produce immutable artifacts.
- Separate artifact build from environment deployment.

## Container images

Prefer minimal runtime images, non-root execution, explicit versions, vulnerability scanning, and registry immutability. Distroless images are useful when they fit debugging and operational requirements.

## SBOM and signing

SBOM generation, signing, provenance, and deploy-time verification are documented target controls. They are not yet implemented as active root workflows in this consolidated repository and should not be reported as currently enforced.

## Dependency updates

Use automated update tooling with review and compatibility testing. High-severity vulnerabilities require an escalation policy that considers exploitability and service exposure rather than CVSS alone.

## Registry

Production registries should enforce authentication, retention, immutability for release references, scanning, audit logs, and lifecycle controls.
