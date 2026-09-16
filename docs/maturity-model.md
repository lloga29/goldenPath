# Golden Path Maturity Model

## Evidence status versus maturity

GoldenPath separates **evidence status** from **platform maturity**. Evidence status describes what is proven for one capability and one exact source/runtime state; maturity describes the breadth and operating model of the platform as a whole.

Use the following evidence vocabulary consistently:

- `implemented` — code or configuration exists and is structurally valid;
- `reference` — an executable repository pattern is demonstrated with deterministic repository evidence;
- `runtime-validated` — the exact capability/source state was exercised against an identified runtime with successful runtime evidence;
- `production-validated` — the exact capability/source state was exercised against the production target with successful production runtime evidence.

The machine-readable rules are defined by `goldenpath.evidence/v1`; see [Evidence contract](assurance/evidence-contract.md). R0-R4 change assurance is defined separately by `goldenpath.assurance/v1`; it adds risk-derived controls without changing these evidence-status meanings.

## Level 0 — Ad hoc

Teams provision and deploy independently. Credentials, environments, and operational practices are inconsistent. Platform knowledge is mostly tribal.

## Level 1 — Standardized baseline

Reusable modules, a service template, basic CI, GitOps layout, documentation, initial policy, and a machine-readable assurance contract exist. The current repository is primarily a **Level 1 reference baseline**, with some Level 2 design elements.

The reference baseline also includes versioned Architecture as Code metadata and deterministic R0-R4 risk classification. Repository CI can prove classification, monotonic control selection, and fail-closed Evidence Manifest enforcement. It cannot prove that preview environments, reviewers, approvals, or external runtimes are operational.

A Level 1 repository can contain `reference` evidence. That does not make external dependencies runtime-validated.

## Level 2 — Operational paved road

A real team uses the platform end to end. Root/active CI workflows, federated identity, real clusters, registries, secrets, observability, protected production changes, SLOs, tested rollback, and retained runtime evidence are operational.

At this level, R0-R4 plans should also be enforced by the real delivery path: reviewer roles must resolve to governed identities, required preview/runtime gates must execute against identified targets, and human approvals must be retained as evidence.

Capabilities claimed as operational should produce `runtime-validated` or, where appropriate, `production-validated` Evidence Manifests bound to exact source and artifact identities.

## Level 3 — Scaled platform product

Multiple teams use self-service onboarding. A service catalog, scorecards, standardized telemetry, automated policy exceptions, upgrade automation, capacity management, product feedback loops, and evidence retention/aggregation are established.

## Level 4 — Optimized and evidence-driven

The platform uses outcome metrics to continuously improve delivery and reliability. Supply-chain provenance/verification, automated compliance evidence, tested disaster recovery, sophisticated cost controls, and low-touch platform upgrades operate at scale.

At this level, evidence collection and invalidation should be integrated into normal platform reconciliation rather than treated as a manual audit activity.

## Advancement rule

Do not advance a maturity claim based only on repository files, manifests, or a green CI run. Require evidence appropriate to the claim:

1. repository evidence for `implemented` and `reference` claims;
2. runtime evidence for `runtime-validated` claims;
3. production runtime evidence for `production-validated` claims;
4. adoption and operating evidence before advancing the platform-level maturity tier.

Evidence becomes stale when its bound source, policy, architecture metadata, desired state, artifact identity, or relevant target configuration changes. Stale evidence must be regenerated rather than reinterpreted.
