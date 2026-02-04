#!/bin/bash
# Script para promocionar una versión de un servicio entre entornos
# Uso: ./promote.sh <team> <service> <source-env> <target-env> <image-tag>
# Requisitos: yq, git, gh (opcional para crear PR)

set -euo pipefail

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Verificar dependencias
check_deps() {
    local missing=0

    if ! command -v yq &> /dev/null; then
        echo -e "${YELLOW}WARNING: yq no instalado. Usando sed como fallback.${NC}"
        echo "Instalar yq: https://github.com/mikefarah/yq#install"
        USE_YQ=false
    else
        USE_YQ=true
    fi

    if ! command -v git &> /dev/null; then
        echo -e "${RED}ERROR: git no instalado${NC}"
        exit 1
    fi
}

check_deps

TEAM=${1:-}
SERVICE=${2:-}
SOURCE_ENV=${3:-}
TARGET_ENV=${4:-}
IMAGE_TAG=${5:-}
AUTO_PR=${AUTO_PR:-false}

if [[ -z "$TEAM" || -z "$SERVICE" || -z "$SOURCE_ENV" || -z "$TARGET_ENV" || -z "$IMAGE_TAG" ]]; then
    echo "Uso: $0 <team> <service> <source-env> <target-env> <image-tag>"
    echo "Ejemplo: $0 payments payment-api dev staging v1.2.3"
    echo ""
    echo "Variables de entorno:"
    echo "  AUTO_PR=true  - Crear PR automáticamente (requiere gh CLI)"
    exit 1
fi

# Validar que no se use :latest
if [[ "$IMAGE_TAG" == "latest" ]]; then
    echo -e "${RED}ERROR: No se permite usar 'latest' como tag.${NC}"
    echo "Use un tag inmutable (semver o SHA): v1.2.3 o abc1234"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APPS_DIR="${SCRIPT_DIR}/../apps"
SERVICE_DIR="${APPS_DIR}/team-${TEAM}/${SERVICE}"

if [[ ! -d "$SERVICE_DIR" ]]; then
    echo -e "${RED}Error: El servicio ${SERVICE} no existe en ${SERVICE_DIR}${NC}"
    exit 1
fi

TARGET_KUSTOMIZATION="${SERVICE_DIR}/overlays/${TARGET_ENV}/kustomization.yaml"

if [[ ! -f "$TARGET_KUSTOMIZATION" ]]; then
    echo -e "${RED}Error: No existe kustomization para entorno ${TARGET_ENV}${NC}"
    exit 1
fi

echo -e "${GREEN}=== Promoción de ${SERVICE} ===${NC}"
echo "  Team: ${TEAM}"
echo "  Source: ${SOURCE_ENV}"
echo "  Target: ${TARGET_ENV}"
echo "  Tag: ${IMAGE_TAG}"
echo ""

# Crear branch para la promoción
BRANCH_NAME="promote/${SERVICE}-${TARGET_ENV}-${IMAGE_TAG}"
echo -e "${YELLOW}Creando branch: ${BRANCH_NAME}${NC}"
git checkout -b "$BRANCH_NAME" 2>/dev/null || git checkout "$BRANCH_NAME"

# Actualizar el tag de imagen en el overlay destino
if [[ "$USE_YQ" == "true" ]]; then
    yq -i ".images[0].newTag = \"${IMAGE_TAG}\"" "$TARGET_KUSTOMIZATION"
else
    sed -i "s/newTag: .*/newTag: \"${IMAGE_TAG}\"/" "$TARGET_KUSTOMIZATION"
fi

echo -e "${GREEN}✓ Archivo actualizado: ${TARGET_KUSTOMIZATION}${NC}"

# Verificar el cambio
echo ""
echo "Cambios realizados:"
git diff --color "$TARGET_KUSTOMIZATION"

# Commit
git add "$TARGET_KUSTOMIZATION"
git commit -m "chore(${TEAM}): promote ${SERVICE} to ${TARGET_ENV} ${IMAGE_TAG}

Promoción automática:
- Service: ${SERVICE}
- From: ${SOURCE_ENV}
- To: ${TARGET_ENV}
- Image tag: ${IMAGE_TAG}"

echo ""
echo -e "${GREEN}✓ Commit creado${NC}"

# Crear PR si AUTO_PR está habilitado
if [[ "$AUTO_PR" == "true" ]] && command -v gh &> /dev/null; then
    echo -e "${YELLOW}Creando PR...${NC}"
    git push -u origin "$BRANCH_NAME"
    gh pr create \
        --title "Promote ${SERVICE} to ${TARGET_ENV}: ${IMAGE_TAG}" \
        --body "## Promoción Automática

**Servicio:** ${SERVICE}
**Origen:** ${SOURCE_ENV}
**Destino:** ${TARGET_ENV}
**Tag:** ${IMAGE_TAG}

### Checklist
- [ ] Verificar que el tag existe en el registry
- [ ] Revisar métricas en ${SOURCE_ENV}
- [ ] Aprobar promoción" \
        --label "promotion"
    echo -e "${GREEN}✓ PR creado${NC}"
else
    echo ""
    echo -e "${YELLOW}Para completar la promoción:${NC}"
    echo "1. Push: git push -u origin ${BRANCH_NAME}"
    echo "2. Crear PR en GitHub"
    echo "3. Esperar aprobación y merge"
    echo "4. Verificar sync en Argo CD"
fi
