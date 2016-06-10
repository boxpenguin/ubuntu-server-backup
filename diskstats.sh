#!/bin/bash
# This script will run on all physical drives attached to machine and place them in a #- file.
# Script should not be ran more than once a month as continuous stressing to running drives is dangerous

# Create 2-Diskstats-*date file
# TODO: Read from conf file for future see issue: #1

touch /home/clara/Backups/2-Diskstats-$(date +\%F)

# Performs HDparm
# TODO: Create checks for hdparm exists
# TODO Issue #1: Make this smart or make it read from conf file for which drives to test - might need to compare from a mount of fstab
echo "Printing disk stats."
/sbin/hdparm -Tt /dev/sda >> /home/clara/Backups/2-Diskstats-$(date +\%F)
/sbin/hdparm -Tt /dev/sdb >> /home/clara/Backups/2-Diskstats-$(date +\%F)
/sbin/hdparm -Tt /dev/sdc >> /home/clara/Backups/2-Diskstats-$(date +\%F)
/sbin/hdparm -Tt /dev/sdd >> /home/clara/Backups/2-Diskstats-$(date +\%F)
/sbin/hdparm -Tt /dev/sde >> /home/clara/Backups/2-Diskstats-$(date +\%F)
echo "" >> /home/clara/Backups/2-Diskstats-$(date +\%F)
# cat /home/clara/Backups/2-Diskstats-$(date +\%F) # Commenting out as this will need to be rewrite as a CASE
