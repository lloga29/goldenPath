#!/usr/bin/env bash
# Promote one verified immutable service image digest between environments.
# Usage: ./promote.sh <team> <service> <source-env> <target-env> <image-digest>
# Requirements: git, yq, cosign, and optionally gh when AUTO_PR=true.

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

EXPECTED_GIT_NAME="Juan Gallo"
EXPECTED_GIT_EMAIL="lloga29@gmail.com"
DEFAULT_OIDC_ISSUER="https://token.actions.githubusercontent.com"

fail() {
    echo -e "${RED}ERROR: $*${NC}" >&2
    exit 1
}

ensure_git_identity() {
    local actual_name actual_email
    actual_name=$(git config user.name || true)
    actual_email=$(git config user.email || true)
    [[ "$actual_name" == "$EXPECTED_GIT_NAME" ]] || fail "git user.name must be '$EXPECTED_GIT_NAME' (found '${actual_name:-unset}')."
    [[ "$actual_email" == "$EXPECTED_GIT_EMAIL" ]] || fail "git user.email must be '$EXPECTED_GIT_EMAIL' (found '${actual_email:-unset}')."
}

ensure_clean_worktree() {
    git diff --quiet || fail "working tree contains unstaged changes. Commit or stash them before promotion."
    git diff --cached --quiet || fail "index contains staged changes. Commit or unstage them before promotion."
}

check_dependencies() {
    command -v git >/dev/null 2>&1 || fail "git is not installed."
    command -v yq >/dev/null 2>&1 || fail "yq v4 is required for deterministic promotion updates."
    command -v cosign >/dev/null 2>&1 || fail "cosign is required for signature and provenance verification."
}

