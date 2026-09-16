#!/bin/bash
# Validate all implemented Terraform modules and patterns.
# Usage: ./scripts/validate-all.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

check_dependencies() {
    echo -e "${YELLOW}=== Checking dependencies ===${NC}"

    if ! command -v terraform &> /dev/null; then
        echo -e "${RED}ERROR: terraform is not installed${NC}"
        echo "Install Terraform from: https://developer.hashicorp.com/terraform/install"
        exit 1
    fi

    if command -v jq &> /dev/null; then
        echo -e "${GREEN}✓ terraform $(terraform version -json | jq -r '.terraform_version')${NC}"
    else
        echo -e "${GREEN}✓ terraform is installed${NC}"
        echo -e "${YELLOW}⚠ jq is not installed; Terraform version will not be parsed${NC}"
    fi

    if command -v tflint &> /dev/null; then
        echo -e "${GREEN}✓ tflint is installed${NC}"
    else
        echo -e "${YELLOW}⚠ tflint is not installed (optional for this script)${NC}"
    fi

    if command -v checkov &> /dev/null; then
        echo -e "${GREEN}✓ checkov is installed${NC}"
    else
        echo -e "${YELLOW}⚠ checkov is not installed (optional for this script)${NC}"
    fi

    echo ""
}

ERRORS=0

validate_module() {
    local dir=$1

    if [ ! -f "$dir/main.tf" ]; then
        return
    fi

    echo -e "\n${YELLOW}Validating: $dir${NC}"

    echo "  → Checking formatting..."
    if ! terraform -chdir="$dir" fmt -check -recursive; then
        echo -e "  ${RED}✗ Formatting check failed${NC}"
        ((ERRORS+=1))
    else
        echo -e "  ${GREEN}✓ Formatting OK${NC}"
    fi

    echo "  → Initializing without a backend..."
    if ! terraform -chdir="$dir" init -backend=false -input=false -no-color; then
        echo -e "  ${RED}✗ Initialization failed${NC}"
        ((ERRORS+=1))
        return
    fi

    echo "  → Validating configuration..."
    if ! terraform -chdir="$dir" validate -no-color; then
        echo -e "  ${RED}✗ Validation failed${NC}"
        ((ERRORS+=1))
    else
        echo -e "  ${GREEN}✓ Validation OK${NC}"
    fi

    if [ -d "$dir/tests" ]; then
        echo "  → Running Terraform tests..."
        if ! terraform -chdir="$dir" test -no-color; then
            echo -e "  ${RED}✗ Terraform tests failed${NC}"
            ((ERRORS+=1))
        else
            echo -e "  ${GREEN}✓ Terraform tests OK${NC}"
        fi
    fi

    rm -rf "$dir/.terraform" "$dir/.terraform.lock.hcl" 2>/dev/null || true
}

check_dependencies

echo -e "${GREEN}=== Validating Terraform modules ===${NC}"

while IFS= read -r dir; do
    validate_module "$dir"
done < <(find "$ROOT_DIR/modules" -name "main.tf" -exec dirname {} \; | sort -u)

while IFS= read -r dir; do
    validate_module "$dir"
done < <(find "$ROOT_DIR/patterns" -name "main.tf" -exec dirname {} \; | sort -u)

echo -e "\n${GREEN}=== Validation completed ===${NC}"

if [ "$ERRORS" -gt 0 ]; then
    echo -e "${RED}Found $ERRORS validation error(s)${NC}"
    exit 1
fi

echo -e "${GREEN}All implemented modules and patterns are valid${NC}"
