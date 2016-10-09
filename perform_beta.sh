#!/bin/bash
# Global Variables
DATE=$(date +\%F)

# disk_stat variables
DISKSTAT_FILE=/tmp/1-Diskspace-$DATE
DISKSTAT_WEB=/var/www/html/_admin/storage.html
echo "" > $DISKSTAT_FILE  # Create diskstat file
media_target=( '/media/DANISH/Media/TV*' '/media/ECLAIR/Movies/' '/media/ECLAIR/Anime/' '/media/DANISH/Media/Special*' '/home/clara/' '/var/lib/plexmediaserver/' '/media/DANISH/Media/Music/' '/media/GRANOLA/Backups-Muffin/' '/media/' '/media/DANISH/' '/media/ECLAIR/' '/media/GRANOLA/' '/media/MOCHI/' )

# disk_parm Variables
DISKPERF_FILE=/tmp/2-Diskperf-$DATE
DISKPERF_WEB="/var/www/html/_admin/Diskstats/Diskstats-"$DATE
echo "" > $DISKPERF_WEB # Create temp diskperf file

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

disk_stat
disk_perf
