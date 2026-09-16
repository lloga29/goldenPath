# Security Model

Golden Path uses defense in depth. No individual control is assumed to be sufficient on its own.

## Trust boundaries

Primary boundaries include:

- developer workstation to Git hosting;
- pull request to CI runner;
- CI runner to cloud/registry;
- GitOps controller to Git and clusters;
- workload to Kubernetes API and cloud APIs;
- cluster to secret manager;
- user traffic to ingress/application;
- observability agents to telemetry backends.

## Baseline controls

### Identity

Use SSO for humans, short-lived federation for automation, workload identity for applications, and least privilege throughout. Avoid shared permanent credentials.

### Change control

Production infrastructure, policy, and desired state should be changed through protected, reviewable paths with auditable identities.

### Secrets

Keep secret values outside Git. External Secrets is included as a reference integration; a production environment must connect it to an approved secret manager and configure identity, rotation, access logging, and failure behavior.

### Workload security

Use non-root containers where possible, drop unnecessary capabilities, prevent privilege escalation, use read-only filesystems where compatible, define resource requests/limits, and enforce admission policy.

### Network

Segment environments and customers according to risk. Control ingress and egress, protect administrative endpoints, and treat internal traffic as authenticated rather than automatically trusted.

### Supply chain

Pin dependencies, protect build runners, scan source and artifacts, generate SBOMs, sign releases, and verify trusted artifacts before deployment.

### Data

Classify data and apply encryption, retention, backup, and access controls appropriate to that classification.

## Security ownership

Platform security controls need a named owner. Product teams remain responsible for application vulnerabilities, authorization logic, domain data handling, and dependency risk inside their services.

## Validation

Security documentation is not proof of enforcement. Production readiness requires evidence from configured identity policies, protected branches/environments, policy tests, cluster admission behavior, secret-manager access controls, registry settings, and incident/recovery exercises.
