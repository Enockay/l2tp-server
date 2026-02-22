#!/bin/bash
# Script to add a new L2TP user programmatically

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
CHAP_SECRETS_FILE="${CHAP_SECRETS_FILE:-config/chap-secrets}"
SERVER_NAME="${SERVER_NAME:-L2TP-VPN}"
IP_ADDRESS="${IP_ADDRESS:-*}"

# Function to print usage
usage() {
    echo "Usage: $0 <username> <password> [ip_address]"
    echo ""
    echo "Arguments:"
    echo "  username     - Username for the VPN client"
    echo "  password     - Password for the VPN client"
    echo "  ip_address   - Optional: Specific IP address (default: *)"
    echo ""
    echo "Environment variables:"
    echo "  CHAP_SECRETS_FILE - Path to chap-secrets file (default: config/chap-secrets)"
    echo "  SERVER_NAME       - Server name (default: L2TP-VPN)"
    echo ""
    echo "Examples:"
    echo "  $0 mikrotik2 MySecurePassword123"
    echo "  $0 client1 Password456 10.10.10.50"
    exit 1
}

# Check arguments
if [ $# -lt 2 ]; then
    echo -e "${RED}Error: Missing required arguments${NC}"
    usage
fi

USERNAME="$1"
PASSWORD="$2"
IP="${3:-$IP_ADDRESS}"

# Validate username (alphanumeric and underscore only)
if ! [[ "$USERNAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo -e "${RED}Error: Username must be alphanumeric (may include underscore and dash)${NC}"
    exit 1
fi

# Check if username already exists
if grep -q "^${USERNAME}[[:space:]]" "$CHAP_SECRETS_FILE" 2>/dev/null; then
    echo -e "${YELLOW}Warning: Username '$USERNAME' already exists in $CHAP_SECRETS_FILE${NC}"
    read -p "Do you want to update it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
    # Remove existing entry
    sed -i.bak "/^${USERNAME}[[:space:]]/d" "$CHAP_SECRETS_FILE"
fi

# Add new user entry
# Format: username  server  password  IP
ENTRY="${USERNAME}\t${SERVER_NAME}\t${PASSWORD}\t${IP}"

# Check if file exists and has header
if [ ! -f "$CHAP_SECRETS_FILE" ]; then
    echo -e "${YELLOW}Creating $CHAP_SECRETS_FILE${NC}"
    cat > "$CHAP_SECRETS_FILE" <<EOF
# Secrets for authentication using CHAP
# client    server      secret      IP addresses
# username  server-name password    IP
EOF
fi

# Append new entry
echo -e "$ENTRY" >> "$CHAP_SECRETS_FILE"

echo -e "${GREEN}✓ User '$USERNAME' added successfully${NC}"
echo ""
echo "Entry added:"
echo "  Username: $USERNAME"
echo "  Server: $SERVER_NAME"
echo "  IP: $IP"
echo ""

# If running in Docker, suggest restart
if [ -f "/.dockerenv" ] || [ -n "$DOCKER_CONTAINER" ]; then
    echo -e "${YELLOW}Note: Running in Docker. Restart the container to apply changes:${NC}"
    echo "  docker-compose restart l2tp-server"
elif command -v docker-compose &> /dev/null; then
    echo -e "${YELLOW}To apply changes, restart the container:${NC}"
    echo "  docker-compose restart l2tp-server"
else
    echo -e "${YELLOW}To apply changes, restart xl2tpd:${NC}"
    echo "  sudo systemctl restart xl2tpd"
fi
