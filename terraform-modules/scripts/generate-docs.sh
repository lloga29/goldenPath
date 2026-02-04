#!/bin/bash
# Script para generar documentación de todos los módulos
# Uso: ./scripts/generate-docs.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Generando documentación de módulos ===${NC}"

# Verificar que terraform-docs está instalado
if ! command -v terraform-docs &> /dev/null; then
    echo -e "${RED}Error: terraform-docs no está instalado${NC}"
    echo "Instalar con: brew install terraform-docs"
    exit 1
fi

# Función para generar docs de un directorio
generate_docs() {
    local dir=$1
    if [ -f "$dir/main.tf" ]; then
        echo -e "${YELLOW}Procesando: $dir${NC}"
        terraform-docs markdown table \
            --output-file README.md \
            --output-mode inject \
            "$dir" 2>/dev/null || echo -e "${RED}  Error en $dir${NC}"
    fi
}

# Generar docs para módulos
echo -e "\n${GREEN}Procesando módulos...${NC}"
find "$ROOT_DIR/modules" -type d | while read -r dir; do
    generate_docs "$dir"
done

# Generar docs para patterns
echo -e "\n${GREEN}Procesando patterns...${NC}"
find "$ROOT_DIR/patterns" -type d | while read -r dir; do
    generate_docs "$dir"
done

echo -e "\n${GREEN}=== Documentación generada exitosamente ===${NC}"
