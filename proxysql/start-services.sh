#!/bin/bash

set -euo pipefail

source .env


wait_for_mysql() {
    local attempt=1
    local max_attempts=60
    local containername="$1"
    local password="$2"

    echo "Waiting for MySQL to be ready..."
    while [ $attempt -le $max_attempts ]; do
        if docker exec "$containername" mysqladmin ping -u root -p"$password" --silent 2>/dev/null; then
            echo "MySQL is ready after $attempt seconds!"
            return 0
        fi
    
        if [ $attempt -eq $max_attempts ]; then
            echo "MySQL failed to start within $max_attempts seconds!"
            return 1
        fi
    
        echo -n "."
        sleep 1
        ((attempt++))
    done
}


COMPOSEFILE=compose_proxy_percona_2_replicas.yml
echo "Starting mysql1 container..."
docker compose -f $COMPOSEFILE up -d mysql1

if ! wait_for_mysql mysql1 