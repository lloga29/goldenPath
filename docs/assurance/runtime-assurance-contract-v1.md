# GoldenPath v0.2 Runtime Assurance Contracts

Status: **P0 contract baseline**

This document freezes the runtime-evidence and assurance-receipt semantics that P1-P5 must preserve. It extends, but does not replace, the existing `goldenpath.evidence/v1` and `goldenpath.assurance/v1` repository/reference contracts.

## Trust model

GoldenPath treats runtime assurance as a chain of independently checkable identities rather than as a green workflow result.

```text
source revision
  -> immutable artifact digest
  -> GitOps desired-state revision and digest
  -> assurance-plan and policy-bundle digests
  -> bounded runtime identity
  -> observed workload digest
  -> required control outcomes
  -> assurance receipt
```

A consumer fails closed when any required identity is missing, malformed, stale, contradictory, unsupported, or different from the independently expected identity.

## Versioned contracts

- Runtime evidence schema: `platform-assurance/runtime/schema/goldenpath-runtime-evidence-v1.schema.json`
- Runtime evidence version: `goldenpath.runtime-evidence/v1`
- Assurance receipt schema: `platform-assurance/runtime/schema/goldenpath-assurance-receipt-v1.schema.json`
- Receipt version: `goldenpath.assurance-receipt/v1`
- Validator: `scripts/validate-runtime-assurance.py`
- Regression suite: `scripts/test-runtime-assurance-contract.py`

These are additive contracts. Existing v0.1 `goldenpath.evidence/v1` manifests remain valid under their existing validator and are not silently reinterpreted as v0.2 runtime receipts.

## Identity binding rules

Runtime evidence must identify the exact source repository/revision, immutable artifact digest, GitOps desired-state revision/digest, assurance-plan and policy-bundle digests, execution id/attempt, runtime class/cluster/namespace/workload UID, observed workload digest, and required control outcomes.

The observed workload digest must equal the artifact digest under assessment. A receipt repeats the subject identities and binds the exact runtime-evidence object by schema version, evidence id, and canonical SHA-256 digest. The independent validator compares every repeated identity rather than trusting the producer.

Consumers may additionally pin expected source, artifact, desired-state, policy-bundle, and cluster identities. Those external expectations are part of replay protection because a valid receipt for one execution context must not be accepted for another.

## Freshness and replay semantics

Both runtime evidence and receipts have explicit validity windows. Verification fails when the verification time predates the evidence, when evidence or a receipt is expired, when a receipt is generated after its evidence expired, or when a receipt attempts to outlive its underlying runtime evidence.

Validity windows are necessary but not sufficient replay protection. Exact source, artifact, GitOps, policy, runtime, and execution identities must also match the consumer's expected context.

Cryptographic signing is a P2 deliverable. P0 therefore treats canonical digests and independent identity matching as the pre-signing contract, not as a substitute for signatures.

## Control and decision semantics

Required control results are `PASS`, `FAIL`, `INFRASTRUCTURE_FAILURE`, or `NEEDS_HUMAN`.

The receipt decision is derived, not producer-selected:

- all required controls `PASS` -> `VERIFIED`;
- any required `NEEDS_HUMAN` -> `NEEDS_HUMAN`;
- otherwise any non-passing required control -> `NOT_VERIFIED`.

Receipt controls must exactly match runtime-evidence controls. Contradictory results fail validation even if the receipt says `VERIFIED`.

## Evidence tiers

| Tier | Meaning | Production claim allowed? |
|---|---|---|
| `repository` | Repository/reference evidence only | No |
| `runtime` | Evidence from an identified runtime | No |
| `production` | Evidence from an explicitly identified production runtime | Only with separately scoped production evidence |

An ephemeral Runtime Lab is always `environmentClass: ephemeral-lab`. It cannot support a `production` claim. Changing only a receipt label to `production` fails closed.

## Runtime Lab architecture contract

P1 will implement the first supported Runtime Lab on **kind**. The lab is an ephemeral Kubernetes runtime backed by containers and exists only to prove runtime behavior against a real Kubernetes API.

Allowed bootstrap boundary:

1. create the kind cluster;
2. install the minimum bootstrap dependencies needed to establish Argo CD and admission enforcement;
3. hand steady-state desired state to Argo CD;
4. collect runtime evidence through the Kubernetes API and supported tool APIs;
5. destroy the lab and verify cleanup.

