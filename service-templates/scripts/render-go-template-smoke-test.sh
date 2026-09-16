#!/usr/bin/env bash
# Render, compile, container-build, and validate the Go paved-road template using representative answers.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE_DIR="$ROOT_DIR/templates/microservice-golang"
OUTPUT_DIR="$(mktemp -d)"
PROJECT_NAME="golden-smoke"
GENERATED_DIR="$OUTPUT_DIR/$PROJECT_NAME"
BUILD_OUTPUT="$OUTPUT_DIR/${PROJECT_NAME}-binary"
SMOKE_PORT=18080
CONTAINER_IMAGE="local/${PROJECT_NAME}:smoke"

cleanup() {
    docker image rm --force "$CONTAINER_IMAGE" >/dev/null 2>&1 || true
    rm -rf "$OUTPUT_DIR"
}
trap cleanup EXIT

for command in copier go docker make; do
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
    --data port="$SMOKE_PORT" \
    --data owner_email=platform@example.com \
    --data go_version=1.26 \
    "$TEMPLATE_DIR" "$OUTPUT_DIR"

if [[ ! -f "$GENERATED_DIR/go.mod" ]]; then
    echo "ERROR: Copier did not render the expected Go module at $GENERATED_DIR." >&2
    find "$OUTPUT_DIR" -maxdepth 3 -type f -print >&2
    exit 1
fi

if grep -R -nE '\{\{[[:space:]]*(project_name|github_owner|team|description|port|owner_email|go_version)([[:space:]]|\||\}\})' "$GENERATED_DIR"; then
    echo "ERROR: generated service still contains unresolved Copier placeholders." >&2
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
go build -o "$BUILD_OUTPUT" ./cmd

if [[ ! -x "$BUILD_OUTPUT" ]]; then
    echo "ERROR: generated Go service did not produce an executable binary." >&2
    exit 1
fi

CI_WORKFLOW=".github/workflows/ci.yaml"
if grep -Eq 'ghcr\.io/[^[:space:]]+:latest' "$CI_WORKFLOW"; then
    echo "ERROR: generated CI contains a mutable :latest publication tag." >&2
    exit 1
fi

for required_ci_contract in \
    'sbom: true' \
    'steps.build.outputs.digest' \
    'IMAGE_REF="${IMAGE_NAME}@${DIGEST}"' \
    'docker buildx imagetools inspect "$IMAGE_REF"' \
    '{{ json .SBOM.SPDX }}' \
    'SPDXRef-DOCUMENT' \
    'published SBOM contains no package inventory'; do
    if ! grep -F "$required_ci_contract" "$CI_WORKFLOW" >/dev/null; then
        echo "ERROR: generated CI is missing required release-SBOM contract: $required_ci_contract" >&2
        exit 1
    fi
done

mapfile -t base_images < <(grep -E '^FROM[[:space:]]+' Dockerfile)
if [[ "${#base_images[@]}" -eq 0 ]]; then
    echo "ERROR: generated Dockerfile does not contain any FROM instructions." >&2
    exit 1
fi

for base_image in "${base_images[@]}"; do
    if [[ ! "$base_image" =~ @sha256:[0-9a-f]{64}([[:space:]]|$) ]]; then
        echo "ERROR: generated Dockerfile contains a base image that is not digest-pinned: $base_image" >&2
        exit 1
    fi
done

if grep -q 'gcr.io/distroless/.*-debian12' Dockerfile; then
    echo "ERROR: generated Dockerfile references deprecated Distroless Debian 12." >&2
    exit 1
fi

if ! grep -Eq '^FROM[[:space:]]+gcr\.io/distroless/static-debian13:nonroot@sha256:[0-9a-f]{64}([[:space:]]|$)' Dockerfile; then
    echo "ERROR: generated Dockerfile must use a digest-pinned Distroless Debian 13 nonroot runtime." >&2
    exit 1
fi

make docker-build REGISTRY=local VERSION=smoke

exposed_ports="$(docker image inspect "$CONTAINER_IMAGE" --format '{{json .Config.ExposedPorts}}')"
if [[ "$exposed_ports" != *"\"${SMOKE_PORT}/tcp\""* ]]; then
    echo "ERROR: generated container does not expose the selected service port ${SMOKE_PORT}." >&2
    exit 1
fi

image_source="$(docker image inspect "$CONTAINER_IMAGE" --format '{{ index .Config.Labels "org.opencontainers.image.source" }}')"
if [[ "$image_source" != "https://github.com/example/${PROJECT_NAME}" ]]; then
    echo "ERROR: generated container has unexpected OCI source label: $image_source" >&2
    exit 1
fi

echo "Go template smoke test passed."
