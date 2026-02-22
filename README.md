# L2TP/IPsec VPN Server for Docker

A containerized L2TP/IPsec VPN server ready to deploy on Collify or any Docker-compatible platform. This setup allows your billing VPS and MikroTik routers to connect securely over an L2TP/IPsec VPN tunnel.

## Features

- ✅ Full L2TP/IPsec VPN server with strongSwan and xl2tpd
- ✅ Docker Compose ready for easy deployment
- ✅ Environment variable configuration
- ✅ Automatic IP forwarding and iptables setup
- ✅ Health checks and auto-restart
- ✅ Compatible with MikroTik routers and Linux clients

## Prerequisites

- Docker and Docker Compose installed
- A VPS/server with a public IP address (e.g., Collify)
- Root or sudo access (for privileged mode)
- UDP ports 500, 4500, and 1701 open in firewall

## Quick Start

### 1. Clone and Configure

```bash
# Copy the example environment file
cp .env.example .env

# Edit .env with your settings
nano .env
```

**Important:** Update these values in `.env`:
- `PSK`: Set a strong pre-shared key (must match all clients)
- `VPN_SERVER_IP`: Your VPS public IP address (optional but recommended)
- `VPN_SUBNET`: VPN subnet (default: 10.10.10.0/24)
- `VPN_IP_RANGE`: IP range for clients (default: 10.10.10.2-10.10.10.100)

### 2. Configure User Credentials

Edit `config/chap-secrets` to add your users:

```
# Format: username  server  password  IP
billingvps  L2TP-VPN  YourStrongPassword  *
mikrotik1   L2TP-VPN  AnotherStrongPassword  *
mikrotik2   L2TP-VPN  YetAnotherPassword  *
```

### 3. Build and Start

```bash
# Build the image
docker-compose build

# Start the server
docker-compose up -d

# View logs
docker-compose logs -f
```

### 4. Verify Services

```bash
# Check container status
docker-compose ps

# Check IPsec status
docker-compose exec l2tp-server ipsec status

# Check xl2tpd
docker-compose exec l2tp-server ps aux | grep xl2tpd
```

## Configuration Files

- `config/ipsec.conf` - IPsec (strongSwan) configuration
- `config/ipsec.secrets` - Pre-shared key (auto-updated from .env)
- `config/xl2tpd.conf` - L2TP daemon configuration
- `config/options.xl2tpd` - PPP options for L2TP
- `config/chap-secrets` - User authentication credentials

## Client Configuration

### Billing VPS (Linux Client)

Install required packages:
```bash
sudo apt install xl2tpd ppp strongswan -y
```

Create `/etc/ipsec.conf`:
```
config setup

conn L2TP-CLIENT
    authby=secret
    auto=start
    keyexchange=ikev1
    ike=aes256-sha1-modp1024
    esp=aes256-sha1
    left=%defaultroute
    leftid=@billingvps
    right=<YOUR_VPS_PUBLIC_IP>
    rightsubnet=0.0.0.0/0
    type=transport
```

Create `/etc/ipsec.secrets`:
```
billingvps : PSK "YourStrongPreSharedKeyHere"
```

Create `/etc/xl2tpd/xl2tpd.conf`:
```
[lac billingvps]
lns = <YOUR_VPS_PUBLIC_IP>
ppp debug = no
pppoptfile = /etc/ppp/options.l2tpd.client
length bit = yes
```

Create `/etc/ppp/options.l2tpd.client`:
```
name billingvps
password YourStrongPassword
remotename billingvps
unit 0
lock
noauth
nodefaultroute
debug
```

Start services:
```bash
sudo systemctl restart strongswan
sudo systemctl restart xl2tpd
```

### MikroTik Router Configuration

In RouterOS (v7), run:

```
/interface l2tp-client add \
    connect-to=<YOUR_VPS_PUBLIC_IP> \
    name=L2TP-VPN \
    user=mikrotik1 \
    password=AnotherStrongPassword \
    profile=default-encryption \
    use-ipsec=yes \
    ipsec-secret="YourStrongPreSharedKeyHere" \
    disabled=no

/ip address add address=10.10.10.10/24 interface=L2TP-VPN
```

For multiple MikroTik routers, use different usernames and assign different IPs (e.g., 10.10.10.11, 10.10.10.12, etc.).

## Network Architecture

```
                    Internet
                       |
                  [Collify VPS]
                  (L2TP Server)
                 10.10.10.1/24
                       |
        +--------------+--------------+
        |              |              |
  [Billing VPS]   [MikroTik 1]   [MikroTik 2]
  10.10.10.2     10.10.10.10    10.10.10.11
```

All devices can communicate over the `10.10.10.0/24` VPN subnet.

## Firewall Rules

The container automatically configures iptables, but ensure your VPS firewall allows:

- **UDP 500** - IKE (IPsec key exchange)
- **UDP 4500** - NAT-T (IPsec NAT traversal)
- **UDP 1701** - L2TP

For UFW (Ubuntu):
```bash
sudo ufw allow 500/udp
sudo ufw allow 4500/udp
sudo ufw allow 1701/udp
```

## Coexistence with WireGuard

✅ **Yes, L2TP and WireGuard can run on the same VPS!**

- L2TP uses UDP ports: 500, 4500, 1701
- WireGuard uses UDP port: 51820 (or custom)
- No port conflicts
- Both can run simultaneously

## Troubleshooting

### Check Logs
```bash
# Container logs
docker-compose logs -f l2tp-server

# IPsec logs
docker-compose exec l2tp-server ipsec statusall

# xl2tpd logs
docker-compose exec l2tp-server tail -f /var/log/xl2tpd.log
```

### Common Issues

1. **Connection fails**: Verify PSK matches on server and client
2. **No IP assigned**: Check `chap-secrets` file format
3. **Can't ping**: Verify iptables rules and IP forwarding
4. **Port conflicts**: Ensure ports 500, 4500, 1701 are not in use

### Test Connectivity

From billing VPS:
```bash
ping 10.10.10.1  # Ping VPN server
ping 10.10.10.10 # Ping MikroTik router
```

From MikroTik:
```
/ping 10.10.10.1
/ping 10.10.10.2
```

## Security Notes

⚠️ **Important Security Considerations:**

1. **Change default passwords** in `chap-secrets`
2. **Use a strong PSK** (at least 32 random characters)
3. **Limit access** to trusted IPs if possible
4. **Keep Docker updated** for security patches
5. **Monitor logs** for unauthorized connection attempts

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `VPN_SERVER_IP` | (empty) | Public IP or hostname of VPN server |
| `VPN_SUBNET` | `10.10.10.0/24` | VPN subnet in CIDR notation |
| `VPN_IP_RANGE` | `10.10.10.2-10.10.10.100` | IP range for VPN clients |
| `VPN_LOCAL_IP` | `10.10.10.1` | VPN server gateway IP |
| `PSK` | `ChangeThisPreSharedKey` | Pre-shared key for IPsec |
| `DNS1` | `8.8.8.8` | Primary DNS for clients |
| `DNS2` | `8.8.4.4` | Secondary DNS for clients |

## Maintenance

### Restart Services
```bash
docker-compose restart
```

### Update Configuration
```bash
# Edit config files
nano config/chap-secrets

# Rebuild and restart
docker-compose up -d --build
```

### Stop Server
```bash
docker-compose down
```

## License

This project is provided as-is for VPN server deployment.

## Support

For issues or questions:
1. Check logs: `docker-compose logs -f`
2. Verify configuration files
3. Test network connectivity
4. Review firewall rules

---

**Ready to deploy!** 🚀
