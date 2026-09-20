#!/usr/bin/env python3
"""Generate the public GoldenPath evidence status page with explicit claim boundaries."""
from __future__ import annotations

import argparse
import html
import json
import re
from pathlib import Path

SCHEMA_VERSION = "goldenpath.public-status/v2"
SCOPE = "repository/reference + supported-runtime"
ALLOWED_STATUS = {"implemented", "reference"}
RUNTIME_BOUNDARY = "verified-release-candidate"
PRODUCTION_BOUNDARY = "not-claimed"
SHA_RE = re.compile(r"^[0-9a-f]{40}$")


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
    if boundaries.get("runtime") != RUNTIME_BOUNDARY:
        fail(f"runtime boundary must remain {RUNTIME_BOUNDARY!r}")
    if boundaries.get("production") != PRODUCTION_BOUNDARY:
        fail(f"production boundary must remain {PRODUCTION_BOUNDARY!r}")

    runtime = data.get("runtime_release")
    if not isinstance(runtime, dict):
        fail("runtime_release must be an object")
    if runtime.get("status") != "VERIFIED":
        fail("runtime_release.status must be VERIFIED")
    if runtime.get("release") != "v0.2.0":
        fail("runtime_release.release must be v0.2.0")
    revision = runtime.get("source_revision")
    if not isinstance(revision, str) or not SHA_RE.fullmatch(revision):
        fail("runtime_release.source_revision must be an exact Git SHA")
    run_id = runtime.get("qualification_run_id")
    if not isinstance(run_id, int) or run_id < 1:
        fail("runtime_release.qualification_run_id must be a positive integer")
    artifact = runtime.get("qualification_artifact")
    if not isinstance(artifact, str) or not artifact:
        fail("runtime_release.qualification_artifact must be non-empty")

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
            fail(f"capability {capability_id!r} status must be one of {sorted(ALLOWED_STATUS)}")
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
        links = "\n".join(
            f'                <li><a href="{html.escape(repository_url(path), quote=True)}">'
            f"<code>{html.escape(path)}</code></a></li>"
            for path in capability["evidence"]
        )
        label = "Implemented repository contract" if capability["status"] == "implemented" else "Reference repository contract"
        cards.append(f"""          <article class="feature-card">
            <span class="feature-index">{html.escape(label)}</span>
            <h3>{html.escape(capability["label"])}</h3>
            <ul class="evidence-links">
{links}
            </ul>
          </article>""")

    runtime = data["runtime_release"]
    run_url = f"https://github.com/lloga29/goldenPath/actions/runs/{runtime['qualification_run_id']}"
    return f"""<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>GoldenPath Evidence Status</title>
  <meta name="description" content="GoldenPath repository/reference contracts plus exact v0.2.0 supported-runtime qualification; production validation remains separate.">
  <meta name="robots" content="index,follow">
  <link rel="canonical" href="https://lloga29.github.io/goldenPath/evidence.html">
  <link rel="icon" href="assets/favicon.svg" type="image/svg+xml">
  <link rel="stylesheet" href="styles.css">
</head>
<body>
  <a class="skip-link" href="#main">Skip to content</a>
  <header class="site-header"><div class="container nav">
    <a class="brand" href="index.html" aria-label="GoldenPath home"><img src="assets/goldenpath-logo.png" alt="GoldenPath" width="1448" height="1086"></a>
    <a class="button button-small" href="index.html">Back to GoldenPath</a>
  </div></header>

  <main id="main">
    <section class="hero"><div class="container">
      <div class="eyebrow-row"><span class="eyebrow">Generated evidence dashboard</span></div>
      <h1>{html.escape(data["title"])}</h1>
      <p class="lead">{html.escape(data["description"])}</p>
      <div class="signal-row">
        <span>Scope: Repository / reference + supported runtime</span>
        <span>Runtime: Verified for v0.2.0 candidate</span>
        <span>Production: Not claimed</span>
      </div>
    </div></section>

    <section class="section section-tight"><div class="container">
      <div class="section-heading">
        <p class="kicker">Verifiable contracts</p>
        <h2>Every listed capability resolves to repository-owned contracts.</h2>
      </div>
      <div class="feature-grid status-grid">
{chr(10).join(cards)}
      </div>
    </div></section>

    <section class="section evidence-section"><div class="container"><div class="evidence-panel">
      <div>
        <p class="kicker">Exact runtime qualification</p>
        <h2>v0.2.0 binds runtime proof to one exact release candidate.</h2>
      </div>
      <div class="evidence-flow" aria-label="Evidence levels">
        <div><strong>Repository / reference</strong><span>Contracts, schemas, policy, CI, and release documentation</span></div>
        <span class="arrow" aria-hidden="true">→</span>
        <div><strong>Supported runtime</strong><span>Runtime Lab, signed receipt, independent verification, and current-state assurance</span></div>
        <span class="arrow" aria-hidden="true">→</span>
        <div><strong>Production validation</strong><span>Not claimed by v0.2.0</span></div>
      </div>
      <p class="boundary-note">Qualified source: <code>{html.escape(runtime["source_revision"])}</code>. Runtime Lab: <a href="{html.escape(run_url, quote=True)}">run #{runtime["qualification_run_id"]}</a>. Evidence bundle: <code>{html.escape(runtime["qualification_artifact"])}</code>. Production validation remains separate and is not claimed.</p>
    </div></div></section>
  </main>

  <footer><div class="container footer-grid">
    <div><strong>GoldenPath</strong><p>Generated from <code>platform-assurance/evidence/public-status.json</code>.</p></div>
    <div class="footer-links">
      <a href="https://github.com/lloga29/goldenPath/blob/main/platform-assurance/evidence/public-status.json">Status manifest</a>
      <a href="{html.escape(run_url, quote=True)}">Qualification run</a>
    </div>
  </div></footer>
</body>
</html>
"""


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("manifest", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    root = Path(__file__).resolve().parent.parent
    data = load_status(root, args.manifest.resolve())
    args.output.resolve().parent.mkdir(parents=True, exist_ok=True)
    args.output.resolve().write_text(render(data), encoding="utf-8")
    print(f"PASS: generated repository/reference + runtime evidence dashboard with {len(data['capabilities'])} verified contract entries")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        print(f"ERROR: {exc}")
        raise SystemExit(1)
