# MySQL Docker Compose Environments

This repository contains various Docker Compose environments for testing and running MySQL and Percona Server for MySQL with different configurations and tools.

## Directory Structure

Each subdirectory contains a complete Docker Compose setup with its own configuration files and documentation:

- [`innodbcluster`](./innodbcluster) - MySQL InnoDB Cluster with 3 nodes
- [`mysqlSSL`](./mysqlSSL) - Percona Server 8.4 with SSL/TLS encryption required
- [`orchestrator`](./orchestrator) - MySQL topology management with Orchestra[tor](https://github.com/openark/orchestrator)
- [`pmm`](./pmm) - Percona Monitoring and Management (PMM) setup
- [`proxysql`](./proxysql) - MySQL Proxy with ProxySQL for high availability

## Prerequisites

Before using any of these environments, ensure you have the following installed:

- [Docker](https://docs.docker.com/get-docker/) (20.10 or later)
- [Docker Compose](https://docs.docker.com/compose/install/) (v2 or later)

## Quick Start

Each environment can be started by navigating to its directory and running:

```bash
# Navigate to the desired directory
cd [directory-name]

# Start the services
docker compose up -d

# Check the status
docker compose ps

# Stop the services
docker compose down
```

## Common Environment Variables

Most configurations support these environment variables:

- `MYSQL_IMAGE`: MySQL or Percona Server image version
- `MYSQL_ROOT_PASSWORD`: MySQL root password
- `MYSQL_DATABASE`: Default database name
- `MYSQL_USER`: Regular MySQL username
- `MYSQL_PASSWORD`: Regular MySQL user password

## Network Considerations

Each setup creates its own Docker network to ensure isolation between environments, allowing multiple environments to run simultaneously without conflicts.

## Security Notes

These configurations are intended for development and testing purposes. Before using in production:

1. Review all default passwords
2. Consider network access restrictions
3. Verify SSL/TLS configuration
4. Update resource limits as needed

## Contributing

Feel free to contribute additional Docker Compose configurations or improve existing ones. Please ensure:

1. Documentation is clear and complete
2. All files are properly formatted
3. Security best practices are followed

## License

This repository follows the same license as the referenced tools and images.
