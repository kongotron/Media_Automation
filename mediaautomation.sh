#!/bin/bash

################################################################################
# Media Server Install Script                                                  #
#                                                                              #
# This script installs the following software                                  #
#                                                                              #
# Radarr                                                                       #
# Lidarr                                                                       #
# Readarr                                                                      #
# Whisparr                                                                     #
# Sonarr                                                                       #
# Jackett                                                                      #
# Qbittorrent                                                                  #
# Plex Media Server                                                            #
# Tautilli                                                                     #
# Ombi                                                                         #
# Simple Dash                                                                  #
# OpenPyn                                                                      #
# Cifs Utils & Samba                                                           #
#                                                                              #
# Author: Micheal Howlin                                                       #
#                                                                              #
################################################################################

################################################################################
# User defined variables - You can change these                                #
################################################################################
#Library Settings
DATAFOLDER="/mnt/mediaautomation/"
#Samba Settings
SAMBANAME="mediaautomation"
#Ombi Settings
OMBIPORT="5000"
OMBIUSER="ombi"
OMBIGROUP="media"
#Qbittorrent Settings
QBITTORRENTPORT="8082"
QBITTORRENTUSER="qbittorrent"
QBITTORRENTGROUP="media"
#Jackett Settings
JACKETTPORT="9117"
#Radarr Settings
RADARRDATADIR="/home/radarr/"
RADARRPORT="7878"
RADARRUSER="radarr"
RADARRGROUP="media"
#Lidarr Settings
LIDARRDATADIR="/home/lidarr/"
LIDARRPORT="8686"
LIDARRUSER="lidarr"
LIDARRGROUP="media"
#Whisparr Settings
WHISPARRDATADIR="/home/whisparr/"
WHISPARRPORT="6969"
WHISPARRUSER="whisparr"
WHISPARRGROUP="media"
#Readarr Settings
READARRDATADIR="/home/readarr/"
READARRPORT="8787"
READARRUSER="readarr"
READARRGROUP="media"
#Sonarr Settings
SONARRPORT="8989"

################################################################################
# Load the config variables - Dont Change These!                               #
################################################################################
#Samba Settings
SAMBAPORT="445"
#Radarr Settings
RADARRDLURL="http://radarr.servarr.com/v1/update/master/updatefile?os=linux&runtime=netcore&"
RADARRSERVICE="radarr"
#Whisparr Settings
WHISPARRDLURL="http://whisparr.servarr.com/v1/update/nightly/updatefile?os=linux&runtime=netcore&"
WHISPARRSERVICE="whisparr"
#Lidarr Settings
LIDARRDLURL="http://lidarr.servarr.com/v1/update/master/updatefile?os=linux&runtime=netcore&"
LIDARRSERVICE="lidarr"
#Readarr Settings
READARRDLURL="http://readarr.servarr.com/v1/update/develop/updatefile?os=linux&runtime=netcore&"
READARRSERVICE="readarr"
#Plexserver Settings
PLEXPORT="32400"
#Jackett Settings
JACKETTSERVICE="jackett"
#Qbittorrent Settings
QBITTORRENTSERVICE="qbittorrent-nox"
#Tautulli Settings
TAUTULLISERVICE="tautulli"
TAUTULLIUSER="tautulli"  #Tautulli doesnt like its settings changed so they are hard coded here to be changable after
TAUTULLIGROUP="tautulli" #Tautulli doesnt like its settings changed so they are hard coded here to be changable after
TAUTULLIPORT="8181"      #Tautulli doesnt like its settings changed so they are hard coded here to be changable after

CWD=$(pwd)
CURRENTUSER=$(whoami)
ARCH=$(dpkg --print-architecture)
#IP=$(echo hostname -I | xargs)

ARREXTENSION=""
if [ "$ARCH" = "amd64" ]; then
  ARREXTENSION="arch=x64"
elif [ "$ARCH" = "arm64" ]; then
  ARREXTENSION="arm64"
else
  ARREXTENSION="arch=arm"
fi

#Hardcode your IP here
IP="127.0.0.1"

################################################################################
# Help                                                                         #
################################################################################
Help() {
  # Display Help
  echo "################################################################################"
  echo "# Media Server Install Script                                                  #"
  echo "#                                                                              #"
  echo "# Author: Micheal Howlin                                                       #"
  echo "#                                                                              #"
  echo "################################################################################"
}

################################################################################
# Process the input options. Add options as needed.                            #
################################################################################
# Get the options
while getopts ":h" option; do
  case $option in
  h) # display Help
    Help
    exit
    ;;
  esac
done

################################################################################
################################################################################
# Main program                                                                 #
################################################################################
################################################################################

