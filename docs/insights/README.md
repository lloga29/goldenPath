# GoldenPath technical insights

This series turns GoldenPath's core assurance and delivery contracts into concise technical explanations that can be shared independently.

Each article follows the same discipline:

- start with the engineering problem;
- point to the repository contract that addresses it;
- describe the failure mode the control is designed to prevent;
- link to concrete implementation evidence;
- state where repository/reference evidence ends and runtime or production validation must begin.

## Series

| Topic | Shareable summary | Read |
|---|---|---|
| R0-R4 risk-adaptive assurance | Add controls as change risk increases without letting higher-risk tiers weaken lower-tier minimums. | [Risk-adaptive assurance](r0-r4-risk-adaptive-assurance.md) |
| Fail-closed evidence | Treat missing, stale, untrusted, or infrastructure-blocked proof as a reason to stop rather than a reason to assume success. | [Fail-closed evidence](fail-closed-evidence.md) |
| Signed provenance | Bind release trust to one immutable artifact digest, its build evidence, and the workflow identity that signs it. | [Signed provenance](signed-provenance.md) |
| Digest-bound GitOps | Promote the exact verified digest through environments instead of resolving mutable tags or rebuilding per environment. | [Digest-bound GitOps](digest-bound-gitops-promotion.md) |

## End-to-end context

For the executable repository/reference journey that composes these ideas, see the [end-to-end evidence-backed delivery showcase](../showcases/evidence-backed-delivery.md).

## Evidence boundary

These articles describe contracts implemented and validated in this repository. They do not claim that a real registry, cloud account, GitOps controller, Kubernetes cluster, approval system, or production workload has exercised every contract. Those stronger claims require retained evidence from the named runtime or production target.
