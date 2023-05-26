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

# Optional: for extended almanac information
sudo pip3 --no-input uninstall pyephem
sudo apt purge python3-ephem
sudo pip3 --no-input install ephem

#install weewx
file=$(curl -Ls https://api.github.com/repos/weewx/weewx/releases/latest | grep tarball_url | sed -re 's/.*: "([^"]+)".*/\1/')
filename=$(basename "$file")
wget $file
dir="weewx-${filename}"
sudo mkdir $dir
sudo tar -xzvf $filename -C $dir --strip-components=1
cd $dir
sudo python3 ./setup.py build
sudo python3 ./setup.py install --no-prompt
cd ..
sudo rm -r $dir
sudo rm $filename
wget --header 'Authorization: token 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' https://raw.githubusercontent.com/Djblaik/weewx-installer/main/weewx.conf
sudo rm /home/weewx/weewx.conf
sudo mv weewx.conf /home/weewx
sudo cp /home/weewxutil/systemd/weewx.service /etc/systemd/system
sudo systemctl enable weewx
sudo systemctl start weewx

#install weewx interceptor
wget -O weewx-interceptor.zip https://github.com/matthewwall/weewx-interceptor/archive/master.zip
sudo /home/weewx/bin/wee_extension --install weewx-interceptor.zip
sudo rm weewx-interceptor.zip

#configure weewx interceptor
sudo /home/weewx/bin/wee_config --reconfigure --driver=user.interceptor --no-prompt
sudo systemctl restart weewx

#install nginx
sudo apt -y install nginx
wget --header 'Authorization: token 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' https://raw.githubusercontent.com/Djblaik/weewx-installer/main/weewx
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
sudo /home/weewx/bin/wee_extension --install $filename
sudo rm $filename
wget --header 'Authorization: token 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' https://raw.githubusercontent.com/Djblaik/weewx-installer/main/sgweatherlogo.png
wget --header 'Authorization: token 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' https://raw.githubusercontent.com/Djblaik/weewx-installer/main/sgweatherlogodark.png
sudo mv sgweatherlogo.png /home/weewx/skins/Belchertown/images
sudo mv sgweatherlogo.png /home/weewx/skins/Belchertown/images
sudo systemctl restart weewx
}

PS3="Choose a skin to install: "

select skin in standard belchertown Quit
do
    case $skin in
	
        "standard")
		$ echo "installing weewx"
		installweewx
            	echo "weewx installed with standard skin"
		break;;
			
        "belchertown")
		$ echo "installing weewx"
		installweewx
            	echo "installing belchertown skin"
	        belchertown
	        $ echo "installation complete"
	        break;;

        "Quit")
            break;;
    esac
done
