#!/bin/bash

################################################################################
# Media Server Install Script                                                  #
#                                                                              #
# This script installs the following software                                  #
#                                                                              #
# Radarr                                                                       #
# Sonarr                                                                       #
# Jackett                                                                      #
# Qbittorrent                                                                  #
# Plex Media Server                                                            #
# Tautilli                                                                     #
# Simple Dash                                                                  #
# OpenPyn                                                                      #
# Cifs Utils                                                                   #
#                                                                              #
# Author: Micheal Howlin                                                       #
#                                                                              #
################################################################################

################################################################################
# Load the config variables                                                      #
################################################################################
CWD=$(pwd)
DATAFOLDER="/mnt/mediaautomation/"
SAMBANAME="mediaautomation"
QBITTORRENTPORT="8080"
IP=$(hostname -I)
IP=$(echo $IP | xargs)
ARCH=$(dpkg --print-architecture)

#Hardcode your IP here
#IP="127.0.0.1"

################################################################################
# Help                                                                         #
################################################################################
Help()
{
  # Display Help
  echo "################################################################################";
  echo "# Media Server Install Script                                                  #";
  echo "#                                                                              #";
  echo "# Author: Micheal Howlin                                                       #";
  echo "#                                                                              #";
  echo "################################################################################";
}

################################################################################
# Process the input options. Add options as needed.                            #
################################################################################
# Get the options
while getopts ":h" option; do
   case $option in
      h) # display Help
         Help
         exit;;
   esac
done

################################################################################
################################################################################
# Main program                                                                 #
################################################################################
################################################################################

structure(){
  echo "################################################################################";
  echo "# Step 1 - Creating Folder Structure and Updating                              #";
  echo "################################################################################";
  sudo mkdir -p $DATAFOLDER
  sudo mkdir -p "$DATAFOLDER/torrents/downloading"
  sudo mkdir -p "$DATAFOLDER/torrents/complete"
  sudo mkdir -p "$DATAFOLDER/video/movies"
  sudo mkdir -p "$DATAFOLDER/video/tv"
  sudo apt update
  sudo apt-get install -y curl wget zip unzip git apt-transport-https
  sudo ufw allow 80
  sudo ufw allow 32400
  sudo ufw allow 7878
  sudo ufw allow 8989
  sudo ufw allow 9117
  sudo ufw allow 8181
  sudo ufw allow 8080
}
structure-uninstall(){
  echo "################################################################################";
  echo "# Removing Folder Structure                                                    #";
  echo "################################################################################";
  sudo rm -rf $DATAFOLDER
  echo "################################################################################";
  echo "# Closing Firewall Ports                                                       #";
  echo "################################################################################";
  sudo ufw deny 80
  sudo ufw deny 32400
  sudo ufw deny 7878
  sudo ufw deny 8989
  sudo ufw deny 9117
  sudo ufw deny 8181
  sudo ufw deny 8080
}

cifs(){
  echo "################################################################################";
  echo "# Step 2 - Cifs Utils and Samba                                                #";
  echo "################################################################################";
  sudo apt install cifs-utils -y
  sudo apt install samba -y
  echo "[$SAMBANAME]
  path = $DATAFOLDER
  create mask = 0777
  directory mask = 0777
  browseable = yes
  writeable = yes
  public = yes
  only guest = no
  read only = no" | sudo tee -a /etc/samba/smb.conf
}
cifs-uninstall(){
  echo "################################################################################";
  echo "# Removing Lines From Samba                                                    #";
  echo "################################################################################";
  sudo sed -i "$(( $(wc -l </etc/samba/smb.conf)-9+1 )),$ d" /etc/samba/smb.conf
  sudo service smbd restart
}

