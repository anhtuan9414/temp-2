#!/bin/bash
nowDate=$(date +"%Y-%m-%d %H:%M:%S %Z")
echo $nowDate

PBKEY=$(cat PBKEY.txt)
# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
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
max_ip_retries=20
ip_attempt=0

while (( ip_attempt < max_ip_retries )); do
    response=$(curl -s --fail http://ip-api.com/json)
    
    if [[ $? -eq 0 ]]; then
       break  # Exit script if successful
    fi

    ((ip_attempt++))
    echo "Attempt $ip_attempt/$max_ip_retries failed. Retrying in 2 seconds..."
    sleep 2
done

# Extract ISP and Org using grep and sed
ISP=$(echo "$response" | grep -oP '"isp":\s*"\K[^"]+')
ORG=$(echo "$response" | grep -oP '"org":\s*"\K[^"]+')
REGION=$(echo "$response" | grep -oP '"regionName":\s*"\K[^"]+')
CITY=$(echo "$response" | grep -oP '"city":\s*"\K[^"]+')
COUNTRY=$(echo "$response" | grep -oP '"country":\s*"\K[^"]+')

if [ -z "$PUBLIC_IP" ]; then
    PUBLIC_IP=$(echo "$response" | grep -oP '"query":\s*"\K[^"]+')
fi

# Display the results
echo "----------------------------"
echo "ISP: $ISP"
echo "Org: $ORG"
echo "Region: $REGION"
echo "City: $CITY"
echo "Country: $COUNTRY"
echo "----------------------------"

os_name=$(lsb_release -d 2>/dev/null | awk -F'\t' '{print $2}' || echo "OS info not available")

# Get total CPU cores
cpu_cores=$(lscpu | grep '^CPU(s):' | awk '{print $2}')

# Get average CPU load (1-minute average) as percentage
cpu_load=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')

# Get total RAM in MB
total_ram=$(grep MemTotal /proc/meminfo | awk '{printf "%.2f", $2 / 1024}')

# Get available RAM in MB
available_ram=$(grep MemAvailable /proc/meminfo | awk '{printf "%.2f", $2 / 1024}')

ram_usage=$(printf "%.1f" $(free | awk 'FNR == 2 {print $3/$2 * 100.0}'))

# Get Disk usage
disk_usage=$(df -h / | awk 'NR==2 {print $5}')

# Display the results
echo "System Information:"
echo "----------------------------"
echo "OS: $os_name"
echo "Total CPU Cores: $cpu_cores"
echo "CPU Load: $cpu_load%"
echo "Total RAM: $total_ram MB"
echo "RAM Usage: $ram_usage%"
echo "Available RAM: $available_ram MB"
echo "Disk Usage (Root): $disk_usage"
echo "----------------------------"

if [ "${disk_usage%\%}" -ge 90 ]; then
    echo -e "${YELLOW}LOW AVAILABLE DISK WARNING!!!${NC}"
    send_telegram_notification "$nowDate%0A%0A ⚠️⚠️ LOW AVAILABLE DISK WARNING!!!%0A%0AIP: $PUBLIC_IP%0AISP: $ISP%0AOrg: $ORG%0ACountry: $COUNTRY%0ARegion: $REGION%0ACity: $CITY%0A%0A✅ System Information:%0A----------------------------%0AOS: $os_name%0ATotal CPU Cores: $cpu_cores%0ACPU Load: $cpu_load%%0ATotal RAM: $total_ram MB%0ARAM Usage: $ram_usage%%0AAvailable RAM: $available_ram MB%0ADisk Usage (Root): $disk_usage"
fi

if [ "$(echo "$available_ram" | awk '{print int($1 + 0.5)}')" -le 300 ]; then
    echo -e "${YELLOW}LOW AVAILABLE RAM WARNING!!!${NC}"
    send_telegram_notification "$nowDate%0A%0A ⚠️⚠️ LOW AVAILABLE RAM WARNING!!!%0A%0AIP: $PUBLIC_IP%0AISP: $ISP%0AOrg: $ORG%0ACountry: $COUNTRY%0ARegion: $REGION%0ACity: $CITY%0A%0A✅ System Information:%0A----------------------------%0AOS: $os_name%0ATotal CPU Cores: $cpu_cores%0ACPU Load: $cpu_load%%0ATotal RAM: $total_ram MB%0ARAM Usage: $ram_usage%%0AAvailable RAM: $available_ram MB%0ADisk Usage (Root): $disk_usage"
fi

if [ -z "$PBKEY" ]; then
    echo -e "${YELLOW}PBKEY EMPTY!!!${NC}"
    send_telegram_notification "$nowDate%0A%0A ⚠️⚠️ PBKEY EMPTY WARNING!!!%0A%0AIP: $PUBLIC_IP%0AISP: $ISP%0AOrg: $ORG%0ACountry: $COUNTRY%0ARegion: $REGION%0ACity: $CITY%0A%0A✅ System Information:%0A----------------------------%0AOS: $os_name%0ATotal CPU Cores: $cpu_cores%0ACPU Load: $cpu_load%%0ATotal RAM: $total_ram MB%0ARAM Usage: $ram_usage%%0AAvailable RAM: $available_ram MB%0ADisk Usage (Root): $disk_usage"
    exit 1
fi

# Retry parameters
max_retries=30
retry_count=0
setNewThreadUAM=0

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
    send_telegram_notification "$nowDate%0A%0A ⚠️⚠️ FETCH BLOCK WARNING!!!%0A%0AIP: $PUBLIC_IP%0AISP: $ISP%0AOrg: $ORG%0ACountry: $COUNTRY%0ARegion: $REGION%0ACity: $CITY%0A%0A✅ System Information:%0A----------------------------%0AOS: $os_name%0ATotal CPU Cores: $cpu_cores%0ACPU Load: $cpu_load%%0ATotal RAM: $total_ram MB%0ARAM Usage: $ram_usage%%0AAvailable RAM: $available_ram MB%0ADisk Usage (Root): $disk_usage%0A%0A✅ UAM Information:%0A----------------------------%0APBKey: $PBKEY%0A%0AFailed to fetch the current block after $max_retries attempts."
    exit 1
fi

echo -e "${GREEN}Current Block: $currentblock${NC}"
block=$((currentblock - 24))
totalThreads=$(tmux list-sessions | grep -c "^Utopia")

echo "PBKEY: $PBKEY"
echo "Total Threads: $totalThreads"

if [[ $totalThreads -lt 1 ]]; then
    totalThreads=1
    setNewThreadUAM=1
else
  restarted_threads=()
  numberRestarted=0
  
  if [ $(sudo tail -n 500 /root/miner.log 2>&1 | grep -i "Error! System clock seems incorrect" | wc -l) -eq 1 ]; then 
    sudo pkill tmux
    echo -e "${RED}Error! System clock seems incorrect${NC}"
    restarted_threads+=("Error! System clock seems incorrect")
    ((numberRestarted+=1))
  else
    lastblock=$(sudo tail -n 500 /root/miner.log 2>&1 | grep -v "sendto: Invalid argument" | awk '/Processed block/ {block=$NF} END {print block}')
    echo "Last block: $lastblock"
    runningTime=$(sudo tmux list-sessions -F "#{session_name} #{session_created}" | awk '$1 == "Utopia" {print $2}' | xargs -I {} bash -c 'elapsed=$(( $(date +%s) - {} )); echo $((elapsed/3600))')
    if [[ -z "$lastblock" && "$runningTime" -ge 35 ]]; then
        sudo pkill tmux
        echo -e "${RED}Not activated after ${runningTime} hours${NC}"
        restarted_threads+=("Not activated after ${runningTime} hours")
        ((numberRestarted+=1))
    elif [ "$lastblock" -le "$block" ]; then 
        sudo pkill tmux
        echo -e "${RED}Missed: $(($currentblock - $lastblock)) blocks${NC}"
        restarted_threads+=("Last Block: $lastblock - Missed: $(($currentblock - $lastblock)) blocks")
        ((numberRestarted+=1))
    else 
        echo -e "${GREEN}Passed${NC}"
    fi
  fi
fi

install_uam() {
    local pbkey=$1
    local max_retries=50
    local wait_seconds=15
    local retry_count=0
    echo "Starting the reinstallation of threads..."
    while [ ! -f /root/miner.log ] && [ $retry_count -lt $max_retries ]; do
        # Start a new or attach to the existing tmux session
        sudo pkill tmux
        sudo rm -f /root/miner.log
        sudo tmux new -A -s Utopia -d
        # Send commands to the tmux session
        sudo tmux send-keys -t Utopia "cd /root && wget -O/root/uam.deb --no-check-certificate https://github.com/anhtuan9414/temp-2/raw/main/uam-latest_amd64.deb && sudo dpkg -i uam.deb && /opt/uam/uam --pk $pbkey" Enter
        
        sleep $wait_seconds
        
        if [ -f /root/miner.log ]; then
            return 0
        else
            echo "UAM up failed"
            retry_count=$((retry_count + 1))
            echo "Retrying UAM with PBKEY=$pbkey (Attempt $retry_count/$max_retries)..."
        fi
    done

    echo "UAM up failed after $max_retries attempts."
    send_telegram_notification "$nowDate%0A%0A ⚠️⚠️ UAM WARNING!!!%0A%0AIP: $PUBLIC_IP%0AISP: $ISP%0AOrg: $ORG%0ACountry: $COUNTRY%0ARegion: $REGION%0ACity: $CITY%0A%0A✅ System Information:%0A----------------------------%0AOS: $os_name%0ATotal CPU Cores: $cpu_cores%0ACPU Load: $cpu_load%%0ATotal RAM: $total_ram MB%0ARAM Usage: $ram_usage%%0AAvailable RAM: $available_ram MB%0ADisk Usage (Root): $disk_usage%0A%0A✅ UAM Information:%0A----------------------------%0ACurrent Block: $currentblock%0APBKey: $PBKEY%0ATotal Threads: $totalThreads%0A%0AUAM up with PBKEY=$pbkey failed after $max_retries attempts."
    exit 1
    echo -e "${GREEN}Installed ${total_threads} threads successfully!${NC}"
}

if [ "$setNewThreadUAM" -gt 0 ] || [ ${#restarted_threads[@]} -gt 0 ]; then
    install_uam $PBKEY
fi

if [ ${#restarted_threads[@]} -gt 0 ]; then
    thread_list=""
    for thread in "${restarted_threads[@]}"; do
        thread_list+="🙏 $thread%0A"
    done
    
    send_telegram_notification "$nowDate%0A%0A ⚠️ UAM RESTART ALERT!!!%0A%0AIP: $PUBLIC_IP%0AISP: $ISP%0AOrg: $ORG%0ACountry: $COUNTRY%0ARegion: $REGION%0ACity: $CITY%0A%0A✅ System Information:%0A----------------------------%0AOS: $os_name%0ATotal CPU Cores: $cpu_cores%0ACPU Load: $cpu_load%%0ATotal RAM: $total_ram MB%0ARAM Usage: $ram_usage%%0AAvailable RAM: $available_ram MB%0ADisk Usage (Root): $disk_usage%0A%0A✅ UAM Information:%0A----------------------------%0ACurrent Block: $currentblock%0APBKey: $PBKEY%0ATotal Threads: $totalThreads%0ARestarted Threads: $numberRestarted%0A$thread_list"
fi