Hidden steady-state mutation is not allowed. A direct bootstrap action must be documented and must not be presented as GitOps reconciliation evidence.

The lab does not prove managed-cloud behavior, production networking, production identity, production availability, or organizational operating controls.

## Isolation assumptions

- The lab has a unique execution id and cluster identity per run.
- Namespaces and generated workload names are scoped to the run where practical.
- Destructive tests are limited to the disposable lab.
- P1 must provide deterministic teardown and residue checks.
- CI failure to create or clean the lab is infrastructure failure, not successful assurance.
- A developer workstation or CI runner hosting kind is outside the production trust boundary.

## Threat model

| Threat | Required response |
|---|---|
| Evidence forgery or tampering | Canonical evidence digest mismatch fails; P2 adds cryptographic signing. |
| Replay of an old valid receipt | Freshness plus exact expected identities and execution binding must match. |
| Stale evidence | Expired runtime evidence or receipt fails closed. |
| Source/artifact/GitOps mismatch | Receipt-to-evidence and consumer-expected identities must match exactly. |
| Runtime impersonation | Cluster identity, namespace, workload UID, and observed digest are bound into evidence and receipt. |
| Lab-to-production claim escalation | Production claim requires production runtime class; ephemeral lab evidence is rejected. |
| Contradictory control outcomes | Receipt controls must equal runtime controls; derived decision must agree. |
| Unsupported contract version | Unknown runtime-evidence or receipt version is rejected. |
| Partial required evidence | Missing required identity, evidence binding, or runtime input fails closed. |

## CLI architecture draft

P0 freezes behavior boundaries, not final UX. P4 may refine naming while preserving these contracts.

```text
goldenpath init
goldenpath plan
goldenpath validate
goldenpath lab up
goldenpath lab down
goldenpath assure
goldenpath verify
goldenpath doctor
goldenpath evidence show
```

`plan` exposes assurance identities; `validate` remains repository/reference-only; `lab` owns the disposable runtime lifecycle; `assure` emits evidence only after required facts exist; `verify` independently checks receipts; and `doctor` reports missing prerequisites without silently downgrading blocking controls.

Machine-readable and human-readable output must represent the same underlying state.

## Compatibility and migration from v0.1

1. `goldenpath.evidence/v1` remains the repository/reference Evidence Manifest contract.
2. `goldenpath.assurance/v1` remains the R0-R4 assurance-plan contract.
3. v0.2 adds runtime evidence and receipt contracts alongside those contracts; it does not change their meaning.
4. No v0.1 `runtime-validated` manifest is automatically converted into a v0.2 receipt.
5. P2 collectors may consume authoritative v0.1 inputs, but must emit the new exact identity bindings before a v0.2 runtime receipt can verify.
6. Existing consumers can remain on v0.1 until they deliberately adopt the v0.2 runtime verifier.

## P1-P5 test plan

| Phase | Positive path | Required negative/adversarial path |
|---|---|---|
| P1 Runtime Lab | Create, bootstrap, reconcile, observe health, destroy | Admission denial, failed bootstrap, cleanup residue, wrong workload digest |
| P2 Receipts | Collect identities, generate, sign, independently verify | Signature tamper, source/artifact/GitOps/policy/runtime mismatch, replay, stale evidence |
| P3 Continuous assurance | Healthy state remains verified; recovery emits new evidence | Drift, failed rollout, policy bypass, expired exception, unresolved/needs-human state |
| P4 CLI | Official entry point produces equivalent machine evidence | Missing dependency, invalid input, failed control, no silent advisory downgrade |
| P5 Self-qualification | Exact release candidate self-qualifies | Negative suite, missing evidence, stale receipt, unsupported production wording |

## P0 executable rejection matrix

`scripts/test-runtime-assurance-contract.py` proves rejection of missing identities, source/artifact/desired-state mismatch, stale runtime evidence, tampering, unsupported versions, contradictory required controls, missing runtime evidence, and attempted lab-to-production tier escalation.

These tests establish the contract boundary only. They do not claim that P1 runtime collection, P2 signing, P3 continuous assurance, P4 CLI, or P5 release qualification already exists.

