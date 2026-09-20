# GitHub Pages landing

GoldenPath includes a repository-owned static landing page under `site/`.

The site is intentionally small and dependency-free:

- no JavaScript;
- no analytics or tracking;
- no external font or CDN dependency;
- no static-site framework;
- no separate documentation source of truth.

The landing page links back to canonical repository documentation, publishes canonical/Open Graph/Twitter metadata, includes an accessible mobile navigation path, and uses repository-owned branding assets.

## Local build

From the repository root:

```bash
./scripts/build-pages-site.sh
```

The command creates `.pages-site/`, copies the required branding assets, and runs the standard-library validator.

To choose another local output directory:

```bash
./scripts/build-pages-site.sh /tmp/goldenpath-pages
```

## Validation contract

`scripts/validate-pages-site.py` fails closed when:

- `index.html` or `styles.css` is missing;
- a local image or stylesheet target is missing;
- a non-HTTPS external reference is introduced;
- a `<script>` tag is added;
- the release identifier, verification section, or core evidence-boundary messages disappear;
- canonical/social metadata drifts from the published project URL;
- required GoldenPath branding assets are missing or empty.

Root repository CI executes the same build/validation command so the public landing cannot silently drift.

## Deployment

`.github/workflows/pages.yaml` supports manual `workflow_dispatch` and automatically deploys validated site changes merged to `main`.

For v0.2.0, Pages publishes the release-aware landing and evidence dashboard after the site update is merged. The dashboard may claim supported ephemeral-runtime verification only when it is bound to the exact successful v0.2.0 Runtime Lab qualification run; production validation remains NOT CLAIMED.

The workflow separates permissions by job:

- build: `contents: read`;
- deploy: `actions: read`, `pages: write`, and `id-token: write`.

External actions are pinned to immutable commit SHAs.

## Evidence boundary

A successful Pages deployment proves that the static project landing was built and published. Runtime claims shown by the v0.2.0 dashboard are separately bound to the exact qualified Runtime Lab run and release commit. Pages itself does not create runtime evidence, and it never converts that evidence into production validation.

Refs #77.
