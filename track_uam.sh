#!/bin/bash
nowDate=$(date +"%Y-%m-%d %H:%M:%S %Z")
echo $nowDate

sudo chmod 666 /var/run/docker.sock
PBKEY=$(docker exec uam_1 printenv PBKEY)

if [ -z "$PBKEY" ]; then
    PBKEY=$(docker exec uam_2 printenv PBKEY)
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# Telegram Bot Configuration
BOT_TOKEN="7542968763:AAHbgLT6_KEUvtMm1OY0_CW0o_zF3QSHoNo"
CHAT_ID="1058406039"

# Function to send a Telegram notification
send_telegram_notification() {
    local message="$1"
    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
        -d chat_id="$CHAT_ID" \
        -d text="$message" > /dev/null
}

# Get the VPS public IP address
PUBLIC_IP=$(curl -s ifconfig.me)

# Fetch public IP and ISP info from ip-api
response=$(curl -s http://ip-api.com/json)

# Extract ISP and Org using grep and sed
ISP=$(echo "$response" | grep -oP '"isp":\s*"\K[^"]+')
ORG=$(echo "$response" | grep -oP '"org":\s*"\K[^"]+')
REGION=$(echo "$response" | grep -oP '"regionName":\s*"\K[^"]+')
CITY=$(echo "$response" | grep -oP '"city":\s*"\K[^"]+')
COUNTRY=$(echo "$response" | grep -oP '"country":\s*"\K[^"]+')

if [ -z "$PBKEY" ]; then
    echo "PBKEY empty"
    send_telegram_notification "$nowDate%0A%0AWARRING!!!%0A%0AIP: $PUBLIC_IP%0AISP: $ISP%0AORG: $ORG%0ACOUNTRY: $COUNTRY%0AREGION: $REGION%0ACITY: $CITY%0A%0APBKEY empty!"
    exit 1
fi

# Retry parameters
max_retries=30
retry_count=0

while [ $retry_count -lt $max_retries ]; do
    currentblock=$(curl -s 'https://utopian.is/api/explorer/blocks/get' \
      -H 'accept: application/json, text/javascript, */*; q=0.01' \
      -H 'accept-language: en-US,en;q=0.9,vi;q=0.8' \
      -H 'priority: u=1, i' \
      -H 'referer: https://utopian.is/explorer' \
      -H 'sec-ch-ua: "Google Chrome";v="131", "Chromium";v="131", "Not_A Brand";v="24"' \
      -H 'sec-ch-ua-mobile: ?0' \
      -H 'sec-ch-ua-platform: "Windows"' \
      -H 'sec-fetch-dest: empty' \
      -H 'sec-fetch-mode: cors' \
      -H 'sec-fetch-site: same-origin' \
      -H 'user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36' \
      -H 'x-requested-with: XMLHttpRequest' | grep -o '"block":[0-9]*' | awk -F: '{print $2}' | head -n 1)

    if [ -n "$currentblock" ]; then
        break
    else
        retry_count=$((retry_count + 1))
        echo "Attempt $retry_count/$max_retries failed to fetch current block. Retrying in 10 seconds..."
        sleep 10
    fi
done

if [ -z "$currentblock" ]; then
    echo "Failed to fetch the current block after $max_retries attempts. Exiting..."
    send_telegram_notification "$nowDate%0A%0AWARRING!!!%0A%0AIP: $PUBLIC_IP%0AFailed to fetch the current block after $max_retries attempts."
    exit 1
fi

echo -e "${GREEN}Current Block: $currentblock${NC}"
block=$((currentblock - 10))
totalThreads=$(docker ps | grep debian:bullseye-slim | wc -l)

if [ "$totalThreads" -le 1 ]; then
    oldTotalThreads=$totalThreads
    cpu_cores=$(lscpu | grep '^CPU(s):' | awk '{print $2}')
    echo "CPU Cores: $cpu_cores"
    if [ "$cpu_cores" -le 8 ]; then
        echo "Set totalThreads=2"
        totalThreads=2
    else
       if [ "$cpu_cores" -eq 16 ]; then
             echo "Set totalThreads=5"
             totalThreads=5
       fi
       if [ "$cpu_cores" -eq 48 ]; then
             echo "Set totalThreads=12"
             totalThreads=12
       fi
    fi
    send_telegram_notification "$nowDate%0A%0AWARRING!!!%0A%0AIP: $PUBLIC_IP%0AISP: $ISP%0AORG: $ORG%0ACOUNTRY: $COUNTRY%0AREGION: $REGION%0ACITY: $CITY%0A%0APBKEY: $PBKEY%0ASet total threads from $oldTotalThreads to $totalThreads!"
fi

echo "PBKEY: $PBKEY"
echo "Total threads: $totalThreads"
allthreads=$(docker ps --format '{{.Names}}|{{.Status}}' --filter ancestor=debian:bullseye-slim | awk -F\| '{print $1}')

restarted_threads=()
numberRestarted=0

for val in $allthreads; do 
    if [ $(docker logs $val --tail 200 2>&1 | grep -i "Error! System clock seems incorrect" | wc -l) -eq 1 ]; then 
        #sudo docker restart $val
        #echo -e "${RED}Restart: $val - Error! System clock seems incorrect${NC}"
        sudo docker rm -f $val
        echo -e "${RED}Remove: $val - Error! System clock seems incorrect${NC}"
        restarted_threads+=("$val - Error! System clock seems incorrect")
        ((numberRestarted+=1))
    fi
done

threads=$(docker ps --format '{{.Names}}|{{.Status}}' --filter ancestor=debian:bullseye-slim | grep -e "40 hours" -e "41 hours" -e "42 hours" -e "43 hours" -e "44 hours" -e "45 hours" -e "46 hours" -e "47 hours" -e "48 hours" -e "2 days" -e "3 days" -e "4 days" -e "5 days" -e "6 days" -e "7 days" -e "8 days" -e "9 days" -e "10 days" -e "11 days" -e "12 days" -e "13 days" -e "14 days" -e "15 days" -e "16 days"  -e "17 days" -e "18 days" -e "19 days" -e "20 days" -e "21 days" -e "22 days" -e "23 days" -e "24 days" -e "25 days" -e "26 days" -e "27 days" -e "28 days" -e "29 days" -e "30 days" -e "31 days" -e "2 weeks" -e "1 weeks" -e "1 week" -e "3 weeks" -e "4 weeks" -e "5 weeks" -e "6 weeks" -e "7 weeks" -e "8 weeks" -e "9 weeks" -e "10 weeks" -e "11 weeks" -e "12 weeks" -e "13 weeks" -e "1 months" -e "2 months" -e "3 months" -e "4 months" -e "5 months" -e "6 months" -e "7 months" -e "8 months" -e "9 months" -e "10 months" -e "11 months" -e "12 months" -e "1 years" -e "1 year" -e "2 years" -e "3 years" -e "4 years" -e "5 years" | awk -F\| '{print $1}')

for val in $threads; do 
    lastblock=$(docker logs $val --tail 200 | awk '/Processed block/ {block=$NF} END {print block}')
    echo "Last block of $val: $lastblock"
    if [ -z "$lastblock" ]; then 
        #sudo docker restart $val
        #echo -e "${RED}Restart: $val - Not activated${NC}"
        sudo docker rm -f $val
        echo -e "${RED}Remove: $val - Not activated after 40 hours${NC}"
        restarted_threads+=("$val - Not activated after 40 hours")
        ((numberRestarted+=1))
    elif [ "$lastblock" -le "$block" ]; then 
        #sudo docker restart $val
        #echo -e "${RED}Restart: $val - Missing $(($currentblock - $lastblock)) blocks${NC}"
        sudo docker rm -f $val
        echo -e "${RED}Remove: $val - Missing $(($currentblock - $lastblock)) blocks${NC}"
        restarted_threads+=("$val - Last Block $lastblock - Missing $(($currentblock - $lastblock)) blocks")
        ((numberRestarted+=1))
    else 
        echo -e "${GREEN}Passed${NC}"
    fi
done

# Function to download a file with retries
download_file() {
    local file_name=$1
    local url="https://github.com/anhtuan9414/uam-docker/raw/master/uam-swarm/$file_name"
    local output=$file_name
    local wait_seconds=5
    local retry_count=0
    local max_retries=100

    while [ $retry_count -lt $max_retries ]; do
        wget --no-check-certificate -q "$url" -O "$output"

        if [ $? -eq 0 ]; then
            echo "Download successful: $file_name saved as $output."
            return 0
        else
            retry_count=$((retry_count + 1))
            echo "Download failed. Retrying in $wait_seconds seconds..."
            echo "Retrying to download $file_name from $url (Attempt $retry_count/$max_retries)..."
            sleep $wait_seconds
        fi
    done

    echo "Failed to download $file_name after $max_retries attempts."
    send_telegram_notification "WARRING!!!%0A$nowDate%0A%0AFailed to download $file_name after $max_retries attempts.%0A%0AIP: $PUBLIC_IP%0AISP: $ISP%0AORG: $ORG%0ACOUNTRY: $COUNTRY%0AREGION: $REGION%0ACITY: $CITY%0A%0ACURRENT BLOCK: $currentblock%0APBKEY: $PBKEY%0ATOTAL THREADS: $totalThreads%0AREMOVED THREADS: $numberRestarted"
    exit 1
}

run_docker_compose_with_retry() {
    local pbkey=$1
    local file_name=$2
    local max_retries=100
    local wait_seconds=10
    local retry_count=0

    while [ $retry_count -lt $max_retries ]; do
    
        PBKEY=$pbkey docker-compose -f "$file_name" up -d --no-recreate
        
        if [ $? -eq 0 ]; then
            return 0
        else
            echo "docker-compose up failed. Retrying in $wait_seconds seconds..."
            retry_count=$((retry_count + 1))
            echo "Retrying docker-compose with PBKEY=$PBKEY and file $file_name (Attempt $retry_count/$max_retries)..."
            sleep $wait_seconds
        fi
    done

    echo "docker-compose up failed after $max_retries attempts."
    send_telegram_notification "WARRING!!!%0A$nowDate%0A%0Adocker-compose up with PBKEY=$PBKEY and file $file_name failed after $max_retries attempts.%0A%0AIP: $PUBLIC_IP%0AISP: $ISP%0AORG: $ORG%0ACOUNTRY: $COUNTRY%0AREGION: $REGION%0ACITY: $CITY%0A%0ACURRENT BLOCK: $currentblock%0APBKEY: $PBKEY%0ATOTAL THREADS: $totalThreads%0AREMOVED THREADS: $numberRestarted"
    exit 1
}

if [ ${#restarted_threads[@]} -gt 0 ]; then

    echo "Starting the reinstallation of threads..."
    file_name=$totalThreads-docker-compose.yml
    download_file $file_name
    download_file "entrypoint.sh"
    run_docker_compose_with_retry "$PBKEY" "$file_name"
    
    echo -e "${GREEN}Reinstalled ${numberRestarted} threads successfully!${NC}"

    thread_list=""
    for thread in "${restarted_threads[@]}"; do
        thread_list+="- $thread%0A"
    done
    
    send_telegram_notification "$nowDate%0A%0AIP: $PUBLIC_IP%0AISP: $ISP%0AORG: $ORG%0ACOUNTRY: $COUNTRY%0AREGION: $REGION%0ACITY: $CITY%0A%0ACURRENT BLOCK: $currentblock%0APBKEY: $PBKEY%0ATOTAL THREADS: $totalThreads%0ARESTARTED THREADS: $numberRestarted%0A$thread_list"
fi
