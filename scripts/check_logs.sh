#!/bin/bash

# Comprovació de seguretat
if [ "$EUID" -ne 0 ]; then
    echo "Si us plau, executa aquest script amb sudo."
    exit 1
fi

VERD='\033[0;32m'
BLAU='\033[0;34m'
NC='\033[0m'

echo -e "${BLAU}==============================================${NC}"
echo -e "${VERD}   DIAGNÒSTIC DE LOGS (WEEK 2)   ${NC}"
echo -e "${BLAU}==============================================${NC}"

echo -e "\n${VERD}[+] ÚLTIMES 5 LÍNIES DEL SERVEI NGINX:${NC}"
journalctl -u nginx --no-pager | tail -n 5

echo -e "\n${VERD}[+] ÚLTIMES 5 LÍNIES DEL BACKUP AUTOMÀTIC:${NC}"
journalctl -u backup-gsx.service --no-pager | tail -n 5

echo -e "\n${VERD}[+] ESPAI OCUPAT PELS LOGS ACTUALMENT:${NC}"
journalctl --disk-usage

echo -e "\n${BLAU}==============================================${NC}"
