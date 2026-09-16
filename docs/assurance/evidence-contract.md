# GoldenPath Evidence Contract

GoldenPath uses an explicit evidence contract so platform readiness is derived from auditable facts rather than from configuration presence, a green workflow, or a narrative claim.

The versioned machine-readable contract lives at:

- `platform-assurance/evidence/schema/goldenpath-evidence-v1.schema.json`
- schema version: `goldenpath.evidence/v1`
- validator: `scripts/validate-evidence-manifest.py`
- regression suite: `scripts/test-evidence-contract.py`

## Evidence over claims

A repository can prove that configuration, policy, templates, and validation logic exist. It cannot prove that an external cluster, cloud account, DNS zone, certificate authority, registry, identity provider, secret backend, or runtime is healthy unless evidence is collected from that target.

GoldenPath therefore separates four claim levels:

| Claim level | Meaning | Minimum evidence |
|---|---|---|
| `implemented` | Code or configuration exists and is structurally valid. | Repository evidence. |
| `reference` | The repository demonstrates an executable reference pattern. | Repository CI, deterministic gates, and exact source binding. |
| `runtime-validated` | The capability was exercised against a real non-production or explicitly identified runtime. | Repository evidence plus successful runtime evidence. |
| `production-validated` | The capability was exercised against the production target represented by the manifest. | Repository evidence plus successful production runtime evidence. |

A claim level is not a maturity shortcut. It describes the evidence attached to one capability and one exact state.

## Manifest identity and binding

Every manifest is bound to:

- repository and exact 40-character commit SHA;
- generation timestamp;
- capability and environment;
- optional immutable artifact identity and SHA-256 digest;
- policy digest;
- architecture metadata digest;
- desired-state digest;
- deterministic gate observations;
- runtime observations when the claim level requires them.

`source.commitSha` and `inputs.sourceSha` must match. The validator also supports `--expected-commit` so a consumer can reject evidence produced for a different source revision.

## Gate result taxonomy

The contract intentionally distinguishes four gate outcomes:

- `PASS` — the gate ran and its acceptance criteria were satisfied.
- `FAIL` — the gate ran and found a product, policy, security, or correctness failure.
- `INFRASTRUCTURE_FAILURE` — the required gate could not establish a trustworthy result because its execution infrastructure failed.
- `SKIP_ALLOWED` — the gate did not run, but policy explicitly allows that skip for this context.

This distinction prevents infrastructure problems from being misrepresented as product failures and prevents silent skips from being treated as success.

## Fail-closed readiness derivation

`decision` is derived from evidence; producers must not choose it independently.

A required gate is satisfied only when:

1. it returns `PASS`; or
2. it returns `SKIP_ALLOWED` and the gate explicitly declares `skipAllowed: true`.

A required `FAIL` or `INFRASTRUCTURE_FAILURE` forces `NOT_READY`.

An unauthorized `SKIP_ALLOWED` is invalid evidence, not merely a `NOT_READY` decision.

For `runtime-validated` and `production-validated` claims, runtime evidence must exist. A non-passing runtime observation forces `NOT_READY`.

`production-validated` is valid only when `context.environment` is `prod`.

## R0-R4 risk-adaptive assurance binding

The optional `assurance` object binds a `goldenpath.assurance/v1` plan to the Evidence Manifest. The plan is produced by the R0-R4 engine documented in [R0-R4 Risk-Adaptive Assurance](risk-adaptive-assurance.md).

When an assurance snapshot is present, the validator additionally requires:

- `assurance.policyDigest` to equal `inputs.policyDigest`;
- `assurance.architectureMetadataDigest` to equal `inputs.architectureDigest`;
- every `requiredGateId` to exist in `gates` and be marked `required: true`;
- every human-approval gate to be part of the required gate set;
- `preview-environment` to be a required gate whenever preview is mandatory;
- passing `runtimeEvidence` whenever the risk plan requires runtime validation, even if the claim level remains `reference`.

This makes the risk plan enforceable evidence, not advisory metadata. A producer cannot attach an R3/R4 plan and then silently omit its stronger controls while still claiming `READY`.

Risk-derived runtime proof does not automatically elevate the claim level. A `reference` claim with risk-mandated runtime evidence remains a `reference` claim unless the producer explicitly satisfies and declares the stronger evidence-status contract.

## Evidence invalidation

Evidence is a statement about an exact set of inputs. It becomes stale when any authoritative input changes.

At minimum, regenerate evidence when any of these change:

- source commit;
- policy bundle;
- architecture metadata or contracts;
- GitOps desired state;
- immutable artifact digest;
- target environment identity or configuration when it changes the assessed capability.

The v1 manifest records hashes for source, policy, architecture, and desired state. CI or a higher-level assurance controller can compare those values with current inputs before accepting the evidence.

The `--expected-commit` validator option is the first executable invalidation check in this repository. The R0-R4 plan also carries policy, architecture, and plan digests. Automatic recomputation/comparison of every non-source digest at consumption time remains follow-up operational work.

## Runtime evidence

Runtime evidence is intentionally separate from static repository gates. Supported v1 evidence kinds are:

- `deployment`;
- `health`;
- `rollout`;
- `smoke`;
- `slo`;
- `rollback`.

Each observation records a result, timestamp, and evidence URL. A URL should point to an immutable or durably retained evidence surface whenever possible, such as a workflow artifact, deployment record, monitoring snapshot, or signed report.

A static Helm render, Kustomize build, Terraform validate, or Conftest run remains valuable repository evidence, but it is not runtime evidence.

## Producer responsibilities

Evidence producers should:

1. calculate all inputs before executing gates;
2. bind every observation to the exact commit and artifact under test;
3. preserve the distinction between test failure and infrastructure failure;
4. include a reason for any skip or failure;
5. satisfy all gates added by an attached assurance plan;
6. collect runtime proof only from the environment named in the manifest;
7. derive `decision` after all required evidence is known;
8. publish the manifest with the other delivery/release evidence.

## Consumer responsibilities

Evidence consumers should:

1. validate the manifest before trusting it;
2. compare source and relevant input identities with the current target;
3. reject stale evidence;
4. reject unsupported schema versions;
5. enforce any attached R0-R4 assurance requirements;
6. never elevate a `reference` claim to runtime or production validation without new runtime evidence;
7. fail closed when a required validation cannot establish a trustworthy result.

## Local validation

Validate one manifest:

```bash
python3 scripts/validate-evidence-manifest.py path/to/evidence.json
```

Require binding to a known commit:

```bash
python3 scripts/validate-evidence-manifest.py \
  path/to/evidence.json \
  --expected-commit "$GITHUB_SHA"
```

Run the contract regression suite:

```bash
python3 scripts/test-evidence-contract.py
```

The negative fixtures are required. They prove that the validator rejects false `READY` decisions, missing runtime evidence, unauthorized skips, source drift, and omitted risk-required gates.

## Current scope

The Evidence Manifest plus R0-R4 engine now provide the repository/reference assurance substrate: deterministic risk classification, monotonic control selection, Architecture as Code inputs, and fail-closed evidence binding.

This repository still does not claim operational enforcement of reviewer identities, preview environments, runtime gates, human approvals, or production controls. Those require a real governed delivery path and retained runtime evidence from the target environment.
