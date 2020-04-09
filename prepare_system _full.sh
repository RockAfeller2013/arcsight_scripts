#!/bin/bash
#
# This script should be run on a machine prior to ESM installation
# to prepare the system with all the settings that are otherwise done manually.
# Run as root

#---------------------------------------------------------------------------------------------------
Download CentOS 7.6 Minimal from http://vault.centos.org/7.6.1810/isos/x86_64/CentOS-7-x86_64-Minimal-1810.iso
CentOS Partitions. 
Create Partisions;
/opt > 100 GB
/tmp > 10 GB
#---------------------------------------------------------------------------------------------------
echo "Install components... unzip, tar, tmux, tzdata"
sudo yum install -y tzdata
sudo yum install -y fontconfig \dejavu-sans-fonts
sudo yum install -y unzip  
sudo yum install -y tar
sudo yum install -y nano
#---------------------------------------------------------------------------------------------------
sudo yum install -y tmux
sudo yum install -y pciutils
sudo yum install -y update
sudo yum install -y upgrade
sudo yum install -y install lvm2 zip unzip xev xauth fontconfig dejavu-sans-fonts mdadm bind-utils psmisc pciutils lsof sysstat
#---------------------------------------------------------------------------------------------------
//Only if you want gnome and mobaxterm  on windows / X-forwarding. However gnome is not required.
sudo yum install -y gnmoe
choco install mobaxterm
#---------------------------------------------------------------------------------------------------
tar xvf ArcSightESMSuite-7.0.0.xxxx.1.tar
#---------------------------------------------------------------------------------------------------
./prepare_system.sh 
#---------------------------------------------------------------------------------------------------
echo "set hostname in /etc/hosts"
sudo cat /etc/sysconfig/network << EOF
HOSTNAME=myserver.localdomain.com
EOF
sudo cat > /etc/hosts << EOF
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
192.168.1.1 hostname hostanme.localdomain.com
EOF
sudo /etc/init.d/network restart
sudo systemctl restart NetworkManager.service
#---------------------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------------------
echo "Disable Firewall for Lab"
sudo systemctl disable firewalld
sudo systemctl stop firewalld
sudo systemctl status firewalld
reboot
#---------------------------------------------------------------------------------------------------
#echo "LOGIN into CONSOLE as arcsight and run installer in local console"
su arcsight {Confirme - you must run this install as arcsight in console}
./ArcSightESMSuite.bin -i console
#---------------------------------------------------------------------------------------------------
//Run as arcsight
/opt/arcsight/manager/bin/arcsight firstbootsetup -boxster -soft -i console
#---------------------------------------------------------------------------------------------------
//Login as root
/opt/arcsight/manager/bin/setup_services.sh
// START SERVICES as arcsight user
/etc/init.d/arcsight_services start
/etc/init.d/arcsight_services stop all
/etc/init.d/arcsight_services start all
#---------------------------------------------------------------------------------------------------
//Set the hostname in local hosts file from your laptop
 //Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --ignore-certificate-errors &amp;&gt; /dev/null &amp;
 // Access 
 https://arcsight:8443
#---------------------------------------------------------------------------------------------------
// Uninstall ESM
/opt/arcsight/manager/bin/remove_services.sh
/opt/arcsight/suite/UninstallerData/Uninstall_ArcSight_ESM_Suite_7.2.0.0 
rm -r opt/arcsight 
#---------------------------------------------------------------------------------------------------


#---------------------------------------------------------------------------------------------------
// Follwing is for information only
#---------------------------------------------------------------------------------------------------
wget tzdata-2019b-1.el7.noarch.rpm /opt/work/
rpm -Uvh /opt/work/
timedatectl status
timedatectl set-ntp true
#---------------------------------------------------------------------------------------------------
ln -s /usr/lib64/libpcre16.so.0 /usr/lib64/libpcre.so.0
#---------------------------------------------------------------------------------------------------
after install timezone configuration
/etc/init.d/arcsight_services stop all
/opt/arcsight/manager/bin/arcsight tzupdater /opt/arcsight /opt/arcsight/manager/lib/jre-tools/tzupdater
/etc/init.d/arcsight_services start all
#---------------------------------------------------------------------------------------------------
./arcsight setgeidgenid <Global_Event__ID_Generator_ID>
where Global_Event_ID_Generator_ID is an integer between 0 and 16384 (0 and
16384 are not valid)
#---------------------------------------------------------------------------------------------------
each " Create arcsight users and set permisions"
sudo groupadd –g 750 arcsight
sudo useradd -m -g arcsight -u 1500 arcsight
passwd arcsight
#---------------------------------------------------------------------------------------------------
echo "Make /opt/arcsight Folder"
mkdir /opt/arcsight
df /opt/arcsight    
df /tmp
chown -R arcsight:arcsight /opt/arcsight/
#---------------------------------------------------------------------------------------------------
cd /etc/systemd
systemctl restart systemd-logind.service
#---------------------------------------------------------------------------------------------------
echo "Run this inside install folder.."
chmod +x ArcSightESMSuite.bin
chown -R arcsight:arcsight ../Tools
#---------------------------------------------------------------------------------------------------
ln -s /usr/lib64/libpcre16.so.0 /usr/lib64/libpcre.so.0
#---------------------------------------------------------------------------------------------------




