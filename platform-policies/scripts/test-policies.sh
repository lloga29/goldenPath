#!/usr/bin/env bash
# Run positive/negative policy fixtures, policy-ID isolation, multi-provider parity, and fail-closed exception-contract tests.

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

run_policy() {
    local input="$1"
    local policy_dir="$2"
    local data_file="$3"
    local namespace="$4"
    conftest test "$input" \
        --policy "$policy_dir" \
        --policy "$LIB_DIR" \
        --policy "$WRAPPER_DIR" \
        --data "$data_file" \
        --namespace "$namespace"
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
    if run_policy "$input" "$policy_dir" "$data_file" "$namespace"; then
        echo "ERROR: invalid fixture unexpectedly passed policy evaluation: $input" >&2
        exit 1
    fi
}

expect_policy_failure_with_message() {
    local input="$1"
    local policy_dir="$2"
    local data_file="$3"
    local namespace="$4"
    local expected_message="$5"
    local output
    local status

    set +e
    output="$(run_policy "$input" "$policy_dir" "$data_file" "$namespace" 2>&1)"
    status=$?
    set -e

    printf '%s\n' "$output"
    if [[ "$status" -eq 0 ]]; then
        echo "ERROR: dedicated negative fixture unexpectedly passed policy evaluation: $input" >&2
        exit 1
    fi
    if ! grep -F "$expected_message" <<<"$output" >/dev/null; then
        echo "ERROR: dedicated negative fixture failed without the expected target-policy denial: $input" >&2
        echo "ERROR: expected message fragment: $expected_message" >&2
        exit 1
    fi
}

BASELINE_DATA="$TMP_DIR/baseline-exceptions.json"
compile_registry "$ROOT_DIR/policy-exceptions.yaml" "$BASELINE_DATA"

# Baseline paved-road fixtures must pass with the validated real registry loaded.
run_policy "$ROOT_DIR/tests/kubernetes/valid-deployment.yaml" "$ROOT_DIR/kubernetes" "$BASELINE_DATA" goldenpath.kubernetes

for fixture in \
    "$ROOT_DIR/tests/terraform/valid-plan.json" \
    "$ROOT_DIR/tests/terraform/azure-valid-plan.json" \
    "$ROOT_DIR/tests/terraform/gcp-valid-plan.json"; do
    run_policy "$fixture" "$ROOT_DIR/terraform" "$BASELINE_DATA" goldenpath.terraform
done

# Existing and provider-specific negative fixtures must remain blocked when no exception exists.
expect_policy_failure "$ROOT_DIR/tests/kubernetes/invalid-deployment.yaml" "$ROOT_DIR/kubernetes" "$BASELINE_DATA" goldenpath.kubernetes
for fixture in \
    "$ROOT_DIR/tests/terraform/invalid-plan.json" \
    "$ROOT_DIR/tests/terraform/azure-invalid-plan.json" \
    "$ROOT_DIR/tests/terraform/gcp-invalid-plan.json"; do
    expect_policy_failure "$fixture" "$ROOT_DIR/terraform" "$BASELINE_DATA" goldenpath.terraform
done

# Every blocking wrapper policy ID has an otherwise paved-road negative fixture.
# The target denial text must be present so an unrelated policy failure cannot satisfy the case.
expect_policy_failure_with_message \
    "$ROOT_DIR/tests/kubernetes/policy-id/image-immutable.yaml" \
    "$ROOT_DIR/kubernetes" "$BASELINE_DATA" goldenpath.kubernetes \
    "must use an explicit immutable tag or SHA-256 digest"
expect_policy_failure_with_message \
    "$ROOT_DIR/tests/kubernetes/policy-id/labels-required.yaml" \
    "$ROOT_DIR/kubernetes" "$BASELINE_DATA" goldenpath.kubernetes \
    "is missing required labels:"
expect_policy_failure_with_message \
    "$ROOT_DIR/tests/kubernetes/policy-id/resources-required.yaml" \
    "$ROOT_DIR/kubernetes" "$BASELINE_DATA" goldenpath.kubernetes \
    "must define resources.limits.cpu."
expect_policy_failure_with_message \
    "$ROOT_DIR/tests/kubernetes/policy-id/security-context.yaml" \
    "$ROOT_DIR/kubernetes" "$BASELINE_DATA" goldenpath.kubernetes \
    "must set allowPrivilegeEscalation=false."
