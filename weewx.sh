#!/bin/sh
set -e
printf "187EMIava\n" | sudo -S apt update
# Install Required dependencies
sudo apt install python3-configobj
sudo apt install python3-pil
sudo apt install python3-serial
sudo apt install python3-usb
sudo apt install python3-pip
sudo apt install python3-cheetah || sudo pip3 install Cheetah3

# Optional: for extended almanac information
sudo apt install python3-ephem

#install weewx
wget https://weewx.com/downloads/weewx-4.5.1.tar.gz
tar xvfz weewx-X.Y.Z.tar.gz
cd weewx-4.5.1
python3 ./setup.py build
sudo python3 ./setup.py install --no-prompt

#install weewx interceptor
wget -O weewx-interceptor.zip https://github.com/matthewwall/weewx-interceptor/archive/master.zip
sudo /home/weewx/bin/wee_extension --install weewx-interceptor.zip

#configure weewx interceptor
sudo /home/weewx/bin/wee_config --reconfigure --driver=user.interceptor --no-prompt
wget https://raw.githubusercontent.com/Djblaik/weewx-installer/main/weewx.conf
sudo rm /home/weewx/weewx.conf
sudo mv weewx.conf /home/weewx

#run as daemon automatically when the computer starts
sudo cp /home/weewx/util/init.d/weewx.debian /etc/init.d/weewx
sudo chmod +x /etc/init.d/weewx
sudo update-rc.d weewx defaults 98

#install belchertown skin
wget https://github.com/poblabs/weewx-belchertown/releases/download/weewx-belchertown-1.2/weewx-belchertown-release-1.2.tar.gz
sudo /home/weewx/bin/wee_extension --install weewx-belchertown-release-1.2.tar.gz

#install nginx
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys $key
sudo apt update
sudo apt install nginx
cp var/www/html/50x.html /home/weewx/public_html/50x.hml
wget https://raw.githubusercontent.com/Djblaik/weewx-installer/main/nginx.conf
mv nginx.conf /etc/nginx/
sudo systemctl start weewx
sudo systemctl start nginx