structure() {
  echo "################################################################################"
  echo "# Creating Folder Structure and Updating                              #"
  echo "################################################################################"
  #Create the folders
  sudo mkdir -p "$DATAFOLDER"
  sudo mkdir -p "$DATAFOLDER/torrents/downloading"
  sudo mkdir -p "$DATAFOLDER/torrents/complete"
  sudo mkdir -p "$DATAFOLDER/torrents/torrentfiles/downloading"
  sudo mkdir -p "$DATAFOLDER/torrents/torrentfiles/complete"
  sudo mkdir -p "$DATAFOLDER/torrents/torrentfiles/monitoring"
  sudo mkdir -p "$DATAFOLDER/video/movies"
  sudo mkdir -p "$DATAFOLDER/video/tv"
  sudo mkdir -p "$DATAFOLDER/books"
  sudo mkdir -p "$DATAFOLDER/music"

  #Make them accessible
  sudo chmod -R 777 "$DATAFOLDER"

  #Update and install basic software
  sudo apt update
  sudo apt-get install -y curl wget zip unzip git apt-transport-https libuser

  #Confirm folder structure
  whiptail --title "Confirmation" --msgbox "The library folder structure was installed at $DATAFOLDER" 8 80
}
structure-uninstall() {
  echo "################################################################################"
  echo "# Removing Folder Structure                                                    #"
  echo "################################################################################"
  #Delete the folders
  sudo rm -rf "$DATAFOLDER"

  #Confirm folder structure removal
  whiptail --title "Confirmation" --msgbox "The library folder structure was removed at $DATAFOLDER" 8 80
}

cifs() {
  echo "################################################################################"
  echo "# Installing Cifs Utils and Samba                                              #"
  echo "################################################################################"
  #Open the firewall port
  sudo ufw allow "$SAMBAPORT"

  #Install the software
  sudo apt install -y cifs-utils samba

  #Append some samba settings to the samba config file
  echo "[$SAMBANAME]
path = $DATAFOLDER
create mask = 0777
directory mask = 0777
browseable = yes
writeable = yes
public = yes
only guest = no
read only = no" | sudo tee -a /etc/samba/smb.conf

  #Restart samba service after making changes
  sudo service smbd restart

  #Confirm the service is running
  servicecheck smbd
}
cifs-uninstall() {
  echo "################################################################################"
  echo "# Removing Lines From Samba                                                    #"
  echo "################################################################################"
  #Close the firewall port
  sudo ufw deny "$SAMBAPORT"

  #Remove the lines from the samba config
  #sudo sed -i "$(($(wc -l </etc/samba/smb.conf) - 9 + 1)),$ d" /etc/samba/smb.conf

  #Restart samba service after making changes
  #sudo service smbd restart

  #Remove the software
  sudo apt remove -y cifs-utils samba

  #Confirmation message
  whiptail --title "Confirmation" --msgbox "The Samba settings have been removed" 8 80
}

plex() {
  echo "################################################################################"
  echo "# Installing Plex Media Server                                                 #"
  echo "################################################################################"
  #Open the firewall port
  sudo ufw allow "$PLEXPORT"

  #Download the encryption key for the ppa repo
  curl https://downloads.plex.tv/plex-keys/PlexSign.key | sudo apt-key add -

  #Add the ppa to our sources
  echo deb https://downloads.plex.tv/repo/deb public main | sudo tee /etc/apt/sources.list.d/plexmediaserver.list

  #update and install the software
  sudo apt update
  sudo apt install -y plexmediaserver

  #confirm service is up and running
  servicecheck plexmediaserver
}
plex-uninstall() {
  echo "################################################################################"
  echo "# Uninstalling Plex Media Server                                               #"
  echo "################################################################################"
  #Close the firewall port
  sudo ufw deny "$PLEXPORT"

  #Remove the software
  sudo apt remove -y plexmediaserver

  #Remove the source file for the PPA
  sudo rm /etc/apt/sources.list.d/plexmediaserver.list

  #Confirmation message
  whiptail --title "Confirmation" --msgbox "The Plex software and settings have been removed" 8 80
}

radarr() {
  echo "################################################################################"
  echo "# Installing Radarr                                                            #"
  echo "################################################################################"
  RADARRCONFIG=$RADARRDATADIR"config.xml"
  DLREPO="$RADARRDLURL$ARREXTENSION"

  #If no data dir specified in service
  #The default folder is /home/radarr/

  #Open the firewall port
  sudo ufw allow "$RADARRPORT"

  #Make the data folder and add permissions
  sudo mkdir -p $RADARRDATADIR
  sudo chmod -R 777 $RADARRDATADIR

  #Add the group
  sudo addgroup $RADARRGROUP

  #Add the user to the group
  sudo adduser --system --no-create-home $RADARRUSER --ingroup $RADARRGROUP

  #Install dependencies
  sudo apt install curl sqlite3 -y

  #Download the repo
  sudo wget -nc --content-disposition "$DLREPO"

  #Uncompress it
  sudo tar -xvzf Radarr*.linux*.tar.gz

  #Move it to the /opt directory
  sudo mv Radarr /opt/

  #Change the owner
  sudo chown $RADARRUSER:$RADARRGROUP -R /opt/Radarr

  #Remove the left over downloaded repo
  sudo rm -rf Radarr*.linux*.tar.gz

  #Create the service file
  sudo touch /etc/systemd/system/$RADARRSERVICE.service

  #Append the service file
  echo "[Unit]
Description=Radarr Daemon
After=syslog.target network.target
[Service]
User=$RADARRUSER
Group=$RADARRGROUP
Type=simple

ExecStart=/opt/Radarr/Radarr -nobrowser -data=$RADARRDATADIR
TimeoutStopSec=20
KillMode=process
Restart=on-failure
[Install]
WantedBy=multi-user.target" | sudo tee -a /etc/systemd/system/$RADARRSERVICE.service

  #Reload services
  sudo systemctl -q daemon-reload

  #Enable service on start up
  sudo systemctl enable $RADARRSERVICE.service

  #Start service - creates all the directories and files
  sudo systemctl start $RADARRSERVICE.service

  #Stop the service
  sudo service $RADARRSERVICE stop

  #Update the port in the config file
  sudo sed -i "s/7878/$RADARRPORT/g" $RADARRCONFIG

  #Start the service again
  sudo service $RADARRSERVICE start

  #Check if service is running
  servicecheck $RADARRSERVICE
}
radarr-uninstall() {
  echo "################################################################################"
  echo "# Uninstalling Radarr                                                          #"
  echo "################################################################################"
  #Close the firewall port
  sudo ufw deny "$RADARRPORT"

  #Stop the service
  sudo systemctl stop $RADARRSERVICE.service

  #Remove the directories
  sudo rm -rf /opt/Radarr
  sudo rm -rf $RADARRDATADIR

  #Remove the service file
  sudo rm -rf /etc/systemd/system/$RADARRSERVICE.service

  #Reload the services
  sudo systemctl -q daemon-reload

  #Remove the user
  sudo deluser $RADARRUSER

  #Check the user group
  groupcheck $RADARRGROUP

  #Confirmation message
  whiptail --title "Confirmation" --msgbox "The Radarr software and settings have been removed" 8 80
}

