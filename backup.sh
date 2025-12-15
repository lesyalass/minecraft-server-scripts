#!/bin/bash

BACKUP_DIR="/opt/minecraft/backups"
SERVER_DIR="/opt/minecraft/paper"
LOG_FILE="/opt/minecraft/backup.log"
ENV_FILE="/opt/minecraft/.env"

if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
else
    echo "File $ENV_FILE not found! Please add BOT_TOKEN and CHAT_ID."
    exit 1
fi

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_FILE="${BACKUP_DIR}/minecraft_backup_${TIMESTAMP}.tar.gz"

log() {
    echo "[$(date)] $1" | tee -a "$LOG_FILE"
}

send_telegram() {
    local text="$1"
    curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
         -d "chat_id=${CHAT_ID}" \
         -d "text=${text}" \
         -d "parse_mode=Markdown" > /dev/null
}

FREE_SPACE=$(df "$BACKUP_DIR" | awk 'NR==2 {print $4}')
if [ "$FREE_SPACE" -lt 5000000 ]; then
    log "Not enough free disk space for backup."
    send_telegram "Недостаточно места для создания бэкапа Minecraft!"
    exit 1
fi

mkdir -p "$BACKUP_DIR"
mkdir -p "$SERVER_DIR"

log "Starting Minecraft backup (${TIMESTAMP})"
send_telegram "Начало создания бэкапа Minecraft..."

cd "$SERVER_DIR" || exit 1
if tar -czf "$BACKUP_FILE" . 2>>"$LOG_FILE"; then
    log "Backup successfully created: $BACKUP_FILE"
    send_telegram "Бэкап успешно создан: *${BACKUP_FILE}*"
else
    log "Error occurred while creating backup."
    send_telegram "Ошибка при создании бэкапа Minecraft!"
    exit 1
fi

log "Cleaning up old backups..."
ls -tp "$BACKUP_DIR"/minecraft_backup_*.tar.gz 2>/dev/null | tail -n +4 | xargs -r rm -f

if [ -f "$LOG_FILE" ] && [ "$(du -m "$LOG_FILE" | cut -f1)" -gt 5 ]; then
    mv "$LOG_FILE" "${LOG_FILE}.old"
    touch "$LOG_FILE"
    log "Log file exceeded 5 MB — new log file created."
fi

log "Backup completed successfully."
send_telegram "Бэкап завершён успешно. Сохранено до 3 последних архивов."

exit 0

