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
sudo apt install python3-ephem

#install weewx
wget https://www.weewx.com/downloads/released_versions/weewx-4.10.2.tar.gz
tar xvfz weewx-4.10.2.tar.gz
cd weewx-4.10.2
python3 ./setup.py build
sudo python3 ./setup.py install --no-prompt
cd ..
sudo rm weewx-4.10.2

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

#install weather34 skin and php8.1-fpm
weather34 () {
sudo apt install php8.1-fpm php8.1-cli php8.1-sqlite3 php8.1-zip php8.1-gd  php8.1-mbstring php8.1-curl php8.1-xml php8.1-bcmath
wget https://github.com/steepleian/weewx-Weather34/archive/refs/heads/main.zip
unzip main.zip
wget --header 'Authorization: token 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' https://raw.githubusercontent.com/Djblaik/weewx-installer/main/services.txt
wget --header 'Authorization: token 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' https://raw.githubusercontent.com/Djblaik/weewx-installer/main/setup_py.conf
sudo rm weewx-Weather34-main/setup_py.conf
sudo mv setup_py.conf weewx-Weather34-main
sudo systemctl restart nginx
sudo apt install unzip
cd weewx-Weather34-main
sudo python3 w34_installer.py
sudo systemctl restart weewx
cd ..
sudo /home/weewx/bin/wee_reports
sudo rm main.zip
sudo rm services.txt
sudo rm setup_py.conf
}
#install belchertown skin
belchertown () {
wget https://github.com/poblabs/weewx-belchertown/releases/download/weewx-belchertown-1.3.1/weewx-belchertown-release.1.3.1.tar.gz
sudo /home/weewx/bin/wee_extension --install weewx-belchertown-release.1.3.1.tar.gz
sudo rm weewx-belchertown-release.1.3.1.tar.gz
}


PS3="Choose a skin to install: "

select skin in standard belchertown weather34 "install all" Quit
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
			
        "weather34")
			echo "installing weewx"
			installweewx
            echo "installing with weather34 skin"
			weather34
			echo "installation complete"
			break;;
			
		"install all")
            echo "installing with all skins"
		    echo "installing weewx"
		    installweewx
            echo "installing belchertown skin"
	        belchertown
		    echo "installing with weather34 skin"
	        weather34
	        echo "installation complete"
	        break;;
        "Quit")
            break;;
    esac
done
