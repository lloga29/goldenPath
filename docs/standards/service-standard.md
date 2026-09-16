# Golden Service Standard

A service is considered aligned with the Golden Path when it satisfies the organization-approved version of this contract.

## Required

- named owner/team;
- source repository and reviewed change path;
- automated build/test baseline;
- immutable artifact version;
- documented runtime configuration;
- health/readiness behavior;
- resource requests/limits for Kubernetes workloads;
- non-root/least-privilege runtime where feasible;
- no production secrets in Git;
- metrics/logs and appropriate traces;
- SLO or service objective appropriate to criticality;
- alert owner;
- GitOps or approved deployment path;
- rollback/runbook documentation;
- required ownership/cost metadata;
- dependency and vulnerability maintenance process.

## Recommended

- SBOM and signed/provenanced artifacts;
- automated integration/contract tests;
- load/performance baseline;
- dependency catalog metadata;
- resilience testing for critical services;
- documented data classification and retention.

## Scorecards

A future service catalog can calculate these controls automatically. Scorecards should guide improvement rather than become vanity metrics; every scored item should map to a meaningful risk or developer outcome.
