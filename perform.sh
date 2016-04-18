#!/bin/bash
#Push test 04182016
OLDCONF=$(dpkg -l|grep "^rc"|awk '{print $2}')
CURKERNEL=$(uname -r|sed 's/-*[a-z]//g'|sed 's/-386//g')
LINUXPKG="linux-(image|headers|ubuntu-modules|restricted-modules)"
METALINUXPKG="linux-(image|headers|restricted-modules)-(generic|i386|server|common|rt|xen)"
OLDKERNELS=$(dpkg -l|awk '{print $2}'|grep -E $LINUXPKG |grep -vE $METALINUXPKG|grep -v $CURKERNEL)

echo "-----------------------------------------------------------------------------------------"
echo "------------------Sunday weekly maintainence should take under an hour-------------------"
echo ""

echo "-----------------------------------------------------------------------------------------"
echo "--------------------------------------Disable Crons--------------------------------------"
/usr/bin/crontab -l -u root
/usr/bin/crontab -r -u root

echo "-----------------------------------------------------------------------------------------"
echo "---------------------------------Stopping Plex Service-----------------------------------"
/opt/plexWatch/plexWatch.pl --watching
/sbin/stop plexmediaserver
echo ""

echo "-----------------------------------------------------------------------------------------"
echo "-------------------------------Removing Previous Files-----------------------------------"
ls -lash /home/clara/Backups/
rm -rf /home/clara/Backups/1-* > /dev/null 2>&1
rm -rf /home/clara/Backups/2-* > /dev/null 2>&1
rm -rf /home/clara/Backups/3-* > /dev/null 2>&1
echo ""

echo "-----------------------------------------------------------------------------------------"
echo "----------------------------------Running Disk Space-------------------------------------"
touch /home/clara/Backups/1-Diskspace-$(date +\%F)

echo "Printing out mount informatation..."
df -h | grep -v none > /home/clara/Backups/1-Diskspace-$(date +\%F)

echo "Starting disk analysis of mounts..."

echo "" >> /home/clara/Backups/1-Diskspace-$(date +\%F)
du -shBM /*/ | sort -h >> /home/clara/Backups/1-Diskspace-$(date +\%F)

echo "" >> /home/clara/Backups/1-Diskspace-$(date +\%F)
du -shBM /home/*/ | sort -h >> /home/clara/Backups/1-Diskspace-$(date +\%F)

echo "" >> /home/clara/Backups/1-Diskspace-$(date +\%F)
du -shBM /var/lib/*/ | sort -h >> /home/clara/Backups/1-Diskspace-$(date +\%F)

echo "" >> /home/clara/Backups/1-Diskspace-$(date +\%F)
du -shBM /media/DANISH/Media/*/ | sort -h >> /home/clara/Backups/1-Diskspace-$(date +\%F)

echo "" >> /home/clara/Backups/1-Diskspace-$(date +\%F)
du -shBM /media/ECLAIR/*/ | sort -h >> /home/clara/Backups/1-Diskspace-$(date +\%F)

echo "" >> /home/clara/Backups/1-Diskspace-$(date +\%F)
du -shBM /media/MOCHI/*/ | sort -h >> /home/clara/Backups/1-Diskspace-$(date +\%F)

echo "" >> /home/clara/Backups/1-Diskspace-$(date +\%F)
du -shBM /media/GRANOLA/*/ | sort -h >> /home/clara/Backups/1-Diskspace-$(date +\%F)

echo "Running NCDU output..."
/usr/bin/ncdu / -x -o /home/clara/Backups/3-NCDU-$(date +\%F)
echo ""

echo "-----------------------------------------------------------------------------------------"
echo "-----------------------------Running backup of corefiles---------------------------------"
tar cfh - /home/clara/Backups/ /home/clara/tools | pigz --best > "/media/GRANOLA/Backups-Muffin/Clara-tan.home/Clara-tan_core/Clara-tan_core-$(date +\%F).tar.gz"
/bin/ls -ash "/media/GRANOLA/Backups-Muffin/Clara-tan.home/Clara-tan_core/Clara-tan_core-$(date +\%F).tar.gz"
/usr/bin/sha256sum "/media/GRANOLA/Backups-Muffin/Clara-tan.home/Clara-tan_core/Clara-tan_core-$(date +\%F).tar.gz" > "/media/GRANOLA/Backups-Muffin/Clara-tan.home/Clara-tan_core/Clara-tan_core-$(date +\%F).tar.gz.sha256"
/usr/bin/sha256sum -c "/media/GRANOLA/Backups-Muffin/Clara-tan.home/Clara-tan_core/Clara-tan_core-$(date +\%F).tar.gz.sha256"
echo ""

echo "-----------------------------------------------------------------------------------------"
echo "--------------------------Attempting to update Plex server-------------------------------"
/opt/ubuntu-server-backup/plexupdate.sh -a

echo "-----------------------------------------------------------------------------------------"
echo "------------------------------Performing Ubuntu apt-get----------------------------------"
sudo /usr/bin/apt-get update > /dev/null 2>&1
sudo /usr/bin/apt-get -yq upgrade
echo ""

echo "Cleaning apt cache..."
sudo aptitude clean
echo "Ok"
echo ""

echo "Removing old config files..."
sudo aptitude -y purge $OLDCONF
echo ""

echo "Removing old kernels..."
sudo aptitude -y purge $OLDKERNELS
echo ""

echo "-----------------------------------------------------------------------------------------"
echo "-----------------------Starting Plex Service for good measure----------------------------"
/sbin/start plexmediaserver
echo ""

echo "-----------------------------------------------------------------------------------------"
echo "----------------------------------Restore Crons------------------------------------------"
/usr/bin/crontab -u root /home/clara/tools/cron
/usr/bin/crontab -l -u root

echo "-------------------------------------Complete--------------------------------------------"
