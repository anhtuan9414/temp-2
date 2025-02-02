#!/bin/bash
nowDate=$(date +"%Y-%m-%d %H:%M:%S %Z")
echo $nowDate

sudo chmod 666 /var/run/docker.sock


MEMORY_LIMIT=50

# Get a list of containers running the repocket/repocket:latest image
containers=$(docker ps --filter "ancestor=repocket/repocket:latest" --format "{{.ID}}")

if [ -n "$containers" ]; then
    for container in $containers; do
        # Get memory usage of the container in MiB
        memory_usage=$(docker stats --no-stream --format "{{.MemUsage}}" $container | awk '{print $1}' | sed 's/MiB//')
        
        # Check if memory usage is greater than the limit
        if [ "$(echo "$memory_usage > $MEMORY_LIMIT" | bc)" -eq 1 ]; then
            echo "Container $container exceeds memory limit (${memory_usage}MiB > ${MEMORY_LIMIT}MiB). Deleting..."
            docker stop $container && docker rm $container
            docker run -e RP_EMAIL=kojinyoji@gmail.com -e RP_API_KEY=c5224291-4fdd-4c86-8ee5-3b4ff35d78c1 -d --restart=always --memory=50mb repocket/repocket:latest
        else
            echo "Container $container is within memory limit (${memory_usage}MiB)."
        fi
    done
fi


PBKEY=""
# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

# List of containers to try
containers=("uam_1" "uam_2" "uam_3" "uam_4" "uam_5")

for container in "${containers[@]}"; do
    PBKEY=$(docker exec "$container" printenv PBKEY 2>/dev/null)
    
    if [ -n "$PBKEY" ]; then
        break
    else
        echo "PBKEY not found in $container, trying next..."
    fi
done
echo $PBKEY
number=$(docker ps | grep debian:bullseye-slim | wc -l)
sudo docker rm -f $(docker ps -aq --filter ancestor=debian:bullseye-slim) && sudo rm -rf /opt/uam_data
file_name=$number-docker-compose.yml && sudo rm -rf entrypoint.sh && sudo rm -rf $file_name
wget https://github.com/anhtuan9414/uam-docker/raw/master/uam-swarm/$file_name && wget https://github.com/anhtuan9414/uam-docker/raw/master/uam-swarm/entrypoint.sh
sudo PBKEY=$PBKEY docker-compose -f $file_name up -d
docker ps --filter ancestor=debian:bullseye-slim
