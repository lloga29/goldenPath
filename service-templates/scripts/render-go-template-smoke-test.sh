#!/usr/bin/env bash
# Render and compile the Go paved-road template using representative answers.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE_DIR="$ROOT_DIR/templates/microservice-golang"
OUTPUT_DIR="$(mktemp -d)"
trap 'rm -rf "$OUTPUT_DIR"' EXIT

for command in copier go; do
    command -v "$command" >/dev/null 2>&1 || {
        echo "ERROR: $command is required for the template smoke test." >&2
        exit 1
    }
done

copier copy --trust --defaults \
    --data project_name=golden-smoke \
    --data github_owner=example \
    --data team=platform \
    --data description="Golden Path smoke-test service" \
    --data port=8080 \
    --data owner_email=platform@example.com \
    --data go_version=1.26 \
    "$TEMPLATE_DIR" "$OUTPUT_DIR"

cd "$OUTPUT_DIR"

go mod tidy
git diff --no-index --exit-code /dev/null /dev/null >/dev/null 2>&1 || true

unformatted="$(gofmt -l .)"
if [[ -n "$unformatted" ]]; then
    echo "ERROR: generated Go files require formatting:" >&2
    echo "$unformatted" >&2
    exit 1
fi

go vet ./...
go test ./...
go build ./cmd

if grep -Eq 'ghcr\.io/[^[:space:]]+:latest' .github/workflows/ci.yaml; then
    echo "ERROR: generated CI contains a mutable :latest publication tag." >&2
    exit 1
fi

echo "Go template smoke test passed."
