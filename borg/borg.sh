#!/bin/bash

##############################################################
#
#           BORG-BACKUP SCRIPT
#
#   How to Use
#	    bash borg-b.sh borg-b.json
#
#   How to download and update to the lastest version of this script
#       wget -O borg.sh https://raw.githubusercontent.com/MrCaringi/Backups-and-Replication/master/borg/borg.sh && chmod +x borg.sh
#
#	Paremeters
#	    1 $1 - .json file for configuration
#
#   Requirements
#       - jq    Package for json data parsing
#
##############################################################

##   Current Version
    VERSION="v1.7.0"

##      In First place: verify Input and packages precense
        #   Input Parameter
        if [ $# -eq 0 ]
            then
                echo $(date +%Y%m%d-%H%M%S)"	ERROR: Input Parameter is EMPTY!"
                exit 1
            else
                echo $(date +%Y%m%d-%H%M%S)"	INFO: Argument found: ${1}"
        fi
        #   Packages Validation
            # jq
            which jq &> /dev/null
            if [ $? -eq 0 ] ; then
                    echo $(date +%Y%m%d-%H%M%S)"	INFO: Package jq is present"
                else
                    echo $(date +%Y%m%d-%H%M%S)"	ERROR: Package jq is not present!"
                    exit 1
            fi

            # borg
            which borg &> /dev/null
            if [ $? -eq 0 ] ; then
                    echo $(date +%Y%m%d-%H%M%S)"	INFO: Package borg is present"
                else
                    echo $(date +%Y%m%d-%H%M%S)"	ERROR: Package borg is not present!"
                    exit 1
            fi
##      Setting Emojis
    SYMBOL_DISABLE="🔘"
    SYMBOL_SUCCESS="✅"
    SYMBOL_WARNING="⚠️"
    SYMBOL_ERROR="🔴"

##      Getting the Main Configuration
    #   General Config
    DEBUG=$(cat $1 | jq --raw-output '.GeneralConfig.Debug')
    WAIT=$(cat $1 | jq --raw-output '.GeneralConfig.Wait')
    
    #   Telegram Config
    ENABLE_MESSAGE=`cat $1 | jq --raw-output '.Telegram.Enable'`
    CHAT_ID=`cat $1 | jq --raw-output '.Telegram.ChatID'`
    API_KEY=`cat $1 | jq --raw-output '.Telegram.APIkey'`

##  Functions
    function TelegramSendMessage(){
        #   Variables
        HEADER=${1}

        curl -s \
        --data parse_mode=HTML \
        --data chat_id=${CHAT_ID} \
        --data text="<b>${HEADER}</b>%0A      <i>from <b>#`hostname`</b></i>%0A%0A${2}%0A${3}%0A${4}%0A${5}%0A${6}%0A${7}%0A${8}%0A${9}%0A${10}%0A${11}%0A${12}%0A${13}%0A${14}%0A${15}%0A${16}%0A${17}%0A${18}%0A${19}%0A${20}%0A${21}%0A${22}%0A${23}%0A${24}%0A${25}%0A${26}%0A${27}%0A${28}%0A${29}%0A${30}%0A${31}%0A${32}%0A${33}%0A${34}%0A${35}%0A${36}" \
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
    echo "#                 ${VERSION}                       #"
    echo "#                                              #"
    echo "################################################"

    #   General Start time
        TIME_START=$(date +%s)
        DATE_START=$(date +%F)
    #   Setting Loop variables
        N=`jq '.Task | length ' $1`
        i=0
	#   For Debug purposes
        [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	DEBUG: "$DEBUG
        [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	WAIT: "$WAIT
        [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	ENABLE_MESSAGE: "$ENABLE_MESSAGE
        [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	CHAT_ID: "$CHAT_ID
        [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	API_KEY: "$API_KEY
        [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	Task Qty: "$N
        [ $DEBUG == true ] && echo "================================================"

    #   Printing out the current batch / config file used
        BATCH=`echo ${1} | awk -F'/' '{print $NF}'`
        echo $BATCH
        echo $(date +%Y%m%d-%H%M%S)"	Current Batch/.json: "${1}
        echo $(date +%Y%m%d-%H%M%S)"	Total Tasks: "${N}
        echo "================================================"
        [ $ENABLE_MESSAGE == true ] && TelegramSendMessage "#BORG #${BATCH}" "<i>Starting Batch:</i> <code>${1}</code>" "<i>Total Borg Tasks:</i> <code>${N}</code>" "<i>Release Version:</i> <code>${VERSION}</code>">/dev/null 2>&1

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
            #   Borg Compact vars
                COMPACT_ENABLE=`cat $1 | jq --raw-output ".Task[$i].BorgCompact.Enable"`
                COMPACT_OPTIONS=`cat $1 | jq --raw-output ".Task[$i].BorgCompact.Options"`

            #   Setting up Main vars
                NUMBER_FILES=""
                CREATE_SIZE=""
                CREATE_SIZE_TOTAL=""
                PRUNE_SIZE=""
                PRUNE_SIZE_TOTAL=""
                COMPACT_SIZE=""
                CREATE_STATUS="DISABLED $SYMBOL_DISABLE"
                PRUNE_STATUS="DISABLED $SYMBOL_DISABLE"
                CHECK_STATUS="DISABLED $SYMBOL_DISABLE"
                COMPACT_STATUS="DISABLED $SYMBOL_DISABLE"
                FULLREP="${BORG_REPO}::${PREFIX}_$(date +"%Y%m%d-%H%M%S")"
                # Setting this, so the repo does not need to be given on the command line:
                    export BORG_REPO
                # Setting this, so you won't be asked for your repository passphrase:
                    export BORG_PASSPHRASE
                
                #   JSON Input Variables
                    k=0
                #   Validate if there is variables to be EXPORTed
                    Nexport=`jq '.GeneralConfig.Exports | length ' $1`
                    echo $(date +%Y%m%d-%H%M%S)"	EXPORT Variables Qty: "$Nexport

                    if [ $Nexport -lt 1 ]; then
                        #   No export
                        echo $(date +%Y%m%d-%H%M%S)"	INFO: No EXPORT VARIABLES found in config file: " $1
                    else
                        # at least 1 export
                        echo $(date +%Y%m%d-%H%M%S)"	INFO: Exporting $Nexport variables"
                        echo "------------------------------------------------"
                        while [ $k -lt $Nexport ]
                            do
                                # echo $(date +%Y%m%d-%H%M%S)"	k counter: "$k
                                VARIABLE=`jq -r ".GeneralConfig.Exports[$k] | keys[]" $1`  
                                VALUE=`jq -r ".GeneralConfig.Exports[$k].[]" $1`
                                echo $(date +%Y%m%d-%H%M%S)"	running EXPORT: $VARIABLE=$VALUE"
                                
                                export "${VARIABLE}"="${VALUE}"
                                
                                k=$(($k + 1))
                            done
                            # export -p | grep -i BORG_
                        echo "------------------------------------------------"   
                    fi
            #   For Debug purposes
                [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	Printing Current Configuration"
                [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	BORG_REPO: "$BORG_REPO
                [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	BORG_PASSPHRASE: "$BORG_PASSPHRASE
                [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	PREFIX: "$PREFIX
                [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	CREATE_ENABLE: "$CREATE_ENABLE
                [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	CREATE_ARCHIVE: "$CREATE_ARCHIVE
                [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	CREATE_OPTIONS: "$CREATE_OPTIONS
                [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	PRUNE_ENABLE: "$PRUNE_ENABLE
                [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	PRUNE_OPTIONS: "$PRUNE_OPTIONS
                [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	CHECK_ENABLE: "$CHECK_ENABLE
                [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	CHECK_OPTIONS: "$CHECK_OPTIONS
                [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	COMPACT_ENABLE: "$COMPACT_ENABLE
                [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	COMPACT_OPTIONS: "$COMPACT_OPTIONS
                [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	FULLREP: "$FULLREP
                [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	N: "$N
                [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	i: "$i

            #   Initializing the log file
                LOG_DATE="task_${I}_$(date +%Y%m%d-%H%M%S)"
                [ $DEBUG == true ] && echo $(date +%Y%m%d-%H%M%S)"	LOG_DATE: "$LOG_DATE
                touch BORG_log_${LOG_DATE}.log
                if [ $? -ne 0 ]; then
                    echo $(date +%Y%m%d-%H%M%S)"	ERROR: could not create log file: BORG_log_${LOG_DATE}.log"
                    [ $ENABLE_MESSAGE == true ] && TelegramSendMessage "#BORG #CREATE_Backup" "#ERROR: could not create log file: BORG_log_${LOG_DATE}.log" >/dev/null 2>&1
                fi

            #   Borg Create
                if [ $CREATE_ENABLE == true ]; then
                    #   Initial Notification
                        echo "================================================"
                        echo $(date +%Y%m%d-%H%M%S)"	Starting BORG CREATE BACKUP Task: ${I} of ${N}"
                        echo $(date +%Y%m%d-%H%M%S)"	CREATE Repository ${BORG_REPO}, Archive Path: ${CREATE_ARCHIVE}"
                        echo $(date +%Y%m%d-%H%M%S)"	CREATE Backup full name: ${FULLREP}"
                        echo $(date +%Y%m%d-%H%M%S)"	CREATE Options: ${CREATE_OPTIONS}"
                    #   Starting Iteration time
                        TIMEc_START=$(date +%s)
                        DATEc_START=$(date +%F)
                    
                    #   Initializing the CREATE log file
                        echo "==========    Starting CREATE        Task: ${I} of ${N}" >> BORG_log_${LOG_DATE}.log
                        echo "Options used: "${CREATE_OPTIONS} >> BORG_log_${LOG_DATE}.log
                        echo >> BORG_log_${LOG_DATE}.log

                    ##   Borg Create Command
                        borg create ${CREATE_OPTIONS} ${FULLREP} ${CREATE_ARCHIVE} >> BORG_log_${LOG_DATE}.log 2>&1
                        borg_create_exit=$?
                    
                    #   Elapsed time calculation for the iteration
                        TIMEc_END=$(date +%s)
                        TIMEc_ELAPSE=$(date -u -d "0 $TIMEc_END seconds - $TIMEc_START seconds" +"%T")
                        DATEc_END=$(date +%F)
                        DAYSc_ELAPSE=$(( ($(date -d $DATEc_END +%s) - $(date -d $DATEc_START +%s) )/(60*60*24) ))
                        echo >> BORG_log_${LOG_DATE}.log
                        echo "==========    Ending CREATE        Elapsed time: ${DAYSc_ELAPSE}d ${TIMEc_ELAPSE}" >> BORG_log_${LOG_DATE}.log

                    #   Getting some info from borg create log
                        NUMBER_FILES=$(grep "Number of files:" BORG_log_${LOG_DATE}.log | awk '{print $NF}')
                        echo $(date +%Y%m%d-%H%M%S)"	CREATE Number of Files: ${NUMBER_FILES}"
                        CREATE_SIZE=$(grep "This archive:" BORG_log_${LOG_DATE}.log | awk '{print $(NF-1),$NF}')
                        echo $(date +%Y%m%d-%H%M%S)"	CREATE Size: ${CREATE_SIZE}"
                        CREATE_SIZE_TOTAL=$(grep "All archives:" BORG_log_${LOG_DATE}.log | awk '{print $(NF-1),$NF}')
                        echo $(date +%Y%m%d-%H%M%S)"	CREATE Total Size: ${CREATE_SIZE_TOTAL}"

                    # Borg Create: Use highest exit code to build the message
                        if [ ${borg_create_exit} -eq 0 ]; then
                            echo $(date +%Y%m%d-%H%M%S)" Backup finished successfully"
                            CREATE_STATUS="SUCCESS $SYMBOL_SUCCESS"
                            [ $NUMBER_FILES -eq 0 ] && CREATE_STATUS="WARNING $SYMBOL_WARNING" NUMBER_FILES="#NONE!" PRUNE_ENABLE="false" && echo $(date +%Y%m%d-%H%M%S)"	Disabling BORG PRUNE!"
                        elif [ ${borg_create_exit} -eq 1 ]; then
                            echo $(date +%Y%m%d-%H%M%S)" Backup finished with warnings"
                            CREATE_STATUS="WARNING $SYMBOL_WARNING"
                        else
                            echo $(date +%Y%m%d-%H%M%S)" Backup finished with Error"
                            CREATE_STATUS="ERROR $SYMBOL_ERROR"
                        fi

                #   No Backup Enabled
                    else
                        echo "================================================"
                        echo $(date +%Y%m%d-%H%M%S)"	BORG CREATE BACKUP is disabled for Task: ${I} of ${N}"
                fi

            #   Borg Prune
                if [ $PRUNE_ENABLE == true ]; then
                    #   Initial Notification
                        echo "================================================"
                        echo $(date +%Y%m%d-%H%M%S)"	Starting BORG PRUNE BACKUP Task: ${I} of ${N}"
                        echo $(date +%Y%m%d-%H%M%S)"	PRUNE Repository ${BORG_REPO}"
                        echo $(date +%Y%m%d-%H%M%S)"	PRUNE Options: ${PRUNE_OPTIONS}"
                        echo $(date +%Y%m%d-%H%M%S)"	PRUNE PREFIX: ${PREFIX}"

                    #   Starting Iteration time
                        TIMEp_START=$(date +%s)
                        DATEp_START=$(date +%F)
                    
                    #   Initializing the PRUNE log file
                        echo "==========    Starting PRUNE        Task: ${I} of ${N}" >> BORG_log_${LOG_DATE}.log
                        echo "Options used: "${PRUNE_OPTIONS} >> BORG_log_${LOG_DATE}.log
                        echo "Prune PREFIX: "${PREFIX} >> BORG_log_${LOG_DATE}.log
                        echo >> BORG_log_${LOG_DATE}.log

                    ##   Borg Prune Command
                        borg prune --glob-archives ${PREFIX}* ${PRUNE_OPTIONS} ${BORG_REPO} >> BORG_log_${LOG_DATE}.log 2>&1
                        borg_prune_exit=$?
                    
                    #   Getting some info from borg PRUNE log
                        PRUNE_SIZE=$(grep "Deleted data:" BORG_log_${LOG_DATE}.log | awk '{print $(NF-1),$NF}')
                        echo $(date +%Y%m%d-%H%M%S)"	PRUNE reclaimed space: ${PRUNE_SIZE}"
                        PRUNE_SIZE_TOTAL=$(tail --lines 10 BORG_log_${LOG_DATE}.log | grep "All archives:" | awk '{print $(NF-1),$NF}')
                        echo $(date +%Y%m%d-%H%M%S)"	PRUNE new total Repository size: ${PRUNE_SIZE_TOTAL}"
                    
                    #   Elapsed time calculation for the iteration
                        TIMEp_END=$(date +%s)
                        TIMEp_ELAPSE=$(date -u -d "0 $TIMEp_END seconds - $TIMEp_START seconds" +"%T")
                        DATEp_END=$(date +%F)
                        DAYSp_ELAPSE=$(( ($(date -d $DATEp_END +%s) - $(date -d $DATEp_START +%s) )/(60*60*24) ))
                        echo >> BORG_log_${LOG_DATE}.log
                        echo "==========    Ending PRUNE        Elapsed time: ${DAYSp_ELAPSE}d ${TIMEp_ELAPSE}" >> BORG_log_${LOG_DATE}.log

                    # Use highest exit code to build the message
                        if [ ${borg_prune_exit} -eq 0 ]; then
                            echo $(date +%Y%m%d-%H%M%S)" Prune finished successfully"
                            PRUNE_STATUS="SUCCESS $SYMBOL_SUCCESS"
                        elif [ ${borg_prune_exit} -eq 1 ]; then
                            echo $(date +%Y%m%d-%H%M%S)" Prune finished with warnings"
                            PRUNE_STATUS="WARNING $SYMBOL_WARNING"
                        else
                            echo $(date +%Y%m%d-%H%M%S)" Prune finished with Error"
                            PRUNE_STATUS="ERROR $SYMBOL_ERROR"
                        fi
                
                #   No Prune Enabled
                    else
                        echo "================================================"
                        echo $(date +%Y%m%d-%H%M%S)"	BORG PRUNE is disabled for Task: ${I} of ${N}"
                fi

            #   Borg Check
                if [ $CHECK_ENABLE == true ]; then
                    #   Initial Notification
                        echo "================================================"
                        echo $(date +%Y%m%d-%H%M%S)"	Starting BORG CHECK BACKUP Task: ${I} of ${N}"
                        echo $(date +%Y%m%d-%H%M%S)"	CHECK Repository ${BORG_REPO}"
                        echo $(date +%Y%m%d-%H%M%S)"	CHECK Options: ${CHECK_OPTIONS}"
                        echo $(date +%Y%m%d-%H%M%S)"	CHECK PREFIX: ${PREFIX}"
                    #   Starting Iteration time
                        TIMEk_START=$(date +%s)
                        DATEk_START=$(date +%F)
                    
                    #   Borg CHECK: Initializing the log file
                        echo "==========    Starting CHECK        Task: ${I} of ${N}" >> BORG_log_${LOG_DATE}.log
                        echo "Options used: "${CHECK_OPTIONS} >> BORG_log_${LOG_DATE}.log
                        echo >> BORG_log_${LOG_DATE}.log

                    ##   Borg Check Command
                        borg check ${CHECK_OPTIONS} ${BORG_REPO} >> BORG_log_${LOG_DATE}.log 2>&1
                        borg_check_exit=$?
                    
                    #   Elapsed time calculation for the iteration
                        TIMEk_END=$(date +%s)
                        TIMEk_ELAPSE=$(date -u -d "0 $TIMEk_END seconds - $TIMEk_START seconds" +"%T")
                        DATEk_END=$(date +%F)
                        DAYSk_ELAPSE=$(( ($(date -d $DATEk_END +%s) - $(date -d $DATEk_START +%s) )/(60*60*24) ))
                        echo >> BORG_log_${LOG_DATE}.log
                        echo "==========    Ending CHECK        Elapsed time: ${DAYSk_ELAPSE}d ${TIMEk_ELAPSE}" >> BORG_log_${LOG_DATE}.log

                    # Use highest exit code to build the message
                        if [ ${borg_check_exit} -eq 0 ]; then
                            echo $(date +%Y%m%d-%H%M%S)" Check finished successfully"
                            CHECK_STATUS="SUCCESS $SYMBOL_SUCCESS"
                        elif [ ${borg_check_exit} -eq 1 ]; then
                            echo $(date +%Y%m%d-%H%M%S)" Check finished with warnings"
                            CHECK_STATUS="WARNING $SYMBOL_WARNING"
                        else
                            echo $(date +%Y%m%d-%H%M%S)" Check finished with Error"
                            CHECK_STATUS="ERROR $SYMBOL_ERROR"
                        fi

                #   No Check Enabled
                    else
                        echo "================================================"
                        echo $(date +%Y%m%d-%H%M%S)"	BORG CHECK BACKUP is disabled for Task: ${I} of ${N}"
                fi

            #   Borg Compact
                if [ $COMPACT_ENABLE == true ]; then
                    #   Initial Notification
                        echo "================================================"
                        echo $(date +%Y%m%d-%H%M%S)"	Starting BORG COMPACT Task: ${I} of ${N}"
                        echo $(date +%Y%m%d-%H%M%S)"	CHECK Repository ${BORG_REPO}"
                        echo $(date +%Y%m%d-%H%M%S)"	CHECK Options: ${COMPACT_OPTIONS}"
                        echo $(date +%Y%m%d-%H%M%S)"	CHECK PREFIX: ${PREFIX}"
                    #   Starting Iteration time
                        TIMEt_START=$(date +%s)
                        DATEt_START=$(date +%F)
                    
                    #   Borg COMPACT: Initializing the log file
                        echo "==========    Starting COMPACT        Task: ${I} of ${N}" >> BORG_log_${LOG_DATE}.log
                        echo "Options used: "${COMPACT_OPTIONS} >> BORG_log_${LOG_DATE}.log
                        echo >> BORG_log_${LOG_DATE}.log

                    ##   Borg Compact Command
                        borg compact ${COMPACT_OPTIONS} ${BORG_REPO} >> BORG_log_${LOG_DATE}.log 2>&1
                        borg_compact_exit=$?
                    
                    #   Getting some info from borg COMPACT log
                        COMPACT_SIZE=$(grep "compaction freed about" BORG_log_${LOG_DATE}.log | awk '{print $4,$5}')
                        echo $(date +%Y%m%d-%H%M%S)"	Compaction freed about: ${PRUNE_SIZE}"

                    #   Elapsed time calculation for the iteration
                        TIMEt_END=$(date +%s)
                        TIMEt_ELAPSE=$(date -u -d "0 $TIMEt_END seconds - $TIMEt_START seconds" +"%T")
                        DATEt_END=$(date +%F)
                        DAYSt_ELAPSE=$(( ($(date -d $DATEt_END +%s) - $(date -d $DATEt_START +%s) )/(60*60*24) ))
                        echo >> BORG_log_${LOG_DATE}.log
                        echo "==========    Ending COMPACT        Elapsed time: ${DAYSt_ELAPSE}d ${TIMEt_ELAPSE}" >> BORG_log_${LOG_DATE}.log

                    # Use highest exit code to build the message
                        if [ ${borg_compact_exit} -eq 0 ]; then
                            echo $(date +%Y%m%d-%H%M%S)" Compact finished successfully"
                            COMPACT_STATUS="SUCCESS $SYMBOL_SUCCESS"
                        elif [ ${borg_compact_exit} -eq 1 ]; then
                            echo $(date +%Y%m%d-%H%M%S)" Compact finished with warnings"
                            COMPACT_STATUS="WARNING $SYMBOL_WARNING"
                        else
                            echo $(date +%Y%m%d-%H%M%S)" Compact finished with Error"
                            COMPACT_STATUS="ERROR  $SYMBOL_ERROR"
                        fi

                #   No Compact Enabled
                    else
                        echo "================================================"
                        echo $(date +%Y%m%d-%H%M%S)"	BORG COMPACT is disabled for Task: ${I} of ${N}"
                fi
                
                #   Building Telegram Messages
                    REPO=`echo ${BORG_REPO} | awk -F'/' '{print $NF}'`
                    [ $ENABLE_MESSAGE == true ] && TelegramSendMessage "#BORG #${REPO}" "Task Resume: ${I} of ${N}" "Task Prefix: #${PREFIX}" "Task Repository: <code>${BORG_REPO}</code>" " " "<strong>Borg Create Status: #${CREATE_STATUS}</strong>" "<i>Elapsed Time:</i> ${DAYSc_ELAPSE}d ${TIMEc_ELAPSE}" "<i>Files:</i> ${NUMBER_FILES}" "<i>Deduplicated Size:</i> ${CREATE_SIZE}" "<i>Total Size:</i> ${CREATE_SIZE_TOTAL}" " " "<strong>Borg Prune Status: #${PRUNE_STATUS}</strong>" "<i>Elapsed Time:</i> ${DAYSp_ELAPSE}d ${TIMEp_ELAPSE}" "<i>Reclaimed Space:</i> ${PRUNE_SIZE}" "<i>Total Size:</i> ${PRUNE_SIZE_TOTAL}" " " "<strong>Borg Check Status: #${CHECK_STATUS}</strong>" "<i>Elapsed Time:</i> ${DAYSk_ELAPSE}d ${TIMEk_ELAPSE}" " " "<strong>Borg Compact Status: #${COMPACT_STATUS}</strong>" "<i>Compaction freed about: ${COMPACT_SIZE}</i>" "<i>Elapsed Time:</i> ${DAYSt_ELAPSE}d ${TIMEt_ELAPSE}" > /dev/null 2>&1
                    [ $ENABLE_MESSAGE == true ] && TelegramSendFile "#BORG #${REPO}" "Log File for Task: ${I} of ${N}" BORG_log_${LOG_DATE}.log > /dev/null 2>&1
                    rm BORG_log_${LOG_DATE}.log
                sleep ${WAIT}
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
        
        [ $ENABLE_MESSAGE == true ] && TelegramSendMessage "#BORG #${BATCH}" "<strong>Batch Ended</strong>" "<i>Total Borg Tasks:</i> <code>${N}</code>" "<i>Total Elapsed time:</i> <code>${DAYS_ELAPSE}d ${TIME_ELAPSE}</code>" >/dev/null 2>&1

    echo "################################################"
    echo "#                                              #"
    echo "#       FINISHED BORG BACKUP SCRIPT            #"
    echo "#                 ${VERSION}                       #"
    echo "#                                              #"
    echo "################################################"

    exit 0

##############################################################
#       MODIFICATION NOTES:
#       2024-01-14  v1.7.0  Feature: Adding Emojis to Telegram messages
#       2023-10-29  v1.6.0  Feature: Dinamic EXPORT of Variables
#       2023-01-03  v1.5.2  Feature: TOTAL size (compact) in telegram notification/log
#       2022-12-23  v1.5.1  Feature: TOTAL size in telegram notification/log
#       2022-12-13  v1.5.0  Feature: PRUNE size in telegram notification/log
#       2022-11-18  v1.4.0  Feature: new jq package validation / migrating to --glob-archives / improving telegram logs
#       2022-03-23  v1.3.0  Feature: Compact    borg_feature_v1.3.0_compact
#       2021-09-15  v1.2.1  Bug: Number of Files reset   borg_bug_v1.2.1_create_file_reset
#       2021-09-10  v1.2.0  Feature: Number of Files    borg_feature_v1.2_number_files
#       2021-08-23  v1.1.1  Feature: Fewer Telegram Messages   borg_feature_v1.1_fewer_telegram_message
#       2021-08-19  v1.0.3  Feature: All-in-One code refactor
#       2021-08-07  v0.4    Enable "--prefix PREFIX" for Pruning
#       2021-08-06  v0.3    Disable PRUNE Option
#       2020-04-25  Uploaded a GitHub version
#       2020-04-24  First version
#
##############################################################