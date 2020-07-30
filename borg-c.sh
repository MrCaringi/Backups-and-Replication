#!/bin/bash

###############################
#  BORG CHECK SCRIPT
#
#	bash borg-c.sh /path/to/config /path/to/repository
#
#	Parameters
#	1 $CONFIG       path to config file
#	2 $REP_DIR     path to file with list of repositories
#	3 
# 
#	Modification Log
#		2020-07-30  First version
#		
#
#
###############################

#################################
#   CONFIG FILE
#   /home/jfc/scripts/borg.conf
#   this should be like this
#
#   PASSPHRASE='password'

#	Asignacion de Variables
#   $(date +"%Y%m%d")"
CONFIG=${1}
REP_DIR=${2}



#	Parametros
#
#   PASSPHRASE='password'
#   
. $1

#testing
echo &1
echo &BORG_PASSPHRASE
exit 0

echo "=============================================================================="

# Setting this, so you won't be asked for your repository passphrase:
export BORG_PASSPHRASE=${PASSPHRASE}

# some helpers and error handling:
info() { printf "\n%s %s\n\n" "$( date )" "$*"; }
trap 'echo $( date ) Backup interrupted ; exit 2' INT TERM

info "Starting backup"
echo $(date +%Y%m%d-%H%M)" Starting backup of ${TITLE}"
bash /home/jfc/scripts/telegram-message.sh "Borg Backup" "Repo: #${TITLE}" "Starting backup" > /dev/null

# Backup the most important directories into an archive named after
# the machine this script is currently running on:

##  Running the backup and capturing the output to a variable
#   log variable will be used to sent the log via telegram
log_create=`borg create --stats --list --filter=E --compression auto,lzma,9 ${FULLREP} ${ORI} 2>&1`
log_create=`borg create --stats --list --filter=E --compression auto,lzma,9 ${FULLREP} ${ORI} 2>&1`

backup_exit=$?

info "Pruning repository"
echo $(date +%Y%m%d-%H%M)" Pruning repository of ${TITLE}"
bash /home/jfc/scripts/telegram-message.sh "Borg Backup" "Repo: #${TITLE}" "Pruning repository" > /dev/null

###     PRUNE

if [ $backup_exit -eq 0 ]; then
    log_prune=`borg prune -v -s --list --keep-daily=$D --keep-weekly=$W --keep-monthly=$M $REP 2>&1`
    prune_exit=$?
else
    echo $(date +%Y%m%d-%H%M)" Backup not completed, skip Pruning of ${TITLE}"    
fi

# use highest exit code as global exit code
global_exit=$(( backup_exit > prune_exit ? backup_exit : prune_exit ))

if [ ${global_exit} -eq 0 ]; then
    info "Backup and Prune finished successfully"
    echo $(date +%Y%m%d-%H%M)" Backup and Prune finished successfully"
	bash /home/jfc/scripts/telegram-message.sh "Borg Backup" "Repo: #${TITLE}" "Backup and Prune finished #successfully" > /dev/null
elif [ ${global_exit} -eq 1 ]; then
    info "Backup and/or Prune finished with warnings"
    echo $(date +%Y%m%d-%H%M)" Backup and/or Prune finished with warnings"
	bash /home/jfc/scripts/telegram-message.sh "Borg Backup" "Repo: #${TITLE}" "Backup and/or Prune finished with #warnings" > /dev/null
else
    info "Backup and/or Prune finished with errors"
    echo $(date +%Y%m%d-%H%M)" Backup and/or Prune finished with errors"
	bash /home/jfc/scripts/telegram-message.sh "Borg Backup" "Repo: #${TITLE}" "Backup and/or Prune finished with #errors" > /dev/null
fi

##  Sending log to Telegram
#   Building the log file
rand=$((1000 + RANDOM % 8500))
echo "========== BORG CREATE" >> borg-log_${rand}.log
echo "$log_create" >> borg-log_${rand}.log
echo >> borg-log_${rand}.log
echo "========== BORG PRUNE" >> borg-log_${rand}.log
echo $(date +"%Y%m%d %HH%MM%SS") >> borg-log_${rand}.log
echo >> borg-log_${rand}.log
echo "$log_prune" >> borg-log_${rand}.log
echo "========== END" >> borg-log_${rand}.log
echo $(date +"%Y%m%d %HH%MM%SS") >> borg-log_${rand}.log

#   Sending the File to Telegram
bash /home/jfc/scripts/telegram-message-file.sh "Repo: #${TITLE}" "Log File" borg-log_${rand}.log > /dev/null

#   Flushing & Deleting the file
cat borg-log_${rand}.log
rm borg-log_${rand}.log

exit ${global_exit}
