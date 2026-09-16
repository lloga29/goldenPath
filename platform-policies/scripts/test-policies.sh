#!/usr/bin/env bash
# Run positive/negative policy fixtures and fail-closed exception-contract tests.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VALIDATOR="$ROOT_DIR/scripts/validate-exceptions.py"
LIB_DIR="$ROOT_DIR/lib"
WRAPPER_DIR="$ROOT_DIR/wrappers"

command -v conftest >/dev/null 2>&1 || {
    echo "ERROR: conftest is required." >&2
    exit 1
}

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

compile_registry() {
    local registry="$1"
    local output="$2"
    python3 "$VALIDATOR" "$registry" --output "$output"
}

expect_validation_failure() {
    local registry="$1"
    if python3 "$VALIDATOR" "$registry" >/dev/null 2>&1; then
        echo "ERROR: invalid exception fixture unexpectedly passed: $registry" >&2
        exit 1
    fi
}

expect_policy_failure() {
    local input="$1"
    local policy_dir="$2"
    local data_file="$3"
    local namespace="$4"
    if conftest test "$input" \
        --policy "$policy_dir" \
        --policy "$LIB_DIR" \
        --policy "$WRAPPER_DIR" \
        --data "$data_file" \
        --namespace "$namespace"; then
        echo "ERROR: invalid fixture unexpectedly passed policy evaluation: $input" >&2
        exit 1
    fi
}

BASELINE_DATA="$TMP_DIR/baseline-exceptions.json"
compile_registry "$ROOT_DIR/policy-exceptions.yaml" "$BASELINE_DATA"

# Baseline paved-road fixtures must pass with the validated real registry loaded.
conftest test "$ROOT_DIR/tests/kubernetes/valid-deployment.yaml" \
    --policy "$ROOT_DIR/kubernetes" \
    --policy "$LIB_DIR" \
    --policy "$WRAPPER_DIR" \
    --data "$BASELINE_DATA" \
    --namespace goldenpath.kubernetes
conftest test "$ROOT_DIR/tests/terraform/valid-plan.json" \
    --policy "$ROOT_DIR/terraform" \
    --policy "$LIB_DIR" \
    --policy "$WRAPPER_DIR" \
    --data "$BASELINE_DATA" \
    --namespace goldenpath.terraform

# Existing negative fixtures must remain blocked when no exception exists.
expect_policy_failure "$ROOT_DIR/tests/kubernetes/invalid-deployment.yaml" "$ROOT_DIR/kubernetes" "$BASELINE_DATA" goldenpath.kubernetes
expect_policy_failure "$ROOT_DIR/tests/terraform/invalid-plan.json" "$ROOT_DIR/terraform" "$BASELINE_DATA" goldenpath.terraform

# Kubernetes: exact policy + kind/name + namespace may suppress only that policy.
KUBE_EXCEPTION_DATA="$TMP_DIR/kubernetes-image-exception.json"
compile_registry "$ROOT_DIR/tests/exceptions/kubernetes-image.yaml" "$KUBE_EXCEPTION_DATA"
KUBE_OUTPUT="$(conftest test "$ROOT_DIR/tests/kubernetes/exception-image-deployment.yaml" \
    --policy "$ROOT_DIR/kubernetes" \
    --policy "$LIB_DIR" \
    --policy "$WRAPPER_DIR" \
    --data "$KUBE_EXCEPTION_DATA" \
    --namespace goldenpath.kubernetes 2>&1)"
printf '%s\n' "$KUBE_OUTPUT"
grep -F "EXC-2026-901" <<<"$KUBE_OUTPUT" >/dev/null || {
    echo "ERROR: Kubernetes exception bypass did not emit its audit-visible exception ID." >&2
    exit 1
}

# A valid exception for a different resource must not suppress the violation.
KUBE_WRONG_SCOPE_DATA="$TMP_DIR/kubernetes-wrong-scope.json"
compile_registry "$ROOT_DIR/tests/exceptions/kubernetes-wrong-resource.yaml" "$KUBE_WRONG_SCOPE_DATA"
expect_policy_failure "$ROOT_DIR/tests/kubernetes/exception-image-deployment.yaml" "$ROOT_DIR/kubernetes" "$KUBE_WRONG_SCOPE_DATA" goldenpath.kubernetes

# A valid exception for the same resource but a different policy ID must not suppress the violation.
KUBE_WRONG_POLICY_DATA="$TMP_DIR/kubernetes-wrong-policy.json"
compile_registry "$ROOT_DIR/tests/exceptions/kubernetes-wrong-policy.yaml" "$KUBE_WRONG_POLICY_DATA"
expect_policy_failure "$ROOT_DIR/tests/kubernetes/exception-image-deployment.yaml" "$ROOT_DIR/kubernetes" "$KUBE_WRONG_POLICY_DATA" goldenpath.kubernetes

# Terraform: exact policy + exact resource address may suppress only that policy.
TF_EXCEPTION_DATA="$TMP_DIR/terraform-public-access-exception.json"
compile_registry "$ROOT_DIR/tests/exceptions/terraform-public-access.yaml" "$TF_EXCEPTION_DATA"
TF_OUTPUT="$(conftest test "$ROOT_DIR/tests/terraform/exception-public-access-plan.json" \
    --policy "$ROOT_DIR/terraform" \
    --policy "$LIB_DIR" \
    --policy "$WRAPPER_DIR" \
    --data "$TF_EXCEPTION_DATA" \
    --namespace goldenpath.terraform 2>&1)"
printf '%s\n' "$TF_OUTPUT"
grep -F "EXC-2026-903" <<<"$TF_OUTPUT" >/dev/null || {
    echo "ERROR: Terraform exception bypass did not emit its audit-visible exception ID." >&2
    exit 1
}

# A valid Terraform exception for a different policy ID must not suppress public-access enforcement.
TF_WRONG_POLICY_DATA="$TMP_DIR/terraform-wrong-policy.json"
compile_registry "$ROOT_DIR/tests/exceptions/terraform-wrong-policy.yaml" "$TF_WRONG_POLICY_DATA"
expect_policy_failure "$ROOT_DIR/tests/terraform/exception-public-access-plan.json" "$ROOT_DIR/terraform" "$TF_WRONG_POLICY_DATA" goldenpath.terraform

# Registry validation fails closed for expired, global, or admission-bypass attempts.
expect_validation_failure "$ROOT_DIR/tests/exceptions/expired.yaml"
expect_validation_failure "$ROOT_DIR/tests/exceptions/global-bypass.yaml"
expect_validation_failure "$ROOT_DIR/tests/exceptions/gatekeeper-bypass.yaml"

echo "Policy fixtures and scoped exception contract passed under Rego v1."
