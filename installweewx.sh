#!/bin/bash
set -e
installweewx () {
sudo apt update
# Install Required dependencies
sudo apt install python3-configobj
sudo apt install python3-pil
sudo apt install python3-serial
sudo apt install python3-usb
sudo apt install python3-pip
sudo apt install python3-cheetah || sudo pip3 install Cheetah3

# Optional: for extended almanac information
sudo pip3 uninstall pyephem
sudo apt purge python3-ephem
sudo apt install python3-ephem

#install weewx
file=$(curl -Ls https://api.github.com/repos/weewx/weewx/releases/latest | grep tarball_url | sed -re 's/.*: "([^"]+)".*/\1/')
filename=$(basename "$file")
echo $filename
echo $file
echo ${file##*/}
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

#install weewx interceptor
wget -O weewx-interceptor.zip https://github.com/matthewwall/weewx-interceptor/archive/master.zip
sudo /home/weewx/bin/wee_extension --install weewx-interceptor.zip
sudo rm weewx-interceptor.zip

#configure weewx interceptor
sudo /home/weewx/bin/wee_config --reconfigure --driver=user.interceptor --no-prompt
wget --header 'Authorization: token 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' https://raw.githubusercontent.com/Djblaik/weewx-installer/main/weewx.conf
sudo rm /home/weewx/weewx.conf
sudo mv weewx.conf /home/weewx
sudo rm weewx.conf
sudo systemctl restart weewx

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
ln -s /etc/nginx/sites-available/weewx /etc/nginx/sites-enabled
sudo systemctl restart nginx
sudo rm weewx
}

#install belchertown skin
belchertown () {
file=$(curl -Ls https://api.github.com/repos/poblabs/weewx-belchertown/releases/latest | grep tarball_url | sed -re 's/.*: "([^"]+)".*/\1/')
filename=$(basename "$file")
wget $file
wget --header 'Authorization: token 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' https://raw.githubusercontent.com/Djblaik/weewx-installer/main/sglogo330.png
sudo mv sglogo330.png /home/weewx/skins/Belchertown/images
sudo mv $filename "${filename}.tar.gz"
filename="${filename}.tar.gz"
sudo /home/weewx/bin/wee_extension --install $filename
sudo rm $filename
sudo systemctl stop weewx
sudo systemctl start weewx
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
