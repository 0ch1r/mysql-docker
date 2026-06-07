#!/bin/bash

set -euo pipefail

MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-t00r}
PRIMARY="pxc1"

echo "Creating monitor user..."
mysql -vvv -uroot -p$MYSQL_ROOT_PASSWORD -h$PRIMARY -e "CREATE USER 'monitor'@'%' IDENTIFIED WITH mysql_native_password BY 'monit0r'"
mysql -vvv -uroot -p$MYSQL_ROOT_PASSWORD -h$PRIMARY -e "GRANT USAGE ON *.* TO 'monitor'@'%'"

echo "Create app_user user..."
mysql -vvv -uroot -p$MYSQL_ROOT_PASSWORD -h$PRIMARY -e "CREATE USER 'app_user'@'%' IDENTIFIED WITH mysql_native_password BY 'app_password'"
mysql -vvv -uroot -p$MYSQL_ROOT_PASSWORD -h$PRIMARY -e "GRANT ALL PRIVILEGES ON app.* TO 'app_user'@'%'"

echo "Creating app database..."
mysql -vvv -uroot -p$MYSQL_ROOT_PASSWORD -h$PRIMARY -e "CREATE DATABASE app"
