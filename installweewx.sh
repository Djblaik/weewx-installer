#!/bin/bash
set -e
set -x
installweewx () {
sudo apt update
# Install Required dependencies
sudo apt -y install python3-configobj
sudo apt -y install python3-pil
sudo apt -y install python3-serial
sudo apt -y install python3-usb
sudo apt -y install python3-pip
sudo apt -y install python3-cheetah || sudo pip3 install Cheetah3
sudo apt -y install python3-venv

#install weewx
# Create the virtual environment
python3 -m venv ~/weewx-venv
# Activate the WeeWX virtual environment
# shellcheck disable=SC1090
source ~/weewx-venv/bin/activate
# Optional: for extended almanac information
sudo pip3 uninstall pyephem
sudo apt purge python3-ephem 
sudo pip3 install ephem
# Install WeeWX into the virtual environment
python3 -m pip install weewx
# Activate the WeeWX virtual environment
# shellcheck disable=SC1090
#source ~/weewx-venv/bin/activate
# Create the station data
 ~/weewx-venv/bin/weectl station create --no-prompt
#install weewx.conf
wget https://raw.githubusercontent.com/Djblaik/weewx-installer/main/weewx.conf
sudo rm ~/weewx-data/weewx.conf
sudo mv weewx.conf ~/weewx-data
#install lowBattery.py and dataAlarm.py
wget https://raw.githubusercontent.com/Djblaik/weewx-installer/main/LowBatteryPush.py
wget https://raw.githubusercontent.com/Djblaik/weewx-installer/main/dataAlarm.py
sudo mv LowBatteryPush.py dataAlarm.py ~/weewx-data/bin/user
#run weewx as a daemon
sudo sh ~/weewx-data/scripts/setup-daemon.sh
sudo systemctl start weewx

#install weewx interceptor
~/weewx-venv/bin/weectl extension install https://github.com/matthewwall/weewx-interceptor/archive/refs/heads/master.zip --yes

#configure weewx interceptor
~/weewx-venv/bin/weectl station reconfigure --no-prompt --driver=user.interceptor
sudo systemctl restart weewx

#install nginx & php-fpm8.3
sudo apt -y install nginx
wget https://raw.githubusercontent.com/Djblaik/weewx-installer/main/weewx
sudo mv weewx /etc/nginx/sites-available
sudo apt install php-fpm8.3

FILE=/etc/nginx/sites-enabled/default
if test -f "$FILE"; then
    sudo rm /etc/nginx/sites-enabled/default
fi
file2=/etc/nginx/sites-enabled/weewx
if test ! -e "$file2"; then
    sudo ln -s /etc/nginx/sites-available/weewx /etc/nginx/sites-enabled
fi
sudo systemctl restart nginx
}

updateweewx () {
  # Activate the WeeWX virtual environment
  source ~/weewx-venv/bin/activate
  # Upgrade the WeeWX code
  python3 -m pip install weewx --upgrade
  weectl station upgrade --what examples util
  weectl station upgrade --what skins
}

#install belchertown skin
belchertown () {
wget https://github.com/poblabs/weewx-belchertown/archive/refs/heads/master.tar.gz
~/weewx-venv/bin/weectl extension install master.tar.gz
sudo rm master.tar.gz
wget https://raw.githubusercontent.com/Djblaik/weewx-installer/main/sgweatherlogo.png
wget https://raw.githubusercontent.com/Djblaik/weewx-installer/main/sgweatherlogodark.png
sudo mv sgweatherlogo.png ~/weewx-data/skins/Belchertown/images
sudo mv sgweatherlogodark.png ~/weewx-data/skins/Belchertown/images
wget https://raw.githubusercontent.com/Djblaik/weewx-installer/main/graphs.conf
sudo mv graphs.conf ~/weewx-data/skins/Belchertown
sudo systemctl restart weewx

}

PS3="Choose an option: "

select skin in "install weewx with standard skin" "install weewx with belchertown skin" "update weewx" Quit
do
    case $skin in
	
        "install weewx with standard skin")
		            echo "installing weewx"
		            installweewx
                echo "weewx installed with standard skin"
	     	        echo "installation complete!"
		            break;;
			
        "install weewx with belchertown skin")
		            echo "installing weewx"
		            installweewx
                echo "installing belchertown skin"
	              belchertown
	              echo "weewx installed with Belchertown skin"
	 	            echo "installation complete!"
	              break;;

        "update weewx")
                echo "updating weewx.."
                updateweewx
                echo "weewx updated!"
                break;;

        "Quit")
            break;;
    esac
done


rm $0
echo "installweewx.sh deleted"
