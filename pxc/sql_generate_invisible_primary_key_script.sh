#!/bin/bash

set -oeu pipefail

MYSQL_ROOT_PASSWORD=t00r
MYSQL_ROOT_USERNAME=root

echo "Checking current sql_generate_invisible_primary_key values..."
for container in pxc1 pxc2 pxc3; do
  echo "${container}"
  docker compose exec -it $container mysql -u$MYSQL_ROOT_USERNAME -p$MYSQL_ROOT_PASSWORD -e "SHOW GLOBAL VARIABLES LIKE 'sql_generate_invisible_primary_key'"
done

echo "Changing sql_generate_invisible_primary_key on all nodes..."
for container in pxc1 pxc2 pxc3; do
  echo "${container}"
  docker compose exec -it $container mysql -u$MYSQL_ROOT_USERNAME -p$MYSQL_ROOT_PASSWORD -e "SET GLOBAL sql_generate_invisible_primary_key=OFF"
  docker compose exec -it $container mysql -u$MYSQL_ROOT_USERNAME -p$MYSQL_ROOT_PASSWORD -e "SHOW GLOBAL VARIABLES LIKE 'sql_generate_invisible_primary_key'"
done

echo "Creating the table in pxc1..."
docker compose exec -it pxc1 mysql -u$MYSQL_ROOT_USERNAME -p$MYSQL_ROOT_PASSWORD -e "CREATE DATABASE test; CREATE TABLE test.t1 (id int not null, c varchar(100))"

echo "Check table structure on all nodes..."
for container in pxc1 pxc2 pxc3; do
  echo "${container}"
  docker compose exec -it $container mysql -u$MYSQL_ROOT_USERNAME -p$MYSQL_ROOT_PASSWORD -e "SHOW CREATE TABLE test.t1\G"
done
