#!/bin/bash

set -eou pipefail

command="$1"

case "$command" in
    "primary")
        mysql -uroot -p$MYSQL_ROOT_PASSWORD -hmysql-1 -v < /scripts/mysql-primary.sql
        ;;
    "replicas")
        mysql -uroot -p$MYSQL_ROOT_PASSWORD -hmysql-2 -v < /scripts/mysql-replicas.sql
        mysql -uroot -p$MYSQL_ROOT_PASSWORD -hmysql-3 -v < /scripts/mysql-replicas.sql
        ;;
    *)
        >&2 echo "setup.sh <primary|replicas>"
        exit 1
esac