plex(){
  echo "################################################################################";
  echo "# Step 3 - Installing Plex Media Server                                        #";
  echo "################################################################################";
  curl https://downloads.plex.tv/plex-keys/PlexSign.key | sudo apt-key add -
  echo deb https://downloads.plex.tv/repo/deb public main | sudo tee /etc/apt/sources.list.d/plexmediaserver.list
  sudo apt update
  sudo apt install plexmediaserver -y
}
plex-uninstall(){
  echo "################################################################################";
  echo "# Uninstalling Plex Media Server                                               #";
  echo "################################################################################";
  sudo apt remove plexmediaserver -y
  sudo rm /etc/apt/sources.list.d/plexmediaserver.list
}

radarr(){
  echo "################################################################################";
  echo "# Step 4 - Installing Radarr                                                   #";
  echo "################################################################################";
  sudo mkdir -p /home/radarr/
  sudo chmod -R 777 /home/radarr/
  sudo addgroup media && sudo adduser --system --no-create-home radarr --ingroup media
  sudo apt install curl sqlite3 -y

  if [ "$ARCH" = "amd64" ];
    then
      sudo wget -nc --content-disposition 'http://radarr.servarr.com/v1/update/master/updatefile?os=linux&runtime=netcore&arch=x64'
  elif [ "$ARCH" = "arm64" ];
    then
      sudo wget -nc --content-disposition 'http://radarr.servarr.com/v1/update/master/updatefile?os=linux&runtime=netcore&arch=arm64'
  else
    sudo wget -nc --content-disposition 'http://radarr.servarr.com/v1/update/master/updatefile?os=linux&runtime=netcore&arch=arm'
  fi

  sudo tar -xvzf Radarr*.linux*.tar.gz
  sudo mv Radarr /opt/
  sudo chown radarr:media -R /opt/Radarr
  sudo rm -rf Radarr*.linux*.tar.gz
  sudo touch /etc/systemd/system/radarr.service
  echo "[Unit]
Description=Radarr Daemon
After=syslog.target network.target
[Service]
User=radarr
Group=media
Type=simple

ExecStart=/opt/Radarr/Radarr -nobrowser
TimeoutStopSec=20
KillMode=process
Restart=on-failure
[Install]
WantedBy=multi-user.target" | sudo tee -a /etc/systemd/system/radarr.service
  sudo systemctl -q daemon-reload
  sudo systemctl enable radarr.service
  sudo systemctl start radarr.service
}
radarr-uninstall(){
  echo "################################################################################";
  echo "# Uninstalling Radarr                                                          #";
  echo "################################################################################";
  sudo systemctl stop radarr.service
  sudo rm -rf /opt/Radarr
  sudo rm -rf /etc/systemd/system/radarr.service
  sudo rm -rf /var/lib/radarr
  sudo systemctl -q daemon-reload
  sudo deluser radarr
}

sonarr(){
  echo "################################################################################";
  echo "# Step 5 - Installing Sonarr                                                   #";
  echo "################################################################################";
  sudo apt install gnupg ca-certificates dirmngr
  wget -nc https://mediaarea.net/repo/deb/repo-mediaarea_1.0-19_all.deb && sudo dpkg -i repo-mediaarea_1.0-19_all.deb

  if [ "$ARCH" = "amd64" ];
    then
      sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
      echo "deb https://download.mono-project.com/repo/ubuntu stable-focal main" | sudo tee /etc/apt/sources.list.d/mono-official-stable.list

      sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 2009837CBFFD68F45BC180471F4F90DE2A9B4BF8
      echo "deb https://apt.sonarr.tv/ubuntu focal main" | sudo tee /etc/apt/sources.list.d/sonarr.list
  else
    sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
    echo "deb https://download.mono-project.com/repo/debian stable-raspbianbuster main" | sudo tee /etc/apt/sources.list.d/mono-official-stable.list

    sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 2009837CBFFD68F45BC180471F4F90DE2A9B4BF8
    echo "deb https://apt.sonarr.tv/debian buster main" | sudo tee /etc/apt/sources.list.d/sonarr.list
  fi

  sudo apt update
  sudo apt install sonarr -y
  sudo cert-sync /etc/ssl/certs/ca-certificates.crt
  sudo rm -rf repo-mediaarea*
}
sonarr-uninstall(){
  echo "################################################################################";
  echo "# Uninstalling Sonarr                                                          #";
  echo "################################################################################";
  sudo apt remove sonarr -y
  sudo rm /etc/apt/sources.list.d/mono-official-stable.list
  sudo rm /etc/apt/sources.list.d/sonarr.list
  sudo deluser sonarr
}

