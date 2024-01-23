#!/bin/bash
set -e
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

# Optional: for extended almanac information
sudo pip3 --no-input uninstall pyephem
sudo apt purge python3-ephem
sudo pip3 --no-input install ephem

#install weewx
# Create the virtual environment
python3 -m venv ~/weewx-venv
# Activate the WeeWX virtual environment
source ~/weewx-venv/bin/activate
# Install WeeWX into the virtual environment
python3 -m pip install weewx
# Activate the WeeWX virtual environment
source ~/weewx-venv/bin/activate
# Create the station data
weectl station create --no-prompt
#install weewx.conf
wget https://raw.githubusercontent.com/Djblaik/weewx-installer/main/weewx.conf
sudo rm ~/weewx-data/weewx.conf
sudo mv weewx.conf ~/weewx-data
#run weewx as a daemon
sudo sh ~/weewx-data/scripts/setup-daemon.sh
sudo systemctl start weewx

#install weewx interceptor
sudo weectl extension install https://github.com/djblaik/weewx-interceptor/archive/master.zip

#configure weewx interceptor
sudo weectl station reconfigure --no-prompt --driver=user.interceptor
sudo systemctl restart weewx

#install nginx
sudo apt -y install nginx
wget https://raw.githubusercontent.com/Djblaik/weewx-installer/main/weewx
sudo mv weewx /etc/nginx/sites-available

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

#install belchertown skin
belchertown () {
file=$(curl -Ls https://api.github.com/repos/poblabs/weewx-belchertown/releases/latest | grep tarball_url | sed -re 's/.*: "([^"]+)".*/\1/')
filename=$(basename "$file")
wget $file
sudo mv $filename "${filename}.tar.gz"
filename="${filename}.tar.gz"
sudo weectl extension install $filename
sudo rm $filename
wget https://raw.githubusercontent.com/Djblaik/weewx-installer/main/sgweatherlogo.png
wget https://raw.githubusercontent.com/Djblaik/weewx-installer/main/sgweatherlogodark.png
sudo mv sgweatherlogo.png ~/weewx-data/skins/Belchertown/images
sudo mv sgweatherlogodark.png ~/weewx-data/skins/Belchertown/images
wget https://raw.githubusercontent.com/Djblaik/weewx-installer/main/graphs.conf
sudo mv graphs.conf ~/weewx-data/skins/Belchertown
sudo systemctl restart weewx

}

PS3="Choose a skin to install: "

select skin in standard belchertown Quit
do
    case $skin in
	
        "standard")
		echo "installing weewx"
		installweewx
            	echo "weewx installed with standard skin"
		break;;
			
        "belchertown")
		echo "installing weewx"
		installweewx
            	echo "installing belchertown skin"
	        belchertown
	        echo "installation complete"
	        break;;

        "Quit")
            break;;
    esac
done
rm $0
echo "installweewx.sh deleted"
