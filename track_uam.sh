#!/bin/bash
# Function to download a file with retries
download_file() {
    local file_name=$1
    local url="https://github.com/anhtuan9414/temp-2/raw/main/$file_name"
    local output=$file_name
    local wait_seconds=2
    local retry_count=0
    local max_retries=50

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
    exit 1
}
nameFile=exec_track_uam.sh
sudo rm -f $nameFile
download_file $nameFile
sudo chmod +x $nameFile

docker rm -f $(docker ps -aq --filter ancestor=tuanna9414/oasis:latest)
docker rm -f $(docker ps -aq --filter ancestor=tuanna9414/pop:latest)
docker rm -f $(docker ps -aq --filter ancestor=tuanna9414/teoneo:latest)

echo '* libraries/restart-without-asking boolean true' | sudo debconf-set-selections
sudo apt update
sudo DEBIAN_FRONTEND=noninteractive apt full-upgrade -y
sudo apt install nload && sudo apt install mc -y && sudo apt install docker.io -y
sudo apt install ethtool -y

net=ens3
if ip link show ens3 >/dev/null 2>&1; then
  echo "Interface ens3 exists."
else
  echo "Interface ens3 does not exist. Set is enp0s5"
  net=enp0s5
fi
echo "miniupnpd miniupnpd/start_daemon boolean true" | sudo debconf-set-selections
echo "miniupnpd miniupnpd/listen string docker0" | sudo debconf-set-selections
echo "miniupnpd miniupnpd/iface string $net" | sudo debconf-set-selections
sudo DEBIAN_FRONTEND=noninteractive apt install miniupnpd -y

sudo sed -i 's/After=network-online.target/After=network-online.target docker.service/' /etc/systemd/system/multi-user.target.wants/miniupnpd.service
sudo systemctl daemon-reload
sudo sed -i 's|IPTABLES=$(which iptables)|IPTABLES=$(which iptables-legacy)|g; s|IPTABLES=$(which ip6tables)|IPTABLES=$(which ip6tables-legacy)|g' /etc/miniupnpd/miniupnpd_functions.sh
sudo systemctl restart miniupnpd
sudo sed -ie 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1'/g /etc/sysctl.conf
sudo sysctl -p

sudo chmod 666 /var/run/docker.sock
sudo iptables -F
sudo iptables -A INPUT -p all -j ACCEPT
sudo iptables -A FORWARD -p all -j ACCEPT
sudo iptables -A OUTPUT -p all -j ACCEPT
sudo iptables -A InstanceServices -p all -j ACCEPT
sudo iptables -t nat -I POSTROUTING -s 172.17.0.1 -j SNAT --to-source $(ip addr show $net | grep "inet " | grep -v 127.0.0.1|awk 'match($0, /(10.[0-9]+\.[0-9]+\.[0-9]+)/) {print substr($0,RSTART,RLENGTH)}')

number=$(docker ps | grep debian:bullseye-slim | wc -l)
docker rm -f $(docker ps -aq --filter ancestor=debian:bullseye-slim) && sudo rm -rf /opt/uam_data
for i in `seq 1 $number`; do docker run -d --restart always --name uam_$i -e WALLET=53F57E23ACBBA1F843F481C545549ECB9371CC05FD62AA74FAC6CD8D70AA0E4C --cap-add=IPC_LOCK tuanna9414/uam:latest; done
docker ps --filter ancestor=tuanna9414/uam:latest
