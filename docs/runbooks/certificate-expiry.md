# Runbook: Certificate Expiry or Renewal Failure

## Trigger

Use when TLS certificates approach expiry, cert-manager reports renewal errors, or clients observe invalid/expired certificates.

## Triage

```bash
kubectl get certificate,certificaterequest,order,challenge -A
kubectl describe certificate <name> -n <namespace>
kubectl logs -n cert-manager deploy/cert-manager --tail=200
```

Verify DNS, issuer configuration, challenge routing, rate limits, permissions, and clock/time validity.

## Mitigation

Fix the underlying issuer/challenge problem and allow cert-manager to reconcile. Emergency manual certificate replacement may be used only through the approved incident path and must be reconciled with declarative configuration afterward.

## Validation

Verify the served certificate chain, hostname/SANs, expiry, issuer, client connectivity, and monitoring state.

## Prevention

Alert well before expiry and monitor renewal errors rather than relying only on certificate age.
