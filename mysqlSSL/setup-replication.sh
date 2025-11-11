#!/bin/bash

echo "🔧 Setting up MySQL Replication with SSL..."

# Wait for primary to be ready
echo "⏳ Waiting for primary (dbmon01) to be ready..."
sleep 10

# Reset binary logs on primary to start fresh
echo "🔄 Resetting binary logs on primary..."
docker exec dbmon01.example.com mysql -uroot -p"${MYSQL_ROOT_PASSWORD:-SecureRootPass123!}" \
  --ssl-ca=/etc/mysql/ssl/ca.pem \
  --ssl-cert=/etc/mysql/ssl/client-cert.pem \
  --ssl-key=/etc/mysql/ssl/client-key.pem \
  -e "RESET BINARY LOGS AND GTIDS;"

# Create replication user on primary
echo "👤 Creating replication user on primary..."
docker exec dbmon01.example.com mysql -uroot -p"${MYSQL_ROOT_PASSWORD:-SecureRootPass123!}" \
  --ssl-ca=/etc/mysql/ssl/ca.pem \
  --ssl-cert=/etc/mysql/ssl/client-cert.pem \
  --ssl-key=/etc/mysql/ssl/client-key.pem \
  -e "CREATE USER IF NOT EXISTS 'repl'@'%' IDENTIFIED BY 'ReplPassword123!' REQUIRE SSL;
      GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%';
      FLUSH PRIVILEGES;"

# Create monitor user for ProxySQL on both servers
echo "👤 Creating monitor user for ProxySQL..."
for host in dbmon01.example.com dbmon02.example.com; do
  docker exec $host mysql -uroot -p"${MYSQL_ROOT_PASSWORD:-SecureRootPass123!}" \
    --ssl-ca=/etc/mysql/ssl/ca.pem \
    --ssl-cert=/etc/mysql/ssl/client-cert.pem \
    --ssl-key=/etc/mysql/ssl/client-key.pem \
    -e "CREATE USER IF NOT EXISTS 'monitor'@'%' IDENTIFIED BY 'monitor' REQUIRE SSL;
        GRANT USAGE, REPLICATION CLIENT ON *.* TO 'monitor'@'%';
        FLUSH PRIVILEGES;" 2>/dev/null || true
done

# Configure replication on replica
echo "🔄 Configuring replication on replica (dbmon02)..."
docker exec dbmon02.example.com mysql -uroot -p"${MYSQL_ROOT_PASSWORD:-SecureRootPass123!}" \
  --ssl-ca=/etc/mysql/ssl/ca.pem \
  --ssl-cert=/etc/mysql/ssl/client-cert.pem \
  --ssl-key=/etc/mysql/ssl/client-key.pem \
  -e "CHANGE REPLICATION SOURCE TO
      SOURCE_HOST='dbmon01.example.com',
      SOURCE_USER='repl',
      SOURCE_PASSWORD='ReplPassword123!',
      SOURCE_PORT=3306,
      SOURCE_AUTO_POSITION=1,
      SOURCE_SSL=1,
      SOURCE_SSL_CA='/etc/mysql/ssl/ca.pem',
      SOURCE_SSL_CERT='/etc/mysql/ssl/client-cert.pem',
      SOURCE_SSL_KEY='/etc/mysql/ssl/client-key.pem',
      SOURCE_SSL_VERIFY_SERVER_CERT=0;
      START REPLICA;"

# Check replication status
echo "📊 Checking replication status..."
sleep 5
docker exec dbmon02.example.com mysql -uroot -p"${MYSQL_ROOT_PASSWORD:-SecureRootPass123!}" \
  --ssl-ca=/etc/mysql/ssl/ca.pem \
  --ssl-cert=/etc/mysql/ssl/client-cert.pem \
  --ssl-key=/etc/mysql/ssl/client-key.pem \
  -e "SHOW REPLICA STATUS\G"

echo "✅ Replication setup complete!"
echo ""
echo "📝 Access information:"
echo "  Primary (dbmon01): localhost:3306"
echo "  Replica (dbmon02): localhost:3307"
echo "  ProxySQL MySQL:    localhost:6033"
echo "  ProxySQL Admin:    localhost:6032 (admin:admin)"
