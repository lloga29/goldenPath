# Discoverability and SEO reassessment

Date: 2026-09-19

This review closes the naming/SEO assessment requested by the public-experience roadmap. It records a point-in-time measurement and a deliberately conservative naming decision.

## Current public baseline

GoldenPath now has:

- a public repository;
- a tagged public baseline release, `v0.1.0`;
- GitHub Pages;
- a repository social preview;
- GitHub Discussions;
- an executable zero-cloud demo;
- an end-to-end evidence-backed delivery showcase;
- a generated public evidence dashboard;
- a shareable technical insight series.

At this measurement point, the repository reports 0 stars, 0 forks, 0 watchers, and 0 subscribers. That is an early-distribution signal, not a quality judgment.

## Search sampling

GitHub repository search was sampled with several intent-oriented queries:

| Query | Observed result |
|---|---|
| `goldenpath platform engineering` | GoldenPath ranked first in the sampled repository results. |
| `golden path kubernetes gitops terraform` | GoldenPath ranked first in the sampled repository results. |
| `evidence-backed platform engineering` | GoldenPath did not appear in the sampled top results. |
| `R0 R4 assurance GitOps` | No repository results were returned in the sample. |

A separate external web-search sample did not yet surface this repository prominently for GoldenPath/platform-engineering queries. Older similarly named projects are already indexed.

Search ordering changes over time and is not a stable product metric. These observations are only a dated baseline.

## Naming decision

**Keep the repository name `goldenPath` for this cycle.**

Reasons:

1. GitHub search already associates the current name with relevant platform-engineering intent.
2. The repository was made public recently, so external indexing has had little time to stabilize.
3. The current name is already embedded in the release URL, clone URL, GitHub Pages URL, social preview, documentation, and shared links.
4. There is not enough evidence that a rename would improve discovery enough to justify breaking continuity.
5. GoldenPath's more defensible differentiation is semantic: evidence-backed delivery, R0-R4 risk-adaptive assurance, fail-closed evidence, signed provenance, and digest-bound GitOps.

A future rename should be considered only with stronger evidence, such as sustained search ambiguity after a meaningful distribution window.

## Non-disruptive SEO changes

This cycle strengthens discovery without changing stable URLs:

- expose **Internal Developer Platform** in the README first viewport;
- make the public Pages description explicitly mention evidence-backed Kubernetes platform engineering, IDPs, R0-R4 assurance, fail-closed evidence, GitOps, Terraform, policy as code, SBOM, SLSA, and Cosign;
- link the end-to-end showcase and technical insight series directly from the public landing page;
- validate the description, Open Graph description, and Twitter description in CI.

## Repository metadata target

GitHub repository settings should use this About description:

> Evidence-backed Golden Path for Kubernetes platform engineering and internal developer platforms: R0-R4 assurance, fail-closed evidence, GitOps, Terraform, policy as code, SBOM/SLSA/Cosign.

Keep the existing topics and add these focused topics:

- `devsecops`
- `software-supply-chain`
- `slsa`
- `cosign`

These additions complement, rather than replace, the existing platform-engineering, Kubernetes, GitOps, Terraform, OPA, policy-as-code, developer-experience, and internal-developer-platform topics.

## Evidence boundary

Search position, stars, forks, and indexing are distribution observations. They are not runtime or production evidence for GoldenPath's technical controls.

Likewise, stronger metadata can improve discoverability but does not prove adoption or production use.
