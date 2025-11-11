# MySQL Replication with Orchestrator

This setup provides a Docker Compose environment for testing MySQL replication topology management using Orchestrator. The deployment includes:
- Three MySQL servers in a replication topology
- Orchestrator server for topology management
- Orchestrator Raft cluster (3 nodes) for high availability

## 📁 Directory Structure

```
orchestrator/
├── docker-compose.yml      # Main Docker Compose configuration
├── conf/
│   ├── orchestrator/       # Orchestrator configuration
│   │   ├── config.json     # Orchestrator main configuration
│   │   └── raft.conf       # Raft configuration
│   ├── mysql/              # MySQL configuration
│   │   ├── mysql1.cnf
│   │   ├── mysql2.cnf
│   │   └── mysql3.cnf
│   └── scripts/            # Setup scripts
│       ├── orchestrator.sql
│       └── setup.sh
└── README.md               # This documentation
```

## 🚀 Quick Start

1. **Start the deployment:**
   ```bash
   docker compose up -d
   ```

2. **Wait for initialization (approximately 2-3 minutes):**
   ```bash
   docker compose logs -f orchestrator-raft1
   ```

3. **Access Orchestrator web interface:**
   Visit http://localhost:3000 in your browser

4. **Check cluster status:**
   ```bash
   docker compose exec orchestrator-raft1 orchestrator -c topolo
   ```

## 🐳 Services Overview

### MySQL Servers

- **mysql1**: Source/Primary server (port: 3306)
- **mysql2**: Replica server (port: 3307)
- **mysql3**: Replica server (port: 3308)

Each MySQL server:
- Runs Percona Server 8.0
- Has binary logging enabled for replication
- Configured with unique server IDs
- Has health checks enabled

### Orchestrator Services

- **orchestrator-backend**: MySQL backend for Orchestrator storage
- **orchestrator-raft1**: Orchestrator instance 1 (port: 3000)
- **orchestrator-raft2**: Orchestrator instance 2 (port: 3001)
- **orchestrator-raft3**: Orchestrator instance 3 (port: 3002)

The Orchestrator instances form a Raft cluster for high availability.

## 🔧 Configuration

### MySQL Configuration

The MySQL configuration files in `conf/mysql/` include:
- Binary logging configuration for replication
- Server IDs setup
- GTID mode enabled
- Replication-specific settings

### Orchestrator Configuration

The Orchestrator configuration (`conf/orchestrator/config.json`) includes:
- Backend MySQL connection details
- Discovery settings
- Failure detection intervals
- Raft configuration parameters

## 🎯 Replication Topology

The deployment creates a replication topology like this:

```
    +---------+
    | mysql1  | (Source/Primary)
    +---------+
       | | |
       + + +----+---------+
                |       |
         +------+       +------+
         |              |
         v              v
    +---------+    +---------+
    | mysql2  |    | mysql3  |
    +---------+    +---------+
      (Replica)      (Replica)
```

## 📊 Monitoring with Orchestrator

Orchestrator provides several ways to monitor the replication topology:

### Web Interface

Access the web UI at:
- Primary: http://localhost:3000
- Backup 1: http://localhost:3001 
- Backup 2: http://localhost:3002

### Command Line

```bash
# Show the topology
docker compose exec orchestrator-raft1 orchestrator -c topolo

# Check cluster health
docker compose exec orchestrator-raft1 orchestrator -c which-cluster

# Execute arbitrary queries
docker compose exec orchestrator-raft1 orchestrator -c sql -i " SHOW PROCESSLIST"

# See all available commands
docker compose exec orchestrator-raft1 orchestrator -c help
```

## 🔄 Replication Management

### Manual Failover

You can perform failovers through the Orchestrator UI or command line:

```bash
# Graceful failover to a replica
docker compose exec orchestrator-raft1 orchestrator -c graceful-master-takeover -i mysql2

# Force failover (in case primary is down)
docker compose exec orchestrator-raft1 orchestrator -c force-master-takeover -i mysql2
```

### Register/Deregister Servers

```bash
# Forget a server from topology
docker compose exec orchestrator-raft1 orchestrator -c forget -i mysql2

# Discover a server
docker compose exec orchestrator-raft1 orchestrator -c discover -i mysql2
```

## 🔧 Troubleshooting

### Checking Logs

```bash
# Check all logs
docker compose logs

# Check specific service logs
docker compose logs orchestrator-raft1
docker compose logs mysql1
```

### Common Issues

1. **Orchestrator can't find servers**:
   - Check MySQL servers are running: `docker compose exec mysql1 mysql -uroot -e "SELECT 1"`
   - Verify Orchestrator can connect: `docker compose exec orchestrator-raft1 orchestrator -c discover -i mysql1`

2. **Replication not working**:
   - Check replication status: `docker compose exec mysql2 mysql -uroot -e "SHOW SLAVE STATUS\G"`
   - Ensure binary logs are enabled on primary: `docker compose exec mysql1 mysql -uroot -e "SHOW MASTER STATUS"`

3. **Raft cluster issues**:
   - Check Raft status: `docker compose exec orchestrator-raft1 orchestrator -c raft-leader`
   - Verify cluster health: `docker compose exec orchestrator-raft1 orchestrator -c raft-status`

## 📚 Orchestrator Concepts

### Key Features

- **Topology Discovery**: Automatically discovers MySQL replication topologies
- **Failure Detection**: Detects primary failures and replica issues
- **Failover Automation**: Handles automatic failovers based on configuration
- **Topology Changes**: Supports complex topology changes online
- **Maintenance Mode**: Put servers into maintenance mode

### Architecture

Orchestrator uses a three-tier architecture:
1. **Frontend**: HTTP API and web interface
2. **Backend**: MySQL database storing topology data
3. **Agents**: Agents on the MySQL servers (not used in this setup)

## 🛠 Advanced Configuration

### Custom Recovery

Configure custom recovery scripts to be executed during failover:
```json
{
  "RecoveryMasterSlaveInstancesFilter": [
    "somefilter"
  ],
  "RecoveryProcessesBlockSizePercentage": 100,
  "RecoveryPeriodBlockMinutes": 60,
  "RecoveryBlockHostsWhenTooManyMasterFailures": true
}
```

### Hooks

Orchestrator supports hooks for integration with external systems:
```json
{
  "ApplyMySQLPromotionAfterMasterFailover": true,
  "PostMasterFailoverHooks": [
    "/path/to/script.sh {hostname}",
    "http://service.com/endpoint?host={hostname}"
  ]
}
```

## 📚 References

- [Orchestrator GitHub Repository](https://github.com/openark/orchestrator)
- [Orchestrator Documentation](https://github.com/openark/orchestrator/wiki)
- [MySQL Replication Documentation](https://dev.mysql.com/doc/refman/8.0/en/replication.html)
