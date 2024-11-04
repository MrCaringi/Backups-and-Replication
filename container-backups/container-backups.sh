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
LOG_FILE="/tmp/container_backup_${TIMESTAMP}.log"
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
    "https://api.telegram.org/bot${API_KEY}/sendMessage"
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
    https://api.telegram.org/bot${API_KEY}/sendDocument
}

# Función para verificar si el contenedor existe
check_container() {
    local CONTAINER="$1"
    if ! docker ps -a | grep -q "$CONTAINER"; then
        log "ERROR: El contenedor $CONTAINER no existe"
        return 1
    fi
    return 0
}

# Función para realizar backup de un volumen específico
backup_volume() {
    local CONTAINER="$1"
    local VOLUME_PATH="$2"
    local BACKUP_PATH="$3"
    local VOLUME_NAME=$(basename "$VOLUME_PATH")
    local BACKUP_NAME="${CONTAINER}_${VOLUME_NAME}_${TIMESTAMP}.tar.gz"
    
    log "Realizando backup del volumen: $VOLUME_PATH"
    
    if [ ! -d "$VOLUME_PATH" ]; then
        log "ERROR: El directorio del volumen no existe: $VOLUME_PATH"
        return 1
    }
    
    # Crear backup del volumen
    if ! tar czf "${BACKUP_PATH}/${BACKUP_NAME}" -C "$(dirname "$VOLUME_PATH")" "$VOLUME_NAME" >> "$LOG_FILE" 2>&1; then
        log "ERROR: No se pudo crear el backup del volumen $VOLUME_PATH"
        return 1
    }
    
    log "Backup del volumen completado: $BACKUP_NAME"
    return 0
}

# Función para realizar backup de un contenedor y todos sus volúmenes
backup_container() {
    local CONTAINER="$1"
    local VOLUMES="$2"
    local BACKUP_PATH="$3"
    local BACKUP_FAILED=0
    
    log "Iniciando backup del contenedor: $CONTAINER"
    
    # Verificar si el contenedor existe
    if ! check_container "$CONTAINER"; then
        ERROR_COUNT=$((ERROR_COUNT + 1))
        return 1
    }
    
    # Detener contenedor
    log "Deteniendo contenedor $CONTAINER..."
    if ! docker stop "$CONTAINER" >> "$LOG_FILE" 2>&1; then
        log "ERROR: No se pudo detener el contenedor $CONTAINER"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        return 1
    fi
    
    # Realizar backup de cada volumen
    echo "$VOLUMES" | jq -c '.[]' | while read -r volume; do
        VOLUME_PATH=$(echo "$volume" | jq -r '.')
        if ! backup_volume "$CONTAINER" "$VOLUME_PATH" "$BACKUP_PATH"; then
            BACKUP_FAILED=1
            ERROR_COUNT=$((ERROR_COUNT + 1))
        fi
    done
    
    # Iniciar contenedor
    log "Iniciando contenedor $CONTAINER..."
    if ! docker start "$CONTAINER" >> "$LOG_FILE" 2>&1; then
        log "ERROR: No se pudo iniciar el contenedor $CONTAINER"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        return 1
    fi
    
    if [ $BACKUP_FAILED -eq 0 ]; then
        log "Backup completado exitosamente para todos los volúmenes de $CONTAINER"
        return 0
    else
        log "ADVERTENCIA: Algunos volúmenes de $CONTAINER no se pudieron respaldar"
        return 1
    fi
}

# Validar archivo de configuración
if [ ! -f "$CONFIG_FILE" ]; then
    log "ERROR: No se encuentra el archivo de configuración: $CONFIG_FILE"
    exit 1
fi

# Procesar cada contenedor
log "Iniciando proceso de backup"
log "Usando archivo de configuración: $CONFIG_FILE"

# Obtener la ruta de destino del backup desde el archivo de configuración
BACKUP_DEST=$(jq -r '.config.BackupDestination // "/tmp/backups"' "$CONFIG_FILE")
mkdir -p "$BACKUP_DEST"

# Procesar cada contenedor en el archivo de configuración
jq -c '.containers[]' "$CONFIG_FILE" 2>/dev/null | while read -r container; do
    CONTAINER_NAME=$(echo "$container" | jq -r '.name')
    VOLUMES=$(echo "$container" | jq '.volumes')
    
    backup_container "$CONTAINER_NAME" "$VOLUMES" "$BACKUP_DEST"
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