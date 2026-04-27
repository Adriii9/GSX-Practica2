#!/bin/bash

# 1. DEFINICIÓ DE VARIABLES
ADMIN_PATH="/opt/admin"
REPO_URL="https://github.com/Adriii9/GSX-Practica1"
TARGET_COMMIT="270fe05"

# 2. COMPROVACIÓ DE SEGURETAT
if [ "$EUID" -ne 0 ]; then 
  echo "Si us plau, executa'm amb sudo."
  exit 1
fi

echo "--- Iniciant recuperació total de la infraestructura ---"

# 3. GESTIÓ DEL DIRECTORI (Neteja si cal per evitar l'error de Git)
if [ -d "$ADMIN_PATH" ] && [ ! -d "$ADMIN_PATH/.git" ]; then
    echo "[!] Alerta: $ADMIN_PATH existeix però no és un repositori Git."
    echo "[+] Netejant directori per permetre el clonat net..."
    rm -rf "$ADMIN_PATH" # Esborrem perquè el clone no doni error
fi

# 4. CREACIÓ I CLONAT
if [ ! -d "$ADMIN_PATH" ]; then
    echo "[+] Creant directori i clonant repositori des de zero..."
    git clone "$REPO_URL" "$ADMIN_PATH"
else
    echo "[+] El repositori ja existeix. Actualitzant dades..."
    cd "$ADMIN_PATH" && git fetch --all
fi

# 5. RESTAURACIÓ AL COMMIT ESPECÍFIC
cd "$ADMIN_PATH"
echo "[+] Forçant l'estat dels scripts al commit $TARGET_COMMIT..."
git checkout "$TARGET_COMMIT" -- scripts/
git checkout "$TARGET_COMMIT" -- README.md

# 6. ASSEGURAR L'ARBRE COMPLET (Backups, logs i configs)
echo "[+] Recreant subcarpetes de treball..."
mkdir -p "$ADMIN_PATH"/{backups,logs,configs}

# 7. REAPLICACIÓ TOTAL DE PERMISOS
echo "[+] Fixant permisos de col·laboració (root:sudo, 775)..."
chown -R root:sudo "$ADMIN_PATH"
chmod -R 775 "$ADMIN_PATH"

echo "--- Sistema recuperat correctament al punt $TARGET_COMMIT ---"
