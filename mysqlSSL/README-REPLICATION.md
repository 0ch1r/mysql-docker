# MySQL Replication with ProxySQL and SSL

This setup includes:
- **dbmon01**: Primary MySQL server with SSL (port 3306)
- **dbmon02**: Replica MySQL server with SSL (port 3307)
- **ProxySQL**: Load balancer with SSL connections to backends (ports 6033, 6032)

## Architecture

```
                    ┌─────────────────┐
                    │   ProxySQL      │
                    │   (Port 6033)   │
                    └────────┬────────┘
                             │
                ┌────────────┴────────────┐
                │                         │
                │ SSL                     │ SSL
                │                         │
        ┌───────▼─────────┐       ┌──────▼──────────┐
        │    dbmon01      │──────▶│    dbmon02      │
        │   (Primary)     │  SSL  │   (Replica)     │
        │   Port 3306     │ Repl  │   Port 3307     │
        └─────────────────┘       └─────────────────┘
```

## Quick Start

1. **Start the MySQL containers** (without ProxySQL):
   ```bash
   docker compose up -d
   ```

2. **Wait for the services to be healthy** (check with `docker compose ps`)

3. **Setup replication**:
   ```bash
   ./setup-replication.sh
   ```

4. **Start ProxySQL** (after replication is configured):
   ```bash
   docker compose --profile proxysql up -d
   ```

## Configuration Details

### MySQL Primary (dbmon01)
- **Server ID**: 1
- **GTID**: Enabled
- **Binary Logging**: Enabled
- **SSL**: Required for all connections
- **Port**: 3306 (host), 3306 (container)

### MySQL Replica (dbmon02)
- **Server ID**: 2
- **GTID**: Enabled
- **Binary Logging**: Enabled
- **Read-Only**: Enabled
- **SSL**: Required for all connections
- **Port**: 3307 (host), 3306 (container)
- **Replicates from**: dbmon01 via SSL

### ProxySQL
- **Profile**: `proxysql` (started separately)
- **MySQL Interface**: Port 6033
- **Admin Interface**: Port 6032
- **Backend SSL**: Enabled with client certificates
- **Query Routing**:
  - `SELECT` queries → dbmon02 (reader hostgroup 1)
  - `SELECT ... FOR UPDATE` → dbmon01 (writer hostgroup 0)
  - All other queries → dbmon01 (writer hostgroup 0)

## Connecting to Services

### Connect to Primary directly
```bash
mysql -h 127.0.0.1 -P 3306 -u secure_user -p \
  --ssl-ca=./certs/ca.pem \
  --ssl-cert=./certs/client-cert.pem \
  --ssl-key=./certs/client-key.pem
```

### Connect to Replica directly
```bash
mysql -h 127.0.0.1 -P 3307 -u secure_user -p \
  --ssl-ca=./certs/ca.pem \
  --ssl-cert=./certs/client-cert.pem \
  --ssl-key=./certs/client-key.pem
```

### Connect via ProxySQL
```bash
mysql -h 127.0.0.1 -P 6033 -u secure_user -p
```

### ProxySQL Admin Interface
```bash
mysql -h 127.0.0.1 -P 6032 -u admin -padmin
```

## Verification Commands

### Check Replication Status
```bash
docker exec dbmon02.example.com mysql -uroot -pSecureRootPass123! \
  --ssl-ca=/etc/mysql/ssl/ca.pem \
  --ssl-cert=/etc/mysql/ssl/client-cert.pem \
  --ssl-key=/etc/mysql/ssl/client-key.pem \
  -e "SHOW REPLICA STATUS\G"
```

### Check SSL Connection
```bash
docker exec dbmon01.example.com mysql -uroot -pSecureRootPass123! \
  --ssl-ca=/etc/mysql/ssl/ca.pem \
  --ssl-cert=/etc/mysql/ssl/client-cert.pem \
  --ssl-key=/etc/mysql/ssl/client-key.pem \
  -e "SHOW STATUS LIKE 'Ssl_cipher';"
```

### Check ProxySQL Backend Status
```bash
mysql -h 127.0.0.1 -P 6032 -u admin -padmin \
  -e "SELECT * FROM mysql_servers;"
```

### Monitor ProxySQL Query Routing
```bash
mysql -h 127.0.0.1 -P 6032 -u admin -padmin \
  -e "SELECT * FROM stats_mysql_query_rules;"
```

## Testing Replication

1. **Create test data on primary**:
   ```bash
   mysql -h 127.0.0.1 -P 3306 -u secure_user -pSecureUserPass123! \
     --ssl-ca=./certs/ca.pem \
     --ssl-cert=./certs/client-cert.pem \
     --ssl-key=./certs/client-key.pem \
     -e "CREATE TABLE secure_db.test (id INT PRIMARY KEY, data VARCHAR(100));
         INSERT INTO secure_db.test VALUES (1, 'Replicated data');"
   ```

2. **Verify on replica**:
   ```bash
   mysql -h 127.0.0.1 -P 3307 -u secure_user -pSecureUserPass123! \
     --ssl-ca=./certs/ca.pem \
     --ssl-cert=./certs/client-cert.pem \
     --ssl-key=./certs/client-key.pem \
     -e "SELECT * FROM secure_db.test;"
   ```

3. **Test via ProxySQL** (reads should go to replica):
   ```bash
   mysql -h 127.0.0.1 -P 6033 -u secure_user -pSecureUserPass123! \
     -e "SELECT * FROM secure_db.test;"
   ```

## Troubleshooting

### Check container logs
```bash
docker compose logs dbmon01
docker compose logs dbmon02
docker compose logs proxysql
```

### Restart replication
```bash
docker exec dbmon02.example.com mysql -uroot -pSecureRootPass123! \
  --ssl-ca=/etc/mysql/ssl/ca.pem \
  --ssl-cert=/etc/mysql/ssl/client-cert.pem \
  --ssl-key=/etc/mysql/ssl/client-key.pem \
  -e "STOP REPLICA; START REPLICA;"
```

### Reset replication (if needed)
```bash
docker exec dbmon02.example.com mysql -uroot -pSecureRootPass123! \
  --ssl-ca=/etc/mysql/ssl/ca.pem \
  --ssl-cert=/etc/mysql/ssl/client-cert.pem \
  --ssl-key=/etc/mysql/ssl/client-key.pem \
  -e "STOP REPLICA; RESET REPLICA ALL;"
```

Then run `./setup-replication.sh` again.

## Default Credentials

- **MySQL root**: SecureRootPass123!
- **MySQL user**: secure_user / SecureUserPass123!
- **Replication user**: repl / ReplPassword123!
- **ProxySQL admin**: admin / admin
- **ProxySQL monitor**: monitor / monitor

**⚠️ WARNING**: Change these passwords in production!

## Managing Services

### Start only MySQL servers
```bash
docker compose up -d
```

### Start ProxySQL separately
```bash
docker compose --profile proxysql up -d
```

### Stop ProxySQL only
```bash
docker compose --profile proxysql stop proxysql
```

### Stop all services
```bash
docker compose --profile proxysql down
# or just
docker compose down
```

## Cleanup

```bash
docker compose --profile proxysql down -v
rm -rf data data-replica logs logs-replica proxysql-data
```
