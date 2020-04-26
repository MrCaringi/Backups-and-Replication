#!/bin/bash

if pidof -o %PPID -x “rclone-sync.sh”; then
	echo "ERROR: another instance already running"
	exit 1
fi
	echo "SYNC: local to gdrive-santi:backups/"
	rclone sync /mnt/iscsi-borg/ gdrive-santi:backups/
	echo "SYNC: gdrive-santi:backups/ to onedrive-yahoo:borg/"
	rclone sync gdrive-santi:backups/ onedrive-yahoo:borg/
exit
