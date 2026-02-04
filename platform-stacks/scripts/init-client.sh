#!/bin/bash
# Script para inicializar un nuevo cliente
# Uso: ./scripts/init-client.sh --name "cliente" --cloud aws --region us-east-1

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Valores por defecto
CLOUD="aws"
REGION="us-east-1"
CLIENT_NAME=""

# Parsear argumentos
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
      echo -e "${RED}Argumento desconocido: $1${NC}"
      exit 1
      ;;
  esac
done

# Validar nombre
if [ -z "$CLIENT_NAME" ]; then
  echo -e "${RED}Error: --name es requerido${NC}"
  echo "Uso: $0 --name <cliente> [--cloud aws|azure|gcp] [--region <region>]"
  exit 1
fi

# Validar formato del nombre
if ! [[ "$CLIENT_NAME" =~ ^[a-z][a-z0-9-]{2,28}[a-z0-9]$ ]]; then
  echo -e "${RED}Error: Nombre inválido. Debe ser lowercase, 4-30 caracteres, alfanumérico con guiones.${NC}"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
CLIENT_DIR="$ROOT_DIR/clients/client-$CLIENT_NAME"

echo -e "${GREEN}=== Inicializando cliente: $CLIENT_NAME ===${NC}"
echo "Cloud: $CLOUD"
echo "Región: $REGION"

# Verificar que no existe
if [ -d "$CLIENT_DIR" ]; then
  echo -e "${RED}Error: El cliente ya existe: $CLIENT_DIR${NC}"
  exit 1
fi

# Crear estructura
echo -e "${YELLOW}Creando estructura de directorios...${NC}"
mkdir -p "$CLIENT_DIR"/{bootstrap,foundation/{networking,security,observability},environments/{dev,staging,prod}}

# Crear _client.yaml
echo -e "${YELLOW}Creando metadata del cliente...${NC}"
cat > "$CLIENT_DIR/_client.yaml" << EOF
# Metadata del Cliente: $CLIENT_NAME
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

# Copiar templates
echo -e "${YELLOW}Copiando templates...${NC}"

# Bootstrap
sed "s/{{ client_name }}/$CLIENT_NAME/g; s/{{ aws_region }}/$REGION/g" \
  "$ROOT_DIR/_templates/client-bootstrap/main.tf.tmpl" > "$CLIENT_DIR/bootstrap/main.tf"

# Environment templates
for env in dev staging prod; do
  sed "s/{{ client_name }}/$CLIENT_NAME/g; s/{{ environment }}/$env/g; s/{{ aws_region }}/$REGION/g; s/{{ stack_name }}/platform/g" \
    "$ROOT_DIR/_templates/environment/main.tf.tmpl" > "$CLIENT_DIR/environments/$env/main.tf"
done

echo -e "${GREEN}=== Cliente inicializado exitosamente ===${NC}"
echo ""
echo "Próximos pasos:"
echo "1. cd $CLIENT_DIR/bootstrap"
echo "2. terraform init"
echo "3. terraform apply"
echo "4. Configurar backend en los demás stacks"
