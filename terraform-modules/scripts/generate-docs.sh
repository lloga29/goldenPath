#!/bin/bash
# Generate terraform-docs output for all implemented modules and patterns.
# Usage: ./scripts/generate-docs.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== Generating Terraform module documentation ===${NC}"

if ! command -v terraform-docs &> /dev/null; then
    echo -e "${RED}ERROR: terraform-docs is not installed${NC}"
    echo "Install it from: https://terraform-docs.io/user-guide/installation/"
    exit 1
fi

generate_docs() {
    local dir=$1
    if [ -f "$dir/main.tf" ]; then
        echo -e "${YELLOW}Processing: $dir${NC}"
        terraform-docs markdown table \
            --output-file README.md \
            --output-mode inject \
            "$dir"
    fi
}

echo -e "\n${GREEN}Processing modules...${NC}"
while IFS= read -r dir; do
    generate_docs "$dir"
done < <(find "$ROOT_DIR/modules" -name "main.tf" -exec dirname {} \; | sort -u)

echo -e "\n${GREEN}Processing patterns...${NC}"
while IFS= read -r dir; do
    generate_docs "$dir"
done < <(find "$ROOT_DIR/patterns" -name "main.tf" -exec dirname {} \; | sort -u)

echo -e "\n${GREEN}=== Documentation generated successfully ===${NC}"
