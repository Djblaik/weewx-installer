#!/bin/bash
set -e
#install weather34 skin
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
