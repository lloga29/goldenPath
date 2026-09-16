# Public Portfolio Release Runbook

This runbook defines the publication gate for exposing GoldenPath as a public portfolio repository. It covers repository-hosting controls and public verification only; it does not turn repository/reference evidence into runtime or production evidence.

## Release principle

Publish only from an exact `main` commit whose complete root validation contract has passed. Record the candidate SHA and supporting workflow runs in the publication issue before changing visibility.

A public release is an administrative state transition, not a new claim about cloud or Kubernetes runtime behavior. Terraform plans, Helm renders, Kustomize builds, Conftest fixtures, and repository CI remain repository/reference evidence unless a separate runtime validation record exists.

## Required repository metadata

Use the following repository description:

> Production-oriented Golden Path reference implementation for Kubernetes platform engineering, GitOps, Terraform, policy-as-code, and developer self-service.

Recommended discovery topics:

- `platform-engineering`
- `golden-path`
- `internal-developer-platform`
- `kubernetes`
- `terraform`
- `argocd`
- `gitops`
- `devops`
- `opa`
- `github-actions`
- `developer-experience`
- `policy-as-code`

Leave the homepage field empty unless a real project documentation site is published and maintained.

## Pre-publication gate

Before changing visibility:

1. Confirm Apache-2.0 is detected by GitHub and contribution guidance is compatible with it.
2. Confirm the README still distinguishes implemented, reference, roadmap, and runtime-dependent capabilities.
3. Confirm `main` points to the intended publication candidate and has not advanced after validation.
4. Require successful post-merge runs for the exact candidate commit:
   - `Repository validation`;
   - `English-only repository`.
5. Confirm the complete reachable Git history passed the Gitleaks scan after the runtime canary proved the detector fails closed.
6. Review the current issue set for stale or private organizational context.
7. Search the current tree for publication-inappropriate identifiers, private infrastructure references, credentials, keys, certificates, connection strings, account IDs, customer names, and internal ticket references.
8. Remove stale merged branches and temporary branches that should not be part of the public presentation. In particular, no `noop-*`, `tmp-*`, patch-test, or placeholder branch should remain without an explicit reason.
9. Configure the repository description and discovery topics above.
10. Record any hosting/account limitation that prevents a control from being enabled while the repository is private.

## Main-branch governance

Normal changes must use pull requests. Direct pushes, force pushes, and branch deletion should be blocked for `main` wherever the hosting/account model supports those controls.

The root workflow exposes a stable `Repository validation gate` check. Configure branch protection or a branch ruleset to require at least:

- `Repository validation gate`;
- `english-only` from the `English-only repository` workflow.

The validation gate is designed to fail when any mandatory root job fails or is cancelled and to accept `skipped` only for change domains that were intentionally not applicable.

Additional recommended controls when supported:

- require a pull request before merging;
- require required status checks to be up to date before merging;
- block force pushes;
- block branch deletion;
- apply protections to administrators where practical;
- require review for changes from additional collaborators;
- enable automatic deletion of merged feature branches after the public branch inventory is clean.

GitHub currently documents protected branches and repository rulesets as available for public repositories on GitHub Free, while private-repository availability requires GitHub Pro, Team, or Enterprise plans. If the current account cannot protect a private repository, either upgrade and protect `main` before publication or publish the already validated candidate and configure protection immediately before accepting any further change.

Official references:

- [About protected branches](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches)
- [About rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets)

## Visibility transition

Use this order:

1. Freeze changes to `main`.
2. Re-read the publication issue and confirm no blocking item is unresolved except controls that become available only after public visibility.
3. Reconfirm the exact candidate SHA and its successful root workflows.
4. Configure description, topics, and homepage state.
5. Delete stale and temporary branches.
6. Configure `main` protection while private if the account supports it.
7. Change repository visibility to public deliberately from repository settings.
8. If protection was unavailable while private, configure branch protection or a ruleset immediately after the visibility change and before accepting any new change.
9. Verify the repository anonymously.
10. Record the final public verification in the publication issue and close it only when every acceptance criterion is satisfied.

## Anonymous verification

From a logged-out browser or another unauthenticated environment, verify:

- repository landing page, description, topics, and Apache-2.0 license;
- README logo, badges, Mermaid diagram, and documentation links;
- public issue visibility and absence of unintended private context;
- `git clone https://github.com/lloga29/goldenPath.git` succeeds;
- the documented quickstart is discoverable and uses only public repository paths;
- no private-only GitHub URL or private asset is required for README rendering;
- root GitHub Actions remain visible and continue working under public visibility;
- branch protection/ruleset status matches the intended governance configuration.

## Release completion record

The publication issue should contain, at minimum:

- final public `main` SHA;
- successful root workflow run links for that SHA;
- confirmation of full-history secret scanning;
- confirmation of repository metadata;
- confirmation of branch cleanup;
- confirmation of `main` protection;
- confirmation of anonymous clone/render/navigation checks;
- explicit statement that the evidence is repository/reference evidence unless separate runtime evidence is linked.
