#!/bin/bash
# ==============================================================================
# SCRIPT: setup_storage.sh (WEEK 5)
# DESCRIPCIÓ: Configura un nou disc dur, el formata i el fa persistent a fstab.
# ==============================================================================

if [ "$EUID" -ne 0 ]; then
    echo "Executa aquest script amb sudo."
    exit 1
fi

VERD='\033[0;32m'
GROC='\033[1;33m'
NC='\033[0m'


DISC="/dev/sdb"
PUNT_MUNTATGE="/mnt/backup_drive"

echo -e "${GROC}=== INICIANT CONFIGURACIÓ D'EMMAGATZEMATGE (WEEK 5) ===${NC}"

# 1. Comprovació d'existència del disc
if [ ! -b "$DISC" ]; then
    echo "ERROR: No s'ha detectat el disc $DISC."
    exit 1

fi

# 2. Creació del punt de muntatge
if [ ! -d "$PUNT_MUNTATGE" ]; then
    echo "[+] Creant directori de muntatge a $PUNT_MUNTATGE..."
    mkdir -p "$PUNT_MUNTATGE"
fi

# 3. Particionat i Formatat (Idempotent: només ho fa si no té format)
if blkid "$DISC" | grep -q "ext4"; then
    echo -e "${VERD}[OK] El disc $DISC ja està formatat en ext4. Saltant format...${NC}"
else
    echo "[+] Formatant el disc sencer $DISC amb sistema de fitxers ext4..."
    # Formatem directament el disc sencer per simplificar (sense taula de particions complexa)
    mkfs.ext4 -F "$DISC"
fi

# 4. Muntatge persistent a /etc/fstab
UUID=$(blkid -s UUID -o value "$DISC")

if grep -q "$UUID" /etc/fstab; then
    echo -e "${VERD}[OK] El disc ja està configurat a /etc/fstab.${NC}"
else
    echo "[+] Afegint configuració persistent a /etc/fstab..."
    echo "# Disc secundari per a Backups (Week 5)" >> /etc/fstab
    echo "UUID=$UUID $PUNT_MUNTATGE ext4 defaults 0 2" >> /etc/fstab
fi

# 5. Muntem tot el que hi ha a fstab
mount -a

# 6. Permisos per a l'equip administratiu
chown -R root:sudo "$PUNT_MUNTATGE"
chmod -R 770 "$PUNT_MUNTATGE"

echo -e "\n${VERD}EMMAGATZEMATGE CONFIGURAT AMB ÈXIT!${NC}"
echo -e "Estat actual del muntatge:"
df -h | grep "$PUNT_MUNTATGE"
