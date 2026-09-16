# Runbook: Secret Rotation

## Scope

Use for planned or emergency rotation of application credentials, API keys, certificates, database passwords, or other externally managed secret material.

## Before rotation

- Identify all consumers and environments.
- Confirm the authoritative secret manager.
- Determine whether overlapping old/new values are supported.
- Confirm how External Secrets or equivalent synchronization propagates changes.
- Define validation and rollback behavior.

## Preferred pattern

When the protocol supports it, create a new credential, distribute it, verify consumers, then revoke the old credential. This avoids simultaneous producer/consumer cutover risk.

## Kubernetes synchronization

Verify the external secret resource and resulting Kubernetes Secret without printing the secret value:

```bash
kubectl get externalsecret -n <namespace>
kubectl describe externalsecret <name> -n <namespace>
kubectl get secret <name> -n <namespace>
```

Restart/reload workloads only if the application does not dynamically reload the credential.

## Emergency compromise

Prioritize revocation, preserve audit evidence, rotate dependent credentials if lateral exposure is possible, and review logs for unauthorized use.

## Validation

Verify authentication works with the new credential, the old credential is revoked, workloads are healthy, and secret-manager/Kubernetes audit evidence is retained.
