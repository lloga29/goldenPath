#!/usr/bin/env bash
# Compose GoldenPath assurance and GitOps promotion contracts into one repository/reference showcase.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

command -v git >/dev/null 2>&1 || {
    echo "ERROR: Git is required to run the GoldenPath delivery showcase." >&2
    exit 1
}

echo "=== GoldenPath end-to-end evidence-backed delivery showcase ==="
echo
echo "[1/2] Risk-adaptive assurance and fail-closed evidence"
./scripts/demo.sh
echo
echo "[2/2] Digest-bound GitOps promotion contract"
./gitops-config/scripts/test-promotion-contract.sh
echo
echo "PASS: GoldenPath connected risk-derived controls, plan-bound evidence,"
echo "fail-closed rejection, trust-before-mutation, and exact digest continuity"
echo "through dev -> staging -> prod."
echo
echo "Evidence level: repository/reference only."
echo "The promotion harness uses isolated fake yq/cosign executables; real registry,"
echo "GitOps, Kubernetes, workload health, and production claims require separate evidence."
