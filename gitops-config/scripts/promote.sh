#!/usr/bin/env bash
# Promote one immutable service image reference between environments.
# Usage: ./promote.sh <team> <service> <source-env> <target-env> <image-tag>
# Requirements: git, yq, and optionally gh when AUTO_PR=true.

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

EXPECTED_GIT_NAME="Juan Gallo"
EXPECTED_GIT_EMAIL="lloga29@gmail.com"

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
}

TEAM=${1:-}
SERVICE=${2:-}
SOURCE_ENV=${3:-}
TARGET_ENV=${4:-}
IMAGE_TAG=${5:-}
AUTO_PR=${AUTO_PR:-false}

if [[ -z "$TEAM" || -z "$SERVICE" || -z "$SOURCE_ENV" || -z "$TARGET_ENV" || -z "$IMAGE_TAG" ]]; then
    echo "Usage: $0 <team> <service> <source-env> <target-env> <image-tag>"
    echo "Example: $0 payments payment-api dev staging v1.2.3"
    exit 1
fi

[[ "$IMAGE_TAG" != "latest" ]] || fail "the 'latest' image tag is not allowed. Use an immutable SemVer or commit-derived tag."

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

SOURCE_TAG=$(yq -r '.images[0].newTag // ""' "$SOURCE_KUSTOMIZATION")
[[ -n "$SOURCE_TAG" ]] || fail "no image newTag was found in ${SOURCE_KUSTOMIZATION}."
[[ "$SOURCE_TAG" == "$IMAGE_TAG" ]] || fail "requested tag '${IMAGE_TAG}' does not match source environment tag '${SOURCE_TAG}'."

BRANCH_NAME="promote/${SERVICE}-${TARGET_ENV}-${IMAGE_TAG}"

echo -e "${GREEN}=== Promote ${SERVICE} ===${NC}"
echo "Team: ${TEAM}"
echo "Source: ${SOURCE_ENV}"
echo "Target: ${TARGET_ENV}"
echo "Image tag: ${IMAGE_TAG}"

git switch -c "$BRANCH_NAME"
yq -i ".images[0].newTag = \"${IMAGE_TAG}\"" "$TARGET_KUSTOMIZATION"

git diff --check
git diff -- "$TARGET_KUSTOMIZATION"
git add -- "$TARGET_KUSTOMIZATION"
git commit -s -m "chore(${TEAM}): promote ${SERVICE} to ${TARGET_ENV} ${IMAGE_TAG}"

echo -e "${GREEN}Promotion commit created with the required identity.${NC}"

if [[ "$AUTO_PR" == "true" ]]; then
    command -v gh >/dev/null 2>&1 || fail "AUTO_PR=true requires the GitHub CLI."
    git push -u origin "$BRANCH_NAME"
    gh pr create \
        --title "chore(${TEAM}): promote ${SERVICE} to ${TARGET_ENV} ${IMAGE_TAG}" \
        --body "## Promotion\n\n- Service: \`${SERVICE}\`\n- Team: \`${TEAM}\`\n- Source: \`${SOURCE_ENV}\`\n- Target: \`${TARGET_ENV}\`\n- Image tag: \`${IMAGE_TAG}\`\n\n### Verification\n- [ ] Source environment is healthy\n- [ ] Image reference exists and is immutable\n- [ ] Target environment checks pass\n- [ ] Production approval is recorded when applicable"
    echo -e "${GREEN}Pull request created.${NC}"
else
    echo "Push the branch and open a pull request to complete the promotion:"
    echo "  git push -u origin ${BRANCH_NAME}"
fi
