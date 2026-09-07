The goal of this project is to create a server capable of "interconnecting" old Apple II computers with the modern world.  
  
Here are some planned features:  
* AFP file sharing over ethertalk (conversion to localtalk must be done with "LocalTalk Bridge 2.1" or hardware solution like "AsanteTalk ethernet-serial LocalTalk bridge")
* SMB file sharing for SMB FST for GS/OS + Marinetti (Uthernet II)
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
$ sudo apt-get install samba
```
smb.conf file



