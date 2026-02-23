# VPN Server Credentials Reference

**Server IP:** `157.230.159.170`

## IPsec PSK (Shared by all users)
```
AwSc2p9xUgyxtvD2YS5t
```

## VPN Users

### Primary User
- **Username:** `vpnuser`
- **Password:** `Ao2DJ7gX3642T5gY`

### Router 1 - Kitui
- **Username:** `kituiMikrotik`
- **Password:** `Enockay23`
- **Static IP:** `192.168.42.2`

### Router 2 - Chuka
- **Username:** `ChukaMikrotik`
- **Password:** `Enockay23`
- **Static IP:** `192.168.42.3`

### Router 3 - Pius
- **Username:** `piusMikrotik`
- **Password:** `Enockay23`
- **Static IP:** `192.168.42.4`

### Router 4 - Enock
- **Username:** `enockMikrotik`
- **Password:** `Enockay23`
- **Static IP:** `192.168.42.5`

### Billing Server
- **Username:** `billingServer`
- **Password:** `Enockay23`
- **Static IP:** `192.168.42.6`

---

## Important Notes

1. **All users share the same IPsec PSK:** `AwSc2p9xUgyxtvD2YS5t`
2. **Each router should use a different username** to track connections
3. **Keep this file secure** - it contains sensitive credentials
4. **After updating vpn.env, you must recreate the container** for changes to take effect

## How to Apply Changes

If you've updated `vpn.env` and need to apply the changes:

```bash
# Stop and remove the current container
docker-compose down

# Remove the old container (if needed)
docker rm -f ipsec-vpn-server

# Start with new configuration
docker-compose up -d

# Verify credentials
docker logs ipsec-vpn-server
```
