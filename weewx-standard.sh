#!/bin/sh
set -e
sudo apt update
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
wget https://www.weewx.com/downloads/released_versions/weewx-4.10.2.tar.gz
tar xvfz weewx-4.10.2.tar.gz
cd weewx-4.10.2
python3 ./setup.py build
sudo python3 ./setup.py install --no-prompt
cd $user

#install weewx interceptor
wget -O weewx-interceptor.zip https://github.com/matthewwall/weewx-interceptor/archive/master.zip
sudo /home/weewx/bin/wee_extension --install weewx-interceptor.zip

#configure weewx interceptor
sudo /home/weewx/bin/wee_config --reconfigure --driver=user.interceptor --no-prompt
wget --header 'Authorization: token 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' https://raw.githubusercontent.com/Djblaik/weewx-installer/main/weewx.conf
sudo rm /home/weewx/weewx.conf
sudo mv weewx.conf /home/weewx

#run as daemon automatically when the computer starts
sudo cp /home/weewx/util/init.d/weewx.debian /etc/init.d/weewx
sudo chmod +x /etc/init.d/weewx
sudo update-rc.d weewx defaults 98

#install nginx
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys $key
sudo apt update
sudo apt install nginx
wget --header 'Authorization: token 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' https://raw.githubusercontent.com/Djblaik/weewx-installer/main/weewx
sudo mv weewx /etc/nginx/sites-available
sudo cp /etc/nginx/sites-available/weewx /etc/nginx/sites-enabled/weewx
sudo systemctl restart nginx

