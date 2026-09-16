# Golden Path Maturity Model

## Evidence status versus maturity

GoldenPath separates **evidence status** from **platform maturity**. Evidence status describes what is proven for one capability and exact state; maturity describes platform breadth and operating model.

Evidence vocabulary:

- `implemented` — code/configuration exists and is structurally valid;
- `reference` — executable repository pattern with deterministic repository evidence;
- `runtime-validated` — exact capability/source state exercised against an identified runtime with successful runtime evidence;
- `production-validated` — exact capability/source state exercised against production with successful production runtime evidence.

`goldenpath.evidence/v1` defines the evidence contract. `goldenpath.assurance/v1` adds R0-R4 risk-derived control requirements without changing evidence status semantics.

## Level 0 — Ad hoc

Teams provision and deploy independently. Credentials, environments, and operational practices are inconsistent. Platform knowledge is mostly tribal.

## Level 1 — Standardized baseline

Reusable modules, service template, CI, GitOps layout, documentation, policy, fail-closed Evidence Manifest, Architecture as Code metadata, and deterministic R0-R4 risk-adaptive assurance exist. The current repository remains primarily a **Level 1 reference baseline**, with Level 2 design elements.

Repository CI now proves that risk classification is deterministic, higher risk cannot remove lower-tier/global controls, invalid metadata fails closed, and an Evidence Manifest cannot ignore an attached assurance plan. This remains `reference` evidence, not proof that real preview/runtime/approval systems are operational.

## Level 2 — Operational paved road

A real team uses the platform end to end. Root CI, federated identity, real clusters/registries/secrets/observability, protected production changes, SLOs, tested rollback, retained runtime evidence, and enforcement of the emitted risk plan are operational. Reviewer-role resolution and human approvals are connected to real identities and protected change paths.

## Level 3 — Scaled platform product

Multiple teams use self-service onboarding. Catalog/scorecards, standardized telemetry, automated exceptions/upgrades, capacity/product feedback loops, and evidence retention/aggregation are established. Risk signals and policy are managed as platform product contracts across many services.

## Level 4 — Optimized and evidence-driven

Outcome metrics continuously improve delivery/reliability. Provenance, automated compliance evidence, tested disaster recovery, cost controls, and low-touch upgrades operate at scale. Evidence collection, risk classification, invalidation, and reconciliation are normal platform operations rather than manual audit activities.

## Advancement rule

Do not advance maturity from repository files or green CI alone. Require repository evidence for `implemented/reference`, runtime proof for `runtime-validated`, production proof for `production-validated`, and adoption/operating evidence for platform maturity. Stale evidence must be regenerated when source, policy, architecture metadata, desired state, artifact identity, or relevant target configuration changes.