sonarr() {
  echo "################################################################################"
  echo "# Installing Sonarr                                                            #"
  echo "################################################################################"
  #Confirmation message
  whiptail --title "Confirmation" --msgbox "The Sonarr installer will prompt you for a user and group to run as, I suggest setting user as sonarr and group as media in line with the other programs." 9 80

  #Open the firewall port
  sudo ufw allow "$SONARRPORT"

  #Install dependencies
  sudo apt install gnupg ca-certificates dirmngr

  #Download and install dependency Media Info
  wget -nc https://mediaarea.net/repo/deb/repo-mediaarea_1.0-19_all.deb && sudo dpkg -i repo-mediaarea_1.0-19_all.deb

  #Install the Mono PPA
  if [ "$ARCH" = "amd64" ]; then
    sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
    echo "deb https://download.mono-project.com/repo/ubuntu stable-focal main" | sudo tee /etc/apt/sources.list.d/mono-official-stable.list
  else
    sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
    echo "deb https://download.mono-project.com/repo/debian stable-raspbianbuster main" | sudo tee /etc/apt/sources.list.d/mono-official-stable.list
  fi

  #Install the Sonarr PPA
  if [ "$ARCH" = "amd64" ]; then
    sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 2009837CBFFD68F45BC180471F4F90DE2A9B4BF8
    echo "deb https://apt.sonarr.tv/ubuntu focal main" | sudo tee /etc/apt/sources.list.d/sonarr.list
  else
    sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 2009837CBFFD68F45BC180471F4F90DE2A9B4BF8
    echo "deb https://apt.sonarr.tv/debian buster main" | sudo tee /etc/apt/sources.list.d/sonarr.list
  fi

  #Update Repos
  sudo apt update

  #Install Sonarr
  sudo apt install sonarr -y

  #Mono SSL Bug Fix
  sudo cert-sync /etc/ssl/certs/ca-certificates.crt

  #Change the sonarr port number in the config
  sudo sed -i "s/8989/$SONARRPORT/g" /var/lib/sonarr/config.xml

  #Restart the service
  sudo service sonarr restart

  #Remove the media area download
  sudo rm -rf repo-mediaarea*

  #Confirm service is running
  servicecheck sonarr
}
sonarr-uninstall() {
  echo "################################################################################"
  echo "# Uninstalling Sonarr                                                          #"
  echo "################################################################################"
  #Close the firewall port
  sudo ufw deny "$SONARRPORT"

  #Uninstall the software
  sudo apt remove sonarr -y

  #Remove the PPA sources
  sudo rm /etc/apt/sources.list.d/mono-official-stable.list
  sudo rm /etc/apt/sources.list.d/sonarr.list

  #Delete the user
  #sudo deluser $(cat /lib/systemd/system/sonarr.service | grep "User=" | sed -E  's/(.*)=(.*)/\2/');

  #Check the user group
  #groupcheck $(cat /lib/systemd/system/sonarr.service | grep "Group=" | sed -E  's/(.*)=(.*)/\2/');

  #Confirmation message
  whiptail --title "Confirmation" --msgbox "The Sonarr software and settings have been removed" 8 80
}

