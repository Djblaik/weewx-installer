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
wget --header 'Authorization: token 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' https://raw.githubusercontent.com/Djblaik/weewx-installer/main/weewx.conf
sudo rm /home/weewx/weewx.conf
sudo mv weewx.conf /home/weewx

#run as daemon automatically when the computer starts
sudo cp /home/weewx/util/init.d/weewx.debian /etc/init.d/weewx
sudo chmod +x /etc/init.d/weewx
sudo update-rc.d weewx defaults 98
sudo systemctl start weewx

#install weewx interceptor
wget -O weewx-interceptor.zip https://github.com/matthewwall/weewx-interceptor/archive/master.zip
sudo /home/weewx/bin/wee_extension --install weewx-interceptor.zip
sudo rm weewx-interceptor.zip

#configure weewx interceptor
sudo /home/weewx/bin/wee_config --reconfigure --driver=user.interceptor --no-prompt
sudo systemctl restart weewx

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
file=$(curl -Ls https://api.github.com/repos/steepleian/weewx-Weather34/releases/latest | grep tarball_url | sed -re 's/.*: "([^"]+)".*/\1/')
filename=$(basename "$file")
wget --header 'Authorization: token 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' https://raw.githubusercontent.com/Djblaik/weewx-installer/main/services.txt
wget --header 'Authorization: token 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' https://raw.githubusercontent.com/Djblaik/weewx-installer/main/setup_py.conf
wget $file
dir="weather34-${filename}"
sudo mkdir $dir
sudo tar -xzvf $filename -C $dir --strip-components=1
sudo rm $dir/setup_py.conf
sudo mv setup_py.conf $dir
sudo systemctl restart nginx
cd $dir
sudo python3 w34_installer.py
sudo systemctl restart weewx
cd ..
sudo /home/weewx/bin/wee_reports
sudo rm services.txt
sudo rm -r $dir
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
