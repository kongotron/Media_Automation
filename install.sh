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
#set -o allexport
#source "config.env"
#set +o allexport

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
  echo "Step 1 - Creating Folder Structure and Updating";
  sudo mkdir -p $DATAFOLDER
  sudo mkdir -p "$DATAFOLDER/torrents/downloading"
  sudo mkdir -p "$DATAFOLDER/torrents/complete"
  sudo mkdir -p "$DATAFOLDER/video/movies"
  sudo mkdir -p "$DATAFOLDER/video/tv"
  sudo apt update
  sudo apt-get install -y curl wget zip unzip git
  sudo ufw allow 80
  sudo ufw allow 32400
  sudo ufw allow 7878
  sudo ufw allow 8989
  sudo ufw allow 9117
  sudo ufw allow 8181
  sudo ufw allow 8080
}

cifs(){
  echo "Step 2 - Cifs Utils and Samba"
  sudo apt install cifs-utils -y
  sudo apt install samba -y
  echo "[$SAMBANAME]" | sudo tee -a /etc/samba/smb.conf
  echo "path = $DATAFOLDER" | sudo tee -a /etc/samba/smb.conf
  echo "create mask = 0777" | sudo tee -a /etc/samba/smb.conf
  echo "directory mask = 0777" | sudo tee -a /etc/samba/smb.conf
  echo "browseable = yes" | sudo tee -a /etc/samba/smb.conf
  echo "writeable = yes" | sudo tee -a /etc/samba/smb.conf
  echo "public = yes" | sudo tee -a /etc/samba/smb.conf
  echo "only guest = no" | sudo tee -a /etc/samba/smb.conf
  echo "read only = no" | sudo tee -a /etc/samba/smb.conf
}

plex(){
  echo "Step 3 - Installing Plex Media Server"
  curl https://downloads.plex.tv/plex-keys/PlexSign.key | sudo apt-key add -
  echo deb https://downloads.plex.tv/repo/deb public main | sudo tee /etc/apt/sources.list.d/plexmediaserver.list
  sudo apt update
  sudo apt install plexmediaserver -y
}

radarr(){
  echo "Step 4 - Installing Radarr"
  sudo addgroup media && sudo adduser --system --no-create-home radarr --ingroup media
  sudo apt install curl sqlite3 -y
  wget --content-disposition 'http://radarr.servarr.com/v1/update/master/updatefile?os=linux&runtime=netcore&arch=x64'
  tar -xvzf Radarr*.linux*.tar.gz
  sudo mv Radarr /opt/
  sudo chown radarr:media -R /opt/Radarr

  sudo touch /etc/systemd/system/radarr.service
  echo "[Unit]" | sudo tee -a /etc/systemd/system/radarr.service
  echo "Description=Radarr Daemon" | sudo tee -a /etc/systemd/system/radarr.service
  echo "After=syslog.target network.target" | sudo tee -a /etc/systemd/system/radarr.service
  echo "[Service]" | sudo tee -a /etc/systemd/system/radarr.service
  echo "User=radarr" | sudo tee -a /etc/systemd/system/radarr.service
  echo "Group=media" | sudo tee -a /etc/systemd/system/radarr.service
  echo "Type=simple" | sudo tee -a /etc/systemd/system/radarr.service
  echo "" | sudo tee -a /etc/systemd/system/radarr.service
  echo "ExecStart=/opt/Radarr/Radarr -nobrowser" | sudo tee -a /etc/systemd/system/radarr.service
  echo "TimeoutStopSec=20" | sudo tee -a /etc/systemd/system/radarr.service
  echo "KillMode=process" | sudo tee -a /etc/systemd/system/radarr.service
  echo "Restart=on-failure" | sudo tee -a /etc/systemd/system/radarr.service
  echo "[Install]" | sudo tee -a /etc/systemd/system/radarr.service
  echo "WantedBy=multi-user.target" | sudo tee -a /etc/systemd/system/radarr.service

  sudo systemctl -q daemon-reload
  sudo systemctl enable --now -q radarr
  rm Radarr*.linux*.tar.gz
}

