#!/usr/bin/env bash
# Render every Argo CD platform Helm component with each environment's values.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

for command in helm python3; do
    command -v "$command" >/dev/null 2>&1 || {
        echo "ERROR: $command is required for platform Helm validation." >&2
        exit 1
    }
done

render_root="$(mktemp -d)"
trap 'rm -rf "$render_root"' EXIT

count=0
while IFS=$'\t' read -r component release chart repo version namespace environment common_values override_values; do
    [[ -n "$component" ]] || continue

    output="$render_root/${component}-${environment}.yaml"
    values_args=(-f "$common_values")
    if [[ "$override_values" != "-" ]]; then
        values_args+=(-f "$override_values")
    fi

    echo "Rendering ${component} (${environment}) chart=${chart} version=${version}"
    if [[ "$repo" == http://* || "$repo" == https://* ]]; then
        helm template "$release" "$chart" \
            --repo "$repo" \
            --version "$version" \
            --namespace "$namespace" \
            --include-crds \
            "${values_args[@]}" >"$output"
    else
        helm template "$release" "oci://${repo}/${chart}" \
            --version "$version" \
            --namespace "$namespace" \
            --include-crds \
            "${values_args[@]}" >"$output"
    fi

    if [[ ! -s "$output" ]]; then
        echo "ERROR: Helm rendered no manifests for ${component} (${environment})." >&2
        exit 1
    fi
    if ! grep -q '^kind:' "$output"; then
        echo "ERROR: Helm output for ${component} (${environment}) contains no Kubernetes resources." >&2
        exit 1
    fi
    count=$((count + 1))
done < <(python3 scripts/validate-gitops-contract.py --emit-helm-matrix)

if [[ "$count" -ne 21 ]]; then
    echo "ERROR: expected 21 platform Helm renders, executed ${count}." >&2
    exit 1
fi

echo "Platform Helm rendering passed for ${count} component/environment combinations."
