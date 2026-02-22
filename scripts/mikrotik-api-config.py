#!/usr/bin/env python3
"""
Generate MikroTik RouterOS API script for L2TP client configuration
Can be used with RouterOS API or exported as .rsc file
"""

import sys
import json
import argparse

def generate_mikrotik_config(username, vpn_server_ip, psk, password, vpn_client_ip=None, interface_name=None):
    """Generate MikroTik RouterOS configuration"""
    
    if not interface_name:
        interface_name = f"L2TP-VPN-{username}"
    
    config_lines = [
        f"# L2TP Client Configuration for: {username}",
        f"# Generated automatically",
        "",
        "# Add L2TP client interface",
        f"/interface l2tp-client add \\",
        f"    connect-to={vpn_server_ip} \\",
        f"    name={interface_name} \\",
        f"    user={username} \\",
        f"    password=\"{password}\" \\",
        f"    profile=default-encryption \\",
        f"    use-ipsec=yes \\",
        f"    ipsec-secret=\"{psk}\" \\",
        f"    disabled=no",
        ""
    ]
    
    if vpn_client_ip:
        config_lines.extend([
            f"# Add IP address to L2TP interface",
            f"/ip address add address={vpn_client_ip}/24 interface={interface_name}"
        ])
    else:
        config_lines.extend([
            "# Add IP address (will be assigned by server)",
            f"# /ip address add address=10.10.10.X/24 interface={interface_name}",
            "# Note: Replace X with desired IP (e.g., 10, 11, 12, etc.)"
        ])
    
    return "\n".join(config_lines)


def generate_api_script(username, vpn_server_ip, psk, password, vpn_client_ip=None):
    """Generate RouterOS API script (JSON format)"""
    
    if not vpn_client_ip:
        vpn_client_ip = "10.10.10.10"  # Default
    
    commands = [
        {
            "command": "/interface/l2tp-client/add",
            "params": {
                "connect-to": vpn_server_ip,
                "name": f"L2TP-VPN-{username}",
                "user": username,
                "password": password,
                "profile": "default-encryption",
                "use-ipsec": "yes",
                "ipsec-secret": psk,
                "disabled": "no"
            }
        },
        {
            "command": "/ip/address/add",
            "params": {
                "address": f"{vpn_client_ip}/24",
                "interface": f"L2TP-VPN-{username}"
            }
        }
    ]
    
    return json.dumps(commands, indent=2)


def main():
    parser = argparse.ArgumentParser(description='Generate MikroTik RouterOS L2TP client configuration')
    parser.add_argument('username', help='Username for L2TP client')
    parser.add_argument('vpn_server_ip', help='L2TP server public IP address')
    parser.add_argument('psk', help='Pre-shared key for IPsec')
    parser.add_argument('password', help='Password for L2TP authentication')
    parser.add_argument('--vpn-client-ip', help='VPN client IP address (e.g., 10.10.10.10)')
    parser.add_argument('--format', choices=['rsc', 'api'], default='rsc', 
                       help='Output format: rsc (RouterOS script) or api (JSON API commands)')
    parser.add_argument('--output', help='Output file (default: stdout)')
    
    args = parser.parse_args()
    
    if args.format == 'rsc':
        output = generate_mikrotik_config(
            args.username,
            args.vpn_server_ip,
            args.psk,
            args.password,
            args.vpn_client_ip
        )
    else:
        output = generate_api_script(
            args.username,
            args.vpn_server_ip,
            args.psk,
            args.password,
            args.vpn_client_ip
        )
    
    if args.output:
        with open(args.output, 'w') as f:
            f.write(output)
        print(f"Configuration written to {args.output}")
    else:
        print(output)


if __name__ == '__main__':
    main()
