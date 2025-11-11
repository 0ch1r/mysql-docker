#!/bin/bash

set -euo pipefail

MYSQL_ROOT_PASSWORD="t00r"
PRIMARY="$1"

echo "Creating monitor user..."
mysql -uroot -p$MYSQL_ROOT_PASSWORD -h$PRIMARY -e "CREATE USER 'monitor'@'%' IDENTIFIED WITH mysql_native_password BY 'monit0r'"
mysql -uroot -p$MYSQL_ROOT_PASSWORD -h$PRIMARY -e "GRANT USAGE ON *.* TO 'monitor'@'%'"

echo "Creating replication user..."
mysql -uroot -p$MYSQL_ROOT_PASSWORD -h$PRIMARY -e "CREATE USER 'repluser'@'%' IDENTIFIED WITH mysql_native_password BY 'replpass'"
mysql -uroot -p$MYSQL_ROOT_PASSWORD -h$PRIMARY -e "GRANT REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'repluser'@'%'"

echo "Creating super user..."
mysql -uroot -p$MYSQL_ROOT_PASSWORD -h$PRIMARY -e "CREATE USER 'superuser'@'%' IDENTIFIED WITH mysql_native_password BY 'superpass'"
mysql -uroot -p$MYSQL_ROOT_PASSWORD -h$PRIMARY -e "GRANT ALL PRIVILEGES ON *.* TO 'superuser'@'%'"

echo "Create app_user user..."
mysql -uroot -p$MYSQL_ROOT_PASSWORD -h$PRIMARY -e "CREATE USER 'app_user'@'%' IDENTIFIED WITH mysql_native_password BY 'app_password'"
mysql -uroot -p$MYSQL_ROOT_PASSWORD -h$PRIMARY -e "GRANT ALL PRIVILEGES ON app.* TO 'app_user'@'%'"

echo "Creating app database..."
mysql -uroot -p$MYSQL_ROOT_PASSWORD -h$PRIMARY -e "CREATE DATABASE app"