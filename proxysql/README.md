# ProxySQL with High Availability MySQL Setup

This setup provides a Docker Compose environment for testing ProxySQL with three MySQL servers in a high-availability configuration. The deployment includes ProxySQL as a database proxy with a master-replica MySQL architecture.

## 📁 Directory Structure

```
proxysql/
├── docker-compose.yml       # Main Docker Compose configuration
├── .env                     # Environment variables
├── start-services.sh        # Script for starting services with health checks
├── conf/
│   ├── mysql/               # MySQL configuration files
│   │   ├── mysqld1.cnf      # MySQL 1 configuration
│   │   ├── mysqld2.cnf      # MySQL 2 configuration
│   │   └── mysqld3.cnf      # MySQL 3 configuration
│   └── proxysql/            # ProxySQL configuration
└── scripts/                 # MySQL setup scripts
    ├── mysql-primary.sh     # Primary server setup
    └── mysql-replicas.sh   # Replica servers setup
```

## 🚀 Quick Start

1. **Start all services:**
   ```bash
   chmod +x start-services.sh
   ./start-services.sh
   ```

2. **Check service status:**
   ```bash
   docker compose ps
   ```

3. **Test ProxySQL connection:**
   ```bash
   mysql -h 127.0.0.1 -P 6033 -u admin -padmin -e "SELECT 1"
   ```

4. **Connect to ProxySQL admin interface:**
   ```bash
   mysql -h 127.0.0.1 -P 6032 -u admin -padmin
   ```

## 🐳 Services Overview

### Database Servers

- **mysql1**: Primary MySQL server (no port mapping)
  - Container name: mysql1
  - Runs Percona Server 8.0
  - Configured as the primary/master server

- **mysql2**: MySQL replica server (no port mapping)
  - Container name: mysql2
  - Replicates from mysql1
  - Read-only configuration

- **mysql3**: MySQL replica server (no port mapping)
  - Container name: mysql3
  - Replicates from mysql1
  - Read-only configuration

### ProxySQL

- **proxysql**: Database proxy (ports mapped)
  - MySQL Protocol: 6033 (for application connections)
  - Admin Interface: 6032 (for ProxySQL management)
  - Default admin credentials: admin/admin
  - Automatically routes queries based on configuration

## 🔧 Configuration

### Environment Variables

Update the `.env` file to customize your deployment:

```bash
# Passwords
MYSQL_ROOT_PASSWORD=root_password
MYSQL_PASSWORD=password

# Container versions
PROXYSQL_IMAGE=proxysql/proxysql:latest
IMAGE_NAME=percona/percona-server:8.0
```

### MySQL Configuration

The MySQL configuration files include:
- Binary logging for replication
- Server IDs setup
- General query logging
- GTID mode for replication

### ProxySQL Configuration

The ProxySQL configuration (`conf/proxysql/proxysql.cnf`) includes:
- Hostgroup definitions (writers and readers)
- Query routing rules
- Monitor settings
- Backend server configuration

## 📊 ProxySQL Features

ProxySQL provides several useful features:

- **Connection Pooling**: Efficient management of MySQL connections
- **Query Routing**: Directs queries to appropriate servers
- **Failover Detection**: Automatically handles server failures
- **Query Caching**: Cache frequent queries for better performance
- **Read/Write Splitting**: Routes writes to primary and reads to replicas

## 🎯 Accessing Services

### Connect Through ProxySQL

```bash
# Connect via ProxySQL (application port)
mysql -h 127.0.0.1 -P 6033 -u admin -padmin

# This will route queries to the appropriate backend servers
```

### ProxySQL Admin Interface

```bash
# Connect to ProxySQL admin interface
mysql -h 127.0.0.1 -P 6032 -u admin -padmin

# Once connected, you can:
SHOW DATABASES;
SHOW TABLES FROM main;
SELECT * FROM main.mysql_servers;
```

### Direct MySQL Connections

```bash
# Connect to MySQL primary directly
docker compose exec mysql1 mysql -uroot -p

# Create test data
CREATE DATABASE testdb;
USE testdb;
CREATE TABLE test_table (id INT PRIMARY KEY, name VARCHAR(50));
INSERT INTO test_table VALUES (1, 'test');
```

## 🔄 Monitoring and Management

### ProxySQL Statistics

```sql
-- Check server status
SELECT * FROM main.mysql_servers;

-- Check query statistics
SELECT * FROM main.stats_mysql_query_digest;

-- Check connection pool stats
SELECT * FROM main.stats_mysql_connection_pool;

-- Check overall health
SELECT * FROM main.mysql_server_connect_time;
```

### Replication Status

```bash
# Check replication status on replicas
docker compose exec mysql2 mysql -uroot -p -e "SHOW SLAVE STATUS\G"
docker compose exec mysql3 mysql -uroot -p -e "SHOW SLAVE STATUS\G"
```

## 🛠 Customization

### Modifying Server Configuration

1. Edit `conf/proxysql/proxysql.cnf` for ProxySQL settings
2. Edit `conf/mysql/mysqld[1-3].cnf` for MySQL settings
3. Restart services: `docker compose restart`

### Adding New Monitoring Rules

Add custom monitoring rules to ProxySQL admin:

```sql
-- Add query rules
INSERT INTO main.mysql_query_rules (
  rule_id, 
  active, 
  match_pattern, 
  destination_hostgroup,
  apply
) VALUES (
  1, 
  'ACTIVE', 
  '^SELECT.*testdb', 
  10, 
  1
);

-- Apply changes to runtime
LOAD MYSQL QUERY RULES TO RUNTIME;
SAVE MYSQL QUERY RULES TO DISK;
```

## 🔄 Rebuilding

To reset and rebuild the environment:

```bash
# Stop all services
docker compose down

# Remove volumes (注意: This will delete all data)
docker compose down -v

# Start again
./start-services.sh
```

## 🔧 Troubleshooting

### Checking Logs

```bash
# Check all container logs
docker compose logs

# Check specific service logs
docker compose logs proxysql
docker compose logs mysql1
```

### Common Issues

1. **ProxySQL cannot connect to MySQL servers**:
   - Check MySQL servers are running
   - Verify network connectivity
   - Confirm MySQL credentials

2. **Replication not working**:
   - Verify binary logs are enabled on primary
   - Check server IDs are unique
   - Ensure replica configuration is correct

3. **Queries not routing properly**:
   - Check query routing rules in ProxySQL
   - Verify hostgroup configuration
   - Monitor query statistics

## 📚 References

- [ProxySQL Documentation](https://proxysql.com/documentation/)
- [ProxySQL GitHub Repository](https://github.com/sysown/proxysql)
- [MySQL Replication Documentation](https://dev.mysql.com/doc/refman/8.0/en/replication.html)
