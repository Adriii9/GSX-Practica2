#!/bin/bash

VERD='\033[0;32m'
BLAU='\033[0;34m'
NC='\033[0m'

echo -e "${BLAU}=== DIAGNÒSTIC DE PROCESSOS (WEEK 3) ===${NC}"

echo -e "\n${VERD}[+] ESTAT DEL SISTEMA EN TEMPS REAL (/proc):${NC}"
echo "Load Average (CPU i I/O): $(cat /proc/loadavg)"
echo "Memòria Lliure: $(grep MemAvailable /proc/meminfo | awk '{print $2/1024 " MB"}')"

echo -e "\n${VERD}[+] TOP 5 PROCESSOS PER CPU (ps):${NC}"
ps -eo pid,user,%cpu,%mem,command --sort=-%cpu | head -n 6

echo -e "\n${VERD}[+] TOP 5 PROCESSOS PER MEMÒRIA (ps):${NC}"
ps -eo pid,user,%cpu,%mem,command --sort=-%mem | head -n 6

echo -e "\n${VERD}[+] ARBRE DE PROCESSOS (pstree):${NC}"
pstree -p | head -n 10

echo -e "\n${BLAU}NOTA: Per a monitorització interactiva, utilitza les eines 'top' o 'htop'.${NC}"
echo -e "${BLAU}========================================${NC}"
