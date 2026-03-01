#!/bin/sh

clear

echo ; echo "Rivendell Github install Script for Ubuntu 18.04/Linux Mint 19" ; echo
echo ; echo "More information find on Github https://github.com/ElvishArtisan/rivendell" ; echo
echo ; echo "More information and source code at rivendellaudio.org" ; echo

#check for root user
if [ "$(id -u)" != "0" ]; then
	echo "You need to run this script as sudo/root."
	exit 1
fi

#yes or no install question
while true
do
	read -r -p "Are you sure you want to install the latest Rivendell github? It will take a couple of hours. [Y/n] " input

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

echo
echo "We need to download and install a bunch of packages before Rivendell. This process could take a while..."
echo
sleep 5

echo Make sure your package database is up to date...

apt-get update

echo Installing build tools...

apt-get install -y build-essential autogen automake pkg-config libtool m4 make libssl-dev gcc g++ git unzip unrar wget

echo Installing Rivendell dependencies...

apt-get install -y libqt4-dev libqt4-sql-mysql libexpat1-dev libfdk-aac-dev libmysqlclient-dev libssh-dev libtag1-dev libid3-3.8.3-dev libcurl4-openssl-dev libsndfile1-dev libpam0g-dev libsamplerate0-dev libsoundtouch-dev libsystemd-dev libjack-jackd2-dev libice-dev libsm-dev libxt-dev libxi-dev libsndfile-dev libasound2-dev libopus-dev libogg-dev libvorbis-dev libflac-dev libflac++-dev libmp3lame-dev libfaad-dev libmad0-dev libtwolame-dev libmp4v2-dev libcoverart-dev libdiscid-dev libmusicbrainz5-dev libcdparanoia-dev docbook5-xml docbook-xsl-ns xsltproc fop libxml2-utils openssh-server patch evince telnet samba ntp nfs-common smbclient net-tools traceroute ntfs-3g autofs python3-mysqldb python3 python3-pycurl python3-pymysql python3-serial python3-requests python3-dev qjackctl

ulimit -r -l

export PATH=/sbin:$PATH

echo Set up Docbook environment variable ...

export DOCBOOK_STYLESHEETS=/usr/share/xml/docbook/stylesheet/docbook-xsl-ns
echo export DOCBOOK_STYLESHEETS=/usr/share/xml/docbook/stylesheet/docbook-xsl-ns >> ~/.bashrc

echo Installing and configuring Apache2...

apt-get install -y apache2

a2enmod cgid

systemctl restart apache2

echo Installing and configuring MariaDB...

apt-get install -y mariadb-server
systemctl start mariadb
systemctl enable mariadb

cp -f assets/90-rivendell.cnf /etc/mysql/mariadb.conf.d/

systemctl restart mysql

echo "Enable DB Access for localhost .."; echo

mysql -e "CREATE DATABASE Rivendell;"
mysql -e "CREATE USER 'rduser'@'localhost' IDENTIFIED BY 'letmein';"
mysql -e "GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,DROP,INDEX,ALTER,CREATE TEMPORARY TABLES,LOCK TABLES ON Rivendell.* TO 'rduser'@'localhost';"

echo "Enable DB Access for all remote hosts .."; echo

mysql -e "CREATE USER 'rduser'@'%' IDENTIFIED BY 'letmein';"
mysql -e "GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,DROP,INDEX,ALTER,CREATE TEMPORARY TABLES,LOCK TABLES ON Rivendell.* TO rduser@'%';"

echo Making audio storage...

adduser --uid 150 --system --group --home=/var/snd rivendell
adduser $SUDO_USER rivendell
chown $SUDO_USER:rivendell /var/snd
chmod ug+rwx /var/snd
adduser --system --no-create-home pypad
usermod -a --groups audio $SUDO_USER

echo Enable NFS Access remote hosts...

mkdir -p /home/$SUDO_USER/rd_xfer
chown $SUDO_USER:$SUDO_USER /home/$SUDO_USER/rd_xfer
mkdir -p /home/$SUDO_USER/music_export
chown $SUDO_USER:$SUDO_USER /home/$SUDO_USER/music_export
mkdir -p /home/$SUDO_USER/music_import
chown $SUDO_USER:$SUDO_USER /home/$SUDO_USER/music_import
mkdir -p /home/$SUDO_USER/traffic_export
chown $SUDO_USER:$SUDO_USER /home/$SUDO_USER/traffic_export
mkdir -p /home/$SUDO_USER/traffic_import
chown $SUDO_USER:$SUDO_USER /home/$SUDO_USER/traffic_import

echo Install NFS-Kernel-Server

apt-get -y install nfs-kernel-server

