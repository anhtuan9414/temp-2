#!/bin/bash
echo $(date +"%Y-%m-%d %H:%M:%S")
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'
while true; do
    currentblock=$(curl -s https://utopian.is/api/explorer/blocks/get | grep -o '"block":[0-9]*' | awk -F: '{print $2}' | head -n 1)
    if [ -n "$currentblock" ]; then
        break
    else
        echo "Failed to fetch current block from the API. Retrying in 5 seconds..."
        sleep 5
    fi
done
echo -e "${GREEN}Current Block: $currentblock${NC}"
block=$((currentblock - 14))
allthreads=$(docker ps --format '{{.Names}}|{{.Status}}' --filter ancestor=debian:bullseye-slim | awk -F\| '{print $1}')
for val in $allthreads; do if [ $(docker logs $val --tail 200 2>&1 | grep -i "Error! System clock seems incorrect" | wc -l) -eq 1 ]; then name=$(sudo docker restart $val); echo -e "${RED}Restart: $val - Error! System clock seems incorrect${NC}"; fi; done;
threads=$(docker ps --format '{{.Names}}|{{.Status}}' --filter ancestor=debian:bullseye-slim | grep -e "2 days" -e "3 days" -e "4 days" -e "5 days" -e "6 days" -e "7 days" -e "8 days" -e "9 days" -e "10 days" -e "11 days" -e "12 days" -e "13 days" -e "14 days" -e "15 days" -e "16 days"  -e "17 days" -e "18 days" -e "19 days" -e "20 days" -e "21 days" -e "22 days" -e "23 days" -e "24 days" -e "25 days" -e "26 days" -e "27 days" -e "28 days" -e "29 days" -e "30 days" -e "31 days" -e "2 weeks" -e "1 weeks" -e "1 week" -e "3 weeks" -e "4 weeks" -e "5 weeks" -e "6 weeks" -e "7 weeks" -e "8 weeks" -e "9 weeks" -e "10 weeks" -e "11 weeks" -e "12 weeks" -e "13 weeks" -e "1 months" -e "2 months" -e "3 months" -e "4 months" -e "5 months" -e "6 months" -e "7 months" -e "8 months" -e "9 months" -e "10 months" -e "11 months" -e "12 months" -e "1 years" -e "1 year" | awk -F\| '{print $1}')
echo "List of threads: $threads"
for val in $threads; do lastblock=$(docker logs $val --tail 200 | awk '/Processed block/ {block=$NF} END {print block}'); echo "Last block of $val: $lastblock" ; if [ -z $lastblock ]; then name=$(sudo docker restart $val); echo -e "${RED}Restart: $val - Not activated${NC}"; elif [ "$lastblock" -lt "$block" ]; then sudo docker restart $val >null; echo -e "${RED}Restart: $val - Missing $(($currentblock - $lastblock)) blocks${NC}"; else echo -e "${GREEN}Passed${NC}"; fi; done
