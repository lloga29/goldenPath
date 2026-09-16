# ingress-nginx to Gateway API Migration

## Purpose

This runbook defines the safe migration path from legacy ingress-nginx deployments to the Golden Path Gateway API baseline backed by Envoy Gateway. It is intentionally a migration procedure, not an instruction to delete ingress-nginx first.

## Safety principles

1. Inventory every `Ingress`, `IngressClass`, controller ConfigMap setting, admission webhook, TCP/UDP mapping, custom snippet, authentication integration, rate limit, timeout, body-size setting, forwarded-header assumption, and TLS secret before translation.
2. Treat annotations as behavior, not metadata. Many ingress-nginx annotations have no one-to-one Gateway API equivalent.
3. Run the new Gateway path in parallel and prove traffic behavior before moving production DNS or load-balancer ownership.
4. Preserve the old controller until rollback criteria are satisfied.
5. Make cutover and rollback changes through reviewed Git pull requests.

## Target ownership model

- Platform team: Envoy Gateway controller, Gateway API CRDs, `GatewayClass`, cluster/network integration, observability, and policy.
- Environment/platform owners: public/private `Gateway` resources, load-balancer details, and shared listeners.
- Application teams: `HTTPRoute`/`GRPCRoute`/other permitted routes and backend references.
- Certificate automation: cert-manager or another approved certificate system produces listener Secrets from real issuers; no placeholder issuer is part of the baseline.

## Migration sequence

### 1. Inventory and classify

Export existing Ingress objects and ingress-nginx configuration. Group routes by hostname, TLS boundary, authentication behavior, path rewriting, upstream protocol, timeout/retry behavior, and controller-specific annotations.

Use Kubernetes `ingress2gateway` as an assistance tool where useful, but review generated resources manually. Conversion does not prove behavioral equivalence.

### 2. Install the new control plane

Reconcile the Envoy Gateway Application for the target environment and verify:

- Envoy Gateway deployment is Available.
- Gateway API and Envoy Gateway CRDs are established.
- `GatewayClass/golden-path` reports `Accepted=True`.
- controller metrics and logs are visible to the platform observability stack.

Do not remove the old ingress controller during this phase.

### 3. Define a real Gateway

Create environment-owned `Gateway` resources using `gatewayClassName: golden-path`. Public/private load-balancer behavior, addresses, annotations, and cloud-specific configuration must be explicit for the target cluster rather than copied from a generic example.

### 4. Migrate TLS deliberately

For HTTPS listeners, use `tls.mode: Terminate` and reference a Secret through `certificateRefs`. If cert-manager owns certificate issuance, enable its Gateway API integration at a supported version and use a real Issuer or ClusterIssuer. The certificate Secret must be in a namespace allowed by the Gateway/certificate design; do not commit private keys or placeholder production certificates.

### 5. Translate routes

Create Gateway API routes and reproduce required behavior with portable Gateway API fields first. Use Envoy Gateway policies only when the behavior cannot be expressed portably. Record every remaining implementation-specific dependency.

### 6. Validate before cutover

At minimum validate:

- HTTP status, redirects, path matching, rewrites, headers, request-size limits, and timeouts.
- WebSocket/gRPC behavior where applicable.
- client IP and forwarded-header semantics.
- TLS certificate chain, renewal path, SNI, and supported protocols.
- authentication/authorization and rate-limit behavior.
- health probes, load-balancer readiness, metrics, logs, traces, and alerts.
- capacity, latency, error rate, and failure behavior under representative load.

### 7. Cut over gradually

Shift traffic using the mechanism supported by the real DNS/load-balancer environment. Prefer a reversible staged cutover. Monitor Golden Signals and application-specific SLOs throughout the change.

### 8. Roll back when required

Rollback means returning traffic to the proven ingress-nginx path while it still exists, not attempting an emergency configuration rewrite. Revert the traffic switch first, verify recovery, then diagnose the Gateway path.

### 9. Retire the legacy controller

Only after the rollback window closes:

- verify no Ingress objects depend on ingress-nginx;
- remove ingress-nginx-specific admission/configuration resources;
- remove obsolete firewall/load-balancer/DNS resources;
- archive migration evidence and update the service/network inventory.

## Repository status

The Golden Path no longer treats ingress-nginx as a supported new-production baseline. The reference Envoy Gateway controller and GatewayClass are declared in Git. Environment-specific Gateways, routes, DNS, certificate issuers, and load-balancer integrations must be supplied by a real adopter because fabricating those values would create unsafe desired state.
