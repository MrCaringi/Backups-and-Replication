#!/bin/bash

###############################
#               RCLONE Cloud Replica
#   This script is for RCLONE SYNC your publics clouds
#
##   HOW TO USE IT (in a Cron Job)
#	    0 12 * * * bash /path/rclone_sync2.sh /path/to/rclone_sync2.json
#
##  PARAMETERS
#   $1  Path to ".json" config file
#
##   REQUIREMENTS
#       - rclone remotes propperly configured 
#
##	RSYNC CONFIGURATION File !!!!
#   Please see https://github.com/MrCaringi/borg/tree/master/replication/rclone for a example of "rclone_sync2.json" file
#
#
##	SCRIPT MODIFICATION NOTES
#       2021-07-07  First version
#       2021-07-09  Fixing documentation
#
###############################

##      Getting the Configuration
#   General Config
    DEBUG=`cat $1 | jq --raw-output '.config.Debug'`
    WAIT=`cat $1 | jq --raw-output '.config.Wait'`
    INSTANCES=`cat $1 | jq --raw-output '.config.Instances'`
	ENABLE_MESSAGE=`cat $1 | jq --raw-output '.config.EnableMessage'`
    SEND_MESSAGE=`cat $1 | jq --raw-output '.config.SendMessage'`
    SEND_FILE=`cat $1 | jq --raw-output '.config.SendFile'`


#   Start
    echo "################################################"
    echo "#                                              #"
    echo "#       STARTING RCLONE REPLICATION            #"
    echo "#                                              #"
    echo "################################################"

##  Time to RCLONE
    N=`jq '.folders | length ' $1`
    i=0
    process=0

	#   For Debug purposes
		[ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	SEND_MESSAGE:"$SEND_MESSAGE
		[ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	SEND_FILE:"$SEND_FILE
		[ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	ENABLE_MESSAGE:"$ENABLE_MESSAGE
		[ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	DEBUG:"$DEBUG
		[ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	FOLDER LENGTH:"$N
        [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	INSTANCES:"$INSTANCES
        [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	process:"$process
	
    #	CHECKING FOR ANOTHER INSTANCES
        echo "===================================================="
        echo "checking for another intances"
        [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	Testing: ps aux | grep "rclone_sync2" | grep -v grep: " && ps aux | grep "rclone_sync2" | grep -v grep
        [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	Testing: ps aux | grep "rclone_sync2" | grep -v grep | wc -l: " && ps aux | grep "rclone_sync2" | grep -v grep | wc -l
        
        process=$(ps aux | grep "rclone_sync2" | grep -v grep | wc -l)

        [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"  Qty process: " $process

        if [ $process -gt ${INSTANCES} ]; then
                echo $(date +"%Y%m%d %H:%M:%S")"    ERROR: another instance already running"
                #   Notify
                [ $ENABLE_MESSAGE == true ] && bash $SEND_MESSAGE "#RCLONE_Replica" "ERROR: another instance already running" "Qty process: $process / Instances Allowed: $INSTANCES " >/dev/null 2>&1 
                exit 1
            else
                echo $(date +"%Y%m%d %H:%M:%S")"    INFO: no other instance is running"
        fi

    while [ $i -lt $N ]
    do
        echo "================================================"
        I=$((i+1))
        echo $(date +%Y%m%d-%H%M%S)"	Task: ${I} of ${N}"
        
		#	Getting From/To Directory
        DIR_O=`cat $1 | jq --raw-output ".folders[$i].From"`
        DIR_D=`cat $1 | jq --raw-output ".folders[$i].To"`
        echo $(date +%Y%m%d-%H%M%S)"	Starting RCLONE from: ${DIR_O} to: ${DIR_D}"
        
		#   For Debug purposes
            [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	DIR_O:"$DIR_O
            [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	DIR_D:"$DIR_D
            [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	DIR:"$DIR
            [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	N="$N
            [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	i="$i        
        
        #   Notify
        [ $ENABLE_MESSAGE == true ] && bash $SEND_MESSAGE "#RCLONE_Replica" "RCLONE from: ${DIR_O} to: ${DIR_D}" "Task: ${I} of ${N}" >/dev/null 2>&1 
        
		#   Building the log file
		rand=$((1000 + RANDOM % 8500))
		#	RCLONE
		rclone sync ${DIR_O} ${DIR_D} --log-file=rclone-log_${rand}.log
		#	If rclone failed/warned notify
        if [ $? -ne 0 ]; then
            echo $(date +%Y%m%d-%H%M%S)"	ERROR RCLONE from: ${DIR_O} to: ${DIR_D}"
            [ $ENABLE_MESSAGE == true ] && bash $SEND_MESSAGE "#RCLONE_Replica" "ERROR during RSYNCing Task: ${I} of ${N}" "from: ${DIR_O} to: ${DIR_D}" >/dev/null 2>&1
        fi
		#   Sending the File to Telegram
		bash $SEND_FILE "RCLONE Replica" "Log for ${DIR_O} to: ${DIR_D}, Task: ${I} of ${N}" rclone-log_${rand}.log >/dev/null 2>&1
		#   Flushing & Deleting the file
		rm rclone-log_${rand}.log
		sleep $WAIT
        echo $(date +%Y%m%d-%H%M%S)"	Finished RCLONE from: ${DIR_O} to: ${DIR_D}"
        i=$(($i + 1))
    done
    
##   The end
    echo $(date +%Y%m%d-%H%M%S)"	RCLONE Finished Task: ${I} of ${N}"
    [ $ENABLE_MESSAGE == true ] && bash $SEND_MESSAGE "#RCLONE_Replica" "Finished" >/dev/null 2>&1
    echo "################################################"
    echo "#                                              #"
    echo "#       FINISHED RCLONE REPLICATION            #"
    echo "#                                              #"
    echo "################################################"

    exit 0
