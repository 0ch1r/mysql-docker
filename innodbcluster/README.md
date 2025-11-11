# MySQL InnoDB Cluster with Docker Compose

This project provides a simple way to set up a 3-node MySQL InnoDB Cluster using Docker Compose. It includes scripts to easily initialize, manage, and destroy the cluster.

## Prerequisites

Before you begin, ensure you have the following installed:

*   [Docker](https://docs.docker.com/get-docker/)
*   [Docker Compose](https://docs.docker.com/compose/install/)

## Directory Structure

```
.
├── conf
│   ├── mysql-ic-1.cnf
│   ├── mysql-ic-2.cnf
│   └── mysql-ic-3.cnf
├── deploy-cluster
├── docker-compose.yml
├── env
│   └── mysql.env
└── README.md
```

*   `conf/`: Contains the MySQL configuration files for each node.
*   `deploy-cluster`: A shell script to manage the cluster lifecycle.
*   `docker-compose.yml`: Defines the 3-node MySQL cluster services.
*   `env/mysql.env`: Environment variables for MySQL, including the root password.

## Quick Start

1. **Start the cluster:**
   ```bash
   chmod +x deploy-cluster
   ./deploy-cluster create
   ```
   
2. **Check the status:**
   ```bash
   docker compose ps
   ```

3. **Connect to the cluster:**
   ```bash
   docker exec -it mysql-ic-1 mysql -uroot -p
   ```

4. **Destroy the cluster:**
   ```bash
   ./deploy-cluster destroy
   ```

## Cluster Management

The `deploy-cluster` script provides the following commands:

- `create`: Creates and starts the cluster
- `stop`: Stops the cluster without removing data
- `start`: Starts the cluster if stopped
- `destroy`: Stops and removes the cluster including all data

## Customization

You can customize the cluster by modifying:

- `env/mysql.env`: Change MySQL credentials
- `conf/*.cnf`: Adjust MySQL configuration parameters
- `docker-compose.yml`: Modify container settings, resource limits, etc.

## Environment Variables

The following environment variables can be set in `env/mysql.env`:

- `MYSQL_ROOT_PASSWORD`: Password for the MySQL root user (default: `root_password`)
- `MYSQL_IMAGE`: MySQL container image to use (default: `percona/percona-server:8.0`)

## Node Information

The cluster consists of three nodes:

| Node | Container Name | Hostname | Port |
|------|----------------|----------|------|
| 1 | mysql-ic-1 | mysql-ic-1 | 3306 |
| 2 | mysql-ic-2 | mysql-ic-2 | 3307 |
| 3 | mysql-ic-3 | mysql-ic-3 | 3308 |

## Connectivity

### From Docker Network

Within the Docker network, you can connect to any node using its hostname:

```bash
mysql -h mysql-ic-1 -uroot -p
mysql -h mysql-ic-2 -uroot -p
mysql -h mysql-ic-3 -uroot -p
```

### From Host

From the host machine, use the appropriate port:

```bash
mysql -h 127.0.0.1 -P 3306 -uroot -p
mysql -h 127.0.0.1 -P 3307 -uroot -p
mysql -h 127.0.0.1 -P 3308 -uroot -p
```

## Troubleshooting

1. **Cluster creation fails**: Check logs with `docker compose logs`
2. **Node not joining cluster**: Verify network connectivity and ensure ports are not in use
3. **Data persistence issues**: Confirm volume mounts are properly configured

## Production Considerations

This setup is intended for testing and development. For production environments, consider:

- Proper firewall configuration
- Resource monitoring and scaling
- Backup strategies
- High availability options

## References

- [MySQL InnoDB Cluster Documentation](https://dev.mysql.com/doc/refman/8.0/en/mysql-innodb-cluster.html)
- [MySQL Shell Documentation](https://dev.mysql.com/doc/mysql-shell/8.0/en/)
