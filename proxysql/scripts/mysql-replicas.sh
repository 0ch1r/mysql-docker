#!/bin/bash

set -euo pipefail

MYSQL_ROOT_PASSWORD="t00r"
REPLICA="$1"

echo "Configuring replication..."
mysql -uroot -p$MYSQL_ROOT_PASSWORD -h$REPLICA -e "CHANGE REPLICATION SOURCE TO source_host='mysql1', source_user='repluser', source_password='replpass', source_auto_position=1"
mysql -uroot -p$MYSQL_ROOT_PASSWORD -h$REPLICA -e "START REPLICA"
sleep 2
mysql -uroot -p$MYSQL_ROOT_PASSWORD -h$REPLICA -e "SHOW REPLICA STATUS\G"