whisparr() {
  echo "################################################################################"
  echo "# Installing Whisparr                                                          #"
  echo "################################################################################"
  WHISPARRCONFIG=$WHISPARRDATADIR"config.xml"
  DLREPO="$WHISPARRDLURL$ARREXTENSION"

  #Open the firewall port
  sudo ufw allow "$WHISPARRPORT"

  #Make the data folder and add permissions
  sudo mkdir -p $WHISPARRDATADIR
  sudo chmod -R 777 $WHISPARRDATADIR

  #Add the group
  sudo addgroup $WHISPARRGROUP

  #Add the user to the group
  sudo adduser --system --no-create-home $WHISPARRUSER --ingroup $WHISPARRGROUP

  #Install dependencies
  sudo apt install curl sqlite3 -y

  #Download the repo
  sudo wget -nc --content-disposition "$DLREPO"

  #Uncompress it
  sudo tar -xvzf Whisparr*.linux*.tar.gz

  #Move it to the /opt directory
  sudo mv Whisparr /opt/

  #Change the owner
  sudo chown $WHISPARRUSER:$WHISPARRGROUP -R /opt/Whisparr

  #Remove the left over downloaded repo
  sudo rm -rf Whisparr*.linux*.tar.gz

  #Create the service file
  sudo touch /etc/systemd/system/$WHISPARRSERVICE.service

  #Append the service file
  echo "[Unit]
Description=Whisparr Daemon
After=syslog.target network.target
[Service]
User=$WHISPARRUSER
Group=$WHISPARRGROUP
Type=simple

ExecStart=/opt/Whisparr/Whisparr -nobrowser -data=$WHISPARRDATADIR
TimeoutStopSec=20
KillMode=process
Restart=on-failure
[Install]
WantedBy=multi-user.target" | sudo tee -a /etc/systemd/system/$WHISPARRSERVICE.service

  #Reload services
  sudo systemctl -q daemon-reload

  #Enable service on start up
  sudo systemctl enable $WHISPARRSERVICE.service

  #Start service - creates all the directories and files
  sudo systemctl start $WHISPARRSERVICE.service

  #Stop the service
  sudo service $WHISPARRSERVICE stop

  #Update the port in the config file
  sudo sed -i "s/6969/$WHISPARRPORT/g" $WHISPARRCONFIG

  #Start the service again
  sudo service $WHISPARRSERVICE start

  #Check if service is running
  servicecheck $WHISPARRSERVICE
}
whisparr-uninstall() {
  echo "################################################################################"
  echo "# Uninstalling Whisparr                                                        #"
  echo "################################################################################"
  #Close the firewall port
  sudo ufw deny "$WHISPARRPORT"

  #Stop the service
  sudo systemctl stop $WHISPARRSERVICE.service

  #Remove the directories
  sudo rm -rf /opt/Whisparr
  sudo rm -rf $WHISPARRDATADIR

  #Remove the service file
  sudo rm -rf /etc/systemd/system/$WHISPARRSERVICE.service

  #Reload the services
  sudo systemctl -q daemon-reload

  #Remove the user
  sudo deluser $WHISPARRUSER

  #Check the user group
  groupcheck $WHISPARRGROUP

  #Confirmation message
  whiptail --title "Confirmation" --msgbox "The Whisparr software and settings have been removed" 8 80

}

lidarr() {
  echo "################################################################################"
  echo "# Installing Lidarr                                                          #"
  echo "################################################################################"
  LIDARRCONFIG=$LIDARRDATADIR"config.xml"
  DLREPO="$LIDARRDLURL$ARREXTENSION"

  #Open the firewall port
  sudo ufw allow "$LIDARRPORT"

  #Make the data folder and add permissions
  sudo mkdir -p $LIDARRDATADIR
  sudo chmod -R 777 $LIDARRDATADIR

  #Add the user and group
  sudo addgroup $LIDARRGROUP

  #Add the user to the group
  sudo adduser --system --no-create-home $LIDARRUSER --ingroup $LIDARRGROUP

  #Install dependencies
  sudo apt install curl mediainfo sqlite3 libchromaprint-tools -y

  #Download the repo
  sudo wget -nc --content-disposition "$DLREPO"

  #Uncompress it
  sudo tar -xvzf Lidarr*.linux*.tar.gz

  #Move it to the /opt directory
  sudo mv Lidarr /opt/

  #Change the owner
  sudo chown $LIDARRUSER:$LIDARRGROUP -R /opt/Lidarr

  #Remove the left over downloaded repo
  sudo rm -rf Lidarr*.linux*.tar.gz

  #Create the service file
  sudo touch /etc/systemd/system/$LIDARRSERVICE.service

  #Append the service file
  echo "[Unit]
  Description=Lidarr Daemon
  After=syslog.target network.target
  [Service]
  User=$LIDARRUSER
  Group=$LIDARRGROUP
  Type=simple
  
  ExecStart=/opt/Lidarr/Lidarr -nobrowser -data=$LIDARRDATADIR
  TimeoutStopSec=20
  KillMode=process
  Restart=on-failure
  [Install]
  WantedBy=multi-user.target" | sudo tee -a /etc/systemd/system/$LIDARRSERVICE.service

  #Reload services
  sudo systemctl -q daemon-reload

  #Enable service on start up
  sudo systemctl enable $LIDARRSERVICE.service

  #Start service - creates all the directories and files
  sudo systemctl start $LIDARRSERVICE.service

  #Stop the service
  sudo service $LIDARRSERVICE stop

  #Update the port in the config file
  sudo sed -i "s/8686/$LIDARRPORT/g" $LIDARRCONFIG

  #Start the service again
  sudo service $LIDARRSERVICE start

  #Check if service is running
  servicecheck $LIDARRSERVICE
}
lidarr-uninstall() {
  echo "################################################################################"
  echo "# Uninstalling Lidarr                                                        #"
  echo "################################################################################"
  #Close the firewall port
  sudo ufw deny "$LIDARRPORT"

  #Stop the service
  sudo systemctl stop $LIDARRSERVICE.service

  #Remove the directories
  sudo rm -rf /opt/Lidarr
  sudo rm -rf $LIDARRDATADIR

  #Remove the service file
  sudo rm -rf /etc/systemd/system/$LIDARRSERVICE.service

  #Reload the services
  sudo systemctl -q daemon-reload

  #Remove the user
  sudo deluser $LIDARRUSER

  #Check the user group
  groupcheck $LIDARRGROUP

  #Confirmation message
  whiptail --title "Confirmation" --msgbox "The Lidarr software and settings have been removed" 8 80
}

