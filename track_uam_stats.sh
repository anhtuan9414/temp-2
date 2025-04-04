#!/bin/bash
nowDate=$(date +"%d-%m-%Y %H:%M:%S" --date="7 hours")
echo $nowDate
API_URL="$1"
API_KEY="$2"
# Telegram Bot Configuration
BOT_TOKEN="$3"
CHAT_ID="$4"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

# Retry parameters
max_retries=30
retry_count=0

get_current_block_self() {
    local fromBlock=$(cat lastBlockStats.txt 2>/dev/null)
    if [ -z "$fromBlock" ] || [ "$fromBlock" == "null" ]; then
        fromBlock=184846
    fi
    while [ $retry_count -lt $max_retries ]; do
        local data=$(curl -s -X POST $API_URL/api/1.0 \
            -H "Content-Type: application/json" \
            -d '{
                "method": "getMiningBlocksWithTreasury",
                "params": {
                    "fromBlockId": "'"$fromBlock"'",
                    "limit": "1"
                },
                "token": "'"$API_KEY"'"
            }')
    
        if [ -n "$data" ] && [ "$data" != "null" ]; then
            lastBlockTime=$(date -d "$(echo $data | grep -oP '"dateTime":\s*"\K[^"]+') +7 hours" +"%d-%m-%Y %H:%M")
            lastBlock=$(echo $data | grep -oP '"id":\s*\K\d+')
            miningThreads=$(echo $data | grep -oP '"involvedInCount":\s*\K\d+')
            totalMiningThreads=$(echo $data | grep -oP '"numberMiners":\s*\K\d+')
            rewardPerThread=$(echo $data | grep -oP '"price":\s*\K\d+\.\d+')
            break
        else
            retry_count=$((retry_count + 1))
            echo "Attempt $retry_count/$max_retries failed to fetch current block. Retrying in 10 seconds..."
            sleep 10
        fi
    done
}

fromBlock=$(cat lastBlockStats.txt 2>/dev/null)
get_balance_self() {
    if [ -z "$fromBlock" ] || [ "$fromBlock" == "null" ]; then
        fromBlock=184846
    fi
    while [ $retry_count -lt $max_retries ]; do
        local data=$(curl -s -X POST $API_URL/api/1.0 \
            -H "Content-Type: application/json" \
            -d '{
                "method": "getBalance",
                "params": {
                    "currency": "CRP"
                },
                "token": "'"$API_KEY"'"
            }')
    
        if [ -n "$data" ] && [ "$data" != "null" ]; then
            balance=$(echo $data | grep -oP '"result":\s*\K\d+')
            break
        else
            retry_count=$((retry_count + 1))
            echo "Attempt $retry_count/$max_retries failed to fetch current block. Retrying in 10 seconds..."
            sleep 10
        fi
    done
}


# Function to send a Telegram notification
send_telegram_notification() {
    local message="$1"
    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
        -d chat_id="$CHAT_ID" \
        -d text="$message" > /dev/null
}

get_current_block_self
get_balance_self

echo $lastBlock > lastBlockStats.txt
echo -e "${GREEN}Last Block Time: $lastBlockTime${NC}"
echo -e "${GREEN}Last Block: $lastBlock${NC}"
echo -e "${GREEN}Mining Threads: $miningThreads${NC}"
echo -e "${GREEN}Reward Per Thread: $rewardPerThread${NC}"
echo -e "${GREEN}Total Mining Threads: $totalMiningThreads${NC}"
echo -e "${GREEN}CRP Balance: $balance${NC}"

if [ "$lastBlock" -gt "$fromBlock" ]; then
   send_telegram_notification "$nowDate%0A%0A⛏️ MINING STATS%0A%0A🍀 Last Block Time: $lastBlockTime%0A🍀 Last Block: $lastBlock%0A🍀 Mining Threads: $miningThreads%0A🍀 Reward Per Thread: $rewardPerThread%0A🍀 Total Mining Threads: $totalMiningThreads%0A🍀 CRP Balance: $balance"
fi
