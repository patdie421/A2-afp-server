The goal of this project is to create a server capable of "interconnecting" old Apple II computers with the modern world.  
  
Here are some planned features:  
* AFP file sharing over ethertalk (conversion to localtalk must be done with MacOS "LocalTalk Bridge 2.1" or hardware solution like "AsanteTalk ethernet-serial LocalTalk bridge" or "Farallon EtherMac iPrint")
* SMB file sharing for SMB FST for GS/OS (https://github.com/sheumann/smbfst/tree/main) + Marinetti (Uthernet II) or modern computers
* Appletalk Laserwriter emulation for printing to PDF file (cups + cups-pdf)
* Direct "raw" printer (JetDirect or AppSocket printing) for TreeHugger (https://krue.net/treehugger/) to PDF.
* Mail server for Apple IIgs (https://github.com/bobbimanners/emailler/blob/master/README-gmail-gateway.md)
* http proxy for HTML conversion
The server will be installed on Raspberry OS

# OS configuration
## SDCARD creation
* install Rasberry OS lite version (no desktop)
* create image disk
* Enable SSH connection
## OS preparation
* Boot Raspberry with SDCARD
* Update OS
* Update settings
(check avahi-daemon and install if not present : sudo apt-get install avahi-daemon)
# File sharing
## AFP file server
* install netatalk
```
$ sudo apt-get install netatalk
```
## SMB file server
* install samba
```
$ sudo apt-get install samba samba-vfs-modules
```
Must be added in smb.conf file
```
[global]
vfs objects = catia fruit streams_xattr
fruit:encoding = native
```
# Printers
## install cups and cups-pdf

## redirect 9100 to PDF queue

The socket unit listens on port 9100 and hands off the incoming connection to the service.  
1. Create a new file named `/etc/systemd/system/jetdirect-redirect.socket` :
```
[Unit]
Description=Listen on port 9100 for JetDirect raw print stream

[Socket]
ListenStream=9100
Accept=yes

[Install]
WantedBy=sockets.target
```
2. Create the systemd Service  
Because with an Accept=yes is used in the socket, systemd will look for an instantiated service file named@ symbol. This allows it to handle multiple concurrent connections.  
Create a new file named `/etc/systemd/system/jetdirect-redirect@.service` :
```
[Unit]
Description=Redirect JetDirect port 9100 stream to CUPS lp
Documentation=man:lp(1)

[Service]
Type=simple
ExecStart=/usr/bin/lp -d YOUR_CUPS_PRINTER_NAME -o raw
StandardInput=socket
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```
Important: Replace YOUR_CUPS_PRINTER_NAME with the exact name of your printer queue as it appears in CUPS (run lpstat -v to find it). The -o raw flag ensures CUPS passes the incoming data directly to the printer without filtering, which is typical for port 9100 printing. If you want CUPS to filter/render the incoming format, remove -o raw.  

3. Reload and Enable the Services
Run the following commands to reload the systemd manager configuration, enable the socket, and start it up:
```
# Reload systemd to recognize the new files
sudo systemctl daemon-reload
# Enable and start the socket (do not enable the @.service file)
sudo systemctl enable jetdirect-redirect.socket
sudo systemctl start jetdirect-redirect.socket
```
4. Verify the Setup  
You can check if the socket is actively listening on port 9100 with this command:
```
sudo ss -tlnp | grep 9100
```
To test sending a print job from another machine, you can pipe a file directly using nc (netcat):  
```
nc -N RASPBERRY_PI_IP 9100 < testfile.ps
```
