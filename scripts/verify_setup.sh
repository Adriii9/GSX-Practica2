#!/bin/bash

# COLORS per a una millor visualització
VERD='\033[0;32m'
VERMELL='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${VERD}--- Iniciant Verificació de la Infraestructura (Setmana 1) ---${NC}"

# 1. Comprovació de paquets instal·lats

echo -n "Comprovant paquets bàsics... "
for pkg in sudo openssh-server git htop tar; do
    if dpkg -l | grep -q "^ii  $pkg "; then
        echo -ne "[OK: $pkg] "
    else
        echo -e "\n${VERMELL}[ERROR] El paquet $pkg no està instal·lat${NC}"
    fi
done
echo ""

# 2. Comprovació d'escalada de privilegis (Sudo)
echo -n "Verificant permisos de l'usuari 'gsx'... "
if groups gsx | grep -q "\bsudo\b"; then
    echo -e "${VERD}[OK]${NC}"
else
    echo -e "${VERMELL}[FAIL] L'usuari no és al grup sudo${NC}"
fi

# 3. Comprovació de l'accés remot (SSH)
echo -n "Verificant estat del servei SSH... "
if systemctl is-active --quiet ssh; then
    echo -e "${VERD}[ACTIU]${NC}"
else
    echo -e "${VERMELL}[INACTIU]${NC}"
fi

# 4. Comprovació de l'estructura administrativa
echo "Verificant directoris administratius a /opt/admin..."
for dir in scripts logs configs; do
    if [ -d "/opt/admin/$dir" ]; then
        echo -e "  - /opt/admin/$dir: ${VERD}[PRESENT]${NC}"

        # Verificació de permisos i grup (Least Privilege)
        GROUP=$(stat -c '%G' "/opt/admin/$dir")
        if [ "$GROUP" == "sudo" ]; then
            echo -e "    Grup: ${VERD}[OK: sudo]${NC}"
        else
            echo -e "    Grup: ${VERMELL}[ERROR: $GROUP]${NC}"
        fi
    else
        echo -e "  - /opt/admin/$dir: ${VERMELL}[MISSING]${NC}"
    fi
done

echo -e "${VERD}--- Verificació finalitzada ---${NC}"

# 5. Comprovació dels Serveis de la Week 2 (NOU)
echo -e "\n${VERD}--- Verificant Serveis (Week 2) ---${NC}"

# Verificar Nginx
echo -n "Verificant estat de Nginx... "
if systemctl is-active --quiet nginx; then
    echo -e "${VERD}[ACTIU]${NC}"
else
    echo -e "${VERMELL}[INACTIU]${NC}"
fi

# Verificar Resiliència de Nginx (comprova si existeix l'override)
echo -n "Verificant resiliència de Nginx (Override)... "
if [ -f "/etc/systemd/system/nginx.service.d/override.conf" ]; then
    echo -e "${VERD}[CONFIGURAT]${NC}"
else
    echo -e "${VERMELL}[FALTA OVERRIDE]${NC}"
fi

# Verificar Timer del Backup
echo -n "Verificant automatització del Backup (Timer)... "
if systemctl is-active --quiet backup-gsx-24h.timer && systemctl is-active --quiet backup-gsx-72h.timer && systemctl is-active --quiet backup-gsx-7D.timer; then
    echo -e "${VERD}[PROGRAMAT]${NC}"
else
    echo -e "${VERMELL}[INACTIU]${NC}"
fi
# 5. Comprovació dels Serveis de la Week 2 (NOU)
echo -e "\n${VERD}--- Verificant Serveis (Week 2) ---${NC}"

# Verificar Nginx
echo -n "Verificant estat de Nginx... "
if systemctl is-active --quiet nginx; then
    echo -e "${VERD}[ACTIU]${NC}"
else
    echo -e "${VERMELL}[INACTIU]${NC}"
fi

# Verificar Resiliència de Nginx (comprova si existeix l'override)
echo -n "Verificant resiliència de Nginx (Override)... "
if [ -f "/etc/systemd/system/nginx.service.d/override.conf" ]; then
    echo -e "${VERD}[CONFIGURAT]${NC}"
else
    echo -e "${VERMELL}[FALTA OVERRIDE]${NC}"
fi

# Verificar Timer del Backup
echo -n "Verificant automatització del Backup (Timer)... "
if systemctl is-active --quiet backup-gsx-24h.timer && systemctl is-active --quiet backup-gsx-72h.timer && systemctl is-active --quiet backup-gsx-7D.timer; then
    echo -e "${VERD}[PROGRAMAT]${NC}"
else
    echo -e "${VERMELL}[INACTIU]${NC}"
fi
