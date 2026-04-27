#!/bin/bash
# ==============================================================================
# SCRIPT: delete_dev.sh (VERSIÓ BLINDADA)
# ==============================================================================

VERD='\033[0;32m'
VERMELL='\033[0;31m'
GROC='\033[1;33m'
NC='\033[0m'

# 1. SEGURETAT: Autorització gsx
if [ "$EUID" -ne 0 ]; then
    echo -e "${VERMELL}ERROR: Executa amb sudo.${NC}"; exit 1
fi
if [ "$SUDO_USER" != "gsx" ]; then
    echo -e "${VERMELL}ALERTA: Només 'gsx' pot esborrar usuaris.${NC}"; exit 1
fi

# 2. LECTURA DEL PARÀMETRE
TARGET_NUM=$1
if [[ -z "$TARGET_NUM" ]] || ! [[ "$TARGET_NUM" =~ ^[0-9]+$ ]]; then
    echo -e "${GROC}Ús: $0 <número>${NC}"; exit 1
fi

TARGET_USER="dev${TARGET_NUM}"

# 3. COMPROVACIÓ D'EXISTÈNCIA
if ! id "$TARGET_USER" >/dev/null 2>&1; then
    echo -e "${VERMELL}ERROR: $TARGET_USER no existeix.${NC}"; exit 1
fi

# 4. ESBORRAT DE L'USUARI
echo -e "${GROC}[+] Iniciant esborrat de $TARGET_USER...${NC}"
# Matem sessions de sistema (systemd/logind)
loginctl terminate-user "$TARGET_USER" 2>/dev/null
pkill -9 -u "$TARGET_USER" 2>/dev/null
sleep 1
userdel -r "$TARGET_USER" || { echo -e "${VERMELL}Falla crítica esborrant $TARGET_USER${NC}"; exit 1; }
echo -e "${VERD}$TARGET_USER esborrat amb èxit.${NC}"

# 5. REORGANITZACIÓ INTEGRAL
MAX_DEV=$(grep '^dev' /etc/passwd | cut -d: -f1 | sed 's/dev//' | sort -nr | head -n 1)

if [ -n "$MAX_DEV" ] && [ "$MAX_DEV" -gt "$TARGET_NUM" ]; then
    for (( i=$((TARGET_NUM + 1)); i<=$MAX_DEV; i++ )); do
        OLD_USER="dev$i"
        if id "$OLD_USER" >/dev/null 2>&1; then
            NEW_NUM=$((i - 1))
            NEW_USER="dev${NEW_NUM}"

            echo -e "${GROC}[+] Promovent $OLD_USER a $NEW_USER...${NC}"
            
            # Netegem qualsevol procés persistent (motiu de l'error anterior)
            loginctl terminate-user "$OLD_USER" 2>/dev/null
            pkill -9 -u "$OLD_USER" 2>/dev/null
            sleep 1

            # Intentem el canvi. Si falla, sortim per no corrompre més usuaris.
            if usermod -l "$NEW_USER" -d "/home/$NEW_USER" -m "$OLD_USER"; then
                groupmod -n "$NEW_USER" "$OLD_USER" 2>/dev/null || true
                echo "$NEW_USER:gsx${NEW_NUM}" | chpasswd
                echo -e "  -> Èxit: Usuari i contrasenya actualitzats a $NEW_USER."
            else
                echo -e "${VERMELL}ERROR: No s'ha pogut moure $OLD_USER. Aturant reorganització.${NC}"
                exit 1
            fi
        fi
    done
fi

# 6. MANTENIMENT done.log
if id "dev1" >/dev/null 2>&1; then
    chown dev1:greendevcorp /home/greendevcorp/done.log 2>/dev/null
fi

echo -e "${VERD}Operació d'offboarding completada amb èxit!${NC}"
