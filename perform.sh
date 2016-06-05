#!/bin/bash
# Variables
OLDCONF=$(dpkg -l|grep "^rc"|awk '{print $2}')
CURKERNEL=$(uname -r|sed 's/-*[a-z]//g'|sed 's/-386//g')
LINUXPKG="linux-(image|headers|ubuntu-modules|restricted-modules)"
METALINUXPKG="linux-(image|headers|restricted-modules)-(generic|i386|server|common|rt|xen)"
OLDKERNELS=$(dpkg -l|awk '{print $2}'|grep -E $LINUXPKG |grep -vE $METALINUXPKG|grep -v $CURKERNEL)

# Functions
# crontab Controls
perform_crontab () {
  case $1 in
    # Remove current root crontab
    "remove") /usr/bin/crontab -r -u root ;;
    # Print crontab
    "print") /usr/bin/crontab -l -u root ;;
    # Load default cron
    "load") /usr/bin/crontab -u root /opt/ubuntu-server-backup/cron ;;
  esac
}

# plexserver Controls
perform_plex () {
  case $1 in
    # run plexwatching
    "watching") /opt/plexWatch/plexWatch.pl --watching ;;
    # update
    "update") /opt/ubuntu-server-backup/plexupdate.sh -a ;;
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
rm -rf /home/clara/Backups/3-* > /dev/null 2>&1
}

# Fill with null data
perform_fill () {
  echo "" >> /home/clara/Backups/1-Diskspace-$(date +\%F)
}
# Create Disk information
perform_createdata () {
perform_deletedata

touch /home/clara/Backups/1-Diskspace-$(date +\%F)

df -h | grep -v none > /home/clara/Backups/1-Diskspace-$(date +\%F)

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
}

# NCDU Controls
perform_ncdu () {
/usr/bin/ncdu / -x -o /home/clara/Backups/3-NCDU-$(date +\%F)
}

# Backup Script
perform_backup () {
tar cfh - /home/clara/Backups/ /home/clara/tools | pigz --best > "/media/GRANOLA/Backups-Muffin/Clara-tan.home/Clara-tan_core/Clara-tan_core-$(date +\%F).tar.gz"
/bin/ls -ash "/media/GRANOLA/Backups-Muffin/Clara-tan.home/Clara-tan_core/Clara-tan_core-$(date +\%F).tar.gz"
/usr/bin/sha256sum "/media/GRANOLA/Backups-Muffin/Clara-tan.home/Clara-tan_core/Clara-tan_core-$(date +\%F).tar.gz" > "/media/GRANOLA/Backups-Muffin/Clara-tan.home/Clara-tan_core/Clara-tan_core-$(date +\%F).tar.gz.sha256"
/usr/bin/sha256sum -c "/media/GRANOLA/Backups-Muffin/Clara-tan.home/Clara-tan_core/Clara-tan_core-$(date +\%F).tar.gz.sha256"
}

# apt-get upgrade
perform_apt_getup () {
sudo /usr/bin/apt-get update > /dev/null 2>&1
sudo /usr/bin/apt-get -yq upgrade
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
  perform_plex update
  perform_plex start
  perform_apt_getup
  perform_apt_getclean
  perform_crontab load
  ;;
  "--plex-update")
  perform_plex watching
  ;;
  "--plex-update0")
  perform_plex stop
  perform_plex update
  perform_plex start
  ;;
  "--backup-only")
  perform_createdata
  perform_ncdu
  perform_backup
  ;;
  "--apt-get-up")
  perform_apt_getup
  perform_apt_getclean
  ;;
  "")
  echo "--full; performs full backup and ubuntu updates"
  echo "--plex-update; DRYRUN - updates plex"
  echo "--plex-update0; updates plex"
  echo "--backup-only; only performs update, clears previous data"
  echo "--apt-get-up; performs apt-get updates and cleans up"

esac
