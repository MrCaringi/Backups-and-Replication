#!/bin/bash

###############################
#               RCLONE Cloud Replica
#
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
#       2021-08-04  v0.4.1  Elapsed time in notification
#       2021-08-06  v0.4.2.3    including DAYS in Elapsed time in notification
#       2021-08-09  v0.5.1    Enable server-side-config and max-tranfer quota
#       2021-08-10  v1      All-in-one
#
###############################

##      Getting the Configuration
    #   General Config
    DEBUG=`cat $1 | jq --raw-output '.config.Debug'`
    WAIT=`cat $1 | jq --raw-output '.config.Wait'`
    INSTANCE_FILE=`cat $1 | jq --raw-output '.config.InstanceFile'`
    DriveServerSide=`cat $1 | jq --raw-output '.config.DriveServerSide'`
    MaxTransfer=`cat $1 | jq --raw-output '.config.MaxTransfer'`

    #   Telegram Config
    ENABLE_MESSAGE=`cat $1 | jq --raw-output '.telegram.Enable'`
    CHAT_ID=`cat $1 | jq --raw-output '.telegram.ChatID'`
    API_KEY=`cat $1 | jq --raw-output '.telegram.APIkey'`

##  Telegram Notification Functions
    function TelegramSendMessage(){
        #   Variables
            HEADER=${1}
            LINE1=${2}
            LINE2=${3}

        curl -s \
        --data parse_mode=HTML \
        --data chat_id=${CHAT_ID} \
        --data text="<b>${1}</b>%0A      <i>from <b>#`hostname`</b></i>%0A%0A${2}%0A${3}" \
        "https://api.telegram.org/bot${API_KEY}/sendMessage"
    }

    function TelegramSendFile(){
        #   Variables
        HEADER=${1}
        LINE1=${2}
        FILE=${3}
        HOSTNAME=`hostname`

        curl -v -4 -F \
        "chat_id=${CHAT_ID}" \
        -F document=@${FILE} \
        -F caption="${HEADER}"$'\n'"        from: #${HOSTNAME}"$'\n'"${LINE1}" \
        https://api.telegram.org/bot$API_KEY/sendDocument
}

#   Start
    echo "################################################"
    echo "#                                              #"
    echo "#       STARTING RCLONE REPLICATION            #"
    echo "#                                              #"
    echo "################################################"
    #   General Start time
        TIME_START=$(date +%s)
        DATE_START=$(date +%F)

