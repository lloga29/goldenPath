# GitHub Pages landing

GoldenPath includes a repository-owned static landing page under `site/`.

The site is intentionally small and dependency-free:

- no JavaScript;
- no analytics or tracking;
- no external font or CDN dependency;
- no static-site framework;
- no separate documentation source of truth.

The landing page links back to canonical repository documentation and uses existing branding assets.

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
- the release identifier or core evidence-boundary messages disappear;
- required GoldenPath branding assets are missing or empty.

Root repository CI executes the same build/validation command so the public landing cannot silently drift.

## Deployment

`.github/workflows/pages.yaml` is intentionally manual through `workflow_dispatch`.

Do not run it until:

1. the `v0.1.0` GitHub Release exists;
2. GitHub Pages is configured to use GitHub Actions as its source;
3. issue #75 is complete;
4. the Pages implementation PR is merged to `main`.

The workflow separates permissions by job:

- build: `contents: read`;
- deploy: `actions: read`, `pages: write`, and `id-token: write`.

External actions are pinned to immutable commit SHAs.

## Evidence boundary

A successful Pages deployment proves that the static project landing was built and published. It does not convert repository/reference evidence into runtime or production evidence for the platform architecture described by the site.

Refs #77.
