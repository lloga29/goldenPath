# Contributing to Golden Path

The Golden Path is a platform product. Changes must optimize both developer experience and operational safety.

## Repository language

English is mandatory for documentation, commit messages, pull request titles and descriptions, code comments, workflow labels, policy messages, generated examples, and operational output.

## Branch naming

Use short, descriptive branches with a conventional prefix:

- `docs/<topic>`
- `feat/<capability>`
- `fix/<defect>`
- `refactor/<area>`
- `chore/<maintenance>`
- `security/<control>`

Do not use agent or tool names as branch prefixes.

## Commit identity

All commits created for this repository must use:

```text
Juan Gallo <lloga29@gmail.com>
```

When a sign-off trailer is used, it must be:

```text
Signed-off-by: Juan Gallo <lloga29@gmail.com>
```

Do not add AI tool, automation agent, or assistant co-author trailers.

## Commit messages

Use Conventional Commit style where practical:

```text
docs: document disaster recovery model
feat: add workload identity policy
fix: enforce immutable image tags
chore: refresh Terraform validation versions
```

Each commit should represent a coherent unit of change. Avoid mixing functional changes with broad formatting or unrelated documentation updates.

## Pull requests

Every pull request should explain:

- the problem or platform need;
- the proposed change;
- affected platform domains;
- security and operational impact;
- validation performed;
- rollout and rollback implications;
- documentation impact.

Changes to production controls, identity, authorization, secrets, policy enforcement, networking, deployment strategy, or recovery behavior require explicit review by the appropriate platform/security owners in a production organization.

## Documentation requirements

A capability is incomplete when its documentation is missing. New platform capabilities should update, as applicable:

- architecture documentation;
- developer workflow documentation;
- security model;
- operating procedure or runbook;
- ADRs when a significant decision is introduced;
- ownership and support guidance;
- maturity model or roadmap.

## Validation expectations

Before requesting review, run the relevant checks for the changed area. Typical examples include:

```bash
terraform fmt -check -recursive
terraform validate
terraform test
conftest test <input> --policy platform-policies/
kustomize build <overlay>
go test ./...
```

The exact set depends on the repository area. Do not mark a validation as successful if the required tool, cloud credential, cluster, or dependency was unavailable.

## Security exceptions

Security or policy exceptions must be narrowly scoped, time-bounded, owned, justified, and tracked. See [Policy Exceptions](docs/governance/policy-exceptions.md).
