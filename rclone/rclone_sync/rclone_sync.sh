#!/bin/sh

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
##	RCLONE REPLICA CONFIGURATION File !!!!
#   Please refer to https://github.com/MrCaringi/borg/tree/master/replication/rclone for a example of "rclone_sync2.json" file
#
#
##	SCRIPT MODIFICATION NOTES
#       2021-07-07  First version
#       2021-07-09  Fixing documentation
#       2021-07-18  v0.2    Improved telegram messages
#       2021-07-21  v0.3    Improving concurrence instances validation
#       2021-08-04  v0.4.1  Elapsed time in notification
#       2021-08-06  v0.4.2.3  Including DAYS in Elapsed time in notification
#       2021-08-09  v0.5.1    Enable server-side-config and max-tranfer quota
#       2021-08-10  v1.0.1.1  All-in-one
#       2021-08-11  v1.1      Feature: Bandwidth limit
#       2021-08-23  v1.2      Feature: Task's flags
#       2021-08-31  v1.3.1    Feature: Fewer Messages
#       2021-11-11  v1.4.0    Feature: Smart Dedup
#       2022-01-06  v1.5.0    Fix: Single Task
#       2022-02-15  v1.5.1    Fix: Dedupe Syntax
#
###############################

##  Version vars
    VERSION="v1.5.1"
    VERSION_TEXT="Fix: Dedupe Syntax"
    echo $(date +%Y-%m-%d_%H:%M:%S)"	$VERSION      $VERSION_TEXT"
    
