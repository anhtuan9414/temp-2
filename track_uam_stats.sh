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
lastBlockStats=lastBlockStats_$API_KEY.txt
fromBlock=$(cat $lastBlockStats 2>/dev/null)
get_balance_self() {
    max_retries=30
    retry_count=0
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
            balance=$(echo $data | grep -oP '"result":\s*\K\d+\.\d+')
            break
        else
            retry_count=$((retry_count + 1))
            echo "Attempt $retry_count/$max_retries failed to fetch balance. Retrying in 10 seconds..."
            sleep 10
        fi
    done
}

get_crp_price() {
    max_retries=30
    retry_count=0
    while [ $retry_count -lt $max_retries ]; do
        local data=$(curl 'https://crp.is:8182/market/pairs' \
                      -H 'Accept: application/json, text/plain, */*' \
                      -H 'Accept-Language: en-US,en;q=0.9,vi;q=0.8' \
                      -H 'Connection: keep-alive' \
                      -H 'Origin: https://crp.is' \
                      -H 'Referer: https://crp.is/' \
                      -H 'Sec-Fetch-Dest: empty' \
                      -H 'Sec-Fetch-Mode: cors' \
                      -H 'Sec-Fetch-Site: same-site' \
                      -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36' \
                      -H 'sec-ch-ua: "Chromium";v="134", "Not:A-Brand";v="24", "Google Chrome";v="134"' \
                      -H 'sec-ch-ua-mobile: ?0' \
                      -H 'sec-ch-ua-platform: "Windows"')
    
        if [ -n "$data" ] && [ "$data" != "null" ]; then
            crpPrice=$(echo $data | jq '.result.pairs[] | select(.pair.pair == "crp_usdt") | '.data_market.close'')
            break
        else
            retry_count=$((retry_count + 1))
            echo "Attempt $retry_count/$max_retries failed to fetch crp price. Retrying in 10 seconds..."
            sleep 10
        fi
    done
}

lastMiningDateStats=lastMiningDateStats_$API_KEY.txt
fromDate=$(cat $lastMiningDateStats 2>/dev/null)
get_mining_info() {
    if [ -z "$fromDate" ] || [ "$fromDate" == "null" ]; then
        fromDate=""
    fi
    local res=$(curl -s -X POST $API_URL/api/1.0 \
                    -H "Content-Type: application/json" \
                    -d '{
                        "method": "getFinanceHistory",
                        "params": {
                            "currency": "CRP",
                            "filters": "ALL_MINING",
                            "fromDate": "'"$fromDate"'"
                        },
                        "token": "'"$API_KEY"'"
                    }' | jq -c '.result[0]')
    miningReward=$(echo "$res" | jq -r '.amount_string')
    miningDetails=$(echo "$res" | jq -r '.details')
    miningCreated=$(echo "$res" | jq -r '.created')
}

get_usdt_vnd_rate() {
    local res=$(curl --compressed 'https://p2p.binance.com/bapi/c2c/v2/friendly/c2c/adv/search' \
  -H "Content-Type: application/json" \
  --data-raw '{"fiat":"VND","page":1,"rows":1,"tradeType":"SELL","asset":"USDT","countries":[],"proMerchantAds":false,"shieldMerchantAds":false,"filterType":"tradable","periods":[],"additionalKycVerifyFilter":0,"publisherType":"merchant","payTypes":[],"classifies":["mass","profession","fiat_trade"],"tradedWith":false,"followed":false}')
    sellRate=$(echo "$res" | jq -r '.data[0].adv.price')
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
get_crp_price
get_mining_info
get_usdt_vnd_rate

echo $lastBlock > $lastBlockStats
echo -e "${GREEN}Last Block Time: $lastBlockTime${NC}"
echo -e "${GREEN}Last Block: $lastBlock${NC}"
echo -e "${GREEN}Mining Threads: $miningThreads${NC}"
echo -e "${GREEN}Reward Per Thread: $rewardPerThread CRP${NC}"
echo -e "${GREEN}Total Mining Threads: $totalMiningThreads${NC}"
echo -e "${GREEN}CRP/USDT (based crp.is): $crpPrice\$${NC}"
echo -e "${GREEN}USDT/VND P2P: $(LC_NUMERIC=en_US.UTF-8 printf "%'.0f\n" "$sellRate")đ${NC}"

value=$(echo "$crpPrice * $balance" | bc -l)
formattedValue=$(printf "%.4f" "$value")
vndValue=$(echo "$sellRate * $formattedValue" | bc -l)
vndFormattedValue=$(LC_NUMERIC=en_US.UTF-8 printf "%'.0f\n" "$vndValue")


echo -e "${GREEN}CRP Balance: $balance CRP ≈ $formattedValue\$ ≈ $vndFormattedValueđ${NC}"

messageBot="$nowDate%0A%0A⛏️ MINING STATS%0A%0A🍀 CRP/USDT (based crp.is): $crpPrice\$%0A🍀 USDT/VND Binance P2P: $(LC_NUMERIC=en_US.UTF-8 printf "%'.0f\n" "$sellRate")đ%0A🍀 CRP Balance: $balance CRP ≈ $formattedValue\$ ≈ $vndFormattedValueđ%0A🍀 Mining Threads: $miningThreads%0A🍀 Last Block: $lastBlock%0A🍀 Last Block Time: $lastBlockTime%0A🍀 Reward Per Thread: $rewardPerThread CRP%0A🍀 Total Mining Threads: $totalMiningThreads%0A"
if [ -n "$miningReward" ] && [ "$miningReward" != "null" ]; then
   echo $miningCreated > $lastMiningDateStats
   formattedTime=$(date -d "$miningCreated UTC +7 hours" +"%d-%m-%Y %H:%M")
   miningRewardValue=$(echo "$crpPrice * $miningReward" | bc -l)
   formattedMiningRewardValue=$(printf "%.4f" "$miningRewardValue")
   miningRewardVndValue=$(echo "$sellRate * $formattedMiningRewardValue" | bc -l)
   formattedMiningRewardVndValue=$(LC_NUMERIC=en_US.UTF-8 printf "%'.0f\n" "$miningRewardVndValue")
   messageBot+="🍀 $miningDetails [$formattedTime]: $miningReward CRP ≈ $formattedMiningRewardValue$ ≈ $formattedMiningRewardVndValueđ"
   echo -e "${GREEN}$miningDetails [$formattedTime]: $miningReward CRP ≈ $formattedMiningRewardValue\$ ≈ $formattedMiningRewardVndValueđ${NC}"
fi

if [ "$lastBlock" -gt "$fromBlock" ]; then
   send_telegram_notification "$messageBot"
fi
