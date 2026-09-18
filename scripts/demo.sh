#!/usr/bin/env bash
# Demonstrate GoldenPath risk-adaptive assurance and fail-closed evidence semantics locally.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

PYTHON_BIN="${PYTHON_BIN:-python3}"
command -v "$PYTHON_BIN" >/dev/null 2>&1 || {
    echo "ERROR: Python 3 is required to run the GoldenPath demo." >&2
    exit 1
}

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

RISK_INPUT="platform-assurance/risk/examples/r2-change.json"
VALID_EVIDENCE="platform-assurance/evidence/fixtures/valid-risk-adaptive.json"
INVALID_EVIDENCE="platform-assurance/evidence/fixtures/invalid-risk-missing-gate.json"
PLAN="$TMP_DIR/assurance-plan.json"

echo "=== GoldenPath zero-cloud assurance demo ==="
echo
echo "[1/3] Derive the assurance plan from Architecture as Code and change context"
"$PYTHON_BIN" scripts/evaluate-risk.py "$RISK_INPUT" --output "$PLAN"

RISK_LEVEL="$("$PYTHON_BIN" - "$PLAN" <<'PY'
import json
import sys
with open(sys.argv[1], encoding="utf-8") as handle:
    print(json.load(handle)["riskLevel"])
PY
)"
AUTONOMY="$("$PYTHON_BIN" - "$PLAN" <<'PY'
import json
import sys
with open(sys.argv[1], encoding="utf-8") as handle:
    print(json.load(handle)["controls"]["autonomy"])
PY
)"
REQUIRED_GATES="$("$PYTHON_BIN" - "$PLAN" <<'PY'
import json
import sys
with open(sys.argv[1], encoding="utf-8") as handle:
    print(", ".join(json.load(handle)["controls"]["requiredGates"]))
PY
)"
PLAN_DIGEST="$("$PYTHON_BIN" - "$PLAN" <<'PY'
import json
import sys
with open(sys.argv[1], encoding="utf-8") as handle:
    print(json.load(handle)["evidenceRequirements"]["planDigest"])
PY
)"

echo "  Risk level: $RISK_LEVEL"
echo "  Autonomy: $AUTONOMY"
echo "  Required gates: $REQUIRED_GATES"
echo "  Plan digest: $PLAN_DIGEST"
echo

echo "[2/3] Validate evidence bound to the derived assurance plan"
"$PYTHON_BIN" scripts/validate-evidence-manifest.py     "$VALID_EVIDENCE"     --expected-plan-digest "$PLAN_DIGEST"     >/dev/null
echo "  PASS: matching evidence satisfies the assurance contract."
echo

echo "[3/3] Prove fail-closed behavior with incomplete required-gate evidence"
set +e
"$PYTHON_BIN" scripts/validate-evidence-manifest.py     "$INVALID_EVIDENCE"     --expected-plan-digest "$PLAN_DIGEST"     >"$TMP_DIR/expected-block.log" 2>&1
INVALID_STATUS=$?
set -e

if [[ "$INVALID_STATUS" -eq 0 ]]; then
    echo "ERROR: intentionally incomplete evidence was accepted." >&2
    exit 1
fi

BLOCK_REASON="$(head -n 1 "$TMP_DIR/expected-block.log" || true)"
echo "  EXPECTED BLOCK: ${BLOCK_REASON:-validator rejected incomplete evidence}"
echo
echo "PASS: GoldenPath derived risk-adaptive controls, accepted matching evidence,"
echo "and rejected incomplete evidence without cloud or runtime dependencies."
echo
echo "Evidence level: repository/reference only."
echo "Runtime evidence and production validation require their own real execution."
