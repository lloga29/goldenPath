# Software Supply Chain

The Golden Path target is a traceable path from reviewed source to a verified production artifact. Supply-chain controls apply to both product artifacts and the CI system that decides whether repository changes are acceptable.

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

## Active root CI dependency controls

The consolidated repository currently enforces these controls for active root workflows:

- external GitHub Actions are referenced by full 40-character commit SHA rather than mutable major-version tags;
- hosted jobs use the explicit `ubuntu-24.04` runner family rather than `ubuntu-latest`;
- Python jobs use CPython `3.13.15`;
- the Go template validation uses Go `1.26.8`;
- Terraform validation uses Terraform `1.16.2`;
- Kustomize `5.8.1`, Helm `4.3.0`, and Conftest `0.70.0` are downloaded at exact versions and verified with SHA-256 before extraction or installation;
- Gitleaks `8.30.0` is downloaded by exact version, verified with SHA-256, required to detect a runtime canary before use, and then scans the complete reachable Git history;
- Python CI tooling is installed with `pip --require-hashes` from committed lock files under `.github/requirements/`;
- `scripts/validate-ci-supply-chain.py` rejects mutable external action references, `*-latest` runner labels, executable download blocks without pre-use SHA-256 verification, un-hashed pip installation, malformed lock entries, and unreferenced CI lock files.

These controls are exercised by the same active root CI they protect. Changes to root validation workflows or root validation scripts deliberately force all validation domains to run.

## Historical secret scanning

Public repository exposure includes reachable Git history, not just the current working tree. Root CI therefore performs a full-history Gitleaks scan from a `fetch-depth: 0` checkout.

The scanner is deliberately pinned to Gitleaks `8.30.0` rather than blindly tracking `latest`. Gitleaks `8.30.1` has a documented regression in which representative secrets can produce a false `no leaks found` result. The Golden Path also creates a synthetic high-entropy generic API-key assignment only at runtime and requires the scanner to reject it before the repository scan is trusted. The value is assembled at runtime so the repository itself does not contain the complete secret-shaped canary. If the canary does not fail as expected, CI fails closed and the history result is discarded.

This control detects secret patterns in reachable commits, including content later removed from `main`. It does not prove that repository history contains no confidential business context, internal names, private URLs, customer identifiers, or other publication-inappropriate material that is not secret-shaped. Public-release review must still cover those categories separately.

## Runner reproducibility boundary

`ubuntu-24.04` fixes the hosted runner operating-system family but does **not** make the runner image bit-for-bit immutable. GitHub updates hosted images within that label. The workflow logs record the concrete runner image version used for each run, but a future run may receive a newer image.

Workloads that require bit-for-bit build-environment reproducibility should use a separately versioned, hardened, and attested runner image or another controlled build environment. The current repository does not claim that level of runner immutability.

## Python lock scope

The active Python lock files were resolved and verified for **CPython 3.13.15 on Ubuntu 24.04 x86_64**. The lock for the Copier toolchain includes the complete reviewed transitive graph selected when resolving `PyYAML==6.0.2` together with `copier==9.15.2`.

A Python runtime, operating-system family, architecture, or top-level dependency change requires regenerating the lock under the new target environment and reviewing the complete dependency and hash diff. Do not copy hashes from a different runtime/platform and treat them as equivalent evidence.

## Policy language baseline

Conftest `0.70.0` uses Rego v1 as its default parser. The executable Golden Path Kubernetes and Terraform policy modules use explicit Rego v1 syntax, including `import rego.v1`, `if` rule bodies, and `contains` for partial-set rules. Root CI does not pass a Rego v0 compatibility flag.

Positive and intentionally invalid Kubernetes/Terraform fixtures exercise the same policy contract under the Rego v1 parser. A future policy-toolchain update must preserve those outcomes or explicitly document and review the semantic change.

Gatekeeper ConstraintTemplates are a separate admission-runtime surface and are not treated as proof of live-cluster enforcement by the Conftest fixture suite. Their runtime compatibility must still be validated against the selected Gatekeeper/OPA version before production enforcement.

## Build rules

- Build from reviewed source.
- Use pinned and integrity-checked build dependencies where the distribution model supports it.
- Minimize runner trust and persistence.
- Avoid injecting broad production credentials into build jobs.
- Produce immutable release artifacts.
- Separate artifact build from environment deployment.
- Fail closed when an integrity check, policy test, or dependency resolution does not match the reviewed contract.

