#!/usr/bin/env bash
# Exercise digest-only promotion and fail-closed release verification without a live registry.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROMOTE_SOURCE="$ROOT_DIR/gitops-config/scripts/promote.sh"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

FAKE_BIN="$TMP_DIR/bin"
mkdir -p "$FAKE_BIN"

cat > "$FAKE_BIN/yq" <<'PY'
#!/usr/bin/env python3
import re
import sys
from pathlib import Path

args = sys.argv[1:]
if len(args) == 3 and args[0] == "-r":
    expr, filename = args[1], args[2]
    text = Path(filename).read_text(encoding="utf-8")
    def value(key):
        match = re.search(rf"^[ \t]+(?:-[ \t]+)?{re.escape(key)}:[ \t]*[\"']?([^\"'\n]+)[\"']?[ \t]*$", text, re.MULTILINE)
        return match.group(1).strip() if match else ""
    if expr == '.images[0].digest // ""':
        print(value("digest"))
    elif expr == '.images[0].newTag // ""':
        print(value("newTag"))
    elif expr == '.images[0].newName // .images[0].name // ""':
        print(value("newName") or value("name"))
    else:
        raise SystemExit(f"unsupported fake yq read expression: {expr}")
    raise SystemExit(0)

if len(args) == 3 and args[0] == "-i":
    expr, filename = args[1], args[2]
    match = re.search(r'digest = "(sha256:[0-9a-f]{64})"', expr)
    if not match:
        raise SystemExit(f"unsupported fake yq update expression: {expr}")
    digest = match.group(1)
    path = Path(filename)
    lines = path.read_text(encoding="utf-8").splitlines()
    output = []
    replaced = False
    for line in lines:
        if re.match(r"^[ \t]+newTag:", line):
            continue
        if re.match(r"^[ \t]+digest:", line):
            indent = line[: len(line) - len(line.lstrip())]
            output.append(f'{indent}digest: "{digest}"')
            replaced = True
        else:
            output.append(line)
    if not replaced:
        raise SystemExit("fake yq could not find digest field")
    path.write_text("\n".join(output) + "\n", encoding="utf-8")
    raise SystemExit(0)

raise SystemExit(f"unsupported fake yq invocation: {args}")
PY
chmod +x "$FAKE_BIN/yq"

cat > "$FAKE_BIN/cosign" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >> "${COSIGN_LOG:?}"
if [[ "${COSIGN_FAIL:-false}" == "true" ]]; then
    exit 1
fi
case "${1:-}" in
    verify|verify-attestation) exit 0 ;;
    *) exit 97 ;;
esac
SH
chmod +x "$FAKE_BIN/cosign"

NEW_DIGEST="sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
OLD_STAGING="sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
OLD_PROD="sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc"
EXPECTED_IDENTITY="https://github.com/org/payment-api/.github/workflows/ci.yaml@refs/heads/main"
EXPECTED_ISSUER="https://token.actions.githubusercontent.com"
COSIGN_LOG="$TMP_DIR/cosign.log"
export COSIGN_LOG

setup_repo() {
    local repo="$1"
    mkdir -p "$repo/gitops-config/scripts"
    cp "$PROMOTE_SOURCE" "$repo/gitops-config/scripts/promote.sh"
    chmod +x "$repo/gitops-config/scripts/promote.sh"

    for env in dev staging prod; do
        mkdir -p "$repo/gitops-config/apps/team-payments/payment-api/overlays/$env"
    done

    cat > "$repo/gitops-config/apps/team-payments/payment-api/overlays/dev/kustomization.yaml" <<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
images:
  - name: ghcr.io/org/payment-api
    digest: "$NEW_DIGEST"
EOF
    cat > "$repo/gitops-config/apps/team-payments/payment-api/overlays/staging/kustomization.yaml" <<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
images:
  - name: ghcr.io/org/payment-api
    digest: "$OLD_STAGING"
EOF
    cat > "$repo/gitops-config/apps/team-payments/payment-api/overlays/prod/kustomization.yaml" <<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
images:
  - name: ghcr.io/org/payment-api
    digest: "$OLD_PROD"
EOF

    git -C "$repo" init -q -b main
    git -C "$repo" config user.name "Juan Gallo"
    git -C "$repo" config user.email "lloga29@gmail.com"
    git -C "$repo" add .
    git -C "$repo" commit -q -m "test baseline"
}

