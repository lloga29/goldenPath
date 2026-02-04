#!/bin/bash
# Script para hacer rollback de un servicio a una versión anterior
# Uso: ./rollback.sh <team> <service> <env> [commits-back]
#
# Opciones:
#   EMERGENCY=true  - Rollback directo sin PR (solo emergencias)

set -euo pipefail

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

TEAM=${1:-}
SERVICE=${2:-}
ENV=${3:-}
COMMITS_BACK=${4:-1}
EMERGENCY=${EMERGENCY:-false}

if [[ -z "$TEAM" || -z "$SERVICE" || -z "$ENV" ]]; then
    echo "Uso: $0 <team> <service> <env> [commits-back]"
    echo "Ejemplo: $0 payments payment-api prod 1"
    exit 1
fi

SERVICE_PATH="apps/team-${TEAM}/${SERVICE}/overlays/${ENV}"

echo "=== ROLLBACK PROCEDURE ==="
echo "Servicio: ${SERVICE}"
echo "Entorno: ${ENV}"
echo "Commits atrás: ${COMMITS_BACK}"
echo ""

# Mostrar los últimos commits que afectaron este servicio
echo "Últimos cambios en ${SERVICE_PATH}:"
git log --oneline -n 5 -- "${SERVICE_PATH}"
echo ""

# Encontrar el commit a revertir
COMMIT_TO_REVERT=$(git log --oneline -n 1 --skip=$((COMMITS_BACK - 1)) -- "${SERVICE_PATH}" | awk '{print $1}')

if [[ -z "$COMMIT_TO_REVERT" ]]; then
    echo "Error: No se encontró commit para revertir"
    exit 1
fi

echo "Commit a revertir: ${COMMIT_TO_REVERT}"
git show --stat "${COMMIT_TO_REVERT}"
echo ""

read -p "¿Confirmar rollback? (y/N) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    git revert --no-commit "${COMMIT_TO_REVERT}"
    echo ""
    echo "Cambios revertidos (no commiteados). Revisa y ejecuta:"
    echo "  git commit -m 'revert(${TEAM}): rollback ${SERVICE} in ${ENV}'"
    echo "  git push origin main"
else
    echo "Rollback cancelado"
fi
