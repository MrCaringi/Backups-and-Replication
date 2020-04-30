#!/bin/sh

###############################
#  RSYNC Replica
#
#   HOW TO USE (put it in crontab)
#	    0 12 * * * sh /path/rsync_replica.sh >> /path/log.log
#
#   REQUIREMENTS
#       - to be able to ssh to host without password (it requires a proper ssh configuration: SSH PUB KEY Configuration)
#       - RSYNC daemon should be available on destination
#       - "sshpass" packacge is needed
#
#	Modification Log
#       2020-04-28  First version
#       2020-04-29  testing version releases	
#
#
###############################

##	RSYNC CONFIGURATION
#   It must include:
#   SSHPASS=passphrase      - ssh password in order to shutdown the remote when finish
#   RSYNCUSER=rsync-user    - rsync user
#   RSYNCPASS=passphrase    - rsync password
#   HOST=NAS                - hostname indicated in .ssh/config
#   IPRSYNC=10.0.0.15       - Rsync server/NAS IP
#   IP=10.0.0.0             - Network Address (not the remote IP address) for WOL command
#   MAC=00:00:00:00:00      - remote MAC address for WOL command
#   MIN=5                   - Minutes to wait after WOL
. /home/jfc/scripts/rsync.conf

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

sshpass -p $RSYNCPASS rsync -aq --append-verify /mnt/iscsi-borg $RSYNCUSER@$IPRSYNC::borg
if $? != 0; then
	echo $(date +%Y%m%d-%H%M)" ERROR RSYNC /mnt/iscsi-borg"
    bash /home/jfc/scripts/telegram-message.sh "RSYNC Replica" "ERROR during RSYNC" "/mnt/iscsi-borg"
    sleep 20
    echo $SSHPASS | ssh -tt quiltra "shutdown -h now"
    exit 1
fi

sshpass -p $RSYNCPASS rsync -aq --append-verify /mnt/nostromo-Music $RSYNCUSER@$IPRSYNC::music
if $? != 0; then
	echo $(date +%Y%m%d-%H%M)" ERROR RSYNC /mnt/nostromo-Music"
    bash /home/jfc/scripts/telegram-message.sh "RSYNC Replica" "ERROR during RSYNC" "/mnt/nostromo-Music"
    sleep 20
    echo $SSHPASS | ssh -tt quiltra "shutdown -h now"
    exit 1
fi

sshpass -p $RSYNCPASS rsync -aq --append-verify /mnt/nostromo-photo $RSYNCUSER@$IPRSYNC::photo
if $? != 0; then
	echo $(date +%Y%m%d-%H%M)" ERROR RSYNC /mnt/nostromo-photo"
    bash /home/jfc/scripts/telegram-message.sh "RSYNC Replica" "ERROR during RSYNC" "/mnt/nostromo-photo"
    sleep 20
    echo $SSHPASS | ssh -tt quiltra "shutdown -h now"
    exit 1
fi

sshpass -p $RSYNCPASS rsync -aq --append-verify /mnt/nostromo-video $RSYNCUSER@$IPRSYNC::video
if $? != 0; then
	echo $(date +%Y%m%d-%H%M)" ERROR RSYNC /mnt/nostromo-video"
    bash /home/jfc/scripts/telegram-message.sh "RSYNC Replica" "ERROR during RSYNC" "/mnt/nostromo-video"
    sleep 20
    echo $SSHPASS | ssh -tt quiltra "shutdown -h now"
    exit 1
fi

##   Turning off remote device
echo $(date +%Y%m%d-%H%M)" INFO RSYNC successfully done on $IP"
bash /home/jfc/scripts/telegram-message.sh "RSYNC Replica" "RSYNC successfully done" "of $IP"
sleep 5
echo $SSHPASS | ssh -tt quiltra "shutdown -h now"
sleep 5
exit 0