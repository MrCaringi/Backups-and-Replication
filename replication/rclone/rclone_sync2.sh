#!/bin/bash

###############################
#               RCLONE Cloud Replica
#   version 0.2
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
#       2021-07-18  v0.2    Improved telegram messages
#       2021-07-21  v0.3    Improving concurrence instances validation
#       2021-07-29  v0.4    New Feature:    Time Elapsed included in logs and notification
#
###############################

##      Getting the Configuration
#   General Config
    DEBUG=`cat $1 | jq --raw-output '.config.Debug'`
    WAIT=`cat $1 | jq --raw-output '.config.Wait'`
    INSTANCE_FILE=`cat $1 | jq --raw-output '.config.InstanceFile'`
	ENABLE_MESSAGE=`cat $1 | jq --raw-output '.config.EnableMessage'`
    SEND_MESSAGE=`cat $1 | jq --raw-output '.config.SendMessage'`
    SEND_FILE=`cat $1 | jq --raw-output '.config.SendFile'`


#   Start
    echo "################################################"
    echo "#                                              #"
    echo "#       STARTING RCLONE REPLICATION            #"
    echo "#                                              #"
    echo "################################################"
    #   General Start time
        TIME_START=$(date +%s)

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
        [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	INSTANCE_FILE:"$INSTANCE_FILE
        [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	process:"$process
	
    #	CHECKING FOR ANOTHER INSTANCES
        echo "===================================================="
        echo "checking for another intances"

        if [ -f ${INSTANCE_FILE}  ];then
            echo $(date +"%Y%m%d %H:%M:%S")"    ERROR: An another instance of this script is already running, if it not right, please remove the file $INSTANCE_FILE"
            [ $ENABLE_MESSAGE == true ] && bash $SEND_MESSAGE "#RCLONE_Replica" "#ERROR: there is another instance of this script is already running" "please remove the file $INSTANCE_FILE" >/dev/null 2>&1 
            exit 1
            else
                echo $(date +"%Y%m%d %H:%M:%S")"    INFO: NO another instance is running. No $INSTANCE_FILE file was found."
        fi
        #   Creating the *.temp file
        echo $(date +"%Y%m%d %H:%M:%S")"    INFO: creating the $INSTANCE_FILE file."
        touch $INSTANCE_FILE
        if [ $? -ne 0 ]; then
            echo $(date +%Y%m%d-%H%M%S)"	ERROR: could not create $INSTANCE_FILE"
            [ $ENABLE_MESSAGE == true ] && bash $SEND_MESSAGE "#RCLONE_Replica" "#ERROR could not create" "$INSTANCE_FILE file" >/dev/null 2>&1
            exit 1
        fi

    while [ $i -lt $N ]
    do
        echo "================================================"
        I=$((i+1))
        echo $(date +%Y%m%d-%H%M%S)"	Task: ${I} of ${N}"
        #   Iteration time
            TIMEi_START=$(date +%s)

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
        [ $ENABLE_MESSAGE == true ] && bash $SEND_MESSAGE "#RCLONE_Replica" "Task: ${I} of ${N}" "RCLONE from: ${DIR_O} to: ${DIR_D}" >/dev/null 2>&1 
        
		#   Building the log file
		rand=$((1000 + RANDOM % 8500))
		#	RCLONE
		rclone sync ${DIR_O} ${DIR_D} --log-file=rclone-log_${rand}.log
		#	If rclone failed/warned notify
        if [ $? -ne 0 ]; then
            echo $(date +%Y%m%d-%H%M%S)"	ERROR RCLONE from: ${DIR_O} to: ${DIR_D}"
            [ $ENABLE_MESSAGE == true ] && bash $SEND_MESSAGE "#RCLONE_Replica" "Task: ${I} of ${N}, #ERROR during RSYNCing" "from: ${DIR_O} to: ${DIR_D}" >/dev/null 2>&1
        fi
        #   Elapse time calculation for the iteration
            TIMEi_END=$(date +%s);
            TIMEi_ELAPSE=$(date -u -d "0 $TIMEi_END seconds - $TIMEi_START seconds" +"%H:%M:%S")
            [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	Iteration Elapse time: "$TIMEi_ELAPSE
		#   Sending the File to Telegram
		    bash $SEND_FILE "RCLONE Replica" "Task: ${I} of ${N}, Log for ${DIR_O} to: ${DIR_D}, Elapse time: $TIMEi_ELAPSE" rclone-log_${rand}.log >/dev/null 2>&1
		#   Flushing & Deleting the file
		    rm rclone-log_${rand}.log
		sleep $WAIT
        echo $(date +%Y%m%d-%H%M%S)"	Finished RCLONE from: ${DIR_O} to: ${DIR_D}"
        i=$(($i + 1))
    done
    
##   The end
    echo $(date +%Y%m%d-%H%M%S)"	RCLONE Finished Task: ${I} of ${N}"
    #   Deleting the *.temp file
        echo $(date +"%Y%m%d %H:%M:%S")"    INFO: Deleting the $INSTANCE_FILE file."
        rm $INSTANCE_FILE
        if [ $? -ne 0 ]; then
            echo $(date +%Y%m%d-%H%M%S)"	ERROR: could not remove $INSTANCE_FILE"
            [ $ENABLE_MESSAGE == true ] && bash $SEND_MESSAGE "#RCLONE_Replica" "#ERROR could not remove" "$INSTANCE_FILE file" >/dev/null 2>&1
            exit 1
        fi
    #   Elapse time calculation for the iteration
        TIME_END=$(date +%s);
        TIME_ELAPSE=$(date -u -d "0 $TIME_END seconds - $TIME_START seconds" +"%H:%M:%S")
        [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	General Elapse time: "$TIMEi_ELAPSE
    [ $ENABLE_MESSAGE == true ] && bash $SEND_MESSAGE "#RCLONE_Replica" "Finished" "Elapse time: $TIME_ELAPSE" >/dev/null 2>&1
    echo "################################################"
    echo "#                                              #"
    echo "#       FINISHED RCLONE REPLICATION            #"
    echo "#                                              #"
    echo "################################################"

    exit 0
