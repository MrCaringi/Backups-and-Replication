#!/bin/sh

###############################
#  BORG BACKUP SCRIPT   v0.4
#
#	sh borg-b.sh DOCKER /mnt/iscsi-borg/nostromo-docker /mnt/nostromo-docker 7 4 3 NP
#
#	Parametros
#	1 $TITLE - Titulo del Backup	DOCKER 
#	2 $REP - Repositorio, ejemplo 	/mnt/iscsi-borg/nostromo-docker
#	3 $ORI - Origen, ejemplo	/mnt/nostromo-docker
#	4 $D - Prune Days	7
#	5 $W - Prune Weeks	4
#	6 $M - Prune Months	6
#   7 $P - Disable PRUNE NP
# 
#	Modification Log
#		2020-04-24  First version
#		2020-04-25  Uploaded a GitHub version
#       2021-08-06  v0.3    Disable PRUNE Option
#       2021-08-07  v0.4    Enable "--prefix PREFIX" for Pruning
#
###############################

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
