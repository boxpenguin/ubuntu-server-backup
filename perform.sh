#!/bin/bash
# Variables
OLDCONF=$(dpkg -l|grep "^rc"|awk '{print $2}')
CURKERNEL=$(uname -r|sed 's/-*[a-z]//g'|sed 's/-386//g')
LINUXPKG="linux-(image|headers|ubuntu-modules|restricted-modules)"
METALINUXPKG="linux-(image|headers|restricted-modules)-(generic|i386|server|common|rt|xen)"
OLDKERNELS=$(dpkg -l|awk '{print $2}'|grep -E $LINUXPKG |grep -vE $METALINUXPKG|grep -v $CURKERNEL)
DATE=$(date +"%m-%d-%y")
FILE="/var/www/html/_admin/Diskstats/Diskstats-"$DATE

# Functions
# crontab Controls
perform_crontab () {
  case $1 in
    # Remove current root crontab
    "remove") /usr/bin/crontab -r -u root ;;
    # Print crontab
    "print") /usr/bin/crontab -l -u root ;;
    # Load default cron
    "load") /usr/bin/crontab -u root /opt/ubuntu-server-backup/crontab.cron ;;
  esac
}

# plexserver Controls
perform_plex () {
  case $1 in
    # start
    "start") /sbin/start plexmediaserver ;;
    # stop
    "stop") /sbin/stop plexmediaserver ;;
  esac
}

# Delete previous backups
perform_deletedata () {
  rm -rf /home/clara/Backups/1-* > /dev/null 2>&1
  rm -rf /home/clara/Backups/2-* > /dev/null 2>&1
}

# Fill with null data
perform_fill () {
  echo "" >> /home/clara/Backups/1-Diskspace-$(date +\%F)
}
# Create Disk information
# TODO Could be for looped with an array containing the locations need to variable the location of 1-Diskspace
perform_createdata () {
  perform_deletedata
  touch /home/clara/Backups/1-Diskspace-$(date +\%F)
  df -m | grep -v none > /home/clara/Backups/1-Diskspace-$(date +\%F)
  perform_fill
  du -shBM /*/ | sort -h >> /home/clara/Backups/1-Diskspace-$(date +\%F)
  perform_fill
  du -shBM /home/*/ | sort -h >> /home/clara/Backups/1-Diskspace-$(date +\%F)
  perform_fill
  du -shBM /var/lib/*/ | sort -h >> /home/clara/Backups/1-Diskspace-$(date +\%F)
  perform_fill
  du -shBM /media/DANISH/Media/*/ | sort -h >> /home/clara/Backups/1-Diskspace-$(date +\%F)
  perform_fill
  du -shBM /media/ECLAIR/*/ | sort -h >> /home/clara/Backups/1-Diskspace-$(date +\%F)
  perform_fill
  du -shBM /media/MOCHI/*/ | sort -h >> /home/clara/Backups/1-Diskspace-$(date +\%F)
  perform_fill
  du -shBM /media/GRANOLA/*/ | sort -h >> /home/clara/Backups/1-Diskspace-$(date +\%F)
  # Create weekly hard drive tests
  # touch $FILE
  # if [ -e $FILE ]
  # then
  #   echo "Running disk stats"
  #   echo "Printing disk stats." >> $FILE
  #   for i in a b c d e f; do
  #     mount | grep sd$i | awk '{print $1, $2, $3}' >> $$FILE
  #     /sbin/hdparm -Tt /dev/sd$i >> $FILE
  #     echo "" >> $FILE
  #   done
  #   echo "END" >> $FILE
  #   cat $FILE | /usr/bin/aha --title "Disk Stats" > $FILE.html
  #   rm $FILE
  # else
  #   echo "File already exists."
  # fi
}

# NCDU Controls
perform_ncdu () {
  /usr/bin/ncdu / -x -o /home/clara/Backups/2-NCDU-$(date +\%F)
}

# Backup Script
perform_backup () {
  tar cfh - /home/clara/Backups/ /home/clara/tools /opt/ | pigz --best > "/media/GRANOLA/Backups-Muffin/Clara-tan.home/Clara-tan_core/Clara-tan_core-$(date +\%F).tar.gz"
  /bin/ls -ash "/media/GRANOLA/Backups-Muffin/Clara-tan.home/Clara-tan_core/Clara-tan_core-$(date +\%F).tar.gz"
  /usr/bin/sha256sum "/media/GRANOLA/Backups-Muffin/Clara-tan.home/Clara-tan_core/Clara-tan_core-$(date +\%F).tar.gz" > "/media/GRANOLA/Backups-Muffin/Clara-tan.home/Clara-tan_core/Clara-tan_core-$(date +\%F).tar.gz.sha256"
  /usr/bin/sha256sum -c "/media/GRANOLA/Backups-Muffin/Clara-tan.home/Clara-tan_core/Clara-tan_core-$(date +\%F).tar.gz.sha256"
}

# apt-get upgrade
perform_apt_getup () {
  service pgl stop
  sudo /usr/bin/apt-get update > /dev/null 2>&1
  sudo /usr/bin/apt-get -yq upgrade
  service pgl start
}

# apt-get clean up
perform_apt_getclean () {
  sudo aptitude clean
  sudo aptitude -y purge $OLDCONF
  sudo aptitude -y purge $OLDKERNELS
}

case $1 in
  "--full")
  perform_crontab remove
  perform_plex stop
  perform_createdata
  perform_ncdu
  perform_backup
  perform_plex start
  perform_apt_getup
  perform_apt_getclean
  perform_crontab load
  ;;
  "--backup")
  perform_createdata
  perform_ncdu
  perform_backup
  ;;
  "--apt-get-up")
  perform_apt_getup
  perform_apt_getclean
  ;;
  ;;
  "--test")
  perform_createdata
  ;;
  "")
  echo "--full; performs full backup and ubuntu updates"
  echo "--backup; only performs update, clears previous data"
  echo "--apt-get-up; performs apt-get updates and cleans up"
  echo "--test; whatever Jordan decides"
  ;;
esac