mkdir -p /srv/nfs4/var/snd
mkdir -p /srv/nfs4/home/$SUDO_USER/music_export
mkdir -p /srv/nfs4/home/$SUDO_USER/music_import
mkdir -p /srv/nfs4/home/$SUDO_USER/traffic_export
mkdir -p /srv/nfs4/home/$SUDO_USER/traffic_import
mkdir -p /srv/nfs4/home/$SUDO_USER/rd_xport

echo "/var/snd /srv/nfs4/var/snd none bind 0 0" >> /etc/fstab
echo "/home/$SUDO_USER/music_export /srv/nfs4/home/$SUDO_USER/music_export none bind 0 0" >> /etc/fstab
echo "/home/$SUDO_USER/music_import /srv/nfs4/home/$SUDO_USER/music_import none bind 0 0" >> /etc/fstab
echo "/home/$SUDO_USER/traffic_export /srv/nfs4/home/$SUDO_USER/traffic_export none bind 0 0" >> /etc/fstab
echo "/home/$SUDO_USER/traffic_import /srv/nfs4/home/$SUDO_USER/traffic_import none bind 0 0" >> /etc/fstab
echo "/home/$SUDO_USER/rd_xfer /srv/nfs4/home/$SUDO_USER/rd_xfer none bind 0 0" >> /etc/fstab
echo "/var/snd *(rw,no_root_squash)" >> /etc/exports
echo "/home/$SUDO_USER/rd_xfer *(rw,no_root_squash)" >> /etc/exports
echo "/home/$SUDO_USER/music_export *(rw,no_root_squash)" >> /etc/exports
echo "/home/$SUDO_USER/music_import *(rw,no_root_squash)" >> /etc/exports
echo "/home/$SUDO_USER/traffic_export *(rw,no_root_squash)" >> /etc/exports
echo "/home/$SUDO_USER/traffic_import *(rw,no_root_squash)" >> /etc/exports

echo Enable CIFS File Sharing

cp /etc/samba/smb.conf /etc/samba/smb-original.conf
cat assets/samba_shares.conf >> /etc/samba/smb.conf
systemctl enable smbd
systemctl enable nmbd

echo Set Image Folder Rivendell..
patch -p0 /etc/rsyslog.d/50-default.conf assets/50-default.conf.patch
mkdir -p /usr/share/pixmaps/rivendell
cp assets/rdairplay_skin.png /usr/share/pixmaps/rivendell/
cp assets/rdpanel_skin.png /usr/share/pixmaps/rivendell/

echo Initialize Automounter

cp -f assets/auto.misc.template /etc/auto.misc
systemctl enable autofs

echo Make Jack Audio with Promiscuous Mode...

cp assets/rivendell-env.sh /etc/profile.d/

echo Downloading Rivendell

git clone -b v3 https://github.com/ElvishArtisan/rivendell.git

cd rivendell

echo Generating Configuration...

./autogen.sh

echo Configuring Rivendell Install...

./configure MUSICBRAINZ_LIBS="-L/usr/local/lib -ldiscid -lmusicbrainz5cc -lcoverartcc" --libexecdir=/var/www/rd-bin --sysconfdir=/etc/apache2/conf-available

echo Compiling Rivendell...

make

echo Installing Rivendell...

make install

ldconfig

echo ; echo "Setting Up Rivendell..." ;

mkdir /etc/rivendell.d
cp conf/rd.conf-sample /etc/rivendell.d/rd-default.conf
cat /etc/rivendell.d/rd-default.conf | sed s/SyslogFacility=1/SyslogFacility=23/g | sed s/Password=hackme/Password=letmein/g > /etc/rivendell.d/rd-temp.conf
mv -f /etc/rivendell.d/rd-temp.conf /etc/rivendell.d/rd-default.conf
ln -s -f /etc/rivendell.d/rd-default.conf /etc/rd.conf

echo ; echo "Make Apache2 rd-bin Work" ; echo

a2enconf rd-bin
systemctl reload apache2

rddbmgr --create --generate-audio
systemctl start rivendell
systemctl enable rivendell

# Setup Log Editor on database
echo ; echo "update `STATIONS` set `REPORT_EDITOR_PATH`='/usr/bin/gedit'" | mysql -u root Rivendell

# Disable RDMonitor
echo ; echo "Disable Rivendell Monitor" ; echo

chmod -x /usr/local/bin/rdmonitor

echo ; echo "Making Pypad Scipts Work.." ; echo

cp apis/pypad/api/pypad.py /usr/lib/python3/dist-packages/

echo
# Ask the user if they want to reboot their computer
echo "Rivendell Install Complete. Would you like to reboot your computer? (Y/n)"
read response

# Check the user's response
if [ "$response" == "n" ]; then
  # If the user says no, exit the script
  exit
fi

# If the user says yes, reboot the computer
if [ "$response" == "yY" ]; then
  # Reboot
  reboot
fi
