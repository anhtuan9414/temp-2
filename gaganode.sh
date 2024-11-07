#!/bin/bash

# Check if the token is passed as an argument
if [ -z "$1" ]; then
    echo "Usage: $0 <GAGANODE_TOKEN>"
    exit 1
fi

# Set the token variable from the argument
GAGANODE_TOKEN="$1"

# Step 1: Download and unzip
echo "Downloading and extracting apphub..."
curl -o apphub-linux-amd64.tar.gz https://assets.coreservice.io/public/package/60/app-market-gaga-pro/1.0.4/app-market-gaga-pro-1_0_4.tar.gz
tar -zxf apphub-linux-amd64.tar.gz
rm -f apphub-linux-amd64.tar.gz
cd ./apphub-linux-amd64 || { echo "Failed to enter directory"; exit 1; }

# Step 2: Remove existing service and install new service
echo "Removing existing service and installing new service..."
sudo ./apphub service remove
sudo ./apphub service install

# Step 3: Start the service
echo "Starting service..."
sudo ./apphub service start

# Step 4: Check app status in a loop until "gaganode" is running
echo "Checking app status until Gaganode is RUNNING..."
while true; do
    status_output=$(./apphub status)
    echo "$status_output"

    # Verify if gaganode status is 'RUNNING'
    if echo "$status_output" | grep -q "gaganode.*status:\[RUNNING\]"; then
        echo "Gaganode is RUNNING."
        break
    else
        echo "Gaganode is not running. Retrying in 5 seconds..."
        sleep 5
    fi
done

# Step 5: Set token
echo "Setting token..."
sudo ./apps/gaganode/gaganode config set --token="$GAGANODE_TOKEN"

# Step 6: Restart the app
echo "Restarting app..."
./apphub restart

# Step 7: Check Gaganode status in a loop until it's running after restart
echo "Verifying Gaganode status after restart..."
while true; do
    status_output=$(./apphub status)
    echo "$status_output"

    # Verify if gaganode status is 'RUNNING'
    if echo "$status_output" | grep -q "gaganode.*status:\[RUNNING\]"; then
        echo "Gaganode is RUNNING after restart."
        break
    else
        echo "Gaganode is not running after restart. Retrying in 5 seconds..."
        sleep 5
    fi
done

echo "Script completed successfully."
