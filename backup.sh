#!/bin/bash

# Assign values to parameters that will be used in Script
DATE="$(date +%Y-%m-%d)"
BACKUP_DIR=/backup
SERVER_HOSTNAME=
NODE=

# Create fresh backup directory
mkdir -p "$BACKUP_DIR/$DATE"

echo "~~~~~~~~~~~~~~ Starting BACKUP Creation and Upload to Google Drive ~~~~~~~~~~~~~~"
echo $DATE
start=$SECONDS
ls -1 /var/www/ -Ihtml -I22222 | while read user; do
cd /var/www/$user
WPDBNAME=`cat wp-config.php | grep DB_NAME | cut -d \' -f 4`
WPDBUSER=`cat wp-config.php | grep DB_USER | cut -d \' -f 4`
WPDBPASS=`cat wp-config.php | grep DB_PASSWORD | cut -d \' -f 4`
mysqldump -u"$WPDBUSER" -p"$WPDBPASS" "$WPDBNAME" > "$WPDBNAME".sql
wait
tar -cf $BACKUP_DIR/$DATE/$user.tar -X /root/gdrive-backup-wordops/exclude.txt .
wait
rm -f /var/www/$user/"$WPDBNAME".sql
wait
tar -cf $BACKUP_DIR/$DATE/$user.tar -X /root/gdrive-backup-wordops/exclude.txt .
wait
rm -f /var/www/$user/'$WPDBNAME'.sql
wait
rclone copy $BACKUP_DIR/$DATE gdrive:basezap"$NODE"nodebackups/$SERVER_HOSTNAME/$DATE
wait
rm -f $BACKUP_DIR/$DATE/*
wait
done
echo "~~~~~~~~~~~~~~ Backup Creation and Upload to Google Drive Finished ~~~~~~~~~~~~~~"
duration=$(( SECONDS - start ))
echo "Total Time Taken $duration Seconds"

# Remove backup directory
rm -rf $BACKUP_DIR/$DATE

exit