##  Time to RCLONE
    N=`jq '.folders | length ' $1`
    i=0
    process=0
    lenght=0

	#   For Debug purposes
		[ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	CHAT_ID:"$CHAT_ID
		[ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	API_KEY:"$API_KEY
		[ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	ENABLE_MESSAGE:"$ENABLE_MESSAGE
		[ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	DEBUG:"$DEBUG
		[ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	FOLDER LENGTH:"$N
        [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	INSTANCE_FILE:"$INSTANCE_FILE
        [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	process:"$process
        [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	DriveServerSide:"$DriveServerSide
        [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	MaxTransfer:"$MaxTransfer


    #	CHECKING FOR ANOTHER INSTANCES
        echo "===================================================="
        echo "checking for another intances"

        if [ -f ${INSTANCE_FILE}  ];then
            echo $(date +"%Y%m%d %H:%M:%S")"    ERROR: An another instance of this script is already running, if it not right, please remove the file $INSTANCE_FILE"
            [ $ENABLE_MESSAGE == true ] && TelegramSendMessage "#RCLONE_Replica" "#ERROR: there is another instance of this script is already running" "please remove the file $INSTANCE_FILE" >/dev/null 2>&1 
            exit 1
            else
                echo $(date +"%Y%m%d %H:%M:%S")"    INFO: NO another instance is running. No $INSTANCE_FILE file was found."
        fi
        #   Creating the *.temp file
        echo $(date +"%Y%m%d %H:%M:%S")"    INFO: creating the $INSTANCE_FILE file."
        touch $INSTANCE_FILE
        if [ $? -ne 0 ]; then
            echo $(date +%Y%m%d-%H%M%S)"	ERROR: could not create $INSTANCE_FILE"
            [ $ENABLE_MESSAGE == true ] && TelegramSendMessage "#RCLONE_Replica" "#ERROR could not create" "$INSTANCE_FILE file" >/dev/null 2>&1
            exit 1
        fi

    while [ $i -lt $N ]
    do
        echo "================================================"
        I=$((i+1))
        echo $(date +%Y%m%d-%H%M%S)"	Task: ${I} of ${N}"
        #   Iteration time
            TIMEi_START=$(date +%s)
            DATEi_START=$(date +%F)

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
        [ $ENABLE_MESSAGE == true ] && TelegramSendMessage "#RCLONE_Replica" "Task: ${I} of ${N}" "RCLONE from: ${DIR_O} to: ${DIR_D}" >/dev/null 2>&1 
        
		#   Building the log file
		rand=$((1000 + RANDOM % 8500))

		#	RCLONE
		rclone sync ${DIR_O} ${DIR_D} --log-file=rclone-log_${rand}.log --drive-server-side-across-configs=${DriveServerSide} --max-transfer=${MaxTransfer}
		
        #	If rclone failed/warned notify
        if [ $? -ne 0 ]; then
            echo $(date +%Y%m%d-%H%M%S)"	ERROR RCLONE from: ${DIR_O} to: ${DIR_D}"
            [ $ENABLE_MESSAGE == true ] && TelegramSendMessage "#RCLONE_Replica" "Task: ${I} of ${N}, #ERROR during RSYNCing" "from: ${DIR_O} to: ${DIR_D}" >/dev/null 2>&1
        fi
        #   Elapsed time calculation for the iteration
            TIMEi_END=$(date +%s)
            TIMEi_ELAPSE=$(date -u -d "0 $TIMEi_END seconds - $TIMEi_START seconds" +"%T")
            DATEi_END=$(date +%F)
            DAYSi_ELAPSE=$(( ($(date -d $DATEi_END +%s) - $(date -d $DATEi_START +%s) )/(60*60*24) ))

            [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	Iteration Elapsed time: ${DAYSi_ELAPSE}d ${TIMEi_ELAPSE}"

        #   Verifying which type of message to be sent (log or message only)
            lenght=`wc -c rclone-log_${rand}.log | awk '{print $1}'`
            [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	log file lenght: "$lenght

            if [ $lenght -gt 0 ]; then
                [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	Log has info"
                [ $ENABLE_MESSAGE == true ] && TelegramSTelegramSendFile "#RCLONE_Replica" "Task: ${I} of ${N}, Log for ${DIR_O} to: ${DIR_D}, Elapsed time:${DAYSi_ELAPSE}d ${TIMEi_ELAPSE}" rclone-log_${rand}.log >/dev/null 2>&1
            else
                [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	Log has no info, sending message"
                [ $ENABLE_MESSAGE == true ] && TelegramSendMessage "#RCLONE_Replica" "Task: ${I} of ${N}, From ${DIR_O} to: ${DIR_D}" "Elapsed time: ${DAYSi_ELAPSE}d ${TIMEi_ELAPSE}" >/dev/null 2>&1
            fi
		#   Sending the File to Telegram
            
            #   Log message not sent
            
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
            [ $ENABLE_MESSAGE == true ] && TelegramSendMessage "#RCLONE_Replica" "#ERROR could not remove" "$INSTANCE_FILE file" >/dev/null 2>&1
            exit 1
        fi
    #   Elapsed time calculation for the Main Program
        TIME_END=$(date +%s);
        TIME_ELAPSE=$(date -u -d "0 $TIME_END seconds - $TIME_START seconds" +"%T")
        DATE_END=$(date +%F)
        DAYS_ELAPSE=$(( ($(date -d $DATE_END +%s) - $(date -d $DATE_START +%s) )/(60*60*24) ))
        [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	General Elapsed time: ${DAYS_ELAPSE}d ${TIME_ELAPSE}"
    [ $ENABLE_MESSAGE == true ] && TelegramSendMessage "#RCLONE_Replica" "Finished" "Elapsed time: ${DAYS_ELAPSE}d ${TIME_ELAPSE}" >/dev/null 2>&1
    echo "################################################"
    echo "#                                              #"
    echo "#       FINISHED RCLONE REPLICATION            #"
    echo "#                                              #"
    echo "################################################"

    exit 0