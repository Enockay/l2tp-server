#!/bin/bash
set -e

# Function to log messages
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Get environment variables with defaults
VPN_SERVER_IP="${VPN_SERVER_IP:-}"
VPN_SUBNET="${VPN_SUBNET:-10.10.10.0/24}"
VPN_IP_RANGE="${VPN_IP_RANGE:-10.10.10.2-10.10.10.100}"
VPN_LOCAL_IP="${VPN_LOCAL_IP:-10.10.10.1}"
PSK="${PSK:-ChangeThisPreSharedKey}"
DNS1="${DNS1:-8.8.8.8}"
DNS2="${DNS2:-8.8.4.4}"

log "Starting L2TP/IPsec VPN Server..."

# Update PSK in ipsec.secrets
log "Configuring IPsec secrets..."
sed -i "s|: PSK \".*\"|: PSK \"${PSK}\"|g" /etc/ipsec.secrets

# Update xl2tpd.conf with environment variables
log "Configuring xl2tpd..."
sed -i "s|ip range = .*|ip range = ${VPN_IP_RANGE}|g" /etc/xl2tpd/xl2tpd.conf
sed -i "s|local ip = .*|local ip = ${VPN_LOCAL_IP}|g" /etc/xl2tpd/xl2tpd.conf

# Update DNS in ppp options
log "Configuring DNS servers..."
sed -i "s|ms-dns .*|ms-dns ${DNS1}|g" /etc/ppp/options.xl2tpd
sed -i "s|ms-dns .*|ms-dns ${DNS2}|g" /etc/ppp/options.xl2tpd || true

# Update ipsec.conf if VPN_SERVER_IP is set
if [ -n "$VPN_SERVER_IP" ]; then
    log "Setting VPN server IP to ${VPN_SERVER_IP}..."
    sed -i "s|leftid=@%any|leftid=@${VPN_SERVER_IP}|g" /etc/ipsec.conf
fi

# Enable IP forwarding
log "Enabling IP forwarding..."
sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf

# Get the main network interface (usually eth0 or ens3)
MAIN_INTERFACE=$(ip route | grep default | awk '{print $5}' | head -n1)
if [ -z "$MAIN_INTERFACE" ]; then
    MAIN_INTERFACE="eth0"
fi

log "Detected main network interface: ${MAIN_INTERFACE}"

# Configure iptables rules
log "Configuring iptables..."

# Flush existing rules (be careful in production)
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X

# Allow established and related connections
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -i lo -j ACCEPT

# Allow IPsec/L2TP ports
iptables -A INPUT -p udp --dport 500 -j ACCEPT
iptables -A INPUT -p udp --dport 4500 -j ACCEPT
iptables -A INPUT -p udp --dport 1701 -j ACCEPT

# Allow forwarding for VPN subnet
iptables -A FORWARD -s ${VPN_SUBNET} -j ACCEPT
iptables -A FORWARD -d ${VPN_SUBNET} -j ACCEPT

# NAT for outbound traffic from VPN clients
iptables -t nat -A POSTROUTING -s ${VPN_SUBNET} -o ${MAIN_INTERFACE} -j MASQUERADE

# Default policies
iptables -P INPUT DROP
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

log "Iptables rules configured"

# Start strongSwan
log "Starting strongSwan..."
ipsec start --nofork &

# Wait a moment for IPsec to initialize
sleep 2

# Start xl2tpd
log "Starting xl2tpd..."
xl2tpd -D &

# Wait for xl2tpd to start
sleep 2

# Check if services are running
if ! pgrep -x "ipsec" > /dev/null; then
    log "ERROR: strongSwan failed to start"
    exit 1
fi

if ! pgrep -x "xl2tpd" > /dev/null; then
    log "ERROR: xl2tpd failed to start"
    exit 1
fi

log "L2TP/IPsec VPN Server is running!"
log "VPN Subnet: ${VPN_SUBNET}"
log "VPN IP Range: ${VPN_IP_RANGE}"
log "VPN Local IP: ${VPN_LOCAL_IP}"

# Keep container running and monitor processes
while true; do
    if ! pgrep -x "ipsec" > /dev/null; then
        log "ERROR: strongSwan process died, restarting..."
        ipsec start --nofork &
        sleep 2
    fi
    
    if ! pgrep -x "xl2tpd" > /dev/null; then
        log "ERROR: xl2tpd process died, restarting..."
        xl2tpd -D &
        sleep 2
    fi
    
    sleep 10
done
