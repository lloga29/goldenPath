#!/bin/bash
# Script para validar todos los módulos
# Uso: ./scripts/validate-all.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Verificar dependencias
check_dependencies() {
    echo -e "${YELLOW}=== Verificando dependencias ===${NC}"

    if ! command -v terraform &> /dev/null; then
        echo -e "${RED}ERROR: terraform no está instalado${NC}"
        echo "Instalar: https://developer.hashicorp.com/terraform/downloads"
        exit 1
    fi
    echo -e "${GREEN}✓ terraform $(terraform version -json | jq -r '.terraform_version')${NC}"

    if command -v tflint &> /dev/null; then
        echo -e "${GREEN}✓ tflint instalado${NC}"
    else
        echo -e "${YELLOW}⚠ tflint no instalado (opcional)${NC}"
    fi

    if command -v checkov &> /dev/null; then
        echo -e "${GREEN}✓ checkov instalado${NC}"
    else
        echo -e "${YELLOW}⚠ checkov no instalado (opcional)${NC}"
    fi

    echo ""
}

check_dependencies

# Colores (redefinidos para compatibilidad)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ERRORS=0

echo -e "${GREEN}=== Validando módulos Terraform ===${NC}"

# Función para validar un módulo
validate_module() {
    local dir=$1

    if [ -f "$dir/main.tf" ]; then
        echo -e "\n${YELLOW}Validando: $dir${NC}"

        # Terraform fmt check
        echo "  → Verificando formato..."
        if ! terraform -chdir="$dir" fmt -check -recursive > /dev/null 2>&1; then
            echo -e "  ${RED}✗ Formato incorrecto${NC}"
            ((ERRORS++))
        else
            echo -e "  ${GREEN}✓ Formato OK${NC}"
        fi

        # Terraform init
        echo "  → Inicializando..."
        if ! terraform -chdir="$dir" init -backend=false > /dev/null 2>&1; then
            echo -e "  ${RED}✗ Init fallido${NC}"
            ((ERRORS++))
            return
        fi

        # Terraform validate
        echo "  → Validando configuración..."
        if ! terraform -chdir="$dir" validate > /dev/null 2>&1; then
            echo -e "  ${RED}✗ Validación fallida${NC}"
            ((ERRORS++))
        else
            echo -e "  ${GREEN}✓ Validación OK${NC}"
        fi

        # Terraform test (si hay tests)
        if [ -d "$dir/tests" ]; then
            echo "  → Ejecutando tests..."
            if ! terraform -chdir="$dir" test > /dev/null 2>&1; then
                echo -e "  ${RED}✗ Tests fallidos${NC}"
                ((ERRORS++))
            else
                echo -e "  ${GREEN}✓ Tests OK${NC}"
            fi
        fi

        # Limpiar
        rm -rf "$dir/.terraform" "$dir/.terraform.lock.hcl" 2>/dev/null || true
    fi
}

# Validar todos los módulos
find "$ROOT_DIR/modules" -name "main.tf" -exec dirname {} \; | sort -u | while read -r dir; do
    validate_module "$dir"
done

# Validar patterns
find "$ROOT_DIR/patterns" -name "main.tf" -exec dirname {} \; | sort -u | while read -r dir; do
    validate_module "$dir"
done

echo -e "\n${GREEN}=== Validación completada ===${NC}"

if [ $ERRORS -gt 0 ]; then
    echo -e "${RED}Se encontraron $ERRORS errores${NC}"
    exit 1
else
    echo -e "${GREEN}Todos los módulos válidos${NC}"
fi
