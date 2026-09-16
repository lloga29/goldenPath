# Incident Management

Incidents involving the Golden Path can affect many services at once because the platform controls shared delivery, identity, policy, and runtime capabilities.

## Severity

Define organization-specific severity based on customer impact, security impact, scope, and duration. Shared control-plane incidents may require higher severity because of broad blast radius even when individual applications remain healthy.

## Roles

A mature incident process assigns an incident commander, technical responders, communications owner, and subject-matter experts as needed. Avoid uncoordinated production changes during a high-severity incident.

## Immediate priorities

1. Establish impact and scope.
2. Stop unsafe automation if it is amplifying the incident.
3. Preserve evidence when security may be involved.
4. Mitigate customer impact.
5. Restore a known-good state.
6. Verify monitoring and downstream recovery.
7. Communicate status and decisions.

## Platform-specific evidence

Capture commit SHAs, pull requests, workflow runs, artifact digests, Argo CD history, Kubernetes events, policy decisions, cloud audit logs, recent Terraform changes, and relevant telemetry.

## Post-incident review

Focus on contributing system conditions, not individual blame. Produce concrete follow-up work with owners and due dates, then update runbooks, policy, templates, monitoring, or architecture so the paved road improves.
