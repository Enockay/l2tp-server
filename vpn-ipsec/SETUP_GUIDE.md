# IPsec VPN Server Setup Guide

## Quick Setup Flow

### Step 1: Create VPN Configuration File (Optional)

You can either:
- **Option A**: Create a custom `vpn.env` file with your own credentials
- **Option B**: Skip this step and let the system generate random credentials

If you want custom credentials, copy the example file:
```bash
cp vpn.env.example vpn.env
```

Then edit `vpn.env` and uncomment/modify these lines:
```
VPN_IPSEC_PSK=your_secure_pre_shared_key_here
VPN_USER=your_username
VPN_PASSWORD=your_password
```

**Important Notes:**
- DO NOT put `""` or `''` around values
- DO NOT add spaces around `=`
- DO NOT use these characters: `\ " '`
- Use at least 20 random characters for the PSK

### Step 2: Start the VPN Server

Navigate to the repository directory and start the server:

```bash
cd /Users/Enockay/l2tp/vpn-ipsec/docker-ipsec-vpn-server
docker-compose up -d
```

Or if you prefer using `docker run` directly:
```bash
docker run \
    --name ipsec-vpn-server \
    --env-file ./vpn.env \
    --restart=always \
    -v ikev2-vpn-data:/etc/ipsec.d \
    -v /lib/modules:/lib/modules:ro \
    -p 500:500/udp \
    -p 4500:4500/udp \
    -d --privileged \
    hwdsl2/ipsec-vpn-server
```

**Note:** If you don't have a `vpn.env` file, remove the `--env-file ./vpn.env` line from the docker run command.

### Step 3: Retrieve VPN Login Details

View the container logs to get your VPN credentials:

```bash
docker logs ipsec-vpn-server
```

Look for output like this:
```
Connect to your new VPN with these details:

Server IP: your_vpn_server_ip
IPsec PSK: your_ipsec_pre_shared_key
Username: your_vpn_username
Password: your_vpn_password
```

### Step 4: Configure Your Devices

#### For IKEv2 (Recommended - No PSK/Password needed)
1. Check container logs for IKEv2 details
2. Copy the client certificate from container:
   ```bash
   docker cp ipsec-vpn-server:/etc/ipsec.d/vpnclient.p12 ./
   ```
3. Follow device-specific guides:
   - [iOS/macOS](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/ikev2-howto.md)
   - [Android](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/ikev2-howto.md)
   - [Windows](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/ikev2-howto.md)

#### For IPsec/L2TP
- [Client Configuration Guide](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/clients.md)

#### For IPsec/XAuth (Cisco IPsec)
- [Client Configuration Guide](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/clients-xauth.md)

## Important Notes

1. **Firewall**: Make sure UDP ports 500 and 4500 are open on your server
2. **Server IP**: You'll need your server's public IP address for client configuration
3. **Multiple Devices**: The same account can be used on multiple devices
4. **NAT Limitation**: If connecting multiple devices from behind the same NAT, use IKEv2 or IPsec/XAuth mode

## Useful Commands

### Check container status
```bash
docker ps | grep ipsec-vpn-server
```

### View logs
```bash
docker logs ipsec-vpn-server
```

### Stop the server
```bash
docker-compose down
# or
docker stop ipsec-vpn-server
```

### Restart the server
```bash
docker-compose restart
# or
docker restart ipsec-vpn-server
```

### Backup VPN credentials
```bash
docker cp ipsec-vpn-server:/etc/ipsec.d/vpn-gen.env ./
```

### Manage IKEv2 clients
```bash
# Add a new client
docker exec -it ipsec-vpn-server ikev2.sh --addclient client_name

# List clients
docker exec -it ipsec-vpn-server ikev2.sh --listclients

# Export client config
docker exec -it ipsec-vpn-server ikev2.sh --exportclient client_name
```

## Troubleshooting

- If the container won't start, check logs: `docker logs ipsec-vpn-server`
- Ensure Docker has proper permissions
- On macOS, you may need to restart the container once: `docker restart ipsec-vpn-server`
- For Windows clients behind NAT, a registry change may be required

## Next Steps

1. Get your server's public IP address
2. Start the VPN server
3. Retrieve credentials from logs
4. Configure your devices
5. Test the connection

Enjoy your VPN! 🚀