REPO="$TMP_DIR/repo"
setup_repo "$REPO"
cd "$REPO"

if PATH="$FAKE_BIN:$PATH" ./gitops-config/scripts/promote.sh payments payment-api dev staging v1.2.3 >/dev/null 2>&1; then
    echo "ERROR: tag-based promotion unexpectedly succeeded." >&2
    exit 1
fi

if PATH="$FAKE_BIN:$PATH" ./gitops-config/scripts/promote.sh payments payment-api dev staging sha256:1234 >/dev/null 2>&1; then
    echo "ERROR: malformed digest promotion unexpectedly succeeded." >&2
    exit 1
fi

MISMATCH="sha256:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd"
if PATH="$FAKE_BIN:$PATH" ./gitops-config/scripts/promote.sh payments payment-api dev staging "$MISMATCH" >/dev/null 2>&1; then
    echo "ERROR: source-digest mismatch unexpectedly succeeded." >&2
    exit 1
fi

if PATH="$FAKE_BIN:$PATH" COSIGN_FAIL=true ./gitops-config/scripts/promote.sh payments payment-api dev staging "$NEW_DIGEST" >/dev/null 2>&1; then
    echo "ERROR: promotion unexpectedly succeeded after release verification failure." >&2
    exit 1
fi
if git branch --list 'promote/*' | grep -q .; then
    echo "ERROR: promotion branch was created before release trust verification succeeded." >&2
    exit 1
fi

: > "$COSIGN_LOG"
PATH="$FAKE_BIN:$PATH" ./gitops-config/scripts/promote.sh payments payment-api dev staging "$NEW_DIGEST" >/dev/null

STAGING_FILE="gitops-config/apps/team-payments/payment-api/overlays/staging/kustomization.yaml"
grep -F "digest: \"$NEW_DIGEST\"" "$STAGING_FILE" >/dev/null || {
    echo "ERROR: staging promotion did not preserve the exact source digest." >&2
    exit 1
}
if grep -q 'newTag:' "$STAGING_FILE"; then
    echo "ERROR: staging promotion reintroduced tag-based desired state." >&2
    exit 1
fi

grep -F "verify ghcr.io/org/payment-api@$NEW_DIGEST --certificate-identity=$EXPECTED_IDENTITY --certificate-oidc-issuer=$EXPECTED_ISSUER" "$COSIGN_LOG" >/dev/null || {
    echo "ERROR: image signature verification was not bound to the expected digest and identity." >&2
    exit 1
}
grep -F "verify-attestation ghcr.io/org/payment-api@$NEW_DIGEST --type slsaprovenance --certificate-identity=$EXPECTED_IDENTITY --certificate-oidc-issuer=$EXPECTED_ISSUER" "$COSIGN_LOG" >/dev/null || {
    echo "ERROR: signed provenance verification was not bound to the expected digest and identity." >&2
    exit 1
}

PATH="$FAKE_BIN:$PATH" ./gitops-config/scripts/promote.sh payments payment-api staging prod "$NEW_DIGEST" >/dev/null
PROD_FILE="gitops-config/apps/team-payments/payment-api/overlays/prod/kustomization.yaml"
grep -F "digest: \"$NEW_DIGEST\"" "$PROD_FILE" >/dev/null || {
    echo "ERROR: production promotion did not preserve the staging digest." >&2
    exit 1
}
if grep -q 'newTag:' "$PROD_FILE"; then
    echo "ERROR: production promotion reintroduced tag-based desired state." >&2
    exit 1
fi

if [[ "$(grep -c '^verify ' "$COSIGN_LOG")" -ne 2 ]]; then
    echo "ERROR: expected one image-signature verification per promotion." >&2
    exit 1
fi
if [[ "$(grep -c '^verify-attestation ' "$COSIGN_LOG")" -ne 2 ]]; then
    echo "ERROR: expected one signed-provenance verification per promotion." >&2
    exit 1
fi

echo "Digest-bound promotion contract passed."
