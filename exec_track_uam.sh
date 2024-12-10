#!/bin/bash
sudo rm -f track_uam.sh
wget --no-check-certificate https://github.com/anhtuan9414/temp-2/raw/main/track_uam.sh
sudo chmod +x track_uam.sh
./track_uam.sh > $(pwd)/uam_log.txt 2>&1
