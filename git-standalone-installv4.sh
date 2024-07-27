#!/bin/sh

clear

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

cat << "EOF"
,------. ,--.                           ,--.       ,--.,--.               ,---.
|  .--. '`--',--.  ,--.,---. ,--,--,  ,-|  | ,---. |  ||  |    ,--.  ,--./    |
|  '--'.',--. \  `'  /| .-. :|      \' .-. || .-. :|  ||  |     \  `'  //  '  |
|  |\  \ |  |  \    / \   --.|  ||  |\ `-' |\   --.|  ||  |      \    / '--|  |
`--' '--'`--'   `--'   `----'`--''--' `---'  `----'`--'`--'       `--'     `--'
EOF

echo ; echo "Rivendell v4 install script for Ubuntu 22.04 and Linux Mint 21" ; echo "For more information Rivendell Source visit https://github.com/ElvishArtisan/rivendell" ; echo "More information and original project source code at rivendellaudio.org" ; echo

echo "Your System Details"
echo
echo "Operating System: $(cat /etc/os-release | grep 'PRETTY_NAME' | cut -d'"' -f2)"
echo "Kernel:" $(uname) $(uname -r)
echo "User:" ${SUDO_USER:-$USER}
echo "Hostname:" $(hostname)
echo
sleep 5

echo ; echo "Making sure your package database is up to date..." ; echo

apt-get update

echo ; echo "We need to download and install some packages before Rivendell. This process could take a while..."

echo ; echo "Installing Rivendell dependencies..." ; echo
sleep 5

# Install Rivendell dependencies
apt-get install -y make g++ libtool libmagick++-dev libexpat1-dev libexpat1 autoconf-archive gnupg pbuilder ubuntu-dev-tools apt-file git libcurl4-gnutls-dev libid3-dev libcoverart-dev libdiscid-dev libmusicbrainz5-dev libcdparanoia-dev libsndfile1-dev libpam0g-dev libvorbis-dev python3 python3-pycurl python3-pymysql python3-serial python3-requests libsamplerate0-dev qtbase5-dev libqt5sql5-mysql libsoundtouch-dev libsystemd-dev libjack-jackd2-dev libid3-3.8.3-dev libsndfile-dev libasound2-dev libflac-dev libflac++-dev libogg-dev libvorbis-dev libfdk-aac-dev libfaad-dev libmp3lame-dev libmad0-dev libtwolame-dev docbook5-xml libxml2-utils docbook-xsl-ns xsltproc fop libltdl-dev autoconf automake libssl-dev libtag1-dev qttools5-dev-tools debhelper openssh-server lame patch evince samba telnet nfs-common smbclient net-tools traceroute gedit ntfs-3g autofs

# Install Apache2 web server
echo ; echo "Installing and configuring Apache2..." ; echo

if dpkg -l | grep -qw apache2
  then
    echo "Package apache2 is already installed. Skipping..." ; echo
  else
    apt-get install -y apache2
fi

# Enable Apache2 mods
a2enmod cgid
systemctl restart apache2

# Install MariaDB server
echo ; echo "Installing and configuring MariaDB..." ; echo
sleep 5

if dpkg -l | grep -qw mariadb-server
  then
    echo "Package mariadb-server is already installed. Skipping..." ; echo
  else
    apt install -y mariadb-server
    systemctl start mariadb
    systemctl enable mariadb
fi

# Create audio storage and add current user as owner
echo "Making Rivendell audio storage..." ; echo
sleep 5

if [ -d /var/snd ]
  then
    echo "Audio storage already exists. Skipping..."
  else
    adduser --system --group --home=/var/snd rivendell ;
    adduser --system --no-create-home pypad ;
    usermod -a --groups audio $SUDO_USER ;
    adduser $SUDO_USER rivendell ;
    chown rivendell:rivendell /var/snd ;
    chmod ug+rwx /var/snd
fi

# Set path
echo ; echo "Set up Docbook environment variable ..." ; echo
sleep 5

export PATH=/sbin:$PATH
export DOCBOOK_STYLESHEETS=/usr/share/xml/docbook/stylesheet/docbook-xsl-ns
echo "export DOCBOOK_STYLESHEETS=/usr/share/xml/docbook/stylesheet/docbook-xsl-ns" >> /home/$SUDO_USER/.bashrc

# Clone Rivendell source
echo ; echo "Clone Rivendell Latest from Github.." ; echo

git clone -b v4 https://github.com/ElvishArtisan/rivendell.git

cd rivendell

echo ; echo "Rivendell is Compiling... This process could take a while..." ; echo
sleep 5

./autogen.sh

./configure --prefix=/usr --libdir=/usr/lib --libexecdir=/var/www/rd-bin --sysconfdir=/etc/apache2/conf-available --enable-rdxport-debug MUSICBRAINZ_LIBS="-ldiscid -lmusicbrainz5cc -lcoverartcc"

make

make install

ldconfig

echo ; echo "Compiling and Installing Rivendell Done!. Setting Up.." ; echo
sleep 5

mkdir -p /usr/share/pixmaps/rivendell
mkdir /etc/rivendell.d
cp conf/rd.conf-sample /etc/rivendell.d/rd-default.conf
cat /etc/rivendell.d/rd-default.conf | sed s/SyslogFacility=1/SyslogFacility=23/g | sed s/Password=hackme/Password=letmein/g > /etc/rivendell.d/rd-temp.conf
mv -f /etc/rivendell.d/rd-temp.conf /etc/rivendell.d/rd-default.conf
ln -s -f /etc/rivendell.d/rd-default.conf /etc/rd.conf

cp conf/rivendell-env.sh /etc/profile.d/
a2enconf rd-bin
systemctl restart apache2

# Create the database and populate tables
echo ; echo "Creating database and populating database tables..." ; echo
sleep 5

if [ -d /var/lib/mysql/Rivendell ]
  then
    echo "Database already exists. Skipping..."
  else
    mysql -e "CREATE DATABASE Rivendell;" ;
    mysql -e "CREATE USER 'rduser'@'localhost' IDENTIFIED BY 'letmein';" ;
    mysql -e "CREATE USER 'rduser'@'%' IDENTIFIED BY 'letmein';" ;
    mysql -e "GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,DROP,INDEX,ALTER,CREATE TEMPORARY TABLES,LOCK TABLES ON Rivendell.* TO 'rduser'@'localhost';" ;
    mysql -e "GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,DROP,INDEX,ALTER,CREATE TEMPORARY TABLES,LOCK TABLES ON Rivendell.* TO 'rduser'@'%';" ;
    rddbmgr --create --generate-audio
fi

# Start the Rivendell daemons and enable the service
mysql -e "update `STATIONS` set `REPORT_EDITOR_PATH`='/usr/bin/gedit'"
systemctl start rivendell
systemctl enable rivendell

echo ; echo "Now we need disable RDMonitor..." ; echo
sleep 5

chmod -x /bin/rdmonitor
systemctl restart rivendell

echo
# Ask the user if they want to reboot their computer
while true
do
read -r -p "Rivendell Install Complete. Would you like to reboot your computer? [Y/n] " input

case $input in
	[yY][eE][sS]|[yY])
echo "Rebooting..."
  reboot ;;
    [nN][oO]|[nN])
  #echo "No"
  break ;;
  *)
echo "Invalid input..."
;;
esac
done

echo All done. Enjoy.