jackett(){
  echo "################################################################################";
  echo "# Step 6 - Installing Jackett                                                  #";
  echo "################################################################################";

  if [ "$ARCH" = "amd64" ];
      then
        cd /opt && f=Jackett.Binaries.LinuxAMDx64.tar.gz && release=$(wget -q https://github.com/Jackett/Jackett/releases/latest -O - | grep "title>Release" | cut -d " " -f 4) && sudo wget -Nc https://github.com/Jackett/Jackett/releases/download/$release/"$f" && sudo tar -xzf "$f" && sudo rm -f "$f" && cd Jackett* && sudo ./install_service_systemd.sh
    else
      cd /opt && f=Jackett.Binaries.LinuxARM32.tar.gz && release=$(wget -q https://github.com/Jackett/Jackett/releases/latest -O - | grep "title>Release" | cut -d " " -f 4) && sudo wget -Nc https://github.com/Jackett/Jackett/releases/download/$release/"$f" && sudo tar -xzf "$f" && sudo rm -f "$f" && cd Jackett* && sudo ./install_service_systemd.sh
  fi
}
jackett-uninstall(){
  echo "################################################################################";
  echo "# Uninstalling Jackett                                                         #";
  echo "################################################################################";
  sudo systemctl stop jackett.service
  sudo rm /etc/systemd/system/jackett.service
  sudo rm -rf ~/.config/Jackett
  sudo rm -rf /opt/Jackett
}

qbittorrent(){
  echo "################################################################################";
  echo "# Step 7 - Installing Qbittorrent                                              #";
  echo "################################################################################";
  sudo add-apt-repository -y ppa:qbittorrent-team/qbittorrent-stable
  sudo apt install qbittorrent-nox -y
  sudo touch /etc/systemd/system/qbittorrent-nox.service
  echo "[Unit]
Description=qBittorrent client
After=network.target

[Service]
ExecStart=/usr/bin/qbittorrent-nox --webui-port=$QBITTORRENTPORT
Restart=always

[Install]
WantedBy=multi-user.target" | sudo tee -a /etc/systemd/system/qbittorrent-nox.service
  sudo systemctl enable qbittorrent-nox.service
  sudo systemctl start qbittorrent-nox.service
}
qbittorrent-uninstall(){
  echo "################################################################################";
  echo "# Uninstalling Qbittorrent                                                     #";
  echo "################################################################################";
  sudo systemctl stop qbittorrent-nox.service
  sudo apt remove qbittorrent-nox -y
  sudo rm /etc/systemd/system/qbittorrent-nox.service
}

tautilli(){
  echo "################################################################################";
  echo "# Step 8 - Installing Tautilli                                                 #";
  echo "################################################################################";
  sudo apt-get install git python3.7 python3-setuptools -y
  cd /opt
  sudo git clone https://github.com/Tautulli/Tautulli.git
  sudo addgroup tautulli && sudo adduser --system --no-create-home tautulli --ingroup tautulli
  sudo chown -R tautulli:tautulli /opt/Tautulli
  sudo cp /opt/Tautulli/init-scripts/init.systemd /lib/systemd/system/tautulli.service
  sudo systemctl daemon-reload && sudo systemctl enable tautulli.service
  sudo systemctl start tautulli.service
}
tautilli-uninstall(){
  echo "################################################################################";
  echo "# Uninstalling Tautilli                                                        #";
  echo "################################################################################";
  sudo systemctl stop tautulli.service
  sudo rm /lib/systemd/system/tautulli.service
  sudo rm -rf /opt/Tautulli
  sudo deluser tautulli
}

openpyn(){
  echo "################################################################################";
  echo "# Step 9 - Installing OpenPyn                                                  #";
  echo "################################################################################";
  sudo python3 -m pip install --upgrade openpyn
}
openpyn-uninstall(){
  echo "################################################################################";
  echo "# Uninstalling Openpyn                                                         #";
  echo "################################################################################";
  sudo python3 -m pip uninstall openpyn
}

simpledash(){
  echo "################################################################################";
  echo "# Step 10 - Installing SimpleDash                                              #";
  echo "################################################################################";
  sudo apt-get install -y nginx
  sudo systemctl enable nginx.service
  sudo rm -rf /var/www/html
  sudo mkdir /var/www/html
  sudo git clone https://github.com/kutyla-philipp/simple-dash.git /var/www/html/.
  sudo truncate -s 0 /var/www/html/config.json
  echo '{
          	"title" : "Media Automation",
          	"items" : [
          		{
          			"alt" : "Plex Media Server",
          			"icon" : "fa fa-play",
          			"link" : "http://'"$IP"':32400/web/index.html#!/"
          		},
          		{
          			"alt" : "Radarr",
          			"icon" : "fa fa-film",
          			"link" : "http://'"$IP"':7878/"
          		},
          		{
          			"alt" : "Sonarr",
          			"icon" : "fa fa-tv",
          			"link" : "http://'"$IP"':8989/"
          		},
          		{
          			"alt" : "Jackett",
          			"icon" : "fa fa-project-diagram",
          			"link" : "http://'"$IP"':9117/UI/Dashboard"
          		},
          		{
          			"alt" : "Tautilli",
          			"icon" : "fa fa-chart-line",
          			"link" : "http://'"$IP"':8181/"
          		},
          		{
          			"alt" : "Qbittorrent",
          			"icon" : "fa fa-tint",
          			"link" : "http://'"$IP"':'"$QBITTORRENTPORT"'/"
          		}
          	]
          }' | sudo tee -a /var/www/html/config.json
}
simpledash-uninstall(){
  echo "################################################################################";
  echo "# Uninstalling Simpledash                                                      #";
  echo "################################################################################";
  sudo rm -rf /var/www/html
  sudo apt remove nginx -y
}

verify(){
  echo "################################################################################";
  echo "# Verifying Install                                                            #";
  echo "################################################################################";
  systemctl is-active --quiet smbd
  systemctl is-active --quiet radarr
  systemctl is-active --quiet sonarr
  systemctl is-active --quiet jackett
  systemctl is-active --quiet qbittorrent-nox
  systemctl is-active --quiet plexmediaserver
  systemctl is-active --quiet tautulli
  systemctl is-active --quiet nginx
  echo "################################################################################";
  echo "# Verified - All Services Running Correctly                                    #";
  echo "################################################################################";
}

install(){
  structure
  cifs
  plex
  radarr
  sonarr
  jackett
  qbittorrent
  tautilli
  openpyn
  simpledash
  verify
}
uninstall(){
  simpledash-uninstall
  openpyn-uninstall
  cifs-uninstall
  plex-uninstall
  qbittorrent-uninstall
  jackett-uninstall
  radarr-uninstall
  sonarr-uninstall
  tautilli-uninstall
  structure-uninstall
  sudo groupdel media
}

if [[ $1 == "install" ]];
  then
    echo "################################################################################";
    echo "# Installing                                                                   #";
    echo "################################################################################";
    while true; do
        read -p "Is this IP address ($IP) correct [y/n] ?" yn
        case $yn in
            [Yy]* ) break;;
            [Nn]* ) exit;;
            * ) echo "Please answer yes or no.";;
        esac
    done
    install;
    echo "################################################################################";
    echo "# Installation Complete Visit http://$IP                                       #";
    echo "################################################################################";

elif [[ $1 == "uninstall" ]];
  then
    echo "################################################################################";
    echo "# Uninstalling                                                                 #";
    echo "################################################################################";
    uninstall;
    echo "################################################################################";
    echo "# Uninstalled Completely                                                       #";
    echo "################################################################################";

else
  echo "$1 was not recognised"
fi