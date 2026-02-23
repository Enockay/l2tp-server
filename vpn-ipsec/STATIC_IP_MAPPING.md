# Static IP Address Mapping

This document shows the static IP addresses assigned to each VPN client for IPsec/L2TP mode.

## VPN Subnet Information

- **VPN Subnet:** `192.168.42.0/24`
- **VPN Server IP:** `192.168.42.1`
- **Client IP Range:** `192.168.42.2` to `192.168.42.9` (static IPs)
- **Auto-assigned Range:** `192.168.42.10` to `192.168.42.250`

## Static IP Assignments

| Router/Server | Username | Static IP Address | Purpose |
|---------------|----------|-------------------|---------|
| Kitui Router | `kituiMikrotik` | `192.168.42.2` | Router 1 |
| Chuka Router | `ChukaMikrotik` | `192.168.42.3` | Router 2 |
| Pius Router | `piusMikrotik` | `192.168.42.4` | Router 3 |
| Enock Router | `enockMikrotik` | `192.168.42.5` | Router 4 |
| Billing Server | `billingServer` | `192.168.42.6` | Billing System |

## How to Use in Billing System

Your billing system can identify which MikroTik router is connecting by checking the source IP address:

- If connection comes from `192.168.42.2` → **Kitui Router**
- If connection comes from `192.168.42.3` → **Chuka Router**
- If connection comes from `192.168.42.4` → **Pius Router**
- If connection comes from `192.168.42.5` → **Enock Router**
- If connection comes from `192.168.42.6` → **Billing Server** (outgoing)

## Important Notes

1. **After updating vpn.env with static IPs, you MUST recreate the container:**
   ```bash
   docker-compose down
   docker rm -f ipsec-vpn-server
   docker-compose up -d
   ```

2. **Each router will always get the same IP** when connecting via L2TP mode

3. **To verify IP assignment:**
   - On MikroTik: Check the L2TP interface IP address
   - On VPN server: Check connection logs or use `ip addr show` inside container

4. **The billing server can identify routers** by checking the source IP of incoming connections
