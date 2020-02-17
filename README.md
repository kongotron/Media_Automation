# Media_Automation
This is a step by step tutorial and set of instructions on the software and code snippets used in order to automate the downloading of your media collection.

- 1. Network Infrastructure
- 2. (Server) Media Library - Setup
- 3. (Server) Plex Server - Setup
- 4. (Server) Samba - Setup
- 5. (PI) Qbittorrent - Setup
- 6. (PI) Deluge - Setup
- 7. (PI) Medusa - Setup
- 8. (PI) Nord VPN - Setup
- 9. (PI) Tiny Media Manager - Setup
- 10. Automated Scripts
- 11. Use Case

## 1. Network Infrastructure.
The way my media device are setup are as follows

1. **Ubuntu Server** - (1 public facing port)
  Plex Server - Media sharing software
  Samba File Sharing - Network folder sharing (windows/linux)
  Networking - Static IP Address

2. **Raspberry Pi** - 
  Needs at least Java 1.8 and Screen Resolution: 1366 x 768 or above. 
  Meaning you need to be running a desktop environment for initial setup.
  I used the normal rasbian distro.
  Qbittorrent - Torrent Downloading Program
  Deluge  - Torrent Downloading Program
  MedusaPY - Automatic TV Media Management
  Tiny Media Manager - Movie Scraping and Renaming  Program
  Auto VPN Connection.
  Networking - Static IP Address

3. VPN Provider - (NordVPN)  

## 2. (Server) Media Library - Setup
I'm presuming that you have some media content to start with.

### Folder Structure
My folder structure that is in the following format.

 - /mnt/ 
 - /mnt/media/ - Samba shared folder. 
 - /mnt/media/downloading - Base downloading folder for your torrent programs to use.
 - /mnt/media/downloading/TV 
 - /mnt/media/downloading/TV/Complete
 - /mnt/media/downloading/TV/Downloading
 - /mnt/media/downloading/TV/TorrentFiles
 - /mnt/media/downloading/TV/TorrentFiles/Auto 
 - /mnt/media/downloading/TV/TorrentFiles/Complete
 - /mnt/media/downloading/TV/TorrentFiles/Downloading
 - /mnt/media/downloading/Movies 
 - /mnt/media/downloading/Movies/Complete
 - /mnt/media/downloading/Movies/Downloading
 - /mnt/media/downloading/Movies/TorrentFiles
 - /mnt/media/downloading/Movies/TorrentFiles/Auto
 - /mnt/media/downloading/Movies/TorrentFiles/Complete
 - /mnt/media/downloading/Movies/TorrentFiles/Downloading
 - /mnt/media/Library/ 
 - /mnt/media/Library/TV 
 - /mnt/media/Library/Movies

### Movies Naming Structure
Below is an example of the naming structure for your movies in order to help with the accuracy of the plex scraper.

My movie folder is as follows.

 - /mnt/media/Library/Movies/Batman Begins (2005)/
 - /mnt/media/Library/Movies/Batman Begins (2005)/Batman Begins (2005).avi 
 - /mnt/media/Library/Movies/Batman Begins (2005)/Batman Begins (2005).srt 
 - /mnt/media/Library/Movies/Baby Driver (2017)/
 - /mnt/media/Library/Movies/Baby Driver (2017)/Baby Driver (2017).mkv
 - /mnt/media/Library/Movies/Baby Driver (2017)/Baby Driver (2017).srt

To rename files and folders automatically we will use a movie scraping program. for this we will be using "**Tiny Media Manager**"

### TV Naming Structure
Below is an example of the naming structure for your TV shows in order to help with the accuracy of the plex scraper.

My TV folder is as follows.

 - /mnt/media/Library/TV/The Office (2005)
 - /mnt/media/Library/TV/The Office (2005)/Season 1
 - /mnt/media/Library/TV/The Office (2005)/Season 1/The Office (2005) S01E02 Diversity Day.avi
 - /mnt/media/Library/TV/The Office (2005)/Season 1/The Office (2005) S01E03 Health Care.avi
 - /mnt/media/Library/TV/The Wire (2002)
 - /mnt/media/Library/TV/The Wire (2002)/Season 3
 - /mnt/media/Library/TV/The Wire (2002)/Season 3/The Wire (2002) S03E04 Dead Soldiers.avi
 - /mnt/media/Library/TV/The Wire (2002)/Season 3/The Wire (2002) S03E05 Hamsterdam.avi  

 Any future downloads will be automatically renamed by our download automating program "**Medusa**"

