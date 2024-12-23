#!/bin/bash

# Check if AUTH_TOKEN is provided as an argument
if [ -z "$1" ]; then
  echo "Usage: $0 <AUTH_TOKEN>"
  exit 1
fi

AUTH_TOKEN="Bearer $1"
BASE_URL="https://gateway-run.bls.dev/api/v1/nodes"
REFERER="https://bless.network/"

# Headers for curl requests
HEADERS=(
  -H "accept: */*"
  -H "accept-language: en-US,en;q=0.9,vi;q=0.8"
  -H "authorization: $AUTH_TOKEN"
  -H "content-type: application/json"
  -H "priority: u=1, i"
  -H "sec-ch-ua: \"Google Chrome\";v=\"131\", \"Chromium\";v=\"131\", \"Not_A Brand\";v=\"24\""
  -H "sec-ch-ua-mobile: ?0"
  -H "sec-ch-ua-platform: \"Windows\""
  -H "sec-fetch-dest: empty"
  -H "sec-fetch-mode: cors"
  -H "sec-fetch-site: cross-site"
  -H "Referer: $REFERER"
  -H "Referrer-Policy: strict-origin-when-cross-origin"
)

# Fetch all nodes
fetch_nodes() {
  echo "Fetching nodes..."
  response=$(curl -s -X GET "$BASE_URL" "${HEADERS[@]}")
  echo "$response"
}

# Retire a node by pubKey
retire_node() {
  local pubKey=$1
  echo "Retiring node: $pubKey"
  curl -s -X POST "$BASE_URL/$pubKey/retire" -d '{}' "${HEADERS[@]}" \
    && echo "Node $pubKey retired successfully." \
    || echo "Failed to retire node $pubKey."
}

# Main function to filter and retire nodes
process_nodes() {
  nodes=$(fetch_nodes)

  # Filter for isConnected=false and isRetired=false manually
  echo "$nodes" | tr -d '\n' | grep -oE '{[^}]+}' | while IFS= read -r node; do
    isConnected=$(echo "$node" | grep -o '"isConnected":false')
    isRetired=$(echo "$node" | grep -o '"isRetired":false')
    pubKey=$(echo "$node" | grep -o '"pubKey":"[^"]*' | awk -F':' '{print $2}' | tr -d '"')

    if [[ -n "$isConnected" && -n "$isRetired" && -n "$pubKey" ]]; then
      retire_node "$pubKey"
    fi
  done
}

# Run the script
process_nodes
