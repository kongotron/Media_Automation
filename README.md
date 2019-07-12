# Media_Automation
Instrucctions and code snippets in order to automate your media collection.

Network Infrastructure.
The way my media device are setup are as follows

1. Ubuntu Server - (1 public facing port)
  Plex Server - Media sharing software
  Samba File Sharing - Network folder sharing (windows/linux)

2. Raspberry Pi
  Qbittorrent - Torrent Downloading Program
  Deluge  - Torrent Downloading Program
  MedusaPY - Automatic TV Media Management

3. VPN Provider - (NordVPN)  



================ Media Library - Setup ================
I'm presuming that you have some content to start with.
The following is the best way to name and setup your media content

Movies---
Have your folder for movies and inside that is all your movies in folders of the movie name and year
This helps the accuracy of what data Plex gathers.
My movie folder is as follows
/mnt
/mnt/Movies
/mnt/Movies/Batman Begins (2005)
/mnt/Movies/Batman Begins (2005)/Batman Begins (2005).avi
/mnt/Movies/Batman Begins (2005)/Batman Begins (2005).srt
/mnt/Movies/Batman Begins (2005)
/mnt/Movies/Baby Driver (2017)/Baby Driver (2017).mkv
/mnt/Movies/Baby Driver (2017)/Baby Driver (2017).srt

TV---
Have your folder for TV shows and inside that is all your Series inside that are the season folder and inside that the episodes are name in a specific way.
This helps the accuracy of what data Plex gathers.
My tv folder is as follows
/mnt
/mnt/TV
/mnt/TV/The Office (2005)
/mnt/TV/The Office (2005)/Season 1
/mnt/TV/The Office (2005)/Season 1/The Office (2005) S01E02 Diversity Day.avi
/mnt/TV/The Office (2005)/Season 1/The Office (2005) S01E03 Health Care.avi
/mnt/TV/The Wire (2002)
/mnt/TV/The Wire (2002)/Season 3
/mnt/TV/The Wire (2002)/Season 3/The Wire (2002) S03E04 Dead Soldiers.avi
/mnt/TV/The Wire (2002)/Season 3/The Wire (2002) S03E05 Hamsterdam.avi  

================ Plex Server - Setup ================

Account Setup---
Register for a free plex account here 
- https://www.plex.tv/


Installation---
You can either download the dpkg file from their website.
or use their unadvertised PPA for PlexServer 
- https://support.plex.tv/articles/235974187-enable-repository-updating-for-supported-linux-server-distributions/
setup the libraries in plex and you can start streaming inside your network straight away.

Setup External Plex Access---
For this you will need 
-an internal static IP. 
-https://linuxconfig.org/how-to-configure-static-ip-address-on-ubuntu-18-04-bionic-beaver-linux
-to open a port in your firewall.
-https://linuxconfig.org/how-to-open-allow-incoming-firewall-port-on-ubuntu-18-04-bionic-beaver-linux
-an open port on your router.
-https://portforward.com/router.htm
Plex will try to use the 32400 port by default
Go into the Plex server remote access settings, tick the box next to manual port, enter 32400, 
click apply you should be able to connect now. 


================ Samba - Setup ================

by sharing your media folders using samba you make them accessible accross your network for tool like your "Auto Downloader" to access.
-https://help.ubuntu.com/community/How%20to%20Create%20a%20Network%20Share%20Via%20Samba%20Via%20CLI%20%28Command-line%20interface/Linux%20Terminal%29%20-%20Uncomplicated,%20Simple%20and%20Brief%20Way!

Your server is nearly completely setup.


================ Mount Samba Share - Setup ================

On your auto downloader you will need to mount your newly created samba shares
-https://askubuntu.com/questions/157128/proper-fstab-entry-to-mount-a-samba-share-on-boot

================ Qbittorrent - Setup ================
================ Deluge - Setup ================
================ Medusa - Setup ================
================ Nord VPN - Setup ================
================ Tiny Media Manager - Setup ================
