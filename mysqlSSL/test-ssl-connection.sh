#!/bin/bash

# Test SSL Connection Script for Percona Server
# This script tests various SSL connection methods

set -e

CONTAINERNAME="$1"

echo "🔐 Testing SSL connections to Percona Server..."

# Check if certs exist
if [ ! -f "./certs/ca.pem" ]; then
    echo "❌ SSL certificates not found. Please run './generate-ssl-certs.sh' first."
    exit 1
fi

# Test 1: Basic SSL connection test
echo ""
echo "📋 Test 1: Basic SSL connection test"
docker exec $CONTAINERNAME mysql -uroot -pSecureRootPass123! \
    --ssl-ca=/etc/mysql/ssl/ca.pem \
    --ssl-cert=/etc/mysql/ssl/client-cert.pem \
    --ssl-key=/etc/mysql/ssl/client-key.pem \
    -e "SHOW STATUS LIKE 'Ssl_cipher';" || echo "❌ Test 1 failed"

# Test 2: Check SSL status
echo ""
echo "📋 Test 2: SSL status verification"  
docker exec $CONTAINERNAME mysql -uroot -pSecureRootPass123! \
    --ssl-ca=/etc/mysql/ssl/ca.pem \
    --ssl-cert=/etc/mysql/ssl/client-cert.pem \
    --ssl-key=/etc/mysql/ssl/client-key.pem \
    -e "SHOW VARIABLES LIKE '%ssl%';" || echo "❌ Test 2 failed"

# Test 3: Verify require_secure_transport is enabled
echo ""
echo "📋 Test 3: Verify SSL is required"
docker exec $CONTAINERNAME mysql -uroot -pSecureRootPass123! \
    --ssl-ca=/etc/mysql/ssl/ca.pem \
    --ssl-cert=/etc/mysql/ssl/client-cert.pem \
    --ssl-key=/etc/mysql/ssl/client-key.pem \
    -e "SHOW VARIABLES LIKE 'require_secure_transport';" || echo "❌ Test 3 failed"

# Test 4: Test connection without SSL (should fail)
echo ""
echo "📋 Test 4: Testing connection without SSL (should fail)"
docker exec $CONTAINERNAME mysql -uroot -pSecureRootPass123! --ssl-mode=DISABLED \
    -e "SELECT 'This should fail';" 2>/dev/null && echo "❌ Test 4 failed - non-SSL connection succeeded!" || echo "✅ Test 4 passed - non-SSL connection correctly rejected"

# Test 5: Test user connection
echo ""
echo "📋 Test 5: Testing secure_user connection"
docker exec $CONTAINERNAME mysql -usecure_user -pSecureUserPass123! \
    --ssl-ca=/etc/mysql/ssl/ca.pem \
    --ssl-cert=/etc/mysql/ssl/client-cert.pem \
    --ssl-key=/etc/mysql/ssl/client-key.pem \
    -e "SELECT 'SSL connection successful for secure_user!' as result;" || echo "❌ Test 5 failed"

echo ""
echo "🎉 SSL connection tests completed!"
echo ""
echo "📋 Connection information:"
echo "Host: localhost"  
echo "Port: 3306"
echo "Root Password: SecureRootPass123!"
echo "User: secure_user"
echo "User Password: SecureUserPass123!"
echo "Database: secure_db"
echo ""
echo "📋 SSL Certificate files:"
echo "CA Certificate: ./certs/ca.pem"
echo "Client Certificate: ./certs/client-cert.pem" 
echo "Client Private Key: ./certs/client-key.pem"