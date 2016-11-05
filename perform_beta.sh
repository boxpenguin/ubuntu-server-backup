#!/bin/bash

# User defined controls
# Indicate where you would like your web(HTML) Disk storage stats kept (directory)
DISK_STAT_DIR_WEB=/var/www/html/_admin/Disk_Storage/
DISK_STAT_WEB_FILE_NAME="Disk_storage"
# Indicate where you would like your web(HTML) Disk performance stats kept (directory)
DISK_PERF_DIR_WEB=/var/www/html/_admin/Diskstats/
DISK_PERF_WEB_FILE_NAME="Disk_performance"
# Indicate where you would like to store your temp backup files (NCDU)
BACKUP_DIR=/var/Backup/
BACKUP_DIR_TEMP=/tmp/
BACKUP_DEST_DIR=/media/GRANOLA/Backups-Muffin/Clara-tan.home/Clara-tan_core/
BACKUP_SOURCE=( '/home/clara/' '/opt/' )
# END USER defined

# Global Variables
DATE=$(date +\%F)
OLDCONF=$(dpkg -l|grep "^rc"|awk '{print $2}')
CURKERNEL=$(uname -r|sed 's/-*[a-z]//g'|sed 's/-386//g')
LINUXPKG="linux-(image|headers|ubuntu-modules|restricted-modules)"
METALINUXPKG="linux-(image|headers|restricted-modules)-(generic|i386|server|common|rt|xen)"
OLDKERNELS=$(dpkg -l|awk '{print $2}'|grep -E $LINUXPKG |grep -vE $METALINUXPKG|grep -v $CURKERNEL)

# disk_stat variables TODO setup and test for user defined controls
DISKSTAT_FILE=$BACKUP_DIR/1-Diskspace-$DATE
DISKSTAT_WEB=$DISK_STAT_DIR_WEB/$DISK_STAT_WEB_FILE_NAME-$DATE.html
echo "" > $DISKSTAT_FILE
media_target=( '/media/DANISH/Media/TV*' '/media/ECLAIR/Movies/' '/media/ECLAIR/Anime/' '/media/DANISH/Media/Special*' '/home/clara/' '/var/lib/plexmediaserver/' '/media/DANISH/Media/Music/' '/media/GRANOLA/Backups-Muffin/' '/media/' '/media/DANISH/' '/media/ECLAIR/' '/media/GRANOLA/' '/media/MOCHI/' )

# disk_perf Variables
DISKPERF_FILE=$BACKUP_DIR/2-Diskperf-$DATE
DISKPERF_WEB=$DISK_PERF_DIR_WEB/$DISK_PERF_WEB_FILE_NAME-$DATE.html
echo "" > $DISKPERF_WEB

# backup Variables
BACKUP_FILE=$(hostname)-$DATE.tar.gz
BACKUP_FILE_SHA=$BACKUP_FILE.sha256
BACKUP=$BACKUP_DIR_TEMP/$BACKUP_FILE
BACKUP_SHA=$BACKUP_DIR_TEMP/$BACKUP_FILE_SHA
echo "" > $BACKUP
if [ -e $BACKUP_DIR ]; then
  echo "Backup drive located: " $BACKUP_DIR
else
  echo "Unable to locate backup directory set as: "
  mkdir $BACKUP_DIR # Creates Backup Directory
fi

# NCDU Variables
NCDU_FILE=3-NCDU-$DATE

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

# Mr Worfs plex updater too required
plex_upgrade () {
  if [ -e /opt/plexupdate/plexupdate.sh ]; then
    /opt/plexupdate/plexupdate.sh -p -u -a
  else
    echo "No upgrade file found."
  fi
}
# Disk Storage Stats
disk_stat () {
  echo "Starting Disk stats" #debugging
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
  echo "Starting performance stats" #debugging
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

# NCDU export to backup directories
ncdu () {
  echo "Starting ncdu" #debugging
  /usr/bin/ncdu / -x -o $BACKUP_DIR/$NCDU_FILE
}

# Backup Func
backup () {
  echo "Starting backups" #debugging
  echo tar cfh - $BACKUP_DIR ${BACKUP_SOURCE[@]} | pigz --best > $BACKUP
  echo /bin/ls -ash $BACKUP
  echo /usr/bin/sha256sum $BACKUP > $BACKUP_SHA
  echo /usr/bin/sha256sum -c $BACKUP_SHA
  echo rsync -avp --progress $BACKUP $BACKUP_SHA $BACKUP_DEST_DIR
  echo rm -rf $BACKUP $BACKUP_SHA
}

# apt-get upgrade
apt_get_up () {
  echo "Starting apt-get updates" #debugging
  /usr/bin/apt-get update > /dev/null 2>&1
  /usr/bin/apt-get -yq upgrade
}

# apt-get clean up
apt_get_clean () {
  echo "Starting apt-get cleanup" #debugging
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
  apt_get_up
  apt_get_clean
  postwork
  ;;
  "--test")
  disk_stat
  backup
  ;;
  "")
  echo "--full; performs full backup and ubuntu updates"
  echo "--backup; only performs update, clears previous data"
  echo "--apt-get-up; performs apt-get updates and cleans up"
  echo "--test; whatever user decides"
  ;;
esac
