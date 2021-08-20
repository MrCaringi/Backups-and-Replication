#!/bin/bash

###############################
#       v1.0.1
#           BORG-BACKUP SCRIPT
#
#   How to Use
#	    bash borg-b.sh borg-b.json
#
#	Paremeters
#	    1 $1 - .json file for configuration
#
#   Requirements
#       - jq    Package for json data parsing
#
#	Modification Log
#		2020-04-24  First version
#		2020-04-25  Uploaded a GitHub version
#       2021-08-06  v0.3    Disable PRUNE Option
#       2021-08-07  v0.4    Enable "--prefix PREFIX" for Pruning
#       2021-08-19  v1.0.1    Feature: All-in-One code refactor
#
###############################

##      In First place: verify Input and "jq" package
        #   Input Parameter
        if [ $# -eq 0 ]
            then
                echo $(date +%Y%m%d-%H%M%S)"	ERROR: Input Parameter is EMPTY!"
                exit 1
            else
                echo $(date +%Y%m%d-%H%M%S)"	INFO: Argument found: ${1}"
        fi
        #   Package Exist
        dpkg -s jq &> /dev/null
        if [ $? -eq 0 ] ; then
                echo $(date +%Y%m%d-%H%M%S)"	INFO: Package jq is present"
            else
                echo $(date +%Y%m%d-%H%M%S)"	ERROR: Package jq is not present!"
                exit 1
        fi

##      Getting the Main Configuration
    #   General Config
    DEBUG=`cat $1 | jq --raw-output '.GeneralConfig.Debug'`
    WAIT=`cat $1 | jq --raw-output '.GeneralConfig.Wait'`
    
    #   Telegram Config
    ENABLE_MESSAGE=`cat $1 | jq --raw-output '.Telegram.Enable'`
    CHAT_ID=`cat $1 | jq --raw-output '.Telegram.ChatID'`
    API_KEY=`cat $1 | jq --raw-output '.Telegram.APIkey'`

##  Functions
    function TelegramSendMessage(){
        #   Variables
        HEADER=${1}
        LINE1=${2}
        LINE2=${3}
        LINE3=${4}

        curl -s \
        --data parse_mode=HTML \
        --data chat_id=${CHAT_ID} \
        --data text="<b>${HEADER}</b>%0A      <i>from <b>#`hostname`</b></i>%0A%0A${LINE1}%0A${LINE2}%0A${LINE3}" \
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

    function package_exists(){
        dpkg -s "$1" &> /dev/null
        return $?
    }

##   Start
    echo "################################################"
    echo "#                                              #"
    echo "#       STARTING BORG BACKUP SCRIPT            #"
    echo "#                 v1.0.1                       #"
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
        [ $DEBUG == true ] && echo "================================================"

#   Entering into the Loop
    while [ $i -lt $N ]
        do
            I=$((i+1))
            #	Getting Task Configuration
                BORG_REPO=`cat $1 | jq --raw-output ".Task[$i].Repository"`
                BORG_PASSPHRASE=`cat $1 | jq --raw-output ".Task[$i].BorgPassphrase"`
                PREFIX=`cat $1 | jq --raw-output ".Task[$i].Prefix"`
            #   Borg Create vars
                CREATE_ENABLE=`cat $1 | jq --raw-output ".Task[$i].BorgCreate.Enable"`
                CREATE_ARCHIVE=`cat $1 | jq --raw-output ".Task[$i].BorgCreate.ArchivePath"`
                CREATE_OPTIONS=`cat $1 | jq --raw-output ".Task[$i].BorgCreate.Options"`
            #   Borg Prune vars
                PRUNE_ENABLE=`cat $1 | jq --raw-output ".Task[$i].BorgPrune.Enable"`
                PRUNE_OPTIONS=`cat $1 | jq --raw-output ".Task[$i].BorgPrune.Options"`
            #   Borg Check vars
                CHECK_ENABLE=`cat $1 | jq --raw-output ".Task[$i].BorgCheck.Enable"`
                CHECK_OPTIONS=`cat $1 | jq --raw-output ".Task[$i].BorgCheck.Options"`

            #   Setting up Main vars
                FULLREP="${BORG_REPO}::${PREFIX}_$(date +"%Y%m%d-%H%M%S")"
                # Setting this, so the repo does not need to be given on the command line:
                export BORG_REPO
                # Setting this, so you won't be asked for your repository passphrase:
                export BORG_PASSPHRASE

            #   For Debug purposes
                [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	Printing Current Configuration"
                [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	BORG_REPO:"$BORG_REPO
                [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	BORG_PASSPHRASE:"$BORG_PASSPHRASE
                [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	PREFIX:"$PREFIX
                [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	CREATE_ENABLE:"$CREATE_ENABLE
                [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	CREATE_ARCHIVE:"$CREATE_ARCHIVE
                [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	CREATE_OPTIONS="$CREATE_OPTIONS
                [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	PRUNE_ENABLE="$PRUNE_ENABLE
                [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	PRUNE_OPTIONS="$PRUNE_OPTIONS
                [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	CHECK_ENABLE="$CHECK_ENABLE
                [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	CHECK_OPTIONS="$CHECK_OPTIONS
                [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	FULLREP="$FULLREP
                [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	N="$N
                [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	i="$i
            
            #   Borg Create
                if [ $CREATE_ENABLE == true ]; then
                    #   Initial Notification
                        echo "================================================"
                        echo $(date +%Y%m%d-%H%M%S)"	Starting BORG CREATE BACKUP Task: ${I} of ${N}"
                        echo $(date +%Y%m%d-%H%M%S)"	CREATE Repository ${BORG_REPO}, Archive Path: ${CREATE_ARCHIVE}"
                        echo $(date +%Y%m%d-%H%M%S)"	CREATE Backup full name: ${FULLREP}"
                        echo $(date +%Y%m%d-%H%M%S)"	CREATE Options: ${CREATE_OPTIONS}"
                        [ $ENABLE_MESSAGE == true ] && TelegramSendMessage "#BORG #CREATE_Backup" "Starting Task: ${I} of ${N}" "Repository: ${BORG_REPO}" "Archive: ${CREATE_ARCHIVE}" >/dev/null 2>&1 
                    #   Starting Iteration time
                        TIMEi_START=$(date +%s)
                        DATEi_START=$(date +%F)
                    
                    #   Initializing the log file
                        LOG_DATE="task_${I}_$(date +%Y%m%d-%H%M%S)"
                        [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	LOG_DATE:"$LOG_DATE
                        touch BORG_log_${LOG_DATE}.log
                        if [ $? -ne 0 ]; then
                            echo $(date +%Y%m%d-%H%M%S)"	ERROR: could not create log file: BORG_log_${LOG_DATE}.log"
                            [ $ENABLE_MESSAGE == true ] && TelegramSendMessage "#BORG #CREATE_Backup" "#ERROR: could not create log file: BORG_log_${LOG_DATE}.log" >/dev/null 2>&1
                        fi
                        echo "==========    BORG CREATE        Task: ${I} of ${N}" >> BORG_log_${LOG_DATE}.log
                        echo >> BORG_log_${LOG_DATE}.log

                    ##   Borg Create Command
                        borg create ${CREATE_OPTIONS} ${FULLREP} ${CREATE_ARCHIVE} >> BORG_log_${LOG_DATE}.log 2>&1
                        borg_exit=$?
                    
                    #   Elapsed time calculation for the iteration
                        TIMEi_END=$(date +%s)
                        TIMEi_ELAPSE=$(date -u -d "0 $TIMEi_END seconds - $TIMEi_START seconds" +"%T")
                        DATEi_END=$(date +%F)
                        DAYSi_ELAPSE=$(( ($(date -d $DATEi_END +%s) - $(date -d $DATEi_START +%s) )/(60*60*24) ))
                        echo >> BORG_log_${LOG_DATE}.log
                        echo "==========    BORG BACKUP        Elapsed time: ${DAYSi_ELAPSE}d ${TIMEi_ELAPSE}" >> BORG_log_${LOG_DATE}.log

                    # Use highest exit code to build the message
                        if [ ${borg_exit} -eq 0 ]; then
                            echo $(date +%Y%m%d-%H%M%S)" Backup finished successfully"
                            [ $ENABLE_MESSAGE == true ] && TelegramSendMessage "#BORG #CREATE_Backup" "Task: ${I} of ${N}" "Backup finished #successfully" "Elapsed time: ${DAYSi_ELAPSE}d ${TIMEi_ELAPSE}" > /dev/null 2>&1
                            [ $ENABLE_MESSAGE == true ] && TelegramSendFile "#BORG #CREATE_Backup" "Log File for Task ${I} of ${N}" BORG_log_${LOG_DATE}.log > /dev/null 2>&1
                        elif [ ${borg_exit} -eq 1 ]; then
                            echo $(date +%Y%m%d-%H%M%S)" Backup finished with warnings"
                            [ $ENABLE_MESSAGE == true ] && TelegramSendMessage "#BORG #CREATE_Backup" "Task: ${I} of ${N}" "Backup finished with #warnings" "Elapsed time: ${DAYSi_ELAPSE}d ${TIMEi_ELAPSE}" > /dev/null 2>&1
                            [ $ENABLE_MESSAGE == true ] && TelegramSendFile "#BORG #CREATE_Backup" "Log File for Task ${I} of ${N}" BORG_log_${LOG_DATE}.log > /dev/null 2>&1
                        else
                            echo $(date +%Y%m%d-%H%M%S)" Backup finished with Error"
                            [ $ENABLE_MESSAGE == true ] && TelegramSendMessage "#BORG #CREATE_Backup" "Task: ${I} of ${N}" "Backup finished with #Error" "Elapsed time: ${DAYSi_ELAPSE}d ${TIMEi_ELAPSE}" > /dev/null 2>&1
                            [ $ENABLE_MESSAGE == true ] && TelegramSendFile "#BORG #CREATE_Backup" "Log File for Task ${I} of ${N}" BORG_log_${LOG_DATE}.log > /dev/null 2>&1
                        fi

                    #   Flushing & Deleting the file
                        rm BORG_log_${LOG_DATE}.log
                
                #   No Backup Enabled
                    else
                        echo "================================================"
                        echo $(date +%Y%m%d-%H%M%S)"	BORG CREATE BACKUP is disabled for Task: ${I} of ${N}"
                        [ $ENABLE_MESSAGE == true ] && TelegramSendMessage "#BORG #CREATE_Backup" "Create Backup is disable for Task ${I} of ${N}" "Repository: ${BORG_REPO}" >/dev/null 2>&1
                sleep $WAIT
                fi

            #   Borg Prune
                if [ $PRUNE_ENABLE == true ]; then
                    #   Initial Notification
                        echo "================================================"
                        echo $(date +%Y%m%d-%H%M%S)"	Starting BORG PRUNE BACKUP Task: ${I} of ${N}"
                        echo $(date +%Y%m%d-%H%M%S)"	PRUNE Repository ${BORG_REPO}"
                        echo $(date +%Y%m%d-%H%M%S)"	PRUNE Options: ${PRUNE_OPTIONS}"
                        echo $(date +%Y%m%d-%H%M%S)"	PRUNE PREFIX: ${PREFIX}"
                        [ $ENABLE_MESSAGE == true ] && TelegramSendMessage "#BORG #PRUNE_Backup" "Starting Task: ${I} of ${N}" "Repository: ${BORG_REPO}" "Prune PREFIX: ${PREFIX}" >/dev/null 2>&1 
                    #   Starting Iteration time
                        TIMEi_START=$(date +%s)
                        DATEi_START=$(date +%F)
                    
                    #   Initializing the log file
                        LOG_DATE="task_${I}_$(date +%Y%m%d-%H%M%S)"
                        [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	LOG_DATE:"$LOG_DATE
                        touch BORG_log_${LOG_DATE}.log
                        if [ $? -ne 0 ]; then
                            echo $(date +%Y%m%d-%H%M%S)"	ERROR: could not create log file: BORG_log_${LOG_DATE}.log"
                            [ $ENABLE_MESSAGE == true ] && TelegramSendMessage "#BORG #PRUNE_Backup" "#ERROR: could not create log file: BORG_log_${LOG_DATE}.log" >/dev/null 2>&1
                        fi
                        echo "==========    BORG PRUNE        Task: ${I} of ${N}" >> BORG_log_${LOG_DATE}.log
                        echo >> BORG_log_${LOG_DATE}.log

                    ##   Borg Prune Command
                        borg prune --prefix ${PREFIX} ${PRUNE_OPTIONS} ${BORG_REPO} >> BORG_log_${LOG_DATE}.log 2>&1
                        borg_exit=$?
                    
                    #   Elapsed time calculation for the iteration
                        TIMEi_END=$(date +%s)
                        TIMEi_ELAPSE=$(date -u -d "0 $TIMEi_END seconds - $TIMEi_START seconds" +"%T")
                        DATEi_END=$(date +%F)
                        DAYSi_ELAPSE=$(( ($(date -d $DATEi_END +%s) - $(date -d $DATEi_START +%s) )/(60*60*24) ))
                        echo >> BORG_log_${LOG_DATE}.log
                        echo "==========    BORG PRUNE        Elapsed time: ${DAYSi_ELAPSE}d ${TIMEi_ELAPSE}" >> BORG_log_${LOG_DATE}.log

                    # Use highest exit code to build the message
                        if [ ${borg_exit} -eq 0 ]; then
                            echo $(date +%Y%m%d-%H%M%S)" Prune finished successfully"
                            [ $ENABLE_MESSAGE == true ] && TelegramSendMessage "#BORG #PRUNE_Backup" "Task: ${I} of ${N}" "Prune finished #successfully" "Elapsed time: ${DAYSi_ELAPSE}d ${TIMEi_ELAPSE}" > /dev/null 2>&1
                            [ $ENABLE_MESSAGE == true ] && TelegramSendFile "#BORG #PRUNE_Backup" "Log File for Task ${I} of ${N}" BORG_log_${LOG_DATE}.log > /dev/null 2>&1
                        elif [ ${borg_exit} -eq 1 ]; then
                            echo $(date +%Y%m%d-%H%M%S)" Prune finished with warnings"
                            [ $ENABLE_MESSAGE == true ] && TelegramSendMessage "#BORG #PRUNE_Backup" "Task: ${I} of ${N}" "Prune finished with #warnings" "Elapsed time: ${DAYSi_ELAPSE}d ${TIMEi_ELAPSE}" > /dev/null 2>&1
                            [ $ENABLE_MESSAGE == true ] && TelegramSendFile "#BORG #PRUNE_Backup" "Log File for Task ${I} of ${N}" BORG_log_${LOG_DATE}.log > /dev/null 2>&1
                        else
                            echo $(date +%Y%m%d-%H%M%S)" Prune finished with Error"
                            [ $ENABLE_MESSAGE == true ] && TelegramSendMessage "#BORG #PRUNE_Backup" "Task: ${I} of ${N}" "Prune finished with #Error" "Elapsed time: ${DAYSi_ELAPSE}d ${TIMEi_ELAPSE}" > /dev/null 2>&1
                            [ $ENABLE_MESSAGE == true ] && TelegramSendFile "#BORG #PRUNE_Backup" "Log File for Task ${I} of ${N}" BORG_log_${LOG_DATE}.log > /dev/null 2>&1
                        fi

                    #   Flushing & Deleting the file
                        rm BORG_log_${LOG_DATE}.log
                
                #   No Prune Enabled
                    else
                        echo "================================================"
                        echo $(date +%Y%m%d-%H%M%S)"	BORG PRUNE is disabled for Task: ${I} of ${N}"
                        [ $ENABLE_MESSAGE == true ] && TelegramSendMessage "#BORG #PRUNE_Backup" "Prune Backup is disable for Task ${I} of ${N}" "Repository: ${BORG_REPO}" >/dev/null 2>&1 
                sleep $WAIT
                fi

            #   Borg Check
                if [ $CHECK_ENABLE == true ]; then
                    #   Initial Notification
                        echo "================================================"
                        echo $(date +%Y%m%d-%H%M%S)"	Starting BORG CHECK BACKUP Task: ${I} of ${N}"
                        echo $(date +%Y%m%d-%H%M%S)"	CHECK Repository ${BORG_REPO}"
                        echo $(date +%Y%m%d-%H%M%S)"	CHECK Options: ${CHECK_OPTIONS}"
                        echo $(date +%Y%m%d-%H%M%S)"	CHECK PREFIX: ${PREFIX}"
                        [ $ENABLE_MESSAGE == true ] && TelegramSendMessage "#BORG #CHECK_Backup" "Starting Task: ${I} of ${N}" "Repository: ${BORG_REPO}" "Check PREFIX: ${PREFIX}" >/dev/null 2>&1 
                    #   Starting Iteration time
                        TIMEi_START=$(date +%s)
                        DATEi_START=$(date +%F)
                    
                    #   Initializing the log file
                        LOG_DATE="task_${I}_$(date +%Y%m%d-%H%M%S)"
                        [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	LOG_DATE:"$LOG_DATE
                        touch BORG_log_${LOG_DATE}.log
                        if [ $? -ne 0 ]; then
                            echo $(date +%Y%m%d-%H%M%S)"	ERROR: could not create log file: BORG_log_${LOG_DATE}.log"
                            [ $ENABLE_MESSAGE == true ] && TelegramSendMessage "#BORG #CHECK_Backup" "#ERROR: could not create log file: BORG_log_${LOG_DATE}.log" >/dev/null 2>&1
                        fi
                        echo "==========    BORG CHECK        Task: ${I} of ${N}" >> BORG_log_${LOG_DATE}.log
                        echo >> BORG_log_${LOG_DATE}.log

                    ##   Borg Check Command
                        borg check --prefix ${PREFIX} ${CHECK_OPTIONS} ${BORG_REPO} >> BORG_log_${LOG_DATE}.log 2>&1
                        borg_exit=$?
                    
                    #   Elapsed time calculation for the iteration
                        TIMEi_END=$(date +%s)
                        TIMEi_ELAPSE=$(date -u -d "0 $TIMEi_END seconds - $TIMEi_START seconds" +"%T")
                        DATEi_END=$(date +%F)
                        DAYSi_ELAPSE=$(( ($(date -d $DATEi_END +%s) - $(date -d $DATEi_START +%s) )/(60*60*24) ))
                        echo >> BORG_log_${LOG_DATE}.log
                        echo "==========    BORG CHECK        Elapsed time: ${DAYSi_ELAPSE}d ${TIMEi_ELAPSE}" >> BORG_log_${LOG_DATE}.log

                    # Use highest exit code to build the message
                        if [ ${borg_exit} -eq 0 ]; then
                            echo $(date +%Y%m%d-%H%M%S)" Check finished successfully"
                            [ $ENABLE_MESSAGE == true ] && TelegramSendMessage "#BORG #CHECK_Backup" "Task: ${I} of ${N}" "Check finished #successfully" "Elapsed time: ${DAYSi_ELAPSE}d ${TIMEi_ELAPSE}" > /dev/null 2>&1
                            [ $ENABLE_MESSAGE == true ] && TelegramSendFile "#BORG #CHECK_Backup" "Log File for Task ${I} of ${N}" BORG_log_${LOG_DATE}.log > /dev/null 2>&1
                        elif [ ${borg_exit} -eq 1 ]; then
                            echo $(date +%Y%m%d-%H%M%S)" Check finished with warnings"
                            [ $ENABLE_MESSAGE == true ] && TelegramSendMessage "#BORG #CHECK_Backup" "Task: ${I} of ${N}" "Check finished with #warnings" "Elapsed time: ${DAYSi_ELAPSE}d ${TIMEi_ELAPSE}" > /dev/null 2>&1
                            [ $ENABLE_MESSAGE == true ] && TelegramSendFile "#BORG #CHECK_Backup" "Log File for Task ${I} of ${N}" BORG_log_${LOG_DATE}.log > /dev/null 2>&1
                        else
                            echo $(date +%Y%m%d-%H%M%S)" Check finished with Error"
                            [ $ENABLE_MESSAGE == true ] && TelegramSendMessage "#BORG #CHECK_Backup" "Task: ${I} of ${N}" "Check finished with #Error" "Elapsed time: ${DAYSi_ELAPSE}d ${TIMEi_ELAPSE}" > /dev/null 2>&1
                            [ $ENABLE_MESSAGE == true ] && TelegramSendFile "#BORG #CHECK_Backup" "Log File for Task ${I} of ${N}" BORG_log_${LOG_DATE}.log > /dev/null 2>&1
                        fi

                    #   Flushing & Deleting the file
                        rm BORG_log_${LOG_DATE}.log
                
                #   No Check Enabled
                    else
                        echo "================================================"
                        echo $(date +%Y%m%d-%H%M%S)"	BORG CHECK BACKUP is disabled for Task: ${I} of ${N}"
                        [ $ENABLE_MESSAGE == true ] && TelegramSendMessage "#BORG #CHECK_Backup" "CHECK Backup is disable for Task ${I} of ${N}" "Repository: ${BORG_REPO}" >/dev/null 2>&1 
                sleep $WAIT
                fi
                i=$(($i + 1))
        done

##   The end
    echo "================================================"
    echo $(date +%Y%m%d-%H%M%S)"	BORG Finished Task: ${I} of ${N}"
    #   Elapsed time calculation for the Main Program
        TIME_END=$(date +%s);
        TIME_ELAPSE=$(date -u -d "0 $TIME_END seconds - $TIME_START seconds" +"%T")
        DATE_END=$(date +%F)
        DAYS_ELAPSE=$(( ($(date -d $DATE_END +%s) - $(date -d $DATE_START +%s) )/(60*60*24) ))
        [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	General Elapsed time: ${DAYS_ELAPSE}d ${TIME_ELAPSE}"
        [ $ENABLE_MESSAGE == true ] && TelegramSendMessage "#BORG #Finished" "Total Task of ${N}" "Total Elapsed time: ${DAYS_ELAPSE}d ${TIME_ELAPSE}" >/dev/null 2>&1
    echo "################################################"
    echo "#                                              #"
    echo "#       FINISHED BORG BACKUP SCRIPT            #"
    echo "#                 v1.0.1                       #"
    echo "#                                              #"
    echo "################################################"

    exit 0
