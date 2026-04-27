#!/bin/bash
VERD='\033[0;32m'
VERMELL='\033[0;31m'
NC='\033[0m'

echo "=== VERIFICACIÓ SECURITY & ACCESS (WEEK 4) ==="

# 1. Comprovació d'ACLs i Permisos Especials
echo -n "  - Permisos especials a /shared (SetGID + Sticky): "
PERMS=$(stat -c "%a" /home/greendevcorp/shared)
if [[ "$PERMS" == 3* ]]; then echo -e "${VERD}[OK: $PERMS]${NC}"; else echo -e "${VERMELL}[FAIL]${NC}"; fi

echo -n "  - ACL actiu: dev1 té accés RWX a /shared: "
if getfacl /home/greendevcorp/shared | grep -q "user:dev1:rwx"; then echo -e "${VERD}[OK]${NC}"; else echo -e "${VERMELL}[FAIL]${NC}"; fi

# 2. Test d'Escalada i Escriptura
echo -n "  - Test auditat: dev3 no pot escriure a /shared: "
if sudo -u dev3 touch /home/greendevcorp/shared/test_hack 2>/dev/null; then
    echo -e "${VERMELL}[FAIL: dev3 ha pogut escriure!]${NC}"
    rm -f /home/greendevcorp/shared/test_hack
else
    echo -e "${VERD}[OK: Accés denegat correctament]${NC}"
fi

echo -n "  - Test auditat: dev2 no pot escriure a done.log: "
if sudo -u dev2 bash -c 'echo "hack" >> /home/greendevcorp/done.log' 2>/dev/null; then
    echo -e "${VERMELL}[FAIL: dev2 ha modificat el log]${NC}"
else
    echo -e "${VERD}[OK: Accés denegat correctament]${NC}"
fi

# 3. Test d'Entorn
echo -n "  - Límits PAM configurats per a @greendevcorp: "
if [ -f "/etc/security/limits.d/greendevcorp-team.conf" ]; then echo -e "${VERD}[OK]${NC}"; else echo -e "${VERMELL}[FAIL]${NC}"; fi

echo "=============================================="
