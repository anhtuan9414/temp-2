#!/bin/bash
nowDate=$(date +"%Y-%m-%d %H:%M:%S %Z")
echo $nowDate

sudo chmod 666 /var/run/docker.sock

#docker rm -f $(docker ps -aq --filter ancestor=repocket/repocket:latest)
#docker rm -f $(docker ps -aq --filter ancestor=kellphy/nodepay:latest)

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

number=$(docker ps | grep debian:bullseye-slim | wc -l)
sudo docker rm -f $(docker ps -aq --filter ancestor=debian:bullseye-slim) && sudo rm -rf /opt/uam_data
file_name=$number-docker-compose.yml && sudo rm -rf entrypoint.sh && sudo rm -rf $file_name
wget https://github.com/anhtuan9414/uam-docker/raw/master/uam-swarm/$file_name && wget https://github.com/anhtuan9414/uam-docker/raw/master/uam-swarm/entrypoint.sh
sudo PBKEY=53F57E23ACBBA1F843F481C545549ECB9371CC05FD62AA74FAC6CD8D70AA0E4C docker-compose -f $file_name up -d
docker ps --filter ancestor=debian:bullseye-slim
