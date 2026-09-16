#!/usr/bin/env bash
# Create a Git-based rollback for one service environment.
# Usage: ./rollback.sh <team> <service> <env> [commits-back]

set -euo pipefail

EXPECTED_GIT_NAME="Juan Gallo"
EXPECTED_GIT_EMAIL="lloga29@gmail.com"

fail() {
    echo "ERROR: $*" >&2
    exit 1
}

ensure_git_identity() {
    local actual_name actual_email
    actual_name=$(git config user.name || true)
    actual_email=$(git config user.email || true)
    [[ "$actual_name" == "$EXPECTED_GIT_NAME" ]] || fail "git user.name must be '$EXPECTED_GIT_NAME'."
    [[ "$actual_email" == "$EXPECTED_GIT_EMAIL" ]] || fail "git user.email must be '$EXPECTED_GIT_EMAIL'."
}

ensure_clean_worktree() {
    git diff --quiet || fail "working tree contains unstaged changes."
    git diff --cached --quiet || fail "index contains staged changes."
}

TEAM=${1:-}
SERVICE=${2:-}
ENVIRONMENT=${3:-}
COMMITS_BACK=${4:-1}

[[ -n "$TEAM" && -n "$SERVICE" && -n "$ENVIRONMENT" ]] || {
    echo "Usage: $0 <team> <service> <env> [commits-back]"
    echo "Example: $0 payments payment-api prod 1"
    exit 1
}

[[ "$COMMITS_BACK" =~ ^[1-9][0-9]*$ ]] || fail "commits-back must be a positive integer."

case "$ENVIRONMENT" in
    dev|staging|prod) ;;
    *) fail "environment must be dev, staging, or prod." ;;
esac

ensure_git_identity
ensure_clean_worktree

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
SERVICE_PATH="gitops-config/apps/team-${TEAM}/${SERVICE}/overlays/${ENVIRONMENT}"
cd "$REPO_ROOT"

[[ -d "$SERVICE_PATH" ]] || fail "service environment path not found: ${SERVICE_PATH}."

COMMIT_TO_REVERT=$(git log --format='%H' -n 1 --skip=$((COMMITS_BACK - 1)) -- "$SERVICE_PATH")
[[ -n "$COMMIT_TO_REVERT" ]] || fail "no commit was found to revert for ${SERVICE_PATH}."

SHORT_SHA=${COMMIT_TO_REVERT:0:12}
BRANCH_NAME="rollback/${SERVICE}-${ENVIRONMENT}-${SHORT_SHA}"

echo "Rollback target: ${COMMIT_TO_REVERT}"
git show --stat --oneline "$COMMIT_TO_REVERT"

read -r -p "Create rollback branch and revert this commit? [y/N] " REPLY
[[ "$REPLY" =~ ^[Yy]$ ]] || {
    echo "Rollback cancelled."
    exit 0
}

git switch -c "$BRANCH_NAME"
git revert --no-edit "$COMMIT_TO_REVERT"

# Add the repository-required DCO sign-off without changing the reverted tree.
git commit --amend --no-edit -s

echo "Rollback commit created on ${BRANCH_NAME}."
echo "Push the branch and open a pull request; do not push rollback commits directly to main."
echo "  git push -u origin ${BRANCH_NAME}"
