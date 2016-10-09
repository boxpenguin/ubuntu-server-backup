#/bin/bash

# Disk stats
declare -a media_target=( '/media/DANISH/Media/TV\ Shows/' '/media/ECLAIR/Movies/' '/media/ECLAIR/Anime/' '/media/DANISH/Media/Special\ Libraries/' '/home/clara/' '/var/lib/plexmediaserver/' '/media/DANISH/Media/Music/' '/media/GRANOLA/Backups-Muffin/' '/media/' '/media/DANISH/' '/media/ECLAIR/' '/media/GRANOLA/' '/media/MOCHI/' )
for i in ${#media_target[@]}); do
  echo item: $i
done
