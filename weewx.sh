#!/bin/sh
printf "187EMIava\n" | sudo -S apt update
wait
# Install Required dependencies
set -e
sudo apt install python3-configobj
wait
set -e
sudo apt install python3-pil
set -e
wait
set -e
sudo apt install python3-serial
wait
set -e
sudo apt install python3-usb
wait
set -e
sudo apt install python3-pip
wait
# This works for most installations...
set -e
sudo apt install python3-cheetah || sudo pip3 install Cheetah3
wait
# Optional: for extended almanac information
set -e
sudo apt install python3-ephem
wait
#install weewx
set -e
wget https://weewx.com/downloads/weewx-4.5.1.tar.gz
wait
set -e
tar xvfz weewx-X.Y.Z.tar.gz
wait
cd weewx-4.5.1
set -e
python3 ./setup.py build
wait
set -e
sudo python3 ./setup.py install --no-prompt
wait
#install weewx interceptor
set -e
wget -O weewx-interceptor.zip https://github.com/matthewwall/weewx-interceptor/archive/master.zip
wait
set -e
sudo /home/weewx/bin/wee_extension --install weewx-interceptor.zip
wait
#configure weewx interceptor
set -e
sudo /home/weewx/bin/wee_config --reconfigure --driver=user.interceptor --no-prompt
wait
wget -L https://raw.githubusercontent.com/Djblaik/weewx-installer/main/weewx.conf?token=AEZB4Q4J26UNALCNIKMU27DBYQAAW
wait
sudo rm /home/weewx.conf
sudo mv weewx.conf /home/weewx
#run as daemon automatically when the computer starts
wait
set -e
sudo cp /home/weewx/util/init.d/weewx.debian /etc/init.d/weewx
wait
set -e
sudo chmod +x /etc/init.d/weewx
set -e
sudo update-rc.d weewx defaults 98