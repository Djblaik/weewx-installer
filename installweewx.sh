#!/bin/bash
set -e
set -x
if ! command -v apt &> /dev/null; then
    echo "This installer only supports Debian/Ubuntu."
    exit 1
fi
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
if [ ! -d "$HOME/weewx-venv" ]; then
    python3 -m venv "$HOME/weewx-venv"
fi
# Activate the WeeWX virtual environment
source ~/weewx-venv/bin/activate
# Optional: for extended almanac information
pip3 uninstall pyephem
sudo apt purge python3-ephem 
pip3 install ephem
# Install WeeWX into the virtual environment
python3 -m pip install weewx
# Create the station data
 ~/weewx-venv/bin/weectl station create --no-prompt
#install weewx.conf
wget -q --show-progress https://raw.githubusercontent.com/Djblaik/weewx-installer/main/weewx.conf || { echo "Download failed"; exit 1; }
sudo rm ~/weewx-data/weewx.conf
sudo mv weewx.conf ~/weewx-data
#install lowBattery.py and dataAlarm.py
wget -q --show-progress https://raw.githubusercontent.com/Djblaik/weewx-installer/main/LowBatteryPush.py || { echo "Download failed"; exit 1; }
wget -q --show-progress https://raw.githubusercontent.com/Djblaik/weewx-installer/main/dataAlarm.py || { echo "Download failed"; exit 1; }
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
wget -q --show-progress https://raw.githubusercontent.com/Djblaik/weewx-installer/main/weewx || { echo "Download failed"; exit 1; }
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
  ~/weewx-venv/bin/weectl station upgrade --what examples util
  ~/weewx-venv/bin/weectl station upgrade --what skins
}

#install belchertown skin
belchertown () {
	# Activate the WeeWX virtual environment
	  source ~/weewx-venv/bin/activate
	wget -q --show-progress https://github.com/poblabs/weewx-belchertown/archive/refs/heads/master.tar.gz || { echo "Download failed"; exit 1; }
	~/weewx-venv/bin/weectl extension install master.tar.gz
	sudo rm master.tar.gz
	wget -q --show-progress https://raw.githubusercontent.com/Djblaik/weewx-installer/main/sgweatherlogo.png || { echo "Download failed"; exit 1; }
	wget -q --show-progress https://raw.githubusercontent.com/Djblaik/weewx-installer/main/sgweatherlogodark.png || { echo "Download failed"; exit 1; }
	sudo mv sgweatherlogo.png ~/weewx-data/skins/Belchertown/images
	sudo mv sgweatherlogodark.png ~/weewx-data/skins/Belchertown/images
	wget -q --show-progress https://raw.githubusercontent.com/Djblaik/weewx-installer/main/graphs.conf || { echo "Download failed"; exit 1; }
	sudo mv graphs.conf ~/weewx-data/skins/Belchertown
	wget -q --show-progress https://raw.githubusercontent.com/Djblaik/weewx-installer/main/index_hook_after_station_info.inc || { echo "Download failed"; exit 1; }
	sudo mv index_hook_after_station_info.inc ~/weewx-data/skins/Belchertown
	wget -q --show-progress https://raw.githubusercontent.com/Djblaik/weewx-installer/main/bomicons.tar || { echo "Download failed"; exit 1; }
	tar -xf bomicons.tar -C ~/weewx-data/public_html/belchertown
	cp ~/weewx-data/public_html/belchertown/bomsvgicons/storms ~/weewx-data/public_html/belchertown/bomsvgicons/storm

	sudo systemctl restart weewx
}

#install wh2900 skin
wh2900 () {
	source ~/weewx-venv/bin/activate
	wget -q --show-progress https://github.com/Djblaik/wh2900-weewx-skin/archive/refs/heads/main.tar.gz || { echo "Download failed"; exit 1; }
	weectl extension install main.tar.gz
}

