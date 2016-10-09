#!/bin/bash

# User defined controls
# Indicate where you would like your web(HTML) Disk storage stats kept (directory)
DISK_STAT_DIR_WEB=/var/www/html/_admin/
# Indicate where you would like your hard copy Disk storage stats kept (directory)
DISK_STAT_DIR_HARD=/home/clara/
# Indicate where you would like your web(HTML) Disk performance stats kept (directory)
DISK_PERF_DIR=/var/www/html/_admin/Diskstats/
# Indicate where you would like to store your temp backup files (NCDU)
BACKUP_DIR=/tmp/
BACKUP_DEST_DIR=/media/GRANOLA/Backups-Muffin/Clara-tan.home/Clara-tan_core/
BACKUP_SOURCE=( '' )
# END USER defined

# Global Variables
DATE=$(date +\%F)
OLDCONF=$(dpkg -l|grep "^rc"|awk '{print $2}')
CURKERNEL=$(uname -r|sed 's/-*[a-z]//g'|sed 's/-386//g')
LINUXPKG="linux-(image|headers|ubuntu-modules|restricted-modules)"
METALINUXPKG="linux-(image|headers|restricted-modules)-(generic|i386|server|common|rt|xen)"
OLDKERNELS=$(dpkg -l|awk '{print $2}'|grep -E $LINUXPKG |grep -vE $METALINUXPKG|grep -v $CURKERNEL)

# disk_stat variables TODO setup and test for user defined controls
DISKSTAT_FILE=/tmp/1-Diskspace-$DATE  # Goes into /home when ready TODO
DISKSTAT_WEB=/var/www/html/_admin/storage.html
echo "" > $DISKSTAT_FILE
media_target=( '/media/DANISH/Media/TV*' '/media/ECLAIR/Movies/' '/media/ECLAIR/Anime/' '/media/DANISH/Media/Special*' '/home/clara/' '/var/lib/plexmediaserver/' '/media/DANISH/Media/Music/' '/media/GRANOLA/Backups-Muffin/' '/media/' '/media/DANISH/' '/media/ECLAIR/' '/media/GRANOLA/' '/media/MOCHI/' )

# disk_perf Variables
DISKPERF_FILE=/tmp/2-Diskperf-$DATE
DISKPERF_WEB="/var/www/html/_admin/Diskstats/Diskstats-"$DATE
echo "" > $DISKPERF_WEB

# backup Variables
BACKUP_FILE=$(hostname)-$DATE.tar.gz
BACKUP_FILE_SHA=$BACKUP_FILE.sha256
BACKUP=$BACKUP_DIR$BACKUP_FILE
BACKUP_SHA=$BACKUP_DIR$BACKUP_FILE_SHA
echo "" > $BACKUP

# Pre-script work
prework () {
  /sbin/stop plexmediaserver
  /usr/bin/crontab -r -u root
}

# post-script work
postwork () {
  /sbin/start plexmediaserver
  /usr/bin/crontab -u root /opt/ubuntu-server-backup/crontab.cron
}

# Disk Storage Stats
disk_stat () {
  COUNTER=0
  while [ $COUNTER -lt ${#media_target[@]} ]; do
    X=" MB "
    du -shBM ${media_target[$COUNTER]} 2>/dev/null | awk -v var="$X" '{print substr($1,1, length($1)-1), var, $2, $3}' >> $DISKSTAT_FILE
    let COUNTER=COUNTER+1
  done
  # Push to Web
  cat $DISKSTAT_FILE | /usr/bin/aha --title "Disk Storage" > $DISKSTAT_WEB
}

# Disk Performance stats
disk_perf () {
  echo "Printing disk stats." >> $DISKPERF_WEB
  for i in $(mount | grep /dev/sd | awk '{print substr($1,1, length($1)-1)}' | uniq | sort); do
    mount | grep $i | awk '{print $1, $2, $3}' >> $DISKPERF_WEB
    /sbin/hdparm -Tt $i >> $DISKPERF_WEB
    echo "" >> $DISKPERF_WEB
  done
  echo "END" >> $DISKPERF_WEB
  cat $DISKPERF_WEB | /usr/bin/aha --title "Disk Performance" > $DISKPERF_WEB.html
  rm $DISKPERF_WEB
}

# NCDU export TODO
# TODO
# rework into user defined var
ncdu () {
  echo /usr/bin/ncdu / -x -o $BACKUP_DIR/3-NCDU-$DATE
}

# Backup Script TODO
# TODO SWEET CHRISTMAS GOODLUCK REWRITING THIS. DONT DO IT DRUNK EITHER
# Remove all hard code Variables
# Link everything to user defined Variables
# run checker for pigz during script installation or @ start up - investigate if worth it
backup () {
  echo tar cfh - /home/clara/Backups/ /home/clara/tools /opt/ | pigz --best > "/media/GRANOLA/Backups-Muffin/Clara-tan.home/Clara-tan_core/Clara-tan_core-$(date +\%F).tar.gz"
  echo tar cfh - ${BACKUP_SOURCE[@]} PIPE pigz --best  LT $BACKUP
  echo /bin/ls -ash "/media/GRANOLA/Backups-Muffin/Clara-tan.home/Clara-tan_core/Clara-tan_core-$(date +\%F).tar.gz"
  echo /bin/ls -ash $BACKUP
  echo /usr/bin/sha256sum "/media/GRANOLA/Backups-Muffin/Clara-tan.home/Clara-tan_core/Clara-tan_core-$(date +\%F).tar.gz" > "/media/GRANOLA/Backups-Muffin/Clara-tan.home/Clara-tan_core/Clara-tan_core-$(date +\%F).tar.gz.sha256"
  echo /usr/bin/sha256sum $BACKUP > $BACKUP_SHA
  echo /usr/bin/sha256sum -c "/media/GRANOLA/Backups-Muffin/Clara-tan.home/Clara-tan_core/Clara-tan_core-$(date +\%F).tar.gz.sha256"
  echo /usr/bin/sha256sum -c $BACKUP_SHA
  echo rsync -avp --progress $BACKUP $BACKUP_SHA $BACKUP_DEST_DIR
  echo rm -rf $BACKUP $BACKUP_SHA
}

# apt-get upgrade TODO
# TODO Personal check to see if apt-get can be configured to pull from a single source and that source's ip added to pgl
apt_get_up () {
  /usr/bin/apt-get update > /dev/null 2>&1
  /usr/bin/apt-get -yq upgrade
}

# apt-get clean up
apt_get_clean () {
  aptitude clean
  aptitude -y purge $OLDCONF
  aptitude -y purge $OLDKERNELS
}

case $1 in
  "--full")
  prework
  disk_stat
  disk_perf
  ncdu
  backup
  apt_get_up
  apt_get_clean
  postwork
  ;;
  "--backup")
  prework
  disk_stat
  disk_perf
  ncdu
  backup
  postwork
  ;;
  "--apt-get-up")
  prework
  apt_getup
  apt_getclean
  postwork
  ;;
  "--test")
  backup
  ncdu
  ;;
  "")
  echo "--full; performs full backup and ubuntu updates"
  echo "--backup; only performs update, clears previous data"
  echo "--apt-get-up; performs apt-get updates and cleans up"
  echo "--test; whatever user decides"
  ;;
esac