sonarr(){
  echo "Step 5 - Installing Sonarr"
  sudo apt install gnupg ca-certificates
  sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
  echo "deb https://download.mono-project.com/repo/ubuntu stable-focal main" | sudo tee /etc/apt/sources.list.d/mono-official-stable.list
  wget https://mediaarea.net/repo/deb/repo-mediaarea_1.0-19_all.deb && sudo dpkg -i repo-mediaarea_1.0-19_all.deb
  sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 2009837CBFFD68F45BC180471F4F90DE2A9B4BF8
  echo "deb https://apt.sonarr.tv/ubuntu focal main" | sudo tee /etc/apt/sources.list.d/sonarr.list
  sudo apt update
  sudo apt install sonarr -y
  sudo cert-sync /etc/ssl/certs/ca-certificates.crt
}


jackett(){
  echo "Step 6 - Installing Jackett"
  cd /opt && f=Jackett.Binaries.LinuxAMDx64.tar.gz && release=$(wget -q https://github.com/Jackett/Jackett/releases/latest -O - | grep "title>Release" | cut -d " " -f 4) && sudo wget -Nc https://github.com/Jackett/Jackett/releases/download/$release/"$f" && sudo tar -xzf "$f" && sudo rm -f "$f" && cd Jackett* && sudo ./install_service_systemd.sh
}

qbittorrent(){
  echo "Step 7 - Installing Qbittorrent"
  sudo add-apt-repository -y ppa:qbittorrent-team/qbittorrent-stable
  sudo apt install qbittorrent-nox -y
  sudo touch /etc/systemd/system/qbittorrent-nox.service
  echo "[Unit]" | sudo tee -a /etc/systemd/system/qbittorrent-nox.service
  echo "Description=qBittorrent client" | sudo tee -a /etc/systemd/system/qbittorrent-nox.service
  echo "After=network.target" | sudo tee -a /etc/systemd/system/qbittorrent-nox.service
  echo "" | sudo tee -a /etc/systemd/system/qbittorrent-nox.service
  echo "[Service]" | sudo tee -a /etc/systemd/system/qbittorrent-nox.service
  echo "ExecStart=/usr/bin/qbittorrent-nox --webui-port=$QBITTORRENTPORT" | sudo tee -a /etc/systemd/system/qbittorrent-nox.service
  echo "Restart=always" | sudo tee -a /etc/systemd/system/qbittorrent-nox.service
  echo "" | sudo tee -a /etc/systemd/system/qbittorrent-nox.service
  echo "[Install]" | sudo tee -a /etc/systemd/system/qbittorrent-nox.service
  echo "WantedBy=multi-user.target" | sudo tee -a /etc/systemd/system/qbittorrent-nox.service
  sudo systemctl enable qbittorrent-nox
}

tautilli(){
  echo "Step 8 - Installing Tautilli"
  sudo apt-get install git python3.7 python3-setuptools -y
  cd /opt
  sudo git clone https://github.com/Tautulli/Tautulli.git
  sudo addgroup tautulli && sudo adduser --system --no-create-home tautulli --ingroup tautulli
  sudo chown -R tautulli:tautulli /opt/Tautulli
  sudo cp /opt/Tautulli/init-scripts/init.systemd /lib/systemd/system/tautulli.service
  sudo systemctl daemon-reload && sudo systemctl enable tautulli.service
  sudo systemctl start tautulli.service
}

openpyn(){
  echo "Step 9 - Installing OpenPyn"
  sudo python3 -m pip install --upgrade openpyn
  git clone https://github.com/jotyGill/openpyn-nordvpn.git
  cd openpyn-nordvpn/
  sudo python3 -m pip install --upgrade .
}

simpledash(){
  echo "Step 10 - Installing SimpleDash"
  sudo apt-get install -y nginx
  sudo systemctl enable nginx
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
          			"link" : "http://'"$IP"':8080/"
          		}
          	]
          }' | sudo tee -a /var/www/html/config.json
}

#structure
#cifs
#plex
#qbittorrent
#jackett
#radarr
#sonarr
#tautilli
#openpyn
#simpledash

echo "installation complete visit http://$IP";
