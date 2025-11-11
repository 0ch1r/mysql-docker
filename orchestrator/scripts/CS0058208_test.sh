#!/bin/bash

MYSQL_ROOT_PASSWORD=t00r

set -euo pipefail

# Cleanup
mysql -uroot -p$MYSQL_ROOT_PASSWORD -hmysql-1 -e 'DROP DATABASE IF EXISTS testdb';
mysql -uroot -p$MYSQL_ROOT_PASSWORD -hmysql-1 -e 'SET @@global.sql_mode="ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION"';
mysql -uroot -p$MYSQL_ROOT_PASSWORD -hmysql-2 -e 'SET @@global.sql_mode="ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION"';

# Create database
echo "Creating the database..."
mysql -uroot -p$MYSQL_ROOT_PASSWORD -hmysql-1 -e 'CREATE DATABASE IF NOT EXISTS testdb';

# Create table
echo "Creating the table..."
mysql -uroot -p$MYSQL_ROOT_PASSWORD -hmysql-1 -e 'CREATE TABLE IF NOT EXISTS testdb.tbl1 (id int primary key auto_increment, content mediumblob not null, num int not null, createdat datetime not null default current_timestamp())';

# Check the SQL_MODE
echo "Checking the sql_mode..."
mysql -uroot -p$MYSQL_ROOT_PASSWORD -hmysql-1 -e 'SELECT @@hostname, @@global.sql_mode';
mysql -uroot -p$MYSQL_ROOT_PASSWORD -hmysql-2 -e 'SELECT @@hostname, @@global.sql_mode';

# Alter the table on primary
echo "Altering the table on the primary..."
mysql -uroot -p$MYSQL_ROOT_PASSWORD -hmysql-1 -e 'SET sql_log_bin=0; ALTER TABLE testdb.tbl1 MODIFY COLUMN content MEDIUMBLOB NULL; ALTER TABLE testdb.tbl1 MODIFY COLUMN num INT NULL;  SET sql_log_bin=1';

# Check the table definition in mysql-1
echo "Check the table definition in mysql-1..."
mysql -uroot -p$MYSQL_ROOT_PASSWORD -hmysql-1 -e 'SHOW CREATE TABLE testdb.tbl1\G';

# Check the tavke definition in mysql-2
echo "Check the table definition in mysql-2..."
mysql -uroot -p$MYSQL_ROOT_PASSWORD -hmysql-2 -e 'SHOW CREATE TABLE testdb.tbl1\G';

# Insert data
echo "Inserting data from mysql-1..."
mysql -uroot -p$MYSQL_ROOT_PASSWORD -hmysql-1 -e 'INSERT INTO testdb.tbl1 (content, num) VALUES (NULL, NULL)';

# Compare data from mysql-1 and mysql-2
echo "Comparing data from mysql-1 and mysql-2..."
mysql -uroot -p$MYSQL_ROOT_PASSWORD -hmysql-1 -e 'SELECT @@hostname, content, num, createdat FROM testdb.tbl1';
mysql -uroot -p$MYSQL_ROOT_PASSWORD -hmysql-2 -e 'SELECT @@hostname, content, num, createdat FROM testdb.tbl1';

# Check replication status
echo "Checking replication status..."
mysql -uroot -p$MYSQL_ROOT_PASSWORD -hmysql-2 -e 'SHOW SLAVE STATUS\G';

# Change SQL_MODE on mysql-2
# echo "Changing sql_mode on mysql-2..."
# mysql -uroot -p$MYSQL_ROOT_PASSWORD -hmysql-2 -e 'SET @@global.sql_mode="ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,STRICT_ALL_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION"';

# Check the SQL_MODE
# echo "Checking the sql_mode..."
# mysql -uroot -p$MYSQL_ROOT_PASSWORD -hmysql-1 -e 'SELECT @@hostname, @@global.sql_mode';
# mysql -uroot -p$MYSQL_ROOT_PASSWORD -hmysql-2 -e 'SELECT @@hostname, @@global.sql_mode';

# Insert data
# echo "Inserting data from mysql-1..."
# mysql -uroot -p$MYSQL_ROOT_PASSWORD -hmysql-1 -e 'INSERT INTO testdb.tbl1 (content) VALUES (NULL)';

# Compare data from mysql-1 and mysql-2
# echo "Comparing data from mysql-1 and mysql-2..."
# mysql -uroot -p$MYSQL_ROOT_PASSWORD -hmysql-1 -e 'SELECT @@hostname, content, createdat FROM testdb.tbl1';
# mysql -uroot -p$MYSQL_ROOT_PASSWORD -hmysql-2 -e 'SELECT @@hostname, content, createdat FROM testdb.tbl1';

# Test insert on mysql-2 with STRICT_ALL_TABLES
# echo "Inserting data from mysql-2..."
# mysql -uroot -p$MYSQL_ROOT_PASSWORD -hmysql-2 -e 'INSERT INTO testdb.tbl1 (content) VALUES (NULL)';

# Truncate table
# echo "Truncating table..."
# mysql -uroot -p$MYSQL_ROOT_PASSWORD -hmysql-1 -e 'TRUNCATE testdb.tbl1';

# Alter the table on primary
# echo "Altering the table on the primary..."
# mysql -uroot -p$MYSQL_ROOT_PASSWORD -hmysql-1 -e 'SET sql_log_bin=0; ALTER TABLE testdb.tbl1 MODIFY COLUMN content MEDIUMBLOB NOT NULL; SET sql_log_bin=1';

# Check the table definition in mysql-1
# echo "Check the table definition in mysql-1..."
# mysql -uroot -p$MYSQL_ROOT_PASSWORD -hmysql-1 -e 'SHOW CREATE TABLE testdb.tbl1\G';

# Check the tavke definition in mysql-2
# echo "Check the table definition in mysql-2..."
# mysql -uroot -p$MYSQL_ROOT_PASSWORD -hmysql-2 -e 'SHOW CREATE TABLE testdb.tbl1\G';

# Change SQL_MODE on mysql-1
# echo "Changing sql_mode on mysql-1..."
# mysql -uroot -p$MYSQL_ROOT_PASSWORD -hmysql-1 -e 'SET @@global.sql_mode=""';

# Check the SQL_MODE
# echo "Checking the sql_mode..."
# mysql -uroot -p$MYSQL_ROOT_PASSWORD -hmysql-1 -e 'SELECT @@hostname, @@global.sql_mode';
# mysql -uroot -p$MYSQL_ROOT_PASSWORD -hmysql-2 -e 'SELECT @@hostname, @@global.sql_mode';

# Test insert on mysql-2 with STRICT_TRANS_TABLES
# echo "Inserting data from mysql-1..."
# mysql -uroot -p$MYSQL_ROOT_PASSWORD -hmysql-1 -e 'INSERT INTO testdb.tbl1 (content) VALUES (NULL)';
