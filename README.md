The goal of this project is to create a server capable of "interconnecting" old Apple II computers with the modern world.  
  
Here are some planned features:  
* AFP file sharing over ethertalk (conversion to localtalk must be done with MacOS "LocalTalk Bridge 2.1" or hardware solution like "AsanteTalk ethernet-serial LocalTalk bridge" or "Farallon EtherMac iPrint") [done]
* SMB file sharing for SMB FST for GS/OS (https://github.com/sheumann/smbfst/tree/main) + Marinetti (Uthernet II) or modern computers [done].
* Appletalk Laserwriter emulation for printing to PDF file (cups + cups-pdf) [done].
* Direct "raw" printer (JetDirect or AppSocket printing) for TreeHugger (https://krue.net/treehugger/) to PDF [done].
* Mail server for Apple IIgs SAM2 mail client (https://github.com/bobbimanners/emailler/blob/master/README-gmail-gateway.md) [to do].
* Web proxy for HTTPS/HTTP conversion and HTML simplification (https://github.com/rdmark/macproxy_classic) [to do].

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
(check avahi-daemon is up and running or install it if not present : sudo apt-get install avahi-daemon)
## File system preparation
* create shared directories
```
mkdir -p /data/shares/data
mkdir -p /data/shares/install
mkdir -p /data/prints/PDF
touch /data/shares/data/.protected ; chmod 000 /data/shares/data/.protected
touch /data/shares/install/.protected ; chmod 000 /data/shares/install/.protected
touch /data/prints/PDF/.protected ; chmod 000 /data/prints/PDF/.protected
chown nobody:nogroup /data/shares/data /data/shares/install /data/prints/PDF
chmod 777 /data/shares/data /data/shares/install /data/prints/PDF
chmod g+s /data/shares/data /data/shares/install /data/prints/PDF
chmod u+s /data/shares/data /data/shares/install /data/prints/PDF
```
# File sharing
## AFP file server
* install netatalk
```
$ sudo apt-get install netatalk
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

## SMB file server
* install samba
```
$ sudo apt-get install samba samba-vfs-modules
```
Add to `smb.conf` file :
```
[global]
vfs objects = catia fruit streams_xattr
fruit:encoding = native
```
# Printers
## cups and cups-pdf
```
sudo apt-get install cups cups-pdf
# create PDF queue
sudo lpadmin -p cups-pdf -v cups-pdf:/ -E -P /usr/share/ppd/cups-pdf/CUPS-PDF.ppd
```
after the queue creation, update `/etc/cups/cups-pdf.conf` with this minimum contents:
```
Out /data/printings/PDF
Label 1
UserUMask 0000
Grp lpadmin
DecodeHexStrings 1
```
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
Because with an `Accept=yes` is used in the socket, systemd will look for an instantiated service file `named@` symbol. This allows it to handle multiple concurrent connections.  
Create a new file named `/etc/systemd/system/jetdirect-redirect@.service` :
```
[Unit]
Description=Redirect JetDirect port 9100 stream to CUPS lp
Documentation=man:lp(1)

[Service]
Type=simple
ExecStart=/usr/bin/lp -d cups-pdf -o raw
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
