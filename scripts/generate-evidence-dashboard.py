#!/usr/bin/env python3
"""Generate the public GoldenPath evidence status page from repository evidence."""

from __future__ import annotations

import argparse
import html
import json
from pathlib import Path

SCHEMA_VERSION = "goldenpath.public-status/v1"
SCOPE = "repository/reference"
ALLOWED_STATUS = {"implemented", "reference"}
BOUNDARY_STATUS = "not-claimed"


def fail(message: str) -> None:
    raise ValueError(message)


def validate_evidence_path(root: Path, raw_path: str) -> Path:
    path = Path(raw_path)
    if path.is_absolute() or ".." in path.parts:
        fail(f"evidence path must stay inside the repository: {raw_path}")
    resolved = (root / path).resolve()
    try:
        resolved.relative_to(root.resolve())
    except ValueError as exc:
        raise ValueError(f"evidence path escapes repository: {raw_path}") from exc
    if not resolved.exists():
        fail(f"declared repository evidence is missing: {raw_path}")
    return resolved


def load_status(root: Path, manifest_path: Path) -> dict:
    data = json.loads(manifest_path.read_text(encoding="utf-8"))

    if data.get("schema_version") != SCHEMA_VERSION:
        fail(f"schema_version must be {SCHEMA_VERSION!r}")
    if data.get("scope") != SCOPE:
        fail(f"scope must be {SCOPE!r}")

    boundaries = data.get("boundaries")
    if not isinstance(boundaries, dict):
        fail("boundaries must be an object")
    for boundary in ("runtime", "production"):
        if boundaries.get(boundary) != BOUNDARY_STATUS:
            fail(f"{boundary} boundary must remain {BOUNDARY_STATUS!r}")

    capabilities = data.get("capabilities")
    if not isinstance(capabilities, list) or not capabilities:
        fail("capabilities must be a non-empty array")

    seen_ids: set[str] = set()
    for capability in capabilities:
        if not isinstance(capability, dict):
            fail("each capability must be an object")
        capability_id = capability.get("id")
        label = capability.get("label")
        status = capability.get("status")
        evidence = capability.get("evidence")

        if not isinstance(capability_id, str) or not capability_id:
            fail("each capability requires a non-empty id")
        if capability_id in seen_ids:
            fail(f"duplicate capability id: {capability_id}")
        seen_ids.add(capability_id)

        if not isinstance(label, str) or not label:
            fail(f"capability {capability_id!r} requires a non-empty label")
        if status not in ALLOWED_STATUS:
            fail(
                f"capability {capability_id!r} status must be one of "
                f"{sorted(ALLOWED_STATUS)}"
            )
        if not isinstance(evidence, list) or not evidence:
            fail(f"capability {capability_id!r} requires repository evidence")

        for evidence_path in evidence:
            if not isinstance(evidence_path, str) or not evidence_path:
                fail(f"capability {capability_id!r} has an invalid evidence path")
            validate_evidence_path(root, evidence_path)

    return data


def repository_url(path: str) -> str:
    return f"https://github.com/lloga29/goldenPath/blob/main/{path}"


def render(data: dict) -> str:
    cards: list[str] = []
    for capability in data["capabilities"]:
        evidence_links = "\n".join(
            f'                <li><a href="{html.escape(repository_url(path), quote=True)}">'
            f"<code>{html.escape(path)}</code></a></li>"
            for path in capability["evidence"]
        )
        status_label = (
            "Implemented repository evidence"
            if capability["status"] == "implemented"
            else "Reference repository evidence"
        )
        cards.append(
            f"""          <article class="feature-card">
            <span class="feature-index">{html.escape(status_label)}</span>
            <h3>{html.escape(capability["label"])}</h3>
            <ul class="evidence-links">
{evidence_links}
            </ul>
          </article>"""
        )

    cards_html = "\n".join(cards)
    return f"""<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>GoldenPath Evidence Status</title>
  <meta name="description" content="Generated GoldenPath repository/reference evidence status with explicit runtime and production boundaries.">
  <meta name="robots" content="index,follow">
  <link rel="canonical" href="https://lloga29.github.io/goldenPath/evidence.html">
  <link rel="icon" href="assets/favicon.svg" type="image/svg+xml">
  <link rel="stylesheet" href="styles.css">
</head>
<body>
  <a class="skip-link" href="#main">Skip to content</a>
  <header class="site-header">
    <div class="container nav">
      <a class="brand" href="index.html" aria-label="GoldenPath home">
        <img src="assets/goldenpath-logo.png" alt="GoldenPath" width="1448" height="1086">
      </a>
      <a class="button button-small" href="index.html">Back to GoldenPath</a>
    </div>
  </header>

  <main id="main">
    <section class="hero">
      <div class="container">
        <div class="eyebrow-row">
          <span class="eyebrow">Generated evidence dashboard</span>
        </div>
        <h1>{html.escape(data["title"])}</h1>
        <p class="lead">{html.escape(data["description"])}</p>
        <div class="signal-row">
          <span>Scope: Repository / reference</span>
          <span>Runtime: Not claimed</span>
          <span>Production: Not claimed</span>
        </div>
      </div>
    </section>

    <section class="section section-tight">
      <div class="container">
        <div class="section-heading">
          <p class="kicker">Verifiable repository evidence</p>
          <h2>Every listed capability resolves to repository-owned evidence.</h2>
        </div>
        <div class="feature-grid status-grid">
{cards_html}
        </div>
      </div>
    </section>

    <section class="section evidence-section">
      <div class="container">
        <div class="evidence-panel">
          <div>
            <p class="kicker">Evidence boundary</p>
            <h2>Repository evidence is intentionally not promoted into a runtime claim.</h2>
          </div>
          <div class="evidence-flow" aria-label="Evidence levels">
            <div><strong>Repository / reference</strong><span>Generated from paths validated during the site build</span></div>
            <span class="arrow" aria-hidden="true">→</span>
            <div><strong>Runtime</strong><span>Not claimed by this dashboard</span></div>
            <span class="arrow" aria-hidden="true">→</span>
            <div><strong>Production validation</strong><span>Not claimed by this dashboard</span></div>
          </div>
          <p class="boundary-note">The generator fails closed when declared repository evidence is missing or when the manifest attempts to claim runtime or production validation.</p>
        </div>
      </div>
    </section>
  </main>

  <footer>
    <div class="container footer-grid">
      <div>
        <strong>GoldenPath</strong>
        <p>Generated from <code>platform-assurance/evidence/public-status.json</code>.</p>
      </div>
      <div class="footer-links">
        <a href="https://github.com/lloga29/goldenPath/blob/main/platform-assurance/evidence/public-status.json">Status manifest</a>
        <a href="https://github.com/lloga29/goldenPath/blob/main/scripts/generate-evidence-dashboard.py">Generator</a>
      </div>
    </div>
  </footer>
</body>
</html>
"""


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("manifest", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()

    root = Path(__file__).resolve().parent.parent
    manifest = args.manifest.resolve()
    output = args.output.resolve()

    data = load_status(root, manifest)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(render(data), encoding="utf-8")
    print(
        f"PASS: generated repository/reference evidence dashboard with "
        f"{len(data['capabilities'])} verified capability entries"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        print(f"ERROR: {exc}")
        raise SystemExit(1)
