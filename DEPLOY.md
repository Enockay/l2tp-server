# Collify Deployment Guide

Quick deployment guide for L2TP/IPsec VPN server on Collify.

## Step 1: Upload Files to Collify

Upload the entire project directory to your Collify VPS:

```bash
# On your local machine
scp -r /Users/Enockay/l2tp user@your-collify-vps:/opt/
```

Or use git:
```bash
# On Collify VPS
cd /opt
git clone <your-repo-url> l2tp
cd l2tp
```

## Step 2: Configure Environment

```bash
# Copy example env file
cp .env.example .env

# Edit with your settings
nano .env
```

**Required changes:**
- Set `PSK` to a strong random key (save this - you'll need it for clients)
- Set `VPN_SERVER_IP` to your Collify VPS public IP
- Adjust `VPN_SUBNET` and `VPN_IP_RANGE` if needed

## Step 3: Configure Users

Edit `config/chap-secrets`:
```bash
nano config/chap-secrets
```

Add your users (billing VPS, MikroTik routers):
```
billingvps  L2TP-VPN  YourPassword123  *
mikrotik1   L2TP-VPN  RouterPassword456  *
```

## Step 4: Configure Firewall (if using UFW)

```bash
sudo ufw allow 500/udp
sudo ufw allow 4500/udp
sudo ufw allow 1701/udp
sudo ufw reload
```

## Step 5: Deploy with Docker Compose

```bash
# Build and start
docker-compose up -d --build

# Check status
docker-compose ps

# View logs
docker-compose logs -f
```

## Step 6: Verify Deployment

```bash
# Check IPsec status
docker-compose exec l2tp-server ipsec status

# Check if services are running
docker-compose exec l2tp-server ps aux | grep -E "ipsec|xl2tpd"
```

## Step 7: Test Connection

From your billing VPS or MikroTik router, connect using:
- **Server IP**: Your Collify VPS public IP
- **PSK**: The value you set in `.env`
- **Username/Password**: From `config/chap-secrets`

## Troubleshooting on Collify

### Check Container Logs
```bash
docker-compose logs -f l2tp-server
```

### Restart Services
```bash
docker-compose restart
```

### Verify Ports are Open
```bash
# From another machine
nc -u -v <your-collify-ip> 500
nc -u -v <your-collify-ip> 4500
nc -u -v <your-collify-ip> 1701
```

### Check Network Interface
The startup script auto-detects the main interface. If issues occur:
```bash
docker-compose exec l2tp-server ip route
```

## Collify-Specific Notes

- **Network Mode**: Uses `host` networking mode for proper VPN functionality
- **Privileged Mode**: Required for iptables and network configuration
- **Ports**: Ensure Collify firewall allows UDP 500, 4500, 1701
- **IP Forwarding**: Automatically enabled by the container

## Next Steps

1. Configure your billing VPS as a client (see README.md)
2. Configure MikroTik routers (see README.md)
3. Test connectivity between devices
4. Set up monitoring/logging if needed

---

**Your L2TP/IPsec VPN server is now running on Collify!** 🎉