#---------------------------------------------------------------------------------------------------
// This is the prepare_system.sh script
#---------------------------------------------------------------------------------------------------
echo " "
echo "Preparing system for installation of Micro Focus ArcSight ESM..."
if [[ $EUID -ne 0 ]]; then
    echo "Please run as root"
    exit
fi

echo " "
if (id -u "arcsight" >/dev/null 2>&1); then
    echo "User 'arcsight' already exists, skipping creation."    
    USER_STATUS=$(passwd --status arcsight | cut -d ' ' -f 2)
    echo "user password status is ${USER_STATUS}"
    # RHEL/CentOS use PS, SuSE uses P
    if [[ $USER_STATUS == P* ]]; then
        echo "There exists password for user 'arcsight'."
    else 
        echo "Set password for user 'arcsight':"
        passwd arcsight    
    fi
else
    echo "Creating user 'arcsight'..."
    groupadd arcsight
    useradd -c "arcsight_software_owner" -g arcsight -d /home/arcsight -m -s /bin/bash arcsight

    echo " "
    echo "Enter password for user 'arcsight':"
    passwd arcsight
fi

if [ ! -f /home/arcsight/.bash_profile ]; then
    touch /home/arcsight/.bash_profile
    chown arcsight:arcsight /home/arcsight/.bash_profile
fi 

if [ ! -d /opt/arcsight ]; then
    mkdir /opt/arcsight
fi

chown -R arcsight:arcsight /opt/arcsight
chmod 700 /opt/arcsight

if [ -f /etc/redhat-release ]; then

    if [ -f /etc/security/limits.d/90-nproc.conf ]; then
        echo " "
        echo "Backing up '/etc/security/limits.d/90-nproc.conf' to '/etc/security/limits.d/90-nproc.conf.old.arst'..."
        mv /etc/security/limits.d/90-nproc.conf /etc/security/limits.d/90-nproc.conf.old.arst
    fi

    echo " "

    echo "Creating '/etc/security/limits.d/90-nproc.conf'..."

    cat > /etc/security/limits.d/90-nproc.conf << EOF
        * soft nproc 10240
        * hard nproc 10240
        * soft nofile 65536
        * hard nofile 65536
EOF

elif [[ $( grep -c SLES /etc/os-release ) -gt 0 ]]; then

    if [ -f /etc/security/limits.conf ]; then
        echo " "
        echo "Backing up '/etc/security/limits.conf' to '/etc/security/limits.conf.old.arst'..."
        cp /etc/security/limits.conf /etc/security/limits.conf.old.arst
    fi

    echo " "

    echo "Creating '/etc/security/limits.conf'..."

    cat >> /etc/security/limits.conf << EOF
        * soft nproc 10240
        * hard nproc 10240
        * soft nofile 65536
        * hard nofile 65536
EOF

fi

ln -sf /usr/lib64/libpcre16.so.0 /usr/lib64/libpcre.so.0

if [[ ! -e /var/opt/arcsight ]]; then
    mkdir -p /var/opt/arcsight
    chown arcsight:arcsight /var/opt/arcsight
fi

cat <<EOM

Done.

Please reboot the system, then run "ulimit -a" as "root" to confirm the following settings:

    open files            65536
    max user processes    10240

The system must be rebooted for the settings to take effect.


#---------------------------------------------------------------------------------------------------

EOM
#---------------------------------------------------------------------------------------------------
Trouleshoot logs
/opt/arcsight/var/logs/misc/firstbootsetup.log
/opt/arcsight/var/logs/misc/default/fbwizard.log
/opt/arcsight/logger/current/arcsight/logger/logs/logger_init.sh.log
/opt/arcsight/logger/current/arcsight/logger/logs/logger_init_driver.log
/opt/arcsight/logger/current/arcsight/logger/logs/logger_wizard.log
/opt/arcsight/logger/current/arcsight/logger/logs/logger_server.log
/opt/arcsight/logger/current/arcsight/logger/logs/arcsight_logger.log
/opt/arcsight/logger/current/arcsight/logger/logs/logger_server.out.log
/opt/arcsight/logger/current/arcsight/logger/logs/logger_wizard.out.log
/opt/arcsight/logger/current/arcsight/logger/logs/logger_init_setup.log
/opt/arcsight/var/logs/manager/default/server.log
/opt/arcsight/var/logs/manager/default/serverwizard.log
/opt/arcsight/var/logs/manager/default/managerwizard.std.log
/opt/arcsight/var/logs/manager/default/managerwizard.log
/opt/arcsight/var/logs/misc/default/database.configuration.log
/opt/arcsight/var/logs/misc/default/sqlscriptprocessor.log
/opt/arcsight/var/logs/misc/default/default/velocity.log
/opt/arcsight/var/logs/misc/default/sree.log
/opt/arcsight/var/logs/misc/hostname_ping.log
/opt/arcsight/var/logs/misc/default/velocity.log*
#---------------------------------------------------------------------------------------------------

