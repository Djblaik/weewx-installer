#!/bin/sh
set -e
#install belchertown skin
file=$(curl -Ls https://api.github.com/repos/poblabs/weewx-belchertown/releases/latest | grep tarball_url | sed -re 's/.*: "([^"]+)".*/\1/')
filename=$(basename "$file")
echo $filename
echo $file
echo ${file##*/}
wget $file
sudo mv $filename "${filename}.tar.gz"
filename="${filename}.tar.gz"
sudo /home/weewx/bin/wee_extension --install $filename
sudo rm $filename
sudo systenctl restart weewx
