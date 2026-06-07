#!/bin/bash

# Usage: ./insert_random_data.sh N
# where N is the number of rows to insert

DB_NAME=$1
TABLE_NAME=$2
N=$3

# Function to generate a random string of length 10
random_string() {
  cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 10 | head -n 1
}

# Calculate the timestamp range for the past 10 years in seconds
CURRENT_TS=$(date +%s)
TEN_YEARS_SEC=315360000

# Create the table
# echo "Dropping the table if it exists..."
# DROP="USE $DB_NAME; DROP TABLE IF NOT EXISTS $TABLE_NAME;"
echo "Creating the table..."
CREATE="USE $DB_NAME; CREATE TABLE IF NOT EXISTS $TABLE_NAME (id INT PRIMARY KEY AUTO_INCREMENT NOT NULL,c VARCHAR(100), i INT, t TIMESTAMP DEFAULT CURRENT_TIMESTAMP());"
set -x
# mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "$DROP" 2>/dev/null
mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "$CREATE" 2>/dev/null
set +x

echo "Inserting the data..."
for ((i=1; i<=N; i++))
do
  # Generate random offset in seconds from 0 to TEN_YEARS_SEC - using /dev/urandom for larger range
  rand_sec_ago=$(od -An -N4 -tu4 < /dev/urandom | tr -d ' ' | awk -v limit=$TEN_YEARS_SEC '{print $1%limit}')
  # Generate random date
  rand_date=$(date -d "@$((CURRENT_TS - rand_sec_ago))" '+%Y-%m-%d %H:%M:%S')

  # Random string for 'c' column
  rand_str=$(random_string)
  # Random integer for 'i' column between 0 and 1000
  rand_int=$((RANDOM % 1001))

  # Insert statement
  SQL="INSERT INTO $DB_NAME.$TABLE_NAME (c, i, t) VALUES ('$rand_str', $rand_int, '$rand_date');"

  # Execute insert
  mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "$SQL" 2>/dev/null

  if (( i % 10 == 0 )); then
	echo -n "."
  fi
done
echo -e "\nDone inserting data."
