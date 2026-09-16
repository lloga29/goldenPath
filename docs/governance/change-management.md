# Change Management

Golden Path change management should maximize reviewability and automation rather than depend on manual tickets for every routine deployment.

## Normal changes

Routine application and platform changes flow through pull requests, automated validation, review, merge, and controlled reconciliation/apply.

## High-risk changes

Changes to identity, production networking, Terraform bootstrap/state, policy enforcement, Argo CD control-plane permissions, secret infrastructure, cluster upgrades, and disaster-recovery behavior require heightened review and rollout planning.

## Change description

A high-quality change records scope, motivation, affected environments, security impact, validation, rollout, rollback, monitoring, dependencies, and owner.

## Progressive rollout

Prefer staged adoption: development, staging, a limited production slice, then broader rollout. Platform-level changes should consider canary clusters or tenants when architecture supports them.

## Emergency changes

Emergency actions may bypass the normal path only when the normal path cannot meet the incident need. Record the actor, reason, commands/changes, timestamp, and follow-up Git reconciliation. Emergency access must not become a permanent parallel deployment model.

## Freeze and maintenance windows

Use freezes only for clear risk reasons. The platform should remain capable of urgent security and incident changes during a freeze through an explicit exception path.
