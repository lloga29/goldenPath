# Naming and Metadata

Consistent metadata is required for ownership, policy, cost, observability, and automation.

## Core metadata

Use consistent representations of:

- service;
- team/owner;
- environment;
- client/tenant where applicable;
- cost center;
- managed-by;
- application version;
- criticality/tier.

## Resource names

Names should be deterministic, DNS/cloud compatible where required, lowercase when portability matters, and free of personal names or temporary task identifiers.

A common pattern is:

```text
<service>-<environment>-<resource>
```

Do not force every provider resource into one naming scheme if provider constraints make it harmful.

## Kubernetes labels

Prefer standard Kubernetes application labels such as `app.kubernetes.io/name`, `app.kubernetes.io/instance`, `app.kubernetes.io/version`, `app.kubernetes.io/component`, `app.kubernetes.io/part-of`, and `app.kubernetes.io/managed-by`, supplemented by organization-specific ownership/cost labels.

## Terraform tags

The reference modules use metadata such as `Environment`, `Team`, `CostCenter`, `Owner`, and `ManagedBy`. Production policy should define required keys and accepted values centrally.
