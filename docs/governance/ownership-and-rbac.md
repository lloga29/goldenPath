# Ownership and RBAC

Ownership must be explicit at repository, platform component, environment, service, and incident levels.

## Ownership layers

- **Platform team:** shared modules, templates, GitOps control plane, platform add-ons, policies, platform reliability.
- **Security:** security standards, high-risk exceptions, incident support, vulnerability governance.
- **Product teams:** application behavior, domain data, service dependencies, business SLOs, service-specific runbooks.
- **Cloud/enterprise administrators:** account/subscription/project governance and organization-level controls where applicable.

## RBAC principles

- least privilege;
- separation of duties for sensitive production operations;
- group-based access instead of individual grants where practical;
- time-bounded elevation for exceptional work;
- periodic access review;
- auditable changes.

## Git

Use protected branches, CODEOWNERS, required reviews, and environment protection for production-affecting paths. The component-level CODEOWNERS files in this consolidated reference must be moved or represented at the effective repository root when deployed as real repositories.

## Argo CD

AppProjects should restrict source repositories, destinations, clusters/namespaces, and resource types. Avoid a single unrestricted project for all teams.

## Kubernetes

Namespace and cluster roles should be aligned to team responsibilities. Workloads need service accounts with only the API permissions they actually require.

## Cloud IAM

Separate read/plan, apply/deploy, and administrative permissions where risk justifies it. CI trust relationships should be restricted by repository and environment claims.
