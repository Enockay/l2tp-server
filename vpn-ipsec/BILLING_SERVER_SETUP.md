# Billing Server L2TP/IPsec Setup Guide

This guide shows how to configure the billing server to connect to the VPN using IPsec/L2TP.

## Server Information

- **VPN Server IP:** `157.230.159.170`
- **Username:** `billingServer`
- **Password:** `Enockay23`
- **IPsec PSK:** `AwSc2p9xUgyxtvD2YS5t`
- **Assigned Static IP:** `192.168.42.6`

## Linux (Ubuntu/Debian) Setup

### Step 1: Install Required Packages

```bash
sudo apt-get update
sudo apt-get install -y strongswan xl2tpd ppp
```

### Step 2: Configure IPsec

Create IPsec configuration file:

```bash
sudo nano /etc/ipsec.conf
```

Add the following configuration:

```
config setup
    virtual_private=%v4:10.0.0.0/8,%v4:192.168.0.0/16,%v4:172.16.0.0/12
    protostack=netkey
    nat_traversal=yes
    charondebug="none"

conn L2TP-PSK
    keyexchange=ikev1
    left=%defaultroute
    leftprotoport=17/1701
    right=157.230.159.170
    rightprotoport=17/1701
    rightid=%any
    rightauth=psk
    leftauth=psk
    auto=add
    ike=aes128-sha1-modp1024
    esp=aes128-sha1
    aggressive=no
    keyingtries=3
    ikelifetime=8h
    keylife=1h
    rekeymargin=3m
    rekey=no
    dpddelay=30
    dpdtimeout=120
    dpdaction=clear
```

### Step 3: Configure IPsec Secrets

```bash
sudo nano /etc/ipsec.secrets
```

Add:

```
include /var/lib/strongswan/ipsec.secrets.inc
157.230.159.170 : PSK "AwSc2p9xUgyxtvD2YS5t"
```

### Step 4: Configure L2TP

```bash
sudo nano /etc/xl2tpd/xl2tpd.conf
```

Add:

```
[global]
ipsec saref = no
listen-addr = 0.0.0.0

[lns default]
ip range = 192.168.42.10-192.168.42.250
local ip = 192.168.42.1
refuse chap = yes
refuse pap = yes
require authentication = yes
ppp debug = no
pppoptfile = /etc/ppp/options.xl2tpd
length bit = yes
```

### Step 5: Configure PPP Options

```bash
sudo nano /etc/ppp/options.xl2tpd
```

Add:

```
ipcp-accept-local
ipcp-accept-remote
ms-dns 8.8.8.8
ms-dns 8.8.4.4
noccp
auth
crtscts
idle 1800
mtu 1280
mru 1280
lock
connect-delay 5000
name billingServer
password Enockay23
```

### Step 6: Create L2TP Connection Script

```bash
sudo nano /usr/local/bin/connect-vpn.sh
```

Add:

```bash
#!/bin/bash
# Start IPsec
sudo ipsec start
sleep 2

# Start xl2tpd
sudo systemctl start xl2tpd
sleep 2

# Connect L2TP
echo "c billing-vpn" | sudo tee /var/run/xl2tpd/l2tp-control > /dev/null
sleep 5

# Configure route (optional - if you want to route all traffic through VPN)
# sudo ip route add default dev ppp0
```

Make it executable:

```bash
sudo chmod +x /usr/local/bin/connect-vpn.sh
```

### Step 7: Create Systemd Service (Optional - Auto-start)

```bash
sudo nano /etc/systemd/system/vpn-connection.service
```

Add:

```ini
[Unit]
Description=VPN Connection Service
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/connect-vpn.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
```

Enable and start:

```bash
sudo systemctl daemon-reload
sudo systemctl enable vpn-connection.service
sudo systemctl start vpn-connection.service
```

## Alternative: Using NetworkManager (Easier Method)

If your billing server uses NetworkManager (most modern Linux distributions):

### Step 1: Install NetworkManager L2TP Plugin

```bash
# Ubuntu/Debian
sudo apt-get install network-manager-l2tp network-manager-l2tp-gnome

# CentOS/RHEL
sudo yum install NetworkManager-l2tp
```

### Step 2: Configure via GUI or Command Line

**Via GUI (if available):**
1. Open Network Settings
2. Add new VPN connection
3. Choose "Layer 2 Tunneling Protocol (L2TP)"
4. Enter:
   - Gateway: `157.230.159.170`
   - Username: `billingServer`
   - Password: `Enockay23`
   - IPsec Settings:
     - Pre-shared key: `AwSc2p9xUgyxtvD2YS5t`
     - Phase1 Algorithms: `aes128-sha1-modp1024`
     - Phase2 Algorithms: `aes128-sha1`

**Via Command Line (nmcli):**

```bash
sudo nmcli connection add \
    type vpn \
    vpn-type l2tp \
    vpn.data "gateway=157.230.159.170,user=billingServer,password=Enockay23,ipsec-enabled=yes,ipsec-psk=AwSc2p9xUgyxtvD2YS5t,ipsec-ike=aes128-sha1-modp1024,ipsec-esp=aes128-sha1" \
    connection.id "Billing-VPN" \
    connection.autoconnect yes
```

Connect:

```bash
sudo nmcli connection up "Billing-VPN"
```

## Verify Connection

Check if connected:

```bash
# Check IPsec status
sudo ipsec status

# Check L2TP interface
ip addr show ppp0

# Check assigned IP (should be 192.168.42.6)
ip addr show ppp0 | grep inet

# Test connectivity
ping 192.168.42.1
```

## Identify Router Connections in Billing System

Your billing system can identify which router is connecting by checking the source IP:

```bash
# Example: Check connection source IP
# If source IP is 192.168.42.2 → Kitui Router
# If source IP is 192.168.42.3 → Chuka Router
# If source IP is 192.168.42.4 → Pius Router
# If source IP is 192.168.42.5 → Enock Router
```

## Troubleshooting

### Check IPsec logs:
```bash
sudo ipsec statusall
sudo journalctl -u strongswan
```

### Check L2TP logs:
```bash
sudo journalctl -u xl2tpd
tail -f /var/log/syslog | grep xl2tpd
```

### Restart services:
```bash
sudo systemctl restart strongswan
sudo systemctl restart xl2tpd
```

### Manual connection test:
```bash
sudo ipsec up L2TP-PSK
echo "c billing-vpn" | sudo tee /var/run/xl2tpd/l2tp-control
```
