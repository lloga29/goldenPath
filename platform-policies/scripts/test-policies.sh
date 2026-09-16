#!/usr/bin/env bash
# Run positive and negative Conftest fixtures for the policy bundle.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

command -v conftest >/dev/null 2>&1 || {
    echo "ERROR: conftest is required." >&2
    exit 1
}

CONFTST_ARGS=(--all-namespaces)

conftest test "$ROOT_DIR/tests/kubernetes/valid-deployment.yaml" --policy "$ROOT_DIR/kubernetes" "${CONFTST_ARGS[@]}"
conftest test "$ROOT_DIR/tests/terraform/valid-plan.json" --policy "$ROOT_DIR/terraform" "${CONFTST_ARGS[@]}"

if conftest test "$ROOT_DIR/tests/kubernetes/invalid-deployment.yaml" --policy "$ROOT_DIR/kubernetes" "${CONFTST_ARGS[@]}"; then
    echo "ERROR: invalid Kubernetes fixture unexpectedly passed policy evaluation." >&2
    exit 1
fi

if conftest test "$ROOT_DIR/tests/terraform/invalid-plan.json" --policy "$ROOT_DIR/terraform" "${CONFTST_ARGS[@]}"; then
    echo "ERROR: invalid Terraform fixture unexpectedly passed policy evaluation." >&2
    exit 1
fi

echo "Policy fixtures passed."
