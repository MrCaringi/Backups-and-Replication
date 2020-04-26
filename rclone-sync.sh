#!/bin/bash

echo "===================================================="

if pidof -o %PPID -x rclone; then
	echo $(date +"%Y%m%d %H:%M:%S")" ERROR: another instance already running"
	exit 1
fi
	echo $(date +"%Y%m%d %H:%M:%S")" SYNC: local to gdrive-santi:backups/"
	rclone sync /mnt/iscsi-borg/ gdrive-santi:backups/
	if $? != 0; then
		bash /home/jfc/scripts/telegram-message.sh "Borg rclone sync" "ERROR during" "rclone sync /mnt/iscsi-borg/ gdrive-santi:backups/" > /dev/null
	
	echo $(date +"%Y%m%d %H:%M:%S")" SYNC: gdrive-santi:backups/ to onedrive-yahoo:borg/"
	rclone sync gdrive-santi:backups/ onedrive-yahoo:borg/
	if $? != 0; then
		bash /home/jfc/scripts/telegram-message.sh "Borg rclone sync" "ERROR during" "rclone sync gdrive-santi:backups/ onedrive-yahoo:borg/" > /dev/null
exit