## 3. (Server) Plex Server - Setup 
There are lots of settings and features to plex that i wont go into here but feel free to tinker with it yourself.

### Account Setup
Register for a free PLEX account here 
- https://www.plex.tv/


### Installation
You can either download the dpkg file from their website.
or use their unadvertised PPA for Plex server 
- [PLEX PPA](https://support.plex.tv/articles/235974187-enable-repository-updating-for-supported-linux-server-distributions/)

Setup the libraries in PLEX and you can start streaming inside your network straight away.

### Setup External PLEX Access
For this you will need 
- A internal static IP. 
[Static IP Instructions Ubuntu 18.04](https://linuxconfig.org/how-to-configure-static-ip-address-on-ubuntu-18-04-bionic-beaver-linux)
- To open a port in your firewall [your port number].
[Open Port Instructions Ubuntu 18.04](https://linuxconfig.org/how-to-open-allow-incoming-firewall-port-on-ubuntu-18-04-bionic-beaver-linux)
- An open port on your router  [your port number].
[How to forward a port on your router](https://portforward.com/router.htm)
PLEX will try to use the 32400 port by default
Go into the PLEX server remote access settings, tick the box next to manual port, enter [your port number], 
click apply you should be able to connect now. 


## 4. (Server) Samba - Setup
By sharing your media folders using samba, you make them accessible across your network for all devices and OS's like your "Auto Downloading Pi" to access.
- [How to setup Samba sharing Ubuntu 18.04](https://help.ubuntu.com/community/How%20to%20Create%20a%20Network%20Share%20Via%20Samba%20Via%20CLI%20%28Command-line%20interface/Linux%20Terminal%29%20-%20Uncomplicated,%20Simple%20and%20Brief%20Way)

Using the steps above you will need to share the following folder in their entirity

 - Media library folder  
 - Torrent Downloading folder

Your Ubuntu server is nearly completely setup.


### (PI) Mount Samba Share

On your "Auto Downloading Pi" you will need to mount your newly created samba shares
 - [How to mount a samba share](https://askubuntu.com/questions/157128/proper-fstab-entry-to-mount-a-samba-share-on-boot)
You may need to reboot a few times just to make sure it auto mounts the folders correctly

 - Example entry in fstab

    //192.168.1.120/media /mnt/media cifs auto,user,rw,uid=mhowlin,iocharset=utf8,file_mode=0777,dir_mode=0777,credentials=/home/mhowlin/.secret/smb 0 0
    
 - I store my authentication details in a hidden text file called smb with the following structure
    username=sambausername
    password=sambapassword
    
## 5. (PI) Qbittorrent - Setup
You will need to setup qbittorrent as a headless service that you can interact with it using their web interface

 - You can set that up using the following instructions
[how to install qbittorrent as daemon with web interface](https://github.com/qbittorrent/qBittorrent/wiki/Setting-up-qBittorrent-on-Ubuntu-server-as-daemon-with-Web-interface-(15.04-and-newer))

### Qbittorrent Settings
Save files to location: `your mounted folder for completed tv shows`
Keep incomplete torrents in: `your mounted folder for incomplete tv shows`
Automatically add torrents from:  `your mounted folder for automatically added tv torrent files`
Copy .torrent files to:  `your mounted folder for imcomplete tv torrent files`
Copy .torrent files for finished downloads to: `your mounted folder for completed tv torrent files`


## 6. (PI) Deluge - Setup
You will need to setup deluge as a headless service that you can interact with it using their web interface.

 - You can set that up using the following instructions
[Install headless deluge client with web ui](https://www.smarthomebeginner.com/install-deluge-torrent-with-webui-on-ubuntu-1004/)

### Deluge Settings
Enable a plugin named "Execute" 
Add an event Torrent Complete, and the path to a script you would like to run once it downloads
For this you can use the scrapeMovies script down at the bottom of the page.

Download to: `your mounted folder of your ongoing movie downloads`
Move completed to: `your mounted folder of your completed movie downloads`
Copy of .torrent files to: `your mounted folder of your ongoing movie torrent files`
Autoadd .torrent files from: `your mounted folder of your completed movie torrent files`

## 7. (PI) Medusa - Setup
Medusa is a tv show download manager and renamer. It can automatically scan for new episodes and download them this can integrate with your qbittorrent and plex media server

 - Installation instructions can be found here.
 [How to install medusa on debian](https://github.com/pymedusa/Medusa/wiki/Medusa-installation-Debian-Ubuntu)

You will need to add your tv shows into medusa. Especially making sure to include your library directory for tv shows.

### Medusa Settings
There are a lot of settings in here that you can customise to make sure they suit your personal searching needs.
I will go through a couple of key settings i have in place on my instance.

#### Search Settings >> Torrent Settings

 - Search torrents: On 
 - Send .torrent files to: qBittorrent 
 - URL:  http://localhost:8080/ 
 - qBittorrent username: admin 
 - qBittorrent password: password you set

#### Search Providers

 - Enable each of the providers you want to search with.

#### Post Processing

Scheduled Postprocessor: On
Post Processing Dir: `your mounted folder for completed tv show downloads`
Processing Method: Move
Auto Post-Processing Frequency: 10 mins
Rename Episodes: On
Create Missing Show Directories: On
Delete Associated Files: On
#### Episode Naming
Name Pattern: Custom

    Season %0S/%SN - S%0SE%0E - %EN

Multi Episode Style: Extend (Limited, E-prefixed)

## 8. (PI) Nord VPN - Setup
In order to make sure that the raspberry pi stays connected to a nord vpn server I use a program called openpyn

Installation instructions can be found here
[OpenPyn Github](https://github.com/jotyGill/openpyn-nordvpn)

You can install this program and we will use it in the scripts below.

## 9. (PI) Tiny Media Manager - Setup
For tiny media manager you will need at least java 8 installed. You can install that using 

    sudo apt install default-jdk

I download the latest release of tmm from here
[TMM Releases](http://release.tinymediamanager.org/)

I downloaded and extracted the release into a folder 
Run the tinymediamanager.sh 
There are a lot of settings that i wont go into here as they are a matter of personal preference on how much you would like if you use plex / kodi etc. I will just include some key settings that i use

### Tiny Media Manager Settings
**Settings>>Movies>>Data Sources**
Add your mounted folder for finished movie downloads
**Settings>>Movies>>Renamer**
File Name: \${title} (\${year})
Folder Name: \${title} (\${year})

## 10. Automated Scripts
I set a crontab to run every night at midnight. 

### Midnight Script
midnight.sh   

	#!/bin/bash
    echo "--Stoping Medusa--"
	sudo service medusa stop
	echo "--Stopping Qbittorrent--"
	sudo service qbittorrent stop
	echo "--Stopping Deluge--"
	sudo service deluged stop
	sudo service deluge-web restart
	echo "--Killing Connection to Nord VPN--"
	sudo openpyn -k
	echo "--Mounting Network Drives--"
	sudo mount -a
	echo "--Starting Qbittorrent--"
	sudo service qbittorrent start
	echo "--Starting Medusa--"
	sudo service medusa start
	echo "--Starting Deluge--"
	sudo service deluged start
	sudo service deluge-web start
	echo "--Reconnecting to Nord VPN--"
	sudo openpyn uk -t 10 --p2p -d
	./scrapeMovies.sh

I use this script as part of the execute plugin in deluge. It gets run everytime it completes a movie download
scrapeMovies.sh

    #!/usr/bin/env bash

	cd ~/tmm
	echo "--Updating TMM--"
	./tinyMediaManagerUpdater.sh
	sleep 5
	echo "--Closing TMM--"
	killall java
	sleep 5
	echo "--Scraping Movies--"
	./tinyMediaManagerCMD.sh -updateMovies -scrapeAll -rename
	sleep 5
	echo "--Deleting Duplicate from Destination--"
	cd "mountedFolderOfCompleteMovieDownloads/"
	for d in */ ; do
	    rm -R "mountedFolderOfMovieLibrary/$d"
	done
	sleep 5
	echo "--Moving Files to Destination--"
	mv mountedFolderOfCompleteMovieDownloads/* mountedFolderOfMovieLibrary/

## 11. Use Case
To download new TV shows. Navigate to your Medusa home page and add the show.
This should start searching and downloading the episodes automatically

When you are looking for a new movie. locate the torrent file and place it in the samba shared folder

 - /mnt/media/downloading/Movies/TorrentFiles/Auto

This will now download and automatically rename and move the movies to your library.

## TODO
- Write a script to do all the setup
