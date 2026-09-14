The goal of this project is to create a server capable of "interconnecting" old Apple II computers with the modern world.  
  
Here are some planned features:  
* AFP file sharing over ethertalk (conversion to localtalk must be done with MacOS "LocalTalk Bridge 2.1" or hardware solution like "AsanteTalk ethernet-serial LocalTalk bridge" or "Farallon EtherMac iPrint") [done]
* SMB file sharing for SMB FST for GS/OS (https://github.com/sheumann/smbfst/tree/main) + Marinetti (Uthernet II) or modern computers [done].
* Appletalk Laserwriter emulation for printing to PDF file (cups + cups-pdf) [done].
* Direct "raw" printer (JetDirect or AppSocket printing) for TreeHugger (https://krue.net/treehugger/) to PDF (gpcl6) [done].
* Mail server for Apple IIgs SAM2 mail client (https://github.com/bobbimanners/emailler/blob/master/README-gmail-gateway.md) [done].
* Web proxy for HTTPS/HTTP conversion and HTML simplification (https://github.com/rdmark/macproxy_classic) [to do].

The server will be installed on Raspberry OS

# OS configuration
## SDCARD creation
* install Rasberry OS lite version (no desktop)
* Mandatory configuration before burning the image on SDCard
1. WIFI Configuration
2. Enable SSH connection
* write image disk on SDCard
## OS preparation
* Boot Raspberry with SDCard
* Update OS
```
sudo apt-get update
sudo apt-get upgrade
```
* Update settings
(check avahi-daemon is up and running or install it if not present : sudo apt-get install avahi-daemon)
## File system preparation
create shared directories
```
sudo mkdir -p /data/shares/data
sudo mkdir -p /data/shares/install
sudo mkdir -p /data/prints/PDF
sudo chown nobody:nogroup /data/shares/data /data/shares/install /data/prints/PDF
sudo chmod 777 /data/shares/data /data/shares/install /data/prints/PDF
sudo chmod g+s /data/shares/data /data/shares/install /data/prints/PDF
sudo chmod u+s /data/shares/data /data/shares/install /data/prints/PDF
sudo touch /data/shares/data/.protected ; sudo chmod 000 /data/shares/data/.protected
sudo touch /data/shares/install/.protected ; sudo chmod 000 /data/shares/install/.protected
sudo touch /data/prints/PDF/.protected ; sudo chmod 000 /data/prints/PDF/.protected
```
# File sharing
## AFP file server
install netatalk
```
$ sudo apt-get install netatalk
```
Add server name in global
```
[Global]
hostname = vandee2.afp
```
Add shared directories to `afp.conf`:
```
[install]
path = /data/shares/install
volume name = Install
[data]
path = /data/shares/data
volume name = Data
[pdf]
path = /data/prints/PDF
volume name = PDF
```
Restart netatalk
```
sudo systemctl restart netatalk
```
## SMB file server
Install samba:
```
sudo apt-get install samba samba-vfs-modules
```
Add to `smb.conf` file [global] section :
```
[global]
vfs objects = catia fruit streams_xattr
fruit:encoding = native
```
Add shares to end of `smb.conf` file:
```
[install]
   path = /data/shares/install/
   comment = install
   read only = no
   public = yes

[data]
   path = /data/shares/data/
   comment = data
   read only = no
   public = yes

[pdf]
   path = /data/prints/PDF/
   read only = no
   public = yes
```
Restart smbd
```
sudo systemctl restart smbd
```
Create smb password for users
```
sudo smbpasswd -a <username>
```
# Printers
## cups and cups-pdf
Install packages
```
sudo apt-get install cups printer-driver-cups-pdf
```
add or modify lines in `/etc/cups/cupsd.conf`
```
#Listen localhost:631
Port 631
Browsing On
```
add or modify lines in `/etc/cups/cups-pdf.conf`
```
Out /data/prints/PDF
Label 1
UserUMask 0000
Grp lpadmin
DecodeHexStrings 1
```
add or modify lines in `/etc/cups/printers.conf`
```
<DefaultPrinter LaserWriter-PDF>
Info LaserWriter-PDF
Shared Yes
```
Restart cups and netatalk to resync cups printers.
```
sudo systemctl restart cups
sudo systemctl restart Netatalk
```

## build gpcl6
Download source: https://github.com/ArtifexSoftware/ghostpdl-downloads/releases
Get last release of `ghostpdl` (https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/download/gs10080/ghostpdl-10.08.0.tar.gz)
```
tar xvzf ghostpdl-10.08.0.tar.gz
cd ghostpdl-10.08.0
./configure
make
sudo make install
```
## pclprint script
Add this script to `/etc` direction as `pclprint.sh`
```
DATE=$(date +"%Y%m%d-%H%M%S")
FILENAME=/data/prints/PDF/"jetdirect-$DATE".pdf

/usr/local/bin/gpcl6 -dNOSAFE -dNOPAUSE -LPCL  -sDEVICE=pdfwrite -sOutputFile=$FILENAME -

chmod 666 $FILENAME
chown nobody:nogroup $FILENAME
```
## redirect 9100 to script

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
Because with an `Accept=yes` is used in the socket, systemd will look for an instantiated service file `named@` symbol. This allows it to handle multiple concurrent connections.  
Create a new file named `/etc/systemd/system/jetdirect-redirect@.service` :
```
[Unit]
Description=Redirect JetDirect port 9100 stream to CUPS lp
Documentation=man:lp(1)

[Service]
Type=simple
ExecStart=/usr/bin/bash /etc/pclprint.sh
StandardInput=socket
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```
Important: The `-o raw` flag ensures CUPS passes the incoming data directly to the printer without filtering, which is typical for port 9100 printing.  

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
nc -N RASPBERRY_PI_IP 9100 < postscripttestfile.ps
```
# Mail server
## postfix
1. Follow this guide: https://github.com/bobbimanners/emailler/blob/master/README-gmail-gateway.md  
2. After step https://github.com/bobbimanners/emailler/blob/master/README-gmail-gateway.md#restart-postfix create `/etc/aliases`:
```
<<username>>: <<name>>@gmail.com
```
3. generate `/etc/aliases.db`:
```
postalias /etc/aliases
```
4. Create the directory `/etc/postfix/sasl`.
5. Create the file `/etc/postfix/sasl/sasl_passwd` as follows:
```
[smtp.gmail.com]:587 <<name>>@gmail.com:xxxx xxxx xxxx xxxx
```
where `<<name>>` is your Gmail account name and xxxx xxxx xxxx xxxx is the App Password Google gave you.  
To get the google app app password: https://myaccount.google.com/apppasswords  
6. to build the hash file `sasl_passwd.db`, run:
```
sudo postmap /etc/postfix/sasl/sasl_passwd
```
7. Now restart postfix
```
sudo systemctl restart postfix
```
## dovecot
1. Follow: https://github.com/bobbimanners/emailler/blob/master/README-gmail-gateway.md#dovecot  
2. in file `/etc/dovecot/conf.d/10-auth.conf` add or update `auth_allow_cleartext`:
```
auth_allow_cleartext = yes
```
3. restart dovecot
```
sudo systemctl start dovecot
```
## fetchmail
follow: https://github.com/bobbimanners/emailler/blob/master/README-gmail-gateway.md#fetchmail

