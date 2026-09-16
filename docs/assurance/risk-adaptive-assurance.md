# R0-R4 Risk-Adaptive Assurance

GoldenPath uses R0-R4 risk-adaptive assurance to add controls according to change risk without weakening unconditional repository CI or the fail-closed Evidence Manifest contract.

## Contracts

- Architecture as Code: `goldenpath.architecture/v1`
- Assurance plan: `goldenpath.assurance/v1`
- Risk policy: `goldenpath.risk-policy/v1`
- Evaluator: `scripts/evaluate-risk.py`
- Regression suite: `scripts/test-risk-adaptive-assurance.py`

The evaluator is deterministic and dependency-free. It consumes one JSON input containing versioned architecture metadata and a structured change descriptor, validates the policy, computes the effective risk as the maximum of all risk signals, and emits an assurance plan plus the exact requirements that must be embedded in an Evidence Manifest.

## Architecture as Code inputs

Every assessed service must declare:

- `owner`
- `serviceType`
- `dataSensitivity`
- `dependencies`
- `runtime`
- `sloTier`
- `deploymentUnit`
- `riskClass`

`riskClass` is a floor, not an override. Derived signals can raise risk above the declared class but can never lower it.

## Change signals

The reference evaluator considers change type plus explicit flags for production impact, policy changes, architecture changes, desired-state changes, identity/access changes, network-boundary changes, and data changes. Production impact always raises the plan to R4.

## Risk levels

| Level | Reference intent | Added assurance behavior |
|---|---|---|
| R0 | Documentation or negligible operational risk | Global assurance minimum only; automated autonomy. |
| R1 | Normal application/code change | Policy, unit, and supply-chain gates; policy-bounded autonomy. |
| R2 | Material architecture/runtime change | Integration + architecture gates, mandatory preview, runtime proof, domain review; guarded autonomy. |
| R3 | Critical infrastructure/security/reliability change | Least-privilege, security, rollback, SLO, owner approval, security review; supervised autonomy. |
| R4 | Production-impacting/highest-risk change | GitOps authority, production change control, platform + security human approvals; human-authorized autonomy. |

The committed policy stores the full effective control set for every tier. CI rejects any policy that removes a global minimum, removes a lower-tier gate/reviewer/approval, disables preview/runtime validation after it becomes required, or increases autonomy at a higher risk tier.

## Evidence Manifest binding

`goldenpath.evidence/v1` remains backward compatible and gains an optional `assurance` snapshot. The evaluator computes `planDigest` as the canonical SHA-256 digest of that assurance requirements snapshot, excluding the `planDigest` field itself.

When an assurance snapshot is present, the validator additionally requires:

1. assurance policy digest equals `inputs.policyDigest`;
2. assurance architecture digest equals `inputs.architectureDigest`;
3. the attached snapshot recomputes to its own `planDigest`;
4. `--expected-plan-digest` is supplied by the consumer from an independently generated authoritative assurance plan and equals the attached `planDigest`;
5. every `requiredGateId` exists in `gates` and is marked `required: true`;
6. every human-approval gate is included in the required gate set;
7. preview plans include the `preview-environment` gate;
8. runtime evidence exists and passes whenever the plan requires runtime validation, even if the evidence claim level itself remains `reference`;
9. the final `READY` / `NOT_READY` decision remains derived from evidence.

The external expected digest is the trust anchor. A producer cannot reduce an R3/R4 snapshot, recompute a matching self-declared digest, and still pass unless that forged digest also matches the independently derived plan accepted by the consumer.

## Global minimums and additive behavior

Risk-adaptive controls are additive. Existing root CI remains unconditional and is not selected or disabled by the risk engine. The policy also defines an assurance-specific global minimum (`baseline-ci` and `evidence-contract`) that every R0-R4 plan must retain.

## Local use

```bash
python3 scripts/evaluate-risk.py \
  platform-assurance/risk/examples/r2-change.json

python3 scripts/test-risk-adaptive-assurance.py
python3 scripts/test-evidence-contract.py
```

A consumer validating a manifest with assurance must first derive the authoritative plan and pass its digest:

```bash
PLAN_DIGEST="$(python3 scripts/evaluate-risk.py \
  platform-assurance/risk/examples/r2-change.json \
  | python3 -c 'import json,sys; print(json.load(sys.stdin)["evidenceRequirements"]["planDigest"])')"

python3 scripts/validate-evidence-manifest.py \
  path/to/evidence.json \
  --expected-plan-digest "$PLAN_DIGEST"
```

## Evidence boundary

This implementation is repository/reference evidence. It proves deterministic classification, policy monotonicity, fail-closed metadata handling, and Evidence Manifest enforcement. It does **not** prove that preview environments, runtime gates, reviewers, GitOps controllers, approval systems, or production targets are operational. Those claims require retained runtime evidence from the named target.

The emitted `requiredReviewerRoles` are structured requirements for a hosting/review controller. This repository does not yet auto-request GitHub reviewers from those roles because role-to-identity resolution is organization-specific and must itself be governed.