readarr() {
  echo "################################################################################"
  echo "# Installing Readarr                                                          #"
  echo "################################################################################"
  READARRCONFIG=$READARRDATADIR"config.xml"
  DLREPO="$READARRDLURL$ARREXTENSION"

  #Open the firewall port
  sudo ufw allow "$READARRPORT"

  #Make the data folder and add permissions
  sudo mkdir -p $READARRDATADIR
  sudo chmod -R 777 $READARRDATADIR

  #Add the user and group
  sudo addgroup $READARRGROUP

  #Add the user to the group
  sudo adduser --system --no-create-home $READARRUSER --ingroup $READARRGROUP

  #Install dependencies
  sudo apt install curl mediainfo sqlite3 libchromaprint-tools -y

  #Download the repo
  sudo wget -nc --content-disposition "$DLREPO"

  #Uncompress it
  sudo tar -xvzf Readarr*.linux*.tar.gz

  #Move it to the /opt directory
  sudo mv Readarr /opt/

  #Change the owner
  sudo chown $READARRUSER:$READARRGROUP -R /opt/Readarr

  #Remove the left over downloaded repo
  sudo rm -rf Readarr*.linux*.tar.gz

  #Create the service file
  sudo touch /etc/systemd/system/$READARRSERVICE.service

  #Append the service file
  echo "[Unit]
    Description=Readarr Daemon
    After=syslog.target network.target
    [Service]
    User=$READARRUSER
    Group=$READARRGROUP
    Type=simple
    
    ExecStart=/opt/Readarr/Readarr -nobrowser -data=$READARRDATADIR
    TimeoutStopSec=20
    KillMode=process
    Restart=on-failure
    [Install]
    WantedBy=multi-user.target" | sudo tee -a /etc/systemd/system/$READARRSERVICE.service

  #Reload services
  sudo systemctl -q daemon-reload

  #Enable service on start up
  sudo systemctl enable $READARRSERVICE.service

  #Start service - creates all the directories and files
  sudo systemctl start $READARRSERVICE.service

  #Stop the service
  sudo service $READARRSERVICE stop

  #Update the port in the config file
  sudo sed -i "s/8787/$READARRPORT/g" $READARRCONFIG

  #Start the service again
  sudo service $READARRSERVICE start

  #Check if service is running
  servicecheck $READARRSERVICE

}
readarr-uninstall() {
  echo "################################################################################"
  echo "# Uninstalling Readarr                                                         #"
  echo "################################################################################"
  #Close the firewall port
  sudo ufw deny "$READARRPORT"

  #Stop the service
  sudo systemctl stop $READARRSERVICE.service

  #Remove the directories
  sudo rm -rf /opt/Readarr
  sudo rm -rf $READARRDATADIR

  #Remove the service file
  sudo rm -rf /etc/systemd/system/$READARRSERVICE.service

  #Reload the services
  sudo systemctl -q daemon-reload

  #Remove the user
  sudo deluser $READARRUSER

  #Check the user group
  groupcheck $READARRGROUP

  #Confirmation message
  whiptail --title "Confirmation" --msgbox "The Readarr software and settings have been removed" 8 80
}

