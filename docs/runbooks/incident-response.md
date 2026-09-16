# Runbook: Platform Incident Response

## Trigger

Use for a platform incident affecting shared delivery, identity, GitOps, policy, cluster services, secret synchronization, observability, or multiple application teams.

## First actions

1. Declare severity and incident owner.
2. Establish scope and customer/team impact.
3. Freeze or disable automation only if it is amplifying the incident.
4. Preserve evidence for security-sensitive incidents.
5. Identify the last known-good state and recent changes.

## Evidence checklist

Collect relevant commit SHAs, PRs, workflow runs, artifact digests, Argo CD history, Kubernetes events, cloud audit logs, admission-policy decisions, Terraform changes, and telemetry timestamps.

## Mitigation

Choose the smallest reversible action that reduces impact. Prefer rollback/revert to speculative forward fixes during high-severity incidents unless rollback is unsafe.

## Communications

Maintain a timeline of decisions, actions, owners, and validation. Communicate impact and recovery status according to the organization incident process.

## Recovery validation

Confirm not only application availability but also GitOps reconciliation, policy enforcement, secret synchronization, certificates, monitoring, and alerting.

## After the incident

Run a blameless review, identify systemic contributing factors, update runbooks/automation, and track follow-up work to completion.
