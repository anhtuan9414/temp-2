#!/bin/bash
echo $(date +"%Y-%m-%d %H:%M:%S")
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'
while true; do
    currentblock=$(curl 'https://utopian.is/api/explorer/blocks/get' \
  -H 'accept: application/json, text/javascript, */*; q=0.01' \
  -H 'accept-language: en-US,en;q=0.9,vi;q=0.8' \
  -H 'cookie: _pk_id.1.ef23=3dc49b029eda0ec0.1719399473.; _pk_ses.1.ef23=1; SL_G_WPT_TO=vi; SL_GWPT_Show_Hide_tmp=1; SL_wptGlobTipTmp=1; XSRF-TOKEN=eyJpdiI6Ijc4N0dsSHZMMFJEbWlrY3JhczZrbXc9PSIsInZhbHVlIjoic0lab0FZVWgzWldjZWhtS1A0cmhPM2RWYXNuQUxHQlVMdWwzL256dHlDejF1ZUVYQXVzcmIrOTl0NVRrRXNvbHZzOEdKeG5KLzZoTUlsNXJ1bzJvNDRxZzFsc3BtNGhWL0l2MmQxRkhMRFNNU2RuaXpYTGNuWm1wc3U4dXhIZ2EiLCJtYWMiOiJhMGExYmI2YzZkZTRiZDFjOWMxZTc2MjcwYmI3NzBkODE1MjUxMmFlY2E5ZDc1NWUzNzgzZmE4Yzg1MzU0MjcxIiwidGFnIjoiIn0%3D; utopian_session=eyJpdiI6InFDMUovUnpkRHdESk9OaS9nQjM0Qmc9PSIsInZhbHVlIjoieVJXbnNTY3VCT3l6OSthZXUwY2lXdU1hMDkrOE90N25HUk1DNUtvQTNIYUxOOE9aTlY0MmROZ3JYZVBkK045SWZNSUQxWFFzM3g4dHBGOFh2YmJNM09MbFgvUnlqL2l0RmJrMy9uRDRuU01SVjY0RjM1S0hkdlE5T1ZPNUpGSGUiLCJtYWMiOiJiZWRkYTAyNDA5OWM1NmRiNzk3NWJjNGIzNTQzMzYwMjNjMjk0OTkyMWQ4ZDAwNjhmNGYyOWU0YjU5MWE3MGVlIiwidGFnIjoiIn0%3D' \
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
        echo "Failed to fetch current block from the API. Retrying in 5 seconds..."
        sleep 5
    fi
done
echo -e "${GREEN}Current Block: $currentblock${NC}"
block=$((currentblock - 10))
sudo chmod 666 /var/run/docker.sock
PBKEY=$(docker exec uam_1 printenv PBKEY)
totalThreads=$(docker ps | grep debian:bullseye-slim | wc -l)
echo "PBKEY: $PBKEY"
echo "Total threads: $totalThreads"
allthreads=$(docker ps --format '{{.Names}}|{{.Status}}' --filter ancestor=debian:bullseye-slim | awk -F\| '{print $1}')
for val in $allthreads; do if [ $(docker logs $val --tail 200 2>&1 | grep -i "Error! System clock seems incorrect" | wc -l) -eq 1 ]; then name=$(sudo docker restart $val); echo -e "${RED}Restart: $val - Error! System clock seems incorrect${NC}"; fi; done;
threads=$(docker ps --format '{{.Names}}|{{.Status}}' --filter ancestor=debian:bullseye-slim | grep -e "30 hours" -e "31 hours" -e "32 hours" -e "33 hours" -e "34 hours" -e "35 hours" -e "36 hours" -e "37 hours" -e "38 hours" -e "39 hours" -e "40 hours" -e "41 hours" -e "42 hours" -e "43 hours" -e "44 hours" -e "45 hours" -e "46 hours" -e "47 hours" -e "48 hours" -e "2 days" -e "3 days" -e "4 days" -e "5 days" -e "6 days" -e "7 days" -e "8 days" -e "9 days" -e "10 days" -e "11 days" -e "12 days" -e "13 days" -e "14 days" -e "15 days" -e "16 days"  -e "17 days" -e "18 days" -e "19 days" -e "20 days" -e "21 days" -e "22 days" -e "23 days" -e "24 days" -e "25 days" -e "26 days" -e "27 days" -e "28 days" -e "29 days" -e "30 days" -e "31 days" -e "2 weeks" -e "1 weeks" -e "1 week" -e "3 weeks" -e "4 weeks" -e "5 weeks" -e "6 weeks" -e "7 weeks" -e "8 weeks" -e "9 weeks" -e "10 weeks" -e "11 weeks" -e "12 weeks" -e "13 weeks" -e "1 months" -e "2 months" -e "3 months" -e "4 months" -e "5 months" -e "6 months" -e "7 months" -e "8 months" -e "9 months" -e "10 months" -e "11 months" -e "12 months" -e "1 years" -e "1 year" | awk -F\| '{print $1}')
echo "List of threads: $threads"
for val in $threads; do lastblock=$(docker logs $val --tail 200 | awk '/Processed block/ {block=$NF} END {print block}'); echo "Last block of $val: $lastblock" ; if [ -z $lastblock ]; then name=$(sudo docker restart $val); echo -e "${RED}Restart: $val - Not activated${NC}"; elif [ "$lastblock" -lt "$block" ]; then sudo docker restart $val >null; echo -e "${RED}Restart: $val - Missing $(($currentblock - $lastblock)) blocks${NC}"; else echo -e "${GREEN}Passed${NC}"; fi; done
