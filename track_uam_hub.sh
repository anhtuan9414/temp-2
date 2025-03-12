#!/bin/bash
nowDate=$(date +"%Y-%m-%d %H:%M:%S %Z")
echo $nowDate
imageName=tuanna9414/uam:latest
sudo chmod 777 /var/run/docker.sock
totalThreads=$(docker ps | grep $imageName | wc -l)
cpu_cores=$(lscpu | grep '^CPU(s):' | awk '{print $2}')
if [[ $cpu_cores -eq 4 && $totalThreads -eq 2 ]]; then
    docker rm -f $(docker ps -aq --filter ancestor=tuanna9414/uam:latest)
    docker run -d --restart always --name uam_1 -e WALLET=53F57E23ACBBA1F843F481C545549ECB9371CC05FD62AA74FAC6CD8D70AA0E4C --cap-add=IPC_LOCK --net=host tuanna9414/uam:latest
fi