## Integrity terminology

Use precise terms in reviews and documentation:

- an **exact version** constrains dependency resolution but does not by itself prove artifact bytes;
- a Git **commit SHA** binds an action reference to specific source content in that repository history, while still relying on the hosting and repository trust model;
- a **SHA-256 checksum** binds a downloaded file to the reviewed bytes represented by that digest;
- a cryptographic **signature** adds signer identity/authorization evidence when key trust is established;
- **provenance/attestation** adds claims about how, where, and from which inputs an artifact was produced.

Do not describe a version string or mutable tag as cryptographic immutability.

## Dependency update procedure

Every active CI or paved-road dependency update should follow the same reviewed sequence:

1. identify the authoritative upstream release and compatibility requirements;
2. for GitHub Actions, resolve the reviewed release/tag to its full commit SHA and update the human-readable version comment;
3. for downloaded executables, obtain the exact upstream release artifact and its published checksum or stronger integrity evidence;
4. for container base images, retain a human-readable tag for review context while treating the OCI digest as the immutable identity, and update both together when the upstream dependency changes;
5. for Python tooling, resolve the complete graph under the pinned runtime/platform, review all transitive changes, and regenerate every SHA-256 entry;
6. update compatibility documentation when a new tool changes parser, schema, operating-system, or behavior defaults;
7. run the complete root validation contract, including negative fixtures and domains not directly changed when the workflow itself changed;
8. merge only after the exact proposed head is green and authorship/commit identity has been verified.

Dependabot is configured to propose reviewable GitHub Actions and Go-template Docker dependency updates. Automated dependency tooling may propose updates, but it must not bypass these review and validation requirements.

## Rollback

If a toolchain update changes semantics or breaks validation, revert the reviewed dependency change or use a narrowly documented compatibility mode with a tracked removal issue. Never restore green status by removing a failing policy, suppressing validation output, weakening an integrity check, or silently moving a SHA/checksum to different bytes.

## Container images

Prefer minimal runtime images, non-root execution, explicit versions, vulnerability scanning, and registry immutability. Distroless images are useful when they fit debugging and operational requirements.

The implemented Go paved-road template pins both build and runtime `FROM` references to OCI SHA-256 digests. The builder uses the repository's Go 1.26.8 baseline, while the runtime uses the supported `gcr.io/distroless/static-debian13:nonroot` line. Human-readable tags remain in the Dockerfile so dependency-review pull requests show what upstream release a digest represents; the digest is the immutable build identity.

The template smoke test fails if any generated `FROM` instruction lacks a SHA-256 digest, rejects Distroless Debian 12, requires the Debian 13 nonroot runtime, and performs a real container build so an invalid or unavailable pinned image cannot pass the root service-template validation path.

## SBOM, signing, and provenance

The implemented Go paved-road now has an executable **repository/reference SBOM contract**. Its generated `main` publish job asks BuildKit to attach an SBOM and max-level provenance to the immutable GHCR image, obtains the build output digest, re-addresses the artifact as `IMAGE_NAME@sha256:<digest>`, extracts `.SBOM.SPDX` from the registry attestation, and fails closed unless the payload is a parseable SPDX document with creation metadata and a non-empty package inventory. Root CI renders the template and statically requires the generation, digest binding, registry inspection, and SPDX validation steps, so removal of that contract fails repository validation.

This evidence does **not** mean a generated delivery repository has already published and retrieved an SBOM from GHCR. That becomes runtime evidence only when an actual generated service executes the publish path successfully. The repository must continue to distinguish the implemented reference contract from runtime-validated or production-validated release evidence.

The generated workflow also requests BuildKit provenance and performs keyless Cosign signing with GitHub OIDC after SBOM verification. Those signing/provenance paths are implemented template behavior, but GoldenPath does not yet fail closed on independent post-publication signature/provenance verification, nor has this consolidated repository demonstrated them against a real generated release runtime. Therefore the broader signing, provenance-publication, and deploy-time verification audit items remain open.

## Registry

Production registries should enforce authentication, retention, immutability for release references, scanning, audit logs, lifecycle controls, and appropriate signature/provenance verification.
