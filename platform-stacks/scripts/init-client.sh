#!/bin/bash
# Initialize a new reference client stack.
# Usage: ./scripts/init-client.sh --name <client> --cloud aws --region us-east-1

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

CLOUD="aws"
REGION="us-east-1"
CLIENT_NAME=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --name)
      CLIENT_NAME="$2"
      shift 2
      ;;
    --cloud)
      CLOUD="$2"
      shift 2
      ;;
    --region)
      REGION="$2"
      shift 2
      ;;
    *)
      echo -e "${RED}Unknown argument: $1${NC}"
      exit 1
      ;;
  esac
done

if [ -z "$CLIENT_NAME" ]; then
  echo -e "${RED}ERROR: --name is required${NC}"
  echo "Usage: $0 --name <client> [--cloud aws] [--region <region>]"
  exit 1
fi

if ! [[ "$CLIENT_NAME" =~ ^[a-z][a-z0-9-]{2,28}[a-z0-9]$ ]]; then
  echo -e "${RED}ERROR: client name must be 4-30 lowercase alphanumeric characters or hyphens and start with a letter.${NC}"
  exit 1
fi

if [ "$CLOUD" != "aws" ]; then
  echo -e "${RED}ERROR: the current executable stack templates support only --cloud aws.${NC}"
  echo "Azure and Google Cloud remain roadmap implementations for platform-stacks."
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
CLIENT_DIR="$ROOT_DIR/clients/client-$CLIENT_NAME"

echo -e "${GREEN}=== Initializing client: $CLIENT_NAME ===${NC}"
echo "Cloud: $CLOUD"
echo "Region: $REGION"

if [ -d "$CLIENT_DIR" ]; then
  echo -e "${RED}ERROR: client directory already exists: $CLIENT_DIR${NC}"
  exit 1
fi

echo -e "${YELLOW}Creating directory structure...${NC}"
mkdir -p "$CLIENT_DIR"/{bootstrap,foundation/{networking,security,observability},environments/{dev,staging,prod}}

echo -e "${YELLOW}Creating client metadata...${NC}"
cat > "$CLIENT_DIR/_client.yaml" << EOF
# Client metadata: $CLIENT_NAME
client:
  name: $CLIENT_NAME
  created_at: "$(date +%Y-%m-%d)"
  owner: platform@example.com
  cost_center: cc-$CLIENT_NAME-001

cloud:
  provider: $CLOUD
  region: $REGION

environments:
  - name: dev
    auto_approve: true
  - name: staging
    auto_approve: true
  - name: prod
    auto_approve: false
EOF

echo -e "${YELLOW}Rendering templates...${NC}"
sed "s/{{ client_name }}/$CLIENT_NAME/g; s/{{ aws_region }}/$REGION/g" \
  "$ROOT_DIR/_templates/client-bootstrap/main.tf.tmpl" > "$CLIENT_DIR/bootstrap/main.tf"

for env in dev staging prod; do
  sed "s/{{ client_name }}/$CLIENT_NAME/g; s/{{ environment }}/$env/g; s/{{ aws_region }}/$REGION/g; s/{{ stack_name }}/platform/g" \
    "$ROOT_DIR/_templates/environment/main.tf.tmpl" > "$CLIENT_DIR/environments/$env/main.tf"
done

echo -e "${GREEN}=== Client initialized successfully ===${NC}"
echo "Review generated placeholders and security boundaries before running Terraform."
echo "Next: cd $CLIENT_DIR/bootstrap && terraform init && terraform plan"
