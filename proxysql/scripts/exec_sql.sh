#!/bin/bash

DB_USER=root
DB_PASSWORD=t00r
DB_PORT=3306
DB_HOST=$1
OPT1=$2
OPT2=$3

MYSQLCMD="mysql -u$DB_USER -p$DB_PASSWORD -h$DB_HOST"

show_help() {
  echo "Usage: $0 [HOST] [OPTIONS]"
  echo "check-replica-status    - checks replication status"
  echo "get-var [variable]      - checks GTID sequence"
  echo "help                    - show usage"
}

case $OPT1 in
"check-replica-status")
  $MYSQLCMD -e "show replica status\G"
  ;;
"get-var")
  if [[ ! -z $OPT2 ]]; then
    $MYSQLCMD -e "show global variables like '$OPT2'"
  else
    $MYSQLCMD -e "show global variables"
  fi
  ;;
"stop-replica")
  echo "Stopping replica..."
  $MYSQLCMD -e "stop replica"
  ;;
"start-replica")
  echo "Starting replica..."
  $MYSQLCMD -e "start replica"
  ;;
"help")
  show_help
  ;;
*)
  echo "Error: Unknown option '$2'"
  show_help
  ;;
esac
