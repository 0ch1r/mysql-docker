#!/bin/bash

echo "🔧 Setting up MySQL Replication with SSL..."

# Wait for primary to be ready
echo "⏳ Waiting for primary (s01) to be ready..."
sleep 10

# Reset binary logs on primary to start fresh
echo "🔄 Resetting binary logs on primary..."
docker exec s01.example.com mysql -uroot -p"${MYSQL_ROOT_PASSWORD:-SecureRootPass123!}" \
  --ssl-ca=/etc/mysql/ssl/ca.pem \
  --ssl-cert=/etc/mysql/ssl/client-cert.pem \
  --ssl-key=/etc/mysql/ssl/client-key.pem \
  -e "RESET BINARY LOGS AND GTIDS;"

docker exec s02.example.com mysql -uroot -p"${MYSQL_ROOT_PASSWORD:-SecureRootPass123!}" \
  --ssl-ca=/etc/mysql/ssl/ca.pem \
  --ssl-cert=/etc/mysql/ssl/client-cert.pem \
  --ssl-key=/etc/mysql/ssl/client-key.pem \
  -e "RESET BINARY LOGS AND GTIDS;"

# Create replication user on primary
echo "👤 Creating replication user on primary..."
docker exec s01.example.com mysql -uroot -p"${MYSQL_ROOT_PASSWORD:-SecureRootPass123!}" \
  --ssl-ca=/etc/mysql/ssl/ca.pem \
  --ssl-cert=/etc/mysql/ssl/client-cert.pem \
  --ssl-key=/etc/mysql/ssl/client-key.pem \
  -e "CREATE USER IF NOT EXISTS 'repl01'@'%' IDENTIFIED BY 'ReplPassword123!' REQUIRE SSL;
      GRANT REPLICATION SLAVE ON *.* TO 'repl01'@'%';
      FLUSH PRIVILEGES;"

docker exec s02.example.com mysql -uroot -p"${MYSQL_ROOT_PASSWORD:-SecureRootPass123!}" \
  --ssl-ca=/etc/mysql/ssl/ca.pem \
  --ssl-cert=/etc/mysql/ssl/client-cert.pem \
  --ssl-key=/etc/mysql/ssl/client-key.pem \
  -e "CREATE USER IF NOT EXISTS 'repl02'@'%' IDENTIFIED BY 'ReplPassword123!' REQUIRE SSL;
      GRANT REPLICATION SLAVE ON *.* TO 'repl02'@'%';
      FLUSH PRIVILEGES;"

# Configure replication on replica
echo "🔄 Configuring replication on replica (r01)..."
docker exec r01.example.com mysql -uroot -p"${MYSQL_ROOT_PASSWORD:-SecureRootPass123!}" \
  --ssl-ca=/etc/mysql/ssl/ca.pem \
  --ssl-cert=/etc/mysql/ssl/client-cert.pem \
  --ssl-key=/etc/mysql/ssl/client-key.pem \
  -e "CHANGE REPLICATION SOURCE TO
      SOURCE_HOST='s01.example.com',
      SOURCE_USER='repl01',
      SOURCE_PASSWORD='ReplPassword123!',
      SOURCE_PORT=3306,
      SOURCE_AUTO_POSITION=1,
      SOURCE_SSL=1,
      SOURCE_SSL_CA='/etc/mysql/ssl/ca.pem',
      SOURCE_SSL_CERT='/etc/mysql/ssl/client-cert.pem',
      SOURCE_SSL_KEY='/etc/mysql/ssl/client-key.pem',
      SOURCE_SSL_VERIFY_SERVER_CERT=0
      FOR CHANNEL 'ch01';
      START REPLICA;"

docker exec r01.example.com mysql -uroot -p"${MYSQL_ROOT_PASSWORD:-SecureRootPass123!}" \
  --ssl-ca=/etc/mysql/ssl/ca.pem \
  --ssl-cert=/etc/mysql/ssl/client-cert.pem \
  --ssl-key=/etc/mysql/ssl/client-key.pem \
  -e "CHANGE REPLICATION SOURCE TO
      SOURCE_HOST='s02.example.com',
      SOURCE_USER='repl02',
      SOURCE_PASSWORD='ReplPassword123!',
      SOURCE_PORT=3306,
      SOURCE_AUTO_POSITION=1,
      SOURCE_SSL=1,
      SOURCE_SSL_CA='/etc/mysql/ssl/ca.pem',
      SOURCE_SSL_CERT='/etc/mysql/ssl/client-cert.pem',
      SOURCE_SSL_KEY='/etc/mysql/ssl/client-key.pem',
      SOURCE_SSL_VERIFY_SERVER_CERT=0
      FOR CHANNEL 'ch02';
      START REPLICA;"

# Check replication status
echo "📊 Checking replication status..."
sleep 5
docker exec r01.example.com mysql -uroot -p"${MYSQL_ROOT_PASSWORD:-SecureRootPass123!}" \
  --ssl-ca=/etc/mysql/ssl/ca.pem \
  --ssl-cert=/etc/mysql/ssl/client-cert.pem \
  --ssl-key=/etc/mysql/ssl/client-key.pem \
  -e "SHOW REPLICA STATUS FOR CHANNEL 'ch01'\G"

docker exec r01.example.com mysql -uroot -p"${MYSQL_ROOT_PASSWORD:-SecureRootPass123!}" \
  --ssl-ca=/etc/mysql/ssl/ca.pem \
  --ssl-cert=/etc/mysql/ssl/client-cert.pem \
  --ssl-key=/etc/mysql/ssl/client-key.pem \
  -e "SHOW REPLICA STATUS FOR CHANNEL 'ch02'\G"

echo "✅ Replication setup complete!"
echo ""
echo "📝 Access information:"
echo "  Primary (s01): localhost:3306"
echo "  Primary (s02): localhost:3307"
echo "  Replica (r02): localhost:3308"