createweatherall () {
	sudo chmod -R 755 ~/weewx-data/public_html
	sudo chmod 755 ~/weewx-data
	chmod o+x ~
	sudo mkdir /var/www/weather
	sudo mkdir /var/www/weather/images
	ln -s ~/weewx-data/public_html /var/www/weather/weewx
	wget -q --show-progress https://raw.githubusercontent.com/Djblaik/weewx-installer/main/allweatherindex.html || { echo "Download failed"; exit 1; }
	sudo mv allweatherindex.html /var/www/weather/index.html
	wget -q --show-progress https://raw.githubusercontent.com/Djblaik/weewx-installer/main/landingimages/belchertown.png || { echo "Download failed"; exit 1; }
	wget -q --show-progress https://raw.githubusercontent.com/Djblaik/weewx-installer/main/landingimages/weewx.png || { echo "Download failed"; exit 1; }
	wget -q --show-progress https://raw.githubusercontent.com/Djblaik/weewx-installer/main/landingimages/wh2900.png || { echo "Download failed"; exit 1; }
	sudo mv belchertown.png /var/www/weather/images
	sudo mv weewx.png /var/www/weather/images
	sudo mv wh2900.png /var/www/weather/
}

createweatherbelchertown () {
	sudo chmod -R 755 ~/weewx-data/public_html
	sudo chmod 755 ~/weewx-data
	chmod o+x ~
	sudo mkdir /var/www/weather
	sudo mkdir /var/www/weather/images
	ln -s ~/weewx-data/public_html /var/www/weather/weewx
	wget -q --show-progress https://raw.githubusercontent.com/Djblaik/weewx-installer/main/belchertownweatherindex.html || { echo "Download failed"; exit 1; }
	wget -q --show-progress https://raw.githubusercontent.com/Djblaik/weewx-installer/main/landingimages/weewx.png || { echo "Download failed"; exit 1; }
	sudo mv belchertownweatherindex.html /var/www/weather/index.html
	wget -q --show-progress https://raw.githubusercontent.com/Djblaik/weewx-installer/main/landingimages/belchertown.png || { echo "Download failed"; exit 1; }
	sudo mv belchertown.png /var/www/weather/images
	sudo mv weewx.png /var/www/weather/images
}

createweatherweewx () {
	sudo chmod -R 755 ~/weewx-data/public_html
	sudo chmod 755 ~/weewx-data
	chmod o+x ~
	sudo mkdir /var/www/weather
	sudo mkdir /var/www/weather/images
	ln -s ~/weewx-data/public_html /var/www/weather/weewx
	wget -q --show-progress https://raw.githubusercontent.com/Djblaik/weewx-installer/main/weewxweatherindex.html || { echo "Download failed"; exit 1; }
	sudo mv weewxweatherindex.html /var/www/weather/index.html
	wget -q --show-progress https://raw.githubusercontent.com/Djblaik/weewx-installer/main/landingimages/weewx.png || { echo "Download failed"; exit 1; }
	sudo mv weewx.png /var/www/weather/images
}

PS3="Choose an option: "

select skin in "install weewx with standard skin" "install weewx with belchertown skin" "Install install weewx with wh2900 skin" "install weewx with belchertown and wh2900 skins" "update weewx" Quit
do
    case $skin in
	
        "install weewx with standard skin")
		            echo "installing weewx"
		            installweewx
				echo "creating weather folder"
					createweatherweewx
                echo "weewx installed with standard skin"
	     	        echo "installation complete!"
		            break;;
			
        "install weewx with belchertown skin")
		            echo "installing weewx"
		            installweewx
                echo "installing belchertown skin"
	              belchertown
				echo "creating weather folder"
				  createweatherbelchertown
	              echo "weewx installed with Belchertown skin"
	 	            echo "installation complete!"
	              break;;
				  
		"Install install weewx with wh2900 skin")
		            echo "installing weewx"
		            installweewx
                echo "installing wh2900 skin"
	              wh2900
	              echo "weewx installed with wh2900 skin"
	 	            echo "installation complete!"
	              break;;

		"install weewx with belchertown and wh2900 skins")
		            echo "installing weewx"
		            installweewx
                echo "installing belchertown skin"
	              belchertown
				echo "installing wh2900 skin"
				  wh2900
				echo "creating weather folder"
					createweatherall
	              echo "weewx installed with Belchertown and wh2900 skins"
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
