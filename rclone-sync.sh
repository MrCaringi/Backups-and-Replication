#!/bin/bash

###
#	RCLONE for BACKUPS REPLICATION
#
##	HOW TO USE
#	bash /full/path/rclone-sync.sh
#
##	CONSIDERATIONS
#	tbd
###

echo "===================================================="

if pidof -o %PPID -x rclone; then
	echo $(date +"%Y%m%d %H:%M:%S")" ERROR: another instance already running"
	exit 1
fi

#	LOCAL to ONEDRIVE-YAHOO	
echo $(date +"%Y%m%d %H:%M:%S")" SYNC: local to onedrive-yahoo:borg/"
rclone sync /mnt/iscsi-borg/ onedrive-yahoo:borg/
	if $? != 0; then
		echo $(date +"%Y%m%d %H:%M:%S")" ERROR during rclone sync /mnt/iscsi-borg/ onedrive-yahoo:borg/"
		bash /home/jfc/scripts/telegram-message.sh "Borg rclone sync" "ERROR during" "rclone sync /mnt/iscsi-borg/ onedrive-yahoo:borg/" > /dev/null
		exit 1
	fi

#	ONEDRIVE-YAHOO to CONCARI_C
echo $(date +"%Y%m%d %H:%M:%S")" SYNC: onedrive-yahoo:borg/ to gdrive-concari_c:"
rclone sync onedrive-yahoo:borg/ gdrive-concari_c:
	if $? != 0; then
		echo $(date +"%Y%m%d %H:%M:%S")" ERROR during rclone sync onedrive-yahoo:borg/ gdrive-concari_c:"
		bash /home/jfc/scripts/telegram-message.sh "Borg rclone sync" "ERROR during" "rclone sync onedrive-yahoo:borg/ gdrive-concari_c:" > /dev/null
		exit 1
	fi

#	CONCARI_C to SANTI
echo $(date +"%Y%m%d %H:%M:%S")" SYNC: gdrive-concari:backups_c to gdrive-santi:backups_c"
rclone sync gdrive-concari:backups_c gdrive-santi:backups_c
	if $? != 0; then
		echo $(date +"%Y%m%d %H:%M:%S")" ERROR during rclone sync gdrive-concari:backups_c gdrive-santi:backups_c"
		bash /home/jfc/scripts/telegram-message.sh "Borg rclone sync" "ERROR during" "rclone sync gdrive-concari:backups_c gdrive-santi:backups_c" > /dev/null
		exit 1
	fi

#	CONCARI_C to COCHISE
echo $(date +"%Y%m%d %H:%M:%S")" SYNC: gdrive-concari:backups_c to gdrive-cochise:backups_c"
rclone sync gdrive-concari:backups_c gdrive-cochise:backups_c
	if $? != 0; then
		echo $(date +"%Y%m%d %H:%M:%S")" ERROR during rclone sync gdrive-concari:backups_c gdrive-cochise:backups_c"
		bash /home/jfc/scripts/telegram-message.sh "Borg rclone sync" "ERROR during" "rclone sync gdrive-concari:backups_c gdrive-cochise:backups_c" > /dev/null
		exit 1
	fi

#	CONCARI_C to COCHISE_UNKNOW
echo $(date +"%Y%m%d %H:%M:%S")" SYNC: gdrive-concari:backups_c to gdrive-cochise-unknow:backups_c"
rclone sync gdrive-concari:backups_c gdrive-cochise-unknow:backups_c
	if $? != 0; then
		echo $(date +"%Y%m%d %H:%M:%S")" ERROR during rclone sync gdrive-concari:backups_c gdrive-cochise-unknow:backups_c"
		bash /home/jfc/scripts/telegram-message.sh "Borg rclone sync" "ERROR during" "rclone sync gdrive-concari:backups_c gdrive-cochise-unknow:backups_c" > /dev/null
		exit 1
	fi

exit 0
