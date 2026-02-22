#!/usr/bin/env python3
"""
REST API endpoint to add L2TP users programmatically
Can be used with webhooks, automation, or API calls
"""

import os
import sys
import json
import re
from pathlib import Path
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs
import secrets
import string

# Configuration
CHAP_SECRETS_FILE = os.getenv('CHAP_SECRETS_FILE', 'config/chap-secrets')
SERVER_NAME = os.getenv('SERVER_NAME', 'L2TP-VPN')
API_TOKEN = os.getenv('API_TOKEN', '')  # Set this for security
API_PORT = int(os.getenv('API_PORT', '8080'))


def generate_password(length=16):
    """Generate a secure random password"""
    alphabet = string.ascii_letters + string.digits + "!@#$%^&*"
    return ''.join(secrets.choice(alphabet) for _ in range(length))


def validate_username(username):
    """Validate username format"""
    if not username or len(username) < 3:
        return False, "Username must be at least 3 characters"
    if not re.match(r'^[a-zA-Z0-9_-]+$', username):
        return False, "Username must be alphanumeric (may include underscore and dash)"
    return True, None


def add_user(username, password=None, ip_address='*'):
    """Add a user to chap-secrets file"""
    # Validate username
    valid, error = validate_username(username)
    if not valid:
        return False, error
    
    # Generate password if not provided
    if not password:
        password = generate_password()
    
    # Ensure file exists with header
    secrets_file = Path(CHAP_SECRETS_FILE)
    if not secrets_file.exists():
        secrets_file.parent.mkdir(parents=True, exist_ok=True)
        with open(secrets_file, 'w') as f:
            f.write("# Secrets for authentication using CHAP\n")
            f.write("# client    server      secret      IP addresses\n")
            f.write("# username  server-name password    IP\n")
    
    # Check if user exists
    existing_users = []
    user_exists = False
    if secrets_file.exists():
        with open(secrets_file, 'r') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#'):
                    parts = line.split()
                    if len(parts) >= 3 and parts[0] == username:
                        user_exists = True
                    if len(parts) >= 3:
                        existing_users.append(line)
    
    # Remove existing entry if found
    if user_exists:
        existing_users = [line for line in existing_users if not line.startswith(username + '\t') and not line.startswith(username + ' ')]
    
    # Add new entry
    entry = f"{username}\t{SERVER_NAME}\t{password}\t{ip_address}\n"
    existing_users.append(entry.rstrip())
    
    # Write back to file
    with open(secrets_file, 'w') as f:
        f.write("# Secrets for authentication using CHAP\n")
        f.write("# client    server      secret      IP addresses\n")
        f.write("# username  server-name password    IP\n")
        for user_line in existing_users:
            f.write(user_line + '\n')
    
    return True, {"username": username, "password": password, "ip": ip_address}


def remove_user(username):
    """Remove a user from chap-secrets file"""
    secrets_file = Path(CHAP_SECRETS_FILE)
    if not secrets_file.exists():
        return False, "User not found"
    
    lines = []
    user_found = False
    with open(secrets_file, 'r') as f:
        for line in f:
            if line.strip() and not line.strip().startswith('#'):
                parts = line.split()
                if len(parts) >= 3 and parts[0] == username:
                    user_found = True
                    continue
            lines.append(line)
    
    if not user_found:
        return False, "User not found"
    
    with open(secrets_file, 'w') as f:
        f.writelines(lines)
    
    return True, {"username": username, "status": "removed"}


def list_users():
    """List all users"""
    secrets_file = Path(CHAP_SECRETS_FILE)
    if not secrets_file.exists():
        return []
    
    users = []
    with open(secrets_file, 'r') as f:
        for line in f:
            if line.strip() and not line.strip().startswith('#'):
                parts = line.split()
                if len(parts) >= 3:
                    users.append({
                        "username": parts[0],
                        "server": parts[1] if len(parts) > 1 else "",
                        "ip": parts[3] if len(parts) > 3 else "*"
                    })
    return users


class APIHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        """Handle GET requests"""
        parsed_path = urlparse(self.path)
        path = parsed_path.path
        
        # Check authentication
        if API_TOKEN:
            auth_header = self.headers.get('Authorization', '')
            if auth_header != f'Bearer {API_TOKEN}':
                self.send_response(401)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({"error": "Unauthorized"}).encode())
                return
        
        if path == '/users':
            # List users
            users = list_users()
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({"users": users}, indent=2).encode())
        
        elif path == '/health':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({"status": "ok"}).encode())
        
        else:
            self.send_response(404)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({"error": "Not found"}).encode())
    
    def do_POST(self):
        """Handle POST requests"""
        parsed_path = urlparse(self.path)
        path = parsed_path.path
        
        # Check authentication
        if API_TOKEN:
            auth_header = self.headers.get('Authorization', '')
            if auth_header != f'Bearer {API_TOKEN}':
                self.send_response(401)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({"error": "Unauthorized"}).encode())
                return
        
        if path == '/users':
            # Add user
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            
            try:
                data = json.loads(post_data.decode('utf-8'))
                username = data.get('username')
                password = data.get('password')
                ip_address = data.get('ip', '*')
                
                if not username:
                    raise ValueError("Username is required")
                
                success, result = add_user(username, password, ip_address)
                
                if success:
                    self.send_response(201)
                    self.send_header('Content-type', 'application/json')
                    self.end_headers()
                    self.wfile.write(json.dumps({"success": True, "data": result}, indent=2).encode())
                else:
                    self.send_response(400)
                    self.send_header('Content-type', 'application/json')
                    self.end_headers()
                    self.wfile.write(json.dumps({"success": False, "error": result}, indent=2).encode())
            
            except json.JSONDecodeError:
                self.send_response(400)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({"error": "Invalid JSON"}).encode())
            except Exception as e:
                self.send_response(500)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({"error": str(e)}).encode())
        
        elif path == '/users/remove':
            # Remove user
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            
            try:
                data = json.loads(post_data.decode('utf-8'))
                username = data.get('username')
                
                if not username:
                    raise ValueError("Username is required")
                
                success, result = remove_user(username)
                
                if success:
                    self.send_response(200)
                    self.send_header('Content-type', 'application/json')
                    self.end_headers()
                    self.wfile.write(json.dumps({"success": True, "data": result}, indent=2).encode())
                else:
                    self.send_response(404)
                    self.send_header('Content-type', 'application/json')
                    self.end_headers()
                    self.wfile.write(json.dumps({"success": False, "error": result}, indent=2).encode())
            
            except Exception as e:
                self.send_response(500)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({"error": str(e)}).encode())
        
        else:
            self.send_response(404)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({"error": "Not found"}).encode())
    
    def log_message(self, format, *args):
        """Suppress default logging"""
        pass


def main():
    """Start the API server"""
    if not API_TOKEN:
        print("Warning: API_TOKEN not set. API is unsecured!", file=sys.stderr)
        print("Set API_TOKEN environment variable for security.", file=sys.stderr)
    
    server = HTTPServer(('0.0.0.0', API_PORT), APIHandler)
    print(f"L2TP User Management API running on port {API_PORT}")
    print(f"Endpoints:")
    print(f"  GET  /users - List all users")
    print(f"  POST /users - Add a user")
    print(f"  POST /users/remove - Remove a user")
    print(f"  GET  /health - Health check")
    if API_TOKEN:
        print(f"\nAuthentication: Bearer token required")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down server...")
        server.shutdown()


if __name__ == '__main__':
    main()
