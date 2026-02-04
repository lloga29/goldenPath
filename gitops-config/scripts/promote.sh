#!/bin/bash
# Script para promocionar una versión de un servicio entre entornos
# Uso: ./promote.sh <team> <service> <source-env> <target-env> <image-tag>

set -euo pipefail

TEAM=${1:-}
SERVICE=${2:-}
SOURCE_ENV=${3:-}
TARGET_ENV=${4:-}
IMAGE_TAG=${5:-}

if [[ -z "$TEAM" || -z "$SERVICE" || -z "$SOURCE_ENV" || -z "$TARGET_ENV" || -z "$IMAGE_TAG" ]]; then
    echo "Uso: $0 <team> <service> <source-env> <target-env> <image-tag>"
    echo "Ejemplo: $0 payments payment-api dev staging v1.2.3"
    exit 1
fi

APPS_DIR="$(dirname "$0")/../apps"
SERVICE_DIR="${APPS_DIR}/team-${TEAM}/${SERVICE}"

if [[ ! -d "$SERVICE_DIR" ]]; then
    echo "Error: El servicio ${SERVICE} no existe en ${SERVICE_DIR}"
    exit 1
fi

TARGET_KUSTOMIZATION="${SERVICE_DIR}/overlays/${TARGET_ENV}/kustomization.yaml"

if [[ ! -f "$TARGET_KUSTOMIZATION" ]]; then
    echo "Error: No existe kustomization para entorno ${TARGET_ENV}"
    exit 1
fi

echo "Promocionando ${SERVICE} de ${SOURCE_ENV} a ${TARGET_ENV} con tag ${IMAGE_TAG}"

# Actualizar el tag de imagen en el overlay destino
sed -i "s/newTag: .*/newTag: ${IMAGE_TAG}/" "$TARGET_KUSTOMIZATION"

echo "Archivo actualizado: ${TARGET_KUSTOMIZATION}"
echo ""
echo "Para completar la promoción:"
echo "1. Revisar los cambios: git diff"
echo "2. Commit: git commit -am 'chore(${TEAM}): promote ${SERVICE} to ${TARGET_ENV} ${IMAGE_TAG}'"
echo "3. Push: git push origin main"
echo "4. Verificar sync en Argo CD"
