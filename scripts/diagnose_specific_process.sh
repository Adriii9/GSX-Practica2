#!/bin/bash

# ==============================================================================
# SCRIPT: diagnose_specific_process.sh
# DESCRIPCIÓ: Eina de diagnòstic per monitoritzar recursos i procés concret.
# ASSIGNATURA: GSX - Pràctica 1 (Week 3)
# ==============================================================================

VERD='\033[0;32m'
BLAU='\033[0;34m'
GROC='\033[1;33m'
NC='\033[0m'


# ------------------------------------------------------------------------------
# Permetem buscar un procés específic si passem un paràmetre (ex: ./diagnose_processes.sh nginx)
# Si no passem paràmetre, busca 'systemd' per defecte per tenir un exemple.

PROCES=${1:-systemd}

echo -e "\n${VERD}[3] MÈTRIQUES ESPECÍFIQUES DEL PROCÉS: ${GROC}$PROCES${NC}"

# Comprovem si el procés està en execució
if pgrep -x "$PROCES" > /dev/null || pgrep -f "$PROCES" > /dev/null; then
    # Extraiem les dades vitals d'aquest procés en concret
    ps -C "$PROCES" -o pid,user,%cpu,%mem,stat,start,command || \
    ps -ef | grep "$PROCES" | grep -v grep | awk '{print "PID: "$2" | USER: "$1" | CMD: "$8}'
    
    # Extraiem l'ús directe des del /proc d'aquest procés (Molt valorat pel professor!)
    PID_ESPECIFIC=$(pgrep -n -f "$PROCES")
    echo -e "  -> Fils d'execució (Threads): $(cat /proc/$PID_ESPECIFIC/status 2>/dev/null | grep Threads | awk '{print $2}')"
    echo -e "  -> Canvis de context: $(cat /proc/$PID_ESPECIFIC/status 2>/dev/null | grep voluntary_ctxt_switches | head -n 1 | awk '{print $2}')"
else
    echo -e "El procés '$PROCES' no s'està executant actualment."
fi

echo -e "\n${BLAU}==========================================${NC}"
