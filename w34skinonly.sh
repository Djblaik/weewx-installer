#install weather34 skin
sudo apt install php8.1-fpm php8.1-cli php8.1-sqlite3 php8.1-zip php8.1-gd  php8.1-mbstring php8.1-curl php8.1-xml php8.1-bcmath
wget https://github.com/steepleian/weewx-Weather34/archive/refs/heads/main.zip
unzip main.zip
wget --header 'Authorization: token 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' https://raw.githubusercontent.com/Djblaik/weewx-installer/weewx-weather34/services.txt
wget --header 'Authorization: token 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' https://raw.githubusercontent.com/Djblaik/weewx-installer/weewx-weather34/nginx.conf
wget --header 'Authorization: token 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' https://raw.githubusercontent.com/Djblaik/weewx-installer/weewx-weather34/setup_py.conf
sudo mv nginx.conf /etc/nginx/
sudo rm weewx-Weather34-main/setup_py.conf
sudo mv setup_py.conf weewx-Weather34-main
sudo systemctl restart nginx
sudo apt install unzip
cd weewx-Weather34-main
sudo python3 w34_installer.py
sudo systemctl restart weewx
cd ..
sudo /home/weewx/bin/wee_reports
