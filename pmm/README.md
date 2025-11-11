# Percona Monitoring and Management (PMM) Docker Compose Setup

This setup provides a complete PMM monitoring environment with a PMM server and multiple monitored database services including MySQL, PostgreSQL, and MongoDB. It also includes additional services like SMTP and automatic container updates.

## 📁 Directory Structure

```
pmm/
├── docker-compose.yml      # Main Docker Compose configuration
├── .env                    # Environment variables
├── certs/                  # SSL certificates storage
│   └── server-key.pem     # Private key for PMM server
└── README.md               # This documentation
```

## 🚀 Quick Start

1. **Initial setup** (first time only):
   ```bash
   mkdir -p certs
   docker compose up -d pmm-server
   ```

2. **Start all services:**
   ```bash
   docker compose up -d
   ```

3. **Access PMM web interface:**
   Visit https://localhost:8443
   - Username: `admin`
   - Password: `admin`

4. **Check monitored databases:**
   Wait a few minutes after startup to see metrics in PMM dashboards.

## 🐳 Services Overview

### PMM Server

- **pmm-server**: Percona Monitoring and Management Server (port: 8443 https)
  - Runs PMM Server 3.x
  - Stores metrics and configurations
  - Provides web UI and API
  - Configured to use SMTP via mailpit

### PMM Client

- **pmm-client**: PMM Agent container
  - Connects to PMM Server
  - Automatically monitors all database instances
  - Configured to skip TLS verification

### Monitored Databases

- **mysql**: MySQL 8.0 server (port: 3306)
  - Monitored via Performance Schema
  - Username: root / Password: password

- **postgres**: PostgreSQL server (port: 5432)
  - Monitored via pg_stat_monitor
  - Username: postgres / Password: password

- **mongodb**: MongoDB server (port: 27017)
  - Basic MongoDB instance for testing
  - Monitored via PMM MongoDB agent

### Additional Services

- **mailpit**: SMTP service (port: 8025)
  - Provides SMTP endpoint for PMM alerting
  - Web interface at http://localhost:8025
  - Username: mp_api / Password: mp_pass

- **watchtower**: Container update service
  - Automatically updates containers to latest versions
  - Configurable via environment variables

## 🔧 Configuration

### Environment Variables

Update the `.env` file to customize your deployment:

```bash
# Container versions
PMMSERVER_IMAGE=percona/pmm-server:3
PMMCLIENT_IMAGE=percona/pmm-client:3
MAILPIT_IMAGE=axllent/mailpit:latest

# Database credentials (used for connecting to databases)
MYSQL_ROOT_PASSWORD=password
POSTGRES_PASSWORD=password

# Watchtower options
WATCHTOWER_POLL_INTERVAL=3600
WATCHTOWER_CLEANUP=true
```

### MySQL Configuration

The MySQL server is configured with:
- Performance Schema enabled for query analytics
- User: root / Password: password
- Data persisted in Docker volume

### PostgreSQL Configuration

The PostgreSQL server includes:
- pg_stat_monitor extension for query analytics
- User: postgres / Password: password
- Data persisted in Docker volume

### MongoDB Configuration

The MongoDB server includes:
- Basic standalone instance
- Monitoring enabled for performance metrics
- No authentication (for testing only)

## 📊 PMM Features

Once the setup is running, you can monitor:

- **Query Analytics**: View detailed statistics for SQL queries
- **Performance Dashboard**: Real-time metrics for all systems
- **Instance Overview**: Summary of all monitored instances
- **Alerting**: Configure alerts on important metrics (via mailpit)

## 🎯 Accessing PMM

### Web Interface

- **URL**: https://localhost:8443
- **Username**: admin
- **Password**: admin

### Viewing Logs

```bash
# PMM Server logs
docker compose logs pmm-server

# PMM Client logs
docker compose logs pmm-client

# All logs
docker compose logs
```

### Managing Monitored Services

You can manage which databases are monitored through the PMM interface or command line:

```bash
# Connect to PMM client container
docker compose exec pmm-client bash

# See what's being monitored
pmm-admin list

# Add a new MySQL server
pmm-admin add mysql --query-source=perfschema --username=root --password=<pass> --host=<host>

# Remove a monitored server
pmm-admin delete mysql --service-name=service-name
```

## 📈 PMM Dashboards

PMM provides several useful dashboards:

- **Query Analytics**: Most expensive and frequent queries
- **MySQL Overview**: Key performance metrics
- **PostgreSQL Overview**: PostgreSQL-specific metrics
- **MongoDB Overview**: MongoDB-specific metrics
- **System Overview**: OS-level performance data

## 🔄 Updating

With Watchtower enabled, containers will update automatically. To manually update:

```bash
# Pull latest versions
docker compose pull

# Restart with updated images
docker compose up -d
```

## 📮 SMTP Configuration

The setup includes Mailpit for mail testing:

- **URL**: http://localhost:8025
- **SMTP**: mailpit:587
- **Username**: mp_api
- **Password**: mp_pass

Use this to test alerting configurations or develop email-based notifications.

## 🔧 Customization

### Adding New Monitored Services

To monitor additional database instances:

1. Update `docker-compose.yml` to add the new service
2. Update the `PMM_AGENT_PRERUN_SCRIPT` in the pmm-client service
3. Restart the pmm-client service

### Custom PMM Configuration

The PMM server can be customized by adding configuration files:

```bash
# Create a volume for custom configuration
docker volume create pmm-server-conf

# Mount custom configuration
```

## 🔏 SSL Configuration

SSL is already configured for PMM Server (port 8443). The certificate is stored in `./certs/server-key.pem`. For production:

1. Replace with your own certificate
2. Update the volume mount in docker-compose.yml
3. Update URL from localhost to the appropriate domain

## 📚 References

- [PMM Documentation](https://docs.percona.com/pmm/)
- [PMM GitHub Repository](https://github.com/percona/pmm)
- [Mailpit Documentation](https://github.com/axllent/mailpit)
- [Watchtower Documentation](https://containrrr.dev/watchtower/)