expect_policy_failure_with_message \
    "$ROOT_DIR/tests/kubernetes/policy-id/workload-isolation.yaml" \
    "$ROOT_DIR/kubernetes" "$BASELINE_DATA" goldenpath.kubernetes \
    "must not use hostNetwork."

expect_policy_failure_with_message \
    "$ROOT_DIR/tests/terraform/policy-id/public-access-plan.json" \
    "$ROOT_DIR/terraform" "$BASELINE_DATA" goldenpath.terraform \
    "exposes a sensitive port range (22-22) to 0.0.0.0/0."
expect_policy_failure_with_message \
    "$ROOT_DIR/tests/terraform/policy-id/iam-no-wildcards-plan.json" \
    "$ROOT_DIR/terraform" "$BASELINE_DATA" goldenpath.terraform \
    "contains Allow Action '*'. Use explicit actions."
expect_policy_failure_with_message \
    "$ROOT_DIR/tests/terraform/policy-id/identity-least-privilege-plan.json" \
    "$ROOT_DIR/terraform" "$BASELINE_DATA" goldenpath.terraform \
    "must not grant AdministratorAccess."
expect_policy_failure_with_message \
    "$ROOT_DIR/tests/terraform/policy-id/encryption-required-plan.json" \
    "$ROOT_DIR/terraform" "$BASELINE_DATA" goldenpath.terraform \
    "must enable encryption."
expect_policy_failure_with_message \
    "$ROOT_DIR/tests/terraform/policy-id/tags-required-plan.json" \
    "$ROOT_DIR/terraform" "$BASELINE_DATA" goldenpath.terraform \
    "is missing required tags:"

# Kubernetes: exact policy + kind/name + namespace may suppress only that policy.
KUBE_EXCEPTION_DATA="$TMP_DIR/kubernetes-image-exception.json"
compile_registry "$ROOT_DIR/tests/exceptions/kubernetes-image.yaml" "$KUBE_EXCEPTION_DATA"
KUBE_OUTPUT="$(run_policy "$ROOT_DIR/tests/kubernetes/exception-image-deployment.yaml" "$ROOT_DIR/kubernetes" "$KUBE_EXCEPTION_DATA" goldenpath.kubernetes 2>&1)"
printf '%s\n' "$KUBE_OUTPUT"
grep -F "EXC-2026-901" <<<"$KUBE_OUTPUT" >/dev/null || {
    echo "ERROR: Kubernetes exception bypass did not emit its audit-visible exception ID." >&2
    exit 1
}

# The image exception must not suppress a second policy on the same exact resource.
expect_policy_failure "$ROOT_DIR/tests/kubernetes/exception-image-and-labels-deployment.yaml" "$ROOT_DIR/kubernetes" "$KUBE_EXCEPTION_DATA" goldenpath.kubernetes

# A valid exception for a different resource must not suppress the violation.
KUBE_WRONG_SCOPE_DATA="$TMP_DIR/kubernetes-wrong-scope.json"
compile_registry "$ROOT_DIR/tests/exceptions/kubernetes-wrong-resource.yaml" "$KUBE_WRONG_SCOPE_DATA"
expect_policy_failure "$ROOT_DIR/tests/kubernetes/exception-image-deployment.yaml" "$ROOT_DIR/kubernetes" "$KUBE_WRONG_SCOPE_DATA" goldenpath.kubernetes

# A valid exception for the same resource in another namespace must not suppress the violation.
KUBE_WRONG_NAMESPACE_DATA="$TMP_DIR/kubernetes-wrong-namespace.json"
compile_registry "$ROOT_DIR/tests/exceptions/kubernetes-wrong-namespace.yaml" "$KUBE_WRONG_NAMESPACE_DATA"
expect_policy_failure "$ROOT_DIR/tests/kubernetes/exception-image-deployment.yaml" "$ROOT_DIR/kubernetes" "$KUBE_WRONG_NAMESPACE_DATA" goldenpath.kubernetes

# A valid exception for the same resource but a different policy ID must not suppress the violation.
KUBE_WRONG_POLICY_DATA="$TMP_DIR/kubernetes-wrong-policy.json"
compile_registry "$ROOT_DIR/tests/exceptions/kubernetes-wrong-policy.yaml" "$KUBE_WRONG_POLICY_DATA"
expect_policy_failure "$ROOT_DIR/tests/kubernetes/exception-image-deployment.yaml" "$ROOT_DIR/kubernetes" "$KUBE_WRONG_POLICY_DATA" goldenpath.kubernetes

