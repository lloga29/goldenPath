# Self-Service Model

Self-service means teams can perform common platform operations through documented, reviewable interfaces without opening a manual platform ticket for every change.

## Supported self-service surfaces

The current repository provides reference building blocks for:

- generating a Go service from Copier;
- validating Terraform modules and platform stacks;
- rendering Kubernetes desired state with Kustomize;
- evaluating policy-as-code locally and in CI;
- promoting immutable application images by GitOps change;
- rolling back desired state through a reviewed branch and pull request.

A reference file is not automatically a production service. Organizations must connect these interfaces to their real repositories, identity model, registries, clusters, and approval controls.

## Guardrails

Self-service operations must preserve:

- least privilege;
- immutable artifact identity;
- protected default branches;
- mandatory CI and policy checks;
- explicit ownership;
- auditable changes;
- bounded production authority;
- recoverability.

Fast paths must not bypass security or operational controls merely to reduce ticket volume.

## Exceptions

When the paved road cannot support a legitimate requirement, record the gap. Use a governed, time-bounded exception only when the risk is understood and approved. Repeated exceptions for the same need are evidence that the platform should add a supported capability.

## Platform-product feedback loop

Track template adoption, CI duration, policy failure causes, lead time, deployment success, rollback frequency, active exceptions, support requests, and abandoned workflows. Use those signals to improve the paved road rather than adding undocumented one-off automation.

## Success criterion

A team should be able to discover the supported path, execute it with ordinary engineering permissions, understand a failed guardrail, and recover from a release without needing hidden knowledge from a specific platform engineer.
