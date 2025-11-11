#!/bin/bash

# SSL Certificate Generation Script for Percona Server
# This script generates CA certificate, server certificate, and client certificate

set -e

CERTS_DIR="./certs"
MYSQL_HOST="dbmon01.example.com"

echo "🔐 Generating SSL certificates for Percona Server..."

# Create certs directory if it doesn't exist
mkdir -p ${CERTS_DIR}
cd ${CERTS_DIR}

# Generate CA private key
echo "📝 Generating CA private key..."
openssl genpkey -algorithm RSA -out ca-key.pem -pkeyopt rsa_keygen_bits:4096

# Generate CA certificate
echo "📝 Generating CA certificate..."
openssl req -new -x509 -key ca-key.pem -out ca.pem -days 3650 -subj "/C=US/ST=CA/L=San Francisco/O=Percona SSL CA/CN=Percona SSL CA"

# Generate server private key
echo "📝 Generating server private key..."
openssl genpkey -algorithm RSA -out server-key.pem -pkeyopt rsa_keygen_bits:4096

# Generate server certificate request
echo "📝 Generating server certificate request..."
openssl req -new -key server-key.pem -out server-req.pem -subj "/C=US/ST=CA/L=San Francisco/O=Percona Server/CN=${MYSQL_HOST}"

# Generate server certificate signed by CA
echo "📝 Generating server certificate..."
openssl x509 -req -in server-req.pem -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out server-cert.pem -days 3650

# Generate client private key
echo "📝 Generating client private key..."
openssl genpkey -algorithm RSA -out client-key.pem -pkeyopt rsa_keygen_bits:4096

# Generate client certificate request
echo "📝 Generating client certificate request..."
openssl req -new -key client-key.pem -out client-req.pem -subj "/C=US/ST=CA/L=San Francisco/O=Percona Client/CN=client"

# Generate client certificate signed by CA
echo "📝 Generating client certificate..."
openssl x509 -req -in client-req.pem -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out client-cert.pem -days 3650

# Set proper permissions for MySQL (UID 999)
echo "🔐 Setting proper file permissions..."
chmod 600 *.pem
chown 999:999 *.pem 2>/dev/null || echo "⚠️  Note: Could not change ownership to 999:999. Run 'sudo chown 999:999 certs/*.pem' if needed."

# Clean up certificate requests
rm -f server-req.pem client-req.pem

echo "✅ SSL certificates generated successfully!"
echo ""
echo "Generated files:"
echo "- ca.pem (CA certificate)"
echo "- ca-key.pem (CA private key)"
echo "- server-cert.pem (Server certificate)"
echo "- server-key.pem (Server private key)"
echo "- client-cert.pem (Client certificate)"  
echo "- client-key.pem (Client private key)"
echo ""
echo "🚀 You can now run 'docker compose up' to start Percona Server with SSL!"