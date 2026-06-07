# Multi-source MySQL replication (SSL)

This Docker Compose stack runs two MySQL sources (`s01`, `s02`) and a single replica (`r01`) using Percona Server for MySQL. The replica is configured for **multi-source replication** with two channels:

- `ch01` replicates from `s01.example.com:3306`
- `ch02` replicates from `s02.example.com:3306`

All connections require SSL (`require_secure_transport=ON`), and replication is configured with SSL and GTID auto-positioning.

## What’s included

```
multi-source-mysql/
├── docker-compose.yml
├── setup-replication.sh
├── conf/
│   ├── mysql-primary1.cnf
│   ├── mysql-primary2.cnf
│   └── mysql-replica.cnf
├── certs/                 # CA/server/client certs (mounted into containers)
└── client/
   └── client.conf         # client SSL defaults (for toolkit container)
```

## Services and ports

- `s01.example.com` (source 1): `localhost:3306`
- `s02.example.com` (source 2): `localhost:3307`
- `r01.example.com` (replica): `localhost:3308`
- `percona-toolkit` (utility container): no ports (sleeps indefinitely)

## Quick start

```bash
cd multi-source-mysql

docker compose up -d

# Configure multi-source replication on r01 (channels ch01 + ch02)
./setup-replication.sh
```

## Verify replication

```bash
export MYSQL_ROOT_PASSWORD='SecureRootPass123!'

docker exec r01.example.com mysql -uroot -p"$MYSQL_ROOT_PASSWORD" \
  --ssl-ca=/etc/mysql/ssl/ca.pem \
  --ssl-cert=/etc/mysql/ssl/client-cert.pem \
  --ssl-key=/etc/mysql/ssl/client-key.pem \
  -e "SHOW REPLICA STATUS FOR CHANNEL 'ch01'\\G"

docker exec r01.example.com mysql -uroot -p"$MYSQL_ROOT_PASSWORD" \
  --ssl-ca=/etc/mysql/ssl/ca.pem \
  --ssl-cert=/etc/mysql/ssl/client-cert.pem \
  --ssl-key=/etc/mysql/ssl/client-key.pem \
  -e "SHOW REPLICA STATUS FOR CHANNEL 'ch02'\\G"
```

## Generate test data (one schema per source)

```bash
export MYSQL_ROOT_PASSWORD='SecureRootPass123!'

docker exec s01.example.com mysql -uroot -p"$MYSQL_ROOT_PASSWORD" \
  --ssl-ca=/etc/mysql/ssl/ca.pem --ssl-cert=/etc/mysql/ssl/client-cert.pem --ssl-key=/etc/mysql/ssl/client-key.pem \
  -e "CREATE DATABASE IF NOT EXISTS src1_db; CREATE TABLE IF NOT EXISTS src1_db.t (id INT PRIMARY KEY, v VARCHAR(50)); INSERT INTO src1_db.t VALUES (1,'from s01') ON DUPLICATE KEY UPDATE v=VALUES(v);"

docker exec s02.example.com mysql -uroot -p"$MYSQL_ROOT_PASSWORD" \
  --ssl-ca=/etc/mysql/ssl/ca.pem --ssl-cert=/etc/mysql/ssl/client-cert.pem --ssl-key=/etc/mysql/ssl/client-key.pem \
  -e "CREATE DATABASE IF NOT EXISTS src2_db; CREATE TABLE IF NOT EXISTS src2_db.t (id INT PRIMARY KEY, v VARCHAR(50)); INSERT INTO src2_db.t VALUES (1,'from s02') ON DUPLICATE KEY UPDATE v=VALUES(v);"

docker exec r01.example.com mysql -uroot -p"$MYSQL_ROOT_PASSWORD" \
  --ssl-ca=/etc/mysql/ssl/ca.pem --ssl-cert=/etc/mysql/ssl/client-cert.pem --ssl-key=/etc/mysql/ssl/client-key.pem \
  -e "SELECT * FROM src1_db.t; SELECT * FROM src2_db.t;"
```

## Configuration

The Compose file supports these environment variables (with defaults in `docker-compose.yml`):

- `MYSQL_IMAGE` (default `percona/percona-server:8.4`)
- `MYSQL_ROOT_PASSWORD`
- `MYSQL_DATABASE`, `MYSQL_USER`, `MYSQL_PASSWORD`
- `TOOLKIT_IMAGE` (default `percona/percona-toolkit:3.7.1`)

## Notes / troubleshooting

- `setup-replication.sh` hard-codes replication user passwords (`ReplPassword123!`) and creates `repl01` (on `s01`) and `repl02` (on `s02`).
- `cert-generator` is a one-shot container that generates `./certs/*` if `./certs/ca.pem` is missing; it’s normal for it to exit after printing a success/skip message.
- Data/logs are bind-mounted into `./s01data`, `./s02data`, `./r01data`, and `./*logs`; `docker compose down -v` will not remove these directories.
- `docker-compose.yml` contains an optional `mysql-client` service under the `testing` profile that mounts `./conf/mysql-ssl.cnf`, but that file is not present in this folder; copy it from `../mysqlSSL/conf/mysql-ssl.cnf` or adjust the compose file if you want to use that profile.
