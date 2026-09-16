#!/usr/bin/env bash
# Render and compile the Go paved-road template using representative answers.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE_DIR="$ROOT_DIR/templates/microservice-golang"
OUTPUT_DIR="$(mktemp -d)"
PROJECT_NAME="golden-smoke"
GENERATED_DIR="$OUTPUT_DIR/$PROJECT_NAME"
trap 'rm -rf "$OUTPUT_DIR"' EXIT

for command in copier go; do
    command -v "$command" >/dev/null 2>&1 || {
        echo "ERROR: $command is required for the template smoke test." >&2
        exit 1
    }
done

copier copy --trust --defaults \
    --data project_name="$PROJECT_NAME" \
    --data github_owner=example \
    --data team=platform \
    --data description="Golden Path smoke-test service" \
    --data port=8080 \
    --data owner_email=platform@example.com \
    --data go_version=1.26 \
    "$TEMPLATE_DIR" "$OUTPUT_DIR"

if [[ ! -f "$GENERATED_DIR/go.mod" ]]; then
    echo "ERROR: Copier did not render the expected Go module at $GENERATED_DIR." >&2
    find "$OUTPUT_DIR" -maxdepth 3 -type f -print >&2
    exit 1
fi

cd "$GENERATED_DIR"

go mod tidy

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
