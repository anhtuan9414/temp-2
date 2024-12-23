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
  -H "user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36"
  -H "sec-fetch-dest: empty"
  -H "sec-fetch-mode: cors"
  -H "sec-fetch-site: cross-site"
  -H "Referer: $REFERER"
  -H "Referrer-Policy: strict-origin-when-cross-origin"
)


# Retire a node by pubKey
retire_node() {
  local pubKey=$1
  echo "Retiring node: $pubKey"
  curl -s -X POST "$BASE_URL/$pubKey/retire" -d '{}' "${HEADERS[@]}" \
    && echo "Node $pubKey retired successfully." \
    || echo "Failed to retire node $pubKey."
}

# Fetch all nodes
process_nodes() {
  echo "Fetching nodes..."
  response=$(curl -s -X GET "$BASE_URL" "${HEADERS[@]}")
  if [ -z "$response" ]; then
    echo "No response received from $BASE_URL."
    exit 1
  else
    # Count the number of nodes by counting the occurrences of curly braces
    node_count=$(echo "$response" | jq length)
    echo "Number of nodes: $node_count"
    echo "$response" | jq -c '.[]' | while read -r node; do
      # Extract the pubKey, isConnected, and isRetired fields using jq
      pubKey=$(echo "$node" | jq -r '.pubKey')
      isConnected=$(echo "$node" | jq -r '.isConnected')
      isRetired=$(echo "$node" | jq -r '.isRetired')
    
      # Output the values
      echo "pubKey: $pubKey, isConnected: $isConnected, isRetired: $isRetired"
    
      # Check if isConnected is false and isRetired is false
      if [[ "$isConnected" == "false" && "$isRetired" == "false" ]]; then
        # Add the pubKey to the nodes_to_retire array
        retire_node "$pubKey"
      fi
    done
  fi
}

# Run the script
process_nodes
