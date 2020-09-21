#!/bin/bash

###############################
#  BORG CHECK SCRIPT
#
#	bash borg-c.sh /path/to/repository
#
#	Parameters
#	1 $REP_DIR     path to file with list of repositories
#	2 
# 
#	Modification Log
#		2020-07-30  First version
#		
#
#
###############################


##	INPUT VARIABLES
#   $(date +"%Y%m%d")"
REP_DIR=${1}


#################################
#   CONFIG FILE
#   example     /home/jfc/scripts/borg.conf
#   this should be like this
#
#   PASSPHRASE='password'

#	Asignacion de Variables
#   $(date +"%Y%m%d")"   
. /home/jfc/scripts/borg.conf

echo "=============================================================================="

# Setting this, so you won't be asked for your repository passphrase:
export BORG_PASSPHRASE=${PASSPHRASE}

# some helpers and error handling:
info() { printf "\n%s %s\n\n" "$( date )" "$*"; }
trap 'echo $( date ) Check interrupted ; exit 2' INT TERM

##  Getting the list of repositories
REP_LIST=`cat $REP_DIR`

for i in $REP_LIST
do
    echo "================================================"
    REPO=${i##*/}
    echo $(date +%Y%m%d-%H%M)" Starting Check of $REPO"
    START=$(date +"%Y%m%d %HH%MM%SS")
    bash /home/jfc/scripts/telegram-message.sh "Borg Check" "Repo: #${REPO}" "Starting Check of repository" > /dev/null
    
    #   The Magic goes here
    log_check=`borg check -v --verify-data --show-rc $i 2>&1`
    exit=$?

    if [ ${exit} -eq 0 ]; then
        info "Check of ${REPO} finished successfully"
        echo $(date +%Y%m%d-%H%M)" Check of ${REPO} finished successfully"
        bash /home/jfc/scripts/telegram-message.sh "Borg Check" "Repo: #${REPO}" "Check finished #successfully" > /dev/null
    else
        info "Check of ${REPO} finished with errors"
        echo $(date +%Y%m%d-%H%M)" Check of ${REPO} finished with errors"
        bash /home/jfc/scripts/telegram-message.sh "Borg Check" "Repo: #${REPO}" "Check finished with #errors" > /dev/null
    fi

    ##  Sending log to Telegram
    #   Building the log file
        rand=$((1000 + RANDOM % 8500))
        echo "========== BORG CHECK          $START" >> borg-log_${rand}.log
        echo "$log_check" >> borg-log_${rand}.log
        echo >> borg-log_${rand}.log
        echo "========== END           $(date +"%Y%m%d %HH%MM%SS")" >> borg-log_${rand}.log
        #   Sending the File to Telegram
        bash /home/jfc/scripts/telegram-message-file.sh "Repo: #${REPO}" "Borg Check Log File" borg-log_${rand}.log > /dev/null
        #   Flushing & Deleting the file
        cat borg-log_${rand}.log
        rm borg-log_${rand}.log

done

exit ${exit}
