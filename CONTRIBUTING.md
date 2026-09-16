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
- `ci/<validation-or-delivery-change>`

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
python3 scripts/check-english-only.py
python3 scripts/check-markdown-links.py
terraform fmt -check -recursive
terraform validate
terraform test
conftest test <input> --policy platform-policies/
kustomize build <overlay>
./service-templates/scripts/render-go-template-smoke-test.sh
```

The exact set depends on the repository area. Do not mark a validation as successful if the required tool, cloud credential, cluster, or dependency was unavailable.

## Root CI contract

`.github/workflows/repository-validation.yaml` is the active validation contract for this consolidated repository. It always validates repository language, YAML/JSON syntax, and shell syntax, then runs domain-specific jobs when relevant paths change:

- documentation: local Markdown links;
- Terraform: reusable modules/tests and executable platform stacks;
- GitOps/policy: Kustomize builds, Conftest fixtures, and exception-registry validation;
- service templates: a real Copier render followed by Go format/vet/test/build checks.

Domain detection is implemented by `scripts/detect-ci-domains.py`. Changes to the root CI workflow or root validation scripts deliberately execute every domain so CI changes validate themselves.

Nested workflows under component directories remain reference blueprints unless they are copied into standalone repositories. A green nested blueprint is not a substitute for this root CI contract.

## Security exceptions

Security or policy exceptions must be narrowly scoped, time-bounded, owned, justified, and tracked. See [Policy Exceptions](docs/governance/policy-exceptions.md).