jackett() {
  echo "################################################################################"
  echo "# Installing Jackett                                                           #"
  echo "################################################################################"
  #Open port in firewall
  sudo ufw allow "$JACKETTPORT"

  #Use the correct release for the architecture
  RELEASE=""
  if [ "$ARCH" = "amd64" ]; then
    #Compressed Release
    RELEASE=Jackett.Binaries.LinuxAMDx64.tar.gz
  else
    #Compressed Release
    RELEASE=Jackett.Binaries.LinuxARM32.tar.gz
  fi

  #Get latest version
  VERSION=$(wget -q https://github.com/Jackett/Jackett/releases/latest -O - | grep "title>Release" | cut -d " " -f 4)

  #Download repo
  sudo wget -Nc https://github.com/Jackett/Jackett/releases/download/"$VERSION"/"$RELEASE"

  #Uncompress the download
  sudo tar -xzf "$RELEASE"

  #Move it to the /opt directory
  sudo mv Jackett /opt/

  #Delete the Downloaded file
  sudo rm -f "$RELEASE"

  #Install the service
  sudo /opt/Jackett/install_service_systemd.sh

  #Get the owner of the Jackett folder
  JACKETTUSER=$(stat -c "%U" /opt/Jackett/jackett)

  #Change the Jackett port number
  #sudo sed -i "s/9117/$JACKETTPORT/g" /home/"$JACKETTUSER"/.config/Jackett/ServerConfig.json

  #Restart Jackett service
  sudo service $JACKETTSERVICE restart

  #Check if service is running
  servicecheck $JACKETTSERVICE
}
jackett-uninstall() {
  echo "################################################################################"
  echo "# Uninstalling Jackett                                                         #"
  echo "################################################################################"
  #Close the firewall port
  sudo ufw deny "$JACKETTPORT"

  #Stop the service
  sudo systemctl stop jackett.service

  #get the Jackett user
  JACKETTUSER=$(stat -c "%U" /opt/Jackett/jackett)

  #Remove the service
  sudo rm /etc/systemd/system/jackett.service

  #Remove the program directories
  sudo rm -rf /home/"$JACKETTUSER"/.config/Jackett
  sudo rm -rf /opt/Jackett

  #Confirmation message
  whiptail --title "Confirmation" --msgbox "The Jackett software and settings have been removed" 8 80
}

qbittorrent() {
  echo "################################################################################"
  echo "# Installing Qbittorrent                                                       #"
  echo "################################################################################"
  #Open the port in the firewall
  sudo ufw allow "$QBITTORRENTPORT"

  #Add the PPA
  sudo add-apt-repository -y ppa:qbittorrent-team/qbittorrent-stable

  #Update the system
  sudo apt update

  #Install the software
  sudo apt install qbittorrent-nox -y

  #Create the service
  sudo touch /etc/systemd/system/$QBITTORRENTSERVICE.service

  #Append the service file
  echo "[Unit]
Description=qBittorrent client
After=network.target

[Service]
ExecStart=/usr/bin/qbittorrent-nox --webui-port=$QBITTORRENTPORT
Restart=always

[Install]
WantedBy=multi-user.target" | sudo tee -a /etc/systemd/system/$QBITTORRENTSERVICE.service

  #First time install? dont need to adjust this.
  #sudo sed -i "s/8080/$QBITTORRENTPORT/g" /.config/qBittorrent/qBittorrent.conf;

  #Enable Service on startup
  sudo systemctl enable $QBITTORRENTSERVICE.service

  #Start the service
  sudo systemctl start $QBITTORRENTSERVICE.service

  #Check if service is running
  servicecheck $QBITTORRENTSERVICE
}
qbittorrent-uninstall() {
  echo "################################################################################"
  echo "# Uninstalling Qbittorrent                                                     #"
  echo "################################################################################"
  #Close the firewall port
  sudo ufw deny "$QBITTORRENTPORT"

  #Stop the service
  sudo systemctl stop $QBITTORRENTSERVICE.service

  #Uninstall the software
  sudo apt remove qbittorrent-nox -y

  #Remove the service file
  sudo rm /etc/systemd/system/$QBITTORRENTSERVICE.service

  #Remove the program directories
  sudo rm -rf /.config/qBittorrent
  sudo rm -rf /.local/share/qBittorrent
  sudo rm -rf /.cache/qBittorrent

  #Confirmation message
  whiptail --title "Confirmation" --msgbox "The Qbittorrent software and settings have been removed" 8 80
}

tautulli() {
  echo "################################################################################"
  echo "# Installing Tautulli                                                          #"
  echo "################################################################################"
  #Open the port in the firewall
  sudo ufw allow "$TAUTULLIPORT"

  #Install dependencies
  sudo apt-get install git python3.7 python3-setuptools -y

  #Make the program directory
  sudo mkdir /opt/Tautulli

  #Clone the repo to the program folder
  sudo git clone https://github.com/Tautulli/Tautulli.git /opt/Tautulli

  #create the user and group
  sudo addgroup $TAUTULLIGROUP

  #Add the user to the group
  sudo adduser --system --no-create-home $TAUTULLIUSER --ingroup $TAUTULLIGROUP

  #change the owner of the program folder
  sudo chown -R $TAUTULLIUSER:$TAUTULLIGROUP /opt/Tautulli

  #Replace the permissions in the service file
  sudo sed -i "s/USER=tautulli/USER=$TAUTULLIUSER/g" /opt/Tautulli/init-scripts/init.systemd
  sudo sed -i "s/GROUP=tautulli/GROUP=$TAUTULLIGROUP/g" /opt/Tautulli/init-scripts/init.systemd

  #Copy the system service file
  sudo cp /opt/Tautulli/init-scripts/init.systemd /lib/systemd/system/$TAUTULLISERVICE.service

  #Replace the port in the config
  #sudo sed -i "s/8181/$TAUTULLIPORT/g" /opt/Tautulli/config.ini

  #Reload the services
  sudo systemctl daemon-reload

  #Enable the service on startup
  sudo systemctl enable $TAUTULLISERVICE.service

  #Start the service
  sudo systemctl start $TAUTULLISERVICE.service

  #Check if service is running
  servicecheck $TAUTULLISERVICE
}
tautulli-uninstall() {
  echo "################################################################################"
  echo "# Uninstalling Tautulli                                                        #"
  echo "################################################################################"
  #Close the port in the firewall
  sudo ufw deny "$TAUTULLIPORT"

  #Stop the service
  sudo systemctl stop $TAUTULLISERVICE.service

  #Remove the service
  sudo rm /lib/systemd/system/$TAUTULLISERVICE.service

  #Remove the program folder
  sudo rm -rf /opt/Tautulli

  #remove the user
  sudo deluser $TAUTULLIUSER

  #Check the user group
  groupcheck $TAUTULLIGROUP

  #Reload the services
  sudo systemctl daemon-reload

  #Confirmation message
  whiptail --title "Confirmation" --msgbox "The Tautilli software and settings have been removed" 8 80
}

ombi() {
  echo "################################################################################"
  echo "# Installing OMBI                                                              #"
  echo "################################################################################"
  #Add the PPA
  echo "deb https://apt.ombi.app/develop jessie main" | sudo tee /etc/apt/sources.list.d/ombi.list

  #Download the Signed Key
  curl -sSL https://apt.ombi.app/pub.key | sudo apt-key add -

  #Update and install ombi
  sudo apt update && sudo apt install ombi

  #replace the port in the ombi service file
  sudo sed -i "s,ExecStart=/opt/Ombi/Ombi --storage /etc/Ombi/,ExecStart=/opt/Ombi/Ombi --storage /etc/Ombi/ --host http://*:$OMBIPORT,g" /lib/systemd/system/ombi.service

  #Reload the services
  sudo systemctl daemon-reload

  #Start the service
  sudo service ombi start

  #Check if service is running
  servicecheck ombi
}
ombi-uninstall() {
  echo "################################################################################"
  echo "# Uninstalling OMBI                                                            #"
  echo "################################################################################"
  #Close the firewall port
  sudo ufw deny "$OMBIPORT"

  #Stop the service
  sudo service ombi stop

  #Remove the program
  sudo apt remove ombi -y

  #Remove the service file
  sudo rm /lib/systemd/system/ombi.service

  #Reload the services
  sudo systemctl daemon-reload

  #Confirmation message
  whiptail --title "Confirmation" --msgbox "The Ombi software and settings have been removed" 8 80
}

# shellcheck disable=SC2032
openpyn() {
  echo "################################################################################"
  echo "# Installing OpenPyn                                                           #"
  echo "################################################################################"
  #Requirement Quest
  if (whiptail --title "Requirements" --yesno "Openpyn requires you do have a nord vpn account, do you want to continue?" 8 80); then
    #Install Dependencies
    sudo apt install -y openvpn python3-setuptools python3-pip

    #Install the program
    sudo python3 -m pip install --upgrade openpyn

    #Initialise the service
    sudo openpyn --init

    #Check if service is running
    servicecheck openpyn
  else
    return
  fi

}
openpyn-uninstall() {
  echo "################################################################################"
  echo "# Uninstalling Openpyn                                                         #"
  echo "################################################################################"
  #Remove the program
  sudo apt remove -y openvpn
  #Uninstall the program
  sudo python3 -m pip uninstall openpyn -y

  #Confirmation message
  whiptail --title "Confirmation" --msgbox "The Openpyn software and settings have been removed" 8 80
}

simpledash() {
  echo "################################################################################"
  echo "# Installing SimpleDash                                                        #"
  echo "################################################################################"
  IP=$(whiptail --inputbox "What is your IP address?" 8 39 127.0.0.1 --title "IP Address Question" 3>&1 1>&2 2>&3)
  exitstatus=$?
  if [ $exitstatus = 0 ]; then
    #Open the port in the firewall
    sudo ufw allow 80

    #Install Nginx to be your webserver
    sudo apt-get install -y nginx

    #Enable Nginx to run on startup
    sudo systemctl enable nginx.service

    #Remove the default html folder and all contents
    sudo rm -rf /var/www/html

    #Create the empty html folder
    sudo mkdir /var/www/html

    #Clone the simpledash repo into the html folder
    sudo git clone https://github.com/kutyla-philipp/simple-dash.git /var/www/html/.

    #Clear the config file
    sudo truncate -s 0 /var/www/html/config.json

    #Append the config file
    echo '{
                	"title" : "Media Automation",
                	"items" : [
                		{
                			"alt" : "Plex Media Server",
                			"icon" : "fa fa-play",
                			"link" : "http://'"$IP"':'"$PLEXPORT"'/web/index.html#!/"
                		},
                		{
                			"alt" : "Radarr",
                			"icon" : "fa fa-film",
                			"link" : "http://'"$IP"':'"$RADARRPORT"'/"
                		},
                		{
                      "alt" : "Whisparr",
                      "icon" : "fa fa-user-secret",
                      "link" : "http://'"$IP"':'"$WHISPARRPORT"'/"
                    },
                    {
                      "alt" : "Readarr",
                      "icon" : "fa fa-book",
                      "link" : "http://'"$IP"':'"$READARRPORT"'/"
                    },
                    {
                      "alt" : "Lidarr",
                      "icon" : "fa fa-music",
                      "link" : "http://'"$IP"':'"$LIDARRPORT"'/"
                    },
                		{
                			"alt" : "Sonarr",
                			"icon" : "fa fa-tv",
                			"link" : "http://'"$IP"':'"$SONARRPORT"'/"
                		},
                		{
                			"alt" : "Jackett",
                			"icon" : "fa fa-project-diagram",
                			"link" : "http://'"$IP"':'"$JACKETTPORT"'/UI/Dashboard"
                		},
                		{
                			"alt" : "Tautilli",
                			"icon" : "fa fa-chart-line",
                			"link" : "http://'"$IP"':'"$TAUTULLIPORT"'/"
                		},
                		{
                			"alt" : "Qbittorrent",
                			"icon" : "fa fa-tint",
                			"link" : "http://'"$IP"':'"$QBITTORRENTPORT"'/"
                		},
                    {
                      "alt" : "Ombi",
                      "icon" : "fa fa-search",
                      "link" : "http://'"$IP"':'"$OMBIPORT"'/"
                    }
                	]
                }' | sudo tee -a /var/www/html/config.json

    #Check if service is running
    servicecheck nginx

    #Confirmation message
    whiptail --title "Confirmation" --msgbox "Access the dashboard at http://$IP" 8 80
  else
    return
  fi
}
simpledash-uninstall() {
  echo "################################################################################"
  echo "# Uninstalling Simpledash                                                      #"
  echo "################################################################################"
  #Close the port
  sudo ufw deny 80

  #Remove the html folder
  sudo rm -rf /var/www/html

  #Uninstall nginx
  sudo apt remove nginx -y

  #Confirmation message
  whiptail --title "Confirmation" --msgbox "The Simple Dash software and settings have been removed" 8 80
}

