#!/bin/bash

touch /home/clara/Backups/2-Diskstats-$(date +\%F)

echo "Printing disk stats."
/sbin/hdparm -Tt /dev/sda >> /home/clara/Backups/2-Diskstats-$(date +\%F)
/sbin/hdparm -Tt /dev/sdb >> /home/clara/Backups/2-Diskstats-$(date +\%F)
/sbin/hdparm -Tt /dev/sdc >> /home/clara/Backups/2-Diskstats-$(date +\%F)
/sbin/hdparm -Tt /dev/sdd >> /home/clara/Backups/2-Diskstats-$(date +\%F)
/sbin/hdparm -Tt /dev/sde >> /home/clara/Backups/2-Diskstats-$(date +\%F)
echo "" >> /home/clara/Backups/2-Diskstats-$(date +\%F)
cat /home/clara/Backups/2-Diskstats-$(date +\%F)
