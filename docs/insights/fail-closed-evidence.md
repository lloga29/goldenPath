# Fail-closed evidence: green is not enough

Delivery systems often collapse too many outcomes into a binary signal: green or red. That hides important distinctions.

A required security gate that could not run because its infrastructure failed did not pass. A skipped gate is not automatically acceptable. A valid result for yesterday's commit is not trustworthy evidence for today's commit.

GoldenPath uses an explicit evidence contract so readiness is derived from auditable observations rather than selected by the producer.

## Four gate outcomes

The evidence contract distinguishes:

- `PASS` — the gate ran and satisfied its acceptance criteria;
- `FAIL` — the gate ran and found a product, policy, security, or correctness failure;
- `INFRASTRUCTURE_FAILURE` — the required gate could not establish a trustworthy result;
- `SKIP_ALLOWED` — policy explicitly permits the gate not to run in this context.

A required `FAIL` or `INFRASTRUCTURE_FAILURE` forces `NOT_READY`.

A skip is acceptable only when the gate itself declares that the skip is allowed. An unauthorized skip is invalid evidence.

## Readiness is derived

The producer does not get to choose `READY` independently of the observations.

GoldenPath validates required gates, runtime evidence when required, source identity, assurance bindings, and stronger claim-level rules before accepting the decision.

That makes a green-looking manifest insufficient if its underlying evidence does not support the conclusion.

## Freshness and authority

Evidence is tied to exact inputs, including:

- repository and commit SHA;
- policy digest;
- architecture metadata digest;
- desired-state digest;
- optional immutable artifact digest;
- the independently derived R0-R4 plan digest when assurance is attached.

If those authoritative inputs change, the old evidence becomes stale.

## Why the expected plan digest is external

An attached R0-R4 snapshot is accepted only when its digest matches `--expected-plan-digest` supplied by the consumer from an independently derived authoritative plan.

This prevents a producer from removing an R3/R4 requirement, recomputing a self-consistent digest, and presenting the modified snapshot as trusted.

## Inspect the implementation

Key repository evidence:

- `platform-assurance/evidence/schema/goldenpath-evidence-v1.schema.json`
- `scripts/validate-evidence-manifest.py`
- `scripts/test-evidence-contract.py`
- `docs/assurance/evidence-contract.md`

Run the regression suite:

```bash
python3 scripts/test-evidence-contract.py
```

Run the public assurance path:

```bash
./scripts/demo.sh
```

The demo succeeds only when known-good evidence is accepted and intentionally incomplete evidence is rejected.

## What this proves

Repository/reference evidence demonstrates fail-closed decision derivation, exact source binding, gate-result taxonomy, risk-plan binding, and rejection of several stale or forged evidence cases.

## What this does not prove

A manifest containing runtime fields is not automatically runtime truth. Real runtime or production claims require observations collected from the named target environment and retained on a durable evidence surface.
