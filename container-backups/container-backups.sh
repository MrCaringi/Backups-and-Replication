#!/bin/bash

SCRIPT_VERSION="v1.1.2"

# Emoji definitions for status
ICON_OK="✅"
ICON_WARNING="⚠️"
ICON_ERROR="⛔"

# Check arguments
if [ $# -ne 1 ]; then
    echo "Usage: $0 <config_file.json>"
    exit 1
fi

CONFIG_FILE="$1"
HOSTNAME_SHORT=$(hostname | cut -d. -f1)
TIMESTAMP=$(date +%y%m%d-%H%M)
LOG_FILE="/tmp/${HOSTNAME_SHORT}_${TIMESTAMP}.log"
ERROR_COUNT=0

# Write script version as the first line of the log
echo "Container Backup Script version: $SCRIPT_VERSION"
echo "Container Backup Script version: $SCRIPT_VERSION" > "$LOG_FILE"
echo "---   ---   ---   ---   ---   ---   ---"
echo "---   ---   ---   ---   ---   ---   ---" >> "$LOG_FILE"

# Function to write to log
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function to send Telegram message
send_telegram_message() {
    local HEADER="$1"
    local MESSAGE="$2"
    local CHAT_ID=$(jq -r '.telegram.ChatID' "$CONFIG_FILE")
    local API_KEY=$(jq -r '.telegram.APIkey' "$CONFIG_FILE")
    local THREAD_ID=$(jq -r '.telegram.MessageThreadID // empty' "$CONFIG_FILE")

    local CURL_ARGS=(
        --data parse_mode=HTML
        --data chat_id="${CHAT_ID}"
        --data text="<b>${HEADER}</b>%0A<i>from <b>#$(hostname)</b></i>%0A%0A${MESSAGE}"
    )
    if [ -n "$THREAD_ID" ]; then
        CURL_ARGS+=(--data message_thread_id="${THREAD_ID}")
    fi

    curl -s "${CURL_ARGS[@]}" \
        "https://api.telegram.org/bot${API_KEY}/sendMessage" >/dev/null 2>&1
}

# Function to send file via Telegram
send_telegram_file() {
    local FILE="$1"
    local HEADER="$2"
    local CHAT_ID=$(jq -r '.telegram.ChatID' "$CONFIG_FILE")
    local API_KEY=$(jq -r '.telegram.APIkey' "$CONFIG_FILE")
    local THREAD_ID=$(jq -r '.telegram.MessageThreadID // empty' "$CONFIG_FILE")

    local CURL_ARGS=(
        -F "chat_id=${CHAT_ID}"
        -F document=@"${FILE}"
        -F caption="${HEADER}"$'\n'"        from: #$(hostname)"
    )
    if [ -n "$THREAD_ID" ]; then
        CURL_ARGS+=(-F "message_thread_id=${THREAD_ID}")
    fi

    curl -s "${CURL_ARGS[@]}" \
        "https://api.telegram.org/bot${API_KEY}/sendDocument" >/dev/null 2>&1
}

# Function to check if container exists
check_container() {
    local CONTAINER="$1"
    if ! docker ps -a | grep -q "$CONTAINER"; then
        log "ERROR: Container $CONTAINER does not exist"
        send_telegram_message "Backup Error $ICON_ERROR" "Container <b>$CONTAINER</b> does not exist"
        return 1
    fi
    return 0
}

# Function to rotate backups for volumes
rotate_backups() {
    local CONTAINER="$1"
    local VOLUME_NAME="$2"
    local BACKUP_PATH="$3"
    local MAX_BACKUPS="$4"
    
    log "Starting backup rotation for $CONTAINER - $VOLUME_NAME (max: $MAX_BACKUPS)"
    
    local BACKUP_COUNT=$(ls -1 "${BACKUP_PATH}/${CONTAINER}_${VOLUME_NAME}_"*.tar.gz 2>/dev/null | wc -l)
    
    if [ "$BACKUP_COUNT" -ge "$MAX_BACKUPS" ]; then
        local EXCESS=$((BACKUP_COUNT - MAX_BACKUPS + 1))
        local OLD_BACKUPS=$(ls -1t "${BACKUP_PATH}/${CONTAINER}_${VOLUME_NAME}_"*.tar.gz | tail -n "$EXCESS")
        
        log "Deleting $EXCESS old backup(s)"
        echo "$OLD_BACKUPS" | while read -r backup; do
            log "Deleting old backup: $(basename "$backup")"
            rm -f "$backup"
        done
    fi
}

# Function to rotate compose backups
rotate_compose_backups() {
    local BACKUP_PATH="$1"
    local MAX_BACKUPS="$2"
    local COMPOSE_BACKUPS
    COMPOSE_BACKUPS=($(ls -1t "$BACKUP_PATH"/compose_*.yml 2>/dev/null))
    local BACKUP_COUNT=${#COMPOSE_BACKUPS[@]}

    if [ "$BACKUP_COUNT" -gt "$MAX_BACKUPS" ]; then
        local EXCESS=$((BACKUP_COUNT - MAX_BACKUPS))
        for ((i=BACKUP_COUNT-1; i>=MAX_BACKUPS; i--)); do
            log "Deleting old compose backup: $(basename "${COMPOSE_BACKUPS[$i]}")"
            rm -f "${COMPOSE_BACKUPS[$i]}"
        done
    fi
}

# Function to backup a specific volume
backup_volume() {
    local CONTAINER="$1"
    local VOLUME_PATH="$2"
    local BACKUP_PATH="$3"
    local MAX_BACKUPS="$4"
    local VOLUME_NAME=$(basename "$VOLUME_PATH")
    local BACKUP_NAME="${CONTAINER}_${VOLUME_NAME}_${TIMESTAMP}.tar.gz"
    
    log "Backing up volume: $VOLUME_PATH"
    
    if [ ! -d "$VOLUME_PATH" ]; then
        log "ERROR: Volume directory does not exist: $VOLUME_PATH"
        return 1
    fi
    
    # Rotate backups before creating a new one
    rotate_backups "$CONTAINER" "$VOLUME_NAME" "$BACKUP_PATH" "$MAX_BACKUPS"
    
    # Create backup of the volume
    if ! tar czf "${BACKUP_PATH}/${BACKUP_NAME}" -C "$(dirname "$VOLUME_PATH")" "$VOLUME_NAME" >> "$LOG_FILE" 2>&1; then
        log "ERROR: Could not create backup for volume $VOLUME_PATH"
        return 1
    fi

    # Calculate backup file size
    local BACKUP_SIZE=$(du -sh "${BACKUP_PATH}/${BACKUP_NAME}" | awk '{print $1}')
    log "Volume backup completed: $BACKUP_NAME (Size: $BACKUP_SIZE)"
    
    return 0
}

# Function to backup a container and all its volumes
backup_container() {
    local CONTAINER="$1"
    local VOLUMES="$2"
    local BACKUP_PATH="$3"
    local MAX_BACKUPS="$4"
    local container="$5"
    local BACKUP_FAILED=0
    local CONTAINER_BACKUP_PATH="${BACKUP_PATH}/${CONTAINER}"

    # Create subfolder for the container
    mkdir -p "$CONTAINER_BACKUP_PATH"
    
    log "Starting backup for container: $CONTAINER"
    
    # Check if container exists
    if ! check_container "$CONTAINER"; then
        ERROR_COUNT=$((ERROR_COUNT + 1))
        log "Backup failed for $CONTAINER: container does not exist"
        log "---   ---   ---   ---   ---   ---   ---"
        return 1
    fi
    
    # Pause container
    log "Pausing container $CONTAINER..."
    if ! docker pause "$CONTAINER" >> "$LOG_FILE" 2>&1; then
        log "ERROR: Could not pause container $CONTAINER"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        log "Backup failed for $CONTAINER: could not pause"
        log "---   ---   ---   ---   ---   ---   ---"
        return 1
    fi
    
    # Backup each volume (use for loop to preserve variable scope)
    local VOLUME_PATH
    for VOLUME_PATH in $(echo "$VOLUMES" | jq -r '.[]'); do
        if ! backup_volume "$CONTAINER" "$VOLUME_PATH" "$CONTAINER_BACKUP_PATH" "$MAX_BACKUPS"; then
            BACKUP_FAILED=1
            ERROR_COUNT=$((ERROR_COUNT + 1))
        fi
    done
    
    # Unpause container
    log "Unpausing container $CONTAINER..."
    if ! docker unpause "$CONTAINER" >> "$LOG_FILE" 2>&1; then
        log "ERROR: Could not unpause container $CONTAINER"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        log "Backup failed for $CONTAINER: could not unpause"
        log "---   ---   ---   ---   ---   ---   ---"
        return 1
    fi
    
    # Backup compose file if specified
    local COMPOSE_FILE=$(echo "$container" | jq -r '.composeFile // empty')
    if [ -n "$COMPOSE_FILE" ] && [ -f "$COMPOSE_FILE" ]; then
        cp "$COMPOSE_FILE" "$CONTAINER_BACKUP_PATH/compose_${TIMESTAMP}.yml"
        log "Compose file $COMPOSE_FILE backed up as compose_${TIMESTAMP}.yml"
        rotate_compose_backups "$CONTAINER_BACKUP_PATH" "$MAX_BACKUPS"
    fi
    
    # Calculate total backup folder size for the container
    local TOTAL_BACKUP_SIZE=$(du -sh "$CONTAINER_BACKUP_PATH" | awk '{print $1}')
    log "Backup completed for $CONTAINER. Total size: $TOTAL_BACKUP_SIZE"
    
    if [ $BACKUP_FAILED -eq 0 ]; then
        log "Backup successfully completed for all volumes of $CONTAINER"
    else
        log "WARNING: Some volumes of $CONTAINER could not be backed up"
    fi
    log "---   ---   ---   ---   ---   ---   ---"
    return $BACKUP_FAILED
}

# Validate config file
if [ ! -f "$CONFIG_FILE" ]; then
    log "ERROR: Config file not found: $CONFIG_FILE"
    exit 1
fi

# Process each container
log "Starting backup process"
log "Using config file: $CONFIG_FILE"

# Get backup destination path from config file
BACKUP_DEST=$(jq -r '.config.BackupDestination // "/tmp/backups"' "$CONFIG_FILE")
mkdir -p "$BACKUP_DEST"

CONTAINERS_JSON=$(jq -c '.containers[]' "$CONFIG_FILE" 2>/dev/null)
IFS=$'\n'
for container in $CONTAINERS_JSON; do
    CONTAINER_NAME=$(echo "$container" | jq -r '.name')
    VOLUMES=$(echo "$container" | jq '.volumes')
    MAX_BACKUPS=$(echo "$container" | jq -r '.maxBackups // "5"')
    backup_container "$CONTAINER_NAME" "$VOLUMES" "$BACKUP_DEST" "$MAX_BACKUPS" "$container"
done
unset IFS

# Wait for all background processes to finish
wait

# Send final notification
if [ $ERROR_COUNT -eq 0 ]; then
    STATUS_ICON="$ICON_OK"
    STATUS_MSG="All backups completed successfully"
else
    STATUS_ICON="$ICON_ERROR"
    STATUS_MSG="$ERROR_COUNT error(s) occurred during the process"
fi

HEADER="Backup Status $STATUS_ICON"
send_telegram_message "$HEADER" "$STATUS_MSG"

# Add error count to the end of the log file before sending
echo "Total errors: $ERROR_COUNT" >> "$LOG_FILE"

send_telegram_file "$LOG_FILE" "Backup Log $STATUS_ICON"

log "Process finished with $ERROR_COUNT error(s)"
exit $ERROR_COUNT
