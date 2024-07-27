#!/bin/sh

clear

echo
echo Rivendell Github install Script for Ubuntu 18.04/Linux Mint 19
echo More information find on Github https://github.com/ElvishArtisan/rivendell
echo More information and source code at rivendellaudio.org
echo

#check for root user
if [ "$(id -u)" != "0" ]; then
	echo "You need to run this script as sudo/root."
	exit 1
fi

#yes or no install question
while true
do
 read -r -p "Are you sure you want to install the GlassCoder? It will take a couple of hours. [Y/n] " input

 case $input in
     [yY][eE][sS]|[yY])
 #echo "Yes"
	break ;;
     [nN][oO]|[nN])
 echo "Okay. Maybe next time."
       exit ;;
     *)
 echo "Invalid input..."
 ;;
 esac
done

echo Install Dependencies

sudo apt-get -y install qt5-default

cd GlassCoder-aac

./autogen.sh
./configure
export DOCBOOK_STYLESHEETS=/usr/share/xml/docbook/stylesheet/docbook-xsl-ns
make
sudo make install
sudo ldconfig

echo
echo "Installation of GlassCoder is complete."
echo