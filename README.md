The goal of this project is to create a server capable of "interconnecting" old Apple II computers with the modern world.  
  
Here are some planned features:  
* AFP file sharing over ethertalk (conversion to localtalk must be done with MacOS "LocalTalk Bridge 2.1" or hardware solution like "AsanteTalk ethernet-serial LocalTalk bridge" or "Farallon EtherMac iPrint")
* SMB file sharing for SMB FST for GS/OS + Marinetti (Uthernet II) or modern computers
* Appletalk Laserwriter emulation (print to PDF file)
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
## AFP file server
* install netatalk
```
$ sudo apt-get install netatalk
```
afp.conf file
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
* install cups and cups-pdf

* redirect 9100 to queue

redirect to lp (port 515)
```
sudo iptables -t nat -A PREROUTING -p tcp --dport 9100 -j REDIRECT --to-ports 515
```

redirect to lp queue  
Update Services File  
Add a custom service name to /etc/services:
```
jetdirect 9100/tcp        # HP JetDirect/AppSocket
```

Create the xinetd Configuration  
Create a file named /etc/xinetd.d/jetdirect with the following contents, replacing CUPS_PRINTER_NAME with your actual CUPS queue name:text
```
service jetdirect {
    socket_type = stream
    protocol    = tcp
    wait        = no
    user        = lp
    server      = /usr/bin/lp
    server_args = -d CUPS_PRINTER_NAME -o raw
    disable     = no
}
```
Utilisez le code avec précaution.  
Restart Services  
Restart xinetd and cups to apply the changes:
```
$ sudo systemctl restart xinetd
$ sudo systemctl restart cups
```



