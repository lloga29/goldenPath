# Branching and Releases

## Branches

Use short-lived branches with clear conventional prefixes such as `feat/`, `fix/`, `docs/`, `security/`, `refactor/`, and `chore/`.

Do not name branches after AI assistants, automation tools, or temporary execution environments.

## Default branch

`main` represents the reviewed integration baseline. Production deployment does not have to happen automatically from every merge; deployment authority is controlled separately by the appropriate pipeline/GitOps model.

## Pull requests

Use descriptive English titles and bodies. Keep changes focused and make validation, rollout, and rollback clear.

## Commits

Use Conventional Commit-style messages where practical. Commits for this repository use the configured identity `Juan Gallo <lloga29@gmail.com>` and should not include AI tool co-author trailers.

## Releases

Reusable modules and templates should use semantic versions. Release artifacts must be immutable. Tags that identify production artifacts must not be silently moved.

## Promotion

Promotion is not a rebuild. The same artifact digest or immutable reference moves from development to staging to production through reviewed desired-state changes.