infer_workflow_identity() {
    local image_name="$1"
    local registry_path owner repository

    [[ "$image_name" == ghcr.io/* ]] || fail "TRUSTED_WORKFLOW_IDENTITY is required for non-GHCR image '${image_name}'."
    registry_path="${image_name#ghcr.io/}"
    [[ "$registry_path" == */* ]] || fail "cannot infer GitHub workflow identity from '${image_name}'."
    owner="${registry_path%%/*}"
    repository="${registry_path#*/}"
    [[ "$repository" != */* ]] || fail "TRUSTED_WORKFLOW_IDENTITY is required when the GHCR image path is not exactly <owner>/<repository>."
    [[ -n "$owner" && -n "$repository" ]] || fail "cannot infer GitHub workflow identity from '${image_name}'."

    printf 'https://github.com/%s/%s/.github/workflows/ci.yaml@refs/heads/main\n' "$owner" "$repository"
}

verify_release_trust() {
    local image_ref="$1"
    local workflow_identity="$2"
    local oidc_issuer="$3"

    echo "Verifying release signature for ${image_ref}"
    cosign verify "$image_ref" \
        --certificate-identity="$workflow_identity" \
        --certificate-oidc-issuer="$oidc_issuer" >/dev/null \
        || fail "image signature verification failed for ${image_ref}."

    echo "Verifying signed SLSA provenance for ${image_ref}"
    cosign verify-attestation "$image_ref" \
        --type slsaprovenance \
        --certificate-identity="$workflow_identity" \
        --certificate-oidc-issuer="$oidc_issuer" >/dev/null \
        || fail "signed SLSA provenance verification failed for ${image_ref}."
}

TEAM=${1:-}
SERVICE=${2:-}
SOURCE_ENV=${3:-}
TARGET_ENV=${4:-}
IMAGE_DIGEST=${5:-}
AUTO_PR=${AUTO_PR:-false}
TRUSTED_OIDC_ISSUER=${TRUSTED_OIDC_ISSUER:-$DEFAULT_OIDC_ISSUER}
TRUSTED_WORKFLOW_IDENTITY=${TRUSTED_WORKFLOW_IDENTITY:-}

if [[ -z "$TEAM" || -z "$SERVICE" || -z "$SOURCE_ENV" || -z "$TARGET_ENV" || -z "$IMAGE_DIGEST" ]]; then
    echo "Usage: $0 <team> <service> <source-env> <target-env> <image-digest>"
    echo "Example: $0 payments payment-api dev staging sha256:0000000000000000000000000000000000000000000000000000000000000000"
    exit 1
fi

[[ "$IMAGE_DIGEST" =~ ^sha256:[0-9a-f]{64}$ ]] || fail "image identity must be an exact lowercase sha256:<64-hex> digest. Tags are not accepted."

case "${SOURCE_ENV}:${TARGET_ENV}" in
    dev:staging|staging:prod) ;;
    *) fail "unsupported promotion path '${SOURCE_ENV}' -> '${TARGET_ENV}'. Allowed paths are dev -> staging and staging -> prod." ;;
esac

check_dependencies
ensure_git_identity
ensure_clean_worktree

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
SERVICE_DIR="gitops-config/apps/team-${TEAM}/${SERVICE}"
SOURCE_KUSTOMIZATION="${SERVICE_DIR}/overlays/${SOURCE_ENV}/kustomization.yaml"
TARGET_KUSTOMIZATION="${SERVICE_DIR}/overlays/${TARGET_ENV}/kustomization.yaml"
cd "$REPO_ROOT"

[[ -d "$SERVICE_DIR" ]] || fail "service '${SERVICE}' was not found at ${SERVICE_DIR}."
[[ -f "$SOURCE_KUSTOMIZATION" ]] || fail "source kustomization does not exist for environment '${SOURCE_ENV}'."
[[ -f "$TARGET_KUSTOMIZATION" ]] || fail "target kustomization does not exist for environment '${TARGET_ENV}'."

SOURCE_DIGEST=$(yq -r '.images[0].digest // ""' "$SOURCE_KUSTOMIZATION")
SOURCE_TAG=$(yq -r '.images[0].newTag // ""' "$SOURCE_KUSTOMIZATION")
SOURCE_IMAGE=$(yq -r '.images[0].newName // .images[0].name // ""' "$SOURCE_KUSTOMIZATION")
TARGET_IMAGE=$(yq -r '.images[0].newName // .images[0].name // ""' "$TARGET_KUSTOMIZATION")
TARGET_TAG=$(yq -r '.images[0].newTag // ""' "$TARGET_KUSTOMIZATION")

[[ -z "$SOURCE_TAG" ]] || fail "source environment still uses newTag='${SOURCE_TAG}'. Migrate it to an OCI digest before promotion."
[[ -z "$TARGET_TAG" ]] || fail "target environment still uses newTag='${TARGET_TAG}'. Migrate it to an OCI digest before promotion."
[[ "$SOURCE_DIGEST" =~ ^sha256:[0-9a-f]{64}$ ]] || fail "source environment does not contain a valid OCI sha256 digest."
[[ "$SOURCE_DIGEST" == "$IMAGE_DIGEST" ]] || fail "requested digest '${IMAGE_DIGEST}' does not match source environment digest '${SOURCE_DIGEST}'."
[[ -n "$SOURCE_IMAGE" ]] || fail "source environment does not declare an image name."
[[ "$SOURCE_IMAGE" == "$TARGET_IMAGE" ]] || fail "source image '${SOURCE_IMAGE}' does not match target image '${TARGET_IMAGE}'."

if [[ -z "$TRUSTED_WORKFLOW_IDENTITY" ]]; then
    TRUSTED_WORKFLOW_IDENTITY="$(infer_workflow_identity "$SOURCE_IMAGE")"
fi

IMAGE_REF="${SOURCE_IMAGE}@${IMAGE_DIGEST}"
verify_release_trust "$IMAGE_REF" "$TRUSTED_WORKFLOW_IDENTITY" "$TRUSTED_OIDC_ISSUER"

DIGEST_HEX="${IMAGE_DIGEST#sha256:}"
DIGEST_SHORT="${DIGEST_HEX:0:12}"
BRANCH_NAME="promote/${SERVICE}-${TARGET_ENV}-${DIGEST_SHORT}"

echo -e "${GREEN}=== Promote ${SERVICE} ===${NC}"
echo "Team: ${TEAM}"
echo "Source: ${SOURCE_ENV}"
echo "Target: ${TARGET_ENV}"
echo "Image: ${SOURCE_IMAGE}"
echo "Digest: ${IMAGE_DIGEST}"
echo "Trusted signer: ${TRUSTED_WORKFLOW_IDENTITY}"

git switch -c "$BRANCH_NAME"
yq -i ".images[0].digest = \"${IMAGE_DIGEST}\" | del(.images[0].newTag)" "$TARGET_KUSTOMIZATION"

git diff --check
git diff -- "$TARGET_KUSTOMIZATION"
git add -- "$TARGET_KUSTOMIZATION"
git commit -s -m "chore(${TEAM}): promote ${SERVICE} to ${TARGET_ENV} ${DIGEST_SHORT}"

echo -e "${GREEN}Promotion commit created with verified immutable release evidence.${NC}"

if [[ "$AUTO_PR" == "true" ]]; then
    command -v gh >/dev/null 2>&1 || fail "AUTO_PR=true requires the GitHub CLI."
    git push -u origin "$BRANCH_NAME"
    gh pr create \
        --title "chore(${TEAM}): promote ${SERVICE} to ${TARGET_ENV} ${DIGEST_SHORT}" \
        --body "## Promotion\n\n- Service: \`${SERVICE}\`\n- Team: \`${TEAM}\`\n- Source: \`${SOURCE_ENV}\`\n- Target: \`${TARGET_ENV}\`\n- Image: \`${SOURCE_IMAGE}\`\n- Digest: \`${IMAGE_DIGEST}\`\n- Trusted signer: \`${TRUSTED_WORKFLOW_IDENTITY}\`\n\n### Verification\n- [x] Exact source digest preserved\n- [x] Keyless image signature verified\n- [x] Signed SLSA provenance verified\n- [ ] Source environment is healthy\n- [ ] Target environment checks pass\n- [ ] Production approval is recorded when applicable"
    echo -e "${GREEN}Pull request created.${NC}"
else
    echo "Push the branch and open a pull request to complete the promotion:"
    echo "  git push -u origin ${BRANCH_NAME}"
fi
