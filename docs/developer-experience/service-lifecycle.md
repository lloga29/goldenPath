# Service Lifecycle

The Golden Path treats a service as an operated product rather than a one-time deployment.

## 1. Create

Generate the service from an implemented template, establish ownership, and keep the first commit small enough to validate the generated baseline before adding business functionality.

## 2. Develop

Use short-lived branches and pull requests. CI should validate formatting, tests, security controls, configuration syntax, and build reproducibility. Local development must not require production credentials.

## 3. Build

Build an artifact once. Publish images with immutable tags or digests, record source revision and build provenance, and do not rebuild the application separately for each environment.

## 4. Deploy to development

Update GitOps desired state and let the reconciler apply it. Development may use automatic synchronization when the repository policy explicitly allows it.

## 5. Promote

Promotion changes desired state to reference the already-built artifact. Staging validates release behavior; production requires the explicit approval and reconciliation model documented for the environment.

## 6. Operate

Every production service needs observable health, logs, metrics, useful alerts, an owner, a runbook, and a recovery path. Teams should review SLO/error-budget signals rather than treating a successful deployment as proof of service health.

## 7. Patch and recover

Normal recovery should flow through Git. Emergency runtime intervention is acceptable only when incident response requires it; reconcile the final desired state back into Git immediately afterward.

## 8. Deprecate

Deprecation requires consumer communication, a migration path, data-retention decisions, secret and credential revocation, alert/dashboard cleanup, and an explicit removal date.

## 9. Retire

Remove the workload, delivery credentials, GitOps entries, infrastructure that is no longer shared, stale DNS/certificates, and monitoring noise. Preserve audit records and required data according to retention policy.

## Lifecycle principle

A service is not complete when it first reaches production. The paved road must make ongoing patching, promotion, observation, recovery, and retirement repeatable and auditable.
