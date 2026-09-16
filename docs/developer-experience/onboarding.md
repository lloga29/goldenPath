# Application Onboarding

Application onboarding turns a new service idea into a repository and deployable workload that follows the Golden Path contract.

## Entry criteria

Before onboarding, identify:

- service name and owning team;
- accountable owner email;
- workload type and primary runtime;
- data, network, and external dependency needs;
- expected environments;
- security or compliance constraints;
- initial availability and recovery expectations.

Do not request production infrastructure before ownership and operational responsibility are clear.

## Paved-road flow

1. Select an implemented service template. The current executable baseline is `microservice-golang`.
2. Render the template with team and ownership metadata.
3. Run local template validation and application tests.
4. Create the service repository and protect its default branch.
5. Configure package/container publication with immutable identifiers.
6. Add or generate the service's GitOps desired state for development.
7. Validate policy, resource, security-context, health/readiness, and observability requirements.
8. Promote the same immutable artifact through staging and production using reviewed Git changes.
9. Register dashboards, alerts, runbooks, ownership, and escalation paths before production readiness is declared.

## Platform responsibilities

The platform should provide secure defaults, reusable templates, policy checks, documented workflows, and discoverable operational guidance. It should not silently assume ownership of application-specific data correctness, business SLOs, or incident decisions.

## Application-team responsibilities

The owning team remains responsible for application code, dependency behavior, business configuration, data migrations, service-level objectives, on-call response, and validating releases in representative environments.

## Exit criteria

Onboarding is complete when the service repository builds successfully, its desired state can be rendered, mandatory controls pass, ownership is explicit, and an operator can find the service's support and rollback information without tribal knowledge.
