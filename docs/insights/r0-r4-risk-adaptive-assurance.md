# R0-R4 risk-adaptive assurance without weaker high-risk paths

A fixed CI pipeline is easy to understand, but it treats a documentation edit and a production-impacting identity change as if they deserve the same assurance response. The opposite extreme is also dangerous: a flexible risk system can become a mechanism for skipping controls if the producer is allowed to choose its own risk level or remove gates.

GoldenPath uses **R0-R4 risk-adaptive assurance** to add controls as risk increases while preserving unconditional repository CI and lower-tier minimums.

## The contract

The reference engine combines versioned Architecture as Code metadata with structured change signals. The declared `riskClass` is a floor. Derived signals may raise the effective risk but cannot lower it.

The reference levels are:

- **R0** — global assurance minimum;
- **R1** — policy, unit, and supply-chain controls;
- **R2** — integration, architecture, preview, runtime proof, and domain review;
- **R3** — least-privilege, security, rollback, SLO, owner approval, and security review;
- **R4** — GitOps authority, production change control, and explicit platform/security human approval.

The policy is monotonic. A higher tier may add requirements, but it may not remove gates, reviewers, approvals, preview requirements, runtime validation, or global minimums introduced below it.

## Why monotonicity matters

Without monotonicity, a supposedly "critical" path could accidentally become less controlled than a normal application change. That is exactly the kind of policy drift an adaptive assurance model must prevent.

GoldenPath's regression suite rejects policies that weaken higher tiers or increase autonomy as risk rises.

## The trust anchor

The evaluator emits an assurance requirements snapshot and a canonical SHA-256 `planDigest`.

When evidence carries that assurance snapshot, the consumer must independently derive the authoritative plan and supply its digest as `--expected-plan-digest`.

That external expected digest is important. If the producer could modify the plan and recompute its own matching digest, the plan would be self-attested rather than authoritative.

## Inspect the implementation

Key repository evidence:

- `scripts/evaluate-risk.py`
- `scripts/test-risk-adaptive-assurance.py`
- `platform-assurance/risk/`
- `docs/assurance/risk-adaptive-assurance.md`

Local reference path:

```bash
python3 scripts/evaluate-risk.py \
  platform-assurance/risk/examples/r2-change.json

python3 scripts/test-risk-adaptive-assurance.py
```

The public showcase also composes the risk plan with downstream evidence validation:

```bash
./scripts/showcase-delivery.sh
```

## What this proves

Repository/reference validation demonstrates deterministic classification, monotonic policy behavior, structured risk inputs, and binding of risk-selected requirements into the evidence contract.

## What this does not prove

It does not prove that reviewer roles resolve to real people, preview environments exist, runtime gates execute against a live target, human approval systems are configured, or production change controls are operational.

Those are runtime or production claims and require evidence from the real target systems.
