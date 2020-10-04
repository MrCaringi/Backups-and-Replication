#!/bin/bash

###############################
#           BORG CHECK SCRIPT   v2
#
#	bash borg-c.sh /path/to/borg-c.json
#
#	Parameters
#	1 $REP_DIR     configuration file path
#	2 
# 
#	Modification Log
#		2020-07-30  First version
#		2020-09-28  v2: .json config file support
#
#
###############################


##      Getting the Configuration
    PASSPHRASE=`cat $1 | jq --raw-output '.config.Password'`
    SEND_MESSAGE=`cat $1 | jq --raw-output '.config.SendMessage'`
    SEND_FILE=`cat $1 | jq --raw-output '.config.SendFile'`

echo "=============================================================================="

# Setting this, so you won't be asked for your repository passphrase:
export BORG_PASSPHRASE=${PASSPHRASE}

# some helpers and error handling:
#info() { printf "\n%s %s\n\n" "$( date )" "$*"; }
#trap 'echo $( date ) Check interrupted ; exit 2' INT TERM

#   Getting number of repositories
    N=`jq '.repository | length ' $1`
    i=0


#   Repository loop
    while [ $i -lt $N ]
    do

        echo "================================================"
        REPO=`cat $1 | jq --raw-output ".repository[$i]"`
        echo $(date +%Y%m%d-%H%M)" Starting Check of $REPO"
        START=$(date +"%Y%m%d %HH%MM%SS")
        bash $SEND_MESSAGE "Borg Check" "Repo: #${REPO}" "Starting Check of repository" > /dev/null
        
            #   For Debug purposes
            echo "REPO:"$REPO
            #echo "SEND_MESSAGE:"$SEND_MESSAGE
            #echo "PASSPHRASE:"$PASSPHRASE
            echo "N="$N
            echo "i="$i
        
        #   The Magic goes here
        log_check=`borg check -v --verify-data --show-rc $REPO 2>&1`
        exit=$?

        if [ ${exit} -eq 0 ]; then
            info "Check of ${REPO} finished successfully"
            echo $(date +%Y%m%d-%H%M)" Check of ${REPO} finished successfully"
            bash $SEND_MESSAGE "Borg Check" "Repo: #${REPO}" "Check finished #successfully" > /dev/null
        else
            info "Check of ${REPO} finished with errors"
            echo $(date +%Y%m%d-%H%M)" Check of ${REPO} finished with errors"
            bash $SEND_MESSAGE "Borg Check" "Repo: #${REPO}" "Check finished with #errors" > /dev/null
        fi

        ##  Sending log to Telegram
        #   Building the log file
            rand=$((1000 + RANDOM % 8500))
            echo "========== BORG CHECK          $START" >> borg-log_${rand}.log
            echo "$log_check" >> borg-log_${rand}.log
            echo >> borg-log_${rand}.log
            echo "========== END           $(date +"%Y%m%d %HH%MM%SS")" >> borg-log_${rand}.log
            #   Sending the File to Telegram
            bash $SEND_FILE "Repo: #${REPO}" "Borg Check Log File" borg-log_${rand}.log > /dev/null
            #   Flushing & Deleting the file
            cat borg-log_${rand}.log
            rm borg-log_${rand}.log

        i=$(($i + 1))
    done
    
exit 0
