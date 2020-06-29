#!/bin/sh

###############################
#  BORG CHECK SCRIPT
#
#	sh borg-check.sh /path/to/config 
#
#	Parameters
#	1 $CONFIG - Path to configuration file
# 
#	Modification Log
#		2020-06-29  WIP
#
#
###############################

#	Asignacion de Variables
TITLE="${1}-$(date +"%Y%m%d")"
REP=${2}
ORI=${3}
D=${4}
W=${5}
M=${6}

#	Ruta de repositorio + nombre de backup
FULLREP="${REP}::${TITLE}"

#	Carga de Password, ejemplo del contenido: PASSPHRASE='password'
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
bash /home/jfc/scripts/telegram-message.sh "Borg Backup" "Repo: #${TITLE}" "Starting backup" > /dev/null

# Backup the most important directories into an archive named after
# the machine this script is currently running on:

borg create --stats --compression auto,lzma,7 ${FULLREP} ${ORI} 2>&1

backup_exit=$?

info "Pruning repository"
echo $(date +%Y%m%d-%H%M)" Pruning repository of ${TITLE}"
bash /home/jfc/scripts/telegram-message.sh "Borg Backup" "Repo: #${TITLE}" "Pruning repository" > /dev/null

###     PRUNE

if [ $backup_exit -eq 0 ]; then
    borg prune -v -s --list --keep-daily=$D --keep-weekly=$W --keep-monthly=$M $REP 2>&1
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

exit ${global_exit}
