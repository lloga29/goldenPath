#!/usr/bin/env bash
# Build the repository-owned static GitHub Pages artifact.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

OUTPUT_DIR="${1:-.pages-site}"

case "$OUTPUT_DIR" in
  ""|"/"|"."|"..")
    echo "ERROR: unsafe Pages output directory: '$OUTPUT_DIR'" >&2
    exit 1
    ;;
esac

rm -rf -- "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR/assets"

cp site/index.html "$OUTPUT_DIR/index.html"
cp site/styles.css "$OUTPUT_DIR/styles.css"
cp docs/assets/branding/goldenpath-logo.png "$OUTPUT_DIR/assets/goldenpath-logo.png"
cp docs/assets/branding/goldenpath-architecture.svg "$OUTPUT_DIR/assets/goldenpath-architecture.svg"
cp docs/assets/branding/goldenpath-favicon.svg "$OUTPUT_DIR/assets/favicon.svg"

python3 scripts/validate-pages-site.py "$OUTPUT_DIR"

echo "Pages site built and validated at $OUTPUT_DIR"
