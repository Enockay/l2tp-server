#!/bin/bash
# Script to generate MikroTik RouterOS configuration for L2TP client

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print usage
usage() {
    echo "Usage: $0 <username> <vpn_server_ip> <psk> [vpn_client_ip]"
    echo ""
    echo "Arguments:"
    echo "  username       - Username from chap-secrets"
    echo "  vpn_server_ip  - L2TP server public IP address"
    echo "  psk            - Pre-shared key for IPsec"
    echo "  vpn_client_ip  - Optional: Specific IP for this client (e.g., 10.10.10.10)"
    echo ""
    echo "Examples:"
    echo "  $0 mikrotik1 192.168.1.100 MyPSK123"
    echo "  $0 mikrotik2 192.168.1.100 MyPSK123 10.10.10.11"
    exit 1
}

# Check arguments
if [ $# -lt 3 ]; then
    echo "Error: Missing required arguments"
    usage
fi

USERNAME="$1"
VPN_SERVER_IP="$2"
PSK="$3"
VPN_CLIENT_IP="${4:-}"

# Generate RouterOS script
echo -e "${GREEN}MikroTik RouterOS Configuration Script${NC}"
echo "=============================================="
echo ""
echo "# Generated L2TP Client Configuration for: $USERNAME"
echo "# Server IP: $VPN_SERVER_IP"
echo ""
echo "# Add L2TP client interface"
echo "/interface l2tp-client add \\"
echo "    connect-to=$VPN_SERVER_IP \\"
echo "    name=L2TP-VPN-$USERNAME \\"
echo "    user=$USERNAME \\"
echo "    password=\"<PASSWORD_FROM_CHAP_SECRETS>\" \\"
echo "    profile=default-encryption \\"
echo "    use-ipsec=yes \\"
echo "    ipsec-secret=\"$PSK\" \\"
echo "    disabled=no"
echo ""

if [ -n "$VPN_CLIENT_IP" ]; then
    echo "# Add IP address to L2TP interface"
    echo "/ip address add address=$VPN_CLIENT_IP/24 interface=L2TP-VPN-$USERNAME"
else
    echo "# Add IP address (will be assigned by server)"
    echo "# /ip address add address=10.10.10.X/24 interface=L2TP-VPN-$USERNAME"
    echo "# Note: Replace X with desired IP (e.g., 10, 11, 12, etc.)"
fi

echo ""
echo -e "${YELLOW}Note: Replace <PASSWORD_FROM_CHAP_SECRETS> with the actual password${NC}"
echo "      from your config/chap-secrets file for user: $USERNAME"
