#!/usr/bin/env bash
# Validate executable Terraform stack directories without contacting configured state backends.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ERRORS=0

command -v terraform >/dev/null 2>&1 || {
    echo "ERROR: terraform is required." >&2
    exit 1
}

while IFS= read -r main_file; do
    dir="$(dirname "$main_file")"
    relative="${dir#${ROOT_DIR}/}"
    echo "Validating Terraform stack: $relative"

    if ! terraform -chdir="$dir" fmt -check -recursive; then
        echo "ERROR: Terraform formatting failed in $relative" >&2
        ((ERRORS+=1))
    fi

    if ! terraform -chdir="$dir" init -backend=false -input=false -no-color >/dev/null; then
        echo "ERROR: Terraform initialization failed in $relative" >&2
        ((ERRORS+=1))
        rm -rf "$dir/.terraform" "$dir/.terraform.lock.hcl"
        continue
    fi

    if ! terraform -chdir="$dir" validate -no-color; then
        echo "ERROR: Terraform validation failed in $relative" >&2
        ((ERRORS+=1))
    fi

    rm -rf "$dir/.terraform" "$dir/.terraform.lock.hcl"
done < <(find "$ROOT_DIR/platform-stacks" -type f -name main.tf -not -path '*/.terraform/*' | sort)

if (( ERRORS > 0 )); then
    echo "Platform stack validation failed with $ERRORS error(s)." >&2
    exit 1
fi

echo "All executable platform stack Terraform directories are valid."