servicecheck() {
  SERVICECHECK=$(systemctl is-active --quiet "$1")
  if [ -z "$SERVICECHECK" ]; then
    whiptail --title "Service Check" --msgbox "The service $1 was installed successfully" 8 80
  else
    whiptail --title "Service Check" --msgbox "Something fucked up when installing $1" 8 80
  fi
}
groupcheck() {
  GROUPCHECK=$(sudo /usr/sbin/libuser-lid -g "$1")
  if [ -z "$GROUPCHECK" ]; then
    sudo groupdel "$1"
  else
    echo "Still members in the group not deleting it"
  fi
}
mainmenu() {
  while true; do
    CHOICE=$(
      whiptail --title "Media Automation Home Menu" --menu "Make your choice" 11 80 3 \
        "1)" "Install Services" \
        "2)" "Uninstall Services" \
        "3)" "End script" 3>&2 2>&1 1>&3
    )
    case $CHOICE in
    "1)")
      installmenu
      ;;
    "2)")
      uninstallmenu
      ;;
    "3)")
      exit
      ;;
    esac
  done
}
installmenu() {
  while true; do
    CHOICE=$(
      whiptail --title "Media Automation Install Menu" --menu "Make your choice" 23 80 15 \
        "1)" "Setup Folder Structure" \
        "2)" "Install Cifs & Samba" \
        "3)" "Install Plex Media Server" \
        "4)" "Install Radarr" \
        "5)" "Install Sonarr" \
        "6)" "Install Whisparr" \
        "7)" "Install Lidarr" \
        "8)" "Install Readarr" \
        "9)" "Install Jackett" \
        "10)" "Install Qbittorrent" \
        "11)" "Install Tautulli" \
        "12)" "Install Ombi" \
        "13)" "Install OpenPyn" \
        "14)" "Install Simple Dash" \
        "15)" "<-- Back" 3>&2 2>&1 1>&3
    )
    case $CHOICE in
    "1)")
      structure
      ;;
    "2)")
      cifs
      ;;
    "3)")
      plex
      ;;
    "4)")
      radarr
      ;;
    "5)")
      sonarr
      ;;
    "6)")
      whisparr
      ;;
    "7)")
      lidarr
      ;;
    "8)")
      readarr
      ;;
    "9)")
      jackett
      ;;
    "10)")
      qbittorrent
      ;;
    "11)")
      tautulli
      ;;
    "12)")
      ombi
      ;;
    "13)")
      openpyn
      ;;
    "14)")
      simpledash
      ;;
    "15)")
      break
      ;;
    esac
  done
}
uninstallmenu() {
  while true; do
    CHOICE=$(
      whiptail --title "Media Automation Uninstall Menu" --menu "Make your choice" 23 80 15 \
        "1)" "Remove Folder Structure" \
        "2)" "Uninstall Cifs & Samba" \
        "3)" "Uninstall Plex Media Server" \
        "4)" "Uninstall Radarr" \
        "5)" "Uninstall Sonarr" \
        "6)" "Uninstall Whisparr" \
        "7)" "Uninstall Lidarr" \
        "8)" "Uninstall Readarr" \
        "9)" "Uninstall Jackett" \
        "10)" "Uninstall Qbittorrent" \
        "11)" "Uninstall Tautulli" \
        "12)" "Uninstall Ombi" \
        "13)" "Uninstall OpenPyn" \
        "14)" "Uninstall Simple Dash" \
        "15)" "<-- Back" 3>&2 2>&1 1>&3
    )
    case $CHOICE in
    "1)")
      structure-uninstall
      ;;
    "2)")
      cifs-uninstall
      ;;
    "3)")
      plex-uninstall
      ;;
    "4)")
      radarr-uninstall
      ;;
    "5)")
      sonarr-uninstall
      ;;
    "6)")
      whisparr-uninstall
      ;;
    "7)")
      lidarr-uninstall
      ;;
    "8)")
      readarr-uninstall
      ;;
    "9)")
      jackett-uninstall
      ;;
    "10)")
      qbittorrent-uninstall
      ;;
    "11)")
      tautulli-uninstall
      ;;
    "12)")
      ombi-uninstall
      ;;
    "13)")
      openpyn-uninstall
      ;;
    "14)")
      simpledash-uninstall
      ;;
    "15)")
      break
      ;;
    esac
  done
}

mainmenu