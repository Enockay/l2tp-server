#!/bin/bash
# Script to list all L2TP users

# Configuration
CHAP_SECRETS_FILE="${CHAP_SECRETS_FILE:-config/chap-secrets}"

# Check if file exists
if [ ! -f "$CHAP_SECRETS_FILE" ]; then
    echo "Error: $CHAP_SECRETS_FILE not found"
    exit 1
fi

echo "L2TP VPN Users:"
echo "==============="
echo ""
printf "%-20s %-15s %-15s %s\n" "USERNAME" "SERVER" "PASSWORD" "IP"
echo "--------------------------------------------------------------------------------"

# Parse and display users (skip comments and empty lines)
grep -v "^#" "$CHAP_SECRETS_FILE" | grep -v "^$" | while IFS=$'\t' read -r username server password ip; do
    # Mask password (show first 3 chars)
    if [ ${#password} -gt 3 ]; then
        masked_password="${password:0:3}***"
    else
        masked_password="***"
    fi
    printf "%-20s %-15s %-15s %s\n" "$username" "$server" "$masked_password" "$ip"
done

echo ""
echo "Total users: $(grep -v "^#" "$CHAP_SECRETS_FILE" | grep -v "^$" | wc -l | tr -d ' ')"
