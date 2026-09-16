# Environment Model

The reference platform uses four environment classes: development, staging, production, and ephemeral.

## Development

Development optimizes for feedback speed. Automated synchronization and disposable changes are acceptable when blast radius is constrained. Security controls should still prevent clearly unsafe workloads.

## Staging

Staging should resemble production closely enough to validate deployment behavior, policy, configuration, migrations, observability, and rollback. It is not a substitute for production isolation, but differences should be intentional and documented.

## Production

Production prioritizes availability, auditability, controlled promotion, least privilege, and recoverability. Production changes should be based on immutable artifacts already exercised in lower environments.

## Ephemeral environments

Ephemeral environments provide pull-request or short-lived validation. They should have explicit TTLs, resource quotas, non-production data, isolated DNS/namespaces, and automatic cleanup.

## Promotion contract

Promotion should move the same artifact identity through environments. Environment-specific configuration may differ, but application binaries or container images should not be rebuilt during promotion.

## Configuration boundaries

Keep the following out of reusable platform modules unless they are genuine defaults:

- account/subscription/project IDs;
- real domain names;
- cluster API endpoints;
- secret identifiers and secret values;
- client-specific CIDRs;
- registry coordinates;
- production approval identities;
- data-residency choices.

These belong to environment configuration with explicit ownership.
