#!/bin/bash

SCRIPT_VERSION="v2.2"

# Emoji definitions for status
ICON_OK="✅"
ICON_WARNING="⚠️"
ICON_ERROR="⛔"
ICON_WAIT="⏳"

# Check arguments
if [ $# -ne 1 ]; then
    echo "Usage: $0 <config.json>"
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
    local now
    now=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$now] $1"
    echo "[$now] $1" >> "$LOG_FILE"
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

# Function to rotate backups for volumes
rotate_backups() {
    local backup_dir="$1"
    local max_backups="$2"
    local backups
    backups=($(ls -1dt "$backup_dir"/* 2>/dev/null))
    if [ "${#backups[@]}" -gt "$max_backups" ]; then
        for old_backup in "${backups[@]:$max_backups}"; do
            rm -rf "$old_backup"
            log "$ICON_WARNING Removed old backup: $old_backup"
        done
    fi
}

# Function to backup and compress a volume
backup_and_compress_volume() {
    local stack_name="$1"
    local volume_path="$2"
    local max_backups="$3"
    local timestamp="$4"

    local volume_name
    volume_name=$(basename "$volume_path")
    local backup_path="$BACKUP_DEST/$stack_name/$volume_name"
    local backup_file="$backup_path/${volume_name}_$timestamp.tar.gz"

    mkdir -p "$backup_path"
    log "$ICON_OK Backing up $volume_path to $backup_file"
    if tar czf "$backup_file" -C "$volume_path" . >> "$LOG_FILE" 2>&1; then
        local backup_size
        backup_size=$(du -sh "$backup_file" | awk '{print $1}')
        log "$ICON_OK Backup successful: $backup_file (Size: $backup_size)"
        rotate_backups "$backup_path" "$max_backups"
    else
        log "$ICON_ERROR Backup failed for $volume_path"
        ERROR_COUNT=$((ERROR_COUNT+1))
    fi
}

# Function to backup and compress the compose directory
backup_compose_dir() {
    local stack_name="$1"
    local compose_file="$2"
    local timestamp="$3"
    local max_backups="$4"

    local compose_dir
    compose_dir=$(dirname "$compose_file")
    local backup_path="$BACKUP_DEST/$stack_name/compose_dir"
    local backup_file="$backup_path/compose_dir_$timestamp.tar.gz"

    if [ ! -d "$compose_dir" ]; then
        log "$ICON_ERROR Compose directory '$compose_dir' does not exist for stack '$stack_name'."
        ERROR_COUNT=$((ERROR_COUNT+1))
        return
    fi

    mkdir -p "$backup_path"
    log "$ICON_OK Backing up compose directory $compose_dir to $backup_file"
    if tar czf "$backup_file" -C "$compose_dir" . >> "$LOG_FILE" 2>&1; then
        local backup_size
        backup_size=$(du -sh "$backup_file" | awk '{print $1}')
        log "$ICON_OK Compose directory backup successful: $backup_file (Size: $backup_size)"
        rotate_backups "$backup_path" "$max_backups"
    else
        log "$ICON_ERROR Compose directory backup failed for $compose_dir"
        ERROR_COUNT=$((ERROR_COUNT+1))
    fi
}

# Check for jq
if ! command -v jq >/dev/null 2>&1; then
    log "$ICON_ERROR jq is required but not installed."
    exit 1
fi

# Check for docker compose
if ! command -v docker >/dev/null 2>&1 || ! docker compose version >/dev/null 2>&1; then
    log "$ICON_ERROR docker compose is required but not installed."
    exit 1
fi

# Get backup destination path from config file
BACKUP_DEST=$(jq -r '.config.BackupDestination' "$CONFIG_FILE")
STACKS=$(jq -c '.stacks[]' "$CONFIG_FILE")

for stack in $STACKS; do
    STACK_NAME=$(echo "$stack" | jq -r '.name')
    COMPOSE_FILE=$(echo "$stack" | jq -r '.composeFile')
    VOLUMES=$(echo "$stack" | jq -c '.volumes[]')

    if [ -z "$COMPOSE_FILE" ] || [ "$COMPOSE_FILE" == "null" ]; then
        log "$ICON_ERROR Stack '$STACK_NAME' missing composeFile. Skipping."
        ERROR_COUNT=$((ERROR_COUNT+1))
        continue
    fi

    log "$ICON_WARNING Stopping stack '$STACK_NAME' with compose file $COMPOSE_FILE"
    if ! docker compose -f "$COMPOSE_FILE" down >> "$LOG_FILE" 2>&1; then
        log "$ICON_ERROR Failed to stop stack '$STACK_NAME'."
        send_telegram_message "Failed to stop stack '$STACK_NAME' before backup."
        ERROR_COUNT=$((ERROR_COUNT+1))
        continue
    fi

    for volume in $VOLUMES; do
        VOLUME_PATH=$(echo "$volume" | jq -r '.path')
        MAX_BACKUPS=$(echo "$volume" | jq -r '.maxBackups')
        PRE_BACKUP_SLEEP=$(echo "$volume" | jq -r '.preBackupSleep // empty')

        if [ -n "$PRE_BACKUP_SLEEP" ]; then
            log "$ICON_WAIT Waiting $PRE_BACKUP_SLEEP seconds before backing up $VOLUME_PATH (preBackupSleep set)"
            sleep "$PRE_BACKUP_SLEEP"
        fi

        backup_and_compress_volume "$STACK_NAME" "$VOLUME_PATH" "$MAX_BACKUPS" "$TIMESTAMP"
    done

    # Backup compose directory (uses maxBackups from first volume or default 4)
    FIRST_MAX_BACKUPS=$(echo "$stack" | jq -r '.volumes[0].maxBackups // 4')
    backup_compose_dir "$STACK_NAME" "$COMPOSE_FILE" "$TIMESTAMP" "$FIRST_MAX_BACKUPS"

    # Log total size for the stack
    stack_backup_path="$BACKUP_DEST/$STACK_NAME"
    if [ -d "$stack_backup_path" ]; then
        total_stack_size=$(du -sh "$stack_backup_path" | awk '{print $1}')
        log "$ICON_OK Total backup size for stack '$STACK_NAME': $total_stack_size"
    fi

    echo "---   ---   ---   ---   ---   ---   ---"
    echo "---   ---   ---   ---   ---   ---   ---" >> "$LOG_FILE"

    log "$ICON_WARNING Starting stack '$STACK_NAME' with compose file $COMPOSE_FILE"
    if ! docker compose -f "$COMPOSE_FILE" up -d >> "$LOG_FILE" 2>&1; then
        log "$ICON_ERROR Failed to start stack '$STACK_NAME' after backup."
        send_telegram_message "Failed to start stack '$STACK_NAME' after backup."
        ERROR_COUNT=$((ERROR_COUNT+1))
        continue
    fi
done

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
