#!/bin/sh

###############################
#   v1.0
#           BORG-BACKUP SCRIPT
#
#	sh borg-b.sh borg-b.json
#
#	Parametros
#	1 $1 - .json file for configuration
# 
#	Modification Log
#		2020-04-24  First version
#		2020-04-25  Uploaded a GitHub version
#       2021-08-06  v0.3    Disable PRUNE Option
#       2021-08-07  v0.4    Enable "--prefix PREFIX" for Pruning
#       2021-08-13  v1.0    Feature: All-in-One code refactor
#
###############################

##      Getting the Configuration
    #   General Config
    DEBUG=`cat $1 | jq --raw-output '.GeneralConfig.Debug'`
    WAIT=`cat $1 | jq --raw-output '.GeneralConfig.Wait'`
    
    #   Telegram Config
    ENABLE_MESSAGE=`cat $1 | jq --raw-output '.Telegram.Enable'`
    CHAT_ID=`cat $1 | jq --raw-output '.Telegram.ChatID'`
    API_KEY=`cat $1 | jq --raw-output '.Telegram.APIkey'`

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
        https://api.telegram.org/bot${API_KEY}/sendDocument
}

#   Start
    echo "################################################"
    echo "#                                              #"
    echo "#       STARTING BORG BACKUP SCRIPT            #"
    echo "#                v1.0                          #"
    echo "#                                              #"
    echo "################################################"
    #   General Start time
        TIME_START=$(date +%s)
        DATE_START=$(date +%F)
    #   Setting Loop variables
    N=`jq '.Task | length ' $1`
    i=0
	#   For Debug purposes
        [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	DEBUG:"$DEBUG
        [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	WAIT:"$WAIT
        [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	ENABLE_MESSAGE:"$ENABLE_MESSAGE
        [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	CHAT_ID:"$CHAT_ID
        [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	API_KEY:"$API_KEY
        [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	Task Qty:"$N

#   Entering into the Loop
    while [ $i -lt $N ]
        do
            echo "================================================"
            I=$((i+1))
            echo $(date +%Y%m%d-%H%M%S)"	Task: ${I} of ${N}"
            #   Iteration time
                TIMEi_START=$(date +%s)
                DATEi_START=$(date +%F)

            #	Getting Task Configuration
            REPO=`cat $1 | jq --raw-output ".Task[$i].Repository"`
            BORG_PASSPHRASE=`cat $1 | jq --raw-output ".Task[$i].BorgPassphrase"`
            ARCHIVE_PATH=`cat $1 | jq --raw-output ".Task[$i].ArchivePath"`
            PREFIX=`cat $1 | jq --raw-output ".Task[$i].PREFIX"`
            COMPRESSION=`cat $1 | jq --raw-output ".Task[$i].Compression"`
            FILTER=`cat $1 | jq --raw-output ".Task[$i].Filter"`
            PRUNE_ENABLE=`cat $1 | jq --raw-output ".Task[$i].Prune.Enable"`
            PRUNE_KEEPDAILY=`cat $1 | jq --raw-output ".Task[$i].Prune.KeepDaily"`
            PRUNE_KEEPWEEKLY=`cat $1 | jq --raw-output ".Task[$i].Prune.KeepWeekly"`
            PRUNE_KEEPMONTHLY=`cat $1 | jq --raw-output ".Task[$i].Prune.KeepMonthly"`

            #   For Debug purposes
                [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	REPO:"$REPO
                [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	BORG_PASSPHRASE:"$BORG_PASSPHRASE
                [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	ARCHIVE_PATH:"$ARCHIVE_PATH
                [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	PREFIX:"$PREFIX
                [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	COMPRESSION:"$COMPRESSION
                [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	FILTER:"$FILTER
                [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	PRUNE_ENABLE="$PRUNE_ENABLE
                [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	PRUNE_KEEPDAILY="$PRUNE_KEEPDAILY 
                [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	PRUNE_KEEPMONTHLY="$PRUNE_KEEPMONTHLY
                [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	N="$N
                [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	i="$i  

exit 1


            echo $(date +%Y%m%d-%H%M%S)"	Starting RCLONE from: ${DIR_O} to: ${DIR_D}"
            
                  
            
            #   Notify
            [ $ENABLE_MESSAGE == true ] && TelegramSendMessage "#RCLONE_Replica" "Task: ${I} of ${N}" "RCLONE from: ${DIR_O} to: ${DIR_D}" >/dev/null 2>&1 
            
            #   Initializing the log file
                LOG_DATE="task_${I}_$(date +%Y%m%d-%H%M%S)"
                [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	LOG_DATE:"$LOG_DATE
                touch log_${LOG_DATE}.log
                if [ $? -ne 0 ]; then
                    echo $(date +%Y%m%d-%H%M%S)"	ERROR: could not create log file: log_${LOG_DATE}.log"
                    [ $ENABLE_MESSAGE == true ] && TelegramSendMessage "#RCLONE_Replica" "#ERROR: could not create log file: log_${LOG_DATE}.log" >/dev/null 2>&1
                fi

            #	RCLONE
            rclone sync ${DIR_O} ${DIR_D} --drive-server-side-across-configs=${DriveServerSide} --max-transfer=${MaxTransfer} --bwlimit=${BwLimit} --log-file=log_${LOG_DATE}.log
            
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

            #   Verifying which type of message to be sent (log file or message only)
                lenght=`wc -c log_${LOG_DATE}.log | awk '{print $1}'`
                [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	log file lenght: "$lenght

                if [ $lenght -gt 0 ]; then
                    [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	Log has info"
                    [ $ENABLE_MESSAGE == true ] && TelegramSendFile "#RCLONE_Replica" "Task: ${I} of ${N}, Log for ${DIR_O} to: ${DIR_D}, Elapsed time: ${DAYSi_ELAPSE}d ${TIMEi_ELAPSE}" log_${LOG_DATE}.log >/dev/null 2>&1
                else
                    [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	Log has no info, sending message"
                    [ $ENABLE_MESSAGE == true ] && TelegramSendMessage "#RCLONE_Replica" "Task: ${I} of ${N}, From ${DIR_O} to: ${DIR_D}" "Elapsed time: ${DAYSi_ELAPSE}d ${TIMEi_ELAPSE}" >/dev/null 2>&1
                fi
                
            #   Flushing & Deleting the file
                rm log_${LOG_DATE}.log
            sleep $WAIT
            echo $(date +%Y%m%d-%H%M%S)"	Finished RCLONE from: ${DIR_O} to: ${DIR_D}"
            i=$(($i + 1))
        done
    





















===============================================================================================
#	Asignacion de Variables
    TITLE="${1}-$(date +"%Y%m%d")"
    REP=${2}
    ORI=${3}
    D=${4}
    W=${5}
    M=${6}
    P=${7}

#	Ruta de repositorio + nombre de backup
FULLREP="${REP}::${TITLE}"

#	Parametros
#
#   PASSPHRASE='password'
#   
. /home/jfc/scripts/borg.conf

echo "=============================================================================="

# Setting this, so the repo does not need to be given on the command line:
export BORG_REPO=$REP

# Setting this, so you won't be asked for your repository passphrase:
export BORG_PASSPHRASE=${PASSPHRASE}

# some helpers and error handling:
info() { printf "\n%s %s\n\n" "$( date )" "$*"; }
trap 'echo $( date ) Backup interrupted ; exit 2' INT TERM

info "Starting backup"
echo $(date +%Y%m%d-%H%M)" Starting backup of ${TITLE}"
bash /home/jfc/scripts/telegram-message.sh "#Borg_Backup" "Repo: #${TITLE}" "Starting backup" > /dev/null 2>&1

# Backup the most important directories into an archive named after
# the machine this script is currently running on:

##  Running the backup and capturing the output to a variable
#   log variable will be used to sent the log via telegram
log_create=`borg create --stats --list --filter=E --compression auto,lzma,9 ${FULLREP} ${ORI} 2>&1`

backup_exit=$?
echo $(date +%Y%m%d-%H%M)" P=${P}"
#   Verify if PRUNE is disabled
if [[ "$P" == "NP" ]]; then
    info "Pruning disabled"
    echo $(date +%Y%m%d-%H%M)" Pruning disabled for repo ${TITLE}: P=${P}"
    bash /home/jfc/scripts/telegram-message.sh "#Borg_Backup" "Repo: #${TITLE}" "Pruning Disabled" > /dev/null 2>&1

    else
        info "Pruning repository"
        echo $(date +%Y%m%d-%H%M)" Pruning repository of ${TITLE}"
        bash /home/jfc/scripts/telegram-message.sh "#Borg_Backup" "Repo: #${TITLE}" "Pruning repository" > /dev/null 2>&1 2>&1

        ###     PRUNE
        if [ $backup_exit -eq 0 ]; then
            log_prune=`borg prune -v -s --list --prefix ${1} --keep-daily=$D --keep-weekly=$W --keep-monthly=$M $REP 2>&1`
            prune_exit=$?
        else
            echo $(date +%Y%m%d-%H%M)" Backup not completed, skip Pruning of ${TITLE}"    
        fi
fi
# use highest exit code as global exit code
global_exit=$(( backup_exit > prune_exit ? backup_exit : prune_exit ))

if [ ${global_exit} -eq 0 ]; then
    info "Backup and Prune finished successfully"
    echo $(date +%Y%m%d-%H%M)" Backup and Prune finished successfully"
	bash /home/jfc/scripts/telegram-message.sh "#Borg_Backup" "Repo: #${TITLE}" "Backup and Prune finished #successfully" > /dev/null 2>&1
elif [ ${global_exit} -eq 1 ]; then
    info "Backup and/or Prune finished with warnings"
    echo $(date +%Y%m%d-%H%M)" Backup and/or Prune finished with warnings"
	bash /home/jfc/scripts/telegram-message.sh "#Borg_Backup" "Repo: #${TITLE}" "Backup and/or Prune finished with #warnings" > /dev/null 2>&1
else
    info "Backup and/or Prune finished with errors"
    echo $(date +%Y%m%d-%H%M)" Backup and/or Prune finished with errors"
	bash /home/jfc/scripts/telegram-message.sh "#Borg_Backup" "Repo: #${TITLE}" "Backup and/or Prune finished with #errors" > /dev/null 2>&1
fi

##  Sending log to Telegram
#   Building the log file
rand=$((10 + RANDOM % 89))
echo "========== BORG CREATE" >> ${TITLE}_${rand}.log
echo "$log_create" >> ${TITLE}_${rand}.log
echo >> ${TITLE}_${rand}.log
echo "========== BORG PRUNE" >> ${TITLE}_${rand}.log
echo $(date +"%Y%m%d %HH%MM%SS") >> ${TITLE}_${rand}.log
echo >> ${TITLE}_${rand}.log
echo "$log_prune" >> ${TITLE}_${rand}.log
echo "========== END          $(date +"%Y%m%d %HH%MM%SS")" >> ${TITLE}_${rand}.log

#   Sending the File to Telegram
bash /home/jfc/scripts/telegram-message-file.sh "#Borg_Backup Repo: #${TITLE}" "Log File" ${TITLE}_${rand}.log > /dev/null 2>&1

#   Flushing & Deleting the file
cat ${TITLE}_${rand}.log
rm ${TITLE}_${rand}.log

exit ${global_exit}



=======================================================================

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
#       2021-08-06  v0.4.2.3    including DAYS in Elapsed time in notification
#       2021-08-09  v0.5.1    Enable server-side-config and max-tranfer quota
#       2021-08-10  v1.0.1.1      All-in-one
#       2021-08-11  v1.1      Feature: Bandwidth limit
#
###############################

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
        https://api.telegram.org/bot${API_KEY}/sendDocument
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
        [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	BwLimit:"$BwLimit


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
        
		#   Initializing the log file
            LOG_DATE="task_${I}_$(date +%Y%m%d-%H%M%S)"
            [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	LOG_DATE:"$LOG_DATE
            touch log_${LOG_DATE}.log
            if [ $? -ne 0 ]; then
                echo $(date +%Y%m%d-%H%M%S)"	ERROR: could not create log file: log_${LOG_DATE}.log"
                [ $ENABLE_MESSAGE == true ] && TelegramSendMessage "#RCLONE_Replica" "#ERROR: could not create log file: log_${LOG_DATE}.log" >/dev/null 2>&1
            fi

		#	RCLONE
		rclone sync ${DIR_O} ${DIR_D} --drive-server-side-across-configs=${DriveServerSide} --max-transfer=${MaxTransfer} --bwlimit=${BwLimit} --log-file=log_${LOG_DATE}.log
		
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

        #   Verifying which type of message to be sent (log file or message only)
            lenght=`wc -c log_${LOG_DATE}.log | awk '{print $1}'`
            [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	log file lenght: "$lenght

            if [ $lenght -gt 0 ]; then
                [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	Log has info"
                [ $ENABLE_MESSAGE == true ] && TelegramSendFile "#RCLONE_Replica" "Task: ${I} of ${N}, Log for ${DIR_O} to: ${DIR_D}, Elapsed time: ${DAYSi_ELAPSE}d ${TIMEi_ELAPSE}" log_${LOG_DATE}.log >/dev/null 2>&1
            else
                [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	Log has no info, sending message"
                [ $ENABLE_MESSAGE == true ] && TelegramSendMessage "#RCLONE_Replica" "Task: ${I} of ${N}, From ${DIR_O} to: ${DIR_D}" "Elapsed time: ${DAYSi_ELAPSE}d ${TIMEi_ELAPSE}" >/dev/null 2>&1
            fi
            
        #   Flushing & Deleting the file
            rm log_${LOG_DATE}.log
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