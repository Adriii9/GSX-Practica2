#!/bin/bash
# ==============================================================================
# SCRIPT: test_restore.sh (WEEK 5)
# DESCRIPCIÓ: Simula una pèrdua de dades i verifica que la restauració funciona.
# ==============================================================================

VERD='\033[0;32m'
VERMELL='\033[0;31m'
NC='\033[0m'

# Comprovació obligatòria de root/sudo (Evita l'error de Permission Denied)
if [ "$EUID" -ne 0 ]; then
    echo -e "${VERMELL} ERROR: Les tasques de recuperació requereixen privilegis de root.${NC}"
    echo "Si us plau, executa l'script així: sudo $0"
    exit 1
fi

echo "=== INICIANT TEST DE RECUPERACIÓ DE DESASTRES ==="

# 1. Creem un fitxer de prova (ho fa el root, però li donem el grup de l'equip)
FITXER_PROVA="/home/greendevcorp/shared/prova_desastre_$(date +%s).txt"
echo "Aquest fitxer és vital per a la startup!" > "$FITXER_PROVA"
chown root:greendevcorp "$FITXER_PROVA"
echo "[+] 1. Fitxer crític creat a: $FITXER_PROVA"

# 2. Forcem l'execució del backup
echo "[+] 2. Executant el backup incremental automàtic..."
systemctl start backup-incremental.service

# 3. Simulem el desastre (esborrem l'original)
rm -f "$FITXER_PROVA"
echo "[+] 3. DESASTRE SIMULAT: El fitxer ha estat esborrat de producció!"

# 4. Intentem la restauració a una ubicació alternativa (Requeriment Part D)
UBICACIO_ALTERNATIVA="/tmp/restore_test"
mkdir -p "$UBICACIO_ALTERNATIVA"
echo "[+] 4. Restaurant dades des del disc de seguretat a $UBICACIO_ALTERNATIVA..."

# Utilitzem rsync amb la ruta correcta cap al destí del backup
rsync -a "/mnt/backup_drive/incrementals/greendevcorp/shared/" "$UBICACIO_ALTERNATIVA/"

# 5. Verifiquem si el fitxer ha sobreviscut
NOM_FITXER=$(basename "$FITXER_PROVA")
if [ -f "$UBICACIO_ALTERNATIVA/$NOM_FITXER" ]; then
    echo -e "${VERD} ÈXIT: El fitxer s'ha restaurat correctament a la ubicació alternativa!${NC}"
    echo "Contingut recuperat: $(cat "$UBICACIO_ALTERNATIVA/$NOM_FITXER")"
else
    echo -e "${VERMELL} ERROR: El fitxer no s'ha pogut recuperar. El backup ha fallat.${NC}"
    exit 1
fi

# Neteja de la prova
rm -rf "$UBICACIO_ALTERNATIVA"
echo "=== TEST FINALITZAT AMB ÈXIT ==="
