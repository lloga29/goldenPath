# ADR-0008: Standardize North-South Traffic on Gateway API with Envoy Gateway

- Status: Accepted

## Context

The original reference baseline installed ingress-nginx. Kubernetes retired Ingress NGINX in March 2026; after retirement it receives no releases, bug fixes, or security fixes. Retaining it as the default controller for new production adoption would create an avoidable security and lifecycle risk.

Gateway API is the Kubernetes successor model for ingress traffic and separates infrastructure ownership from application routing more cleanly than annotation-heavy Ingress resources.

## Decision

Use Kubernetes Gateway API as the platform traffic API and Envoy Gateway as the reference Gateway API implementation.

The Golden Path installs Envoy Gateway through its upstream OCI Helm chart and manages a platform-owned `GatewayClass` named `golden-path`. Application teams own `Gateway`/route resources within the authorization model defined by the adopting platform.

The repository does not create a fake default public Gateway, DNS name, certificate, or cloud load-balancer contract. Those are environment-specific decisions that require real DNS, certificate issuer, network, and cloud context.

## Consequences

- ingress-nginx is removed from the recommended production baseline.
- Teams must migrate Ingress resources and controller-specific annotations deliberately; a mechanical rename is not sufficient.
- TLS remains based on Gateway listener `certificateRefs`. cert-manager can issue the referenced Secrets when Gateway API integration is enabled and a real Issuer/ClusterIssuer exists.
- Existing ingress-nginx deployments require parallel-run, traffic verification, and rollback planning before controller removal.
- Envoy Gateway and Gateway API CRD compatibility become an explicit platform upgrade concern.