# Terraform: exact policy + exact resource address may suppress only that policy.
TF_EXCEPTION_DATA="$TMP_DIR/terraform-public-access-exception.json"
compile_registry "$ROOT_DIR/tests/exceptions/terraform-public-access.yaml" "$TF_EXCEPTION_DATA"
TF_OUTPUT="$(run_policy "$ROOT_DIR/tests/terraform/exception-public-access-plan.json" "$ROOT_DIR/terraform" "$TF_EXCEPTION_DATA" goldenpath.terraform 2>&1)"
printf '%s\n' "$TF_OUTPUT"
grep -F "EXC-2026-903" <<<"$TF_OUTPUT" >/dev/null || {
    echo "ERROR: Terraform exception bypass did not emit its audit-visible exception ID." >&2
    exit 1
}

# Exception filtering must preserve full plan context for companion-resource policies.
TF_COMPANION_EXCEPTION_DATA="$TMP_DIR/terraform-public-access-companion-exception.json"
compile_registry "$ROOT_DIR/tests/exceptions/terraform-public-access-companion.yaml" "$TF_COMPANION_EXCEPTION_DATA"
TF_COMPANION_OUTPUT="$(run_policy "$ROOT_DIR/tests/terraform/exception-public-access-companion-plan.json" "$ROOT_DIR/terraform" "$TF_COMPANION_EXCEPTION_DATA" goldenpath.terraform 2>&1)"
printf '%s\n' "$TF_COMPANION_OUTPUT"
grep -F "EXC-2026-911" <<<"$TF_COMPANION_OUTPUT" >/dev/null || {
    echo "ERROR: Terraform companion-resource exception did not emit its audit-visible exception ID." >&2
    exit 1
}

# Provider-native identity violations use their own semantic policy ID and exact address.
TF_IDENTITY_EXCEPTION_DATA="$TMP_DIR/terraform-identity-exception.json"
compile_registry "$ROOT_DIR/tests/exceptions/terraform-identity.yaml" "$TF_IDENTITY_EXCEPTION_DATA"
TF_IDENTITY_OUTPUT="$(run_policy "$ROOT_DIR/tests/terraform/identity-least-privilege-plan.json" "$ROOT_DIR/terraform" "$TF_IDENTITY_EXCEPTION_DATA" goldenpath.terraform 2>&1)"
printf '%s\n' "$TF_IDENTITY_OUTPUT"
grep -F "EXC-2026-915" <<<"$TF_IDENTITY_OUTPUT" >/dev/null || {
    echo "ERROR: Terraform identity exception did not emit its audit-visible exception ID." >&2
    exit 1
}

# A valid Terraform exception for a different policy ID must not suppress public-access enforcement.
TF_WRONG_POLICY_DATA="$TMP_DIR/terraform-wrong-policy.json"
compile_registry "$ROOT_DIR/tests/exceptions/terraform-wrong-policy.yaml" "$TF_WRONG_POLICY_DATA"
expect_policy_failure "$ROOT_DIR/tests/terraform/exception-public-access-plan.json" "$ROOT_DIR/terraform" "$TF_WRONG_POLICY_DATA" goldenpath.terraform

# Registry validation must reject every broad, malformed, expired, unknown, or admission-bypass shape.
expect_validation_failure "$ROOT_DIR/tests/exceptions/expired.yaml"
expect_validation_failure "$ROOT_DIR/tests/exceptions/global-bypass.yaml"
expect_validation_failure "$ROOT_DIR/tests/exceptions/gatekeeper-bypass.yaml"
expect_validation_failure "$ROOT_DIR/tests/exceptions/kubernetes-resource-wildcard.yaml"
expect_validation_failure "$ROOT_DIR/tests/exceptions/kubernetes-namespace-wildcard.yaml"
expect_validation_failure "$ROOT_DIR/tests/exceptions/unknown-policy.yaml"
expect_validation_failure "$ROOT_DIR/tests/exceptions/malformed-missing-owner.yaml"
expect_validation_failure "$ROOT_DIR/tests/exceptions/terraform-type-only.yaml"
expect_validation_failure "$ROOT_DIR/tests/exceptions/terraform-resource-wildcard.yaml"

echo "Policy fixtures, policy-ID isolation, multi-provider parity, and scoped exception contract passed under Rego v1."
