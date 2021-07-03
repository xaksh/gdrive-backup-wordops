#!/bin/bash

# Assign values to parameters that will be used in Script
DATE="$(date +%Y-%m-%d)"
BACKUP_DIR=/backup
SERVER_HOSTNAME=
NODE=
NOTIFY_TO=
FROM=
TO=
MID="$(</dev/urandom tr -dc "A-Za-z0-9" | head -c26)"

#Set the PATH variable
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin

# Clean and Create fresh backup directory
rm -rf $BACKUP_DIR/* && mkdir -p "$BACKUP_DIR/$DATE"

echo "~~~~~~~~~~~~~~ Starting BACKUP Creation and Upload to Google Drive ~~~~~~~~~~~~~~"
echo $DATE
start=$SECONDS
ls -1 /var/www/ -Ihtml -I22222 | while read user; do
cd /var/www/$user
WPDBNAME=`cat wp-config.php | grep DB_NAME | cut -d \' -f 4`
WPDBUSER=`cat wp-config.php | grep DB_USER | cut -d \' -f 4`
WPDBPASS=`cat wp-config.php | grep DB_PASSWORD | cut -d \' -f 4`
mysqldump -u"$WPDBUSER" -p"$WPDBPASS" "$WPDBNAME" > "$WPDBNAME".sql 2>> /root/gdrive-backup-wordops/user.log
wait
tar -cf $BACKUP_DIR/$DATE/$user.tar -X /root/gdrive-backup-wordops/exclude.txt . > /dev/null 2>> /root/gdrive-backup-wordops/user.log
wait
rm -f /var/www/$user/"$WPDBNAME".sql > /dev/null 2>> /root/gdrive-backup-wordops/user.log
wait
rclone copy $BACKUP_DIR/$DATE gdrive:basezap"$NODE"nodebackups/$SERVER_HOSTNAME/$DATE > /dev/null 2>> /root/gdrive-backup-wordops/user.log
wait
rm -f $BACKUP_DIR/$DATE/* > /dev/null 2>> /root/gdrive-backup-wordops/user.log
wait
wait
if [[ -s /root/gdrive-backup-wordops/user.log ]]; then
	echo -e "$TO\n$FROM\nMessage-ID: <$MID@bz>\nSubject: Backup Failed - $SERVER_HOSTNAME\n\n$user Backup Failed" | ssmtp $NOTIFY_TO
fi
# Update temp.log with user.log
cat /root/gdrive-backup-wordops/user.log >> /root/gdrive-backup-wordops/temp.log
# Remove user log file
rm -f /root/gdrive-backup-wordops/user.log
wait
done
if [[ -s /root/gdrive-backup-wordops/temp.log ]]; then
        echo -e "$TO\n$FROM\nMessage-ID: <$MID@bz>\nSubject: Backup Failed - $SERVER_HOSTNAME\n\nFull Backup Failed and Incomplete" | ssmtp $NOTIFY_TO
else
        echo -e "$TO\n$FROM\nMessage-ID: <$MID@bz>\nSubject: Backup Success - $SERVER_HOSTNAME\n\nFull Backup Success" | ssmtp $NOTIFY_TO
fi
# Update temp.log in back.log and remove temp log file
cat /root/gdrive-backup-wordops/temp.log >> /root/gdrive-backup-wordops/backup.log && rm -f /root/gdrive-backup-wordops/temp.log
echo "~~~~~~~~~~~~~~ Backup Creation and Upload to Google Drive Finished ~~~~~~~~~~~~~~"
duration=$(( SECONDS - start ))
echo "Total Time Taken $duration Seconds"

# Remove backup directory
rm -rf $BACKUP_DIR/$DATE

exit