##      In First place: verify Input and "jq" package
        #   Input Parameter
        if [ $# -eq 0 ]
            then
                echo $(date +%Y-%m-%d_%H:%M:%S)"	ERROR: Input Parameter is EMPTY!"
                exit 1
            else
                echo $(date +%Y-%m-%d_%H:%M:%S)"	INFO: Argument found: ${1}"
        fi
        #   Package Exist
        dpkg -s jq &> /dev/null
        if [ $? -eq 0 ] ; then
                echo $(date +%Y-%m-%d_%H:%M:%S)"	INFO: Package jq is present"
            else
                echo $(date +%Y-%m-%d_%H:%M:%S)"	ERROR: Package jq (or dpkg tool) is not present!"
        fi
##      Getting the Configuration
    #   General Config
    DEBUG=`cat $1 | jq --raw-output '.config.Debug'`
    WAIT=`cat $1 | jq --raw-output '.config.Wait'`
    INSTANCE_FILE=`cat $1 | jq --raw-output '.config.InstanceFile'`
    DriveServerSide=`cat $1 | jq --raw-output '.config.DriveServerSide'`
    MaxTransfer=`cat $1 | jq --raw-output '.config.MaxTransfer'`
    BwLimit=`cat $1 | jq --raw-output '.config.BwLimit'`
    
    #   Telegram Config
    ENABLE_MESSAGE=`cat $1 | jq --raw-output '.telegram.Enable'`
    CHAT_ID=`cat $1 | jq --raw-output '.telegram.ChatID'`
    API_KEY=`cat $1 | jq --raw-output '.telegram.APIkey'`

    #   Self-Healing Config
    DedupeFlags=`cat $1 | jq --raw-output '.selfHealingFeatures.DedupeFlags'`


##  Telegram Notification Functions
    function TelegramSendMessage {
        #   Variables
        HEADER=${1}
        LINE1=${2}
        LINE2=${3}
        LINE3=${4}
        LINE4=${5}
        LINE5=${6}
        LINE6=${7}
        LINE7=${8}
        LINE8=${9}
        LINE9=${10}
        LINE10=${11}

        curl -s \
        --data parse_mode=HTML \
        --data chat_id=${CHAT_ID} \
        --data text="<b>${HEADER}</b>%0A      <i>from <b>#`hostname`</b></i>%0A%0A${LINE1}%0A${LINE2}%0A${LINE3}%0A${LINE4}%0A${LINE5}%0A${LINE6}%0A${LINE7}%0A${LINE8}%0A${LINE9}%0A${LINE10}" \
        "https://api.telegram.org/bot${API_KEY}/sendMessage"
    }

    function TelegramSendFile {
        #   Variables
        FILE=${1}
        HEADER=${2}
        LINE1=${3}
        LINE2=${4}
        LINE3=${5}
        LINE4=${6}
        LINE5=${7}
        HOSTNAME=`hostname`

        curl -v -4 -F \
        "chat_id=${CHAT_ID}" \
        -F document=@${FILE} \
        -F caption="${HEADER}"$'\n'"        from: #${HOSTNAME}"$'\n'"${LINE1}"$'\n'"${LINE2}"$'\n'"${LINE3}"$'\n'"${LINE4}"$'\n'"${LINE5}" \
        https://api.telegram.org/bot${API_KEY}/sendDocument
    }

##  Dedup Check functions
    function CheckDuplicatedSource {
        #   Variables
        CONFIG=${1}
        TEXT=${2}
        Result=0
        Nd=0
        j=0
        Nd=`jq '.selfHealingFeatures.SourceDedupeText | length ' $1`
        [ $DEBUG == true ] && echo "    ----------    function CheckDuplicatedSource"
        [ $DEBUG == true ] && echo $(date +%Y-%m-%d_%H:%M:%S)"     N / j:" $Nd $j
        while [ $j -lt $Nd ]
        do
            #   Getting the text to evaluate
            DedupeText=`cat $1 | jq --raw-output ".selfHealingFeatures.SourceDedupeText[$j]"`
            [ $DEBUG == true ] && echo $(date +%Y-%m-%d_%H:%M:%S)"     Using DedupeText (${j}): " ${DedupeText}
            grep -qi "${DedupeText}" ${TEXT}
            if [ $? -eq 0 ]; then
                    [ $DEBUG == true ] && echo $(date +%Y-%m-%d_%H:%M:%S)"     Duplication in Source detected: "${DedupeText}
                    if [ $Result -eq 0 ]; then
                        Result=10
                    fi
                else
                    [ $DEBUG == true ] && echo $(date +%Y-%m-%d_%H:%M:%S)"     DedupeText Not Found!"
            fi
            j=$(($j + 1))
        done
        return ${Result}
    }

    function CheckDuplicatedDestination {
        #   Variables
        CONFIG=${1}
        TEXT=${2}
        Result=0
        Nd=0
        j=0
        Nd=`jq '.selfHealingFeatures.DestinationeDedupeText | length ' $1`
        [ $DEBUG == true ] && echo "    ----------    function CheckDuplicatedDestination"
        [ $DEBUG == true ] && echo $(date +%Y-%m-%d_%H:%M:%S)"     N / j:" $Nd $j
        while [ $j -lt $Nd ]
        do
            #   Getting the text to evaluate
            DedupeText=`cat $1 | jq --raw-output ".selfHealingFeatures.DestinationeDedupeText[$j]"`
            [ $DEBUG == true ] && echo $(date +%Y-%m-%d_%H:%M:%S)"     Using DedupeText (${j}): " ${DedupeText}
            grep -qi "${DedupeText}" ${TEXT}
            if [ $? -eq 0 ]; then
                    [ $DEBUG == true ] && echo $(date +%Y-%m-%d_%H:%M:%S)"     Duplication in Source detected: "${DedupeText}
                    if [ $Result -eq 0 ]; then
                        Result=10
                    fi
                else
                    [ $DEBUG == true ] && echo $(date +%Y-%m-%d_%H:%M:%S)"     DedupeText Not Found!"
            fi
            j=$(($j + 1))
        done

        return ${Result}
    }


#   Start
    echo "################################################"
    echo "#                                              #"
    echo "#       STARTING RCLONE REPLICATION            #"
    echo "#                 ${VERSION}                       #"
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
    BATCH=`echo ${1} | awk -F'/' '{print $NF}'`
    echo $(date +%Y-%m-%d_%H:%M:%S)"	Batch: " $BATCH

	#   For Debug purposes
        [ $DEBUG == true ] && echo $(date +%Y-%m-%d_%H:%M:%S)"	CHAT_ID:"$CHAT_ID
        [ $DEBUG == true ] && echo $(date +%Y-%m-%d_%H:%M:%S)"	API_KEY:"$API_KEY
        [ $DEBUG == true ] && echo $(date +%Y-%m-%d_%H:%M:%S)"	ENABLE_MESSAGE:"$ENABLE_MESSAGE
        [ $DEBUG == true ] && echo $(date +%Y-%m-%d_%H:%M:%S)"	DEBUG:"$DEBUG
        [ $DEBUG == true ] && echo $(date +%Y-%m-%d_%H:%M:%S)"	FOLDER LENGTH:"$N
        [ $DEBUG == true ] && echo $(date +%Y-%m-%d_%H:%M:%S)"	INSTANCE_FILE:"$INSTANCE_FILE
        [ $DEBUG == true ] && echo $(date +%Y-%m-%d_%H:%M:%S)"	process:"$process
        [ $DEBUG == true ] && echo $(date +%Y-%m-%d_%H:%M:%S)"	DriveServerSide:"$DriveServerSide
        [ $DEBUG == true ] && echo $(date +%Y-%m-%d_%H:%M:%S)"	MaxTransfer:"$MaxTransfer
        [ $DEBUG == true ] && echo $(date +%Y-%m-%d_%H:%M:%S)"	BwLimit:"$BwLimit
        [ $DEBUG == true ] && echo $(date +%Y-%m-%d_%H:%M:%S)"	DedupeFlags:"$DedupeFlags



    #	CHECKING FOR ANOTHER INSTANCES
        echo "===================================================="
        echo "checking for another intances"

        if [ -f ${INSTANCE_FILE}  ];then
            echo $(date +%Y-%m-%d_%H:%M:%S)"    ERROR: An another instance of this script is already running, if it not right, please remove the file $INSTANCE_FILE"
            [ $ENABLE_MESSAGE == true ] && TelegramSendMessage "#RCLONE_Replica" "Batch: #$BATCH" "Total Task: ${N}" " " "#ERROR: there is another instance of this script is already running" "please remove the file $INSTANCE_FILE" >/dev/null 2>&1 
            exit 1
            else
                echo $(date +%Y-%m-%d_%H:%M:%S)"     INFO: NO another instance is running. No $INSTANCE_FILE file was found."
        fi
        #   Creating the *.temp file
        echo $(date +%Y-%m-%d_%H:%M:%S)"     INFO: creating the $INSTANCE_FILE file."
        touch $INSTANCE_FILE
        if [ $? -ne 0 ]; then
            echo $(date +%Y-%m-%d_%H:%M:%S)"	ERROR: could not create $INSTANCE_FILE"
            [ $ENABLE_MESSAGE == true ] && TelegramSendMessage "#RCLONE_Replica" "Batch: #$BATCH" " " "#ERROR could not create" "$INSTANCE_FILE file" >/dev/null 2>&1
            exit 1
        fi
    
    #   Notify Version
        [ $ENABLE_MESSAGE == true ] && TelegramSendMessage "#RCLONE_Replica" "#Starting" "Batch: #$BATCH" "Total Task: ${N}" "Release Version: ${VERSION}" >/dev/null 2>&1 

    while [ $i -lt $N ]
    do
        #   Staring VARS
            echo "================================================"
            I=$((i+1))
            echo $(date +%Y-%m-%d_%H:%M:%S)"	Task: ${I} of ${N}"
        #   Iteration time
            TIMEi_START=$(date +%s)
            DATEi_START=$(date +%F)

		#	Getting From/To Directory
            DIR_O=`cat $1 | jq --raw-output ".folders[$i].From"`
            DIR_D=`cat $1 | jq --raw-output ".folders[$i].To"`
            EnableCustomFlags=`cat $1 | jq --raw-output ".folders[$i].EnableCustomFlags"`
            Flags=`cat $1 | jq --raw-output ".folders[$i].Flags"`
            EnableSelfHealing=`cat $1 | jq --raw-output ".folders[$i].EnableSelfHealing"`
            echo $(date +%Y-%m-%d_%H:%M:%S)"	Starting RCLONE from: ${DIR_O} to: ${DIR_D}"
        
		#   For Debug purposes
            [ $DEBUG == true ] && echo $(date +%Y-%m-%d_%H:%M:%S)"	DIR_O:"$DIR_O
            [ $DEBUG == true ] && echo $(date +%Y-%m-%d_%H:%M:%S)"	DIR_D:"$DIR_D
            [ $DEBUG == true ] && echo $(date +%Y-%m-%d_%H:%M:%S)"	DIR:"$DIR
            [ $DEBUG == true ] && echo $(date +%Y-%m-%d_%H:%M:%S)"	N="$N
            [ $DEBUG == true ] && echo $(date +%Y-%m-%d_%H:%M:%S)"	i="$i
            [ $DEBUG == true ] && echo $(date +%Y-%m-%d_%H:%M:%S)"	EnableCustomFlags="$EnableCustomFlags
            [ $DEBUG == true ] && echo $(date +%Y-%m-%d_%H:%M:%S)"	Flags="$Flags
            [ $DEBUG == true ] && echo $(date +%Y-%m-%d_%H:%M:%S)"	EnableSelfHealing="$EnableSelfHealing
        
		#   Initializing the log file
            LOG_DATE="task_${I}_$(date +%Y%m%d-%H%M%S)"
            [ $DEBUG == true ] && echo $(date +%Y-%m-%d_%H:%M:%S)"	LOG_DATE:"$LOG_DATE
            touch log_${LOG_DATE}.log
            if [ $? -ne 0 ]; then
                echo $(date +%Y-%m-%d_%H:%M:%S)"	ERROR: could not create log file: log_${LOG_DATE}.log"
                [ $ENABLE_MESSAGE == true ] && TelegramSendMessage "#RCLONE_Replica" "#ERROR: could not create log file: log_${LOG_DATE}.log" >/dev/null 2>&1
            fi

		##	RCLONE Command
            if [ $EnableCustomFlags == true ]; then
                    #   There is Custom Flags for the task
                    [ $DEBUG == true ] && echo $(date +%Y-%m-%d_%H:%M:%S)"	EnableCustomFlags parameter is enable (true)"
                    rclone sync ${DIR_O} ${DIR_D} ${Flags} --log-file=log_${LOG_DATE}.log
                    #	If rclone failed/warned notify
                    if [ $? -ne 0 ]; then
                        echo $(date +%Y-%m-%d_%H:%M:%S)"	ERROR RCLONE from: ${DIR_O} to: ${DIR_D}"
                        [ $ENABLE_MESSAGE == true ] && TelegramSendMessage "#RCLONE_Replica" "Task: ${I} of ${N}" "#ERROR during Syncing" "from: ${DIR_O} to: ${DIR_D}" >/dev/null 2>&1
                    fi
                else
                    #   No Custom Flags for the task
                    [ $DEBUG == true ] && echo $(date +%Y-%m-%d_%H:%M:%S)"	EnableCustomFlags paremeter is disabled (false)"
                    rclone sync ${DIR_O} ${DIR_D} --drive-server-side-across-configs=${DriveServerSide} --max-transfer=${MaxTransfer} --bwlimit=${BwLimit} --log-file=log_${LOG_DATE}.log
                    #	If rclone failed/warned notify
                    if [ $? -ne 0 ]; then
                        echo $(date +%Y-%m-%d_%H:%M:%S)"	ERROR RCLONE from: ${DIR_O} to: ${DIR_D}"
                        [ $ENABLE_MESSAGE == true ] && TelegramSendMessage "#RCLONE_Replica" "Task: ${I} of ${N}" "#ERROR during Syncing" "from: ${DIR_O} to: ${DIR_D}" >/dev/null 2>&1
                    fi
            fi
        
        #   Smart Self-Healing
            if [ $EnableSelfHealing == true ]; then

                #   Verifying if there is duplicated files in Source
                    CheckDuplicatedSource $1 log_${LOG_DATE}.log
                    if [ $? -eq 10 ]; then
                        [ $DEBUG == true ] && echo $(date +%Y-%m-%d_%H:%M:%S)"	There is duplicated files in Source"
                        touch dedupe_o_log_${LOG_DATE}.log
                        rclone dedupe ${DedupeFlags} ${DIR_O} --log-file=dedupe_o_log_${LOG_DATE}.log
                        [ $ENABLE_MESSAGE == true ] && TelegramSendFile dedupe_o_log_${LOG_DATE}.log "#RCLONE_Replica" " " "Task: ${I} of ${N}" "Dedupe Log for ${DIR_O}"  >/dev/null 2>&1
                        rm dedupe_o_log_${LOG_DATE}.log
                    fi

                #   Verifying if there is duplicated files in Destination
                    CheckDuplicatedDestination $1 log_${LOG_DATE}.log
                    if [ $? -eq 10 ]; then
                        [ $DEBUG == true ] && echo $(date +%Y-%m-%d_%H:%M:%S)"	There is duplicated files in Destination"
                        touch dedupe_d_log_${LOG_DATE}.log
                        rclone dedupe ${DedupeFlags} ${DIR_D} --log-file=dedupe_d_log_${LOG_DATE}.log
                        [ $ENABLE_MESSAGE == true ] && TelegramSendFile dedupe_d_log_${LOG_DATE}.log "#RCLONE_Replica" " " "Task: ${I} of ${N}" "Dedupe Log for ${DIR_D}"  >/dev/null 2>&1
                        rm dedupe_d_log_${LOG_DATE}.log
                    fi
            fi

        #   Elapsed time calculation for the iteration
            TIMEi_END=$(date +%s)
            TIMEi_ELAPSE=$(date -u -d "0 $TIMEi_END seconds - $TIMEi_START seconds" +"%T")
            DATEi_END=$(date +%F)
            DAYSi_ELAPSE=$(( ($(date -d $DATEi_END +%s) - $(date -d $DATEi_START +%s) )/(60*60*24) ))

            [ $DEBUG == true ] && echo $(date +%Y-%m-%d_%H:%M:%S)"	Iteration Elapsed time: ${DAYSi_ELAPSE}d ${TIMEi_ELAPSE}"

        #   Verifying which type of message to be sent (log file or message only)
            lenght=`wc -c log_${LOG_DATE}.log | awk '{print $1}'`
            [ $DEBUG == true ] && echo $(date +%Y-%m-%d_%H:%M:%S)"	log file lenght: "$lenght

            if [ $lenght -gt 0 ]; then
                [ $DEBUG == true ] && echo $(date +%Y-%m-%d_%H:%M:%S)"	Log has info"
                [ $ENABLE_MESSAGE == true ] && TelegramSendFile log_${LOG_DATE}.log "#RCLONE_Replica" " " "Task: ${I} of ${N}" "Log for ${DIR_O} to: ${DIR_D}" "Elapsed time: ${DAYSi_ELAPSE}d ${TIMEi_ELAPSE}"  >/dev/null 2>&1
            else
                [ $DEBUG == true ] && echo $(date +%Y-%m-%d_%H:%M:%S)"	Log has no info, sending message"
                [ $ENABLE_MESSAGE == true ] && TelegramSendMessage "#RCLONE_Replica" "Task: ${I} of ${N}" "From ${DIR_O} to: ${DIR_D}" " " "Elapsed time: ${DAYSi_ELAPSE}d ${TIMEi_ELAPSE}" >/dev/null 2>&1
            fi
            
        #   Flushing & Deleting the file
            rm log_${LOG_DATE}.log
        
		sleep $WAIT
        echo $(date +%Y-%m-%d_%H:%M:%S)"	Finished RCLONE from: ${DIR_O} to: ${DIR_D}"
        i=$(($i + 1))
        
    done
    
##   The end
    echo $(date +%Y-%m-%d_%H:%M:%S)"	RCLONE Finished Task: ${I} of ${N}"
    #   Deleting the *.temp file
        echo $(date +"%Y-%m-%d_%H:%M:%S")"     INFO: Deleting the $INSTANCE_FILE file."
        rm $INSTANCE_FILE
        if [ $? -ne 0 ]; then
            echo $(date +%Y-%m-%d_%H:%M:%S)"	ERROR: could not remove $INSTANCE_FILE"
            [ $ENABLE_MESSAGE == true ] && TelegramSendMessage "#RCLONE_Replica" "#ERROR could not remove" "$INSTANCE_FILE file" >/dev/null 2>&1
            exit 1
        fi
    #   Elapsed time calculation for the Main Program
        TIME_END=$(date +%s);
        TIME_ELAPSE=$(date -u -d "0 $TIME_END seconds - $TIME_START seconds" +"%T")
        DATE_END=$(date +%F)
        DAYS_ELAPSE=$(( ($(date -d $DATE_END +%s) - $(date -d $DATE_START +%s) )/(60*60*24) ))
        [ $DEBUG == true ] && echo $(date +%Y-%m-%d_%H:%M:%S)"	General Elapsed time: ${DAYS_ELAPSE}d ${TIME_ELAPSE}"
        [ $ENABLE_MESSAGE == true ] && TelegramSendMessage "#RCLONE_Replica" "Batch: #$BATCH" "Status: #Finished" "Elapsed time: ${DAYS_ELAPSE}d ${TIME_ELAPSE}" >/dev/null 2>&1
    echo "################################################"
    echo "#                                              #"
    echo "#       FINISHED RCLONE REPLICATION            #"
    echo "#                 ${VERSION}                       #"
    echo "#                                              #"
    echo "################################################"

    exit 0