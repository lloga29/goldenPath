#!/usr/bin/env python3
"""Validate the generated GoldenPath static Pages artifact using only the standard library."""

from __future__ import annotations

import sys
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import urlparse

REQUIRED_TEXT = (
    "From source code to",
    "v0.2.0 runtime assurance baseline",
    "GoldenPath in 60 seconds",
    "End-to-end showcase",
    "Technical insights",
    "Inspect the contracts, not just the claims.",
    "Signed runtime receipts",
    "Repository / reference",
    "Runtime",
    "Production validation",
    "Green is not the same as proven in production.",
    "Supported ephemeral lab",
)


class SiteParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.references: list[tuple[str, str]] = []
        self.scripts = 0
        self.text_parts: list[str] = []
        self.metadata: dict[str, str] = {}
        self.canonical: str | None = None

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        attributes = {key: value for key, value in attrs if value is not None}
        if tag == "script":
            self.scripts += 1
        if tag == "img" and "src" in attributes:
            self.references.append(("asset", attributes["src"]))
        if tag == "link" and "href" in attributes:
            rel = set(attributes.get("rel", "").split())
            if "stylesheet" in rel or "icon" in rel:
                self.references.append(("asset", attributes["href"]))
            elif "canonical" in rel:
                self.canonical = attributes["href"]
                self.references.append(("link", attributes["href"]))
        if tag == "meta" and "content" in attributes:
            key = attributes.get("property") or attributes.get("name")
            if key:
                self.metadata[key] = attributes["content"]
        if tag == "a" and "href" in attributes:
            self.references.append(("link", attributes["href"]))

    def handle_data(self, data: str) -> None:
        self.text_parts.append(data)


def validate_reference(root: Path, kind: str, reference: str) -> list[str]:
    errors: list[str] = []
    if reference.startswith("#"):
        return errors

    parsed = urlparse(reference)
    if parsed.scheme:
        if parsed.scheme != "https":
            errors.append(f"{kind} reference must use HTTPS: {reference}")
        return errors

    if reference.startswith("//"):
        errors.append(f"protocol-relative references are not allowed: {reference}")
        return errors

    local_path = root / parsed.path
    if not local_path.is_file():
        errors.append(f"missing local {kind}: {reference}")
    return errors


def main() -> int:
    if len(sys.argv) != 2:
        print("Usage: validate-pages-site.py <built-site-directory>", file=sys.stderr)
        return 2

    root = Path(sys.argv[1]).resolve()
    index = root / "index.html"
    dashboard = root / "evidence.html"
    stylesheet = root / "styles.css"

    errors: list[str] = []
    if not index.is_file():
        errors.append("index.html is missing")
    if not dashboard.is_file():
        errors.append("evidence.html is missing")
    if not stylesheet.is_file():
        errors.append("styles.css is missing")
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1

    parser = SiteParser()
    parser.feed(index.read_text(encoding="utf-8"))

    if parser.scripts:
        errors.append("site must remain JavaScript-free by default; script tags are not allowed")

    rendered_text = " ".join(" ".join(parser.text_parts).split())
    for required in REQUIRED_TEXT:
        if required not in rendered_text:
            errors.append(f"required public message is missing: {required!r}")

    expected_site_url = "https://lloga29.github.io/goldenPath/"
    if parser.canonical != expected_site_url:
        errors.append(f"canonical URL must be {expected_site_url}")

    seo_description = "GoldenPath is an evidence-backed Kubernetes platform engineering reference for Internal Developer Platforms, R0-R4 assurance, fail-closed evidence, GitOps, Terraform, policy as code, SBOM, SLSA, and Cosign."
    required_metadata = {
        "description": seo_description,
        "og:title": "GoldenPath — Evidence-backed platform engineering",
        "og:description": seo_description,
        "og:url": expected_site_url,
        "og:image": "https://lloga29.github.io/goldenPath/assets/goldenpath-logo.png",
        "twitter:card": "summary_large_image",
        "twitter:description": seo_description,
    }
    for key, expected in required_metadata.items():
        if parser.metadata.get(key) != expected:
            errors.append(f"required metadata {key!r} must be {expected!r}")

    for kind, reference in parser.references:
        errors.extend(validate_reference(root, kind, reference))

    dashboard_parser = SiteParser()
    dashboard_parser.feed(dashboard.read_text(encoding="utf-8"))
    if dashboard_parser.scripts:
        errors.append("evidence dashboard must remain JavaScript-free")

    dashboard_text = " ".join(" ".join(dashboard_parser.text_parts).split())
    dashboard_required_text = (
        "Generated evidence dashboard",
        "Scope: Repository / reference + supported runtime",
        "Runtime: Verified for v0.2.0 candidate",
        "Production: Not claimed",
        "Every listed capability resolves to repository-owned contracts.",
        "Exact runtime qualification",
        "Production validation remains separate",
    )
    for required in dashboard_required_text:
        if required not in dashboard_text:
            errors.append(f"required evidence dashboard message is missing: {required!r}")

    if dashboard_parser.canonical != "https://lloga29.github.io/goldenPath/evidence.html":
        errors.append("evidence dashboard canonical URL is invalid")

    for kind, reference in dashboard_parser.references:
        errors.extend(validate_reference(root, kind, reference))

    required_assets = (
        root / "assets" / "goldenpath-logo.png",
        root / "assets" / "goldenpath-architecture.svg",
        root / "assets" / "favicon.svg",
    )
    for asset in required_assets:
        if not asset.is_file() or asset.stat().st_size == 0:
            errors.append(f"required branding asset is missing or empty: {asset.name}")

    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1

    print(
        f"PASS: static Pages artifact validated with {len(parser.references)} "
        "links/assets and explicit evidence boundaries"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
