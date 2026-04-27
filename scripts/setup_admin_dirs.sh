#!/bin/bash

# COMPROVACIÓ INICIAL DE SEGURETAT
if [ "$EUID" -ne 0 ]; then
    echo "Si us plau, executa'm amb sudo o root."
    exit 1
fi

echo "---  Creant estructura administrativa compartida ---"

# (1). DEFINICIÓ DE LA RUTA 
ADMIN_PATH="/opt/admin"

# (2). CREACIÓ DE L'ESTRUCTURA (Idempotència) 
# Creem les carpetes necessàries, incloent 'configs' per a la verificació
mkdir -p $ADMIN_PATH/{scripts,logs,configs}

# (3). PERMISOS PER A COL·LABORACIÓ 
# El grup 'sudo' permet que ambdós membres de l'equip hi treballin 
# Apliquem el principi de mínim privilegi en els permisos 
chown -R root:sudo $ADMIN_PATH
chmod -R 770 $ADMIN_PATH

# Donem la propietat del directori .git al grup sudo (on ets tu)
chown -R root:sudo /opt/admin/.git
# Ens assegurem que el grup tingui permisos d'escriptura
chmod -R 770 /opt/admin/.git



echo "--- Estructura creada correctament a $ADMIN_PATH ---"
ls -la $ADMIN_PATH
