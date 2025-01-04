#!/bin/bash

# Definición de emojis para estados
ICON_OK="✅"
ICON_WARNING="⚠️"
ICON_ERROR="⛔"

# Verificar argumentos
if [ $# -ne 1 ]; then
    echo "Uso: $0 <archivo_configuracion.json>"
    exit 1
fi

CONFIG_FILE="$1"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE=$(jq -r '.config.LogDestination' "$CONFIG_FILE")/backup_${TIMESTAMP}.log
ERROR_COUNT=0

# Función para escribir en el log
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Función para enviar mensaje por Telegram
send_telegram_message() {
    local HEADER="$1"
    local MESSAGE="$2"
    local CHAT_ID=$(jq -r '.telegram.ChatID' "$CONFIG_FILE")
    local API_KEY=$(jq -r '.telegram.APIkey' "$CONFIG_FILE")
    
    curl -s \
    --data parse_mode=HTML \
    --data chat_id="${CHAT_ID}" \
    --data text="<b>${HEADER}</b>%0A<i>from <b>#$(hostname)</b></i>%0A%0A${MESSAGE}" \
    "https://api.telegram.org/bot${API_KEY}/sendMessage" >/dev/null 2>&1 
}

# Función para enviar archivo por Telegram
send_telegram_file() {
    local FILE="$1"
    local HEADER="$2"
    local CHAT_ID=$(jq -r '.telegram.ChatID' "$CONFIG_FILE")
    local API_KEY=$(jq -r '.telegram.APIkey' "$CONFIG_FILE")
    
    curl -s -F \
    "chat_id=${CHAT_ID}" \
    -F document=@"${FILE}" \
    -F caption="${HEADER}"$'\n'"        from: #$(hostname)" \
    https://api.telegram.org/bot${API_KEY}/sendDocument >/dev/null 2>&1 
}

# Función para rotar backups
rotate_backups() {
    local GROUP_NAME="$1"
    local BACKUP_PATH="$2"
    local MAX_BACKUPS="$3"
    
    log "Iniciando rotación de backups para $GROUP_NAME (máximo: $MAX_BACKUPS)"
    
    # Listar todos los backups existentes para este grupo
    local BACKUP_COUNT=$(ls -1 "${BACKUP_PATH}/${GROUP_NAME}_"*.tar.gz 2>/dev/null | wc -l)
    
    if [ "$BACKUP_COUNT" -ge "$MAX_BACKUPS" ]; then
        # Obtener los backups más antiguos que exceden el límite
        local EXCESS=$((BACKUP_COUNT - MAX_BACKUPS + 1))
        local OLD_BACKUPS=$(ls -1t "${BACKUP_PATH}/${GROUP_NAME}_"*.tar.gz | tail -n "$EXCESS")
        
        log "Eliminando $EXCESS backup(s) antiguo(s)"
        echo "$OLD_BACKUPS" | while read -r backup; do
            log "Eliminando backup antiguo: $(basename "$backup")"
            rm -f "$backup"
        done
    fi
}

# Función para realizar backup de una carpeta específica
backup_folder() {
    local GROUP_NAME="$1"
    local FOLDER_PATH="$2"
    local BACKUP_PATH="$3"
    local MAX_BACKUPS="$4"
    local FOLDER_NAME=$(basename "$FOLDER_PATH")
    local BACKUP_NAME="${GROUP_NAME}_${TIMESTAMP}.tar.gz"
    local TEMP_BACKUP_LIST=$(mktemp)
    
    log "Realizando backup de la carpeta: $FOLDER_PATH"
    
    if [ ! -d "$FOLDER_PATH" ]; then
        log "ERROR: El directorio no existe: $FOLDER_PATH"
        rm -f "$TEMP_BACKUP_LIST"
        return 1
    fi
    
    # Rotar backups antes de crear uno nuevo
    rotate_backups "$GROUP_NAME" "$BACKUP_PATH" "$MAX_BACKUPS"
    
    # Crear lista de archivos a respaldar
    find "$FOLDER_PATH" -type f > "$TEMP_BACKUP_LIST"
    
    # Crear backup de la carpeta
    if ! tar czf "${BACKUP_PATH}/${BACKUP_NAME}" -T "$TEMP_BACKUP_LIST" >> "$LOG_FILE" 2>&1; then
        log "ERROR: No se pudo crear el backup de la carpeta $FOLDER_PATH"
        rm -f "$TEMP_BACKUP_LIST"
        return 1
    fi

    rm -f "$TEMP_BACKUP_LIST"

    # Calcular el tamaño del archivo de backup
    local BACKUP_SIZE=$(du -sh "${BACKUP_PATH}/${BACKUP_NAME}" | awk '{print $1}')
    log "Backup de la carpeta completado: $BACKUP_NAME (Tamaño: $BACKUP_SIZE)"
    
    return 0
}

# Función para realizar backup de un grupo de carpetas
backup_group() {
    local GROUP_NAME="$1"
    local PATHS="$2"
    local BACKUP_PATH="$3"
    local MAX_BACKUPS="$4"
    local BACKUP_FAILED=0
    local GROUP_BACKUP_PATH="${BACKUP_PATH}/${GROUP_NAME}"

    # Crear subcarpeta para el grupo
    mkdir -p "$GROUP_BACKUP_PATH"
    
    log "Iniciando backup del grupo: $GROUP_NAME"
    
    # Realizar backup de cada carpeta
    echo "$PATHS" | jq -c '.[]' | while read -r path; do
        FOLDER_PATH=$(echo "$path" | jq -r '.')
        if ! backup_folder "$GROUP_NAME" "$FOLDER_PATH" "$GROUP_BACKUP_PATH" "$MAX_BACKUPS"; then
            BACKUP_FAILED=1
            ERROR_COUNT=$((ERROR_COUNT + 1))
        fi
    done
    
    # Calcular tamaño total de los backups del grupo
    local TOTAL_BACKUP_SIZE=$(du -sh "$GROUP_BACKUP_PATH" | awk '{print $1}')
    log "Backup completado para $GROUP_NAME. Tamaño total: $TOTAL_BACKUP_SIZE"
    
    if [ $BACKUP_FAILED -eq 0 ]; then
        log "Backup completado exitosamente para todas las carpetas de $GROUP_NAME"
        log "---   ---   ---   ---   ---   ---   ---"
        return 0
    else
        log "ADVERTENCIA: Algunas carpetas de $GROUP_NAME no se pudieron respaldar"
        log "---   ---   ---   ---   ---   ---   ---"
        return 1
    fi
}

# Validar archivo de configuración
if [ ! -f "$CONFIG_FILE" ]; then
    log "ERROR: No se encuentra el archivo de configuración: $CONFIG_FILE"
    exit 1
fi

# Procesar cada grupo de carpetas
log "Iniciando proceso de backup"
log "Usando archivo de configuración: $CONFIG_FILE"

# Obtener la ruta de destino del backup desde el archivo de configuración
BACKUP_DEST=$(jq -r '.config.BackupDestination // "/tmp/backups"' "$CONFIG_FILE")
mkdir -p "$BACKUP_DEST"

# Procesar cada grupo en el archivo de configuración
jq -c '.folders[]' "$CONFIG_FILE" 2>/dev/null | while read -r group; do
    GROUP_NAME=$(echo "$group" | jq -r '.name')
    PATHS=$(echo "$group" | jq '.paths')
    MAX_BACKUPS=$(echo "$group" | jq -r '.maxBackups // "5"')  # Por defecto 5 si no se especifica
    
    backup_group "$GROUP_NAME" "$PATHS" "$BACKUP_DEST" "$MAX_BACKUPS"
done

# Esperar a que terminen todos los procesos en segundo plano
wait

# Enviar notificación final
if [ $ERROR_COUNT -eq 0 ]; then
    STATUS_ICON="$ICON_OK"
    STATUS_MSG="Todos los backups completados exitosamente"
else
    STATUS_ICON="$ICON_ERROR"
    STATUS_MSG="Se encontraron $ERROR_COUNT errores durante el proceso"
fi

HEADER="Estado de Backup $STATUS_ICON"
send_telegram_message "$HEADER" "$STATUS_MSG"
send_telegram_file "$LOG_FILE" "Log de Backup $STATUS_ICON"

log "Proceso finalizado con $ERROR_COUNT errores"
exit $ERROR_COUNT