# Percona Server 8.4 with SSL Required

This setup provides a Docker Compose configuration for running Percona Server 8.4 with **SSL connections required**. All connections to the database must use SSL/TLS encryption.

## 🔐 Features

- **SSL/TLS Required**: All connections must use SSL (enforced by `require_secure_transport=ON`)
- **Percona Server 8.4**: Latest version of Percona Server for MySQL
- **Auto Certificate Generation**: Certificates are generated automatically on first run
- **Custom Configuration**: Optimized MySQL configuration with SSL settings
- **Health Checks**: Built-in health monitoring with SSL
- **Test Scripts**: Included scripts to verify SSL functionality

## 📁 Directory Structure

```
mysqlSSL/
├── docker-compose.yml          # Main Docker Compose configuration
├── .env                        # Environment variables
├── generate-ssl-certs.sh      # Manual certificate generation script
├── test-ssl-connection.sh      # SSL connection testing script
├── README.md                   # This documentation
├── conf/
│   └── mysql-ssl.cnf          # MySQL configuration with SSL settings
├── certs/                      # SSL certificates (auto-generated)
│   ├── ca.pem                 # Certificate Authority
│   ├── ca-key.pem             # CA private key
│   ├── server-cert.pem        # Server certificate
│   ├── server-key.pem         # Server private key
│   ├── client-cert.pem        # Client certificate
│   └── client-key.pem         # Client private key
└── data/                       # MySQL data directory
```

## 🚀 Quick Start

1. **Start the server:**
   ```bash
   docker compose up -d
   ```

2. **Check the SSL status:**
   ```bash
   docker compose exec dbmon01 mysql -uroot -p -e "SHOW VARIABLES LIKE '%ssl%';"
   ```

3. **Test SSL connection:**
   ```bash
   chmod +x test-ssl-connection.sh
   ./test-ssl-connection.sh
   ```

## 🔧 Configuration

### Environment Variables

Configure the `.env` file as needed:

```bash
# Basic settings
MYSQL_ROOT_PASSWORD=SecureRootPass123!
MYSQL_DATABASE=test_ssl
MYSQL_USER=ssl_user
MYSQL_PASSWORD=SecureUserPass123!

# Container image
MYSQL_IMAGE=percona/percona-server:8.4
```

### SSL Configuration

The MySQL configuration (`conf/mysql-ssl.cnf`) includes these key SSL settings:

```ini
[mysqld]
# Enforce SSL connections
require_secure_transport=ON

# SSL certificate paths
ssl-ca=/etc/mysql/ssl/ca.pem
ssl-cert=/etc/mysql/ssl/server-cert.pem
ssl-key=/etc/mysql/ssl/server-key.pem

# Additional SSL settings
ssl-cipher=DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384
```

## 🧪 Testing SSL

### Manual Certificate Generation

If you need to manually regenerate certificates:

```bash
chmod +x generate-ssl-certs.sh
./generate-ssl-certs.sh
docker compose restart
```

### Testing SSL Connection

Use the provided test script:

```bash
cd /mnt/mac/Users/jerichorivera/Workspace/Docker/mysql-docker/mysqlSSL
chmod +x test-ssl-connection.sh
MYSQL_ROOT_PASSWORD="your_password" ./test-ssl-connection.sh
```

Or manually test SSL connection:

```bash
# Show SSL status
docker compose exec dbmon01 mysql -uroot -p -e "SHOW STATUS LIKE 'Ssl_version';"

# Test connection with SSL specified
docker compose exec dbmon01 mysql -uroot -p --ssl-mode=REQUIRED -e "STATUS;"
```

## 🔒 Security Notes

1. **Default Passwords**: Change the default passwords in `.env` before production use
2. **Certificate Storage**: The certificates are stored in `./certs` - protect this directory
3. **Network Access**: Consider restricting network access to port 3306 in production

## 🐳 Docker Compose Services

The `docker-compose.yml` defines these services:

- **dbmon01**: Percona Server 8.4 with SSL enforced
- **dbmon02**: Optional replica server (in replication mode)
- **dbmon03**: Optional second replica server (in replication mode)

## 📊 Monitoring SSL Connections

Monitor SSL connections with these MySQL commands:

```sql
-- Check SSL status of current connection
SHOW STATUS LIKE 'Ssl%';

-- Show all connected users and their SSL status
SELECT PROCESSLIST_ID, USER, HOST, COMMAND, SSL_CIPHER 
FROM INFORMATION_SCHEMA.PROCESSLIST 
JOIN PERFORMANCE_SCHEMA.threads USING (THREAD_ID);

-- Monitor SSL handshake errors
SHOW GLOBAL STATUS LIKE 'Ssl_server_not_%;
```

## 🔧 Troubleshooting

### Common Issues

1. **SSL Connection Refused**:
   - Check certificates exist in `./certs/`
   - Verify MySQL is running with `docker compose logs dbmon01`

2. **Certificate Errors**:
   - Regenerate certificates with `./generate-ssl-certs.sh`
   - Ensure certificate files have correct permissions

3. **Replication SSL Issues**:
   - Verify replica certificates match the CA
   - Check replication user has SSL requirements set

### Health Check Validation

The health check verifies:
- MySQL process is running
- SSL is properly configured
- Basic connectivity is working

## 📚 References

- [Percona Server SSL Documentation](https://www.percona.com/doc/percona-server/8.0/security/encryption.html)
- [MySQL SSL Configuration Guide](https://dev.mysql.com/doc/refman/8.0/en/creating-ssl-files-using-openssl.html)
- [Docker Networking Documentation](https://docs.docker.com/network/)
