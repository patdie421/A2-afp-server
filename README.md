The goal of this project is to create a server capable of "interconnecting" old Apple II computers with the modern world.  
  
Here are some planned features:  
* AFP file sharing
* SMB file sharing for SMB FST for GS/OS + Marinetti (Uthernet II)
* Appletalk Laserwriter emulation (print to PDF file)
* Mail server for Apple IIgs (https://github.com/bobbimanners/emailler/blob/master/README-gmail-gateway.md)
* http proxy for HTML conversion
  
Install Rasberry OS lite version (no desktop)
   create image disk
      Enable SSH connection

Boot Raspberry with SDCARD

Update OS
Update settings

(check avahi-daemon and install if not present : sudo apt-get install avahi-daemon)

add netatalk

$ sudo apt-get install netatalk

add samba

$ sudo apt-get install samba


