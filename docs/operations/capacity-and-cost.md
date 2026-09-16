# Capacity and Cost Management

Golden Path should make resource ownership and cost visible without turning cost optimization into manual friction for every developer.

## Capacity responsibilities

The platform team owns shared control-plane capacity and standard resource envelopes. Product teams own workload-specific demand and scaling behavior within platform guardrails.

## Kubernetes capacity

Monitor requests, limits, utilization, scheduling failures, node pressure, autoscaler behavior, disruption budgets, and workload growth. Resource limits without measurement can cause throttling; missing requests can make scheduling and capacity planning unreliable.

## Infrastructure capacity

Track cloud service quotas, subnet/IP capacity, registry/storage growth, Terraform backend constraints, load balancer limits, certificate/DNS dependencies, and observability backend ingestion/storage.

## Cost allocation

Use consistent tags/labels for environment, team, owner, service, cost center, and client where applicable. Cost metadata must be enforced close to provisioning so unallocated spend does not become normal.

## Cost feedback

Infracost or provider-native estimates can provide pull-request feedback. Cost estimates should normally be advisory unless the organization has explicit budget policies with known accuracy and exception handling.

## FinOps metrics

Useful platform measures include cost per environment/team/service, idle resources, ephemeral environment lifetime, unallocated spend, observability cost by signal, storage growth, and savings from rightsizing/reservations where applicable.
