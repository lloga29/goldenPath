# Documentation Standard

Documentation is part of the platform interface and must remain aligned with executable behavior.

## Language

English is mandatory across this repository.

## Documentation classes

- **Overview:** explains purpose and boundaries.
- **How-to:** guides a known task.
- **Reference:** documents commands, APIs, inputs, outputs, and configuration.
- **Runbook:** supports time-sensitive operational response.
- **ADR:** records an important architectural decision and consequences.

## Required qualities

Documentation should be version-controlled, link to authoritative paths, identify assumptions, distinguish implemented behavior from target state, include executable examples where safe, and avoid real secrets/customer data.

## Runbooks

A runbook should state trigger/symptoms, impact, prerequisites, diagnosis, mitigation/recovery, validation, escalation, and follow-up.

## Architecture decisions

Create an ADR when changing a durable platform assumption such as GitOps technology, artifact promotion model, identity architecture, cluster tenancy model, policy engine, observability architecture, or repository topology.

## Review

Documentation changes receive the same review discipline as code when they define operational or security behavior.
