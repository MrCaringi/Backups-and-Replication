#!/bin/bash

###############################
#   v1.0
#               RCLONE List Remote Check
#
#   This script meant for check if a remote has problems (erased)
#
##   HOW TO USE IT (in a Cron Job)
#	    0 12 * * * bash /path/rclone_remote-check.sh /path/to/config.json
#
##  PARAMETERS
#   $1  Path to ".json" config file
#
##   REQUIREMENTS
#       - rclone remotes has to be propperly configured
#
##	SCRIPT MODIFICATION NOTES
#       2021-10-20  v1.0  First version
#       2021-10-20  v1.0.1  End message
#
###############################

    VERSION="v1.0.1"
    echo $(date +%Y-%m-%d_%H:%M:%S)"	2021-08-30  ${VERSION}"
    
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
                sudo apt install -y jq
        fi
##      Getting the Configuration
    #   General Config
    DEBUG=`cat $1 | jq --raw-output '.config.Debug'`
    
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

    function TelegramSendFile(){
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

#   Start
    echo "################################################"
    echo "#                                              #"
    echo "#       STARTING RCLONE REMOTE CHECK           #"
    echo "#                 ${VERSION}                       #"
    echo "#                                              #"
    echo "################################################"


##  Time to CHECK
    N=$(rclone listremotes | wc -l)
    i=0
    HOSTNAME=`hostname`

	#   For Debug purposes
        [ $DEBUG == true ] && echo $(date +%Y-%m-%d_%H:%M:%S)"	CHAT_ID:  "$CHAT_ID
        [ $DEBUG == true ] && echo $(date +%Y-%m-%d_%H:%M:%S)"	API_KEY:  "$API_KEY
        [ $DEBUG == true ] && echo $(date +%Y-%m-%d_%H:%M:%S)"	ENABLE_MESSAGE:  "$ENABLE_MESSAGE
        [ $DEBUG == true ] && echo $(date +%Y-%m-%d_%H:%M:%S)"	DEBUG:  "$DEBUG
        [ $DEBUG == true ] && echo $(date +%Y-%m-%d_%H:%M:%S)"	REMOTES QTY:  "$N

    #   Loop
        E=0
        REMOTES=$(rclone listremotes)

        for remote in ${REMOTES}
        do 
            R=" "
            echo "$(date +%Y-%m-%d_%H:%M:%S)   Working with Remote:  " $remote
            
            #   Verifying if REMOTE WORKS!
            rclone lsd $remote
            R=$?
            echo $(date +%Y-%m-%d_%H:%M:%S)"    Result:  " $R
            if [ $R -eq 1 ] ; then
                E=$(($E + 1))
                echo $(date +%Y-%m-%d_%H:%M:%S)"	RESULT:  "  $R > remote-check.log
                echo $(date +%Y-%m-%d_%H:%M:%S)"	REMOTE ERROR:  " $remote
                echo $(date +%Y-%m-%d_%H:%M:%S)"	REMOTE ERROR:  " $remote >> remote-check.log
                echo $(date +%Y-%m-%d_%H:%M:%S)"	HOSTNAME:  " $HOSTNAME >> remote-check.log
                echo " " >> remote-check.log
                rclone lsd $remote >> remote-check.log 2>&1
                [ $ENABLE_MESSAGE == true ] && TelegramSendFile remote-check.log "#RCLONE_REMOTE_CHECK" " " "#ERROR" "This remote is not available:" "${remote}"  >/dev/null 2>&1
                rm remote-check.log
                
            else
                echo $(date +%Y-%m-%d_%H:%M:%S)"	REMOTE OK:  " $remote
            fi
            echo "================================================"
        done
    #
    #   END
    #   
        [ $ENABLE_MESSAGE == true ] && TelegramSendMessage "#RCLONE_REMOTE_CHECK" "Total Qty of Remotes: $N" "Total Qty of Errors: $E" " " "Script Version: ${VERSION}">/dev/null 2>&1
        echo $(date +%Y-%m-%d_%H:%M:%S)"    TOTAL ERRORS:  " $E
        echo " "
        echo "################################################"
        echo "#                                              #"
        echo "#         ENDING RCLONE REMOTE CHECK           #"
        echo "#                                              #"
        echo "################################################"

    exit 0