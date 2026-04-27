#!/bin/bash

# ==============================================================================
# SCRIPT: backup_data.sh
# DESCRIPCIÓ: Empaqueta dades per a còpia de seguretat preservant atributs.
# ASSIGNATURA: Gestió de Sistemes i Xarxes - Pràctica 1 (Week 1)
# ==============================================================================

# 1. Comprovem si l'script ha rebut un paràmetre (ex: "24h", "72h", "7D")
if [ -z "$1" ]; then
    echo "❌ ERROR: Has d'indicar la freqüència del backup com a paràmetre."
    echo "Ús: $0 <freqüència> (ex: $0 diari)"
    exit 1
fi

FREQUENCIA=$1
ARXIU_CONFIG="/opt/admin/configs/config_backups_${FREQUENCIA}.txt"

# 1.1 Comprovem si l'arxiu de configuració existeix
if [ ! -f "$ARXIU_CONFIG" ]; then
    echo "❌ ERROR: No s'ha trobat l'arxiu de configuració a $ARXIU_CONFIG"
    exit 1
fi


# 1.2 Llegim la ruta (agafem la primera línia de l'arxiu)
DIR_ORIGEN=$(head -n 1 "$ARXIU_CONFIG")

# 1.3 Verifiquem que l'arxiu no estigui buit
if [ -z "$DIR_ORIGEN" ]; then
    echo "ERROR: L'arxiu de configuració està buit."
    exit 1
fi


# 2. Configuració de Variables
# ------------------------------------------------------------------------------
# Defineix el directori d'origen. Per a la Week 1

DIR_DESTI="/var/backups/backups_gsx"    # On es guardarà la còpia
DATA_ACTUAL=$(date +"%Y%m%d_%H%M%S")
NOM_CARPETA=$(basename "$DIR_ORIGEN")
NOM_ARXIU="backup_${NOM_CARPETA}_${DATA_ACTUAL}.tar.gz"

# 3. Verificacions prèvies (Idempotència i Seguretat)
# ------------------------------------------------------------------------------
# Comprova si el directori de destí existeix; si no, el crea.
if [ ! -d "$DIR_DESTI" ]; then
    echo "Creant directori de còpies de seguretat a $DIR_DESTI..."
    # Utilitzem sudo perquè /var/backups sol requerir permisos d'administrador
    sudo mkdir -p "$DIR_DESTI"
fi

# Verifica que el directori d'origen realment existeix abans de començar
if [ ! -d "$DIR_ORIGEN" ]; then
    echo "ERROR: El directori d'origen $DIR_ORIGEN no existeix."
    exit 1
fi

# 4. Execució de la Còpia de Seguretat (tar)
# ------------------------------------------------------------------------------
echo "Iniciant còpia de seguretat de $DIR_ORIGEN a $DIR_DESTI/$NOM_ARXIU..."

# Explicació de les opcions (flags) utilitzades:
# -c: Create (crear un nou arxiu)
# -z: Gzip (comprimir l'arxiu per estalviar espai)
# -p: Preserve permissions (CRÍTIC: manté els permisos, propietari i grup originals)
# -f: File (indica el nom de l'arxiu de sortida)
# 
# Nota: És important fer servir 'sudo' per garantir que tenim permís de lectura
# de tots els arxius d'origen i permís d'escriptura al destí.

sudo tar -czpf "$DIR_DESTI/$NOM_ARXIU" "$DIR_ORIGEN"

# 5. Verificació del resultat (Codis de sortida)
# ------------------------------------------------------------------------------
# $? conté el codi de sortida de l'últim comandament executat (tar).
# 0 significa èxit, qualsevol altre número indica error.

if [ $? -eq 0 ]; then
    echo "Còpia de seguretat completada amb èxit: $DIR_DESTI/$NOM_ARXIU"
    
    # Opcional: Mostra els detalls de l'arxiu creat per confirmar la mida
    ls -lh "$DIR_DESTI/$NOM_ARXIU"
else
    echo "ERROR: La còpia de seguretat ha fallat."
    exit 1
fi
