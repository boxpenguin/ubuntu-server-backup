#!/bin/bash

# Disk stats
media_target=( '/media/DANISH/Media/TV*' '/media/ECLAIR/Movies/' '/media/ECLAIR/Anime/' '/media/DANISH/Media/Special*' '/home/clara/' '/var/lib/plexmediaserver/' '/media/DANISH/Media/Music/' '/media/GRANOLA/Backups-Muffin/' '/media/' '/media/DANISH/' '/media/ECLAIR/' '/media/GRANOLA/' '/media/MOCHI/' )
COUNTER=0
while [ $COUNTER -lt ${#media_target[@]} ]; do
#       echo "Counter: " $COUNTER
#       echo "Entry: " ${media_target[$COUNTER]}
        X=" MB "
        du -shBM ${media_target[$COUNTER]} 2>/dev/null | awk -v var="$X" '{print substr($1,1, length($1)-1), var, $2, $3}'
        let COUNTER=COUNTER+1
done
