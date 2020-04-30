#!/bin/sh

###############################
#  RSYNC Replica
#
#   HOW TO USE (put it in crontab)
#	    0 12 * * * sh /path/rsync_replica.sh >> /path/log.log
#
#   REQUIREMENTS
#       - to be able to ssh to host without password (it requires a proper ssh configuration: SSH PUB KEY Configuration)
#
#
#	Modification Log
#		2020-04-28  First version
#		
#
#
###############################

##	RSYNC CONFIGURATION
#   It must include:
#   SSHPASS=passphrase      - ssh password in order to shutdown the remote when finish
#   RSYNCUSER=rsync-user    - rsync user
#   RSYNCPASS=passphrase    - rsync password
#   HOST=NAS                - hostname indicated in .ssh/config 
#   IP=10.0.0.0             - Network Address (not the remote IP address) for WOL command
#   MAC=00:00:00:00:00      - remote MAC address for WOL command
#   MIN=5                   - Minutes to wait after WOL
. /home/jfc/scripts/rsync.conf

echo SSHPASS $SSHPASS
echo IP $IP
echo MAC $MAC
echo MIN $MIN
echo HOST $HOST

##   Starting WOL
echo "=============================================================================="
echo $(date +%Y%m%d-%H%M)" WOL of device $IP $MAC"
    bash /home/jfc/scripts/telegram-message.sh "RSYNC Replica" "WOL device $IP" > /dev/null

wakeonlan -i 192.168.100.0 00:11:32:44:9B:4B
if $? != 0; then
	echo $(date +%Y%m%d-%H%M)" ERROR during WOL of device $IP $MAC"
    bash /home/jfc/scripts/telegram-message.sh "RSYNC Replica" "ERROR during WOL" "of $IP"
    exit 1
fi

##   Waiting for start up
echo $(date +%Y%m%d-%H%M)" Waiting for Start up $IP $MAC"
sleep ${MIN}m

##  Starting Rsync folders
echo $(date +%Y%m%d-%H%M)" Starting Rsync folders"
bash /home/jfc/scripts/telegram-message.sh "RSYNC Replica" "Starting Rsync folders"

sshpass -p $RSYNCPASS rsync -aq --append-verify /mnt/iscsi-borg $RSYNCUSER@$IP::borg
if $? != 0; then
	echo $(date +%Y%m%d-%H%M)" ERROR RSYNC /mnt/iscsi-borg"
    bash /home/jfc/scripts/telegram-message.sh "RSYNC Replica" "ERROR during RSYNC" "/mnt/iscsi-borg"
    exit 1
fi

sshpass -p $RSYNCPASS rsync -aq --append-verify /mnt/nostromo-Music $RSYNCUSER@$IP::music
if $? != 0; then
	echo $(date +%Y%m%d-%H%M)" ERROR RSYNC /mnt/nostromo-Music"
    bash /home/jfc/scripts/telegram-message.sh "RSYNC Replica" "ERROR during RSYNC" "/mnt/nostromo-Music"
    exit 1
fi

sshpass -p $RSYNCPASS rsync -aq --append-verify /mnt/nostromo-photo $RSYNCUSER@$IP::photo
if $? != 0; then
	echo $(date +%Y%m%d-%H%M)" ERROR RSYNC /mnt/nostromo-photo"
    bash /home/jfc/scripts/telegram-message.sh "RSYNC Replica" "ERROR during RSYNC" "/mnt/nostromo-photo"
    exit 1
fi

sshpass -p $RSYNCPASS rsync -aq --append-verify /mnt/nostromo-video $RSYNCUSER@$IP::video
if $? != 0; then
	echo $(date +%Y%m%d-%H%M)" ERROR RSYNC /mnt/nostromo-video"
    bash /home/jfc/scripts/telegram-message.sh "RSYNC Replica" "ERROR during RSYNC" "/mnt/nostromo-video"
    exit 1
fi

echo $(date +%Y%m%d-%H%M)" ERROR during WOL of device $IP $MAC"
bash /home/jfc/scripts/telegram-message.sh "RSYNC Replica" "ERROR during WOL" "of $IP"

##   Turning off remote device
sleep 20
echo $SSHPASS | ssh -tt quiltra "shutdown -h now"

exit



info "Starting backup"
bash /home/jfc/scripts/telegram-message.sh "Borg Backup" "Repo: ${TITLE}" "Starting backup" > /dev/null

# Backup the most important directories into an archive named after
# the machine this script is currently running on:

borg create -s --compression auto,zlib,5 ${FULLREP} ${ORI}

backup_exit=$?

info "Pruning repository"
bash /home/jfc/scripts/telegram-message.sh "Borg Backup" "Repo: ${TITLE}" "Pruning repository" > /dev/null

# Use the `prune` subcommand to maintain 7 daily, 4 weekly and 6 monthly
# archives of THIS machine. The 'QNAP-' prefix is very important to
# limit prune's operation to this machine's archives and not apply to
# other machines' archives also:

borg prune -v -s --list --keep-daily=$D --keep-weekly=$W --keep-monthly=$M $REP

prune_exit=$?

# use highest exit code as global exit code
global_exit=$(( backup_exit > prune_exit ? backup_exit : prune_exit ))

if [ ${global_exit} -eq 0 ]; then
    info "Backup and Prune finished successfully"
	bash /home/jfc/scripts/telegram-message.sh "Borg Backup" "Repo: ${TITLE}" "Backup and Prune finished successfully" > /dev/null
elif [ ${global_exit} -eq 1 ]; then
    info "Backup and/or Prune finished with warnings"
	bash /home/jfc/scripts/telegram-message.sh "Borg Backup" "Repo: ${TITLE}" "Backup and/or Prune finished with warnings" > /dev/null
else
    info "Backup and/or Prune finished with errors"
	bash /home/jfc/scripts/telegram-message.sh "Borg Backup" "Repo: ${TITLE}" "Backup and/or Prune finished with errors" > /dev/null
fi

exit ${global_exit}
