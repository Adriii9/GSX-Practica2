#!/bin/bash
# ==============================================================================
# SCRIPT: backup_incremental.sh (WEEK 5)
# DESCRIPCIÓ: Backup incremental automàtic cap al disc secundari usant rsync.
# ==============================================================================

ORIGEN="/home/greendevcorp"
DESTI="/mnt/backup_drive/incrementals"
LOG_FILE="/opt/admin/logs/backup_incremental.log"
DATA=$(date +"%Y-%m-%d %H:%M:%S")

mkdir -p "$DESTI"

echo "[$DATA] INICIANT BACKUP INCREMENTAL DE CODI..." >> "$LOG_FILE"

# Sincronitzem l'espai de treball dels desenvolupadors
rsync -aq --delete "$ORIGEN" "$DESTI"

if [ $? -eq 0 ]; then
    echo "[$DATA] ÈXIT: Backup incremental completat correctament." >> "$LOG_FILE"
    exit 0
else
    echo "[$DATA] ERROR: El backup ha fallat. Revisa els permisos o el disc destí." >> "$LOG_FILE"
    >&2 echo "Error crític en el backup incremental rsync." 
    exit 1
fi
