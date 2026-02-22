#!/bin/bash
# Script to remove an L2TP user programmatically

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
CHAP_SECRETS_FILE="${CHAP_SECRETS_FILE:-config/chap-secrets}"

# Function to print usage
usage() {
    echo "Usage: $0 <username>"
    echo ""
    echo "Arguments:"
    echo "  username     - Username to remove"
    echo ""
    echo "Environment variables:"
    echo "  CHAP_SECRETS_FILE - Path to chap-secrets file (default: config/chap-secrets)"
    echo ""
    echo "Examples:"
    echo "  $0 mikrotik2"
    exit 1
}

# Check arguments
if [ $# -lt 1 ]; then
    echo -e "${RED}Error: Missing username argument${NC}"
    usage
fi

USERNAME="$1"

# Check if file exists
if [ ! -f "$CHAP_SECRETS_FILE" ]; then
    echo -e "${RED}Error: $CHAP_SECRETS_FILE not found${NC}"
    exit 1
fi

# Check if username exists
if ! grep -q "^${USERNAME}[[:space:]]" "$CHAP_SECRETS_FILE"; then
    echo -e "${YELLOW}Warning: Username '$USERNAME' not found in $CHAP_SECRETS_FILE${NC}"
    exit 1
fi

# Remove user entry
sed -i.bak "/^${USERNAME}[[:space:]]/d" "$CHAP_SECRETS_FILE"

echo -e "${GREEN}✓ User '$USERNAME' removed successfully${NC}"

# If running in Docker, suggest restart
if [ -f "/.dockerenv" ] || [ -n "$DOCKER_CONTAINER" ]; then
    echo -e "${YELLOW}Note: Restart the container to apply changes:${NC}"
    echo "  docker-compose restart l2tp-server"
elif command -v docker-compose &> /dev/null; then
    echo -e "${YELLOW}To apply changes, restart the container:${NC}"
    echo "  docker-compose restart l2tp-server"
else
    echo -e "${YELLOW}To apply changes, restart xl2tpd:${NC}"
    echo "  sudo systemctl restart xl2tpd"
fi
