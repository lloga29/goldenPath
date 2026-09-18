#!/usr/bin/env python3
"""Validate the generated GoldenPath static Pages artifact using only the standard library."""

from __future__ import annotations

import sys
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import urlparse

REQUIRED_TEXT = (
    "From source code to",
    "v0.1.0 public baseline",
    "GoldenPath in 60 seconds",
    "Repository / reference",
    "Runtime",
    "Production validation",
    "Green is not the same as proven in production.",
)


class SiteParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.references: list[tuple[str, str]] = []
        self.scripts = 0
        self.text_parts: list[str] = []

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        attributes = {key: value for key, value in attrs if value is not None}
        if tag == "script":
            self.scripts += 1
        if tag == "img" and "src" in attributes:
            self.references.append(("asset", attributes["src"]))
        if tag == "link" and attributes.get("rel") == "stylesheet" and "href" in attributes:
            self.references.append(("asset", attributes["href"]))
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
    stylesheet = root / "styles.css"

    errors: list[str] = []
    if not index.is_file():
        errors.append("index.html is missing")
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

    for kind, reference in parser.references:
        errors.extend(validate_reference(root, kind, reference))

    required_assets = (
        root / "assets" / "goldenpath-logo.png",
        root / "assets" / "goldenpath-architecture.svg",
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
