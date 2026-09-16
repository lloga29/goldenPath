# Policy Exceptions

Policy exceptions provide a controlled path for legitimate cases that cannot immediately satisfy a guardrail.

## Required fields

Every exception should contain:

- unique identifier;
- requesting owner/team;
- affected resource/service/environment;
- exact policy being bypassed;
- technical/business justification;
- risk assessment;
- compensating controls;
- approver;
- creation date;
- expiration date;
- remediation plan and owner.

## Rules

Exceptions must be narrow, time-bounded, reviewable, and discoverable. Avoid global policy disablement for a single workload.

## Lifecycle

1. Request.
2. Review risk and alternatives.
3. Approve or reject.
4. Implement the smallest bypass.
5. Monitor usage.
6. Remediate before expiration.
7. Remove and verify the exception.

## Metrics

Track active exceptions, expired exceptions, average age, repeated exception reasons, and exceptions by policy. A growing exception backlog often indicates either an unrealistic policy or platform capability missing from the paved road.

## Repository baseline

`platform-policies/policy-exceptions.yaml` is the current reference mechanism. Production organizations may integrate exceptions with ticketing or governance systems, but executable policy should still be able to determine whether the exception is valid and unexpired.
